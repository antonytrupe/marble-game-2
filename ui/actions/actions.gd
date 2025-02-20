extends CanvasLayer

@export var player_id: int

@onready var action_status = %ActionStatus
@onready var movement_status = %MovementStatus


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.Actions.connect(_on_action)
	#Signals.NewTurn.connect(_on_new_turn)


func _on_action(_player_id, actions: Dictionary):
	#print("actions _on_move_action ")
	#print(player_id, _player_id, actions)
	if player_id == int(_player_id):
		#print("me")
		#print(player_id, _player_id, actions)

		if actions.move:
			#print(MOVE.STRINGS[actions.move])
			movement_status.text = MOVE.STRINGS[actions.move]
		else:
			movement_status.text = ""

		if actions.action:
			#print(type_string(typeof(actions.action)))
			if actions.action is String:
				#print("action is string")
				action_status.text = actions.action
			elif actions.action is MOVE.MODE:
				action_status.text = MOVE.STRINGS[actions.move]
		else:
			action_status.text = ""
