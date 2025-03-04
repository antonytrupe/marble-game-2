extends GutTest

var instance: QuantityAction
#var game_scene_double
#var player_scene_double


func before_each():
	instance = QuantityAction.new()
	instance.remaining = 2
	instance.frequency = 1

	var game = partial_double(load('res://game.tscn')).instantiate()
	add_child(game)
	instance.game = game

	#stub(instance.game._get_turn_number).to_call_super()

	var player = partial_double(load('res://player/player.tscn')).instantiate()
	instance.player=player
	add_child(player)



func test_passes():
	# this test will pass because 1 does equal 1
	assert_eq(1, 1)


func test_can_instantiate():
	assert_not_null(instance)


func test_mock_game():
	assert_not_null(instance.game)


func test_mock_player():
	assert_not_null(instance.player)


func test_is_child_of_player():
	stub(instance.player.add_child).to_call_super()
	#assert_is(instance.get_parent(),instance.player)
	assert_not_null(instance.get_parent())

func test_turn_one_init():
	#make sure the game turn is 0
	assert_eq(instance.player.turn_number,1)
	#make sure the action's last turn is null
	assert_null(instance.last_turn)
	#make sure the action's frequency is 1
	assert_eq(instance.frequency,1)
	assert_eq(instance.remaining,2)


func test_once_one_first_turn():
	#stub(instance.game._get_turn_number).to_call_super()
	#instance._process(0)
	gut.simulate(instance,1,0)

	assert_eq(instance.player.turn_number,1)
	#make sure the action's last turn is null
	assert_eq(instance.last_turn,1)
	#make sure the action's frequency is 1
	assert_eq(instance.frequency,1)
	assert_eq(instance.remaining,1)

	gut.simulate(instance,1,0)
	assert_eq(instance.last_turn,1)
	assert_eq(instance.remaining,1)


func test_start_turn_in_future():
	instance.start_turn=3
	gut.simulate(instance,1,0)
	assert_null(instance.last_turn)
	assert_eq(instance.remaining,2)


func _test_once_one_second_turn():
	assert_null(instance.last_turn)
	#stub(instance.game._get_turn_number).to_call_super()
	assert_eq(instance.player.turn_number,1)

	var times=1
	var delta=6
	gut.simulate(instance,times,delta)
	gut.simulate(instance,times,delta)

	#make sure the action's last turn is null
	assert_eq(instance.last_turn,1)
	#make sure the action's frequency is 1
	assert_eq(instance.frequency,1)
	assert_eq(instance.remaining,1)

	#stub(instance.game._get_turn_number).to_return(2)
	#instance.game.turn_number=2
	assert_eq(instance.player.turn_number,2)

	gut.simulate(instance,1,0)

	assert_eq(instance.last_turn,2)
	assert_eq(instance.remaining,0)
