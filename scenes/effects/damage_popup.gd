class_name DamagePopup
extends Node2D

@onready var label: RichTextLabel = $LabelNode/Label
@onready var label_container: Node2D = $LabelNode
@onready var ap: AnimationPlayer = $AnimationPlayer

var camera: Camera3D
var damage_value: int
var damage_type: Unit.DamageType
var spawn_position: Vector3


func _ready():
	if Config.is_dedicated_server:
		queue_free()
		return
	
	call_deferred("play")


func play():
	camera = get_viewport().get_camera_3d()

	if not camera:
		print("Couldn't get camera")
		remove()
		return

	if not spawn_position:
		print("No spawn position set for damage popup")
		remove()
		return
	
	if not damage_value:
		print("No damage value set for damage popup")
		remove()
		return

	if not damage_type:
		print("No damage type set for damage popup")
		remove()
		return

	var start_pos = camera.unproject_position(spawn_position)
	var length = ap.get_animation("pop_up").length
	var end_pos = start_pos + Vector2(0, -20)
	var tween = get_tree().create_tween()

	label.text = str(damage_value)
	ap.play("pop_up")
	
	tween.tween_property(label_container, "position", end_pos, length).from(start_pos)


func remove() -> void:
	ap.stop()
	queue_free() 
