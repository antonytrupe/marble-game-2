extends Node3D
class_name Stone

@export var birth_date: int = 0:
	set = set_birth_date
@export var extra_age: int = 0:
	set = set_extra_age

var brittleness: float
var hardness: float
var sharpness: float
var mass:float
var volume:float

@onready var world = $/root/Game/World

static var category: String = "Stone"

var calculated_age: int:
	get = calculate_age


func _ready():
	var rng = RandomNumberGenerator.new()
	brittleness = rng.randi_range(1, 100)
	hardness = rng.randi_range(1, 100)


func craft(player: MarbleCharacter, loot: Dictionary):
	#print('%s stone crafting' % player.name, self)
	var result={}
	for item_name in loot.keys():
		var item=player.inventory[item_name]
		#print(item)
		if item.category == "Stone":
			if item.hardness<hardness:
				print("old sharpness:",item.sharpness)
				item.sharpness+=(item.brittleness/100.0)*(hardness/100.0)
				print("new sharpness:",item.sharpness)
			elif item.hardness>hardness:
				print('break tool')
		result[item.name]=item
	return result


func pick_up():
	hide()
	queue_free()

	var d = save()
	d.erase('transform')

	return {d.name:d}


func get_actions():
	print(get_parent().get_class())
	var actions = []
	if get_parent().name == 'Terra':
		actions.append('pick_up')
	elif get_parent().is_class('MarbleCharacter'):
		actions.append('knap')
	return actions


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
		category = category,
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
	if node_data.has("transform"):
		transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	for p in node_data:
		if p in self and p not in ['transform']:
			self[p] = node_data[p]
