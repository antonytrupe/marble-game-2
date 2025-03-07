extends GutTest

var instance: Chunks


func before_each():
	instance = partial_double(load("res://chunks.gd")).new()
	#stub(instance.is_server).to_return(true)
	add_child(instance)


func test_get_chunk_name():
	var name = instance.get_chunk_name(Vector3(-1, 0, -1))
	assert_eq(name, "[0,0,0]")
