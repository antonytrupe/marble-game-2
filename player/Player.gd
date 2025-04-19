class_name MarbleCharacter
extends CharacterBody3D

const SPEED_MULTIPLIER = 1.0 / 24.0
const JUMP_VELOCITY = 5.0

@export var other_trade_inventory = {}:
	set = _set_other_trade_inventory
@export var other_player_quests = {}:
	set = _set_other_player_quests
@export var trading: bool = false:
	set = _set_trading
@export var my_trade_inventory = {}:
	set = _set_trade_inventory
@export var trade_accepted = false

@export var health = 3
@export var player_id: String
##how fast to go
@export var mode: MOVE.MODE = MOVE.MODE.WALK:
	set = _set_mode
@export var speed = 30.0
#@export var birth_date: int = 0:
#set = _set_birth_date

##seconds
@export var age: float = 0.0:
	set = _set_age

@export var warp_speed: float = 1.0:
	set = _set_warp_speed

@export var turn_number: int = 1:
	set = _set_turn_number

@export var current_turn_actions = {"move": null, "action": null}:
	set = _set_action

#map of name:item
@export var inventory: Dictionary:
	set = _set_inventory

@export var quests = {}:
	set = _set_quests

@export var peer_id: int

@export var skills = {}
##the warp vote this player called
@export var warp_vote: String
##the warp votes this player is in range of
@export var warp_votes = []:
	set = _set_warp_votes

var trade_partner: MarbleCharacter:
	set = _set_trade_partner
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var chat_mode = false

@onready var game: Game = $/root/Game
@onready var world: World = $/root/Game/World
@onready var chat_text_edit: TextEdit = $/root/Game/UI/HUD/ChatInput
@onready var chat_bubbles = %ChatBubbles
@onready var camera_pivot = $CameraPivot
@onready var camera = %Camera3D
@onready var raycast = %RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var chunk_scanner: Area3D = %ChunkScanner
@onready var character_sheet = %CharacterSheet
@onready var quest_creator_ui: QuestManager = %QuestCreator
@onready var actions_ui = %ActionsUI
@onready var fade_anim = %AnimationPlayer

@onready var quest_indicator = %"?"
@onready var warp_scanner:Area3D =%WarpScannerArea3D

func _set_warp_speed(value: float):
	warp_speed = value
	#(warp_scanner.shape as SphereShape3D).radius=(warp_speed-1)*300


@rpc("any_peer")
func set_warp_speed(value: float):
	print("player.set_warp_speed")
	if is_server():
		print("setting world warp speed")
		warp_speed = value


func update_local_warp():
	var local_bodies=warp_scanner.get_overlapping_bodies()
	#local_bodies.all(func(element): return element > 5)
	for body in local_bodies:
		#var distance=body.position.direction_to(position)
		#var ratio=distance/warp_scanner.shape.radius

		body.warp_speed=warp_speed

func wander(count: int):
	var w = Wander.new()
	w.remaining = count
	w.start_turn = game.turn_number
	w.game = game
	w.player = self


func add_action(count: int, frequency: int):
	var a = QuantityAction.new()
	a.remaining = count
	a.frequency = frequency
	#print('a.remaining:',a.remaining)
	a.start_turn = game.turn_number + 1
	a.game = game
	a.player = self


func _ready():
	actions_ui.player_id = player_id
	#Signals.NewTurn.connect(_on_new_turn)
	#if is_server():
	#Signals.PlayerZoned.connect(_on_player_zoned)
	if is_current_player():
		Signals.CurrentPlayer.emit(self)
		camera.current = true
		actions_ui.show()
		game.cross_hair.show()
		game.inventory_ui.me = self
		game.craft_ui.me = self
		game.trade_ui.me = self
		game.warp_vote_ui.me = self
		game.warp_vote_ui.game = game


func _unhandled_input(event):
	if game and !is_current_player():
		return

	var something_visible = false

	if Input.is_action_just_pressed("character_sheet"):
		character_sheet.visible = !character_sheet.visible
		something_visible = something_visible or character_sheet.visible

	if Input.is_action_just_pressed("quest_creator"):
		quest_creator_ui.visible = !quest_creator_ui.visible
		something_visible = something_visible or quest_creator_ui.visible

	if event is InputEventMouseMotion:
		if (
			Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if is_server():
				server_rotate(event.relative)
			else:
				server_rotate.rpc_id(1, event.relative)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_action_just_pressed("quit") and chat_mode:
		#don't let this event bubble up
		get_viewport().set_input_as_handled()
		chat_text_edit.hide()
		chat_text_edit.release_focus()
		chat_mode = false

	if Input.is_action_just_pressed("quit") and trading:
		#don't let this event bubble up
		get_viewport().set_input_as_handled()

		if is_server():
			cancel_trade()
		else:
			cancel_trade.rpc_id(1)

	#if Input.is_action_just_pressed("quit") and inventory_ui_window.visible:
	##don't let this event bubble up
	#get_viewport().set_input_as_handled()
#
	#inventory_ui_window.hide()

	#if Input.is_action_just_pressed("quit") and craft_ui_window.visible:
	##don't let this event bubble up
	#get_viewport().set_input_as_handled()

	#craft_ui_window.hide()

	if Input.is_action_just_pressed("chat"):
		chat_text_edit.visible = !chat_text_edit.visible
		chat_mode = !chat_mode
		if chat_mode:
			chat_text_edit.grab_focus()
		else:
			chat_text_edit.release_focus()
			server_chat.rpc_id(1, chat_text_edit.text)
			chat_text_edit.text = ""


#delta is in seconds
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta * warp_speed

	if is_server():
		age = age + delta * warp_speed * 1000
		#print(age)
		var new_turn_number: int = int(age / 6000 + 1)
		#print(new_turn_number)
		if turn_number != new_turn_number:
			#print('new turn:',new_turn_number)
			turn_number = new_turn_number
			reset_actions()

	if is_current_player() and !chat_mode:
		# TODO check just_press/just_release, or is_pressed?
		# crouch
		if Input.is_action_just_pressed("crouch"):
			if is_server():
				server_mode(MOVE.MODE.CROUCH)
			else:
				server_mode.rpc_id(1, MOVE.MODE.CROUCH)
		if Input.is_action_just_released("crouch"):
			if is_server():
				server_mode(MOVE.MODE.WALK)
			else:
				server_mode.rpc_id(1, MOVE.MODE.WALK)

		# run
		if Input.is_action_just_pressed("run"):
			if is_server():
				server_mode(MOVE.MODE.HUSTLE)
			else:
				server_mode.rpc_id(1, MOVE.MODE.HUSTLE)
		if Input.is_action_just_released("run"):
			if is_server():
				server_mode(MOVE.MODE.WALK)
			else:
				server_mode.rpc_id(1, MOVE.MODE.WALK)

		# Jump
		if Input.is_action_just_pressed("jump") and is_on_floor():
			if is_server():
				server_jump()
			else:
				server_jump.rpc_id(1)

		if Input.is_action_just_pressed("action"):
			if is_server():
				interact()
			else:
				interact.rpc_id(1)
		# Get the input direction and handle the movement/deceleration.
		var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
		if is_server():
			server_move(input_dir)
		else:
			server_move.rpc_id(1, input_dir)

	move_and_slide()


func is_server() -> bool:
	return multiplayer.is_server()


func _set_warp_votes(value):
	warp_votes = value
	if game and game.warp_vote_ui:
		game.warp_vote_ui.update()
	#print()


func skillup(skill, amount):
	if skill not in skills:
		skills[skill] = {level = 1, xp = 0}
	skills[skill].xp += amount


func _set_trade_partner(partner: MarbleCharacter):
	trade_partner = partner
	if trade_partner:
		other_player_quests = trade_partner.quests


func _set_quests(value: Dictionary):
	quests = value
	if quest_indicator:
		if quests.size():
			quest_indicator.show()
		else:
			quest_indicator.hide()
	if quest_creator_ui:
		quest_creator_ui.update()


@rpc("any_peer")
func create_quest(quest: Dictionary):
	if not is_server():
		return
	quests[quest.name] = quest
	quest_creator_ui.update()


@rpc("any_peer")
func delete_quest(quest: Dictionary):
	if not is_server():
		return
	quests.erase(quest.name)


##server code
@rpc("any_peer")
func craft(action: String, tool: Dictionary, reagents: Dictionary):
	if not is_server():
		return
	var scene = load(tool.scene_file_path)
	var instance = scene.instantiate()
	instance.load_node(inventory[tool.name])
	var result = instance.call(action, self, reagents)
	remove_from_inventory(reagents)

	add_to_inventory(result)

	if peer_id:
		game.inventory_ui.update.rpc_id(peer_id)


func _set_other_player_quests(q):
	other_player_quests = q
	if game and game.trade_ui:
		game.trade_ui.other_player_quests = other_player_quests
		game.trade_ui.update()


func _set_other_trade_inventory(loot):
	other_trade_inventory = loot
	if game and game.trade_ui:
		game.trade_ui.other_player_trade = other_trade_inventory
		game.trade_ui.update()


func _set_trade_inventory(loot):
	my_trade_inventory = loot
	if game and game.trade_ui and is_current_player():
		game.trade_ui.update()
	if trade_partner:
		trade_partner.other_trade_inventory = loot


##server code
@rpc("any_peer")
func accept_trade():
	if !is_server():
		return
	trade_accepted = true
	if trade_accepted and trade_partner.trade_accepted:
		#TODO make sure the whole trade will succeed before doing any part
		#swap loot
		if trade_partner.remove_from_inventory(trade_partner.my_trade_inventory):
			add_to_inventory(trade_partner.my_trade_inventory)

		if remove_from_inventory(my_trade_inventory):
			trade_partner.add_to_inventory(my_trade_inventory)
		#clear stuff
		trade_partner.trading = false

		trading = false


##server code
@rpc("any_peer")
func remove_from_trade(loot: Dictionary):
	if !is_server():
		return
	for item in loot.values():
		my_trade_inventory.erase(item.name)


##server code
@rpc("any_peer")
func add_to_trade(item: Dictionary):
	if not is_server():
		return
	if !my_trade_inventory.has(item.name):
		my_trade_inventory[item.name] = item

	trade_partner.other_trade_inventory = my_trade_inventory
	#trade_partner.updateTradeUI.rpc()


func is_current_player():
	return game and player_id and player_id == game.player_id


#is this always on the server?
func _set_trading(value):
	trading = value
	#if the tradeui is ready and this is the current player
	if game and game.trade_ui and is_current_player():
		if trading:
			game.trade_ui.other_player_trade = other_trade_inventory
			game.trade_ui.other_player_quests = other_player_quests

			game.trade_ui.update()

			game.trade_ui_window.show()
			game.inventory_ui_window.show()
		else:
			game.trade_ui_window.hide()
			game.inventory_ui_window.hide()

		game.trade_ui.reset()
		game.inventory_ui.reset()

	if !trading:
		trade_partner = null
		trade_accepted = false
		my_trade_inventory = {}
		other_trade_inventory = {}


#func reset_inventory_ui():
#game.inventory_ui.update()


func _set_inventory(value: Dictionary):
	inventory = value
	if game and game.inventory_ui:
		game.inventory_ui.reset()
	if game and game.trade_ui:
		game.trade_ui.update()
	if game and game.craft_ui:
		game.craft_ui.reset()


#setter, don't call directly
func _set_action(value):
	current_turn_actions = value
	Signals.Actions.emit(player_id, current_turn_actions)


# use reset_actions to clear this and skip internal logic
func set_action(value: Dictionary):
	if value.has("action") and value.action:
		current_turn_actions.action = value.action
	# only update move if we went faster
	if (
		value.has("move")
		and (current_turn_actions.move == null or value.move > current_turn_actions.move)
	):
		current_turn_actions.move = value.move


func reset_actions():
	current_turn_actions = {"move": null, "action": null}


func get_chunks() -> Array[Chunk]:
	var areas = chunk_scanner.get_overlapping_areas()
	var chunks: Array[Chunk] = []
	for area: Area3D in areas:
		chunks.append(area.get_parent())
	return chunks





func _set_turn_number(value):
	turn_number = value


func _set_age(value: float):
	age = value


func _set_mode(new_mode):
	#TODO animations and stuff
	if mode != new_mode:
		if new_mode == MOVE.MODE.CROUCH:
			anim_player.play("crouch")
		elif mode == MOVE.MODE.CROUCH:
			anim_player.play_backwards("crouch")
		else:
			anim_player.play("RESET")
	mode = new_mode


@rpc
func play_animation(animation_name):
	anim_player.play(animation_name)


func load_node(node_data):
	print(node_data)
	player_id = node_data["player_id"]
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	for p in node_data:
		if p in self and p not in ["transform", "parent"]:
			self[p] = node_data[p]
	#TODO figure out camera rotation


func save_node():
	var save_dict = {
		#
		player_id = player_id,
		transform = JSON3D.Transform3DtoDictionary(transform),
		health = health,
		warp_speed = warp_speed,
		age = age,
		inventory = inventory,
		skills = skills,
		quests = quests,
		warp_vote = warp_vote,
		warp_votes = warp_votes,
	}
	return save_dict


#func _on_new_turn(_turn_id):
#reset_actions()

#func _on_player_zoned(player: MarbleCharacter, chunk: Node3D):
#if game.player_id == player.name:
##get all the chunks the player is overlapping
#var chunks = player.get_zones()
#if !chunks:
#print('%s not in any chunks' % [player.name])
## tell the daynightcycle node what chunks the player is in
#dayNightCycle.chunks = chunks

@rpc("authority")
func play_fade():
	fade_anim.play("fade")


#this is the function that runs on the server that any peer can call
@rpc("any_peer")
func server_mode(new_mode: MOVE.MODE):
	if !is_server():
		return
	#if we've used an action, no hustling/running
	if !current_turn_actions.action or [MOVE.MODE.CROUCH, MOVE.MODE.WALK].has(new_mode):
		mode = new_mode


func approve_warp_vote(vote_id: String):
	game.approve_warp.rpc_id(1, vote_id, player_id)


##server code
@rpc("any_peer")
func time_warp(minutes: int):
	if !is_server():
		return

	age = age + 1000 * 60 * minutes
	#TODO update turn number too


#this is the function that runs on the server that any peer can call
@rpc("any_peer", "call_remote", "reliable", 1)
func server_chat(message: String):
	if !is_server():
		return
	if message.begins_with("/"):
		game.command(message, self)
	else:
		client_chat.rpc(message)


#this the function that runs on all the peers that only the server can call
@rpc("authority", "call_local", "reliable", 1)
func client_chat(message):
	if multiplayer.get_remote_sender_id() != 1:
		return
	var bubble = load("res://ChatBubble.tscn").instantiate()
	bubble.text = message
	chat_bubbles.add_child(bubble)


@rpc("any_peer")
func server_rotate(value: Vector2):
	if !is_server():
		return
	#print(value)
	rotate_y(-value.x * .005)
	#print(value.x)
	rotate_camera(value)


func rotate_camera(value: Vector2):
	camera_pivot.rotate_x(-value.y * .005)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2, PI / 2)


func start_trade(player: MarbleCharacter):
	if !is_server():
		return
	#open the trade window
	trade_partner = player
	trading = true

	player.trade_partner = self
	player.trading = true


@rpc("any_peer")
func cancel_trade():
	if !is_server():
		return

	trade_partner.trading = false
	trade_partner.trade_partner = null
	trading = false
	trade_partner = null


func get_actions():
	return ["trade"]


@rpc("any_peer")
func interact():
	if !is_server():
		return

	if trading:
		cancel_trade()
		return
	if raycast.is_colliding():
		var entity = raycast.get_collider()

		if entity.has_method("start_trade"):
			start_trade(entity)
			entity.start_trade(self)

		if entity.has_method("pick_berry"):
			var action = "pick_berry"
			# make actions.action always a string
			if current_turn_actions.action != null and current_turn_actions.action != action:
				return
			var loot = entity.pick_berry()
			add_to_inventory(loot)
			set_action({"action": "pick_berry"})

		if entity.has_method("pick_up"):
			var action = "pick_up"
			# make actions.action always a string
			if current_turn_actions.action != null and current_turn_actions.action != action:
				return
			var loot = entity.pick_up()
			add_to_inventory(loot)
			set_action({"action": "pick_up"})


func add_to_inventory(loot: Dictionary):
	if !is_server():
		return
	for item in loot.keys():
		inventory[item] = loot[item]


##loot is {item_name:{item}}
func remove_from_inventory(loot: Dictionary) -> bool:
	if !is_server():
		return false
	for item in loot.keys():
		if item not in inventory:
			return false
		inventory.erase(item)

	return true


@rpc("any_peer")
func server_jump():
	if !is_server():
		return
	velocity.y = JUMP_VELOCITY * warp_speed


#this is the function that runs on the server that any peer can call
@rpc("any_peer")
func server_move(d: Vector2):
	if !is_server():
		return
	#print(d)
	var direction = (transform.basis * Vector3(d.x, 0, d.y)).normalized()

	#m*SPEED_MULTIPLIER*speed
	if direction:
		velocity.x = direction.x * mode * SPEED_MULTIPLIER * speed * warp_speed
		velocity.z = direction.z * mode * SPEED_MULTIPLIER * speed * warp_speed
	else:
		velocity.x = move_toward(velocity.x, 0, mode * SPEED_MULTIPLIER * speed * warp_speed)
		velocity.z = move_toward(velocity.z, 0, mode * SPEED_MULTIPLIER * speed * warp_speed)
	if !is_zero_approx(velocity.x) or !is_zero_approx(velocity.z):
		set_action({"move": mode})
		play_animation.rpc("walking")
		if mode in [MOVE.MODE.HUSTLE, MOVE.MODE.RUN]:
			set_action({"action": MOVE.STRINGS[mode]})
	#else:
	#TODO animation state machine so that walk and crouch can play at the same time
	#play_animation.rpc("RESET")


func _on_2x_warp_exit(body: Node3D) -> void:
	print("unfound a body 2x:", body.name)
	#body.warp_speed = 1


func _on_2x_warp_enter(body: Node3D) -> void:
	print("found a body 2x:", body.name)
	#body.warp_speed = 10
