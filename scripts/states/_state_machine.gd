extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary = {}
@onready var entity = get_parent();


func _ready():
	for state in get_children():
		if state is State:
			states[state.name] = state
			state.change.connect(change_state)
			
	if initial_state != null:
		initial_state.enter(entity);
		current_state = initial_state


func _process(delta):
	if not current_state: return
	current_state.update(entity, delta);


func _physics_process(delta):
	if not current_state: return
	if multiplayer.is_server():
		current_state.update_tick_server(entity, delta)
	else:
		current_state.update_tick_client(entity, delta)
	

func change_state(new_state_name, args = null):
	if not states.has(new_state_name): return
	
	var new_state = states[new_state_name]
	if current_state == new_state:
		print("Updating state " + new_state_name + " of "  + entity.name)
		current_state.modify(entity, args)
		return
		
	print("Changing " + entity.name + " to " + new_state_name)
	
	if current_state != null:
		current_state.exit(entity)
	
	new_state.enter(entity, args)
	current_state = new_state
	
