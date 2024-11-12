extends Node2D
@export var age = 0

@onready var ageField = $Age


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	ageField.text = GameTime.format(age)
