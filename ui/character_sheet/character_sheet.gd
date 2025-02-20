extends Node2D
@export var age = 0

@onready var age_field = $Age


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	age_field.text = GameTime.format(age)
