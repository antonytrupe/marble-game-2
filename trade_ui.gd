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
	for ii in me.inventory:
		if !ii in myInventorySlots:
			var new_slot = inventory_slot_scene.instantiate()
			new_slot.item = ii
			myInventorySlots[ii] = new_slot
			myItems.add_child(new_slot)
			new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))

		myInventorySlots[ii].quantity = me.inventory[ii].quantity
		if ii in me.myTradeInventory:
			myInventorySlots[ii].quantity -= me.myTradeInventory[ii].quantity

	#my trades
	for ii in me.myTradeInventory:
		if !ii in myTradeSlots:
			var new_slot = inventory_slot_scene.instantiate()
			new_slot.item = ii
			myTradeSlots[ii] = new_slot
			myTradeItems.add_child(new_slot)
			new_slot.pressed.connect(_on_trade_slot_pressed.bind(new_slot))

		myTradeSlots[ii].quantity = me.myTradeInventory[ii].quantity

	#remove any slots that don't have items any more
	for ii in myTradeSlots:
		if !me.myTradeInventory.has(ii) or me.myTradeInventory[ii].quantity <= 0:
			myTradeSlots[ii].queue_free()
			myTradeSlots.erase(ii)

	#other player trade
	for ii in otherPlayerTrade:
		if !ii in otherTradeSlots:
			var new_slot = inventory_slot_scene.instantiate()
			new_slot.item = ii
			otherTradeSlots[ii] = new_slot
			otherTradeItems.add_child(new_slot)
			#new_slot.pressed.connect(_on_trade_slot_pressed.bind(new_slot))

		otherTradeSlots[ii].quantity = otherPlayerTrade[ii].quantity

	#remove any slots that don't have items any more
	for ii in otherTradeSlots:
		if !otherPlayerTrade.has(ii) or otherPlayerTrade[ii].quantity <= 0:
			otherTradeSlots[ii].queue_free()
			otherTradeSlots.erase(ii)


func _on_inventory_slot_pressed(slot) -> void:
	me.add_to_trade.rpc_id(1, {slot.item: {quantity = 1}})
	update()


func _on_trade_slot_pressed(slot) -> void:
	me.remove_from_trade.rpc_id(1, {slot.item: {quantity = 1}})
	update()


func _on_accept_pressed() -> void:
	pass  # Replace with function body.
	me.accept_trade.rpc_id(1)
