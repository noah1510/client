extends Control

@onready var item_lists_container : BoxContainer = $ScrollContainer/ItemListsContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var item_tiers : int = RegistryManager.items().highest_item_tier
	print("Item tiers in shop: %d" % item_tiers)
	
	if item_tiers < 0:
		print("no valid item in registry, can't show shop")
		return
	
	for item_tier in range(item_tiers + 1):
		var all_in_tier : Array[Item] = RegistryManager.items().get_all_in_tier(item_tier)
		
		if all_in_tier.is_empty():
			continue
		
		item_lists_container.add_child(HSeparator.new())
		var tier_label = Label.new()
		tier_label.name = "Item_tier_label_%d" % item_tier
		tier_label.text = "Tier %d" % item_tier
		item_lists_container.add_child(tier_label)
		
		item_lists_container.add_child(HSeparator.new())
		
		var _item_tier_box = FlowContainer.new()
		_item_tier_box.name = "Item_tier_flow_%d" % item_tier
		
		for _item in all_in_tier:
			var item_desctiptions = _item.get_desctiption_strings()
			
			var texture_resource = _item.get_texture_resource()
			var item_texture = load(AssetIndexer.get_asset_path(texture_resource))
			if item_texture == null:
				print("Item (%s): Texture (%s) not found." % [item_desctiptions["name"], texture_resource.to_string()])
				continue

			var item_image = TextureRect.new()
			item_image.texture = item_texture
			item_image.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
			item_image.stretch_mode = TextureRect.STRETCH_SCALE
			item_image.tooltip_text = "%s\n%s\n\n%s\n%s" % [
				item_desctiptions["name"],
				item_desctiptions["lore"],
				item_desctiptions["stats"],
				item_desctiptions["cost"]
			]
			item_image.mouse_filter = Control.MOUSE_FILTER_STOP

			var item_container = AspectRatioContainer.new()
			item_container.size = Vector2(64, 64)
			item_container.custom_minimum_size = Vector2(64, 64)
			item_container.add_child(item_image)

			_item_tier_box.add_child(item_container)
		
		item_lists_container.add_child(_item_tier_box)
		
		if item_tier != item_tiers:
			item_lists_container.add_child(HSeparator.new())
		
	item_lists_container.add_child(HSeparator.new())
	item_lists_container.add_spacer(false)

	hide()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("player_open_shop"):
		return
	
	if visible:
		hide()
		Config.in_focued_menu = false
	else:
		# make sure we aren't already in a different menu
		if Config.in_focued_menu:
			return
		
		show()
		Config.in_focued_menu = true
