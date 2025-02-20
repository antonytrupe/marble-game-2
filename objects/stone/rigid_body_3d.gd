extends RigidBody3D

@export var root: Node3D


func get_actions():
	root.get_actions()


func pick_up():
	return root.pick_up()
