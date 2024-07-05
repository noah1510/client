extends Unit
class_name CharacterUnit


func _ready():
	super()
	healthbar.size = Vector2(100, 15)


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
