extends Node
class_name MapNode

enum EndCondition{
	TEAM_ELIMINATION,
	STRUCTURE_DESTRUCTION,
}

@export var map_configuration: Dictionary = {}

@export var connected_players: Array
@export var character_container: Node

@export var map_features: Node
@export var player_spawns = {}

@export var time_elapsed : float = 0

var Characters = {}
var player_cooldowns = {}
var end_conditions = []

var last_player_index = 0

const player_desktop_hud = preload("res://ui/game_ui.tscn")
const player_desktop_settings = preload("res://ui/settings_menu/settings_menu.tscn")


func _ready():
	_load_config()
	_setup_nodes()
	
	# TODO: make sure all clients have the map fully loaded before
	# continueing here. For now we just do a 1 seconds delay.
	await get_tree().create_timer(1).timeout
	
	if not Config.is_dedicated_server:
		client_setup()
	
	if not multiplayer.is_server():
		return

	for player in connected_players:
		var spawn_args = {}
		
		spawn_args["name"] = str(player["peer_id"])
		spawn_args["character"] = player["character"]
		spawn_args["id"] = player["peer_id"]
		spawn_args["nametag"] = player["name"]
		spawn_args["index"] = last_player_index
		spawn_args["team"] = player["team"]
		spawn_args["position"] = player_spawns[str(player["team"])].position

		last_player_index += 1
		
		var new_char = $CharacterSpawner.spawn(spawn_args)
		new_char.look_at(Vector3(0,0,0))
		Characters[player['peer_id']] = new_char


func _physics_process(delta):
	time_elapsed += delta


func _setup_nodes():
	character_container = Node.new()
	character_container.name = "Characters"
	add_child(character_container)
	character_container = get_node("Characters")
	
	var character_spawner = MultiplayerSpawner.new()
	character_spawner.name ="CharacterSpawner"
	character_spawner.spawn_path = NodePath("../Characters")
	character_spawner.spawn_limit = 50
	character_spawner.spawn_function = _spawn_character
	
	add_child(character_spawner)
	
	var abilities_node = Node.new()
	abilities_node.name = "Abilities"
	add_child(abilities_node)
	

func _spawn_character(args):
	var spawn_args = args as Dictionary
	
	if not spawn_args:
		print("Error character spawn args could now be parsed as dict!")
		return null
	
	print("loading character:" + spawn_args["character"])
	
	
	var char_data = RegistryManager.characters().get_element(spawn_args["character"])
	if not char_data:
		print("Error character data could not be found in registry!")
		return null

	var new_char = char_data.spawn(spawn_args)

	if multiplayer.is_server():
		new_char.died.connect(func(): on_player_death(spawn_args["id"]))

	return new_char


func _load_config():
	# unlike the other nodes the map features node is not created in the _setup_nodes function
	# this is needed because all features are added to this node and we need to load the map configuration
	# before we can set up most of the nodes
	var _map_features = Node.new()
	_map_features.name = "MapFeatures"
	add_child(_map_features)
	map_features = get_node("MapFeatures")

	# Load the map configuration
	if not map_configuration.has("end_conditions"):
		print("Map config is missing end conditions")
		return

	var raw_end_conditions = map_configuration["end_conditions"]
	for condition in raw_end_conditions:
		if not condition.has("type"):
			print("End condition is missing type")
			continue

		var type = condition["type"]
		match type:
			"team_elimination":
				if not condition.has("team"):
					print("Team elimination condition is missing team")
					continue
				end_conditions.append({
					"type": EndCondition.TEAM_ELIMINATION,
					"team": condition["team"]
				})
			"structure_destruction":
				if not condition.has("structure"):
					print("Structure destruction condition is missing structure")
					continue
				end_conditions.append({
					"type": EndCondition.STRUCTURE_DESTRUCTION,
					"structure_name": condition["structure_name"],
					"loosing_team": condition["loosing_team"]
				})
			_:
				print("Unknown end condition type: " + type)

	if not map_configuration.has("features"):
		print("Map config is missing features")
		return

	var features = map_configuration["features"]
	for feature in features:
		MapFeature.spawn_feature(feature, self)


func client_setup():
	# Add the player into the world
	# The player rig will ask the server for their character
	var player_rig = load("res://scenes/player/_player.tscn").instantiate()
	add_child(player_rig)
	
	# instantiate and add all the UI components
	add_child(player_desktop_settings.instantiate())

	var hud = player_desktop_hud.instantiate()
	hud._map = self
	add_child(hud)


func on_player_death(player_id: int):
	# get the character that died
	var character = Characters.get(player_id)
	var team = character.team

	# Check if the game has ended
	var team_alive = false
	var team_elimination = false
	for condition in end_conditions:
		if condition["type"] != EndCondition.TEAM_ELIMINATION:
			continue
		
		if team != condition["team"]:
			continue
		
		team_elimination = true
		for _char in Characters.values():
			if _char.name == str(player_id):
				continue
			
			if _char.team != team:
				continue

			if not _char.is_alive:
				continue

			team_alive = true
			break

	# End the game if a team has been eliminated
	if team_elimination and not team_alive:
		print("Team " + str(team) + " has been eliminated")
		return

	# get the respawn timer and respawn the player once it's done
	var respawn_time = player_spawns[str(team)].get_respawn_time(character.level, time_elapsed)
	get_tree().create_timer(respawn_time).timeout.connect(func(): respawn(character))


@rpc("any_peer")
func client_ready():
	print(connected_players);
	print(multiplayer.get_remote_sender_id())


@rpc("any_peer")
func register_player():
	var peer_id = multiplayer.get_remote_sender_id()


@rpc("any_peer", "call_local")
func move_to(pos: Vector3):
	var character = get_character(multiplayer.get_remote_sender_id())
	character.change_state.rpc("Moving", pos)


@rpc("any_peer", "call_local")
func target(target_path):
	var character = get_character(multiplayer.get_remote_sender_id())

	var target_unit = get_node(target_path) as Unit
	if not target_unit:
		print_debug("Failed to find target: " + target_path)
		return

	# Dont Kill Yourself
	if target_unit == character:
		print_debug("That's you ya idjit") # :O
		return

	character.change_state("Attacking", target_unit)


@rpc("any_peer", "call_local")
func spawn_ability(ability_name, ability_type, ability_pos, ability_mana_cost, cooldown, ab_id):
	var peer_id = multiplayer.get_remote_sender_id()
	var character = get_character(peer_id)

	if character.mana < ability_mana_cost:
		print("Not enough mana!")
		return

	if player_cooldowns[peer_id][ab_id-1] != 0:
		print("This ability is on cooldown! Wait " + str(cooldown) + " seconds!")
		return
	
	player_cooldowns[peer_id][ab_id-1] = cooldown
	free_ability(cooldown, peer_id, ab_id-1)
	character.mana -= ability_mana_cost
	print(character.mana)

	rpc_id(peer_id, "spawn_local_effect", ability_name, ability_type, ability_pos, character.position, character.team)


@rpc("any_peer", "call_local")
func spawn_local_effect(ability_name, ability_type, ability_pos, player_pos, player_team) -> void:
	var ability_scene = load("res://effects/abilities/"+ability_name+".tscn").instantiate()

	match ability_type:
		0:
			ability_scene.position = ability_pos
		1:
			ability_scene.direction = ability_pos
			ability_scene.position = player_pos

	ability_scene.team = player_team

	$"../Abilities".add_child(ability_scene)
	

@rpc("any_peer", "call_local")
func respawn(character: CharacterBody3D):
	var spawner = player_spawns[str(character.team)]
	
	character.server_position = spawner.get_spawn_position(character.index)
	character.position = character.server_position

	character.set_health(character.get_health_max())
	character.is_dead = false
	character.show()
	character.rpc_id(character.pid, "respawn")


func free_ability(cooldown: float, peer_id: int, ab_id: int) -> void:
	await get_tree().create_timer(cooldown).timeout
	player_cooldowns[peer_id][ab_id] = 0


func get_character(id:int):
	var character = Characters.get(id)
	if not character:
		print_debug("Failed to find character")
		return false
	
	return character
