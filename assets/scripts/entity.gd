extends CharacterBody3D

@export var speed: float = 5.0
var lane_index: int = -1  # Will be set by spawner

func _physics_process(delta):
	velocity = transform.basis.z * speed
	move_and_slide()

func _input_event(camera: Camera3D, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_parent().has_method("on_entity_clicked"):
			get_parent().on_entity_clicked(self)
