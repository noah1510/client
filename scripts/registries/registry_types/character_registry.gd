extends RegistryBase
class_name CharacterRegistry

var _internal_values: Dictionary = {}


func _init():
	_json_type = "character"


func contains(_item: String) -> bool:
	return _internal_values.has(_item)


func get_element(_item: String):
	return _internal_values[_item]


func assure_validity():
	for _char in _internal_values.values():
		if not _char.is_valid(self):
			print("Character (%s): Invalid character." % _char.get_id())
			_internal_values.erase(_char.get_id().to_string())

	return true


func load_from_json(_json: Dictionary) -> bool:
	if not can_load_from_json(_json):
		print("Wrong JSON type.")
		return false

	if not _json.has("data"):
		print("Character: No data object provided.")
		return false

	var _json_data = _json["data"] as Dictionary
	if _json_data == null:
		print("Character: Data object is not a dictionary.")
		return false

	if not _json_data.has("id"):
		print("Character: No name provided.")
		return false

	var char_id_str := str(_json_data["id"])
	var char_id := Identifier.from_string(char_id_str)

	if contains(char_id_str):
		print("Character (%s): Character already exists in character registry." % char_id_str)
		return false

	var char_model_id = null
	if _json_data.has("model"):
		var raw_model_id = _json_data["model"]
		if not (raw_model_id is String):
			print("Character (%s): model must be a string." % char_id_str)
			return false

		char_model_id = Identifier.for_resource("character://" + raw_model_id)
	else:
		char_model_id = Identifier.for_resource("character://" + char_id_str)

	var char_icon_id = null
	if _json_data.has("icon"):
		var raw_icon_id = _json_data["icon"]
		if not (raw_icon_id is String):
			print("Character (%s): icon must be a string." % char_id_str)
			return false

		char_icon_id = Identifier.for_resource("texture://" + raw_icon_id)
	else:
		char_icon_id = Identifier.for_resource("texture://openchamp:character/fallback/icon")

	var raw_stats = _json_data["base_stats"]
	if not (raw_stats is Dictionary):
		print("Character (%s): base_stats must be a dictionary." % char_id_str)
		return false

	var stats = StatCollection.from_dict(raw_stats)

	var raw_stat_growth = _json_data["stat_growth"]
	if not (raw_stat_growth is Dictionary):
		print("Character (%s): stat_growth must be a dictionary." % char_id_str)
		return false

	var stat_growth = StatCollection.from_dict(raw_stat_growth)

	var tags: Array[String] = []
	if _json_data.has("tags"):
		var raw_tags = _json_data["tags"]
		if not (raw_tags is Array):
			print("Character (%s): tags must be an array." % char_id_str)
			return false

		for tag in raw_tags:
			if not (tag is String):
				print("Character (%s): tag must be a string, got %s." % [char_id_str, str(tag)])
				continue

			tags.append(tag)

	var new_char = CharacterData.new(
		char_id,
		char_model_id,
		char_icon_id,
		stats,
		stat_growth,
		tags
	)
	_internal_values[char_id_str] = new_char

	return true
