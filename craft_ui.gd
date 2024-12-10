class_name CraftUI
extends Panel

const INVENTORY_SLOT_SCENE = preload("res://inventory_slot_2.tscn")

@export var me: MarbleCharacter

var reagent_slots = {}
var reagent_inventory = {}
var tool_slots = {}
var tool_inventory = {}
@onready var tool_container = %ToolSlot
@onready var reagent_container = %MyCraftReagents


func _unhandled_input(event):
	me._unhandled_input(event)


func reset():
	me.reset_inventory_ui()
	reagent_slots = {}
	reagent_inventory = {}
	tool_slots = {}
	tool_inventory = {}
	for c in reagent_container.get_children():
		reagent_container.remove_child(c)
		c.queue_free()
	for c in tool_container.get_children():
		tool_container.remove_child(c)
		c.queue_free()


func add_item_to_tool(item: Dictionary):
	if !(item.name in tool_slots):
		var new_slot: InventorySlot2 = INVENTORY_SLOT_SCENE.instantiate()
		new_slot.item = item
		new_slot.src = tool_container.get_parent()
		tool_slots[item.name] = new_slot
		tool_container.add_child(new_slot)

		tool_inventory[item.name] = item


func remove_item_from_tool(item_name: String):
	var slot: InventorySlot2 = tool_slots[item_name]
	slot.hide()
	slot.queue_free()
	tool_slots.erase(item_name)
	tool_inventory.erase(item_name)


func add_item_to_reagents(item: Dictionary):
	if !(item.name in reagent_slots):
		var new_slot: InventorySlot2 = INVENTORY_SLOT_SCENE.instantiate()
		new_slot.item = item
		new_slot.src = reagent_container.get_parent()
		new_slot.item = item
		reagent_slots[item.name] = new_slot
		reagent_container.add_child(new_slot)
		#new_slot.pressed.connect(_on_craft_slot_pressed.bind(new_slot))

		reagent_inventory[item.name] = item


func remove_item_from_reagent(item_name: String):
	var slot: InventorySlot2 = reagent_slots[item_name]
	slot.hide()
	slot.queue_free()
	reagent_slots.erase(item_name)
	reagent_inventory.erase(item_name)


func _on_craft_pressed() -> void:
	print("_on_craft_pressed")
	if tool_inventory.size() == 0:
		print("no tool item")
		return
	me.craft.rpc_id(1, "craft", tool_inventory[0], reagent_inventory)
	reset()


func _on_hidden() -> void:
	reset()
