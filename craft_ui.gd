extends Node2D

@export var me: MarbleCharacter
@onready var myItems = %MyInventory
@onready var myCraftItems = %MyCrafts
var myInventorySlots = {}
var myCraftSlots = {}
var tool = null
@onready var toolSlot: InventorySlot = %Tool
var crafting = {}
const inventory_slot_scene = preload("res://inventory_slot.tscn")


func _ready() -> void:
	toolSlot.pressed.connect(_on_tool_slot_pressed.bind(toolSlot))
	update()


func update() -> void:
	#my inventory
	for ii in me.inventory:
		if !ii in myInventorySlots:
			var new_slot: InventorySlot = inventory_slot_scene.instantiate()
			new_slot.type = ii
			new_slot.type_scene_file_path = me.inventory[ii].scene_file_path

			#new_slot.items=me.inventory[ii].items
			myInventorySlots[ii] = new_slot
			myItems.add_child(new_slot)
			new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))

		myInventorySlots[ii].quantity = me.inventory[ii].quantity
		#var craft_quantity = 0
		if ii in crafting:
			myInventorySlots[ii].quantity = me.inventory[ii].quantity - crafting[ii].quantity

		if tool and tool .type == ii:
			myInventorySlots[ii].quantity -= tool .quantity

		if myInventorySlots[ii].quantity <= 0:
			#delete the inventory slot node
			myInventorySlots[ii].queue_free()
			#clean up data
			myInventorySlots.erase(ii)

	#crafting window
	for ii in crafting:
		if !ii in myCraftSlots:
			var new_slot: InventorySlot = inventory_slot_scene.instantiate()
			new_slot.type = ii
			new_slot.type_scene_file_path = me.inventory[ii].scene_file_path

			myCraftSlots[ii] = new_slot
			myCraftItems.add_child(new_slot)
			new_slot.pressed.connect(_on_craft_slot_pressed.bind(new_slot))

		myCraftSlots[ii].quantity = crafting[ii].quantity

	#remove any slots that don't have items any more
	for ii in myCraftSlots:
		if !crafting.has(ii) or crafting[ii].quantity <= 0:
			myCraftSlots[ii].queue_free()
			myCraftSlots.erase(ii)

	#tool slot

func _on_tool_slot_pressed(slot: InventorySlot):
	tool = null
	slot.quantity = 0
	slot.type = ""
	slot.type_scene_file_path = ""
	update()

func _on_inventory_slot_pressed(slot: InventorySlot) -> void:
	#me.add_to_trade.rpc_id(1, {slot.item: {quantity = 1}})

	if ! tool:
		tool = {
			type = slot.type,
			quantity = 1,
			scene_file_path = slot.type_scene_file_path,
			items = [],
		}
		toolSlot.type = slot.type
		toolSlot.quantity = 1
		toolSlot.type_scene_file_path = slot.type_scene_file_path

	else:
		if !crafting.has(slot.type):
			crafting[slot.type] = {
				quantity = 0,
				items = [],
				}
		#var item = loot[item_name]
		crafting[slot.type].quantity += 1
	update()

func _on_craft_slot_pressed(slot) -> void:
	#me.remove_from_trade.rpc_id(1, {slot.item: {quantity = 1}})
	crafting[slot.type].quantity -= 1
	if crafting[slot.type].quantity <= 0:
		crafting.erase(slot.type)
	update()

func _on_craft_pressed() -> void:
	if ! tool:
		print('no tool item')
		return
	me.craft.rpc_id(1, tool , crafting)
