class_name PlayerInteraction
extends Panel

const INVENTORY_SLOT_SCENE = preload("res://inventory_slot.tscn")
const QUEST_HEADER_SCENE = preload("res://QuestHeader.tscn")

@export var me: MarbleCharacter
#@export var other:MarbleCharacter
@export var other_player_trade: Dictionary = {}
@export var other_player_quests: Dictionary = {}

#state about what's on the screen
var my_trade_slots = {}
var other_trade_slots = {}
var quest_to_ui = {}
var selected_quest = {}

@onready var my_trade_items = %MyTrades
@onready var other_trade_items = %OtherPlayerTrades
@onready var other_quests_ui = %OtherPlayerQuests
@onready var quest_details = %QuestDetails


func _ready() -> void:
	update()


func _unhandled_input(event):
	me._unhandled_input(event)


@rpc("any_peer")
func add_item_to_trade(item: Dictionary):
	if not multiplayer.is_server():
		return

	if !(item.name in my_trade_slots):
		var new_slot: InventorySlot = INVENTORY_SLOT_SCENE.instantiate()
		new_slot.item = item
		new_slot.src = my_trade_items.get_parent()
		my_trade_slots[item.name] = new_slot
		my_trade_items.add_child(new_slot)
		#update current player
		me.my_trade_inventory[item.name] = item
		#update other player
		me.trade_partner.other_trade_inventory = me.my_trade_inventory


@rpc("any_peer")
func remove_item_from_trade(item_name: String):
	if not multiplayer.is_server():
		return
	var slot: InventorySlot = my_trade_slots[item_name]
	slot.hide()
	slot.queue_free()
	my_trade_slots.erase(item_name)
	my_trade_items.remove_child(slot)
	#update current player
	me.my_trade_inventory.erase(item_name)
	#update other player
	me.trade_partner.other_trade_inventory = me.my_trade_inventory


func select_quest(quest: Dictionary):
	selected_quest = quest

	var need = selected_quest.quantity
	var category = selected_quest.category
	var have = 0
	if category in me.my_trade_inventory:
		have = me.my_trade_inventory[category].items.size()
	quest_details.text = "%s of %s %s" % [have, need, category]


func update() -> void:
	#print('player interactions update',me.inventory)

	#quests
	for quest in other_player_quests.values():
		#print(quest)
		if quest.name not in quest_to_ui:
			#print('adding quest')
			var h: QuestHeader = QUEST_HEADER_SCENE.instantiate()
			h.quest = quest
			h.interaction = self
			#h.me=me
			quest_to_ui[quest.name] = h
			other_quests_ui.add_child(h)

	if selected_quest:
		select_quest(selected_quest)

	##my trades
	for item_name in me.my_trade_inventory:
		var item = me.my_trade_inventory[item_name]
		if !item_name in my_trade_slots:
			var new_slot = INVENTORY_SLOT_SCENE.instantiate()
			new_slot.item = item
			new_slot.src = my_trade_items.get_parent()
			my_trade_slots[item_name] = new_slot

			my_trade_items.add_child(new_slot)

	#other player trade
	print(me.other_trade_inventory)
	for slot in other_trade_slots.values():
		other_trade_items.remove_child(slot)
		slot.queue_free()
	other_trade_slots.clear()
	for item_name in me.other_trade_inventory:
		var item = me.other_trade_inventory[item_name]
		if !item_name in other_trade_slots:
			var new_slot: InventorySlot = INVENTORY_SLOT_SCENE.instantiate()
			new_slot.item = item
			new_slot.src = my_trade_items
			other_trade_slots[item_name] = new_slot
			other_trade_items.add_child(new_slot)


func _on_accept_pressed() -> void:
	me.accept_trade.rpc_id(1)
