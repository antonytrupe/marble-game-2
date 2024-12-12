extends VBoxContainer

@export var trade_ui: PlayerInteraction


func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	trade_ui.add_item_to_trade.rpc_id(1, data.item)
	data.src.move_item_from_inventory(data.item)


func move_item_from_inventory(item: Dictionary):
	trade_ui.remove_item_from_trade.rpc_id(1, item.name)
