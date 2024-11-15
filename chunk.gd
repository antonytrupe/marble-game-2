extends Node3D
class_name Chunk

@onready var label = $Label3D
@onready var world = $"/root/Game/World"

@export var birth_date: int = 0:
	set = set_birth_date
@export var extra_age: int = 0:
	set = set_extra_age
var calculated_age: int:
	get = calculate_age


func set_birth_date(value):
	birth_date = value


func set_extra_age(value):
	extra_age = value


func calculate_age():
	return world.world_age + extra_age + Time.get_ticks_msec() - birth_date


func get_players():
	return $ChunkArea3D.get_overlapping_bodies()


func server_request_rest(minutes: int):
	#print("chunk server_request_rest")
	if !multiplayer.is_server():
		print("someone trying to call server_request_rest")
		return
	extra_age = extra_age + 1000 * 60 * minutes
	#TODO tell all the players there was a timewarp
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


func _on_area_3d_body_entered(playerArea: CharacterBody3D) -> void:
	#print(self)
	Signals.PlayerZoned.emit(playerArea, self)


func _process(_delta):
	#label.text = "birth date:" + str(birth_date) + "\n" + "extra age:" + str(extra_age) + "\n" + "calculated age:" + str(calculated_age) + "\n"
	var age = GameTime.get_age_parts(calculated_age)
	label.text = "%d years, %d months, %d days, %02d:%02d:%02d" % [age.years, age.months, age.days, age.hours, age.minutes, age.seconds]


func _on_chunk_area_3d_body_exited(playerArea: CharacterBody3D) -> void:
	Signals.PlayerZoned.emit(playerArea, self)
