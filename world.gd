class_name World
extends Node3D

const CHUNK_SCENE = preload("res://chunk.tscn")

@export var world_age: int = 0

var calculated_age: int:
	get = calculate_age

var turn_start: int = 0


func _ready() -> void:
	Signals.TimeWarp.connect(_on_time_warp)


func calculate_age():
	return world_age + Time.get_ticks_msec()


func save_node():
	var save_dict = {
		#
		"world_age": calculated_age
	}
	return save_dict


func load_node(node_data):
	name = node_data["name"]
	if "world_age" in node_data:
		world_age = node_data.world_age


func get_chunk_cirle(_center: Array[Chunk], _ring: int):
	#TODO get adjacent chunks
	pass


func _on_time_warp(minutes: int, chunks: Array[Chunk]):
	#var visited_chunks = chunks
	for chunk in chunks:
		chunk.time_warp(minutes)

	#TODO time warp adjacent chunks


func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


func update_health_bar(_health_value):
	#health_bar.value = health_value
	pass
