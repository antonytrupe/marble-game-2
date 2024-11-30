extends Control

@export var me: MarbleCharacter

@onready var item:OptionButton=%ItemOptionButton
@onready var quantity_button=%QuantityOptionButton

func _on_create_quest_button_pressed() -> void:
	#print('_on_create_quest_button_pressed')
	var item_name=item.get_item_text(item.selected)
	#print(itemName)
	#print(item.get_item_text(item.selected))
	var quantity=quantity_button.value
	me.create_quest(item_name,quantity)
