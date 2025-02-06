extends GutTest
var game: Game
var chunk: Chunk


func test_true():
	assert_true(true)


func before_each():
	game = preload("res://game.tscn").instantiate()
	chunk = preload("res://chunk.tscn").instantiate()
	chunk.name = "CHUNK"
	game.chunks.add_child(chunk)


func test_instantiate():
	var chunks: Dictionary = {"CHUNK": 60}

	var warp_vote = game._create_warp_vote(chunks, 1)
	assert_eq(warp_vote, {})
