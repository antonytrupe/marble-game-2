extends Node3D

@export var birth_date: int = 0:
	set = set_birth_date
@export var extra_age: int = 0:
	set = set_extra_age

var brittleness: int = 50
var hardness: int = 50
var sharpness: int = 0

@onready var world = $/root/Game/World

static var category: String = "Stone"

var calculated_age: int:
	get = calculate_age


func _ready():
	var rng = RandomNumberGenerator.new()
	brittleness = rng.randi_range(1, 100)
	hardness = rng.randi_range(1, 100)


func craft(player: MarbleCharacter, items):
	print('%s stone crafting' % player.name, items)
	for type in items:
		print(type)

	return items


func pick_up():
	hide()
	queue_free()

	var d = save()
	d.erase('transform')

	return {
		category:
		{
			#
			quantity = 1,
			scene_file_path = scene_file_path,
			items = [d],
		}
	}


func get_actions():
	return ["pick_up", "knap"]


func set_birth_date(value):
	birth_date = value


func set_extra_age(value):
	extra_age = value


func calculate_age():
	return world.world_age + extra_age + Time.get_ticks_msec() - birth_date


func toDictionary() -> Dictionary:
	return save()


func save() -> Dictionary:
	var save_dict = {
		transform = JSON3D.Transform3DtoDictionary(transform),
		birth_date = birth_date,
		extra_age = extra_age,
		name = name,
		category=category,
		"class" = get_class(),
		scene_file_path = get_scene_file_path(),
		hardness = hardness,
		sharpness = sharpness,
		brittleness = brittleness,

	}
	if get_parent():
		save_dict.parent = get_parent().get_path()
	return save_dict


func load(node_data: Dictionary):
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	for p in node_data:
		if p in self and p not in ['transform']:
			self[p] = node_data[p]
