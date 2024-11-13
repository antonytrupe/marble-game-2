extends CanvasLayer

@export var player_id: int

@onready var actionStatus = %ActionStatus
@onready var movementStatus = %MovementStatus


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.Actions.connect(_on_move_action)
	#Signals.NewTurn.connect(_on_new_turn)


func _on_move_action(_player_id, actions: Dictionary):
	#print("actions _on_move_action ", actions)
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
			if actions.action is String:
				actionStatus.text = actions.action
			elif actions.action is MOVE.MODE:
				actionStatus.text = MOVE.STRINGS[actions.move]
		else:
			actionStatus.text = ""
