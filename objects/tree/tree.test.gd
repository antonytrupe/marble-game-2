extends GutTest

var tree: MarbleTree


func before_each():
	tree = partial_double(load("res://objects/tree/tree.tscn")).instantiate()
	#stub(tree.is_server).to_return(true)


func test_not_null():
	assert_not_null(tree)
