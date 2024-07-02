extends Object
class_name Character

var stats = StatCollection.new()
var stat_growth = StatCollection.new()

var id: Identifier
var model_id: Identifier
var icon_id: Identifier

var tags: Array[String] = []

func get_id() -> Identifier:
	return id


func get_model_id() -> Identifier:
	if AssetIndexer.get_asset_path(model_id) == "":
		print("Character (%s): Model asset not found." % id.to_string())
		return Identifier.for_resource("character://openchamp:fallback")
	
	return model_id


func get_icon_id() -> Identifier:
	if AssetIndexer.get_asset_path(icon_id) == "":
		print("Character (%s): Icon asset not found." % id.to_string())
		return Identifier.for_resource("texture://openchamp:character/fallback/icon")
	
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

	var character = model_scene.instantiate()
	if character == null:
		print("Character (%s): Failed to instantiate model." % id.to_string())
		return null

	# set the character's script and set all the values
	#character.set_script("res://classes/champion.gd")

	character.maximum_stats = stats.get_copy()
	character.current_stats = stats.get_copy()
	character.per_level_stats = stat_growth.get_copy()

	character.name = spawn_args["name"]
	character.id = spawn_args["id"]
	character.nametag = spawn_args["nametag"]
	character.team = spawn_args["team"]
	character.position = spawn_args["position"]
	character.server_position = character.position

	character.unit_id = id.to_string()

	# Add all the common components

	return character


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
