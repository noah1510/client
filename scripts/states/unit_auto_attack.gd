extends State
class_name unit_auto_attack

var windup_timer: Timer
var cooldown_timer: Timer
var target_unit: Unit


func enter(entity: Unit, _args = null):
	# Configure Timers
	windup_timer = entity.get_node("Abilities/AutoAttack/AAWindup")
	cooldown_timer = entity.get_node("Abilities/AutoAttack/AACooldown")

	# Subscribe to timer timeout
	windup_timer.timeout.connect(
		func(): do_attack(entity)
	)

	modify(entity, _args)


func modify(entity: Unit, _args = null):
	if _args == null:
		print("No target entity provided")
		return

	var _unit = _args as Unit
	if not _unit:
		print("No target doesn't seem to be a unit")
		return
	
	target_unit = _unit

	if target_unit != entity.target_entity:
		entity.target_entity = target_unit
	
	if not target_unit.is_alive:
		print("Target is dead, going back to idle state")
		entity.change_state("Idle", null)
		return
		

func exit(_entity: Unit):
	for conn in windup_timer.timeout.get_connections():
		windup_timer.timeout.disconnect(conn["callable"])


func update(entity: Unit, delta):
	# Client only
	if entity.global_position != entity.server_position:
		entity.global_position = entity.server_position
		entity.global_position = entity.global_position.lerp(entity.server_position, delta * entity.current_stats.movement_speed)


func update_tick_server(entity: Unit, delta):
	if not entity.target_entity: 
		entity.change_state("Idle", null)
		return
	
	if entity.target_entity.current_stats.health_max <= 0: 
		entity.change_state("Idle", null)
		return
	
	var target_distance = entity.position.distance_to(entity.target_entity.position)
	if target_distance <= entity.current_stats.attack_range:
		start_windup(entity)
		return
	
	entity.nav_agent.target_position = entity.target_entity.global_position
	entity.move_on_path(delta)


func start_windup(entity):
	if not entity.can_attack(): return
	if not windup_timer.is_stopped(): return
	if not cooldown_timer.is_stopped(): return

	# 1/2 of the attack duration is the windup time
	windup_timer.wait_time = (1.0 / entity.current_stats.attack_speed) / 2.0
	windup_timer.start()


func do_attack(entity):
	if not entity.can_attack(): return

	entity.attack()

	# The other 1/2 of the attack duration is the cooldown time
	cooldown_timer.wait_time = (1.0 / entity.current_stats.attack_speed) / 2.0
	cooldown_timer.start()
