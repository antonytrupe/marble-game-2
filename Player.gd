class_name MarbleCharacter
extends CharacterBody3D

const SPEED_MULTIPLIER = 1.0 / 24.0
const JUMP_VELOCITY = 5.0

@export var other_trade_inventory = {}:
	set = _update_other_trade_inventory
@export var trading: bool = false:
	set = _set_trading
@export var my_trade_inventory = {}:
	set = _update_trade_inventory
@export var trade_accepted = false

@export var health = 3
@export var player_id: String
##how fast to go
@export var mode: MOVE.MODE = MOVE.MODE.WALK:
	set = update_mode
@export var speed = 30.0
@export var birth_date: int = 0:
	set = set_birth_date

@export var extra_age: int = 0:
	set = set_extra_age

@export var actions = {"move": null, "action": null}:
	set = _set_action

@export var inventory: Dictionary:
	set = _set_inventory

var trade_partner: MarbleCharacter
#we need otherTradeInventory on the client side because we can't sync trade_partner
var calculated_age: int:
	get = calculate_age
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var chat_mode = false
var skills = {}
var quests = []

@onready var game: Game = $/root/Game
@onready var world: World = $/root/Game/World
@onready var chat_text_edit: TextEdit = $/root/Game/UI/HUD/ChatInput
@onready var chat_bubbles = %ChatBubbles
@onready var camera_pivot = $CameraPivot
@onready var camera = %Camera3D
@onready var raycast = %RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var inventory_ui = %InventoryUI
@onready var chunk_scanner = %ChunkScanner
@onready var character_sheet = %CharacterSheet
@onready var quest_creator_ui = %QuestCreator
@onready var actions_ui = %ActionsUI
@onready var fade_anim = %AnimationPlayer
#@onready var trade_ui = %TradeUI
@onready var trade_ui = %PlayerInteractionUI
@onready var craft_ui = %CraftUI
@onready var cross_hair = %CrossHair


@rpc("any_peer")
func create_quest(item_name, quantity):
	if not multiplayer.is_server():
		return
	print(item_name, quantity)
	(
		quests.append(
			{
				item = item_name,
				quantity = quantity,
			}
		)
	)


@rpc("any_peer")
func craft(action: String, tool: Dictionary, loot: Dictionary):
	if not multiplayer.is_server():
		return
	var scene = load(tool.scene_file_path)
	var instance = scene.instantiate()
	var result = instance.call(action, self, loot)
	#var result = instance.craft(self, loot)
	#print(result)
	#remove_from_inventory({tool.category:{"items":{tool.name:tool}}})
	remove_from_inventory(loot)

	add_to_inventory(result)
	#if loot.keys().size()>0 and loot[loot.keys()[0]].has_method("craft"):
	#loot[0].craft(loot)


func _update_other_trade_inventory(loot):
	other_trade_inventory = loot
	if trade_ui:
		trade_ui.other_player_trade = other_trade_inventory
		trade_ui.update()


func _update_trade_inventory(loot):
	my_trade_inventory = loot
	if trade_ui:
		trade_ui.update()
	if trade_partner:
		trade_partner.other_trade_inventory = loot


#@rpc("call_remote")
#func updateTradeUI():
#trade_ui.otherPlayerTrade = otherTradeInventory
#trade_ui.update()

@rpc("any_peer")
func accept_trade():
	if !multiplayer.is_server():
		return
	print('accept_trade')
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


@rpc("any_peer")
func remove_from_trade(loot: Dictionary):
	if !multiplayer.is_server():
		return
	for category in loot:
		#var item = loot[category]
		for item in loot[category].items.values():
			my_trade_inventory[category].items.erase(item.name)
		#if item.items.keys().size() > 0:
			#my_trade_inventory[category].quantity -= item.quantity
		if my_trade_inventory[category].items.keys().size() <= 0:
			my_trade_inventory.erase(category)
	#trade_partner.updateTradeUI.rpc()


@rpc("any_peer")
func add_to_trade(loot: Dictionary):
	if not multiplayer.is_server():
		return
	for category in loot:
		if !my_trade_inventory.has(category):
			my_trade_inventory[category] = {
				scene_file_path = loot[category].scene_file_path,
				items = {},
			}
		#var item = loot[item_name]
		#my_trade_inventory[item_name].quantity += loot[item_name].quantity
		my_trade_inventory[category].items.merge(loot[category].items)
	trade_partner.other_trade_inventory = my_trade_inventory
	#trade_partner.updateTradeUI.rpc()


func is_current_player():
	return game and player_id and player_id == game.player_id


func _set_trading(value):
	trading = value
	#if the tradeui is ready and this is the current player
	if trade_ui and is_current_player():
		if trading:
			trade_ui.other_player_trade = other_trade_inventory
			trade_ui.update()
			trade_ui.show()
		else:
			trade_ui.hide()
	if !trading:
		trade_partner = null
		trade_accepted = false
		my_trade_inventory = {}
		other_trade_inventory = {}


func _set_inventory(value: Dictionary):
	#print('player._set_inventory')
	inventory = value
	if inventory_ui:
		inventory_ui.update()
	if trade_ui:
		trade_ui.update()
	if craft_ui:
		craft_ui.update()


#setter, don't call directly
func _set_action(value):
	actions = value
	Signals.Actions.emit(player_id, actions)


# use reset_actions to clear this and skip internal logic
func set_action(value: Dictionary):
	if value.has("action") and value.action:
		actions.action = value.action
	# only update move if we went faster
	if value.has("move") and (actions.move == null or value.move > actions.move):
		actions.move = value.move


func reset_actions():
	actions = {"move": null, "action": null}


func get_zones() -> Array[Chunk]:
	var areas = chunk_scanner.get_overlapping_areas()
	var chunks: Array[Chunk] = []
	for area: Area3D in areas:
		chunks.append(area.get_parent())
	return chunks


func set_birth_date(value):
	birth_date = value


func set_extra_age(value):
	extra_age = value


func calculate_age():
	return world.world_age + extra_age + Time.get_ticks_msec() - birth_date


func update_mode(new_mode):
	#print(new_mode)
	#TODO animations and stuff
	if mode != new_mode:
		if new_mode == MOVE.MODE.CROUCH:
			anim_player.play("crouch")
			#print("play crouch")
		elif mode == MOVE.MODE.CROUCH:
			anim_player.play_backwards("crouch")
			#print("play crouch backwards")
		else:
			anim_player.play("RESET")
			#print("play reset")
	mode = new_mode


@rpc
func play_animation(animation_name):
	anim_player.play(animation_name)


func load(node_data):
	player_id = node_data["player_id"]
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	for p in node_data:
		if p in self and p not in ["transform"]:
			self[p] = node_data[p]
	#TODO figure out camera rotation


func save():
	var save_dict = {
		#
		player_id = player_id,
		transform = JSON3D.Transform3DtoDictionary(transform),
		health = health,
		birth_date = birth_date,
		extra_age = extra_age,
		inventory = inventory,
		skills = skills,
		quests = quests,
	}
	return save_dict


func _on_new_turn(_turn_id):
	reset_actions()


func _ready():
	actions_ui.player_id = player_id
	Signals.NewTurn.connect(_on_new_turn)
	#if multiplayer.is_server():
	#Signals.PlayerZoned.connect(_on_player_zoned)
	if is_current_player():
		camera.current = true
		actions_ui.show()
		cross_hair.visible = true
	else:
		pass


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


func _unhandled_input(event):
	if game and !is_current_player():
		return

	if Input.is_action_just_pressed("long_rest"):
		var minutes = 8 * 60
		if multiplayer.is_server():
			time_warp(minutes)
		else:
			time_warp.rpc_id(1, minutes)

	if Input.is_action_just_pressed("short_rest"):
		var minutes = 60
		if multiplayer.is_server():
			time_warp(minutes)
		else:
			time_warp.rpc_id(1, minutes)

	if Input.is_action_just_pressed("inventory"):
		inventory_ui.visible = !inventory_ui.visible

	if Input.is_action_just_pressed("craft"):
		craft_ui.visible = !craft_ui.visible
		cross_hair.visible = !cross_hair.visible

	if Input.is_action_just_pressed("character_sheet"):
		character_sheet.visible = !character_sheet.visible

	if Input.is_action_just_pressed("quest_creator"):
		quest_creator_ui.visible = !quest_creator_ui.visible
		cross_hair.visible = !cross_hair.visible

	if event is InputEventMouseMotion:
		if (
			Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if multiplayer.is_server():
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

		if multiplayer.is_server():
			cancel_trade()
		else:
			cancel_trade.rpc_id(1)

	if Input.is_action_just_pressed("quit") and inventory_ui.visible:
		#don't let this event bubble up
		get_viewport().set_input_as_handled()

		inventory_ui.hide()

	if Input.is_action_just_pressed("chat"):
		chat_text_edit.visible = !chat_text_edit.visible
		chat_mode = !chat_mode
		if chat_mode:
			chat_text_edit.grab_focus()
		else:
			chat_text_edit.release_focus()
			server_chat.rpc_id(1, chat_text_edit.text)
			chat_text_edit.text = ""


func _process(_delta):
	character_sheet.age = calculated_age


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_current_player() and !chat_mode:
		# TODO check just_press/just_release, or is_pressed?
		# crouch
		if Input.is_action_just_pressed("crouch"):
			if multiplayer.is_server():
				server_mode(MOVE.MODE.CROUCH)
			else:
				server_mode.rpc_id(1, MOVE.MODE.CROUCH)
		if Input.is_action_just_released("crouch"):
			if multiplayer.is_server():
				server_mode(MOVE.MODE.WALK)
			else:
				server_mode.rpc_id(1, MOVE.MODE.WALK)

		# run
		if Input.is_action_just_pressed("run"):
			if multiplayer.is_server():
				server_mode(MOVE.MODE.HUSTLE)
			else:
				server_mode.rpc_id(1, MOVE.MODE.HUSTLE)
		if Input.is_action_just_released("run"):
			if multiplayer.is_server():
				server_mode(MOVE.MODE.WALK)
			else:
				server_mode.rpc_id(1, MOVE.MODE.WALK)

		# Jump
		if Input.is_action_just_pressed("jump") and is_on_floor():
			if multiplayer.is_server():
				server_jump()
			else:
				server_jump.rpc_id(1)

		if Input.is_action_just_pressed("action"):
			if multiplayer.is_server():
				interact()
			else:
				interact.rpc_id(1)
		# Get the input direction and handle the movement/deceleration.
		var input_dir = Input.get_vector("left", "right", "up", "down")

		if multiplayer.is_server():
			server_move(input_dir)
		else:
			server_move.rpc_id(1, input_dir)

	move_and_slide()


#this is the function that runs on the server that any peer can call
@rpc("any_peer")
func server_mode(new_mode: MOVE.MODE):
	if !multiplayer.is_server():
		return
	#if we've used an action, no hustling/running
	if !actions.action or [MOVE.MODE.CROUCH, MOVE.MODE.WALK].has(new_mode):
		mode = new_mode


@rpc("any_peer")
func time_warp(minutes: int):
	if !multiplayer.is_server():
		return

	extra_age = extra_age + 1000 * 60 * minutes

	# emit an even for the world/game node to handle
	Signals.TimeWarp.emit(minutes, get_zones())


#this is the function that runs on the server that any peer can call
@rpc("any_peer", "call_remote", "reliable", 1)
func server_chat(message: String):
	if !multiplayer.is_server():
		return
	if message.begins_with("/"):
		#print("command", self)
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
	if !multiplayer.is_server():
		return
	rotate_y(-value.x * .005)
	camera_pivot.rotate_x(-value.y * .005)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2, PI / 2)


func start_trade(player: MarbleCharacter):
	if !multiplayer.is_server():
		return
	#open the trade window
	trading = true
	trade_partner = player
	player.trading = true
	player.trade_partner = self


@rpc("any_peer")
func cancel_trade():
	if !multiplayer.is_server():
		return

	trade_partner.trading = false
	trade_partner.trade_partner = null
	trading = false
	trade_partner = null


func get_actions():
	return ["trade"]


@rpc("any_peer")
func interact():
	if !multiplayer.is_server():
		return

	if trading:
		cancel_trade()
		return
	if raycast.is_colliding():
		var entity = raycast.get_collider()
		#print('found:', entity)

		if entity.has_method("start_trade"):
			start_trade(entity)
			entity.start_trade(self)

		if entity.has_method("pick_berry"):
			var action = "pick_berry"
			# make actions.action always a string
			if actions.action != null and actions.action != action:
				return
			var loot = entity.pick_berry()
			add_to_inventory(loot)
			set_action({"action": "pick_berry"})

		if entity.has_method("pick_up"):
			var action = "pick_up"
			# make actions.action always a string
			if actions.action != null and actions.action != action:
				return
			var loot = entity.pick_up()
			add_to_inventory(loot)
			set_action({"action": "pick_up"})


func add_to_inventory(loot: Dictionary):
	if !multiplayer.is_server():
		return
	#print('loot:', loot)
	for category in loot:
		if !inventory.has(category):
			inventory[category] = {
				items = {},
				scene_file_path = loot[category].scene_file_path,
			}
		if !inventory[category].has("items"):
			inventory[category].items = {}
		if !inventory[category].has("scene_file_path"):
			inventory[category].scene_file_path = loot[category].scene_file_path

		#var loot_item = loot[item_name]

		for item in loot[category].items.values():
			#TODO instantiate in inventory
			inventory[category].items[item.name] = item

	#print('inventory:', inventory)
	craft_ui.update.rpc()


func remove_from_inventory(loot: Dictionary) -> bool:
	#print("remove_from_inventory:", loot)
	if !multiplayer.is_server():
		return false
	for category in loot:
		if (
			!inventory.has(category)
			or inventory[category].items.keys().size() < loot[category].items.keys().size()
		):
			print("not removing")
			return false

		for id in loot[category].items.keys():
			inventory[category].items.erase(id)
			print("removed %s" % id)

		if inventory[category].items.keys().size() == 0:
			inventory.erase(category)
	return true


@rpc("any_peer")
func server_jump():
	if !multiplayer.is_server():
		return
	velocity.y = JUMP_VELOCITY


#this is the function that runs on the server that any peer can call
@rpc("any_peer")
func server_move(d):
	if !multiplayer.is_server():
		return
	var direction = (transform.basis * Vector3(d.x, 0, d.y)).normalized()

	#m*SPEED_MULTIPLIER*speed
	if direction:
		velocity.x = direction.x * mode * SPEED_MULTIPLIER * speed
		velocity.z = direction.z * mode * SPEED_MULTIPLIER * speed
	else:
		velocity.x = move_toward(velocity.x, 0, mode * SPEED_MULTIPLIER * speed)
		velocity.z = move_toward(velocity.z, 0, mode * SPEED_MULTIPLIER * speed)
	if !is_zero_approx(velocity.x) or !is_zero_approx(velocity.z):
		set_action({"move": mode})
		play_animation.rpc("walking")
		if mode in [MOVE.MODE.HUSTLE, MOVE.MODE.RUN]:
			set_action({"action": MOVE.STRINGS[mode]})
	#else:
	#TODO animation state machine so that walk and crouch can play at the same time
	#play_animation.rpc("RESET")
