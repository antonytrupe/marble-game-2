extends Control

@export var me: MarbleCharacter

@onready var item:OptionButton=%ItemOptionButton
@onready var quantityButton=%QuantityOptionButton

func _on_create_quest_button_pressed() -> void:
	#print('_on_create_quest_button_pressed')
	var itemName=item.get_item_text(item.selected)
	#print(itemName)
	#print(item.get_item_text(item.selected))
	var quantity=quantityButton.value
	me.create_quest(itemName,quantity)
