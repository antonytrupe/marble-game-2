class_name Wander
extends QuantityAction

var angle_velocity:Vector2 =Vector2(0,0)
var speed_velocity:Vector2 =Vector2(0,0)

func _process(_delta):
	pass

func _physics_process(_delta):
	print("Wander._physics_process")

	if(remaining<=0):
		stop()
		return

	#if its a new turn, pick a new angle
	if(last_turn==null or player.turn_number>last_turn):
		print('picking new direction')
		angle_velocity=get_angle_velocity()
		speed_velocity=get_speed_velocity()
		remaining=remaining-1

	#+x is left, -x is right, y is up and down
	player.server_rotate(angle_velocity)

	#forward
	player.server_move(speed_velocity)

	last_turn=player.turn_number


func get_angle_velocity():
	var s=randi_range(-5,5)
	return Vector2(s,0)


func get_speed_velocity():
	var s=randi_range(0,1)
	return Vector2(s,0)
