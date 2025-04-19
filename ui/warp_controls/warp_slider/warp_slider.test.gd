extends GutTest

var instance: WarpSlider

func before_each():
	instance = partial_double(load("res://ui/warp_controls/warp_slider/warp_slider.gd"))\
	.new()
	add_child(instance)


func test_not_null():
	assert_not_null(instance)


func test_default_values():
	assert_eq_deep(instance.custom_values,[ 1, 2, 3, 4, 6, 8, 10,12,16,20,100,500,3000])
	assert_eq(instance.value,0.0)
	assert_eq(instance.custom_value,1.0)


func test_change_custom_value():
	instance.custom_value=2
	assert_almost_eq(instance.value,0.0833,0.001)
	assert_eq(instance.custom_value,2.0)
