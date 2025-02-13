extends GutTest

var instance: QuantityAction


func before_each():
	instance = QuantityAction.new()
	instance.remaining = 2
	instance.frequency = 1
	instance.start_turn = 1
	instance.game = load("res://game.tscn").instantiate()
	add_child(instance.game)
	add_child(instance)
	instance.game.player_id = ""
	#instance.game.turn_number=0
	#instance.player=preload("res://player.tscn").instantiate()


func test_passes():
	# this test will pass because 1 does equal 1
	assert_eq(1, 1)


func test_first_time():
	pass


func test_second_time():
	pass


func test_last_time():
	pass


func test_once_per_turn():
	pass
