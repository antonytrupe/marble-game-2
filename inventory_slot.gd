class_name InventorySlot
extends Button

@export var type_scene_file_path: String

@export var category: String
var _items = {}:
	get = get_items

@onready var label = self


func get_items():
	return _items


func size():
	return _items.keys().size()


func add_items(items: Dictionary):
	for item in items.values():
		_items[item.name] = item
		category = item.category
	update()


func remove_item(item: Dictionary):
	_items.erase(item.name)
	update()


func add_item(item: Dictionary):
	_items[item.name] = item
	category = item.category
	update()


func update_category(c: String):
	category = c
	update()


# Called when the node enters the scene tree for the first time.
func update() -> void:
	#print("item inventory update")
	if label:
		if size() == 0:
			hide()
		else:
			show()
		label.text = "%s x%s" % [category, str(size())]


func _ready():
	update()
