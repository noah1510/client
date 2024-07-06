extends Object
class_name UnitData

enum AggroType {
	# Doesn't attack.
	PASSIVE,
	# Attacks when attacked.
	NEUTRAL,
	# Attacks anything not on its team.
	AGGRESSIVE,
}

var stats = StatCollection.new()
var stat_growth = StatCollection.new()

var id: Identifier
var model_id: Identifier
var icon_id: Identifier

var tags: Array[String] = []

var is_character: bool = false

var aggro_type: AggroType
var aggro_distance: float = 1.0
var deaggro_distance: float = 3.0


static func from_dict(_json: Dictionary, _registry: RegistryBase):
	if not _registry:
		print("UnitData: No registry provided.")
		return false
	
	if not _registry.can_load_from_json(_json):
		print("Wrong JSON type.")
		return false

	var _is_character: bool = _json["type"] == "character"

	if not _json.has("data"):
		print("Unit: No data object provided.")
		return false

	var _json_data = _json["data"] as Dictionary
	if _json_data == null:
		print("Unit: Data object is not a dictionary.")
		return false

	if not _json_data.has("id"):
		print("Unit: No name provided.")
		return false

	var _unit_id_str := str(_json_data["id"])
	var _unit_id := Identifier.from_string(_unit_id_str)

	if _registry.contains(_unit_id_str):
		print("Unit (%s): Unit already exists in unit registry." % _unit_id_str)
		return false

	var _unit_model_id = null
	if _json_data.has("model"):
		var raw_model_id = _json_data["model"]
		if not (raw_model_id is String):
			print("Unit (%s): model must be a string." % _unit_id_str)
			return false

		_unit_model_id = Identifier.for_resource("unit://" + raw_model_id)
	else:
		if _is_character:
			_unit_model_id = Identifier.for_resource("unit://" + _unit_id.get_group() + ":characters/" + _unit_id.get_name())
		else:
			_unit_model_id = Identifier.for_resource("unit://" + _unit_id_str)

	var _unit_icon_id = null
	if _json_data.has("icon"):
		var raw_icon_id = _json_data["icon"]
		if not (raw_icon_id is String):
			print("Unit (%s): icon must be a string." % _unit_id_str)
			return false

		_unit_icon_id = Identifier.for_resource("texture://" + raw_icon_id)
	else:
		if _is_character:
			_unit_icon_id = Identifier.for_resource("texture://" + _unit_id.get_group() + ":units/characters/" + _unit_id.get_name() + "/icon")
		else:
			_unit_icon_id = Identifier.for_resource("texture://" + _unit_id.get_group() + ":units/" + _unit_id.get_name() + "/icon")

	var raw_stats = _json_data["base_stats"]
	if not (raw_stats is Dictionary):
		print("Unit (%s): base_stats must be a dictionary." % _unit_id_str)
		return false

	var _stats = StatCollection.from_dict(raw_stats)

	var raw_stat_growth = _json_data["stat_growth"]
	if not (raw_stat_growth is Dictionary):
		print("Unit (%s): stat_growth must be a dictionary." % _unit_id_str)
		return false

	var _stat_growth = StatCollection.from_dict(raw_stat_growth)

	var _tags: Array[String] = []
	if _json_data.has("tags"):
		var raw_tags = _json_data["tags"]
		if not (raw_tags is Array):
			print("Unit (%s): tags must be an array." % _unit_id_str)
			return false

		for tag in raw_tags:
			if not (tag is String):
				print("Unit (%s): tag must be a string, got %s." % [_unit_id_str, str(tag)])
				continue

			_tags.append(tag)

	var new_unit = UnitData.new(
		_unit_id,
		_unit_model_id,
		_unit_icon_id,
		_stats,
		_stat_growth,
		_tags
	)
	new_unit.is_character = _is_character

	if _json_data.has("aggro_type"):
		var raw_aggro_type = _json_data["aggro_type"]

		match str(raw_aggro_type):
			"passive":
				new_unit.aggro_type = AggroType.PASSIVE
			"neutral":
				new_unit.aggro_type = AggroType.NEUTRAL
			"aggressive":
				new_unit.aggro_type = AggroType.AGGRESSIVE
			_:
				print("Unit (%s): Invalid aggro_type: %s" % [_unit_id_str, str(raw_aggro_type)])
				new_unit.aggro_type = AggroType.PASSIVE

	if _json_data.has("aggro_distance"):
		var raw_aggro_distance = _json_data["aggro_distance"]
		if raw_aggro_distance is float:
			new_unit.aggro_distance = raw_aggro_distance
		else:
			print("Unit (%s): aggro_distance must be a float. using default" % _unit_id_str)
			new_unit.aggro_distance = 1.0
	
	if _json_data.has("deaggro_distance"):
		var raw_deaggro_distance = _json_data["deaggro_distance"]
		if raw_deaggro_distance is float:
			new_unit.deaggro_distance = raw_deaggro_distance
		else:
			print("Unit (%s): deaggro_distance must be a float. using default" % _unit_id_str)
			new_unit.deaggro_distance = 3.0

	return new_unit


func get_id() -> Identifier:
	return id


func get_model_id() -> Identifier:
	if AssetIndexer.get_asset_path(model_id) == "":
		print("Unit (%s): Model asset not found." % id.to_string())
		return Identifier.for_resource("unit://openchamp:fallback")
	
	return model_id


func get_icon_id() -> Identifier:
	if AssetIndexer.get_asset_path(icon_id) == "":
		print("Unit (%s): Icon asset not found." % id.to_string())
		return Identifier.for_resource("texture://openchamp:units/fallback/icon")
	
	return icon_id


func get_stats() -> StatCollection:
	return stats


func get_stat_growth() -> StatCollection:
	return stat_growth


func is_valid(_registry: RegistryBase = null) -> bool:
	if not id.is_valid():
		return false
			
	return true


func spawn(spawn_args: Dictionary):
	var model_id_str = get_model_id().get_resource_id()
	print("Character (%s): Spawning character using the model: (%s)" % [id.to_string(), model_id_str])

	var model_scene = load(model_id_str)
	if model_scene == null:
		print("Character (%s): Failed to load model." % id.to_string())
		return null

	var _unit = model_scene.instantiate()
	if _unit == null:
		print("Character (%s): Failed to instantiate model." % id.to_string())
		return null

	_unit.name = spawn_args["name"]
	_unit.nametag = spawn_args["nametag"]
	_unit.team = spawn_args["team"]
	_unit.position = spawn_args["position"]

	_unit.server_position = _unit.position

	_unit.maximum_stats = stats.get_copy()
	_unit.current_stats = stats.get_copy()
	_unit.per_level_stats = stat_growth.get_copy()
	_unit.unit_id = id.to_string()

	if is_character:
		# set the character's script and set all the values
		#character.set_script("res://classes/character.gd")

		_unit.id = spawn_args["id"]
		_unit.has_mana = true
		_unit.player_controlled = true
	else:
		var unit_controller = NPC_Controller.new()
		unit_controller.aggro_type = aggro_type
		unit_controller.aggro_distance = aggro_distance
		unit_controller.deaggro_distance = deaggro_distance
		unit_controller.controlled_unit = _unit

		_unit.add_child(unit_controller)

	return _unit


func _init(
	_id: Identifier,
	_model_id: Identifier,
	_icon_id: Identifier,
	_stats: StatCollection,
	_stat_growth: StatCollection,
	_tags: Array[String]
):
	id = _id
	model_id = _model_id
	icon_id = _icon_id
	stats = _stats
	stat_growth = _stat_growth
	tags = _tags
