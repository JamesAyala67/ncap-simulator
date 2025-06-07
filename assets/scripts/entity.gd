extends CharacterBody3D

@export var speed: float = 5.0
var lane_index: int = -1  # Will be set by spawner

func _physics_process(delta):
	velocity = transform.basis.z * speed
	move_and_slide()

func go_poof():
	print("Poof!", self.name)
	queue_free()  # This removes the entity from the game
