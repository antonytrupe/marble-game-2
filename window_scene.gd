class_name UIWindow
extends Window

@export var me: MarbleCharacter


func _on_close_requested() -> void:
	visible = false


func save_node():
	var save_dict = {
		#
		position = JSON3D.Vector2ToDictionary(position),
		size = JSON3D.Vector2ToDictionary(size),
	}
	return save_dict


func load_node(node_data):
	if "position" in node_data:
		position = JSON3D.DictionaryToVector2(node_data.position)
	if "size" in node_data:
		size = JSON3D.DictionaryToVector2(node_data.size)
	for p in node_data:
		if p in self and p not in ["transform", "position", "size"]:
			self[p] = node_data[p]
