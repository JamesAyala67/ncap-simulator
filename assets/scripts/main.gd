# Main.gd
extends Node3D

@export var spawn_interval: float = 2.0
@export var spawn_speed: float = 5.0
@export var speed_increment: float = 1.0
@export var speed_increase_interval: float = 5.0
@export var spawn_entities: Array[PackedScene]  # Drag entity scenes here in Inspector

var spawn_points: Array[Marker3D] = []

func _ready():
	randomize()
	for child in $spawnpoints.get_children():
		if child is Marker3D:
			spawn_points.append(child as Marker3D)
		
	_start_spawn_timer()
	_start_speed_timer()

func _start_spawn_timer():
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(func(): _on_spawn_timer())
	add_child(timer)

func _start_speed_timer():
	var timer = Timer.new()
	timer.wait_time = speed_increase_interval
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(func(): _on_speed_timer())
	add_child(timer)

func _on_spawn_timer():
	if spawn_entities.is_empty() or spawn_points.is_empty():
		return
		
	var entity_scene = spawn_entities.pick_random()
	var spawn_point = spawn_points.pick_random()
	
	var entity = entity_scene.instantiate()
	entity.global_transform = spawn_point.global_transform
	entity.set("speed", spawn_speed)  # Assumes your entities have a `speed` variable
	add_child(entity)

func _on_speed_timer():
	spawn_speed += speed_increment

#CAMERA CCTV SHADER
func _process(delta):
	var color_rect = $CanvasLayer/ColorRect
	var mat = color_rect.material
	if mat is ShaderMaterial:
		mat.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)

	# Blink "REC" text
	if $CanvasLayer.has_node("REC"):
		$CanvasLayer/REC.visible = int(Time.get_ticks_msec() / 500) % 2 == 0

	# Show time
	if $CanvasLayer.has_node("TimeLabel"):
		$CanvasLayer/TimeLabel.text = Time.get_datetime_string_from_system()
		
