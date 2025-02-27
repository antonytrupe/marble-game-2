class_name WarpSlider
extends HSlider

@export var custom_values: Array[float] = [.1, .2, .3, .4, .5, .6, .7, .8, .9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,]
@export var custom_value: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	step = 1.0 / (custom_values.size() - 1)
	value_changed.connect(_on_value_changed)
	_on_value_changed(value)  # Initialize with the starting value


func _on_value_changed(value):
	custom_value = get_custom_value_from_normalized_position(value)
	print("Custom Value: ", custom_value)


func get_custom_value_from_normalized_position(normalized_position: float) -> float:
	if custom_values.is_empty():
		return 1

	var custom_values_count = custom_values.size()
	if custom_values_count == 1:
		return custom_values[0]

	var segment_width = 1.0 / (custom_values_count - 1)

	for i in range(custom_values_count - 1):
		if (
			normalized_position >= i * segment_width
			and normalized_position <= (i + 1) * segment_width
		):
			# Linear interpolation between custom values
			var segment_position = (normalized_position - i * segment_width) / segment_width
			return lerp(custom_values[i], custom_values[i + 1], segment_position)

		# Handle the case where the slider is at the very end
	return custom_values[custom_values_count - 1]
