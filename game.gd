class_name Game
extends Node

const PORT = 9999
const PLAYER_SCENE = preload("res://player/player.tscn")
const STONE_SCENE = preload("res://objects/stone/stone.tscn")
const ACORN_SCENE = preload("res://objects/acorn/acorn.tscn")
const BUSH_SCENE = preload("res://objects/bush/bush.tscn")
const TREE_SCENE = preload("res://objects/tree/tree.tscn")
const WARP_VOTE_SCENE = preload("res://ui/warp_vote/warp_vote.tscn")
const ROOT_WINDOW_SCRIPT = preload("res://root_window.gd")

#@export var turn_number = 1:
#set = _update_turn_number,
#get = _get_turn_number

var enet_peer = ENetMultiplayerPeer.new()

#var turn_start = 0
var player_id: String
var is_server: bool = false
var rng = RandomNumberGenerator.new()

@onready var inventory_ui: PlayerInventory = %InventoryUI
@onready var inventory_ui_window = %InventoryUIWindow
@onready var craft_ui = %CraftUI
@onready var craft_ui_window = %CraftUIWindow
@onready var trade_ui: PlayerInteraction = %PlayerInteractionUI
@onready var trade_ui_window = %PlayerInteractionWindow
@onready var hud = $UI/HUD
@onready var server_camera = $CameraPivot/ServerCamera3D
@onready var world = %World
@onready var players = %Players
@onready var cross_hair = %CrossHair
@onready var chunks: Chunks = %Chunks
@onready var turn_timer:TurnTimerUI =%TurnTimer
@onready var warp_settings:WarpSettingsUI=%WarpSettings
@onready var day_night_cycle=%DayNightCycle

func _set_current_player(player:MarbleCharacter):
	cross_hair.show()
	inventory_ui.me = player
	craft_ui.me = player
	trade_ui.me = player
	turn_timer.player=player
	warp_settings.player=player
	day_night_cycle.player=player

func _ready():
	Signals.CurrentPlayer.connect(_set_current_player)

	var view_port: Window
	view_port = get_tree().get_root().get_window()
	view_port.set_script(ROOT_WINDOW_SCRIPT)
	view_port.add_to_group("persist-client")

	var config_file = ConfigFile.new()
	# Load data from a file.
	#var err = config.load("user://config.cfg")
	var err = config_file.load("res://config.cfg")
	# If the file didn't load, ignore it.
	if err != OK:
		print("error reading config file")

	var config = {server = false}

	for key in config_file.get_section_keys("default"):
		config[key] = config_file.get_value("default", key, "")

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
		is_server = true
		_start_server()
		#main_menu.hide()
		hud.show()
		#health_bar.hide()
		server_camera.show()
		server_camera.current = true
		get_viewport().get_window().title += " - SERVER"
	#TODO make this an if
	elif config.has("player_id"):
		player_id = config["player_id"]
		_start_client()
		_create_client(config.remote_ip)
		#get_viewport().get_window().title += " - " + player_id
		print("started client")
	else:
		print("not a client nor a server")


func _unhandled_input(_event):
	if Input.is_action_just_pressed("inventory"):
		inventory_ui_window.visible = !inventory_ui_window.visible

	if Input.is_action_just_pressed("craft"):
		craft_ui_window.visible = !craft_ui_window.visible
		if craft_ui_window.visible:
			inventory_ui_window.show()
		else:
			inventory_ui_window.hide()

	if Input.is_action_just_pressed("long_rest"):
		if multiplayer.is_server():
			pass
		else:
			pass

	if Input.is_action_just_pressed("short_rest"):
		if multiplayer.is_server():
			pass
		else:
			pass

	if Input.is_action_just_pressed("quit"):
		if inventory_ui_window.visible:
			#get_viewport().set_input_as_handled()
			inventory_ui_window.hide()

		elif craft_ui_window.visible:
			craft_ui_window.hide()
			#get_viewport().set_input_as_handled()

		else:
			if is_server:
				_save_server()

			_save_client()
			get_tree().quit()

	if (
		craft_ui_window.visible
		or inventory_ui_window.visible
		or trade_ui_window.visible
		#or warp_vote_window.visible
	):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		cross_hair.visible = false
	else:
		cross_hair.visible = true




func _spawn_stones(quantity: int, p: Vector3):
	quantity = clampi(quantity, 1, 100)
	for i in quantity:
		var stone = STONE_SCENE.instantiate()
		stone.name = stone.name + "%010d" % rng.randi()
		stone.global_position = _get_random_vector(10, p)
		var chunk: Chunk = chunks.get_chunk(stone.global_position)
		chunk.terra.add_child(stone)


func command(cmd: String, player: MarbleCharacter):
	if !multiplayer.is_server():
		return
	var parts: PackedStringArray = cmd.replace("/", "").split(" ")
	match parts[0]:
		"teleport":
			if parts.size() >= 4:
				player.position=Vector3(float(parts[1]),float(parts[2]),float(parts[3]))
		"wander":
			var count = 10
			if parts.size() >= 2:
				count = int(parts[1])
			player.wander(count)
		"action":
			#todo create the action
			var count = 1
			var frequency = 1
			if parts.size() >= 2:
				count = int(parts[1])
				if parts.size() >= 3:
					frequency = int(parts[2])
			player.add_action(count, frequency)
		"spawn", "/spawn":
			match parts[1]:
				"stone", "stones":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_stones(count, player.position)

				"acorn", "acorns":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					count = clampi(count, 1, 100)
					_spawn_acorns(count, player.position)

				"bush", "bushes":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_bushes(count, player.position)

				"tree", "trees":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_trees(count, player.position)


func _spawn_acorns(count: int, center: Vector3):
	count = clampi(count, 1, 100)
	for i in count:
		var acorn = ACORN_SCENE.instantiate()
		acorn.name = acorn.name + "%010d" % rng.randi()
		acorn.global_position = _get_random_vector(10, center)
		var chunk = chunks.get_chunk(acorn.global_position)
		chunk.flora.add_child(acorn)


func _spawn_bushes(count: int, center: Vector3):
	count = clampi(count, 1, 100)
	for i in count:
		var bush = BUSH_SCENE.instantiate()
		bush.name = bush.name + "%010d" % rng.randi()
		bush.global_position = _get_random_vector(10, center)
		var chunk = chunks.get_chunk(bush.global_position)
		chunk.flora.add_child(bush)


func _spawn_trees(count: int, center: Vector3):
	count = clampi(count, 1, 100)
	for i in count:
		var tree = TREE_SCENE.instantiate()
		tree.name = tree.name + "%010d" % rng.randi()
		#TODO do this more righter
		tree.global_position = _get_random_vector(10, center)
		var chunk = chunks.get_chunk(tree.global_position)
		chunk.flora.add_child(tree)


func _get_random_vector(radius: float, center: Vector3) -> Vector3:
	#var rng = RandomNumberGenerator.new()
	var r = radius * sqrt(rng.randf())
	var theta = rng.randf() * 2 * PI
	var x = center.x + r * cos(theta)
	var z = center.z + r * sin(theta)
	return Vector3(x, 0, z)


func _start_server():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	_load_server()
	print("started server")


func _server_disconnected():
	_save_client()
	get_tree().quit()


func _create_client(ip_address):
	print("joining ", ip_address)
	hud.show()

	enet_peer.create_client(ip_address, PORT)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.multiplayer_peer = enet_peer


func _on_connected_to_server():
	_register_player.rpc_id(1, player_id)


@rpc("any_peer", "reliable")
func _register_player(_player_id):
	var peer_id = multiplayer.get_remote_sender_id()
	_add_player(peer_id, _player_id)
	#send_world_age.rpc_id(peer_id, Time.get_ticks_msec() + world.world_age)


@rpc("authority", "call_local", "reliable")
func send_world_age(_world_age):
	if multiplayer.get_remote_sender_id() != 1:
		print("someone else trying to call send_world_age")
		return
	world.world_age = _world_age


func _add_player(_peer_id, _player_id):
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
	player.peer_id = _peer_id


#func _update_turn_number(value):
#turn_number = value
##turn_number_label.text = "turn " + str(value)
#turn_start = Time.get_ticks_msec()
#Signals.NewTurn.emit(turn_number)

#func _get_turn_number():
#return turn_number


func _on_host_button_pressed():
	hud.show()
	_start_server()


func get_player(id) -> MarbleCharacter:
	var p = players.get_node_or_null(id)
	return p


func get_chunk(id) -> Chunk:
	var c = chunks.get_node_or_null(id)
	return c


func save_node():
	# print(get_viewport().get_window().position)
	# print(get_viewport().get_window().current_screen)
	var save_dict = {
		#
		host_player_id = player_id,
		position = 0,
	}
	return save_dict


func load_node(node_data):
	for p in node_data:
		if p in self and p not in ["transform", "parent"]:
			self[p] = node_data[p]


func _save_client():
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
		if node.get_parent():
			node_data.parent = node.get_parent().get_path()
		else:
			node_data.parent = ""
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
	#TODO backup client saves
	#DirAccess.copy_absolute(
	#save_file.get_path_absolute(),
	#"user://savegame_" + str(Time.get_ticks_msec() + world.world_age) + ".save"
	#)


func _save_server():
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
		if node.get_parent():
			node_data.parent = node.get_parent().get_path()
		else:
			node_data.parent = ""
		#class only returns native classes, not custom class_name
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
		"user://savegame_" + str(Time.get_ticks_msec()) + ".save"
	)


func _start_client():
	_load_client()
	get_viewport().get_window().title += " - " + player_id


func _load_client():
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
		elif !node:
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
		if !node.get_parent() and node_data.parent:
			get_node_or_null(node_data["parent"]).add_child(node)


func _load_server():
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
			var parent = get_node_or_null(node_data["parent"])
			if parent:
				parent.add_child(node)
