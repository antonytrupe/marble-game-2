class_name WindowBar
extends Panel

@export var game:Game


func _unhandled_input(event):
	print('window bar _unhandled_input')
	game._unhandled_input(event)


func _on_warp_button_pressed() -> void:
	var event = InputEventAction.new()
	event.action = "warp_vote"
	event.pressed = true
	Input.parse_input_event(event)


func _on_craft_button_pressed() -> void:
	var event = InputEventAction.new()
	event.action = "craft"
	event.pressed = true
	Input.parse_input_event(event)


func _on_inventory_button_pressed() -> void:
	var event = InputEventAction.new()
	event.action = "inventory"
	event.pressed = true
	Input.parse_input_event(event)
