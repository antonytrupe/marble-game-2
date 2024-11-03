extends Node

@onready var main_menu = $UI/MainMenu
@onready var address_entry = $UI/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $UI/HUD
@onready var health_bar = $UI/HUD/HealthBar
@onready var turnNumberLabel=$UI/HUD/TurnTimer/TurnNumber
@onready var turnTimer=$UI/HUD/TurnTimer
@onready var serverCamera=$Node3D/ServerCamera3D
@onready var world=$"."

@export var turn_number=1:
	set = update_turn_number

const Player = preload("res://player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()
var turn_start=0
@export var server_age=0
var player_id

#var sf= SurfaceTool.new()

func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"server_age":server_age+Time.get_ticks_msec()
	}
	return save_dict

func save_game():
	print('save_game')
	var save_file = FileAccess.open('user://savegame.save', FileAccess.WRITE)
	#var save_file = FileAccess.open('user://savegame_'+str(Time.get_ticks_msec())+'.save', FileAccess.WRITE)

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
	var backup = FileAccess.open('user://savegame_'+str(Time.get_ticks_msec()+server_age)+'.save', FileAccess.WRITE)
	backup.store_string(save_file.get_as_text())
	save_file.close()
	backup.close()

func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	#var save_nodes = get_tree().get_nodes_in_group("Persist")
	#for i in save_nodes:
		#i.queue_free()
		

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	#process world node
	var world_line=save_file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(world_line)
	if(json.data.has("server_age")):
		world.server_age=int(json.data["server_age"])
	#TODO process player nodes
	while false and save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var node_data = json.data

		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instantiate()
		get_node(node_data["parent"]).add_child(new_object)
		#new_object.position = Vector3(node_data["pos_x"], node_data["pos_y"], node_data["pos_z"])

		# Now we set the remaining variables.
		for i in node_data.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
				continue
			new_object.set(i, node_data[i])

func _ready():
	var arguments = {}
	for argument in OS.get_cmdline_user_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""
	
	print(arguments)
	if arguments.has("server"):
		start_server()
		main_menu.hide()
		hud.show()
		health_bar.hide()
		serverCamera.show()
		serverCamera.current=true
	else:
		player_id=arguments['player_id']

func _process(_delta):
	var now=Time.get_ticks_msec()
	
	if multiplayer.is_server():
		turnTimer.value=(now+server_age)%6000
		var newTurnNumber = (now+server_age) / (6 * 1000) +1
		if ( turn_number!=newTurnNumber):
			turn_number=newTurnNumber
	else:
		turnTimer.value=(now-turn_start)%6000

func update_turn_number(value):
	turn_number=value
	turnNumberLabel.text='turn '+ str(value)
	turn_start=Time.get_ticks_msec()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		if(multiplayer.is_server()):
			save_game()
		get_tree().quit()

func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	start_server()
	add_player(multiplayer.get_unique_id())

func start_server():
	print('start_server')
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	#multiplayer.peer_disconnected.connect(remove_player)
	load_game()

func server_disconnected():
	print('server_disconnected')
	get_tree().quit()

func _on_join_button_pressed():
	main_menu.hide()
	hud.show()

	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(server_disconnected)
	multiplayer.multiplayer_peer = enet_peer
	print(player_id)
	#await get_tree().create_timer(0.5).timeout
	#world.register_player.rpc_id(1,player_id)

func _on_connected_to_server():
	print('_on_connected_to_server')
	world.register_player.rpc_id(1,player_id)

func _on_multiplayer_spawner_spawned(node):
	#TODO
	if true:
		node.health_changed.connect(update_health_bar)

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

func add_player(peer_id):
	#first check if this player already has a node
	#_register_player.rpc_id(peer_id, player_id)
	
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	print('add_player ',player.name)
	#if player.is_multiplayer_authority():
	#if multiplayer.get_unique_id()==str(name).to_int():
		#player.health_changed.connect(update_health_bar)

@rpc("any_peer", "reliable")
func register_player(new_player_info):
	var peer_id = multiplayer.get_remote_sender_id()
	print(peer_id,':',new_player_info)
	players[peer_id] = new_player_info
	#player_connected.emit(new_player_id, new_player_info)
	#var player = Player.instantiate()
	#player.name = str(peer_id)
	#add_child(player)
	#print('add_player ',player.name)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value
