extends GutTest

var instance: Game


func before_each():
	instance = partial_double(load("res://game.tscn")).instantiate()
	stub(instance.is_server).to_return(true)
	add_child(instance)


func test_find_origin_chunk():
	var chunk = instance.get_chunk("[0,0,0]")
	assert_not_null(chunk)
	assert_eq(chunk.name, "[0,0,0]")


func test_create_tree():
	instance._spawn_trees(1, Vector3(0, 0, 0))
	#/root/GutRunner/@Node@4/Game/World/Chunks/[0,0,0]/Flora/Tree0592085972

	var flora = get_node_or_null("Game/World/Chunks/[0,0,0]/Flora")
	assert_not_null(flora)
	var children = flora.get_children()
	assert_eq(children.size(), 2)
	var tree = flora.find_child("Tree*",true,false)
	assert_not_null(tree)
