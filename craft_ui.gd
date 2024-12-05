extends Panel
const INVENTORY_SLOT_SCENE = preload("res://inventory_slot_2.tscn")

@export var me: MarbleCharacter
var my_inventory_slots = {}
var my_craft_slots = {}
var tool = null
var craft_inventory = {}
@onready var tool_slot: InventorySlot = %Tool
@onready var my_items = %MyInventory
@onready var my_craft_items = %MyCrafts


func _ready() -> void:
	tool_slot.pressed.connect(_on_tool_slot_pressed)
	update()


@rpc("any_peer", "call_remote")
func update() -> void:
	my_inventory_slots = {}
	for c in my_items.get_children():
		my_items.remove_child(c)
		c.queue_free()

	my_craft_slots = {}
	for c in my_craft_items.get_children():
		my_craft_items.remove_child(c)
		c.queue_free()

	if tool:
		tool_slot.remove_item(tool)
		tool = null

	#print('craftui update',me.inventory)
	for category in me.inventory:
		for item in me.inventory[category].items.values():
			add_item_to_inventory(item)


func add_item_to_inventory(item: Dictionary):

	var new_slot: InventorySlot2 = INVENTORY_SLOT_SCENE.instantiate()
	new_slot.item =item
	#new_slot.items=me.inventory[ii].items
	my_inventory_slots[item.name] = new_slot
	my_items.add_child(new_slot)
	#new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))


func remove_item_from_inventory(category: String) -> Dictionary:
	var slot: InventorySlot = my_inventory_slots[category]
	var item = slot.get_items().values()[0]
	slot.remove_item(item)
	slot.update()

	if slot.size() == 0:
		my_inventory_slots.erase(category)
		slot.hide()
		slot.queue_free()

	return item


func add_item_to_tool(item: Dictionary):
	tool_slot.type_scene_file_path = item.scene_file_path
	tool_slot.add_item(item)
	tool = item
	#TODO update the actions buttonss


func remove_item_from_tool() -> Dictionary:
	tool_slot.remove_item(tool)

	var t = tool
	tool = null
	return t


func add_item_to_craft(item: Dictionary):
	if !(item.category in my_craft_slots):
		var new_slot: InventorySlot2 = INVENTORY_SLOT_SCENE.instantiate()
		#new_slot.items = {}
		new_slot.type_scene_file_path = item.scene_file_path
		#new_slot.items=me.inventory[ii].items
		my_craft_slots[item.category] = new_slot
		my_craft_items.add_child(new_slot)
		new_slot.pressed.connect(_on_craft_slot_pressed.bind(new_slot))

		craft_inventory[item.category] = {items = {}}

	craft_inventory[item.category].items[item.name] = item
	my_craft_slots[item.category].add_item(item)


func remove_item_from_craft(category: String) -> Dictionary:
	var slot: InventorySlot = my_craft_slots[category]
	var item = slot.get_items().values()[0]
	slot.remove_item(item)
	slot.update()

	if slot.size() == 0:
		my_craft_slots.erase(category)
		slot.hide()
		slot.queue_free()

	craft_inventory[item.category].items.erase(item.name)

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
	me.craft.rpc_id(1, "craft", tool, craft_inventory)
	update()
