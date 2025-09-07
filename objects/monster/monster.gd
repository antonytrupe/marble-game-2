class_name Monster
extends CharacterBody3D

@export var movement_speed: float = 2.0
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	set_movement_target(create_movement_target())


func create_movement_target()->Vector3:
	return Utilities._get_random_vector(10,position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Do not query when the map has never synchronized and is empty.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if navigation_agent.is_navigation_finished():
		set_movement_target(create_movement_target())
		return

	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = global_position.direction_to(next_path_position) * movement_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
		pass
	else:
		#_on_velocity_computed(new_velocity)
		pass


func _on_velocity_computed(safe_velocity: Vector3):
	var old_y=velocity.y
	velocity = safe_velocity
	velocity.y=old_y
	move_and_slide()


func save_node():
	var save_dict = {
		transform = JSON3D.Transform3DtoDictionary(transform),
	}
	return save_dict


func load_node(node_data):
	transform = JSON3D.DictionaryToTransform3D(node_data["transform"])
	for p in node_data:
		if p in self and p not in ["transform", "parent"]:
			self[p] = node_data[p]
