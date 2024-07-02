extends Node


func _ready() -> void:
    if Config.is_dedicated_server:
        return

    # Todo get the current player and set the icons to the
    # the ones for the actual character of the current player

    pass
