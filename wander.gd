class_name Wander
extends QuantityAction

@export var angle: int = 0

func _process(_delta):
	do()

func do():
	print("Wander.do")

	#+x is left, -x is right, y is up and down
	var r:Vector2=Vector2(angle,0)
	player.server_rotate(r)

	#forward
	var d:Vector2=Vector2(0,-1)
	player.server_move(d)
	#player.current_turn_actions.action='generic action'
