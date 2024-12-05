extends Control

const INVENTORY_SLOT_SCENE: Resource = preload("res://inventory_slot_2.tscn")

@export var me: MarbleCharacter
var my_inventory_slots = {}

@onready var my_items = %ItemList


func _on_inventory_slot_pressed(slot: InventorySlot2) -> void:
	print("clicked on %s" % slot.item.category)


func update():
	for category in me.inventory:
		for item in me.inventory[category].items.values():
			add_item_to_inventory(item)


func add_item_to_inventory(item: Dictionary):
	if !(item.name in my_inventory_slots):
		var new_slot: InventorySlot2 = INVENTORY_SLOT_SCENE.instantiate()
		#new_slot.items = {}
		new_slot.item = item
		#new_slot.items=me.inventory[ii].items
		my_inventory_slots[item.name] = new_slot
		my_items.add_child(new_slot)
		#new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))
