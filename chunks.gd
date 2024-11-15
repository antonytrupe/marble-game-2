extends Node3D

@onready var game = $"/root/Game"
@onready var world = %World
@onready var dayNightCycle = %DayNightCycle

const Chunk = preload("res://chunk.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		Signals.PlayerZoned.connect(_on_player_zoned)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_player_zoned(player: MarbleCharacter, chunk: Node3D):
	#print("_on_player_zoned", player.name, chunk.name)
	if game.player_id == player.name:
		#get all the chunks the player is overlapping
		var chunks = player.get_zones()
		#print(chunks)
		dayNightCycle.chunks = chunks

	if !multiplayer.is_server():
		#print('_on_player_zoned not from server')
		return

	var chunk_json = JSON.parse_string(chunk.name)
	#return
	#print(chunk_json)
	for x in range(-1, 1 + 1):
		for z in range(-1, 1 + 1):
			var adj_x = chunk_json[0] + x
			var adj_y = chunk_json[1] + 0
			var adj_z = chunk_json[2] + z
			var adj_chunk_name = "[%s,%s,%s]" % [adj_x, adj_y, adj_z]
			#print('adj_chunk_name:',adj_chunk_name)
			var adj_chunk = get_node_or_null(adj_chunk_name)
			if !adj_chunk:
				var new_chunk = Chunk.instantiate()
				new_chunk.position = Vector3(adj_x * 60, adj_y * 60, adj_z * 60)
				new_chunk.name = adj_chunk_name
				new_chunk.birth_date = Time.get_ticks_msec() + world.world_age
				#new_chunk.extra_age=
				add_child(new_chunk)
				#print('added new chunk')
