class_name UIWindow
extends Window

@export var me: MarbleCharacter
var saved_position:Vector2i:
	set=_set_position

func _set_position(p:Vector2):
	position=p

func _on_close_requested() -> void:
	print('_on_close_requested')
	#location=position
	visible=false


func _on_visibility_changed() -> void:
	print('_on_visibility_changed')
	if visible and saved_position:
		position=saved_position
	else:
		saved_position=position

func save_node():
	var save_dict = {
		#
		saved_position = JSON3D.Vector2ToDictionary(saved_position),
	}
	return save_dict

func load_node(node_data):
	print(node_data)
	saved_position=JSON3D.DictionaryToVector2(node_data.saved_position)
	for p in node_data:
		if p in self and p not in ["transform","saved_position"]:
			self[p] = node_data[p]
