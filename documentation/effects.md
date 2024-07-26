# Effects Object Format

Every effect in the game has the following properties, which define its behavior and characteristics:

- **base_id**: (string) The unique base identifier for the effect. This is used internally to reference the effect. Example: `"OnHitDamageEffect"`.
- **display_id**: (string) The unique display identifier for the effect. This is used for displaying the effect in the user interface. Example: `"openchamp:hidden_kunai_onhit"`.
- **is_exclusive**: (boolean) Indicates whether the effect is exclusive. If `true`, this effect cannot be combined with other effects of the same display_id. Example: `true`.

## Passive effects

Passive effects are a type of effect that do not require any additional properties beyond those defined in the base effects class.
They are always active and do not need to be triggered by manually by the player.

### OnHitDamageEffect

The `OnHitDamageEffect` is a type of passive effect that is triggered when a basic attack hits an enemy unit.
These effects are designed to enhance the damage output of basic attacks without triggering other on-hit effects.
They follow the same damage calculation rules as basic attack hits.

- **damage**: (number) The amount of damage dealt by the effect when it is triggered. This value is added to the damage of the basic attack. Example: `20`.
- **scaling**: (string) The formula used to calculate the scaling of the effect's damage. This formula can include variables such as the target's maximum health (`t.max.hp`). Detailed information about scaling formulas can be found in [scalings.md](scalings.md). Example: `"10 + 0.01 t.max.hp"`.
- **can_crit**: (boolean) Indicates whether the effect's damage can critically hit. If `true`, the effect's damage can be increased by critical hit multipliers. Example: `false`.
- **damage_type**: (string) The type of damage dealt by the effect. This can be used to determine how the damage interacts with various resistances and vulnerabilities. Example: `"physical"`.

The damage field is used as a fallback in case scaling can't be parsed or is not defined.
If scaling is parsed successfully then the damge field will be ignored.

#### Example

```json
{
    "base_id": "OnHitDamageEffect",
    "display_id": "openchamp:hidden_kunai_onhit",
    "is_exclusive": true,
    "damage": 20,
    "scaling": "10 + 0.01 t.max.hp",
    "can_crit": false,
    "damage_type": "true"
}
```