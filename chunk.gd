extends Node3D
class_name Chunk

@export var birth_date: int = 0:
	set = set_birth_date
@export var extra_age: int = 0:
	set = set_extra_age

@onready var label = %AgeLabel
@onready var world = $/root/Game/World
@onready var floraFaunaScanner = %FloraFaunaScanner
@onready var playerScanner = %PlayerScanner

var calculated_age: int:
	get = calculate_age


#func _process(_delta):
	#label.text = GameTime.format(calculated_age)


# func _ready():
# 	for player: MarbleCharacter in get_players():
# 		var zones = player.get_zones()


func set_birth_date(value):
	birth_date = value


func set_extra_age(value):
	extra_age = value


func calculate_age():
	return world.world_age + extra_age + Time.get_ticks_msec() - birth_date


func get_players():
	return playerScanner.get_overlapping_bodies()


func get_flora_fauna() -> Array[Node3D]:
	var areas = floraFaunaScanner.get_overlapping_areas()
	var entities: Array[Node3D] = []
	for area: Area3D in areas:
		entities.append(area.get_parent())

	#print("flora_fauna:", entities)

	return entities


func time_warp(minutes: int):
	if !multiplayer.is_server():
		print("someone trying to call time_warp")
		return
	extra_age = extra_age + 1000 * 60 * minutes

	# TODO get everythng else in this chunk and time warp it
	var flora_fauna = get_flora_fauna()
	for f in flora_fauna:
		f.time_warp(minutes)

	# tell all the players there was a timewarp
	var players = get_players()
	for p in players:
		p.play_fade.rpc()


func save():
	var save_dict = {
		"transform": JSON3D.Transform3DtoDictionary(transform),
		"birth_date": birth_date,
		"extra_age": extra_age,
	}
	return save_dict


func load(node_data):
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


func _on_area_3d_body_entered(playerArea: Node3D) -> void:
	if playerArea is CharacterBody3D:
		Signals.PlayerZoned.emit(playerArea, self)


func _on_chunk_area_3d_body_exited(playerArea: Node3D) -> void:
	if playerArea is CharacterBody3D:
		Signals.PlayerZoned.emit(playerArea, self)
