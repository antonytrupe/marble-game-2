extends Node3D
@onready var sun = %Sun

@onready var chunks: Array[Chunk] = [%"[0,0,0]"]


func _ready() -> void:
	var a = fposmod(getVectorFromHour(0).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 2 / 4), "%f isn't %f" % [a, PI * 2 / 4])

	a = fposmod(getVectorFromHour(3).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 3 / 4), "%f isn't %f" % [a, PI * 3 / 4])

	a = fposmod(getVectorFromHour(6).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 4 / 4), "%f isn't %f" % [a, PI * 4 / 4])

	a = fposmod(getVectorFromHour(9).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 5 / 4), "%f isn't %f" % [a, PI * 5 / 4])

	a = fposmod(getVectorFromHour(12).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 6 / 4), "%f isn't %f" % [a, PI * 6 / 4])

	a = fposmod(getVectorFromHour(15).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 7 / 4), "%f isn't %f" % [a, PI * 7 / 4])

	a = fposmod(getVectorFromHour(18).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 0 / 4), "%f isn't %f" % [a, PI * 0 / 4])

	a = fposmod(getVectorFromHour(21).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 1 / 4), "%f isn't %f" % [a, PI * 1 / 4])

	a = fposmod(getVectorFromHour(24).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 2 / 4), "%f isn't %f" % [a, PI * 2 / 4])

	a = fposmod((getVectorFromHour(6) + getVectorFromHour(12)).angle(), PI * 2)
	assert(is_equal_approx(a, PI * 5 / 4), "%f isn't %f" % [a, PI * 5 / 4])

	a = lerp_angle(1, 2, .0001)
	assert(is_equal_approx(a, 1.0001), "%f isn't %f" % [a, 1.0001])

	a = lerp_angle(2, 1, .0001)
	assert(is_equal_approx(a, 1.9999), "%f isn't %f" % [a, 1.9999])


func getVectorFromHour(hour: int):
	var radians = hour / 24.0 * 2.0 * PI + PI / 2.0
	var v = Vector2.from_angle(radians)
	return v


func _process(_delta: float) -> void:
	if chunks.size() == 0:
		return
	var total = Vector2(0.0, 0.0)
	for c in chunks:
		var hour = GameTime.get_age_parts(c.calculated_age).hours
		var v = getVectorFromHour(hour)
		total = total + v

	#0 is sunset
	#1/2pi is midnight
	#pi is sunrise
	#pi*3/2 is noon
	#pi*2 is sunset
	#offset by a quarter circle to get midnight to be down
	var end: float = fposmod(total.angle(), PI * 2)
	var start = fposmod(sun.rotation.x, PI * 2)

	#.001 is a little slow
	var _lerp = lerp_angle(start, end, .001)
	#print("start:%f end:%f lerp:%f" % [start, end, _lerp])
	if is_equal_approx(_lerp, end):
		_lerp = end
	else:
		pass
		#print("lerping")
		#print("start:%f end:%f lerp:%f" % [start, end, _lerp])

	sun.rotation.x = _lerp
