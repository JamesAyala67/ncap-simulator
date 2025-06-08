extends CharacterBody3D

@export var speed: float = 5.0
@export var min_distance_ahead: float = 2.0  # Distance to check for collisions
@export var slowdown_factor: float = 0.3     # Scale speed when too close
@export var category: String = "commuter"    # Entity category (commuter, bus, motorcycle, etc.)

var lane_index: int = -1

func _ready():
	add_to_group("poofable")
	
	
func set_speed_multiplier(multiplier: float):
	speed *= multiplier
	
func _physics_process(delta):
	var forward = transform.basis.z.normalized()
	var origin = global_transform.origin + Vector3(0, 0.5, 0)  # slightly above ground to avoid false negatives
	var to = origin + forward * min_distance_ahead

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = origin
	ray_params.to = to
	ray_params.exclude = [self]
	ray_params.collide_with_areas = false
	ray_params.collide_with_bodies = true

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_params)

	var current_speed = speed
	if result and result.collider.is_in_group("poofable"):
		# Optional: consider distance to adjust speed gradually
		var distance = origin.distance_to(result.position)
		if distance < min_distance_ahead:
			current_speed *= slowdown_factor

	velocity = forward * current_speed
	move_and_slide()

func go_poof():
	# Notify the main scene regardless of lane
	get_tree().get_current_scene().call("on_entity_clicked", self)
	queue_free()
	
func get_lane_index() -> int:
	return lane_index

func get_category() -> String:
	return category
