extends Node2D

@export var me: MarbleCharacter
@export var otherPlayerTrade: Dictionary = {}
@onready var myItems = %MyInventory
@onready var myTradeItems = %MyTrades
@onready var otherTradeItems = %OtherPlayerTrades
var myInventorySlots = {}
var myTradeSlots = {}
var otherTradeSlots = {}
const inventory_slot_scene = preload("res://inventory_slot.tscn")


func _ready() -> void:
	update()


func update() -> void:
	#my inventory
	for category in me.inventory:
		if !category in myInventorySlots:
			var new_slot = inventory_slot_scene.instantiate()
			new_slot.category = category
			new_slot.type_scene_file_path = me.inventory[category].scene_file_path
			myInventorySlots[category] = new_slot
			myItems.add_child(new_slot)
			new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))

		#var trade_quantity = 0
		if category in me.myTradeInventory:
			myInventorySlots[category].quantity = me.inventory[category].quantity - me.myTradeInventory[category].quantity
			#trade_quantity = me.myTradeInventory[ii].quantity


	#my trades
	for category in me.myTradeInventory:
		if !category in myTradeSlots:
			var new_slot = inventory_slot_scene.instantiate()
			new_slot.category = category
			new_slot.type_scene_file_path = me.myTradeInventory[category].scene_file_path
			myTradeSlots[category] = new_slot
			myTradeItems.add_child(new_slot)
			new_slot.pressed.connect(_on_trade_slot_pressed.bind(new_slot))

		myTradeSlots[category].quantity = me.myTradeInventory[category].quantity

	#remove any slots that don't have items any more
	for category in myTradeSlots:
		if !me.myTradeInventory.has(category) or me.myTradeInventory[category].quantity <= 0:
			myTradeSlots[category].queue_free()
			myTradeSlots.erase(category)

	#other player trade
	for category in otherPlayerTrade:
		if !category in otherTradeSlots:
			var new_slot: InventorySlot = inventory_slot_scene.instantiate()
			new_slot.category = category
			otherTradeSlots[category] = new_slot
			otherTradeItems.add_child(new_slot)
			#new_slot.pressed.connect(_on_trade_slot_pressed.bind(new_slot))

		otherTradeSlots[category].quantity = otherPlayerTrade[category].quantity

	#remove any slots that don't have items any more
	for category in otherTradeSlots:
		if !otherPlayerTrade.has(category) or otherPlayerTrade[category].quantity <= 0:
			otherTradeSlots[category].queue_free()
			otherTradeSlots.erase(category)


func _on_inventory_slot_pressed(slot: InventorySlot) -> void:
	me.add_to_trade.rpc_id(1, {slot.category: {
		quantity = 1,
		scene_file_path = slot.type_scene_file_path,
		items = [],
	}})
	update()


func _on_trade_slot_pressed(slot) -> void:
	me.remove_from_trade.rpc_id(1, {slot.category: {
		quantity = 1,
		scene_file_path = slot.type_scene_file_path,
		items = slot.items,
		}})
	update()


func _on_accept_pressed() -> void:
	pass # Replace with function body.
	me.accept_trade.rpc_id(1)
