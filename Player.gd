extends CharacterBody3D

signal health_changed(health_value)

@onready var ChatBubbles=$ChatBubbles
@onready var cameraPivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var raycast = $CameraPivot/Camera3D/RayCast3D
@onready var anim_player =  $AnimationPlayer
@onready var chatTextEdit:TextEdit=$/root/Game/UI/HUD/ChatInput
@onready var game=$/root/Game

@export var health = 3
@export var player_id:String
##how fast to go
@export var mode:MODE=MODE.HUSTLE:
	set= update_mode
@export var speed=30.0

enum MODE {
	##half the walk distance
	##usually 15ft/round
	CROUCH=1,
	##single move action
	##usually 30ft/round
	WALK=2,
	##this is the double move action
	##usually 60ft/round
	HUSTLE =4,
	##not used?
	RUN=6}

const SPEED_MULTIPLIER = (1.0/24.0)
const JUMP_VELOCITY = 14.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0
var chatMode=false

func update_mode(new_mode):
	print('client got new mode:',new_mode)
	#TODO animations and stuff
	if mode!=new_mode:
		if new_mode==MODE.CROUCH:
			anim_player.play("crouch")
		else:
			anim_player.play("RESET")
	#if anim_player.current_animation == "shoot":
		#pass
	#elif input_dir != Vector2.ZERO and is_on_floor():
		#anim_player.play("move")
	#else:
		#anim_player.play("idle")
	mode=new_mode

func load(node_data):
	#print('player load')
	name=node_data["name"]
	player_id=node_data["player_id"]
	transform=JSON3D.DictionaryToTransform3D(node_data["transform"])
	#TODO figure out camera rotation
	#print(rotation)
	#print(camera)
	#camera.rotation=rotation

func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"name":name,
		"parent" : get_parent().get_path(),
		#"path": get_path(),
		"player_id":player_id,
		"transform": JSON3D.Transform3DtoDictionary(transform),
		"health": health,
		#"attack" : attack,
		#"defense" : defense,
		#"current_health" : current_health,
		#"max_health" : max_health,
		#"damage" : damage,
		#"regen" : regen,
	}
	return save_dict

func _enter_tree():
	pass

func _ready():
	if player_id and player_id==game.player_id:
		#print('me')
		camera.current = true
	else:
		#print('someone else')
		pass

func _unhandled_input(event):
	#print('_unhandled_input')
	if game and player_id!=game.player_id:
		return

	if event is InputEventMouseMotion:
		if(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or\
			Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if multiplayer.is_server():
				server_rotate(-event.relative.x)
			else:
				server_rotate.rpc_id(1,-event.relative.x)
			cameraPivot.rotate_x(-event.relative.y * .005)
			cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, -PI/2, PI/2)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_action_just_pressed("quit") and chatMode:
		#don't let this event bubble up
		get_viewport().set_input_as_handled()
		chatTextEdit.hide()
		chatTextEdit.release_focus()
		chatMode=false
	if Input.is_action_just_pressed("chat"):
		if(!chatMode):
			chatTextEdit.show()
			chatTextEdit.grab_focus()
			chatMode=true
		else:
			chatTextEdit.hide()
			chatTextEdit.release_focus()
			print(chatTextEdit.text)
			server_chat.rpc_id(1,chatTextEdit.text)
			chatTextEdit.text=""
			chatMode=false
		pass

func _physics_process(delta):

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if game and player_id==game.player_id and !chatMode:

		# TODO check just_press/just_release, or is_pressed?
		# crouch
		if Input.is_action_just_pressed("crouch"):
			if multiplayer.is_server():
				server_mode(MODE.CROUCH)
			else:
				server_mode.rpc_id(1,MODE.CROUCH)
		if Input.is_action_just_released("crouch"):
			if multiplayer.is_server():
				server_mode(MODE.WALK)
			else:
				server_mode.rpc_id(1,MODE.WALK)

		# run
		if Input.is_action_just_pressed("run"):
			if multiplayer.is_server():
				server_mode(MODE.HUSTLE)
			else:
				server_mode.rpc_id(1,MODE.HUSTLE)
		if Input.is_action_just_released("run"):
			if multiplayer.is_server():
				server_mode(MODE.WALK)
			else:
				server_mode.rpc_id(1,MODE.WALK)

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
	# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("left", "right", "up", "down")

		if multiplayer.is_server():
			server_move(input_dir)
		else:
			#print('calling process_input')
			server_move.rpc_id(1,input_dir)

	move_and_slide()

#this is the function that runs on the server that any peer can call
@rpc("any_peer")
func server_mode(new_mode:MODE):
	if !multiplayer.is_server():
		print('someone trying to call server_mode')
		return
	print('server_mode updating mode')
	mode=new_mode

#this is the function that runs on the server that any peer can call
@rpc("any_peer","call_remote","reliable",1)
func server_chat(message):
	if !multiplayer.is_server():
		print('someone trying to call server_chat')
		return
	client_chat.rpc(message)

#this the function that runs on all the peers that only the server can call
@rpc("authority","call_local","reliable",1)
func client_chat(message):
	if multiplayer.get_remote_sender_id()!=1:
		print('someone else trying to call sendChat')
		return
	print('client_chat:',message)
	var bubble = load('res://ChatBubble.tscn').instantiate()
	bubble.text=message
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
	print('server_action')
	if raycast.is_colliding():
		var bush = raycast.get_collider()
		print('hit something ',bush.name)
		if bush.has_method('pickBerry'):
			print('picking berry')
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
		print('server_move not from server')
		return
	var direction = (transform.basis * Vector3(d.x, 0, d.y)).normalized()

	#m*SPEED_MULTIPLIER*speed
	if direction:
		velocity.x = direction.x * mode*SPEED_MULTIPLIER*speed
		velocity.z = direction.z *mode*SPEED_MULTIPLIER*speed
	else:
		velocity.x = move_toward(velocity.x, 0, mode*SPEED_MULTIPLIER*speed)
		velocity.z = move_toward(velocity.z, 0, mode*SPEED_MULTIPLIER*speed)

#@rpc("any_peer","call_local")
#func play_shoot_effects():
	#anim_player.stop()
	#anim_player.play("shoot")
	#muzzle_flash.restart()
	#muzzle_flash.emitting = true

@rpc("authority")
func receive_damage():
	print('receive_damage',multiplayer.get_unique_id())
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO+Vector3(0,.5,0)
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
