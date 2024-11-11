extends Node3D

@onready var label = $Label3D
@onready var game = $"../.."

@export var birth_date = 0:
	set = set_birth_date
@export var extra_age = 0:
	set = set_extra_age
var calculated_age:
	get = calculate_age

func set_birth_date(value):
	birth_date = value


func set_extra_age(value):
	extra_age = value


func calculate_age():
	return game.server_age + extra_age + Time.get_ticks_msec() - birth_date


func server_request_long_rest():
	print('chunk request long rest')
	if !multiplayer.is_server():
		print('someone trying to call request_long_rest')
		return
	extra_age = extra_age + 1000 * 60 * 60 * 8


func save():
	var save_dict = {
		"filename": get_scene_file_path(),
		"name": name,
		"parent": get_parent().get_path(),
		#"path": get_path(),
		"transform": JSON3D.Transform3DtoDictionary(transform),
		"birth_date": birth_date,
		"extra_age": extra_age,
	}
	return save_dict


func load(node_data):
	name = node_data["name"]
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	if "birth_date" in node_data:
		birth_date = node_data.birth_date
	if "extra_age" in node_data:
		extra_age = node_data.extra_age


func generate_terrain():
	var _a_mesh: ArrayMesh
	var surftool = SurfaceTool.new()

	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(30):
		for x in range(30):
			var y = 0
			surftool.add_vertex(Vector3(x, y, z))

	_a_mesh = surftool.commit()
	#mesh=a_mesh


func _on_area_3d_body_entered(body: Node3D) -> void:
	Signals.PlayerZoned.emit(body.name, name)


func _process(_delta):
	label.text = \
		"birth date:" + str(birth_date) + "\n" + \
		"extra age:" + str(extra_age) + "\n" + \
		"calculated age:" + str(calculated_age) + "\n"
