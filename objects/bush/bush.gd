extends Node3D

#10 years
@export var maturity: int = int(1000 * 60 * 60 * 24 * 360 * (10))

@export var berries = 9:
	set(value):
		berries = value
		setup()

@export var birth_date: int = 0:
	set = set_birth_date
@export var extra_age: int = 0:
	set = set_extra_age

var calculated_age: int:
	get = calculate_age

var rng = RandomNumberGenerator.new()

@onready var world = $/root/Game/World
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


func get_actions():
	return ["pick_berry"]


func set_birth_date(value):
	birth_date = value


func set_extra_age(value):
	extra_age = value


func calculate_age():
	return world.world_age + extra_age + Time.get_ticks_msec() - birth_date


func save_node():
	var save_dict = {
		"transform": JSON3D.Transform3DtoDictionary(transform),
		"birth_date": birth_date,
		"extra_age": extra_age,
	}
	return save_dict


func load_node(node_data):
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	if "birth_date" in node_data:
		birth_date = node_data.birth_date
	if "extra_age" in node_data:
		extra_age = node_data.extra_age


func pick_berry():
	if berries:
		b[berries - 1].hide()
		berries = berries - 1
		#print(GlobalRandom.Items.berry)
		var a = {berry = GlobalRandom.Items.berry}
		a.berry.quantity = 1
		#print(a)
		return a
	else:
		return {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()


func setup():
	for i in range(0, 9):
		if i < berries and b:
			b[i].show()
		else:
			if b:
				b[i].hide()


func _process(_delta):
	var s = clampf(float(calculated_age) / maturity, .1, 1.0)
	scale = Vector3(s, s, s)

	if multiplayer.is_server():
		if berries < 9:
			if rng.randi_range(0, 1000) <= 1:
				print("spawn a berry")
				berries = berries + 1
