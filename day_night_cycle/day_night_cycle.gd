class_name DayNightCycle
extends Node
@export var intensity: Curve

@export var player: MarbleCharacter
@export var world: World

@onready var sun = %Sun

func get_vector_from_hour(hour: float):
	var radians = hour / 24.0 * 2.0 * PI + PI / 2.0
	var v = Vector2.from_angle(radians)
	return v


func get_target_position():
	var total = Vector2(0.0, 0.0)
	#for c:Chunk in _chunks:
	var t = {hours = 0, minutes = 0, seconds = 0}
	if player:
		t = GameTime.get_age_parts(player.age)
		#print("using player")
	elif world:
		t = GameTime.get_age_parts(world.age)
		#print("using world")
	var hour = t.hours + t.minutes / 60.0 + t.seconds / (60.0 * 60.0)
	var v = get_vector_from_hour(hour)
	total = total + v
	return total


func set_angle_and_intensity(rotation_x, light_energy):
	sun.rotation.x = rotation_x
	sun.light_energy = light_energy


func _process(_delta: float) -> void:
	#if !chunks or chunks.size() == 0:
	##print("no chunks %s"%[game.player_id])
	#return
	var total = get_target_position()

	#0 is sunset
	#1/2pi is midnight
	#pi is sunrise
	#pi*3/2 is noon
	#pi*2 is sunset
	#offset by a quarter circle to get midnight to be down
	var end: float = fposmod(total.angle(), PI * 2)
	var current = fposmod(sun.rotation.x, PI * 2)

	#.001 is a little slow
	var rotation_x = lerp_angle(current, end, .05)
	#TODO make sure the sun doesn't go backwards
	#skip lerp for troubleshooting
	#rotation_x = end
	if is_equal_approx(rotation_x, end):
		rotation_x = end

	var light_energy = intensity.sample(fposmod(rotation_x - PI / 2.0, PI * 2) / (PI * 2))
	#if player and !player.is_server():
		#print(rotation_x)

	set_angle_and_intensity(rotation_x, light_energy)
