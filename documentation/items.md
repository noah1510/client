# Item JSON File Format

This document describes the format for an item JSON file used in the game.
These item json files specify all the details about the job of an item, its stats and the way it get's crafted.

## Root Object

- **type**: (string) The type of the object. For items, this is always `"item"`.
- **format_version**: (string) The version of the format. Example: `"1"`.
- **data**: (string) The actual item data (see below).

## Data Object

- **id**: (string) The unique identifier for the item. Example: `"openchamp:hidden_kunai"`.
- **texture**: (string) The path to the texture for the item. Example: `"openchamp:items/hidden_kunai"`.
- **recipe**: (object) The crafting recipe for the item.
  - **gold_cost**: (number) The gold cost to combine or purchase the item. Example: `500`.
  - **components**: (array of strings) The components required to craft the item. Example: `["openchamp:old_bow", "openchamp:old_bow"]`.
- **stats**: (object) The stats provided by the item. See the [Stats Object Format](stats.md) section for details.
- **effects**: (array of objects) The effects applied by the item. See the [Effects Object Format](effects.md) section for details.

### Extra info regarding textures

The texture field uses texture assets ids.
If the texture field contains `"openchamp:items/hidden_kunai"` the game will request `"texture://openchamp:items/hidden_kunai"` from the asset loader.
In this case the loaded texture will be `"openchamp/textures/items/hidden_kunai.png"`.
If the texture doesn't exist a fallback texture will be used.
This is done to ensure that the clients will not crash even with missing display data.

## Example

```json
{
    "type": "item",
    "format_version": "1",
    "data": {
        "id": "openchamp:hidden_kunai",
        "texture": "openchamp:items/hidden_kunai",
        "recipe": {
            "gold_cost": 500,
            "components": [
                "openchamp:old_bow",
                "openchamp:old_bow"
            ]
        },
        "stats": {
            "attack_speed": 20
        },
        "effects": [
            {
                "base_id": "OnHitDamageEffect",
                "display_id": "openchamp:hidden_kunai_onhit",
                "is_exclusive": true,
                "damage": 20,
                "scaling": "10 + 0.01 t.max.hp",
                "can_crit": false,
                "damage_type": "true"
            }
        ]
    }
}
```