class_name Chunks
extends Node3D
const ChunkResource = preload("res://chunk/chunk.tscn")

@onready var game = $"/root/Game"
@onready var world = %World
@onready var day_night_cycle: DayNightCycle = %DayNightCycle


func _ready() -> void:
	#if !multiplayer.is_server():
	Signals.PlayerZoned.connect(_on_player_zoned)


func time_warp(warp_vote: WarpVote):
	#var chunk_warp = get_adjacent_chunks(origin_chunks, minutes)
	for chunk_name: String in warp_vote.chunks:
		var chunk: Chunk = get_node_or_null(chunk_name)
		var m = warp_vote.chunks[chunk_name]
		if chunk:
			chunk.time_warp(m)


func vector3_from_chunk_name(chunk_name):
	var a = JSON.parse_string(chunk_name)
	var v = Vector3(a[0], a[1], a[2])
	return v


func get_chunk_name(p: Vector3):
	var chunk_name = (
		"[%s,%s,%s]" % [floor((p.x + 30) / 60), floor((p.y + 30) / 60), floor((p.z + 30) / 60)]
	)
	return chunk_name


func get_chunk(p: Vector3):
	return get_node_or_null(get_chunk_name(p))


func get_adjacent_chunks(origin_chunks: Array[Chunk], origin_minutes) -> Dictionary:
	var step_minutes = 30.0
	var size = (origin_minutes / step_minutes) - 1
	var adjacent_chunks = {}
	var min_x = null
	var min_z = null
	var max_x = null
	var max_z = null

	#get our min and max's for origin_chunks
	for origin_chunk in origin_chunks:
		var v = vector3_from_chunk_name(origin_chunk.name)
		if min_x == null or min_x > v.x:
			min_x = v.x
		if min_z == null or min_z > v.z:
			min_z = v.z

		if max_x == null or max_x < v.x:
			max_x = v.x
		if max_z == null or max_z < v.z:
			max_z = v.z

	for x in range(min_x - size, max_x + size + 1):
		for z in range(min_z - size, max_z + size + 1):
			#skip origin nodes
			#if (x < min_x or x > max_x) or (z < min_z or z > max_z):
			var chunk_name = "[%s,%s,%s]" % [x, 0, z]
			var x_minutes = min(abs(min_x - x), abs(x - max_x))

			var z_minutes = min(abs(min_z - z), abs(z - max_z))
			adjacent_chunks[chunk_name] = (size - max(x_minutes, z_minutes) + 1) * step_minutes

	return adjacent_chunks


func update_day_night_cycle(player: MarbleCharacter):
	#get all the chunks the player is overlapping
	var chunks: Array[Chunk] = player.get_chunks()
	if !chunks:
		print("%s not in any chunks at %s" % [player.name, player.position])
		#print("using zoned chunk")
		#chunks = [chunk]
	# tell the daynightcycle node what chunks the player is in
	else:
		#print("%s in chunks %s at %s" % [player.name, chunks, player.position])
		pass
	#day_night_cycle.chunks = chunks


##chunk could be the old chunk or new chunk
func _on_player_zoned(player: MarbleCharacter, chunk: Chunk):
	#print("_on_player_zoned %s in %s on %s" % [player.name, chunk.name, game.player_id])
	#this should probably be somewhere else
	#if game.player_id == player.name:
		#update_day_night_cycle(player)

	# check if we're the server
	if !multiplayer.is_server():
		return

	#only generate chunks on the server
	generate_chunks(chunk)

	update_warp_votes(player, chunk)


func update_warp_votes(player: MarbleCharacter, chunk: Chunk):
	#TODO
	print(player)
	print(chunk)


func generate_chunks(chunk: Chunk):
	var chunk_json = JSON.parse_string(chunk.name)
	for x in range(-1, 1 + 1):
		for z in range(-1, 1 + 1):
			var adj_x = chunk_json[0] + x
			var adj_y = chunk_json[1] + 0
			var adj_z = chunk_json[2] + z
			var adj_chunk_name = "[%s,%s,%s]" % [adj_x, adj_y, adj_z]

			var adj_chunk = get_node_or_null(adj_chunk_name)
			if !adj_chunk:
				var new_chunk = ChunkResource.instantiate()
				new_chunk.position = Vector3(adj_x * 60, adj_y * 60, adj_z * 60)
				new_chunk.name = adj_chunk_name
				#new_chunk.birth_date = Time.get_ticks_msec() + world.world_age
				#new_chunk.extra_age=
				add_child(new_chunk)
