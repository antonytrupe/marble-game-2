class_name World
extends Node3D

##milliseconds
@export var age: float = 0

@export var warp_speed:float=1.0

@export var turn_number:int=1


func is_server()->bool:
	return multiplayer.is_server()


@rpc("any_peer")
func set_warp_speed(value:float) -> void:
	print('world.set_warp_speed')
	if is_server():
		print('setting world warp speed')
		warp_speed=value

#delta is in seconds
func _physics_process(delta):
	if multiplayer.is_server():
		age = age + delta * warp_speed *1000
		#print(age)
		var new_turn_number:int = int(age / 6000  + 1)
		#print(new_turn_number)
		if turn_number != new_turn_number:
			#print('new turn:',new_turn_number)
			turn_number = new_turn_number


func save_node():
	var save_dict = {
		"age": age,
		"warp_speed": warp_speed,
		"turn_number": turn_number,
	}
	return save_dict


func load_node(node_data):
	name = node_data["name"]
	if "age" in node_data:
		age = node_data.age
	if "warp_speed" in node_data:
		warp_speed = node_data.warp_speed
	if "turn_number" in node_data:
		turn_number = node_data.turn_number


func get_chunk_cirle(_center: Array[Chunk], _ring: int):
	#TODO get adjacent chunks
	pass


func _on_time_warp(minutes: int, chunks: Array[Chunk]):
	#var visited_chunks = chunks
	for chunk in chunks:
		chunk.time_warp(minutes)

	#TODO time warp adjacent chunks
