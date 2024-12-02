class_name QuestManager
extends CanvasLayer

const QUEST_HEADER_SCENE = preload("res://QuestHeader.tscn")

@export var me: MarbleCharacter

var quest_to_ui={}

@onready var item:OptionButton=%ItemOptionButton
@onready var quantity_button=%QuantityOptionButton
@onready var quest_name_text=%QuestNameText
@onready var quest_list_container=%QuestListContainer


func _ready():
	update()

func edit_quest(quest:Dictionary):
	quantity_button.value=quest.quantity
	quest_name_text.text=quest.name
	var meta=item.get_meta("items")
	#var idx=item.get_meta("Stone")
	#var l=item.get_meta_list()
	var idx=meta[quest.category]
	item.select(idx)

func update():
	#check for quests to add to the list
	for quest in me.quests.values():
		if quest.name not in quest_to_ui:
			var h=QUEST_HEADER_SCENE.instantiate()
			h.quest=quest
			h.me=me
			h.manager=self
			quest_to_ui[quest.name]=h
			quest_list_container.add_child(h)

	#check the list for quests to remove or update
	for quest_name in quest_to_ui:
		var h:QuestHeader=quest_to_ui[quest_name]
		if quest_name not in me.quests.keys():
			quest_list_container.remove_child(quest_to_ui[quest_name])
			quest_to_ui[quest_name].queue_free()
			quest_to_ui.erase(quest_name)
		else:
			h.quest=me.quests[quest_name]


func _on_create_quest_button_pressed() -> void:

	var item_name=item.get_item_text(item.selected)
	var quantity=quantity_button.value
	if item.selected<0 or quantity<=0:
		print('no item selected')
		return
	var quest_name=quest_name_text.text
	me.create_quest.rpc_id(1,{
		name=quest_name,
		category=item_name,
		quantity=quantity,
		})
