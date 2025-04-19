class_name WarpSlider
extends HSlider

@export var custom_values: Array[int] = [ 1, 2, 3, 4, 6, 8, 10,12,16,20,100,500,3000]
@export var custom_value: float = 1.0:
	set=_set_custom_value

signal custom_value_changed(value:float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	step = 1.0 / (custom_values.size() - 1)
	tick_count=custom_values.size()
	value_changed.connect(_on_value_changed)
	_on_value_changed(value)  # Initialize with the starting value


func _set_custom_value(v:float):
	custom_value=v
	value=get_normalized_position_from_custom_value(v)


func _on_value_changed(new_value):
	custom_value = get_custom_value_from_normalized_position(new_value)
	custom_value_changed.emit(custom_value)


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


func get_normalized_position_from_custom_value(cv: float) -> float:

	if custom_values.is_empty():
		return -1.0

	var custom_values_count = custom_values.size()
	if custom_values_count == 1:
		if custom_values[0] == cv:
			return 0.0
		else:
			return -1.0

	for i in range(custom_values_count - 1):
		if cv >= custom_values[i] and cv <= custom_values[i + 1]:
			# Linear interpolation to find the normalized position within the segment
			var segment_position = (cv - custom_values[i]) / (custom_values[i + 1] - custom_values[i])
			return (i + segment_position) / (custom_values_count - 1)

	# Handle edge cases
	if cv <= custom_values[0]:
		return 0.0
	elif cv >= custom_values[custom_values_count - 1]:
		return 1.0

	return -1.0  # Custom value not found within the range
