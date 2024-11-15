#@tool
extends Node3D

#10 years
@export var maturity: int = 1000 * 60 * 60 * 24 * 360 * (10 * .001)

@export var birth_date: int = 0:
	set = set_birth_date
@export var extra_age: int = 0:
	set = set_extra_age

@onready var world = $/root/Game/World

var calculated_age: int:
	get = calculate_age


func time_warp(minutes):
	print('tree time_warp')
	extra_age = extra_age + 1000 * 60 * minutes


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#rotation.y += PI * delta * .1
	var s = clampf(float(calculated_age) / maturity, .1, 1.0)
	#s = .5
	scale = Vector3(s, s, s)


func set_birth_date(value):
	birth_date = value


func set_extra_age(value):
	extra_age = value


func calculate_age():
	return world.world_age + extra_age + Time.get_ticks_msec() - birth_date
