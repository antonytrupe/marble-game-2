class_name QuantityAction
extends Node

@export var player: MarbleCharacter
@export var game: Game
@export var frequency: int = 1
@export var start_turn: int
@export var last_turn = null
@export var remaining: int = 1


func _ready():
	add_to_group("persist")


func do():
	print("QuantityAction.do")
	#player.current_turn_actions.action='generic action'


func _process(_delta):
	#if we aren't supposed to start yet
	if game.turn_number < start_turn:
		#print("wait for first turn")
		return
	#if we already did it this turn
	#if game.turn_number<=last_turn:
	#return
	#if its not time to do it again
	if last_turn != null and last_turn + frequency > game.turn_number:
		#print("wait for next turn")
		#print('last turn',last_turn)
		return

	do()

	last_turn = game.turn_number

	remaining = remaining - 1
	if remaining <= 0:
		print("all done")
		queue_free()
		get_parent().remove_child(self)
