extends Node3D

#@onready var signals=$/root/Game/Signals
#@onready var j=preload("res://JSON.cs")

#@onready var signals=load("res://Signals.cs").new()

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
	}
	return save_dict

func load(node_data):
	name=node_data["name"]
	#transform=Dictionary_to_Transform3D(node_data["transform"])
	transform=JSON3D.DictionaryToTransform3D(node_data["transform"])

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
	print(body.name,' entered ', name)
	Signals.PlayerZoned.emit(body.name,name)
	pass # Replace with function body.
