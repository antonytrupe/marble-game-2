extends Node2D
const INVENTORY_SLOT_SCENE = preload("res://inventory_slot.tscn")

@export var me: MarbleCharacter
@export var other_player_trade: Dictionary = {}

var my_inventory_slots = {}
var my_trade_slots = {}
var other_trade_slots = {}

@onready var my_items = %MyInventory
@onready var my_trade_items = %MyTrades
@onready var other_trade_items = %OtherPlayerTrades

func _ready() -> void:
	update()


func update() -> void:
	#my inventory
	for category in me.inventory:
		if !category in my_inventory_slots:
			var new_slot = INVENTORY_SLOT_SCENE.instantiate()
			new_slot.category = category
			new_slot.type_scene_file_path = me.inventory[category].scene_file_path
			my_inventory_slots[category] = new_slot
			my_items.add_child(new_slot)
			new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))

		#var trade_quantity = 0
		if category in me.my_trade_inventory:
			my_inventory_slots[category].quantity = me.inventory[category].quantity - me.my_trade_inventory[category].quantity
			#trade_quantity = me.myTradeInventory[ii].quantity


	#my trades
	for category in me.my_trade_inventory:
		if !category in my_trade_slots:
			var new_slot = INVENTORY_SLOT_SCENE.instantiate()
			new_slot.category = category
			new_slot.type_scene_file_path = me.my_trade_inventory[category].scene_file_path
			my_trade_slots[category] = new_slot
			my_trade_items.add_child(new_slot)
			new_slot.pressed.connect(_on_trade_slot_pressed.bind(new_slot))

		my_trade_slots[category].quantity = me.my_trade_inventory[category].quantity

	#remove any slots that don't have items any more
	for category in my_trade_slots:
		if !me.my_trade_inventory.has(category) or me.my_trade_inventory[category].quantity <= 0:
			my_trade_slots[category].queue_free()
			my_trade_slots.erase(category)

	#other player trade
	for category in other_player_trade:
		if !category in other_trade_slots:
			var new_slot: InventorySlot = INVENTORY_SLOT_SCENE.instantiate()
			new_slot.category = category
			other_trade_slots[category] = new_slot
			other_trade_items.add_child(new_slot)
			#new_slot.pressed.connect(_on_trade_slot_pressed.bind(new_slot))

		other_trade_slots[category].quantity = other_player_trade[category].quantity

	#remove any slots that don't have items any more
	for category in other_trade_slots:
		if !other_player_trade.has(category) or other_player_trade[category].quantity <= 0:
			other_trade_slots[category].queue_free()
			other_trade_slots.erase(category)


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
	me.accept_trade.rpc_id(1)
