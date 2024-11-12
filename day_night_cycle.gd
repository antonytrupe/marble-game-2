extends Node3D
@onready var game = $".."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var hour = GameTime.get_age_parts(game.calculated_age).hours
	#game.sun.rotation.x = 12 / 24.0 * PI * 2
	#0 is sunset
	#1/2pi is midnight
	#pi is sunrise
	#pi*3/2 is noon
	#pi*2 is sunset

	game.sun.rotation.x = hour / 24.0 * 2.0 * PI + PI / 2
