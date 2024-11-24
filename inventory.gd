extends Control

#@export var inventory: Dictionary = {}:
#set = update_inventory

@export var player: MarbleCharacter

@onready var list = %ItemList
const inventory_slot_scene = preload("res://inventory_slot.tscn")

var slots = {}


func _on_inventory_slot_pressed(slot) -> void:
	pass  # Replace with function body.
	print("clicked on %s" % slot.item)


func update():
	#print('inventory update:',player.inventory)
	for ii in player.inventory:
		if !ii in slots:
			var new_slot:InventorySlot = inventory_slot_scene.instantiate()
			new_slot.type = ii
			new_slot.type_scene_file_path=player.inventory[ii].scene_file_path
			slots[ii] = new_slot
			list.add_child(new_slot)
			new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))

		slots[ii].quantity = player.inventory[ii].quantity
