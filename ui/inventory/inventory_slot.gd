class_name InventorySlot
extends MarginContainer

@export var item: Dictionary
@export var src = null

@onready var attributes_label = %Attributes
@onready var name_label = %Name


func update_label() -> void:
	if item:
		name_label.text = item.name
		var s: String
		for key in item:
			if key not in ["birth_date","extra_age","name","class","scene_file_path","parent","category"]:
				s = s + "%s:%s\n" % [key, item[key]]
		attributes_label.text = s


func _ready():
	update_label()
