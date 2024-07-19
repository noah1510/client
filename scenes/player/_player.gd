extends Node3D

@export var cur_zoom: int

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
#@onready var attack_move_cast: ShapeCast3D = $AttackMoveCast
@export var server_listener: Node

@export var MoveMarker: PackedScene

var camera_target_position := Vector3.ZERO
var initial_mouse_position := Vector2.ZERO
var is_middle_mouse_dragging := false
var is_right_mouse_dragging := false
var is_left_mouse_dragging := false
var character : Unit
var attack_collider : Area3D

@onready var marker = MoveMarker.instantiate()
#@export var player := 1:
	#set(id):
		#player = id
		#$MultiplayerSynchronizer.set_multiplayer_authority(id)


func _ready():
	add_child(marker)

	# For now close game when server dies
	multiplayer.server_disconnected.connect(get_tree().quit)
	spring_arm.spring_length = Config.camera_settings.max_zoom
	Config.camera_property_changed.connect(_on_camera_setting_changed)
	
	center_camera.call_deferred(multiplayer.get_unique_id())
	
	if server_listener == null:
		server_listener = get_parent()
		while !server_listener.is_in_group("Map"):
			server_listener = server_listener.get_parent()

	# set up the attack collider
	var attack_coll_shape = CapsuleShape3D.new()
	attack_coll_shape.radius = 10

	var attack_collision_shape = CollisionShape3D.new()
	attack_collision_shape.shape = attack_coll_shape

	attack_collider = Area3D.new()
	attack_collider.name = "AttackCollider"
	attack_collider.add_child(attack_collision_shape)

	add_child(attack_collider)
	attack_collider = get_node("AttackCollider")


func _input(event):
	if Config.is_dedicated_server: return;
	
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_LEFT and not is_right_mouse_dragging:
			player_mouse_action(event, not is_left_mouse_dragging, true)
			if event.is_pressed and not is_left_mouse_dragging:
				is_left_mouse_dragging = true
			else:
				is_left_mouse_dragging = false
		
		# Right click to move
		if event.button_index == MOUSE_BUTTON_RIGHT and not is_left_mouse_dragging:
			# Start dragging
			player_mouse_action(event, not is_right_mouse_dragging) # For single clicks

			if event.is_pressed and not is_right_mouse_dragging:
				is_right_mouse_dragging = true
			else:
				is_right_mouse_dragging = false

		# if event.button_index == MOUSE_BUTTON_MIDDLE:
		# 	if event.pressed:
		# 		initial_mouse_position = event.position
		# 		is_middle_mouse_dragging = true
		# 	else:
		# 		is_middle_mouse_dragging = false
		
		# Stop dragging if mouse is released
		return
	
	if event is InputEventMouseMotion:
		if is_left_mouse_dragging:
			player_mouse_action(event, false, true)
			return
		
		if is_right_mouse_dragging:
			player_mouse_action(event, false)
			return

	
	if event.is_action("player_attack_closest"):
		if not _player_action_attack_near(character.global_position, null):
			character.change_state("Idle", null)
		
		return


func get_target_position(pid: int) -> Vector3:
	var champ = get_character(pid)
	if champ:
		return champ.position
	return Vector3.ZERO
	

func player_mouse_action(event, play_marker: bool=false, attack_move: bool=false):
	var from = camera.project_ray_origin(event.position)
	var to = from + camera.project_ray_normal(event.position) * 1000
	
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(params)
	if !result: return

	# Move
	if result.collider.is_in_group("Ground"):
		if attack_move:
			if not _player_action_attack_near(result.position, null):
				character.change_state("Idle", null)
		else:
			_player_action_move(result.position, play_marker)
	
	else:
		# Attack
		_player_action_attack(result.collider)


func _player_action_attack(collider):
	var colliding_unit = collider as Unit
	if not colliding_unit:
		return
	
	if colliding_unit.team == get_character(multiplayer.get_unique_id()).team:
		return
	
	var target_path = str(colliding_unit.get_path())
	server_listener.rpc_id(get_multiplayer_authority(), "target", target_path)

	_play_move_marker(colliding_unit.global_position, true)


func _player_action_attack_near(center: Vector3, target_mode = null) -> bool:
	# make the attack range visable for a bit
	if not Config.show_all_attack_ranges:
		character.attack_range_visualizer.show()
		get_tree().create_timer(0.2).connect("timeout", character.attack_range_visualizer.hide)

	var targeted_unit = target_mode as Unit
	if targeted_unit:
		print("Attacking " + targeted_unit.name)
		return false

	var target_players = true
	var target_minions = true
	var target_structures = true

	if target_mode != null:
		match str(target_mode):
			"players_only":
				target_minions = false
				target_structures = false
			"minions_only":
				target_players = false
				target_structures = false
			"structures_only":
				target_players = false
				target_minions = false
	
	var closest_unit = null
	var closest_distance = 1000000

	attack_collider.get_child(0).shape.radius = character.current_stats.attack_range * 0.01
	attack_collider.global_transform.origin = character.server_position

	var bodies = attack_collider.get_overlapping_bodies()
	for body in bodies:
		var unit = body as Unit
		if unit == null: continue
		if unit == character: continue
		if unit.team == character.team: continue
		if not unit.is_alive: continue

		if unit.player_controlled and not target_players: continue
		if not unit.player_controlled and not target_minions: continue
		if unit.is_structure and not target_structures: continue

		if unit.global_position.distance_to(character.global_position) > (character.current_stats.attack_range * 0.01): continue

		var distance = unit.global_position.distance_to(center)
		if distance > closest_distance: continue

		closest_unit = unit
		closest_distance = distance

	if closest_unit == null:
		print("No valid targets in range")
		return false
	
	_player_action_attack(closest_unit)

	return true


func _player_action_move(target_pos: Vector3, update_marker: bool = false):
	if update_marker:
		_play_move_marker(target_pos, false)
	
	target_pos.y += 1
	server_listener.rpc_id(get_multiplayer_authority(), "move_to", target_pos)


func _play_move_marker(marker_position : Vector3, attack_move: bool = false):
	marker.global_position = marker_position
	marker.attack_move = attack_move
	marker.play()


func center_camera(playerid):
	camera_target_position = get_target_position(playerid)


func _process(delta):
	if Config.is_dedicated_server : return

	# Handle the gamepad and touch movement input
	var movement_delta = Vector3()

	movement_delta.x += Input.get_action_strength("character_move_right") - Input.get_action_strength("character_move_left")
	movement_delta.z += Input.get_action_strength("character_move_down") - Input.get_action_strength("character_move_up")

	if not movement_delta.is_zero_approx():
		var target_position = movement_delta * character.current_stats.movement_speed * delta + character.global_position
		_player_action_move(target_position)

	# handle all the camera-related input
	camera_movement_handler()
	
	# check input for ability uses
	detect_ability_use()
	
	# update the camera position using lerp
	position = position.lerp(camera_target_position, delta * Config.camera_settings.cam_speed)


func detect_ability_use() -> void:
	var pid = multiplayer.get_unique_id()
	if Input.is_action_just_pressed("player_ability1"):
		get_character(pid).trigger_ability(1)
		return
	if Input.is_action_just_pressed("player_ability2"):
		get_character(pid).trigger_ability(2)
		return
	if Input.is_action_just_pressed("player_ability3"):
		get_character(pid).trigger_ability(3)
		return
	if Input.is_action_just_pressed("player_ability4"):
		get_character(pid).trigger_ability(4)
		return


func camera_movement_handler() -> void:
	# don't move the cam while changing the settings since that is annoying af
	if Config.in_focued_menu:
		return

	# Zoom
	if Input.is_action_just_pressed("player_zoomin"):
		if spring_arm.spring_length > Config.camera_settings.min_zoom:
			spring_arm.spring_length -= 1
	if Input.is_action_just_pressed("player_zoomout"):
		if spring_arm.spring_length < Config.camera_settings.max_zoom:
			spring_arm.spring_length += 1
	
	# Recenter - Tap
	if Input.is_action_pressed("player_camera_recenter"):
		camera_target_position = get_target_position(multiplayer.get_unique_id())
		
	# Recenter - Toggle
	if Input.is_action_just_pressed("player_camera_recenter_toggle"):
		Config.camera_settings.is_cam_centered = (!Config.camera_settings.is_cam_centered)
	
	# If centered, blindly follow the character
	if (Config.camera_settings.is_cam_centered):
		camera_target_position = get_target_position(multiplayer.get_unique_id())
		return
	
	#ignore the input if this window is not even focused
	if not get_window().has_focus():
		return
	
	# Get Mouse Coords on screen
	var current_mouse_position = get_viewport().get_mouse_position()
	var size = get_viewport().get_visible_rect().size
	var cam_delta = Vector3(0, 0, 0)
	var edge_margin = Config.camera_settings.edge_margin
	
	# Check if there is a collision at the mouse position
	if not get_viewport().get_visible_rect().has_point(
		get_viewport().get_final_transform() * current_mouse_position
	):
		return
		
	# Edge Panning
	if current_mouse_position.x <= edge_margin:
		cam_delta.x -= 1
	elif current_mouse_position.x >= size.x - edge_margin:
		cam_delta.x += 1

	if current_mouse_position.y <= edge_margin:
		cam_delta.z -= 1
	elif current_mouse_position.y >= size.y - edge_margin:
		cam_delta.z += 1
	
	# Keyboard input
	cam_delta.x += Input.get_action_strength("camera_right") - Input.get_action_strength("camera_left")
	cam_delta.z += Input.get_action_strength("camera_down") - Input.get_action_strength("camera_up")
	
	# Middle mouse dragging
	if is_middle_mouse_dragging:
		var mouse_delta = current_mouse_position - initial_mouse_position
		cam_delta += Vector3(mouse_delta.x, 0, mouse_delta.y) * Config.camera_settings.cam_pan_sensitivity
	
	# Apply camera movement
	if cam_delta != Vector3.ZERO:
		camera_target_position += cam_delta


func get_character(pid: int) -> Node:
	if character == null:
		var champs = $"../Characters".get_children()
		for child in champs:
			if child.name == str(pid):
				character = child
				return child
		return null
	else:
		return character


func _on_camera_setting_changed():
	spring_arm.spring_length = clamp(
		spring_arm.spring_length,
		Config.camera_settings.min_zoom,
		Config.camera_settings.max_zoom
	)
