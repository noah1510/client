extends Node

@export var _map : Node

@onready var player_icon = $CharacterUI/Portrait
@onready var money_count = $GameStats/Money

var _character

func _ready() -> void:
	if Config.is_dedicated_server:
		return

	if _map == null:
		print("map not set")
		return

	# Todo get the current player and set the icons to the
	# the ones for the actual character of the current player
	call_deferred("_set_icons")


func _process(delta: float) -> void:
	if Config.is_dedicated_server:
		return

	if _character == null:
		call_deferred("_set_icons")

	if _character == null:
		return

	money_count.text = str(_character.current_gold)


func _set_icons():
	while _character == null:
		var _char = _map.get_character(multiplayer.get_unique_id())
		if typeof(_char) == TYPE_BOOL:
			print("Character not found")
		elif _char != null:
			_character = _char
			break
		
		print("Character not found")

	var player_icon_id = RegistryManager.characters().get_element(_character.unit_id).get_icon_id()
	if player_icon_id == null:
		print("Icon not found")
		return

	var _player_icon = load(player_icon_id.get_resource_id())
	if _player_icon == null:
		print("Icon not loaded")
		return

	player_icon.texture = _player_icon
