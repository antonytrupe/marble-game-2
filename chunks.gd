extends Node3D
const ChunkResource = preload("res://chunk.tscn")

@onready var game = $"/root/Game"
@onready var world = %World
@onready var day_night_cycle: DayNightCycle = %DayNightCycle


func _ready() -> void:
	#if !multiplayer.is_server():
	Signals.PlayerZoned.connect(_on_player_zoned)


##chunk could be the old chunk or new chunk
func _on_player_zoned(player: MarbleCharacter, chunk: Chunk):
	print("_on_player_zoned %s in %s on %s" % [player.name, chunk.name, game.player_id])
	if game.player_id == player.name:
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
		day_night_cycle.chunks = chunks

	# check if we're the server
	if !multiplayer.is_server():
		return

	#only generate chunks on the server
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
				new_chunk.birth_date = Time.get_ticks_msec() + world.world_age
				#new_chunk.extra_age=
				add_child(new_chunk)
