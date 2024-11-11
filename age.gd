extends Node3D

@onready var label = $Seconds


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label.text = "%s years, %s days, %s:%s:%s" % [1, 1, 1, 1, 1]
