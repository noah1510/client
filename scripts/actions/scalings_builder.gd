class_name ScalingsBuilder

static func build_scaling_function(scalings_spec: String):
    if scalings_spec == "":
        return null

    var tokens = scalings_spec.split(" ")

    var base_value = float(tokens[0])
    
    var base_scaling = func(_caster, _target) -> float: return base_value

    return hanlde_tokens(base_scaling, tokens.slice(1))

    
static func hanlde_tokens(value: Callable, remaining_tokens):
    if remaining_tokens.is_empty():
        return value

    if remaining_tokens.size() < 3:
        print("Not enough tokens to handle")
        return null

    var next_operator = remaining_tokens[0]
    var next_operand = _get_next_scaled_stat(remaining_tokens.slice(1))

    if next_operand == null:
        return null

    var next_value
    match next_operator:
        "+":
            next_value = func(_caster, _target) -> float: return value.call(_caster, _target) + next_operand.call(_caster, _target)
        "-":
            next_value = func(_caster, _target) -> float: return value.call(_caster, _target) - next_operand.call(_caster, _target)
        "*", "X", "x":
            next_value = func(_caster, _target) -> float: return value.call(_caster, _target) * next_operand.call(_caster, _target)
        "/":
            next_value = func(_caster, _target) -> float: return value.call(_caster, _target) / next_operand.call(_caster, _target)
        _:
            print("Invalid operator")
            return null

    return hanlde_tokens(next_value, remaining_tokens.slice(3))
    

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
    match stat_spec[1]:
        "l", "lvl", "level":
            if actor == "caster":
                return func(_caster, _target) -> float: return next_scaling_value * _caster.level
            else:
                return func(_caster, _target) -> float: return next_scaling_value * _target.level
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
    
    if actor == "caster":
        if stat_set == "max":
            return func(_caster, _target) -> float: return next_scaling_value * stat_getter.call(_caster.maximum_stats)
        elif stat_set == "current":
            return func(_caster, _target) -> float: return next_scaling_value * stat_getter.call(_caster.current_stats)
        elif stat_set == "base":
            return func(_caster, _target) -> float: return next_scaling_value * stat_getter.call(_caster.base_stats)
    else:
        if stat_set == "max":
            return func(_caster, _target) -> float: return next_scaling_value * stat_getter.call(_target.maximum_stats)
        elif stat_set == "current":
            return func(_caster, _target) -> float: return next_scaling_value * stat_getter.call(_target.current_stats)
        elif stat_set == "base":
            return func(_caster, _target) -> float: return next_scaling_value * stat_getter.call(_target.base_stats)
