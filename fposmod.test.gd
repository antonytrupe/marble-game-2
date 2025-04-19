extends GutTest


func test_fposmod():
	var Foo = load("res://day_night_cycle/day_night_cycle.gd")
	var partial = partial_double(Foo).new()

	var a = fposmod(partial.get_vector_from_hour(0).angle(), PI * 2)
	assert_almost_eq(a, PI * 2 / 4, .000001, "%f isn't %f" % [a, PI * 2 / 4])

	a = fposmod(partial.get_vector_from_hour(3).angle(), PI * 2)
	assert_almost_eq(a, PI * 3 / 4, .000001, "%f isn't %f" % [a, PI * 3 / 4])

	a = fposmod(partial.get_vector_from_hour(6).angle(), PI * 2)
	assert_almost_eq(a, PI * 4 / 4, .000001, "%f isn't %f" % [a, PI * 4 / 4])

	a = fposmod(partial.get_vector_from_hour(9).angle(), PI * 2)
	assert_almost_eq(a, PI * 5 / 4, .000001, "%f isn't %f" % [a, PI * 5 / 4])

	a = fposmod(partial.get_vector_from_hour(12).angle(), PI * 2)
	assert_almost_eq(a, PI * 6 / 4, .000001, "%f isn't %f" % [a, PI * 6 / 4])

	a = fposmod(partial.get_vector_from_hour(15).angle(), PI * 2)
	assert_almost_eq(a, PI * 7 / 4, .000001, "%f isn't %f" % [a, PI * 7 / 4])

	a = fposmod(partial.get_vector_from_hour(18).angle(), PI * 2)
	assert_almost_eq(a, PI * 0 / 4, .000001, "%f isn't %f" % [a, PI * 0 / 4])

	a = fposmod(partial.get_vector_from_hour(21).angle(), PI * 2)
	assert_almost_eq(a, PI * 1 / 4, .000001, "%f isn't %f" % [a, PI * 1 / 4])

	a = fposmod(partial.get_vector_from_hour(24).angle(), PI * 2)
	assert_almost_eq(a, PI * 2 / 4, .000001, "%f isn't %f" % [a, PI * 2 / 4])

	a = fposmod(
		(partial.get_vector_from_hour(6) + partial.get_vector_from_hour(12)).angle(), PI * 2
	)
	assert_almost_eq(a, PI * 5 / 4, .000001, "%f isn't %f" % [a, PI * 5 / 4])

	a = lerp_angle(1, 2, .0001)
	assert_almost_eq(a, 1.0001, .000001, "%f isn't %f" % [a, 1.0001])

	a = lerp_angle(2, 1, .0001)
	assert_almost_eq(a, 1.9999, .000001, "%f isn't %f" % [a, 1.9999])
