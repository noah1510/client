class_name Item extends Object

var gold_cost: int = 0
var components: Array[String] = []
var item_tier: int = -1

var stats = StatCollection.new()

var id: Identifier
var texture_id: Identifier


func get_copy() -> Item:
	var new_item = Item.new(id, texture_id, gold_cost, components, stats)
	new_item.item_tier = item_tier
	return new_item


func get_id() -> Identifier:
	return id


func get_desctiption_strings() -> Dictionary:
	var item_descriptions = {}
	item_descriptions["name"] = tr("ITEM:%s:NAME" % id.to_string())
	item_descriptions["lore"] = tr("ITEM:%s:LORE" % id.to_string())
	item_descriptions["cost"] = tr("ITEM:COST_LABEL") % calculate_gold_cost()

	var stats_dict = stats.to_dict()
	var item_stat_string = ""
	for stat in stats_dict.keys():
		var stat_value = stats_dict[stat]
		if stat_value == 0:
			continue
		
		item_stat_string += tr("STAT:%s:NAME" % stat) + ": " + str(stats_dict[stat]) + "\n"

	item_descriptions["stats"] = item_stat_string

	return item_descriptions


func get_texture_resource() -> Identifier:
	if texture_id.is_valid():
		if AssetIndexer.get_asset_path(texture_id) != "":
			return texture_id
	
	print("Item (%s): Texture asset not found." % id.to_string())
	return Identifier.for_resource("texture://openchamp:placeholder")


func get_stats() -> StatCollection:
	return stats


func get_combine_cost() -> int:
	return gold_cost


func calculate_gold_cost() -> int:
	var cost = gold_cost
	for component in components:
		var item = RegistryManager.items().get(component)
		if item == null:
			print("Item (%s): Component item not found." % component)
			continue
		
		cost += item.calculate_gold_cost()

	return cost


func is_valid(item_registry: RegistryBase = null) -> bool:
	# This is a fast pass to avoid checking the item's components if it's already been validated
	# By default the item_tier is set to -1, so if it's not negative, it's already been validated
	if item_tier >= 0:
		return true
	
	if item_registry == null:
		item_registry = RegistryManager.items()

	if not id.is_valid():
		return false

	if not texture_id.is_valid():
		return false

	if gold_cost < 0:
		return false

	var highest_tier = -1
	if components.size() > 0:
		for component in components:
			if not Identifier.from_string(component).is_valid():
				return false

			if not item_registry.contains(component):
				return false

			var comp_item = item_registry.get_element(component)
			if comp_item.item_tier < 0:
				if not comp_item.is_valid(item_registry):
					return false
			
			if comp_item.item_tier > highest_tier:
				highest_tier = comp_item.item_tier
			
	item_tier = highest_tier + 1

	return true


func _init(
	_id: Identifier,
	_texture_id: Identifier,
	_gold_cost: int,
	_components: Array[String],
	_stats: StatCollection
):
	id = _id
	texture_id = _texture_id
	gold_cost = _gold_cost
	components = _components
	stats = _stats

	