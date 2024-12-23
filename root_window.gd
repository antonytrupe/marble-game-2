extends Window


func save_node():
	print('root window save')
	# print(get_viewport().get_window().position)
	# print(get_viewport().get_window().current_screen)
	var data = {
		#
		initial_position = initial_position,
		mode = mode,
		position = JSON3D.Vector2ToDictionary(position),
		size = JSON3D.Vector2ToDictionary(size),
		current_screen = current_screen,
	}
	print(data)
	return data


func load_node(data):
	print('root window load')
	if "size" in data:
		size = JSON3D.DictionaryToVector2(data["size"])
	if "position" in data:
		position = JSON3D.DictionaryToVector2(data["position"])
	for p in data:
		if p in self and p not in ["size","position" ,"parent"]:
			self[p] = data[p]
