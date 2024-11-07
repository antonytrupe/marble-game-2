extends Node3D


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
		#"transform": Player.Transform3D_to_Dictionary(transform),
	}
	return save_dict

func load(node_data):
	name=node_data["name"]

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
