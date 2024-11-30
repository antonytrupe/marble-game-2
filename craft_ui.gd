extends Node2D
const INVENTORY_SLOT_SCENE = preload("res://inventory_slot.tscn")

@export var me: MarbleCharacter
var myInventorySlots = {}
var myCraftSlots = {}
var tool = null
var craftInventory = {}
@onready var toolSlot: InventorySlot = %Tool
@onready var myItems = %MyInventory
@onready var myCraftItems = %MyCrafts


func _ready() -> void:
	toolSlot.pressed.connect(_on_tool_slot_pressed)
	update()


@rpc("any_peer", "call_remote")
func update() -> void:
	myInventorySlots = {}
	for c in myItems.get_children():
		myItems.remove_child(c)
		c.queue_free()

	myCraftSlots = {}
	for c in myCraftItems.get_children():
		myCraftItems.remove_child(c)
		c.queue_free()

	if tool:
		toolSlot.remove_item(tool)
		tool = null

	#print('craftui update',me.inventory)
	for category in me.inventory:
		for item in me.inventory[category].items.values():
			add_item_to_inventory(item)


func add_item_to_inventory(item: Dictionary):
	if !(item.category in myInventorySlots):
		var new_slot: InventorySlot = INVENTORY_SLOT_SCENE.instantiate()
		#new_slot.items = {}
		new_slot.type_scene_file_path = item.scene_file_path
		#new_slot.items=me.inventory[ii].items
		myInventorySlots[item.category] = new_slot
		myItems.add_child(new_slot)
		new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))

	myInventorySlots[item.category].add_item(item)


func remove_item_from_inventory(category: String) -> Dictionary:
	var slot: InventorySlot = myInventorySlots[category]
	var item = slot.get_items().values()[0]
	slot.remove_item(item)
	slot.update()

	if slot.size() == 0:
		myInventorySlots.erase(category)
		slot.hide()
		slot.queue_free()

	return item


func add_item_to_tool(item: Dictionary):
	toolSlot.type_scene_file_path = item.scene_file_path
	toolSlot.add_item(item)
	tool = item
	#TODO update the actions buttonss


func remove_item_from_tool() -> Dictionary:
	toolSlot.remove_item(tool)

	var t = tool
	tool = null
	return t


func add_item_to_craft(item: Dictionary):
	if !(item.category in myCraftSlots):
		var new_slot: InventorySlot = INVENTORY_SLOT_SCENE.instantiate()
		#new_slot.items = {}
		new_slot.type_scene_file_path = item.scene_file_path
		#new_slot.items=me.inventory[ii].items
		myCraftSlots[item.category] = new_slot
		myCraftItems.add_child(new_slot)
		new_slot.pressed.connect(_on_craft_slot_pressed.bind(new_slot))

		craftInventory[item.category] = {items = {}}

	craftInventory[item.category].items[item.name] = item
	myCraftSlots[item.category].add_item(item)


func remove_item_from_craft(category: String) -> Dictionary:
	var slot: InventorySlot = myCraftSlots[category]
	var item = slot.get_items().values()[0]
	slot.remove_item(item)
	slot.update()

	if slot.size() == 0:
		myCraftSlots.erase(category)
		slot.hide()
		slot.queue_free()

	craftInventory[item.category].items.erase(item.name)

	return item


func _on_tool_slot_pressed():
	var item = remove_item_from_tool()
	add_item_to_inventory(item)
	#update()


func _on_inventory_slot_pressed(slot: InventorySlot) -> void:
	var item = remove_item_from_inventory(slot.category)
	if !tool:
		add_item_to_tool(item)

	else:
		add_item_to_craft(item)
	#update()


func _on_craft_slot_pressed(slot: InventorySlot) -> void:
	var item = remove_item_from_craft(slot.category)
	add_item_to_inventory(item)
	#update()


func _on_craft_pressed() -> void:
	if !tool:
		print("no tool item")
		return
	me.craft.rpc_id(1, "craft", tool, craftInventory)
	update()
