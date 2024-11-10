extends Node3D

@export var birth_date=0
@export var extra_age=0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"name":name,
		"parent" : get_parent().get_path(),
		#"path": get_path(),
		"transform": JSON3D.Transform3DtoDictionary(transform),
		"birth_date":birth_date,
		"extra_age":extra_age,
	}
	return save_dict

func load(node_data):
	name=node_data["name"]
	transform=JSON3D.DictionaryToTransform3D(node_data["transform"])
	if "birth_date" in node_data:
		birth_date=node_data.birth_date
	if "extra_age" in node_data:
		extra_age=node_data.extra_age

func generate_terrain():
	var _a_mesh:ArrayMesh
	var surftool= SurfaceTool.new()

	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(30):
		for x in range(30):
			var y=0
			surftool.add_vertex(Vector3(x,y,z))

	_a_mesh=surftool.commit()
	#mesh=a_mesh

func _on_area_3d_body_entered(body: Node3D) -> void:
	Signals.PlayerZoned.emit(body.name,name)
