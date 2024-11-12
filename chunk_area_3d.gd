extends Area3D

@onready var chunk = $".."


func request_rest(hours:int):
	chunk.server_request_rest(hours)
