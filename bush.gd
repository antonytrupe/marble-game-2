extends Node3D

@export var berries = 9:
	set(value):
		berries = value
		setup()

@onready var b = [
	$BushMeshInstance3D/BerryMeshInstance3D1,
	$BushMeshInstance3D/BerryMeshInstance3D2,
	$BushMeshInstance3D/BerryMeshInstance3D3,
	$BushMeshInstance3D/BerryMeshInstance3D4,
	$BushMeshInstance3D/BerryMeshInstance3D5,
	$BushMeshInstance3D/BerryMeshInstance3D6,
	$BushMeshInstance3D/BerryMeshInstance3D7,
	$BushMeshInstance3D/BerryMeshInstance3D8,
	$BushMeshInstance3D/BerryMeshInstance3D9,
]


func pickBerry():
	if berries:
		b[berries - 1].hide()
		berries = berries - 1
		print(berries)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()


func setup():
	for i in range(0, 9):
		if i < berries:
			b[i].show()
		else:
			b[i].hide()
