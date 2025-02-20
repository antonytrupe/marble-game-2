class_name WarpVote
extends Node

@export var players: Dictionary = {}
@export var chunks: Dictionary = {}


func save_node() -> Dictionary:
	var save_dict = {
		players = players,
		chunks = chunks,
	}
	return save_dict


func load_node(data: Dictionary):
	for p in data:
		if p in self and p not in ["transform", "parent"]:
			self[p] = data[p]
