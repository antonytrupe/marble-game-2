class_name Game
extends Node

const PORT = 9999
const PLAYER_SCENE = preload("res://player.tscn")
const STONE_SCENE = preload("res://stone/stone.tscn")
const ACORN_SCENE = preload("res://acorn/acorn.tscn")
const BUSH_SCENE = preload("res://bush/bush.tscn")
const TREE_SCENE = preload("res://tree/tree.tscn")

@export var turn_number = 1:
	set = update_turn_number

var enet_peer = ENetMultiplayerPeer.new()

var turn_start = 0
var player_id: String
# This will contain player info for every player,
# with the keys being each player's unique IDs.
#var players = {}
var rng = RandomNumberGenerator.new()

#@onready var main_menu = $UI/MainMenu
@onready var hud = $UI/HUD
@onready var terra = %Terra
@onready var flora = %Flora
@onready var turn_number_label = %TurnNumber
@onready var turn_timer = %TurnTimer
@onready var server_camera = $CameraPivot/ServerCamera3D
@onready var world = %World
#@onready var world_time = %WorldTimeLabel
@onready var players = %Players


func get_chunk(_position: Vector3) -> Chunk:
	return null


func get_chunk_name(_p: Vector3) -> String:
	# var x = p.x / 60
	return "[0,0,0]"


func spawn_stones(quantity: int, p: Vector3):
	quantity = clampi(quantity, 1, 100)
	for i in quantity:
		var stone = STONE_SCENE.instantiate()
		stone.name = stone.name + "%010d" % rng.randi()
		stone.position = get_random_vector(10, p)
		#var chunk_name=get_chunk_name(stone.position)
		# var chunk=get_chunk(stone.position)
		terra.add_child(stone)


func command(cmd: String, player: MarbleCharacter):
	if !multiplayer.is_server():
		return
	#print("server game command:", cmd)
	var parts = cmd.replace("/", "").split(" ")
	#print(parts)
	match parts[0]:
		"spawn", "/spawn":
			#print("spawn")
			match parts[1]:
				"stone", "stones":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					spawn_stones(count, player.position)
				"acorn":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 10)
					for i in count:
						var acorn = ACORN_SCENE.instantiate()
						acorn.name = acorn.name + "%010d" % rng.randi()
						acorn.position = get_random_vector(10, player.position)
						#var chunk = get_chunk(acorn.position)
						flora.add_child(acorn)
				"bush":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 10)
					for i in count:
						var bush = BUSH_SCENE.instantiate()
						bush.name = bush.name + "%010d" % rng.randi()
						bush.position = get_random_vector(10, player.position)
						#var chunk = get_chunk(bush.position)
						flora.add_child(bush)
				"tree", "trees":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 10)
					for i in count:
						var tree = TREE_SCENE.instantiate()
						tree.name = tree.name + "%010d" % rng.randi()
						tree.position = get_random_vector(10, player.position)
						#var chunk = get_chunk(tree.position)
						flora.add_child(tree)


func get_random_vector(R: float, center: Vector3) -> Vector3:
	#var rng = RandomNumberGenerator.new()
	var r = R * sqrt(rng.randf())
	var theta = rng.randf() * 2 * PI
	var x = center.x + r * cos(theta)
	var z = center.z + r * sin(theta)
	return Vector3(x, 0, z)


func start_server():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	load_server()
	print("started server")


func server_disconnected():
	get_tree().quit()


func _on_join_button_pressed(ip_address):
	print("joining ", ip_address)
	#main_menu.hide()
	hud.show()

	enet_peer.create_client(ip_address, PORT)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(server_disconnected)
	multiplayer.multiplayer_peer = enet_peer


func _on_connected_to_server():
	register_player.rpc_id(1, player_id)


@rpc("any_peer", "reliable")
func register_player(player_id):
	var peer_id = multiplayer.get_remote_sender_id()
	add_player(peer_id, player_id)
	send_world_age.rpc_id(peer_id, Time.get_ticks_msec() + world.world_age)


@rpc("authority", "call_local", "reliable")
func send_world_age(_world_age):
	if multiplayer.get_remote_sender_id() != 1:
		print("someone else trying to call send_world_age")
		return
	world.world_age = _world_age


func add_player(_peer_id, _player_id):
	print("%s connected" % _player_id)
	#first check if this player already has a node
	var player = players.get_node_or_null(_player_id)
	if !player:
		player = PLAYER_SCENE.instantiate()
		player.name = _player_id
		player.player_id = _player_id

		player.position.x = RandomNumberGenerator.new().randi_range(-5, 5)
		player.position.z = RandomNumberGenerator.new().randi_range(-5, 5)
		players.add_child(player)


func _ready():
	#var signals=load("res://Signals.cs").new()

	var config_file = ConfigFile.new()
	# Load data from a file.
	#var err = config.load("user://config.cfg")
	var err = config_file.load("res://config.cfg")
	# If the file didn't load, ignore it.
	if err != OK:
		print("error reading config file")

	var config = {}
	config.player_id = config_file.get_value("default", "player_id", "")
	config.remote_ip = config_file.get_value("default", "remote_ip", "")
	config.server = config_file.get_value("default", "server", false)

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
		#main_menu.hide()
		hud.show()
		#health_bar.hide()
		server_camera.show()
		server_camera.current = true
		get_viewport().get_window().title += " - SERVER"
	elif config.has("player_id"):
		player_id = config["player_id"]
		start_client()
		_on_join_button_pressed(config.remote_ip)
		get_viewport().get_window().title += " - " + player_id
		print("started client")
	else:
		print("not a client nor a server")


func update_turn_number(value):
	turn_number = value
	turn_number_label.text = "turn " + str(value)
	turn_start = Time.get_ticks_msec()
	Signals.NewTurn.emit(turn_number)


func _on_host_button_pressed():
	#main_menu.hide()
	hud.show()
	start_server()
	#add_player(multiplayer.get_unique_id())


func _unhandled_input(_event):
	var player: MarbleCharacter = get_player(player_id)

	if Input.is_action_just_pressed("long_rest"):
		var minutes = 8 * 60
		if multiplayer.is_server():
			player.time_warp(minutes)
		else:
			player.time_warp.rpc_id(1, minutes)

	if Input.is_action_just_pressed("short_rest"):
		var minutes = 60
		if multiplayer.is_server():
			player.time_warp(minutes)
		else:
			player.time_warp.rpc_id(1, minutes)

	if Input.is_action_just_pressed("quit"):
		if multiplayer.is_server():
			save_server()
		else:
			save_client()
		get_tree().quit()


func get_player(player_id) -> MarbleCharacter:
	var p = players.get_node_or_null(player_id)
	return p


func _process(_delta):
	var now = Time.get_ticks_msec()

	if multiplayer.is_server():
		turn_timer.value = (now + world.world_age) % 6000
		var new_turn_number = (now + world.world_age) / (6 * 1000) + 1
		if turn_number != new_turn_number:
			turn_number = new_turn_number

	else:
		turn_timer.value = (now - turn_start) % 6000


func save_node():
	var save_dict = {
		#
		"host_player_id": player_id
	}
	return save_dict


func load_node(node_data):
	if "host_player_id" in node_data:
		player_id = node_data.host_player_id


func save_client():
	var save_file = FileAccess.open("user://%s.save" % player_id, FileAccess.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("persist-client")
	for node in save_nodes:
		# Check the node has a save function.
		if !node.has_method("save_node"):
			print(
				"client persistent node '%s' is missing a save_node() function, skipped" % node.name
			)
			print(node)
			continue

		# Call the node's save function.
		var node_data: Dictionary = node.call("save_node")

		node_data.name = node.name
		node_data.parent = node.get_parent().get_path()
		node_data.class = node.get_class()
		node_data.scene_file_path = node.get_scene_file_path()

		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data, "", false)
		#var json_string = JSON.stringify(node_data,"\t",false)

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(json_string)
	#save_file.close()
	save_file.flush()
	print("saved ", save_file.get_path_absolute())
	DirAccess.copy_absolute(
		save_file.get_path_absolute(),
		"user://savegame_" + str(Time.get_ticks_msec() + world.world_age) + ".save"
	)


func save_server():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)

	var save_nodes = get_tree().get_nodes_in_group("persist")
	for node in save_nodes:
		# Check the node has a save function.
		if !node.has_method("save_node"):
			print("persistent node '%s' is missing a save_node() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data: Dictionary = node.call("save_node")

		node_data.name = node.name
		node_data.parent = node.get_parent().get_path()
		node_data.class = node.get_class()
		node_data.scene_file_path = node.get_scene_file_path()

		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data, "", false)
		#var json_string = JSON.stringify(node_data,"\t",false)

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(json_string)
	#save_file.close()
	save_file.flush()
	print("saved ", save_file.get_path_absolute())
	DirAccess.copy_absolute(
		save_file.get_path_absolute(),
		"user://savegame_" + str(Time.get_ticks_msec() + world.world_age) + ".save"
	)


func start_client():
	pass
	#load_client()


func load_client():
	print("load client %s" % player_id)
	if not FileAccess.file_exists("user://%s.save" % player_id):
		print("client save not found")
		return  # Error! We don't have a save to load.

	var save_file = FileAccess.open("user://%s.save" % player_id, FileAccess.READ)
	var json = JSON.new()
	var parse_result
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		parse_result = json.parse(json_string)
		if not parse_result == OK:
			print(
				"JSON Parse Error: ",
				json.get_error_message(),
				" in ",
				json_string,
				" at line ",
				json.get_error_line()
			)
			continue

		# Get the data from the JSON object.
		var node_data = json.data

		# Firstly, we need to create the object and add it to the tree
		# check if the node is in the tree already
		var node = get_node_or_null(node_data.parent + "/" + node_data.name)
		if !node and node_data["scene_file_path"]:
			node = load(node_data["scene_file_path"]).instantiate()
		elif !node and node_data["class"]:
			node = ClassDB.instantiate(node_data.class)
		else:
			print("did not find node in tree and not enough info to instantiate")
			print(node_data)
		# Check the node has a load function.
		if !node.has_method("load_node"):
			print(
				"client persistent node '%s' is missing a load_node() function, skipped" % node.name
			)
			print(node.name)
			continue
		node.call("load_node", node_data)
		node.name = node_data.name
		if !node.get_parent():
			get_node_or_null(node_data["parent"]).add_child(node)


func load_server():
	if not FileAccess.file_exists("user://savegame.save"):
		print("save not found")
		return  # Error! We don't have a save to load.

	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var json = JSON.new()
	var parse_result
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		parse_result = json.parse(json_string)
		if not parse_result == OK:
			print(
				"JSON Parse Error: ",
				json.get_error_message(),
				" in ",
				json_string,
				" at line ",
				json.get_error_line()
			)
			continue

		# Get the data from the JSON object.
		var node_data = json.data

		# Firstly, we need to create the object and add it to the tree
		# check if the node is in the tree already
		var node = get_node_or_null(node_data.parent + "/" + node_data.name)
		if !node and node_data["scene_file_path"]:
			node = load(node_data["scene_file_path"]).instantiate()
		elif !node and node_data["class"]:
			node = ClassDB.instantiate(node_data.class)
		else:
			pass
		# Check the node has a load function.
		if !node.has_method("load_node"):
			print("persistent node '%s' is missing a load() function, skipped" % node.name)
			continue
		node.call("load_node", node_data)
		node.name = node_data.name
		if !node.get_parent():
			get_node_or_null(node_data["parent"]).add_child(node)
