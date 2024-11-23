extends Button

@export var type: String
#@export var items:Array=[]

@export var quantity: int:
	set = update_quantity
@onready var label = self


func update_quantity(q: int):
	quantity = q
	if label:
		label.text = "%s x%s" % [type, str(quantity)]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = "%s x%s" % [type, str(quantity)]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
