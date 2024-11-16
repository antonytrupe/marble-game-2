extends Control

@export var inventory: Dictionary = {}:
	set = update_inventory

@onready var list = %ItemList
const inventory_slot_scene = preload("res://inventory_slot.tscn")

var slots = {}


func update_inventory(i):
	print(" inventory update_inventory", i)
	inventory = i
	for ii in inventory:
		print(ii)
		if !ii in slots:
			var new_slot = inventory_slot_scene.instantiate()
			new_slot.item = ii
			slots[ii] = new_slot
			list.add_child(new_slot)

		slots[ii].quantity = inventory[ii].quantity


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
