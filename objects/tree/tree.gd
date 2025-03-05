class_name MarbleTree
extends Node3D

#50 years
@export var maturity: int = int(1000 * 60 * 60 * 24 * 360 * (50))

##seconds
@export var age: float = 0
@export var warp_speed:float=1

@onready var world = $/root/Game/World
@onready var ageLabel = %AgeLabel


func save_node():
	var save_dict = {
		"transform": JSON3D.Transform3DtoDictionary(transform),
		"age": age
	}
	return save_dict


func load_node(node_data):
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	if "age" in node_data:
		age = node_data.age


func time_warp(minutes):
	print("tree time_warp")
	age = age + 1000 * 60 * minutes


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var s = clampf(float(age) / maturity, .1, 1.0)
	scale = Vector3(s, s, s)


func _physics_process(delta):
	if is_server():
		age = age + delta * warp_speed


func is_server()->bool:
	return multiplayer.is_server()
