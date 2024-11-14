extends StaticBody3D

@onready var root = $".."


func pick_berry():
	return root.pick_berry()
