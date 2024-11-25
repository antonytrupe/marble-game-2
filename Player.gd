extends CharacterBody3D
class_name MarbleCharacter

const SPEED_MULTIPLIER = 1.0 / 24.0
const JUMP_VELOCITY = 5.0

@export var otherTradeInventory = {}:
	set = _update_other_trade_inventory
@export var trading: bool = false:
	set = set_trading
@export var myTradeInventory = {}:
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

var tradePartner: MarbleCharacter
#we need otherTradeInventory on the client side because we can't sync tradePartner

var calculated_age: int:
	get = calculate_age

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var chatMode = false

@onready var game: Game = $/root/Game
@onready var world: World = $/root/Game/World
@onready var chatTextEdit: TextEdit = $/root/Game/UI/HUD/ChatInput
@onready var ChatBubbles = %ChatBubbles
@onready var cameraPivot = $CameraPivot
@onready var camera = %Camera3D
@onready var raycast = %RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var inventoryUI = %InventoryUI
@onready var chunkScanner = %ChunkScanner
@onready var characterSheet = %CharacterSheet
@onready var actionsUI = %ActionsUI
@onready var fade_anim = %AnimationPlayer
@onready var tradeUI = %TradeUI
@onready var craftUI = %CraftUI
@onready var inventoryNode = %Inventory


@rpc("any_peer")
func craft(tool , loot: Dictionary):
	if not multiplayer.is_server():
		return
	#print('craft:', loot)
	# var type = loot.keys()[0]
	#print(type)
	#var tool=inventory[type]
	#print(tool )
	var scene = load(tool .scene_file_path)
	var instance = scene.instantiate()
	var result = instance.craft(self, loot)
	print(result)
	remove_from_inventory(tool )
	remove_from_inventory(loot)
	add_to_inventory({
		instance.label: {
			quantity = 1,
			scene_file_path = instance.get_scene_file_path(),
			items = [instance.save(),
			],
		}})
	add_to_inventory(result)
	#if loot.keys().size()>0 and loot[loot.keys()[0]].has_method("craft"):
		#loot[0].craft(loot)

func _update_other_trade_inventory(loot):
	otherTradeInventory = loot
	if tradeUI:
		tradeUI.otherPlayerTrade = otherTradeInventory
		tradeUI.update()


func _update_trade_inventory(loot):
	myTradeInventory = loot
	if tradeUI:
		tradeUI.update()
	if tradePartner:
		tradePartner.otherTradeInventory = loot


#@rpc("call_remote")
#func updateTradeUI():
#tradeUI.otherPlayerTrade = otherTradeInventory
#tradeUI.update()

@rpc("any_peer")
func accept_trade():
	if !multiplayer.is_server():
		return
	trade_accepted = true
	if trade_accepted and tradePartner.trade_accepted:

		#TODO make sure the whole trade will succeed before doing any part
		#swap loot
		if tradePartner.remove_from_inventory(tradePartner.myTradeInventory):
			add_to_inventory(tradePartner.myTradeInventory)

		if remove_from_inventory(myTradeInventory):
			tradePartner.add_to_inventory(myTradeInventory)
		#clear stuff
		tradePartner.trading = false

		trading = false


@rpc("any_peer")
func remove_from_trade(loot: Dictionary):
	if !multiplayer.is_server():
		return
	for item_name in loot:
		var item = loot[item_name]
		if item.quantity > 0:
			myTradeInventory[item_name].quantity -= item.quantity
		if myTradeInventory[item_name].quantity <= 0:
			myTradeInventory.erase(item_name)
	#tradePartner.updateTradeUI.rpc()


@rpc("any_peer")
func add_to_trade(loot: Dictionary):
	if not multiplayer.is_server():
		return
	for item_name in loot:
		if !myTradeInventory.has(item_name):
			myTradeInventory[item_name] = {
				quantity = 0,
				scene_file_path = loot[item_name].scene_file_path,
				items = [],
				}
		#var item = loot[item_name]
		myTradeInventory[item_name].quantity += loot[item_name].quantity
		myTradeInventory[item_name].items.append_array(loot[item_name].items)
	tradePartner.otherTradeInventory = myTradeInventory
	#tradePartner.updateTradeUI.rpc()
	#TODO check to make sure tradeinventory quantities don't go over inventory quantity


func isCurrentPlayer():
	return game and player_id and player_id == game.player_id


func set_trading(value):
	trading = value
	#if the tradeui is ready and this is the current player
	if tradeUI and isCurrentPlayer():
		if trading:
			tradeUI.otherPlayerTrade = otherTradeInventory
			tradeUI.update()
			tradeUI.show()
		else:
			tradeUI.hide()
	if !trading:
		tradePartner = null
		trade_accepted = false
		myTradeInventory = {}
		otherTradeInventory = {}


func _set_inventory(value: Dictionary):
	inventory = value
	if inventoryUI:
		inventoryUI.update()
	if tradeUI:
		tradeUI.update()
	if craftUI:
		craftUI.update()


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
	var areas = chunkScanner.get_overlapping_areas()
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

func load(node_data):
	player_id = node_data["player_id"]
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	if "birth_date" in node_data:
		birth_date = node_data.birth_date
	if "extra_age" in node_data:
		extra_age = node_data.extra_age
	if "inventory" in node_data:
		inventory = node_data.inventory
	#TODO figure out camera rotation


func save():
	var save_dict = {
		#
		"player_id": player_id,
		"transform": JSON3D.Transform3DtoDictionary(transform),
		"health": health,
		"birth_date": birth_date,
		"extra_age": extra_age,
		"inventory": inventory,
	}
	return save_dict


func _on_new_turn(_turn_id):
	reset_actions()


func _ready():
	actionsUI.player_id = player_id
	Signals.NewTurn.connect(_on_new_turn)
	if isCurrentPlayer():
		camera.current = true
		actionsUI.show()
	else:
		pass


@rpc("authority")
func play_fade():
	fade_anim.play("fade")


func _unhandled_input(event):
	if game and !isCurrentPlayer():
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
		inventoryUI.visible = !inventoryUI.visible

	if Input.is_action_just_pressed("craft"):
		craftUI.visible = !craftUI.visible

	if Input.is_action_just_pressed("character_sheet"):
		characterSheet.visible = !characterSheet.visible

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if multiplayer.is_server():
				server_rotate(event.relative)
			else:
				server_rotate.rpc_id(1, event.relative)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_action_just_pressed("quit") and chatMode:
		#don't let this event bubble up
		get_viewport().set_input_as_handled()
		chatTextEdit.hide()
		chatTextEdit.release_focus()
		chatMode = false

	if Input.is_action_just_pressed("quit") and trading:
		#don't let this event bubble up
		get_viewport().set_input_as_handled()

		if multiplayer.is_server():
			cancel_trade()
		else:
			cancel_trade.rpc_id(1)

	if Input.is_action_just_pressed("quit") and inventoryUI.visible:
		#don't let this event bubble up
		get_viewport().set_input_as_handled()

		inventoryUI.hide()

	if Input.is_action_just_pressed("chat"):
		chatTextEdit.visible = !chatTextEdit.visible
		chatMode = !chatMode
		if chatMode:
			chatTextEdit.grab_focus()
		else:
			chatTextEdit.release_focus()
			server_chat.rpc_id(1, chatTextEdit.text)
			chatTextEdit.text = ""


func _process(_delta):
	characterSheet.age = calculated_age


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if isCurrentPlayer() and !chatMode:
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
				server_action()
			else:
				server_action.rpc_id(1)
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
	ChatBubbles.add_child(bubble)


@rpc("any_peer")
func server_rotate(value: Vector2):
	if !multiplayer.is_server():
		return
	rotate_y(-value.x * .005)
	cameraPivot.rotate_x(-value.y * .005)
	cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, -PI / 2, PI / 2)


func start_trade(player: MarbleCharacter):
	if !multiplayer.is_server():
		return
	#open the trade window
	trading = true
	tradePartner = player
	player.trading = true
	player.tradePartner = self


@rpc("any_peer")
func cancel_trade():
	if !multiplayer.is_server():
		return

	tradePartner.trading = false
	tradePartner.tradePartner = null
	trading = false
	tradePartner = null


func get_actions():
	return ["trade"]


@rpc("any_peer")
func server_action():
	if !multiplayer.is_server():
		return

	if trading:
		cancel_trade()
		return
	if raycast.is_colliding():
		var entity = raycast.get_collider()
		print('found:', entity)

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
			inventory[category] = {quantity = 0,
			items = [],
			scene_file_path = loot[category].scene_file_path,
			}
		if !inventory[category].has("items"):
			inventory[category].items = []
		if !inventory[category].has("scene_file_path"):
			inventory[category].scene_file_path = loot[category].scene_file_path

		#var loot_item = loot[item_name]
		inventory[category].quantity += loot[category].quantity

		for item in loot[category].items:
			#TODO instantiate in inventory
			inventory[category].items.append(item)

	#print('inventory:', inventory)


func remove_from_inventory(loot: Dictionary) -> bool:
	if !multiplayer.is_server():
		return false
	for item_name in loot:
		if !inventory.has(item_name) or inventory[item_name].quantity < loot[item_name].quantity:
			return false
		var item = loot[item_name]

		inventory[item_name].quantity -= item.quantity
		if inventory[item_name].quantity == 0:
			inventory.erase((item_name))
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
		play_animation.rpc('walking')
		if mode in [MOVE.MODE.HUSTLE, MOVE.MODE.RUN]:
			set_action({"action": MOVE.STRINGS[mode]})
	else:
		play_animation.rpc('RESET')


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
