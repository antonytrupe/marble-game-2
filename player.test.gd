extends GutTest

var player: MarbleCharacter


func before_each():
	player = preload("res://player.tscn").instantiate()


func test_test():
	assert_true(true)


func test_add_to_inventory():
	player.add_to_inventory({"item": {}})
