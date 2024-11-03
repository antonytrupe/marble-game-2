extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player =  $AnimationPlayer
@onready var muzzle_flash = $Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D

@export var health = 3

const SPEED = 10.0
const JUMP_VELOCITY = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0

func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z":position.z,
		"health": health,
		#"attack" : attack,
		#"defense" : defense,
		#"current_health" : current_health,
		#"max_health" : max_health,
		#"damage" : damage,
		#"regen" : regen,
		#"experience" : experience,
		#"tnl" : tnl,
		#"level" : level,
		#"attack_growth" : attack_growth,
		#"defense_growth" : defense_growth,
		#"health_growth" : health_growth,
		#"is_alive" : is_alive,
		#"last_attack" : last_attack
	}
	return save_dict

func _enter_tree():
	#set_multiplayer_authority(str(name).to_int())
	#add_to_group("Persist")
	pass

func _ready():
	#if not is_multiplayer_authority(): return
	#print(is_multiplayer_authority())
	if multiplayer.get_unique_id()==str(name).to_int():
		#print('me')
		#print(multiplayer.get_unique_id())
		#print(name)
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		camera.current = true
	else:
		#print('someone else')
		pass

func _unhandled_input(event):
	#print('_unhandled_input')
	#print(multiplayer.get_unique_id())
	#print(name)
	if multiplayer.get_unique_id()!=str(name).to_int(): 
		#print('not the client player')
		#print(multiplayer.get_unique_id())
		#print(name)
		return
	
	if event is InputEventMouseMotion:
		if(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
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
	if multiplayer.get_unique_id()==str(name).to_int():
		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			if multiplayer.is_server():
				jump()
			else:
				jump.rpc_id(1)
			
		if multiplayer.is_server():
			process_input(input_dir)
		else:
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
