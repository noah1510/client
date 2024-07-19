## This class is used to store all the stats of a unit.
## All stats are stored as integers to prevent floating point errors.
class_name StatCollection
extends Object


## The actual health value of the unit.
@export var health_max: int = 0
## The amount of health the unit regenerates per 5 seconds.
@export var health_regen: int = 0

## The actual mana value of the unit.
@export var mana_max: int = 0
## The amount of mana the unit regenerates per 5 seconds.
@export var mana_regen: int = 0

## The physical damage reduction of the unit.
@export var armor: int = 0
## The magic damage reduction of the unit.
@export var magic_resist: int = 0

## The amount of flat armor penetration the unit has.
@export var armor_pen_flat: int = 0
## The amount of percentage armor penetration the unit has. (0 - 100)
@export var armor_pen_percent: int = 0

## The amount of flat magic penetration the unit has.
@export var magic_pen_flat: int = 0
## The amount of percentage magic penetration the unit has. (0 - 100)
@export var magic_pen_percent: int = 0

## The amount of physical damage the unit deals.
@export var attack_damage: int = 0
## The attack speed of the unit.
## Because of we need to use int for everything to prevent floating point errors,
## the attack speed is stored as 100 times the expected float value.
## This means that values below 100 are less than 1 attack per second,
## and values above 100 are more than 1 attack per second.
## Every 100 points is 1 attack per second.
@export var attack_speed: int = 0
## The attack range of the unit in centimeters.
## 100 centimeters is 1 meter for those now fluent in the metric system.
@export var attack_range: int = 0
## The chance of the unit to deal a critical strike in percentage (0 - 100).
@export var attack_crit_chance: int = 0
## The amount of bonus damage the unit deals on a critical strike in percentage (> 0)
@export var attack_crit_damage: int = 0

## The percentage of post-mitigation damage dealt by the unit that is returned as healing (0-100).
## To calculate the actual percentage the omnivamp value is added to the physical, magic and true vamp values depending on the damage type.
@export var omnivamp: int = 0
## The percentage of post-mitigation physical damage dealt by the unit that is returned as healing (0-100).
@export var physical_vamp: int = 0
## The percentage of post-mitigation magic damage dealt by the unit that is returned as healing (0-100).
@export var magic_vamp: int = 0
## The percentage of post-mitigation true damage dealt by the unit that is returned as healing (0-100).
@export var true_vamp: int = 0

## The movement speed of the unit in centimeters per second.
@export var movement_speed: int = 0


static func from_dict(json_data_object: Dictionary) -> StatCollection:
    var stat = StatCollection.new()
    
    stat.health_max = JsonHelper.get_optional_int(json_data_object, "health_max", 0)
    stat.health_regen = JsonHelper.get_optional_int(json_data_object, "health_regen", 0)

    stat.mana_max = JsonHelper.get_optional_int(json_data_object, "mana_max", 0)
    stat.mana_regen = JsonHelper.get_optional_int(json_data_object, "mana_regen", 0)

    stat.armor = JsonHelper.get_optional_int(json_data_object, "armor", 0)
    stat.magic_resist = JsonHelper.get_optional_int(json_data_object, "magic_resist", 0)

    stat.armor_pen_flat = JsonHelper.get_optional_int(json_data_object, "armor_pen_flat", 0)
    stat.armor_pen_percent = JsonHelper.get_optional_int(json_data_object, "armor_pen_percent", 0)

    stat.magic_pen_flat = JsonHelper.get_optional_int(json_data_object, "magic_pen_flat", 0)
    stat.magic_pen_percent = JsonHelper.get_optional_int(json_data_object, "magic_pen_percent", 0)

    stat.attack_damage = JsonHelper.get_optional_int(json_data_object, "attack_damage", 0)
    stat.attack_speed = JsonHelper.get_optional_int(json_data_object, "attack_speed", 0)
    stat.attack_range = JsonHelper.get_optional_int(json_data_object, "attack_range", 0)
    stat.attack_crit_chance = JsonHelper.get_optional_int(json_data_object, "attack_crit_chance", 0)
    stat.attack_crit_damage = JsonHelper.get_optional_int(json_data_object, "attack_crit_damage", 0)

    stat.omnivamp = JsonHelper.get_optional_int(json_data_object, "omnivamp", 0)
    stat.physical_vamp = JsonHelper.get_optional_int(json_data_object, "physical_vamp", 0)
    stat.magic_vamp = JsonHelper.get_optional_int(json_data_object, "magic_vamp", 0)
    stat.true_vamp = JsonHelper.get_optional_int(json_data_object, "true_vamp", 0)

    stat.movement_speed = JsonHelper.get_optional_int(json_data_object, "movement_speed", 0)
    
    return stat


func get_copy() -> StatCollection:
    var stat = StatCollection.new()
    stat.add(self)
    return stat


func add(other: StatCollection, times: int = 1):
    health_max += other.health_max * times
    health_regen += other.health_regen * times

    mana_max += other.mana_max * times
    mana_regen += other.mana_regen * times

    armor += other.armor * times
    magic_resist += other.magic_resist * times

    armor_pen_flat += other.armor_pen_flat * times
    armor_pen_percent += other.armor_pen_percent * times

    magic_pen_flat += other.magic_pen_flat * times
    magic_pen_percent += other.magic_pen_percent * times

    attack_damage += other.attack_damage * times
    attack_speed += other.attack_speed * times
    attack_range += other.attack_range * times
    attack_crit_chance += other.attack_crit_chance * times
    attack_crit_damage += other.attack_crit_damage * times
    
    movement_speed += other.movement_speed * times

    omnivamp += other.omnivamp * times
    physical_vamp += other.physical_vamp * times
    magic_vamp += other.magic_vamp * times
    true_vamp += other.true_vamp * times


func clamp_self(_min: StatCollection, _max: StatCollection):
    var new_vals : StatCollection = clamp(self, _min, _max)
    health_max = new_vals.health_max
    health_regen = new_vals.health_regen

    mana_max = new_vals.mana_max
    mana_regen = new_vals.mana_regen

    armor = new_vals.armor
    magic_resist = new_vals.magic_resist

    armor_pen_flat = new_vals.armor_pen_flat
    armor_pen_percent = new_vals.armor_pen_percent

    magic_pen_flat = new_vals.magic_pen_flat
    magic_pen_percent = new_vals.magic_pen_percent

    attack_damage = new_vals.attack_damage
    attack_speed = new_vals.attack_speed
    attack_range = new_vals.attack_range
    attack_crit_chance = new_vals.attack_crit_chance
    attack_crit_damage = new_vals.attack_crit_damage

    movement_speed = new_vals.movement_speed

    omnivamp = new_vals.omnivamp
    physical_vamp = new_vals.physical_vamp
    magic_vamp = new_vals.magic_vamp
    true_vamp = new_vals.true_vamp


func clamp_below(_max: StatCollection):
    clamp_self(StatCollection.new(), _max)


static func clamp(_stat: StatCollection, _min: StatCollection, _max: StatCollection) -> StatCollection:
    var stat := StatCollection.new()
    stat.health_max = clamp(_stat.health_max, _min.health_max, _max.health_max)
    stat.health_regen = clamp(_stat.health_regen, _min.health_regen, _max.health_regen)

    stat.mana_max = clamp(_stat.mana_max, _min.mana_max, _max.mana_max)
    stat.mana_regen = clamp(_stat.mana_regen, _min.mana_regen, _max.mana_regen)

    stat.armor = clamp(_stat.armor, _min.armor, _max.armor)
    stat.magic_resist = clamp(_stat.magic_resist, _min.magic_resist, _max.magic_resist)

    stat.armor_pen_flat = clamp(_stat.armor_pen_flat, _min.armor_pen_flat, _max.armor_pen_flat)
    stat.armor_pen_percent = clamp(_stat.armor_pen_percent, _min.armor_pen_percent, _max.armor_pen_percent)

    stat.magic_pen_flat = clamp(_stat.magic_pen_flat, _min.magic_pen_flat, _max.magic_pen_flat)
    stat.magic_pen_percent = clamp(_stat.magic_pen_percent, _min.magic_pen_percent, _max.magic_pen_percent)

    stat.attack_damage = clamp(_stat.attack_damage, _min.attack_damage, _max.attack_damage)
    stat.attack_speed = clamp(_stat.attack_speed, _min.attack_speed, _max.attack_speed)
    stat.attack_range = clamp(_stat.attack_range, _min.attack_range, _max.attack_range)
    stat.attack_crit_chance = clamp(_stat.attack_crit_chance, _min.attack_crit_chance, _max.attack_crit_chance)
    stat.attack_crit_damage = clamp(_stat.attack_crit_damage, _min.attack_crit_damage, _max.attack_crit_damage)

    stat.movement_speed = clamp(_stat.movement_speed, _min.movement_speed, _max.movement_speed)

    stat.omnivamp = clamp(_stat.omnivamp, _min.omnivamp, _max.omnivamp)
    stat.physical_vamp = clamp(_stat.physical_vamp, _min.physical_vamp, _max.physical_vamp)
    stat.magic_vamp = clamp(_stat.magic_vamp, _min.magic_vamp, _max.magic_vamp)
    stat.true_vamp = clamp(_stat.true_vamp, _min.true_vamp, _max.true_vamp)

    return stat


static func sum(stats: Array[StatCollection]) -> StatCollection:
    var result = StatCollection.new()
    for stat in stats:
        result.add(stat)
    
    return result
