class_name NPC_Unit
extends Unit

enum AggroType {
	PASSIVE, # Doesn't attack.
	NEUTRAL, # Attacks when attacked.
	AGGRESSIVE, # Attacks anything not on its team.
}

var aggro_type : AggroType
var aggro_distance : float = 1.0
var deaggro_distance: float = 3.0

var aggro_collider: Area3D

func _ready():
	var aggro_shape = CapsuleShape3D.new()
	aggro_shape.radius = aggro_distance

	var aggro_collision_shape = CollisionShape3D.new()
	aggro_collision_shape.shape = aggro_shape

	aggro_collider = Area3D.new()
	aggro_collider.name = "AggroCollider"
	aggro_collider.add_child(aggro_collision_shape)

	aggro_collider.body_entered.connect(_enter_aggro_range)

	add_child(aggro_collider)

	super._ready()


func _enter_aggro_range(body: PhysicsBody3D):
	if aggro_type != AggroType.AGGRESSIVE: return
	if target_entity: return
	change_state("Attacking", null)
