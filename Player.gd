extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player =  $AnimationPlayer
@onready var muzzle_flash = $Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var chatTextEdit:TextEdit=$/root/Game/UI/HUD/ChatInput
var chatMode=false

@export var health = 3
@export var player_id:String

@onready var world=$/root/Game

const SPEED = 10.0
const JUMP_VELOCITY = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0

func load(node_data):
	#print('player load')
	name=node_data["name"]
	player_id=node_data["player_id"]
	transform=Dictionary_to_Transform3D(node_data["transform"])
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
		"transform": Transform3D_to_Dictionary(transform),
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
	if player_id and player_id==world.player_id:
		#print('me')
		camera.current = true
	else:
		#print('someone else')
		pass

func _unhandled_input(event):
	#print('_unhandled_input')
	if world and player_id!=world.player_id:
		return

	if event is InputEventMouseMotion:
		if(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or\
			Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if multiplayer.is_server():
				_rotate(-event.relative.x)
			else:
				_rotate.rpc_id(1,-event.relative.x)
			camera.rotate_x(-event.relative.y * .005)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot":
		#shoot()
		pass

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
			chat.rpc_id(1,chatTextEdit.text)
			chatTextEdit.text=""
			chatMode=false
		pass

#this is the function that runs on the server that any peer can call
@rpc("any_peer")
func chat(message):
	sendChat.rpc(message)

#this the function that runs on all the peers that only the server can call
@rpc("authority","call_local")
func sendChat(message):
	print('sendChat',message)
	var bubble = load('res://ChatBubble.tscn').instantiate()
	bubble.text=message
	add_child(bubble)

@rpc("any_peer")
func _rotate(value):
	rotate_y(value * .005)

func shoot():
	print('shoot ',multiplayer.get_unique_id())
	play_shoot_effects.rpc()

	if multiplayer.is_server():
		check_for_hit()
	else:
		check_for_hit.rpc_id(1)

@rpc("any_peer")
func check_for_hit():
	print('check_for_hit ',multiplayer.get_unique_id())
	if raycast.is_colliding():
		var hit_player = raycast.get_collider()
		print('hit player ',hit_player)
		hit_player.receive_damage()

func _physics_process(delta):
	#TODO
	#if not is_multiplayer_authority(): return

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	if world and player_id==world.player_id and !chatMode:
	#if multiplayer.get_unique_id()==str(name).to_int():
		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			if multiplayer.is_server():
				jump()
			else:
				jump.rpc_id(1)

		if multiplayer.is_server():
			process_input(input_dir)
		else:
			#print('calling process_input')
			process_input.rpc_id(1,input_dir)

	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")

	move_and_slide()

@rpc("any_peer")
func jump():
	velocity.y = JUMP_VELOCITY

@rpc("any_peer")
func process_input(input_dir):
	var z=  Vector2(0,0)
	if(input_dir != z):
		#print('process_input')
		#print(input_dir)
		#print('multiplayer id ',multiplayer.get_unique_id())
		#print('moving ',name)
		pass

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

@rpc("any_peer","call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

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

static func Transform3D_to_Dictionary(t:Transform3D):
	var d={
		"basis":{
			"x":Vector3_to_Dictionary(t.basis.x),
			"y":Vector3_to_Dictionary(t.basis.y),
			"z":Vector3_to_Dictionary(t.basis.z)
		},
		"origin":Vector3_to_Dictionary(t.origin)
	}
	#print(d)
	return d

static func Dictionary_to_Transform3D(d:Dictionary):
	#x_axis: Vector3, y_axis: Vector3, z_axis: Vector3, origin: Vector3)
	#print(d)
	var x_axis=Dictionary_to_Vector3(d.basis.x)
	var y_axis=Dictionary_to_Vector3(d.basis.y)
	var z_axis=Dictionary_to_Vector3(d.basis.z)
	var origin=Dictionary_to_Vector3(d.origin)
	var _basis=Basis(x_axis,y_axis,z_axis)

	return Transform3D(_basis,origin)

static func Dictionary_to_Vector3(d:Dictionary):
	return Vector3(d.x,d.y,d.z)

static func Vector3_to_Dictionary(vector3:Vector3):
	var d= {
		"x":vector3.x,
		"y":vector3.y,
		"z":vector3.z
		}
	#print(d)
	return d
