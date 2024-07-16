extends CharacterBody3D
class_name Unit


# Signals
signal died

# constant unit variables
@export var id: int
@export var team: int
@export var index: int = 0
@export var nametag: String
@export var player_controlled: bool = false
@export var unit_id : String = ""

# Stats:
var maximum_stats: StatCollection
var current_stats: StatCollection
var per_level_stats: StatCollection

var has_mana: bool = false

var current_shielding: int = 0

var turn_speed: float = 15.0
var windup_fraction: float = 0.1

var level : int = 1
var level_exp : int = 0
var required_exp : int = 100
var dropped_exp : int = 0
var exp_per_second: float = 0

var current_gold : int = 0
var dropped_gold : int = 0
var gold_per_second : float = 0

var is_alive : bool = true

var kills : int = 0
var deaths : int = 0
var assists : int = 0

var minion_kills: int = 0

# Each bit of cc_state represents a different type of crowd control.
var cc_state: int = 0
var effect_array: Array[UnitEffect] = []

var target_entity: Node = null
var server_position

var nav_agent : NavigationAgent3D

var map : Node = null
var projectile_config : Dictionary
var projectile_spawner : MultiplayerSpawner

# UI
var healthbar : ProgressBar

# Preloaded scripts and scenes
const state_machine_script = preload("res://scripts/states/_state_machine.gd")
const state_idle_script = preload("res://scripts/states/unit_idle.gd")
const state_move_script = preload("res://scripts/states/unit_move.gd")
const state_auto_attack_script = preload("res://scripts/states/unit_auto_attack.gd")

const healthbar_scene = preload("res://ui/player_stats/healthbar.tscn")


func _init():
	if maximum_stats == null:
		maximum_stats = StatCollection.from_dict({
			"health_max": 640,
			"health_regen": 3.5,

			"mana_max": 280,
			"mana_regen": 7,
			
			"armor": 26,
			"magic_resist": 30,

			"attack_range": 3.0,
			"attack_damage": 60,
			"attack_speed": 0.75,

			"movement_speed": 100,
		} as Dictionary)
	
	if current_stats == null:
		current_stats = maximum_stats.get_copy()

	if per_level_stats == null:
		per_level_stats = StatCollection.new()

	required_exp = get_exp_for_levelup(level + 1)


func _ready():
	# setting up the multiplayer synchronization
	var replication_config = SceneReplicationConfig.new()

	replication_config.add_property(NodePath(".:rotation"))
	replication_config.property_set_spawn(NodePath(".:rotation"), true)
	replication_config.property_set_replication_mode(NodePath(".:rotation"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

	replication_config.add_property(NodePath(".:id"))
	replication_config.property_set_spawn(NodePath(".:id"), true)
	replication_config.property_set_replication_mode(NodePath(".:id"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

	replication_config.add_property(NodePath(".:maximum_stats"))
	replication_config.property_set_spawn(NodePath(".:maximum_stats"), true)
	replication_config.property_set_replication_mode(NodePath(".:maximum_stats"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

	replication_config.add_property(NodePath(".:current_stats"))
	replication_config.property_set_spawn(NodePath(".:current_stats"), true)
	replication_config.property_set_replication_mode(NodePath(".:current_stats"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

	replication_config.add_property(NodePath(".:server_position"))
	replication_config.property_set_spawn(NodePath(".:server_position"), true)
	replication_config.property_set_replication_mode(NodePath(".:server_position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	
	var multiplayer_synchronizer = MultiplayerSynchronizer.new()
	multiplayer_synchronizer.set_replication_config(replication_config)
	multiplayer_synchronizer.name = "MultiplayerSynchronizer"
	add_child(multiplayer_synchronizer)

	# setting up the state machine
	var state_machine_node = Node.new()
	state_machine_node.name = "StateMachine"
	state_machine_node.set_script(state_machine_script)
	state_machine_node.print_state_changes = player_controlled

	var state_idle_node = Node.new()
	state_idle_node.name = "Idle"
	state_idle_node.set_script(state_idle_script)
	state_machine_node.add_child(state_idle_node)

	var state_move_node = Node.new()
	state_move_node.name = "Moving"
	state_move_node.set_script(state_move_script)
	state_machine_node.add_child(state_move_node)

	var state_auto_attack_node = Node.new()
	state_auto_attack_node.name = "Attacking"
	state_auto_attack_node.set_script(state_auto_attack_script)
	state_machine_node.add_child(state_auto_attack_node)

	state_machine_node.initial_state = state_idle_node
	add_child(state_machine_node)

	# set up the abilities
	var abilities_node = Node.new()
	abilities_node.name = "Abilities"

	var auto_attack_node = Node.new()
	auto_attack_node.name = "AutoAttack"

	var aa_windup_node = Timer.new()
	aa_windup_node.name = "AAWindup"
	aa_windup_node.one_shot = true
	aa_windup_node.process_callback = Timer.TIMER_PROCESS_PHYSICS
	auto_attack_node.add_child(aa_windup_node)

	var aa_cooldown_node = Timer.new()
	aa_cooldown_node.name = "AACooldown"
	aa_cooldown_node.one_shot = true
	aa_cooldown_node.process_callback = Timer.TIMER_PROCESS_PHYSICS
	auto_attack_node.add_child(aa_cooldown_node)

	abilities_node.add_child(auto_attack_node)
	add_child(abilities_node)

	# set up projectile spawning
	var projectiles_node = Node.new()
	projectiles_node.name = "Projectiles"
	add_child(projectiles_node)

	var projectile_spawner_node = MultiplayerSpawner.new()
	projectile_spawner_node.name = "ProjectileSpawner"
	projectile_spawner_node.spawn_limit = 999
	projectile_spawner_node.spawn_path = NodePath("../Projectiles")
	projectile_spawner_node.spawn_function = spawn_projectile
	add_child(projectile_spawner_node)
	projectile_spawner = get_node("ProjectileSpawner")

	# set up the navitation agent
	var _nav_agent = NavigationAgent3D.new()
	_nav_agent.name = "NavigationAgent3D"
	add_child(_nav_agent)
	nav_agent = get_node("NavigationAgent3D")

	# set up the healthbar
	var healthbar_node = healthbar_scene.instantiate()
	healthbar_node.name = "Healthbar"
	add_child(healthbar_node)
	healthbar = get_node("Healthbar")
	healthbar.max_value = maximum_stats.health_max
	healthbar.sync(current_stats.health_max)


func spawn_projectile(_args):
	if not projectile_config:
		print("Projectile config not set.")
		return null
	
	var _projectile = Projectile.new()

	var spawn_offset = projectile_config["spawn_offset"] as Vector3
	spawn_offset = spawn_offset.rotated(Vector3(0, 1, 0), rotation.y)

	_projectile.caster = self
	_projectile.position = server_position + spawn_offset
	_projectile.target = target_entity

	_projectile.model = projectile_config["model"]
	_projectile.model_scale = projectile_config["model_scale"]
	_projectile.model_rotation = projectile_config["model_rotation"]
	_projectile.speed = projectile_config["speed"]

	_projectile.is_crit = should_crit()

	return _projectile


# Stats related things
func level_up(times: int = 1):
	maximum_stats.add(per_level_stats, times)
	current_stats.add(per_level_stats, times)
	
	# fixes a potential bug with the spawners
	# this allows for level up to be called before spawning the unit
	if healthbar:
		healthbar.max_value = maximum_stats.health_max
	
	level += times
	required_exp = get_exp_for_levelup(level + 1)


func give_exp(amount: int):
	level_exp += amount
	
	while level_exp >= required_exp:
		level_up()
		level_exp -= required_exp


func reward_exp_on_death(murderer = null):
	var exp_reward_shape = CylinderShape3D.new()
	# set the radius in which all units will be rewarded experience
	exp_reward_shape.radius = 100.0

	var exp_reward_collision = CollisionShape3D.new()
	exp_reward_collision.shape = exp_reward_shape

	var exp_reward_collider = Area3D.new()
	exp_reward_collider.name = "ExpRewardCollider"
	exp_reward_collider.add_child(exp_reward_collision)
	add_child(exp_reward_collider)

	var rewarded_units : Array[Unit] = []
	if murderer != null:
		rewarded_units.append(murderer)

	var bodies = exp_reward_collider.get_overlapping_bodies()
	for body in bodies:
		var _unit = body as Unit
		if _unit == null: continue
		if _unit.team == team: continue
		if not _unit.is_alive: continue
		if _unit == murderer: continue
		
		rewarded_units.append(_unit)
	
	exp_reward_collider.queue_free()
	
	if rewarded_units.size() == 0:
		return

	var unit_share_factor = 1.0 + 3.0 * log(float(rewarded_units.size()))
	var per_unit_exp = int(dropped_exp / unit_share_factor)
	var per_unit_gold = int(dropped_gold / unit_share_factor)

	if player_controlled:
		for _unit in rewarded_units:
			if _unit == murderer:
				_unit.kills += 1
			else:
				_unit.assists += 1
	else:
		murderer.minion_kills += 1

	if rewarded_units.size() == 1:
		murderer.give_exp(per_unit_exp)
		murderer.give_gold(per_unit_gold)
	else:
		for _unit in rewarded_units:
			_unit.give_exp(per_unit_exp)

			# the murderer gets more gold than everyone else
			if _unit == murderer:
				_unit.give_gold(int(per_unit_gold * 1.5))
			else:
				_unit.give_gold(per_unit_gold)


## This function returns the amount of experience required to level up.
## The returned value is the difference in exp needed to level up from
## _level-1 to _level.
## At the moment, the exp required to level up is 100 * _level.
static func get_exp_for_levelup(_level: int) -> int:
	return 100 * _level


# Gold related things
func give_gold(amount: int):
	current_gold += amount


# Movement
func update_target_location(target_location: Vector3):
	print("Target Location Updated");
	target_entity = null
	nav_agent.target_position = target_location


## Combat
func take_damage(caster: Unit, is_crit: bool):
	if not can_take_damage(): return

	var effective_armor = current_stats.armor
	effective_armor *= (1.0 - caster.current_stats.armor_pen_percent / 100.0)
	effective_armor -= caster.current_stats.armor_pen_flat
	effective_armor = max(0, effective_armor)

	var taken = float(effective_armor) / 100.0
	taken = caster.current_stats.attack_damage / (taken + 1)
	if is_crit:
		taken *= (1.0 + caster.current_stats.attack_crit_damage)

	var actual_damage = int(taken)
	if current_shielding > 0:
		current_shielding -= actual_damage
		if current_shielding <= 0:
			# since current_shielding is negative, we add it to
			# health_max to subtract the remaining shielding
			current_stats.health_max += current_shielding
			current_shielding = 0
	else:
		current_stats.health_max -= actual_damage
	
	if current_stats.health_max <= 0:
		current_stats.health_max = 0
		die(caster)
		
	healthbar.sync(current_stats.health_max)


func attack():
	if projectile_config:
		projectile_spawner.spawn()
	else:
		target_entity.take_damage(self, should_crit())


func should_crit() -> bool:
	if current_stats.attack_crit_chance < 0.0001: return false
	if current_stats.attack_crit_chance > 0.9999: return true

	var rand = RandomNumberGenerator.new()
	rand.seed = int(map.time_elapsed*60)
	return rand.randf() < current_stats.attack_crit_chance


func heal(amount:float, keep_extra:bool = false):
	current_stats.health_max += int(amount)
	if current_stats.health_max <= maximum_stats.health_max: return
	if keep_extra:
		current_shielding = current_stats.health_max - maximum_stats.health_max
	
	current_stats.health_max = maximum_stats.health_max
	healthbar.sync(current_stats.health_max)


func die(murderer = null):
	is_alive = false

	reward_exp_on_death(murderer)
	died.emit()

	if team > 0:
		deaths += 1


# UI
func _update_healthbar(node: ProgressBar):
	node.value = current_stats.health_max


func move_on_path(delta: float):
	if nav_agent.is_navigation_finished(): return
	if not can_move(): return
	server_position = global_position
	
	var target_location = nav_agent.get_next_path_position()
	var direction = target_location - global_position
	
	velocity = direction.normalized() * current_stats.movement_speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)
	move_and_slide()


func trigger_ability(_index: int):
	if not can_cast(): return
	
	# check if the ability exists
	var abilities_node = get_node("Abilities")
	if abilities_node == null:
		print("Abilities node not found.")
		return

	if _index >= abilities_node.get_child_count():
		print("Ability (%s) larger than the amount of known abilities (%s)." % [str(_index), str(abilities_node.get_child_count())])
		return

	var ability_node = get_node("Abilities").get_child(_index)
	if ability_node == null:
		print("Ability not found (%s)." % str(_index))
		return


func apply_effect(effect: UnitEffect):
	effect_array.append(effect)
	add_child(effect)
	recalculate_cc_state()


func _on_cc_end(effect: UnitEffect):
	effect_array.erase(effect)
	effect.end()
	recalculate_cc_state()


func recalculate_cc_state() -> int:
	var new_state := 0
	for effect in effect_array:
		new_state = new_state | effect.cc_mask
	cc_state = new_state
	return new_state


func can_move() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_MOVEMENT == 0


func can_cast_movement() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_CAST_MOBILITY == 0


func can_attack() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_ATTACK == 0


func can_cast() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_CAST == 0


func can_change_target() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_TARGET == 0


func can_take_damage() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_TAKE_DAMAGE == 0


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
