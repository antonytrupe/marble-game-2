class_name WanderTest
extends GutTest

var instance: Wander


func before_each():
	instance = Wander.new()

	#instance.angle=10
	instance.remaining=3

	var game_scene_double = double(load('res://game.tscn'))
	instance.game = game_scene_double.instantiate()
	#stub(instance.game._get_turn_number).to_call_super()

	var player_scene_double = double(load('res://player/player.tscn'))
	#var player_scene_double = load('res://player.tscn')
	instance.player=player_scene_double.instantiate()
	stub(instance.player.server_move).to_call_super()
	stub(instance.player.server_rotate).to_call_super()
	stub(instance.player.rotate_y).to_call_super()
	stub(instance.player.is_server).to_return(true)
	stub(instance.player.camera_pivot).to_call_super()



func test_passes():
	# this test will pass because 1 does equal 1
	assert_eq(1, 1)


func test_can_instantiate():
	assert_not_null(instance)


func _test_starts_rotating():
	assert_eq(instance.player.rotation.x,0)
	assert_eq(instance.player.rotation.y,0)
	assert_eq(instance.player.rotation.x,0)

	gut.simulate(instance,1,18)
	assert_eq(instance.player.rotation.x,0)
	assert_almost_eq(instance.player.rotation.y,-.005,.001)
	assert_eq(instance.player.rotation.x,0)

	gut.simulate(instance,1,17)
	assert_eq(instance.player.rotation.x,0)
	assert_almost_eq(instance.player.rotation.y,-.01,.001)
	assert_eq(instance.player.rotation.x,0)


func test_turn_right():
	pass

func test_turn_left():
	pass

func test_change_direction():
	gut.simulate(instance,1,0)
