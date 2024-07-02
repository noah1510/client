extends RichTextLabel
class_name MatchTimer

var time_elapsed : float = 0;
# Called when the node enters the scene tree for the first time.
func _ready():
	time_elapsed = 0;
	pass # Replace with function body.


func _physics_process(delta):
	time_elapsed += delta
	set_time(int(time_elapsed))

func set_time(t:int):
	var sec: int = t % 60
	var _min := int((t-sec) / 60.0)
	
	text = ""
	if _min < 10:
		text = "0"
	text += str(_min) + ":" + str(sec)
