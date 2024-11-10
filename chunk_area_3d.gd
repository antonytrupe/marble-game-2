extends Area3D

@onready var chunk=$".."

func request_long_rest():
	chunk.server_request_long_rest()
