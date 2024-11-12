extends CanvasLayer

@export var player_id: int

@onready var actionStatus = %ActionStatus
@onready var movementStatus = %MovementStatus


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.
	Signals.Actions.connect(_on_move_action)
	#Signals.NewTurn.connect(_on_new_turn)


func _on_move_action(_player_id, actions: Dictionary):
	print("actions _on_move_action ", actions)
	#print(player_id, _player_id, mode)
	if player_id == int(_player_id):
		#print("me")
		if actions.move:
			#print(MOVE.STRINGS[actions.move])
			movementStatus.text = MOVE.STRINGS[actions.move]
			if actions.move >= MOVE.MODE.HUSTLE:
				actionStatus.text = MOVE.STRINGS[actions.move]
		else:
			movementStatus.text = ""
		if actions.action:
			actionStatus.text = actions.action
		else:
			actionStatus.text = ""

#func _on_new_turn(_turn_id):
##print("actions _on_new_turn",_turn_id)
#movementStatus.text = ""
##print(movementStatus.text)
#actionStatus.text = ""
