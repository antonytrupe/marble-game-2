class_name WarpSettingsUI
extends PanelContainer

@export var game: Game
@export var world: World
@export var player: MarbleCharacter:
	set = _set_player
@export var custom_values: Array[float] = [1, 2, 3, 4, 6, 8, 10, 12, 16, 20]

@onready var slider: WarpSlider = %PlayerWarpSlider

#TODO figure out how to get the world warp speed to show up on the server


func _set_player(value: MarbleCharacter):
	player = value
	if player:
		slider.custom_value = player.warp_speed


func _on_short_rest_button_pressed() -> void:
	game.call_warp_vote(60, game.player_id)


func _on_long_rest_button_pressed() -> void:
	game.call_warp_vote(60 * 8, game.player_id)


func _on_player_warp_slider_value_changed(value: float) -> void:
	print(value)
	if player:
		if !player.is_server():
			player.set_warp_speed.rpc_id(1, value)
		else:
			player.set_warp_speed(value)
	elif world:
		if !world.is_server():
			world.set_warp_speed.rpc_id(1, value)
		else:
			world.set_warp_speed(value)
