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
	var new_char = UnitData.from_dict(_json, self)
	if not new_char:
		return false
	
	var char_id_str: String = new_char.get_id().to_string()
	_internal_values[char_id_str] = new_char

	return true
