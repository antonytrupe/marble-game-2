extends Node

@onready var main_menu = $UI/MainMenu
@onready var hud = $UI/HUD
@onready var health_bar = $UI/HUD/HealthBar
@onready var turnNumberLabel = $UI/HUD/TurnTimer/TurnNumber
@onready var turnTimer = $UI/HUD/TurnTimer
@onready var serverCamera = $CameraPivot/ServerCamera3D
@onready var Players = $Players
@onready var game = $"."
@onready var sun = %Sun
@onready var Chunks = $Chunks
@onready var worldTime = %WorldTime
@export var turn_number = 1:
	set = update_turn_number
@export var server_age = 0

var calculated_age: int:
	get = calculate_age

const Player = preload("res://player.tscn")
const Chunk = preload("res://chunk.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()
var turn_start = 0
var player_id: String
# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}


func calculate_age():
	return server_age + Time.get_ticks_msec()


#var sf= SurfaceTool.new()
func _on_player_zoned(_player_id, chunk_id):
	if !multiplayer.is_server():
		#print('_on_player_zoned not from server')
		return

	#print("_on_player_zoned",_player_id,chunk_id)
	var chunk_json = JSON.parse_string(chunk_id)
	#return
	#print(chunk_json)
	for x in range(-1, 1 + 1):
		for z in range(-1, 1 + 1):
			var adj_x = chunk_json[0] + x
			var adj_y = chunk_json[1] + 0
			var adj_z = chunk_json[2] + z
			var adj_chunk_name = "[%s,%s,%s]" % [adj_x, adj_y, adj_z]
			#print('adj_chunk_name:',adj_chunk_name)
			var adj_chunk = Chunks.get_node_or_null(adj_chunk_name)
			if !adj_chunk:
				var new_chunk = Chunk.instantiate()
				new_chunk.position = Vector3(adj_x * 60, adj_y * 60, adj_z * 60)
				new_chunk.name = adj_chunk_name
				new_chunk.birth_date = Time.get_ticks_msec() + server_age
				Chunks.add_child(new_chunk)
				#print('added new chunk')
	pass


func save():
	var save_dict = {"filename": get_scene_file_path(), "parent": get_parent().get_path(), "server_age": server_age + Time.get_ticks_msec(), "host_player_id": player_id}
	return save_dict


func save_game():
	#print('save_game')
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	#var save_file = FileAccess.open('user://savegame_'+str(Time.get_ticks_msec())+'.save', FileAccess.WRITE)
	print("saved ", save_file.get_path_absolute())
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save")

		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data)

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(json_string)
	#save_file.close()
	save_file.flush()
	DirAccess.copy_absolute(save_file.get_path_absolute(), "user://savegame_" + str(Time.get_ticks_msec() + server_age) + ".save")


func load_game():
	#print('load_game')
	if not FileAccess.file_exists("user://savegame.save"):
		print("save not found")
		return  # Error! We don't have a save to load.

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	#process world node
	var world_line = save_file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(world_line)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", world_line, " at line ", json.get_error_line())
		return
	if json.data.has("server_age"):
		game.server_age = int(json.data["server_age"])
	#process player nodes
	#print('looking for players')
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var node_data = json.data
		#print('loading ',node_data["player_id"])

		# Firstly, we need to create the object and add it to the tree
		#TODO check if the node is in the tree already
		var node = get_node_or_null(node_data.parent + "/" + node_data.name)
		if !node:
			#print('new node')
			node = load(node_data["filename"]).instantiate()
		else:
			#print('found node')
			pass
		# Check the node has a save function.
		if !node.has_method("load"):
			print("persistent node '%s' is missing a load() function, skipped" % node.name)
			continue
		node.call("load", node_data)
		#var ms=$MultiplayerSynchronizer
		#ms.set_visibility_for()
		if !node.get_parent():
			get_node_or_null(node_data["parent"]).add_child(node)
		#print('added ',node.name)


func _ready():
	#var signals=load("res://Signals.cs").new()
	Signals.PlayerZoned.connect(_on_player_zoned)

	var configFile = ConfigFile.new()
	# Load data from a file.
	#var err = config.load("user://config.cfg")
	var err = configFile.load("res://config.cfg")

	# If the file didn't load, ignore it.
	if err != OK:
		print("error reading config file")

	var config = {}
	config.player_id = configFile.get_value("default", "player_id", null)
	config.remote_ip = configFile.get_value("default", "remote_ip", null)
	config.server = configFile.get_value("default", "server", false)

	print("config:", config)

	var arguments = {}
	for argument in OS.get_cmdline_user_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""

	print("arguments:", arguments)
	config.merge(arguments, true)

	print("merged:", config)

	if config.server:
		start_server()
		main_menu.hide()
		hud.show()
		health_bar.hide()
		serverCamera.show()
		serverCamera.current = true
	elif config.has("player_id"):
		player_id = config["player_id"]
		_on_join_button_pressed(config.remote_ip)


func _process(_delta):
	var now = Time.get_ticks_msec()

	var age = GameTime.get_age_parts(calculated_age)
	worldTime.text = "%d years, %d months, %d days, %02d:%02d:%02d" % [age.years, age.months, age.days, age.hours, age.minutes, age.seconds]

	sun.rotation.x = -PI / 8

	if multiplayer.is_server():
		turnTimer.value = (now + server_age) % 6000
		var newTurnNumber = (now + server_age) / (6 * 1000) + 1
		if turn_number != newTurnNumber:
			turn_number = newTurnNumber
	else:
		turnTimer.value = (now - turn_start) % 6000


func update_turn_number(value):
	turn_number = value
	turnNumberLabel.text = "turn " + str(value)
	turn_start = Time.get_ticks_msec()


func _unhandled_input(_event):
	#print('_unhandled_input')
	if Input.is_action_just_pressed("quit"):
		#print('quit')
		if multiplayer.is_server():
			print("server save")
			save_game()
		get_tree().quit()


func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	start_server()
	#add_player(multiplayer.get_unique_id())


func start_server():
	#print('start_server')
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	#multiplayer.peer_connected.connect(add_player)
	#multiplayer.peer_disconnected.connect(remove_player)
	load_game()


func server_disconnected():
	#print('server_disconnected')
	get_tree().quit()


func _on_join_button_pressed(ip_address):
	print("joining ", ip_address)
	main_menu.hide()
	hud.show()

	enet_peer.create_client(ip_address, PORT)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(server_disconnected)
	multiplayer.multiplayer_peer = enet_peer
	#print(player_id)


func _on_connected_to_server():
	#print('_on_connected_to_server')
	game.register_player.rpc_id(1, player_id)


@rpc("authority", "call_local", "reliable")
func send_server_age(_server_age):
	if multiplayer.get_remote_sender_id() != 1:
		print("someone else trying to call send_server_age")
		return
	server_age = _server_age


func add_player(_peer_id, _player_id):
	#first check if this player already has a node
	var player = Players.get_node_or_null(_player_id)
	if !player:
		player = Player.instantiate()
		player.name = _player_id
		player.player_id = _player_id
		#TODO make sure player isn't colliding with existing player
		Players.add_child(player)


@rpc("any_peer", "reliable")
func register_player(new_player_info):
	var peer_id = multiplayer.get_remote_sender_id()
	players[peer_id] = new_player_info
	add_player(peer_id, new_player_info)
	send_server_age.rpc_id(peer_id, Time.get_ticks_msec() + server_age)


func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


func update_health_bar(health_value):
	health_bar.value = health_value
