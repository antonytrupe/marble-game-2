class_name Chunk
extends Node3D

@export var birth_date: int = 0:
	set = set_birth_date
@export var extra_age: int = 0:
	set = set_extra_age

@export var flora: Node3D
@export var fauna: Node3D
@export var terra: Node3D
##list of warp_vote id's
@export var warp_votes: Array = []

var rng = RandomNumberGenerator.new()

var calculated_age: int:
	get = calculate_age

@onready var label = %AgeLabel
@onready var world = $/root/Game/World
@onready var flora_fauna_scanner = %FloraFaunaScanner
@onready var player_scanner = %PlayerScanner


func set_birth_date(value):
	birth_date = value


func set_extra_age(value):
	extra_age = value


func calculate_age():
	return world.world_age + extra_age + Time.get_ticks_msec() - birth_date


func get_players() -> Array[Node3D]:
	return player_scanner.get_overlapping_bodies()


func get_flora_fauna() -> Array[Node3D]:
	var areas = flora_fauna_scanner.get_overlapping_areas()
	var entities: Array[Node3D] = []
	for area: Area3D in areas:
		entities.append(area.get_parent())
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
	for p: MarbleCharacter in players:
		p.time_warp(minutes)
		p.play_fade.rpc()


func save_node():
	var save_dict = {
		transform = JSON3D.Transform3DtoDictionary(transform),
		birth_date = birth_date,
		extra_age = extra_age,
		warp_votes = warp_votes,
	}
	return save_dict


func load_node(node_data):
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


func _on_area_3d_body_entered(player_area: Node3D) -> void:
	if player_area is CharacterBody3D:
		Signals.PlayerZoned.emit(player_area, self)


func _on_chunk_area_3d_body_exited(player_area: Node3D) -> void:
	if player_area is CharacterBody3D:
		Signals.PlayerZoned.emit(player_area, self)
