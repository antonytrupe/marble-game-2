class_name QuestHeader
extends HBoxContainer

@export var quest:Dictionary:
	set=_set_quest
@export var me:MarbleCharacter
@export var manager:QuestManager

@onready var name_button=%NameButton
@onready var delete_button=%DeleteButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name_button.text=quest.name
	if me:
		delete_button.show()


func _set_quest(q:Dictionary):
	quest=q

func _on_delete_button_pressed() -> void:
	me.delete_quest.rpc_id(1,quest)


func _on_name_button_pressed() -> void:
	manager.edit_quest(quest)
