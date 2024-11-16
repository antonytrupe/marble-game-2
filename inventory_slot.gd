extends PanelContainer

@export var item: String

@export var quantity: int:
	set = update_quantity
@onready var label = $MarginContainer/Label


func update_quantity(q: int):
	print(item)
	quantity = q
	print(quantity)
	if label:
		label.text = "%s x%s" % [item, str(quantity)]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = "%s x%s" % [item, str(quantity)]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
