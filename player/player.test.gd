extends GutTest

var player: MarbleCharacter


func before_each():
	player = partial_double(load("res://player/player.tscn")).instantiate()
	stub(player.is_server).to_return(true)
	add_child(player)

func test_test():
	assert_true(true)


func test_add_to_inventory():
	player.add_to_inventory({"item": {}})


func test_set_nearby_warp_speed():
	assert_eq(player.warp_speed,1)
	#assert_eq((player.warp_scanner.shape as SphereShape3D).radius ,0)

	var tree:MarbleTree=partial_double(load("res://objects/tree/tree.tscn")).instantiate()
	add_child(tree)
	tree.position.x=1
	assert_eq(tree.warp_speed,1)

	player.warp_speed=2
	assert_eq(player.warp_speed,2)

	#assert_eq(tree.warp_speed,2)
