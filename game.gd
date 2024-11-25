extends Node3D
class_name Game

const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

@onready var main_menu = $UI/MainMenu
@onready var hud = $UI/HUD
@onready var terra = %Terra
@onready var flora = %Flora
@onready var turnNumberLabel = %TurnNumber
@onready var turnTimer = %TurnTimer
@onready var serverCamera = $CameraPivot/ServerCamera3D
@onready var world = %World
@onready var worldTime = %WorldTimeLabel
@onready var players = %Players

@export var turn_number = 1:
	set = update_turn_number

var turn_start = 0
var player_id: String
# This will contain player info for every player,
# with the keys being each player's unique IDs.
#var players = {}

const Player = preload("res://player.tscn")
const Stone = preload("res://stone/stone.tscn")
const Acorn = preload("res://acorn/acorn.tscn")
const Bush = preload("res://bush/bush.tscn")
const Tree_ = preload("res://tree/tree.tscn")


func command(cmd: String, player: MarbleCharacter):
	if !multiplayer.is_server():
		return
	#print("server game command:", cmd)
	var parts = cmd.replace("/", "").split(" ")
	#print(parts)
	match parts[0]:
		"spawn", "/spawn":
			#print("spawn")
			var rng = RandomNumberGenerator.new()
			match parts[1]:
				"stone", "stones":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 10)
					for i in count:
						var stone = Stone.instantiate()
						stone.name = stone.name + "%010d" % rng.randi()
						stone.position = get_random_vector(10, player.position)
						terra.add_child(stone)
				"acorn":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 10)
					for i in count:
						var acorn = Acorn.instantiate()
						acorn.name = acorn.name + "%010d" % rng.randi()
						acorn.position = get_random_vector(10, player.position)
						flora.add_child(acorn)
				"bush":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 10)
					for i in count:
						var bush = Bush.instantiate()
						bush.name = bush.name + "%010d" % rng.randi()
						bush.position = get_random_vector(10, player.position)
						flora.add_child(bush)
				"tree", "trees":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 10)
					for i in count:
						var tree = Tree_.instantiate()
						tree.name = tree.name + "%010d" % rng.randi()
						tree.position = get_random_vector(10, player.position)
						flora.add_child(tree)


func get_random_vector(R: float, center: Vector3) -> Vector3:
	var rng = RandomNumberGenerator.new()
	var r = R * sqrt(rng.randf())
	var theta = rng.randf() * 2 * PI
	var x = center.x + r * cos(theta)
	var z = center.z + r * sin(theta)
	return Vector3(x, 0, z)


func start_server():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	load_game()
	print("started server")


func server_disconnected():
	get_tree().quit()


func _on_join_button_pressed(ip_address):
	print("joining ", ip_address)
	main_menu.hide()
	hud.show()

	enet_peer.create_client(ip_address, PORT)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(server_disconnected)
	multiplayer.multiplayer_peer = enet_peer


func _on_connected_to_server():
	register_player.rpc_id(1, player_id)


@rpc("any_peer", "reliable")
func register_player(new_player_info):
	var peer_id = multiplayer.get_remote_sender_id()
	#players[peer_id] = new_player_info
	add_player(peer_id, new_player_info)
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
		player = Player.instantiate()
		player.name = _player_id
		player.player_id = _player_id
		#TODO make sure player isn't colliding with existing player
		#PhysicsServer3D.space_get_direct_state(0)
		get_world_3d().space.get_id()
		#As per docs
		#var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		#params.shape_rid = player.get_rid()
		#print(player.get_rid())
		#print(player.get_shape_owners())
		#params.shape = player
		#params.transform = player.transform
		#params.collide_with_bodies = true
		#params.collide_with_areas = true
		#var i = get_world_3d().direct_space_state.intersect_shape(params)
		#var i = get_world_3d().direct_space_state.collide_shape(params)
		#print(i)
		#if i:
			#print("found overlap")
		player.position.x = RandomNumberGenerator.new().randi_range(-5, 5)
		player.position.z = RandomNumberGenerator.new().randi_range(-5, 5)
		players.add_child(player)


func _ready():
	#var signals=load("res://Signals.cs").new()

	var configFile = ConfigFile.new()
	# Load data from a file.
	#var err = config.load("user://config.cfg")
	var err = configFile.load("res://config.cfg")
	# If the file didn't load, ignore it.
	if err != OK:
		print("error reading config file")

	var config = {}
	config.player_id = configFile.get_value("default", "player_id", "")
	config.remote_ip = configFile.get_value("default", "remote_ip", "")
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
		#health_bar.hide()
		serverCamera.show()
		serverCamera.current = true
		get_viewport().get_window().title += " - SERVER"
	elif config.has("player_id"):
		player_id = config["player_id"]
		_on_join_button_pressed(config.remote_ip)
		get_viewport().get_window().title += " - " + player_id
		print("started client")
	else:
		print("not a client nor a server")


func update_turn_number(value):
	turn_number = value
	turnNumberLabel.text = "turn " + str(value)
	turn_start = Time.get_ticks_msec()
	Signals.NewTurn.emit(turn_number)


func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	start_server()
	#add_player(multiplayer.get_unique_id())


func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		if multiplayer.is_server():
			save_game()
		get_tree().quit()


func _process(_delta):
	var now = Time.get_ticks_msec()

	var age = GameTime.get_age_parts(world.calculated_age)
	worldTime.text = "%d years, %d months, %d days, %02d:%02d:%02d" % [age.years, age.months, age.days, age.hours, age.minutes, age.seconds]

	if multiplayer.is_server():
		turnTimer.value = (now + world.world_age) % 6000
		var newTurnNumber = (now + world.world_age) / (6 * 1000) + 1
		if turn_number != newTurnNumber:
			turn_number = newTurnNumber

	else:
		turnTimer.value = (now - turn_start) % 6000


func save():
	var save_dict = {
		#
		"host_player_id": player_id
	}
	return save_dict


func load(node_data):
	if "host_player_id" in node_data:
		player_id = node_data.host_player_id


func save_game():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)

	var save_nodes = get_tree().get_nodes_in_group("persist")
	for node in save_nodes:
		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data: Dictionary = node.call("save")

		node_data.name = node.name
		node_data.parent = node.get_parent().get_path()
		node_data. class = node.get_class()
		node_data.scene_file_path = node.get_scene_file_path()

		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data, "", false)
		#var json_string = JSON.stringify(node_data,"\t",false)

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(json_string)
	#save_file.close()
	save_file.flush()
	print("saved ", save_file.get_path_absolute())
	DirAccess.copy_absolute(save_file.get_path_absolute(), "user://savegame_" + str(Time.get_ticks_msec() + world.world_age) + ".save")


func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		print("save not found")
		return # Error! We don't have a save to load.

	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var json = JSON.new()
	var parse_result
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var node_data = json.data

		# Firstly, we need to create the object and add it to the tree
		# check if the node is in the tree already
		var node = get_node_or_null(node_data.parent + "/" + node_data.name)
		if !node and node_data["scene_file_path"]:
			node = load(node_data["scene_file_path"]).instantiate()
		elif !node and node_data["class"]:
			node = ClassDB.instantiate(node_data. class )
		else:
			pass
		# Check the node has a load function.
		if !node.has_method("load"):
			print("persistent node '%s' is missing a load() function, skipped" % node.name)
			continue
		node.call("load", node_data)
		node.name = node_data.name
		if !node.get_parent():
			get_node_or_null(node_data["parent"]).add_child(node)
