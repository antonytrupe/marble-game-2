extends Node3D

@export var birth_date: int = 0:
	set = set_birth_date
@export var extra_age: int = 0:
	set = set_extra_age

@onready var world = $/root/Game/World

static var label: String = "Stone"

var calculated_age: int:
	get = calculate_age


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
		self.label:
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


func save() -> Dictionary:
	var save_dict = {
		"transform": JSON3D.Transform3DtoDictionary(transform),
		"birth_date": birth_date,
		"extra_age": extra_age,
		"name": name,

		"class": get_class(),
		"scene_file_path": get_scene_file_path(),
	}
	if get_parent():
		save_dict.parent = get_parent().get_path()
	return save_dict


func toDictionary() -> Dictionary:
	return save()


func load(node_data: Dictionary):
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	if "birth_date" in node_data:
		birth_date = node_data.birth_date
	if "extra_age" in node_data:
		extra_age = node_data.extra_age
