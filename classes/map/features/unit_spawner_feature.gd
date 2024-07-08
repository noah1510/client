extends MapFeature
class_name UnitSpawnerFeature

# serialized data stats
var team: int

var unit_type : String = ""
var unit_level : int = 1
var unit_level_growth : int = 1
var unit_level_growth_time : float = 0

var initial_cooldown : float = 30
var wave_interval : float = 60
var wave_size : int = 1
var wave_growth : int = 1

var require_clear : bool = false

# current spawner values
var current_wave : int = 0

var spawned_units : Node
var spawn_timer : Timer


func _init():
	feature_type = "unit_spawn"


func spawn(feature_data: Dictionary, parent: Node) -> bool:
	if not feature_data.has("name"):
		print("Spawn is missing name")
		return false

	name = feature_data["name"]
	feature_name = name

	if not feature_data.has("team"):
		print("Spawn is missing team")
		return false
	team = int(feature_data["team"])

	if not feature_data.has("spawn_behaviour"):
		print("Spawn is missing spawn_behaviour")
		return false

	var spawn_behaviour: Dictionary = feature_data["spawn_behaviour"]
	
	if not spawn_behaviour.has("unit_type"):
		print("Spawn is missing unit_type")
		return false

	unit_type = str(spawn_behaviour["unit_type"])
	var unit_type_id = Identifier.from_string(unit_type)
	if not unit_type_id.is_valid():
		print("Failed to get unit type")
		return false

	if spawn_behaviour.has("unit_level"):
		unit_level = int(spawn_behaviour["unit_level"])

	if spawn_behaviour.has("unit_level_growth"):
		unit_level_growth = int(spawn_behaviour["unit_level_growth"])

	if spawn_behaviour.has("unit_level_growth_time"):
		unit_level_growth_time = float(spawn_behaviour["unit_level_growth_time"])

	if spawn_behaviour.has("initial_cooldown"):
		initial_cooldown = float(spawn_behaviour["initial_cooldown"])

	if spawn_behaviour.has("wave_interval"):
		wave_interval = float(spawn_behaviour["wave_interval"])

	if spawn_behaviour.has("wave_size"):
		wave_size = int(spawn_behaviour["wave_size"])

	if spawn_behaviour.has("wave_growth"):
		wave_growth = int(spawn_behaviour["wave_growth"])

	if spawn_behaviour.has("require_clear"):
		require_clear = bool(spawn_behaviour["require_clear"])

	position = _get_position(name, parent, feature_data)
	if position == null:
		print("Failed to get position")
		return false

	parent.player_spawns[str(team)] = self

	spawned_units = Node.new()
	spawned_units.name = "SpawnedUnits"
	add_child(spawned_units)
	spawned_units = get_node("SpawnedUnits")

	spawn_timer = Timer.new()
	spawn_timer.name = "SpawnTimer"
	spawn_timer.wait_time = initial_cooldown
	spawn_timer.one_shot = true
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_wave)
	add_child(spawn_timer)
	spawn_timer = get_node("SpawnTimer")

	return true


func _get_unit_level(game_time: float) -> int:
	return unit_level + (unit_level_growth * current_wave) + int(unit_level_growth_time * game_time)


func _get_wave_cooldown() -> float:
	return wave_interval


func _get_wave_size() -> int:
	return wave_size + (wave_growth * current_wave)


func _on_unit_death(unit: Unit):
	spawned_units.remove_child(unit)
	unit.queue_free()

	if not require_clear:
		return
	
	if spawned_units.get_child_count() == 0:
		var _next_cd = _get_wave_cooldown()
		print("Next wave in " + str(_next_cd) + " seconds")
		spawn_timer.wait_time = _next_cd
		spawn_timer.start()


func _spawn_wave():
	current_wave += 1
	var _size = _get_wave_size()
	print("Spawning wave of " + str(_size) + " units")

	for i in range(_size):
		get_tree().create_timer(i * 0.5).timeout.connect(_spawn_wave_unit)
	
	if not require_clear:
		var _next_cd = _get_wave_cooldown()
		print("Next wave in " + str(_next_cd) + " seconds")
		spawn_timer.wait_time = _next_cd
		spawn_timer.start()


func _spawn_wave_unit():
	var _unit_data = RegistryManager.units().get_element(unit_type)
	if _unit_data == null:
		print("Failed to get unit data")
		return

	var spawn_data = {
		"name": name + "_unit_" + str(current_wave),
		"team": team,
		"position": position,
		"level": _get_unit_level(map.time_elapsed),
	}

	var _unit = _unit_data.spawn(spawn_data)
	spawned_units.add_child(_unit)
