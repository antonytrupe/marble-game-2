extends GutTest

var chunks_script = load("res://chunks.gd")
var chunk_script = load("res://chunk/chunk.gd")

var instance: Chunks


func before_each():
	instance = partial_double(chunks_script).new()


func test_passes():
	# this test will pass because 1 does equal 1
	assert_eq(1, 1)


func test_single_origin_30_minutes():
	# this test will pass because 1 does equal 1
	var chunk: Chunk = partial_double(chunk_script).new()
	chunk.name = "[0,0,0]"

	var chunks: Array[Chunk] = [chunk]
	var adjacent = instance.get_adjacent_chunks(chunks, 30)
	assert_eq(adjacent.size(), 1)
	assert_eq_deep(adjacent, {"[0,0,0]": 30.0})


func test_single_origin_60_minutes():
	# this test will pass because 1 does equal 1
	var chunk: Chunk = partial_double(chunk_script).new()
	chunk.name = "[0,0,0]"

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
	chunk1.name = "[0,0,0]"

	var chunk2: Chunk = partial_double(chunk_script).new()
	chunk2.name = "[1,0,0]"

	var chunks: Array[Chunk] = [chunk1, chunk2]
	var adjacent = instance.get_adjacent_chunks(chunks, 30)
	assert_eq(adjacent.size(), 2)
	assert_eq_deep(adjacent, {"[0,0,0]": 30.0, "[1,0,0]": 30.0})


func test_double_origin_60_minutes():
	# this test will pass because 1 does equal 1
	var chunk1: Chunk = partial_double(chunk_script).new()
	chunk1.name = "[0,0,0]"

	var chunk2: Chunk = partial_double(chunk_script).new()
	chunk2.name = "[1,0,0]"

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


func test_get_chunk_0_0_0():
	var c = instance.get_chunk_name(Vector3(0, 0, 0))
	assert_eq(c, "[%s,%s,%s]" % [0, 0, 0])


func test_get_chunk_1_1_1():
	var c = instance.get_chunk_name(Vector3(1, 1, 1))
	assert_eq(c, "[%s,%s,%s]" % [0, 0, 0])


func test_get_chunk_31_1_1():
	var c = instance.get_chunk_name(Vector3(31, 1, 1))
	assert_eq(c, "[%s,%s,%s]" % [1, 0, 0])


func test_get_chunk_33_1_1():
	var c = instance.get_chunk_name(Vector3(30, 1, 1))
	assert_eq(c, "[%s,%s,%s]" % [1, 0, 0])


func test_get_chunk_29_1_1():
	var c = instance.get_chunk_name(Vector3(29, 1, 1))
	assert_eq(c, "[%s,%s,%s]" % [0, 0, 0])


func test_get_chunk_60_1_1():
	var c = instance.get_chunk_name(Vector3(60, 1, 1))
	assert_eq(c, "[%s,%s,%s]" % [1, 0, 0])


func test_get_chunk_89_1_1():
	var c = instance.get_chunk_name(Vector3(89, 1, 1))
	assert_eq(c, "[%s,%s,%s]" % [1, 0, 0])


func test_get_chunk_90_1_1():
	var c = instance.get_chunk_name(Vector3(90, 1, 1))
	assert_eq(c, "[%s,%s,%s]" % [2, 0, 0])


func test_get_chunk_90_0_90():
	var c = instance.get_chunk_name(Vector3(90, 0, 90))
	assert_eq(c, "[%s,%s,%s]" % [2, 0, 2])


func test_get_chunk_n60_0_90():
	var c = instance.get_chunk_name(Vector3(-60, 0, 0))
	assert_eq(c, "[%s,%s,%s]" % [-1, 0, 0])
