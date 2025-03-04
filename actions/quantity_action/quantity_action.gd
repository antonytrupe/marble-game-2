class_name QuantityAction
extends Node

@export var player: MarbleCharacter:
	set=_set_player
@export var game: Game
@export var frequency: int = 1
@export var start_turn: int
@export var last_turn = null
@export var remaining: int = 1


func _ready():
	add_to_group("persist")


func _set_player(p:MarbleCharacter):
	player=p
	player.add_child(self)


func do():
	print("QuantityAction.do")
	#player.current_turn_actions.action='generic action'

func stop():
	print("all done")
	queue_free()
	get_parent().remove_child(self)

func _process(_delta):
	#if we aren't supposed to start yet
	if player.turn_number < start_turn:
		print("wait for first turn")
		return
	#if we already did it this turn
	#if game.turn_number<=last_turn:
	#return
	#if its not time to do it again
	if last_turn != null and last_turn + frequency > player.turn_number:
		print("wait for next turn")
		print('last turn',last_turn)
		print('player.turn_number',player.turn_number)
		return

	do()

	last_turn = player.turn_number

	remaining = remaining - 1
	if remaining <= 0:
		stop()
