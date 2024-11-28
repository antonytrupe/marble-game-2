extends Control

#@export var inventory: Dictionary = {}:
#set = update_inventory

@export var me: MarbleCharacter

@onready var myItems = %ItemList
const inventory_slot_scene: Resource = preload("res://inventory_slot.tscn")

var myInventorySlots = {}


func _on_inventory_slot_pressed(slot: InventorySlot) -> void:
	pass # Replace with function body.
	print("clicked on %s" % slot.category)


func update():
	#print('inventory update:',player.inventory)
	for category in me.inventory:
		for item in me.inventory[category].items.values():
			add_item_to_inventory(item)


func add_item_to_inventory(item: Dictionary):
	if !(item.category in myInventorySlots):
		var new_slot: InventorySlot = inventory_slot_scene.instantiate()
		#new_slot.items = {}
		new_slot.type_scene_file_path = item.scene_file_path
		#new_slot.items=me.inventory[ii].items
		myInventorySlots[item.category] = new_slot
		myItems.add_child(new_slot)
		new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))

	myInventorySlots[item.category].add_item(item)
