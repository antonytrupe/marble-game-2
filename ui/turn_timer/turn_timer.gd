class_name TurnTimerUI
extends MarginContainer

@export var character:MarbleCharacter
@export var world:World

@onready var turn_timer:ProgressBar=%TurnTimer
@onready var turn_number:Label=%TurnNumber


#delta is in seconds
func _process(_delta: float) -> void:
	if character:
		#print('using player age')
		#turn timer from 0 to 6000 in milliseconds
		turn_timer.value = int(character.age*1) % 6000
		turn_number.text = "turn " + str(character.turn_number)
	elif world:
		#print('using world age')
		turn_timer.value = int(world.age*1) % 6000
		turn_number.text = "turn " + str(world.turn_number)
