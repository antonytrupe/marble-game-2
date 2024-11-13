extends CharacterBody3D
class_name MarbleCharacter

@onready var ChatBubbles = $ChatBubbles
@onready var cameraPivot = $CameraPivot
@onready var camera = %Camera3D
@onready var raycast = %RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var chatTextEdit: TextEdit = $/root/Game/UI/HUD/ChatInput
@onready var game = $/root/Game
@onready var inventory = $Inventory
@onready var area3D = $Area3D
@onready var characterSheet = $CharacterSheet
@onready var actionsUI = %ActionsUI
@onready var fade_anim = %AnimationPlayer

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
var calculated_age: int:
	get = calculate_age

@export var actions = {"move": null, "action": null}:
	set = set_actions

var reset_actions = null:
	set = _reset_actions


func get_zones() -> Array[Chunk]:
	var areas = area3D.get_overlapping_areas()
	var chunks: Array[Chunk] = []
	for area: Area3D in areas:
		chunks.append(area.get_parent())
	return chunks


# use reset_actions to clear this and skip internal logic
func set_actions(value: Dictionary):
	#print("player set_actions ", value)

	actions.action = value.action
	# only update move if we went faster
	if value.move != null and (actions.move == null or value.move > actions.move):
		actions.move = value.move
	Signals.Actions.emit(player_id, actions)


func _reset_actions(_value):
	#print("player _reset_actions")
	actions = {"move": null, "action": null}
	#print("player _reset_actions ", actions)
	Signals.Actions.emit(player_id, actions)


func set_birth_date(value):
	birth_date = value


func set_extra_age(value):
	extra_age = value


func calculate_age():
	return game.server_age + extra_age + Time.get_ticks_msec() - birth_date


const SPEED_MULTIPLIER = 1.0 / 24.0
const JUMP_VELOCITY = 14.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0
var chatMode = false


func update_mode(new_mode):
	#print('client got new mode:',new_mode)
	#TODO animations and stuff
	if mode != new_mode:
		if new_mode == MOVE.MODE.CROUCH:
			anim_player.play("crouch")
		else:
			anim_player.play("RESET")
	#if anim_player.current_animation == "shoot":
	#pass
	#elif input_dir != Vector2.ZERO and is_on_floor():
	#anim_player.play("move")
	#else:
	#anim_player.play("idle")
	mode = new_mode


func load(node_data):
	name = node_data["name"]
	player_id = node_data["player_id"]
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	if "birth_date" in node_data:
		birth_date = node_data.birth_date
	if "extra_age" in node_data:
		extra_age = node_data.extra_age
	#TODO figure out camera rotation


func save():
	var save_dict = {
		"filename": get_scene_file_path(),
		"name": name,
		"parent": get_parent().get_path(),
		"player_id": player_id,
		"transform": JSON3D.Transform3DtoDictionary(transform),
		"health": health,
		"birth_date": birth_date,
		"extra_age": extra_age,
	}
	return save_dict


func _on_new_turn(_turn_id):
	#print("player _on_new_turn ", turn_id)
	reset_actions = null


func _ready():
	actionsUI.player_id = player_id
	Signals.NewTurn.connect(_on_new_turn)
	if player_id and player_id == game.player_id:
		camera.current = true
		actionsUI.show()
	else:
		pass


@rpc("authority")
func play_fade():
	fade_anim.play("fade")


func _unhandled_input(event):
	if game and player_id != game.player_id:
		return

	if Input.is_action_just_pressed("long_rest"):
		var minutes = 8 * 60
		if multiplayer.is_server():
			server_request_rest(minutes)
		else:
			server_request_rest.rpc_id(1, minutes)

	if Input.is_action_just_pressed("short_rest"):
		var minutes = 60
		if multiplayer.is_server():
			server_request_rest(minutes)
		else:
			server_request_rest.rpc_id(1, minutes)

	if Input.is_action_just_pressed("inventory"):
		inventory.visible = !inventory.visible

	if Input.is_action_just_pressed("character_sheet"):
		characterSheet.visible = !characterSheet.visible

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if multiplayer.is_server():
				server_rotate(-event.relative.x)
			else:
				server_rotate.rpc_id(1, -event.relative.x)
			cameraPivot.rotate_x(-event.relative.y * .005)
			cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, -PI / 2, PI / 2)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_action_just_pressed("quit") and chatMode:
		#don't let this event bubble up
		get_viewport().set_input_as_handled()
		chatTextEdit.hide()
		chatTextEdit.release_focus()
		chatMode = false
	if Input.is_action_just_pressed("chat"):
		if !chatMode:
			chatTextEdit.show()
			chatTextEdit.grab_focus()
			chatMode = true
		else:
			chatTextEdit.hide()
			chatTextEdit.release_focus()
			print(chatTextEdit.text)
			server_chat.rpc_id(1, chatTextEdit.text)
			chatTextEdit.text = ""
			chatMode = false
		pass


func _process(_delta):
	characterSheet.age = calculated_age


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if game and player_id == game.player_id and !chatMode:
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
		print("someone trying to call server_mode")
		return
	#print('server_mode updating mode')
	mode = new_mode


@rpc("any_peer")
func server_request_rest(minutes: int):
	print("server_request_rest")
	if !multiplayer.is_server():
		print("someone trying to call server_request_rest")
		return

	extra_age = extra_age + 1000 * 60 * minutes

	# emit an even for the world/game node to handle
	Signals.TimeWarp.emit(minutes, get_zones())


#this is the function that runs on the server that any peer can call
@rpc("any_peer", "call_remote", "reliable", 1)
func server_chat(message):
	if !multiplayer.is_server():
		print("someone trying to call server_chat")
		return
	client_chat.rpc(message)


#this the function that runs on all the peers that only the server can call
@rpc("authority", "call_local", "reliable", 1)
func client_chat(message):
	if multiplayer.get_remote_sender_id() != 1:
		print("someone else trying to call sendChat")
		return
	var bubble = load("res://ChatBubble.tscn").instantiate()
	bubble.text = message
	ChatBubbles.add_child(bubble)


@rpc("any_peer")
func server_rotate(value):
	if !multiplayer.is_server():
		return
	rotate_y(value * .005)


#func shoot():
#print('shoot ',multiplayer.get_unique_id())
#play_shoot_effects.rpc()
#
#if multiplayer.is_server():
#check_for_hit()
#else:
#check_for_hit.rpc_id(1)

#@rpc("any_peer")
#func check_for_hit():
#print('check_for_hit ',multiplayer.get_unique_id())
#if raycast.is_colliding():
#var hit_player = raycast.get_collider()
#print('hit player ',hit_player)
#hit_player.receive_damage()

@rpc("any_peer")
func server_action():
	if !multiplayer.is_server():
		return
	print("server_action")
	if raycast.is_colliding():
		var bush = raycast.get_collider()
		print("hit something ", bush.name)
		if bush.has_method("pickBerry"):
			print("picking berry")
			bush.pickBerry()


@rpc("any_peer")
func server_jump():
	if !multiplayer.is_server():
		return
	velocity.y = JUMP_VELOCITY


#this is the function that runs on the server that any peer can call
@rpc("any_peer")
func server_move(d):
	if !multiplayer.is_server():
		print("server_move not from server")
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
		actions.move = mode
		if [MOVE.MODE.HUSTLE, MOVE.MODE.RUN].has(mode):
			actions.action = mode


@rpc("authority")
func receive_damage():
	print("receive_damage", multiplayer.get_unique_id())
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO + Vector3(0, .5, 0)
	#health_changed.emit(health)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
