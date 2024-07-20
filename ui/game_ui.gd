extends Node

@export var _map : Node

@onready var player_icon = $CharacterUI/Portrait
@onready var money_count = $GameStats/Money
@onready var kda_display = $GameStats/KDA
@onready var cs_display = $GameStats/CS

@onready var hp_bar = $CharacterUI/HealthMana/HealthBar
@onready var mana_bar = $CharacterUI/HealthMana/ManaBar

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


func _process(_delta: float) -> void:
	if Config.is_dedicated_server:
		return

	if _character == null:
		call_deferred("_set_icons")

	if _character == null:
		return

	money_count.text = str(_character.current_gold)
	kda_display.text = str(_character.kills) + "/" + str(_character.deaths) + "/" + str(_character.assists)
	cs_display.text = str(_character.minion_kills)

	hp_bar.value = _character.current_stats.health
	hp_bar.max_value = _character.maximum_stats.health

	mana_bar.value = _character.current_stats.mana
	mana_bar.max_value = _character.maximum_stats.mana


func _set_icons():
	while _character == null:
		var _char = _map.get_character(multiplayer.get_unique_id())
		if typeof(_char) == TYPE_BOOL:
			print("Character not found")
		elif _char != null:
			_character = _char
			break
		
		print("Character not found")

	var player_icon_id = RegistryManager.units().get_element(_character.unit_id).get_icon_id()
	if player_icon_id == null:
		print("Icon not found")
		return

	var _player_icon = load(player_icon_id.get_resource_id())
	if _player_icon == null:
		print("Icon not loaded")
		return

	player_icon.texture = _player_icon

	if _character.has_mana:
		mana_bar.show()
	else:
		mana_bar.hide()
