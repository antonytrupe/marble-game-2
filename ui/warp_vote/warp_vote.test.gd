extends GutTest
var game: Game
var chunk: Chunk


func test_true():
	assert_true(true)


func before_each():
	game = load("res://game.tscn").instantiate()
	chunk = load("res://chunk.tscn").instantiate()
	chunk.name = "CHUNK"
	await wait_until(func(): return game.is_inside_tree(), 5)
	#game.chunks.add_child(chunk)


func test_instantiate():
	var chunks: Dictionary = {"[0,0,0]": 60}

	var warp_vote = game._create_warp_vote(chunks, 1)
	#assert_eq(warp_vote, {})
