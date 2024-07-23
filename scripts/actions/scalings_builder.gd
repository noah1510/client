class_name ScalingsBuilder

static func build_scaling_function(scalings_spec: String):
	if scalings_spec == "":
		return null

	var tokens = scalings_spec.split(" ")

	var base_value = float(tokens[0])
	
	var base_scaling = func(_caster, _target) -> float: return base_value
	var base_display = func(_caster) -> String : return str(base_value)

	return hanlde_tokens(base_scaling, base_display, tokens.slice(1))

	
static func hanlde_tokens(value: Callable, display_func: Callable, remaining_tokens):
	if remaining_tokens.is_empty():
		return [value, display_func]

	if remaining_tokens.size() < 3:
		print("Not enough tokens to handle")
		return null

	var next_operator = remaining_tokens[0]
	var next_func = _get_next_scaled_stat(remaining_tokens.slice(1))

	if next_func == null:
		return null

	var next_operand = next_func[0]
	var next_display = next_func[1]

	var next_value
	var display_string
	match next_operator:
		"+":
			next_value = func(_caster, _target) -> float: return value.call(_caster, _target) + next_operand.call(_caster, _target)
			display_string = "%s + %s"
		"-":
			next_value = func(_caster, _target) -> float: return value.call(_caster, _target) - next_operand.call(_caster, _target)
			display_string = "%s - %s"
		"*", "X", "x":
			next_value = func(_caster, _target) -> float: return value.call(_caster, _target) * next_operand.call(_caster, _target)
			display_string = "%s * %s"
		"/":
			next_value = func(_caster, _target) -> float: return value.call(_caster, _target) / next_operand.call(_caster, _target)
			display_string = "%s / %s"
		_:
			print("Invalid operator")
			return null

	var next_display_func = func(_caster) -> String : return display_string % [display_func.call(_caster), next_display.call(_caster)]
	return hanlde_tokens(next_value, next_display_func, remaining_tokens.slice(3))
	

static func _get_next_scaled_stat(tokens):
	if tokens.size() < 2:
		print("Not enough tokens to get next scaled stat")
		return null

	var next_scaling_value = float(tokens[0])
	var next_scaling_stat = str(tokens[1])

	var stat_spec = next_scaling_stat.split(".")

	if stat_spec.size() < 2:
		print("Invalid stat spec")
		return null

	var actor = null
	match stat_spec[0]:
		"c","caster":
			actor = "caster"
		"t","target":
			actor = "target"
		_:
			print("Invalid actor")
			return null

	var stat_set = null
	var stat_func = null
	var display_func = null

	match stat_spec[1]:
		"l", "lvl", "level":
			if actor == "caster":
				stat_func = func(_caster, _target) -> float: return next_scaling_value * _caster.level
				display_func = func(_caster) -> String :
					return "%.3f caster level (%.3f = %.3f * %.3f)" % [
						next_scaling_value, next_scaling_value*_caster.level, next_scaling_value, float(_caster.level)
					]
				return [stat_func, display_func]
			else:
				stat_func = func(_caster, _target) -> float: return next_scaling_value * _target.level
				display_func = func(_caster) -> String : return "%.3f target level" % next_scaling_value
				return [stat_func, display_func]
		"m", "max":
			stat_set = "max"
		"c", "curr", "current":
			stat_set = "current"
		"b", "base":
			stat_set = "base"
		_:
			print("Invalid stat set")
			return null

	if stat_spec.size() < 3:
		print("Invalid stat spec, no stat name found")
		return null

	var stat_name = StatCollection.get_full_stat_name(stat_spec[2])
	var stat_getter = StatCollection.get_stat_getter(stat_name)
	var final_stat_getter = create_unit_stat_getter_func(stat_set, stat_getter)
	
	if actor == "caster":
		display_func = func(_caster) -> String :
			if _caster == null:
				return "%.3f caster %s %s" % [next_scaling_value, stat_set, stat_name]
			
			var stat_value = float(final_stat_getter.call(_caster))
			return "%.3f caster %s %s (%.3f = %.3f * %.3f)" % [
				next_scaling_value, stat_set, stat_name, next_scaling_value*stat_value, next_scaling_value, stat_value
			]

		stat_func = func(_caster, _target) -> float: return next_scaling_value * final_stat_getter.call(_caster)
	else:
		display_func = func(_caster) -> String : return "%.3f target %s %s" % [next_scaling_value, stat_set, stat_name]
		stat_func = func(_caster, _target) -> float: return next_scaling_value * final_stat_getter.call(_target)

	return [stat_func, display_func]


static func create_unit_stat_getter_func(stat_set: String, stat_getter: Callable) -> Callable:
	match stat_set:
		"max":
			return func(_unit) -> float: return stat_getter.call(_unit.maximum_stats)
		"current":
			return func(_unit) -> float: return stat_getter.call(_unit.current_stats)
		"base":
			return func(_unit) -> float: return stat_getter.call(_unit.base_stats)
		_:
			print("Invalid stat set " + stat_set)
			return func(_unit) -> float: return 0.0
