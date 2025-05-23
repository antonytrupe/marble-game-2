class_name PlayerInventory
extends Panel

const INVENTORY_SLOT_SCENE: Resource = preload("res://ui/inventory/inventory_slot.tscn")

@export var me: MarbleCharacter
var my_inventory_slots = {}

@onready var my_items = %ItemList
@onready var game: Game = $/root/Game


func _unhandled_input(event):
	game._unhandled_input(event)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	data.src.move_item_from_inventory(data.item)
	add_item_to_inventory(data.item)


##client code
@rpc("authority")
func reset():

	# clear local data structures
	my_inventory_slots = {}

	#clear ui
	for child in my_items.get_children():
		my_items.remove_child(child)
		child.queue_free()

	#rebuild
	if me:
		for item in me.inventory.values():
			add_item_to_inventory(item)


func remove_item_from_inventory(item: Dictionary):
	my_items.remove_child(my_inventory_slots[item.name])
	my_inventory_slots[item.name].queue_free()
	my_inventory_slots.erase(item.name)


func add_item_to_inventory(item: Dictionary):
	if !(item.name in my_inventory_slots):
		var new_slot: InventorySlot = INVENTORY_SLOT_SCENE.instantiate()
		new_slot.src = self
		#new_slot.item = item
		my_inventory_slots[item.name] = new_slot
		my_items.add_child(new_slot)

	my_inventory_slots[item.name].item=item
	my_inventory_slots[item.name].update_label()
