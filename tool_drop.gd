extends ScrollContainer

@export var craft_ui: CraftUI


func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	data.src.remove_item_from_inventory(data.item)
	craft_ui.add_item_to_tool(data.item)


func move_item_from_inventory(item: Dictionary):
	craft_ui.remove_item_from_tool(item.name)
