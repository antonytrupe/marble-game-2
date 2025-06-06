class_name Chunk
extends Node3D

##milliseconds
#@export var age: float = 0
#@export var warp_speed: float = 1

#@export var turn_number:int = 1

@export var flora: Node3D
@export var fauna: Node3D
@export var terra: Node3D
##list of warp_vote id's
#@export var warp_votes: Array = []

var rng = RandomNumberGenerator.new()


#@onready var label = %AgeLabel
@onready var world = $/root/Game/World
@onready var flora_fauna_scanner = %FloraFaunaScanner
@onready var player_scanner = %PlayerScanner


#func _ready():
	#Signals.WarpSpeedChanged.connect(_on_warp_speed_changed)


#func _physics_process(delta: float) -> void:
	#if multiplayer.is_server():
		#age = age + delta * warp_speed
		#var new_turn_number:int = (age) / (6 ) + 1
		#if turn_number != new_turn_number:
			#print('new turn:',new_turn_number)
			#turn_number = new_turn_number


#func _on_warp_speed_changed(value):
	#warp_speed = value


func get_players() -> Array[Node3D]:
	return player_scanner.get_overlapping_bodies()


func get_flora_fauna() -> Array[Node3D]:
	var areas = flora_fauna_scanner.get_overlapping_areas()
	var entities: Array[Node3D] = []
	for area: Area3D in areas:
		entities.append(area.get_parent())
	return entities


func save_node():
	var save_dict = {
		transform = JSON3D.Transform3DtoDictionary(transform),
		#age = age,
		#warp_speed = warp_speed,
		#warp_votes = warp_votes,
	}
	return save_dict


func load_node(node_data):
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	#if "age" in node_data:
		#age = node_data.age
	#if "warp_speed" in node_data:
		#warp_speed = node_data.warp_speed


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


func _on_area_3d_body_entered(player_area: Node3D) -> void:
	if player_area is CharacterBody3D:
		Signals.PlayerZoned.emit(player_area, self)


func _on_chunk_area_3d_body_exited(player_area: Node3D) -> void:
	if player_area is CharacterBody3D:
		Signals.PlayerZoned.emit(player_area, self)
