extends PanelContainer

const INVENTORY_SLOT_SCENE: Resource = preload("res://inventory_slot.tscn")

@export var inventory_slot: InventorySlot


func _get_drag_data(_at_position: Vector2) -> Variant:
	var drag = INVENTORY_SLOT_SCENE.instantiate()
	drag.item = inventory_slot.item
	set_drag_preview(drag)
	return {
		item = inventory_slot.item,
		src = inventory_slot.src,
	}
