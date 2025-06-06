extends GutTest

var instance: WarpSettingsUI

func before_each():
	instance = partial_double(load("res://ui/warp_controls/warp_settings.tscn"))\
	.instantiate()
	add_child(instance)


func test_not_null():
	assert_not_null(instance)


func test_default_value():
	assert_eq(instance.slider.value,0)


func test_default_custom_value():
	assert_eq(instance.slider.custom_value,1)


func _test_when_player_warp_speed_is_set():
	var player:MarbleCharacter= double(load("res://player/Player.gd")).new()
	add_child(player)
	instance.player=player
	player.warp_speed=2.0
	assert_eq(2.0,2.0)
	assert_eq(instance.slider.custom_value,2.0)


func _test_when_only_world_is_set():
	var world:World= double(load("res://world.gd")).new()
	world.warp_speed=2.0
	instance.world=world
	assert_eq(2.0,2.0)
	assert_eq(instance.slider.custom_value,2.0)
