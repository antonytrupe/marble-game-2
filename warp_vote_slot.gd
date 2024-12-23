class_name WarpVoteSlot
extends MarginContainer

@export var warp_vote_id:String
@export var me:MarbleCharacter
@export var approved:bool:
	set=_set_approved
@export var display_name:String:
	set=_set_label

@onready var button:Button=%ApproveButton
@onready var label:Label=%Name

func _set_label(s:String):
	label.text=s

func _set_approved(b:bool):
	#if button:
		#print('button press')
	button.button_pressed=b
	if button.button_pressed:
		button.text="Approved"
		#button.pressed
	else:
		button.text="Approve"

func _on_approve_button_pressed() -> void:
	me.approve_warp_vote(warp_vote_id)
