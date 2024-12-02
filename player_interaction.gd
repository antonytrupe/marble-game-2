class_name PlayerInteraction
extends CanvasLayer

const INVENTORY_SLOT_SCENE = preload("res://inventory_slot.tscn")
const QUEST_HEADER_SCENE = preload("res://QuestHeader.tscn")

@export var me: MarbleCharacter
#@export var other:MarbleCharacter
@export var other_player_trade: Dictionary = {}
@export var other_player_quests: Dictionary = {}

#state about what's on the screen
var my_inventory_slots = {}
var my_trade_slots = {}
var other_trade_slots = {}
var quest_to_ui = {}
var selected_quest = {}

@onready var my_items = %MyInventory
@onready var my_trade_items = %MyTrades
@onready var other_trade_items = %OtherPlayerTrades
@onready var other_quests_ui = %OtherPlayerQuests
@onready var quest_details = %QuestDetails


func _ready() -> void:
	update()


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

	#my inventory
	for category in me.inventory:
		if !category in my_inventory_slots:
			var new_slot = INVENTORY_SLOT_SCENE.instantiate()
			new_slot.category = category
			new_slot.type_scene_file_path = me.inventory[category].scene_file_path
			new_slot.add_items(me.inventory[category].items)
			new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))
			my_inventory_slots[category] = new_slot
			my_items.add_child(new_slot)

	##my trades
	for category in me.my_trade_inventory:
		if !category in my_trade_slots:
			var new_slot = INVENTORY_SLOT_SCENE.instantiate()
			new_slot.category = category
			new_slot.type_scene_file_path = me.my_trade_inventory[category].scene_file_path
			new_slot.add_items(me.my_trade_inventory[category].items)
			my_trade_slots[category] = new_slot

			my_trade_items.add_child(new_slot)
			new_slot.pressed.connect(_on_trade_slot_pressed.bind(new_slot))

	#other player trade
	for slot in other_trade_slots.values():
		other_trade_items.remove_child(slot)
		slot.queue_free()
	other_trade_slots.clear()
	for category in me.other_trade_inventory:
		if !category in other_trade_slots:
			var new_slot: InventorySlot = INVENTORY_SLOT_SCENE.instantiate()
			new_slot.category = category
			var i = me.other_trade_inventory[category].items
			new_slot.add_items(i)
			other_trade_slots[category] = new_slot
			other_trade_items.add_child(new_slot)


func _on_inventory_slot_pressed(slot: InventorySlot) -> void:
	var item = slot._items.values()[0]
	slot.remove_item(item)

	if !item.category in my_trade_slots:
		var new_slot = INVENTORY_SLOT_SCENE.instantiate()
		new_slot.category = item.category
		new_slot.type_scene_file_path = item.scene_file_path
		new_slot.pressed.connect(_on_trade_slot_pressed.bind(new_slot))
		my_trade_slots[item.category] = new_slot
		my_trade_items.add_child(new_slot)

	my_trade_slots[item.category].add_items({
				item.name:item,
				},
			)

	me.add_to_trade.rpc_id(1, {slot.category: {
		scene_file_path = slot.type_scene_file_path,
		items = {item.name:item},
	}})


func _on_trade_slot_pressed(slot: InventorySlot) -> void:
	var item = slot._items.values()[0]
	slot.remove_item(item)

	if !item.category in my_inventory_slots:
		var new_slot = INVENTORY_SLOT_SCENE.instantiate()
		new_slot.category = item.category
		new_slot.type_scene_file_path = item.scene_file_path
		new_slot.pressed.connect(_on_inventory_slot_pressed.bind(new_slot))
		my_inventory_slots[item.category] = new_slot
		my_items.add_child(new_slot)

	my_inventory_slots[item.category].add_items({
		item.name:item,
	})


	me.remove_from_trade.rpc_id(1, {slot.category: {
		scene_file_path = slot.type_scene_file_path,
		items =  {item.name:item},
		}})
	#update()


func _on_accept_pressed() -> void:
	me.accept_trade.rpc_id(1)


func _on_visibility_changed() -> void:
	if !visible:
		if me:
			me.my_trade_inventory = {}
		for slot in my_inventory_slots.values():
			my_items.remove_child(slot)
			slot.queue_free()
		my_inventory_slots.clear()

		for slot in my_trade_slots.values():
			my_trade_items.remove_child(slot)
			slot.queue_free()
		my_trade_slots.clear()
