extends PanelContainer

const INVENTORY_SLOT_SCENE: Resource = preload("res://inventory_slot_2.tscn")

@export var inventory_slot: InventorySlot2


func _get_drag_data(_at_position: Vector2) -> Variant:
	var drag = INVENTORY_SLOT_SCENE.instantiate()
	drag.item = inventory_slot.item
	set_drag_preview(drag)
	return {
		item = inventory_slot.item,
		src = inventory_slot.src,
	}
