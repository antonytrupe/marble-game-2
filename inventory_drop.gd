extends Control

@export var inventory_ui: PlayerInventory


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	data.src.move_item_from_inventory(data.item)
	inventory_ui.add_item_to_inventory(data.item)
