# Stats Object Format

The `StatCollection` class is used to store all the stats of a unit. All stats are stored as integers to prevent floating point errors.
StatCollections can be created from parsing json stats objects.
If a stat is missing in an object a default value (ususally 0) will be used.

## Stat List

- **health**: The actual health value of the unit.
- **health_regen**: The amount of health the unit regenerates per 5 seconds.
- **mana**: The actual mana value of the unit.
- **mana_regen**: The amount of mana the unit regenerates per 5 seconds.
- **armor**: The physical damage reduction of the unit.
- **magic_resist**: The magic damage reduction of the unit.
- **armor_pen_flat**: The amount of flat armor penetration the unit has.
- **armor_pen_percent**: The amount of percentage armor penetration the unit has. (0 - 100)
- **magic_pen_flat**: The amount of flat magic penetration the unit has.
- **magic_pen_percent**: The amount of percentage magic penetration the unit has. (0 - 100)
- **attack_damage**: The amount of physical damage the unit deals.
- **attack_speed**: The attack speed of the unit. Stored as 100 times the expected float value. Values below 100 are less than 1 attack per second, and values above 100 are more than 1 attack per second. Every 100 points is 1 attack per second.
- **attack_range**: The attack range of the unit in centimeters. 100 centimeters is 1 meter.
- **attack_crit_chance**: The chance of the unit to deal a critical strike in percentage (0 - 100).
- **attack_crit_damage**: The amount of bonus damage the unit deals on a critical strike in percentage (> 0).
- **ability_power**: The amount of ability power the unit has. Ability power is used to increase the damage of abilities that scale with ability power.
- **ability_haste**: The amount of ability haste the unit has. Ability haste is used to reduce the cooldown of abilities. Every 100 points of ability haste allow the unit to cast the ability one more time per stock cooldown.
- **omnivamp**: The percentage of post-mitigation damage dealt by the unit that is returned as healing (0-100). The omnivamp value is added to the physical, magic, and true vamp values depending on the damage type.
- **physical_vamp**: The percentage of post-mitigation physical damage dealt by the unit that is returned as healing (0-100).
- **magic_vamp**: The percentage of post-mitigation magic damage dealt by the unit that is returned as healing (0-100).
- **true_vamp**: The percentage of post-mitigation true damage dealt by the unit that is returned as healing (0-100).
- **movement_speed**: The movement speed of the unit in centimeters per second.

## Example

```json
{
    "health": 200,
    "health_regen": 0,

    "mana": 280,
    "mana_regen": 7,
    
    "armor": 26,
    "magic_resist": 30,

    "attack_range": 150,
    "attack_damage": 40,
    "attack_speed": 75,
    "attack_crit_chance": 0,
    "attack_crit_damage": 10,

    "movement_speed": 300
}
```

