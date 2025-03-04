class_name TurnTimerUI
extends MarginContainer

@export var player:MarbleCharacter
@export var world:World

@onready var turn_timer:ProgressBar=%TurnTimer
@onready var turn_number:Label=%TurnNumber


# Called every frame. 'delta' is the elapsed time since the previous frame in seconds
func _process(_delta: float) -> void:
	if player:
		#print('using player age')
		#turn timer from 0 to 6000 in milliseconds
		turn_timer.value = int(player.age*1000) % 6000
		turn_number.text = "turn " + str(player.turn_number)
	elif world:
		#print('using world age')
		turn_timer.value = int(world.age*1000) % 6000
		turn_number.text = "turn " + str(world.turn_number)
