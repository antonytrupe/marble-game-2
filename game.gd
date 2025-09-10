class_name Game
extends Node

const PORT = 9999
const CHARACTER_SCENE = preload("res://character/character.tscn")
const STONE_SCENE = preload("res://objects/stone/stone.tscn")
const ACORN_SCENE = preload("res://objects/acorn/acorn.tscn")
const BUSH_SCENE = preload("res://objects/bush/bush.tscn")
const TREE_SCENE = preload("res://objects/tree/tree.tscn")
const MOB_SCENE = preload("res://objects/monster/monster.tscn")
const WARP_VOTE_SCENE = preload("res://ui/warp_vote/warp_vote.tscn")
const ROOT_WINDOW_SCRIPT = preload("res://root_window.gd")

var auth_ticket: Dictionary  # Your auth ticket
var client_auth_tickets: Array  # Array of tickets from other clients

#var multiplayer_peer = ENetMultiplayerPeer.new()
var player_id: String
var is_server: bool = false
@export var player_data = {}

@onready var inventory_ui: PlayerInventory = %InventoryUI
@onready var inventory_ui_window = %InventoryUIWindow
@onready var craft_ui = %CraftUI
@onready var craft_ui_window = %CraftUIWindow
@onready var trade_ui: PlayerInteraction = %PlayerInteractionUI
@onready var trade_ui_window = %PlayerInteractionWindow
@onready var hud = $UI/HUD
@onready var server_camera = $CameraPivot/ServerCamera3D
@onready var world = %World
@onready var characters = %Characters
@onready var cross_hair = %CrossHair
@onready var chunks: Chunks = %Chunks
@onready var turn_timer: TurnTimerUI = %TurnTimer
@onready var warp_settings: WarpSettingsUI = %WarpSettings
@onready var day_night_cycle = %DayNightCycle


func _set_current_player(character: MarbleCharacter):
	player_id = character.player_id
	# player_data[player_id]=character.name
	cross_hair.show()
	inventory_ui.me = character
	craft_ui.me = character
	trade_ui.me = character
	turn_timer.character = character
	warp_settings.character = character
	day_night_cycle.character = character


# Callback from getting the auth ticket from Steam
func _on_get_auth_session_ticket_response(this_auth_ticket: int, result: int) -> void:
	print("Auth session result: %s" % result)
	print("Auth session ticket handle: %s" % this_auth_ticket)


# Callback from attempting to validate the auth ticket
func _on_validate_auth_ticket_response(auth_id: int, response: int, owner_id: int) -> void:
	print("Ticket Owner: %s" % auth_id)

	# Make the response more verbose, highly unnecessary but good for this example
	var verbose_response: String
	match response:
		0:
			verbose_response = (
				"Steam has verified the user is online, the ticket is valid "
				+ "and ticket has not been reused."
			)
		1:
			verbose_response = "The user in question is not connected to Steam."
		2:
			verbose_response = "The user doesn't have a license for this App ID or the ticket has expired."
		3:
			verbose_response = "The user is VAC banned for this game."
		4:
			verbose_response = (
				"The user account has logged in elsewhere and the session containing "
				+ "the game instance has been disconnected."
			)
		5:
			verbose_response = "VAC has been unable to perform anti-cheat checks on this user."
		6:
			verbose_response = "The ticket has been canceled by the issuer."
		7:
			verbose_response = "This ticket has already been used, it is not valid."
		8:
			verbose_response = "This ticket is not from a user instance currently connected to steam."
		9:
			verbose_response = (
				"The user is banned for this game. The ban came via the Web API " + "and not VAC."
			)
	print("Auth response: %s" % verbose_response)
	print("Game owner ID: %s" % owner_id)


func validate_auth_session(ticket: Dictionary, steam_id: int) -> void:
	var auth_response: int = Steam.beginAuthSession(ticket.buffer, ticket.size, steam_id)

	# Get a verbose response; unnecessary but useful in this example
	var verbose_response: String
	match auth_response:
		0:
			verbose_response = "Ticket is valid for this game and this Steam ID."
		1:
			verbose_response = "The ticket is invalid."
		2:
			verbose_response = "A ticket has already been submitted for this Steam ID."
		3:
			verbose_response = "Ticket is from an incompatible interface version."
		4:
			verbose_response = "Ticket is not for this game."
		5:
			verbose_response = "Ticket has expired."
	print("Auth verifcation response: %s" % verbose_response)

	if auth_response == 0:
		print("Validation successful, adding user to client_auth_tickets")
		client_auth_tickets.append({"id": steam_id, "ticket": ticket.id})

	# You can now add the client to the game


func _ready():
	Signals.CurrentPlayer.connect(_set_current_player)

	Steam.get_auth_session_ticket_response.connect(_on_get_auth_session_ticket_response)
	Steam.validate_auth_ticket_response.connect(_on_validate_auth_ticket_response)

	if Steam.isSteamRunning():
		print("steam is running")
	else:
		print("steam is not running")

	var steam_id = Steam.getSteamID()
	print("steam_id:", steam_id)
	var steam_persona_name = Steam.getFriendPersonaName(steam_id)
	print("steam_persona_name:", steam_persona_name)

	var view_port: Window
	view_port = get_tree().get_root().get_window()
	view_port.set_script(ROOT_WINDOW_SCRIPT)
	view_port.add_to_group("persist-client")

	var config_file = ConfigFile.new()
	# Load data from a file.
	var err = config_file.load("res://config.cfg")
	# If the file didn't load, ignore it.
	if err != OK:
		print("error reading config file")

	var config = {server = false}

	for key in config_file.get_section_keys("default"):
		config[key] = config_file.get_value("default", key, "")

	#print("config:", config)

	var arguments = {}
	for argument in OS.get_cmdline_user_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""

	#print("arguments:", arguments)
	config.merge(arguments, true)

	if steam_id and !config.has("player_id"):
		config["player_id"] = "steam:" + str(steam_id)

	#print("merged:", config)
	if config.has("player_id"):
		print("client")
		#server_camera.hide()
		#server_camera.current = false
		player_id = config["player_id"]
		_load_client()

		get_viewport().get_window().title += " - " + player_id
		if not config.server:
			print("just client")
			_create_client(config.remote_ip)

	if config.server:
		print("server")
		is_server = true
		_create_server()
		if not config.has("player_id"):
			print("just server")

			server_camera.show()
			server_camera.current = true
		else:
			_register_player(player_id)
		get_viewport().get_window().title += " - SERVER"

	if not config.server and not config.has("player_id"):
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

	if craft_ui_window.visible or inventory_ui_window.visible or trade_ui_window.visible:
		#or warp_vote_window.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		cross_hair.visible = false
	else:
		cross_hair.visible = true


func _spawn_stones(quantity: int, p: Vector3):
	quantity = clampi(quantity, 1, 100)
	for i in quantity:
		var stone = STONE_SCENE.instantiate()
		stone.name = stone.name + "%010d" % randi()
		stone.global_position = _get_random_vector(10, p)
		var chunk: Chunk = chunks.get_chunk(stone.global_position)
		chunk.terra.add_child(stone)


func command(cmd: String, player: MarbleCharacter):
	if !multiplayer.is_server():
		print("not server")
		return
	var parts: PackedStringArray = cmd.replace("/", "").split(" ")
	match parts[0]:
		"s", "switch":
			print("switch")
			var target = player.get_target()
			if target:
				print(target.name)
				print(target)
				Signals.CurrentPlayer.emit(target)
			else:
				print("no target")
		"teleport":
			if parts.size() >= 4:
				player.position = Vector3(float(parts[1]), float(parts[2]), float(parts[3]))
		"wander":
			var count = 10
			if parts.size() >= 2:
				count = int(parts[1])
			player._wander(count)
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
				"mob", "monster":
					var count = 1
					if parts.size() >= 3:
						count = int(parts[2])
					_spawn_mob(count, player.position)
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
		acorn.name = acorn.name + "%010d" % randi()
		acorn.global_position = _get_random_vector(10, center)
		var chunk = chunks.get_chunk(acorn.global_position)
		chunk.flora.add_child(acorn)


func _spawn_bushes(count: int, center: Vector3):
	count = clampi(count, 1, 100)
	for i in count:
		var bush = BUSH_SCENE.instantiate()
		bush.name = bush.name + "%010d" % randi()
		bush.global_position = _get_random_vector(10, center)
		var chunk = chunks.get_chunk(bush.global_position)
		chunk.flora.add_child(bush)


func _spawn_trees(count: int, center: Vector3):
	count = clampi(count, 1, 100)
	for i in count:
		var tree = TREE_SCENE.instantiate()
		tree.name = tree.name + "%010d" % randi()
		#TODO do this more righter
		tree.global_position = _get_random_vector(10, center)
		var chunk = chunks.get_chunk(tree.global_position)
		chunk.flora.add_child(tree)


func _spawn_mob(count: int, center: Vector3):
	for i in count:
		var mob = MOB_SCENE.instantiate()
		mob.name = mob.name + "%010d" % randi()
		var chunk = chunks.get_chunk(center)
		var y = randf_range(0, PI)
		print("y:", y)  # Debug

		mob.rotation.y = y
		chunk.fauna.add_child(mob)

		print("After rotation:", mob.rotation.y)  # Debug
		mob.position = _get_random_vector(10, center)


func _get_random_vector(radius: float, center: Vector3) -> Vector3:
	#var rng = RandomNumberGenerator.new()
	var r = radius * sqrt(randf())
	var theta = randf() * 2 * PI
	var x = center.x + r * cos(theta)
	var z = center.z + r * sin(theta)
	return Vector3(x, 0, z)


func _create_server():
	var multiplayer_peer = ENetMultiplayerPeer.new()
	multiplayer_peer.create_server(PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	_load_server()
	print("started server")


func _server_disconnected():
	_save_client()
	get_tree().quit()


func _create_client(ip_address):
	print("joining ", ip_address)
	hud.show()
	var multiplayer_peer = ENetMultiplayerPeer.new()
	multiplayer_peer.create_client(ip_address, PORT)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.multiplayer_peer = multiplayer_peer


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
	print("%s connected %s" % [_player_id, _peer_id])

	var character_name
	var character
	# check if this player has a current character
	if player_data.has(_player_id):
		character_name = player_data[_player_id]
		character = characters.get_node_or_null(NodePath(character_name))

	if !character:
		print("making a new character for %s" % _player_id)
		character = CHARACTER_SCENE.instantiate()
		character.name = _player_id
		character.player_id = _player_id

		character.position.x = RandomNumberGenerator.new().randi_range(-5, 5)
		character.position.z = RandomNumberGenerator.new().randi_range(-5, 5)

		player_data[_player_id] = character.name
		characters.add_child(character)

	character.peer_id = _peer_id


func get_player(id) -> MarbleCharacter:
	var p = characters.get_node_or_null(id)
	return p


func get_chunk(id) -> Chunk:
	var c = chunks.get_node_or_null(id)
	return c


func save_node():
	var save_dict = {
		#
		#host_player_id = player_id,
		#position = 0,
		#player_data = player_data,
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
		save_file.get_path_absolute(), "user://savegame_" + str(Time.get_ticks_msec()) + ".save"
	)


#func _start_client():
#_load_client()
#get_viewport().get_window().title += " - " + player_id


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
