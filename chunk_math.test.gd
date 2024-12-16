extends GutTest

var chunks_script = load("res://chunks.gd")
var chunk_script = load("res://chunk.gd")

var instance: Chunks


func before_each():
	instance = partial_double(chunks_script).new()


func test_passes():
	# this test will pass because 1 does equal 1
	assert_eq(1, 1)


func test_single_origin_30_minutes():
	# this test will pass because 1 does equal 1
	var chunk: Chunk = partial_double(chunk_script).new()
	chunk.name="[0,0,0]"

	var chunks: Array[Chunk] = [chunk]
	var adjacent = instance.get_adjacent_chunks(chunks, 30)
	assert_eq(adjacent.size(), 1)
	assert_eq_deep(adjacent, {"[0,0,0]":30.0})


func test_single_origin_60_minutes():
	# this test will pass because 1 does equal 1
	var chunk: Chunk = partial_double(chunk_script).new()
	chunk.name="[0,0,0]"

	var chunks: Array[Chunk] = [chunk]
	var adjacent = instance.get_adjacent_chunks(chunks, 60)
	assert_eq(adjacent.size(), 9)
	assert_eq_deep(
		adjacent,
		{
			"[-1,0,-1]": 30.0,
			"[-1,0,0]": 30.0,
			"[-1,0,1]": 30.0,
			"[0,0,-1]": 30.0,
			"[0,0,0]": 60.0,
			"[0,0,1]": 30.0,
			"[1,0,-1]": 30.0,
			"[1,0,0]": 30.0,
			"[1,0,1]": 30.0
		}
	)


func test_double_origin_30_minutes():
	# this test will pass because 1 does equal 1
	var chunk1: Chunk = partial_double(chunk_script).new()
	chunk1.name="[0,0,0]"

	var chunk2: Chunk = partial_double(chunk_script).new()
	chunk2.name="[1,0,0]"

	var chunks: Array[Chunk] = [chunk1, chunk2]
	var adjacent = instance.get_adjacent_chunks(chunks, 30)
	assert_eq(adjacent.size(), 2)
	assert_eq_deep(adjacent, {"[0,0,0]": 30.0, "[1,0,0]": 30.0})


func test_double_origin_60_minutes():
	# this test will pass because 1 does equal 1
	var chunk1: Chunk = partial_double(chunk_script).new()
	chunk1.name="[0,0,0]"

	var chunk2: Chunk = partial_double(chunk_script).new()
	chunk2.name="[1,0,0]"

	var chunks: Array[Chunk] = [chunk1, chunk2]
	var adjacent = instance.get_adjacent_chunks(chunks, 60)
	assert_eq(adjacent.size(), 12)
	assert_eq_deep(
		adjacent,
		{
			"[-1,0,-1]": 30.0,
			"[-1,0,0]": 30.0,
			"[-1,0,1]": 30.0,
			"[0,0,-1]": 30.0,
			"[0,0,0]": 60.0,
			"[0,0,1]": 30.0,
			"[1,0,-1]": 30.0,
			"[1,0,0]": 60.0,
			"[1,0,1]": 30.0,
			"[2,0,-1]": 30.0,
			"[2,0,0]": 30.0,
			"[2,0,1]": 30.0,
		}
	)
