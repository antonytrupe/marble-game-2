extends Control

#@export var inventory: Dictionary = {}:
#set = update_inventory
const INVENTORY_SLOT_SCENE: Resource = preload("res://inventory_slot.tscn")

@export var me: MarbleCharacter
var my_inventory_slots = {}

@onready var my_items = %ItemList


func _on_inventory_slot_pressed(slot: InventorySlot) -> void:
	print("clicked on %s" % slot.category)


func update():
	#print('inventory update:',player.inventory)
	for category in me.inventory:
		for item in me.inventory[category].items.values():
			add_item_to_inventory(item)


func add_item_to_inventory(item: Dictionary):
	if !(item.category in my_inventory_slots):
		var new_slot: InventorySlot = INVENTORY_SLOT_SCENE.instantiate()
		#new_slot.items = {}
		new_slot.type_scene_file_path = item.scene_file_path
		#new_slot.items=me.inventory[ii].items
		my_inventory_slots[item.category] = new_slot
		my_items.add_child(new_slot)
		new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))

	my_inventory_slots[item.category].add_item(item)
