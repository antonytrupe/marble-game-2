class_name Utilities
extends RefCounted


static func _get_random_vector(radius: float, center: Vector3) -> Vector3:
	var r = radius * sqrt(randf())
	var theta = randf() * 2 * PI
	var x = center.x + r * cos(theta)
	var z = center.z + r * sin(theta)
	return Vector3(x, 0, z)
