class_name PlayerInteraction
extends Panel

const INVENTORY_SLOT_SCENE = preload("res://ui/inventory/inventory_slot.tscn")
const QUEST_HEADER_SCENE = preload("res://ui/quests/QuestHeader.tscn")

@export var me: MarbleCharacter
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
@onready var game: Game = $/root/Game


func _unhandled_input(event):
	game._unhandled_input(event)

##client code
func add_item_to_trade(item: Dictionary):

	if !(item.name in my_trade_slots):
		var new_slot: InventorySlot = INVENTORY_SLOT_SCENE.instantiate()
		new_slot.item = item
		new_slot.src = my_trade_items.get_parent()
		my_trade_slots[item.name] = new_slot
		my_trade_items.add_child(new_slot)
		me.add_to_trade.rpc_id(1,item)



#client code
func remove_item_from_trade(item: Dictionary):
	if not multiplayer.is_server():
		return
	var slot: InventorySlot = my_trade_slots[item.name]
	slot.hide()
	slot.queue_free()
	my_trade_slots.erase(item.name)
	my_trade_items.remove_child(slot)
	#update current player
	me.my_trade_inventory.erase(item.name)
	me.remove_from_trade.rpc_id(1,item)
	#update other player
	if me.trade_partner:
		me.trade_partner.other_trade_inventory = me.my_trade_inventory


func select_quest(quest: Dictionary):
	selected_quest = quest

	var need = selected_quest.quantity
	var category = selected_quest.category
	var have = 0
	if category in me.my_trade_inventory:
		have = me.my_trade_inventory[category].items.size()
	quest_details.text = "%s of %s %s" % [have, need, category]

@rpc("authority")
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

	#my trades
	if me:
		for item_name in me.my_trade_inventory:
			var item = me.my_trade_inventory[item_name]
			if !item_name in my_trade_slots:
				var new_slot = INVENTORY_SLOT_SCENE.instantiate()
				new_slot.item = item
				new_slot.src = my_trade_items.get_parent()
				my_trade_slots[item_name] = new_slot

				my_trade_items.add_child(new_slot)

	#other player trade
	#print(me.other_trade_inventory)
	for slot in other_trade_slots.values():
		other_trade_items.remove_child(slot)
		slot.queue_free()
	other_trade_slots.clear()
	if me:
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


func _on_hidden() -> void:
	reset()

func reset():

	#clear local data structures
	my_trade_slots = {}
	other_trade_slots = {}
	quest_to_ui = {}
	selected_quest = {}

	game.inventory_ui.reset()

	#clear ui
	for child in my_trade_items.get_children():
		my_trade_items.remove_child(child)
		child.queue_free()

	for child in other_trade_items.get_children():
		other_trade_items.remove_child(child)
		child.queue_free()

	for child in other_quests_ui.get_children():
		other_quests_ui.remove_child(child)
		child.queue_free()

	for child in quest_details.get_children():
		quest_details.remove_child(child)
		child.queue_free()

	#rebuild
	update()
