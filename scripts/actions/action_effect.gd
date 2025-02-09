extends Node

## The base class for all action effects.
## [br][br]
## This class creates a common interface for all action effects
## and provides some basic functionality that all action effects
## should have.
## [br][br]
## Actions effects are used to define the effects of actions
## that can be performed by units in the game.
## These effects can both be active and passive and can have
## a wide range of effects on the game world.
## [br][br]
## This class is meant to be extended by other classes that
## implement specific action effects.
class_name ActionEffect


## The activation state of the action effect
## [br][br]
## This is used to determine what the action effect is currently doing
## and what it should do next upon activation.
## Note that this set of states is not exhaustive and might get extended
## in the future. Don't rely on the exact values of this enum.
enum ActivationState{
	## Indicates that the action effect is not doing anything
	NONE,
	## Indicates that the action effect is ready to be activated
	READY,
	## Indicates that the action effect is currently in the targeting phase
	## This is used to make sure that only one effect shows a range indicator at a time
	TARGETING,
	## Indicates that the action effect is currently channeling
	## This means that the ability is currently having an effect on the game world
	## but will be interrupted if the caster is interrupted or moves.
	CHANNELING,
	## Indicates that the action effect is currently active.
	## This state is used for effects that have a duration and are not interrupted by movement.
	## The state will decay into the COOLDOWN or READY state once the duration is over.
	ACTIVE,
	## Indicates that the action effect is currently on cooldown.
	## The on_activation function should just do nothing in this state.
	COOLDOWN
}


## The type of an an active ability.
## [br][br]
## This is used to determine how certain effects should be applied.
## For example, a single targeted ability should only affect one target
## while an area untargeted ability should affect all units in an area.
enum AbilityType{
	## Indicates that the ability is passive and can not be activated.
	PASSIVE,
	## Indicates that the ability is targeted and can only affect one unit.
	## In other words this is a point and click ability.
	SINGLE_TARGETED,
	## Point and click ability that can affect multiple units.
	## This is used mostly for abilities that potentially hit multiple units but are not area effects.
	MULTILE_TARGETED,
	## Indicates that the ability is untargeted but only affects one unit.
	SINGLE_UNTARGETED,
	## Indicates that an ability affects all units in an area but disappears after one use.
	AREA_ONETIME,
	## Indicates that an ability affects all units in an area and stays active for a duration.
	## These DOT effects will be applied in regular intervals and on first contact.
	AREA_CONTINUOUS
}


# Common fields for all action effects
# These are all protected fields and should not be accessed directly
# outside of the action effect class and its subclasses.


## The current activation state of the action effect
var _activation_state: ActivationState = ActivationState.NONE


## The type of ability described by the action effect
var _ability_type: AbilityType = AbilityType.PASSIVE


## Indicates if the action effect has been loaded and is ready to be used
## This should be false until _from_dict has been called
var _is_loaded: bool = false


## The display id of the action effect
## This field is used to have a unique name for action effects
## created by the same action effect subclass.
## This is used to as the translation key for the action effect
## and to identify the action effect in the game world.
## This field is set in the generic _from_dict function.
var _display_id: Identifier = null


## Indicates if the action effect is exclusive.
## This means a unit can only have one effect with the
## same display id active at a time.
## This is set in the generic _from_dict function and optional.
var _is_exclusive: bool = false


## Create a new action effect from a dictionary
## This will load the action effect based on the class name,
## which has to be in the dictionary and be a subclass of ActionEffect.
## The dictionary should contain all the data needed to create the
## specific action effect subclass.
## The return value should be the new action effect instance or null if the
## creation failed.
static func from_dict(_dict: Dictionary) -> ActionEffect:
	if not _dict.has("base_id"):
		print("Could not create action effect from dictionary. Dictionary has no base_id key.")
		return null

	var _instance : ActionEffect = null
	match _dict["base_id"]:
		"ActionEffect":
			print("Could not create action effect from dictionary. Class is the base class: " + _dict["base_id"])
			return null
		"OnHitDamageEffect":
			_instance = OnHitDamageEffect.new()
		
		_:
			print("Invalid action effect class name: " + _dict["base_id"])
			return null

	if not _dict.has("display_id"):
		print("Could not create action effect from dictionary. Dictionary has no display_id key.")
		return null

	_instance._display_id = Identifier.from_string(str(_dict["display_id"]))
	_instance._is_exclusive = JsonHelper.get_optional_bool(_dict, "is_exclusive", false)

	if not _instance._from_dict(_dict):
		print("Could not create action effect from dictionary. Could not load data.")
		return null
	
	return _instance


# The getter functions for the action effect


## Get the current activation state of the action effect
func get_activation_state() -> ActivationState:
	return _activation_state


## Get the type of ability described by the action effect
func get_ability_type() -> AbilityType:
	return _ability_type


## Check if the action effect has been loaded and is ready to be used
## This should always be true if an action effect has been created
## succefully with from_dict.
func is_loaded() -> bool:
	return _is_loaded


## Get the display id of the action effect.
## Use this to identify the action effect in the game world.
## This is used as the translation key for the action effect,AbilityType
## to find an icon for the action effect and much more.
func get_display_id() -> Identifier:
	return _display_id


## Check if the action effect is exclusive.
## Use this to prevent shop purchases and other actions
## that would add an effect with the same display id to a unit.
func is_exclusive() -> bool:
	return _is_exclusive


## Attach the action effect to a unit.
## This should be called when the action effect is added to a unit.
## It will connect to all the signals needed to make the action effect work.
func connect_to_unit(_unit: Unit) -> void:
	pass


func disconnect_from_unit(_unit: Unit) -> void:
	pass


func get_description_string(_caster: Unit) -> String:
	return tr("ACTION_EFFECT:%s" % _display_id.to_string())


## Actually load the action effect from a dictionary.
## The dictionary should contain all the data needed to create the
## specific action effect subclass.
## The return value should be true if the loading was successful
func _from_dict(_dict: Dictionary) -> bool:
	return false


func get_copy() -> ActionEffect:
	print("ActionEffect.get_copy() is not implemented.")
	return null
