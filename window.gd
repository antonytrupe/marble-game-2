extends Window

@export var me: MarbleCharacter

func _on_close_requested() -> void:
	#print('window _on_close_requested')
	visible=false
