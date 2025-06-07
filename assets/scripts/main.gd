extends Node3D

@export var spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.3
@export var spawn_speed: float = 5.0
@export var speed_increment: float = 1.0
@export var spawn_speed_variance: float = 2.0
@export var spawn_entities: Array[PackedScene]
@export var spawn_points_group: NodePath = "SpawnPoints"
@export var default_spawn_indexes: Array[int] = [0, 1]
@export var random_spawn_chance: float = 0.35
@export var lane_categories: Array[String] = ["commuter", "commuter", "motorcycle", "private", "private", "bus"] # Index must match spawn points
@export var slowdown_combo_threshold: int = 15
@export var slowdown_multiplier: float = 0.5
@export var slowdown_duration: float = 3.0

var spawn_points: Array[Marker3D] = []
var lives: int = 3
var combo_counter: int = 0
var highest_combo: int = 0
var lane_category_mapping: Dictionary = {}
var game_over: bool = false
var score: int = 0
var is_slowdown_active := false
var slowdown_timer: Timer = null
var can_use_slowdown: bool = false
var slowdown_used: bool = false
var slowdown_cooldown: Timer = null
var slowdown_cooldown_time_left: float = 0.0
const SLOWDOWN_COOLDOWN_TIME: float = 7.0

var point_values := {
	"motorcycle": 7,
	"commuter": 3,
	"private": 3,
	"bus": 5,
	"airplane": 50
}

func _ready():
	randomize()
	for i in range(lane_categories.size()):
		lane_category_mapping[i] = lane_categories[i]

	var group_node = get_node_or_null(spawn_points_group)
	if group_node:
		for child in group_node.get_children():
			if child is Marker3D:
				spawn_points.append(child as Marker3D)

	_start_spawn_timer()
	_start_speed_timer()
	_update_ui()  # initialize UI values
	$CanvasLayer/SlowdownButton.pressed.connect(_on_slowdown_button_pressed)

func _start_spawn_timer():
	var timer = Timer.new()
	timer.name = "SpawnTimer"
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(func(): _on_spawn_timer())
	add_child(timer)

func _start_speed_timer():
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(func(): _on_speed_timer())
	add_child(timer)

func _on_spawn_timer():
	if spawn_entities.is_empty() or spawn_points.is_empty():
		return

	var num_to_spawn = randi_range(1, 3)
	var use_random = randf() < random_spawn_chance

	if use_random:
		var shuffled = spawn_points.duplicate()
		shuffled.shuffle()
		var spawned = 0
		for sp in shuffled:
			if spawned >= num_to_spawn:
				break
			if _spawn_entity_at(sp):
				spawned += 1
		if spawned == 0:
			print("No entity spawned. All lanes blocked?")
	else:
		var shuffled_indexes = default_spawn_indexes.duplicate()
		shuffled_indexes.shuffle()
		for i in range(min(num_to_spawn, shuffled_indexes.size())):
			var idx = shuffled_indexes[i]
			if idx >= 0 and idx < spawn_points.size():
				_spawn_entity_at(spawn_points[idx])


func _spawn_entity_at(spawn_point: Marker3D) -> bool:
	var space_state = get_world_3d().direct_space_state
	var origin = spawn_point.global_transform.origin + Vector3(0, 0.5, 0)
	var to = origin + Vector3(0, 0, 1.5)

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = origin
	ray_params.to = to
	ray_params.collide_with_bodies = true
	ray_params.collide_with_areas = false

	var result = space_state.intersect_ray(ray_params)

	if result and result.collider.is_in_group("poofable"):
		print("Blocked by entity at:", result.position)
		return false
		
	var entity_scene = spawn_entities.pick_random()
	var entity = entity_scene.instantiate()
	
	if entity is CharacterBody3D:
		entity.global_transform = spawn_point.global_transform
		var randomized_speed = spawn_speed + randf_range(-spawn_speed_variance, spawn_speed_variance)
		entity.speed = max(randomized_speed, 0.1)
		entity.lane_index = spawn_points.find(spawn_point)
		add_child(entity)
		return true
	else:
		push_error("Spawned entity is not a CharacterBody3D")
		return false

		
func _on_speed_timer():
	spawn_speed += speed_increment
	spawn_interval = max(spawn_interval - 0.1, min_spawn_interval)
	var timer = get_node("SpawnTimer") as Timer
	timer.wait_time = spawn_interval
	
func on_entity_clicked(entity):
	if game_over:
		return
		
	var expected_category = ""
	if lane_category_mapping.has(entity.lane_index):
		expected_category = lane_category_mapping[entity.lane_index]
		
	var category = entity.category if "category" in entity else "unknown"
	var points = point_values.get(category, 0)
	
	if category == expected_category:
		combo_counter = 0
		can_use_slowdown = false
		slowdown_used = false
		$CanvasLayer/SlowdownButton.disabled = true
		lives -= 1
		print("Wrong click! Lives left: %d" % lives)
	else:
		score += points
		combo_counter += 1
		if combo_counter > highest_combo:
			highest_combo = combo_counter
		print("+%d pts (wrong lane). Combo: %d" % [points, combo_counter])
		
		if combo_counter >= slowdown_combo_threshold and not slowdown_used and slowdown_cooldown == null:
			can_use_slowdown = true
			$CanvasLayer/SlowdownButton.disabled = false
			
	show_point_popup(entity.global_position, points, category == expected_category)
	entity.queue_free()
	
	if lives <= 0:
		_end_game()
		
	_update_ui()
	
		
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
	# Update cooldown label if active
	if slowdown_cooldown:
		slowdown_cooldown_time_left = max(0.0, slowdown_cooldown_time_left - delta)
	if $CanvasLayer.has_node("SlowdownCooldownLabel"):
		$CanvasLayer/SlowdownCooldownLabel.text = "Cooldown: %.1f s" % slowdown_cooldown_time_left
	else:
		if $CanvasLayer.has_node("SlowdownCooldownLabel"):
			$CanvasLayer/SlowdownCooldownLabel.text = ""

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for node in $CanvasLayer.get_children():
			if node.has_method("set_mouse_filter"):
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var camera = $Camera3D
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 100

		var ray_params = PhysicsRayQueryParameters3D.new()
		ray_params.from = from
		ray_params.to = to
		ray_params.collide_with_areas = true
		ray_params.collide_with_bodies = true

		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(ray_params)

		if result:
			var clicked = result.collider
			if clicked and clicked.is_in_group("poofable"):
				clicked.call_deferred("go_poof")

	# 👇 Add this block to allow key activation
	if event is InputEventKey and event.pressed and not event.echo:
		if Input.is_action_pressed("slowdown_activate"):
			_try_activate_slowdown()

func _update_ui():
	if $CanvasLayer.has_node("ComboLabel"):
		$CanvasLayer/ComboLabel.text = "Combo: %d" % combo_counter

	if $CanvasLayer.has_node("LivesLabel"):
		$CanvasLayer/LivesLabel.text = "Lives: %d" % lives

	if $CanvasLayer.has_node("ScoreLabel"):
		$CanvasLayer/ScoreLabel.text = "Score: %d" % score
		
	if $CanvasLayer.has_node("ComboMeter"):
		var meter = $CanvasLayer/ComboMeter
		meter.value = combo_counter
		
		# Optional color modulation based on combo streak
		if combo_counter >= 20:
			meter.modulate = Color.RED
		elif combo_counter >= 10:
			meter.modulate = Color.ORANGE
		else:
			meter.modulate = Color.WHITE
			
	
func _end_game():
	game_over = true
	print("\n--- GAME OVER ---")
	print("Final Score: ", combo_counter)
	print("Highest Combo: ", highest_combo)
	
	# Optional: stop spawning
	var spawn_timer = get_node_or_null("SpawnTimer")
	if spawn_timer:
		spawn_timer.stop()
	
	# Optional: Show game over UI
	if $CanvasLayer.has_node("GameOverLabel"):
		$CanvasLayer/GameOverLabel.text = "GAME OVER\nScore: %d\nBest Combo: %d" % [combo_counter, highest_combo]
		$CanvasLayer/GameOverLabel.visible = true
		
func show_point_popup(world_position: Vector3, points: int, is_penalty: bool):
	var popup = Label.new()
	popup.text = "-%d" % points if is_penalty else "+%d" % points
	popup.modulate = Color(1, 0.2, 0.2) if is_penalty else Color(0.3, 1, 0.3)
	popup.add_theme_font_size_override("font_size", 24)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var canvas = $CanvasLayer
	canvas.add_child(popup)

	# Convert 3D world position to 2D screen position
	var screen_position = $Camera3D.unproject_position(world_position)
	popup.position = screen_position

	# Animate: float up and fade out
	var tween = get_tree().create_tween()
	tween.tween_property(popup, "position:y", popup.position.y - 50, 1.0)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.tween_callback(Callable(popup, "queue_free"))
	
func _activate_slowdown():
	is_slowdown_active = true
	print("SLOWDOWN ACTIVATED")
	$CanvasLayer/SlowdownButton.disabled = true

	# Show "HULI KAAA!" popup
	var popup = $CanvasLayer/SlowdownPopupLabel
	popup.text = "HULI KAAA!"
	popup.visible = true
	popup.modulate = Color(1, 0.2, 0.2, 1.0)
	popup.scale = Vector2(1, 1)

	var popup_tween = create_tween()
	popup_tween.tween_property(popup, "modulate:a", 0.0, 1.2)
	popup_tween.tween_property(popup, "scale", Vector2(1.5, 1.5), 1.2)
	popup_tween.tween_callback(Callable(popup, "hide"))

	# Apply speed slowdown to entities
	for child in get_children():
		if child.is_in_group("poofable") and child.has_method("set_speed_multiplier"):
			child.set_speed_multiplier(slowdown_multiplier)

	# Animate screen effect
	var mat = $CanvasLayer/ColorRect.material as ShaderMaterial
	if mat:
		var shader_tween = create_tween()
		shader_tween.tween_property(mat, "shader_parameter/slowdown_intensity", 1.0, 0.3)

	# Start slowdown duration timer
	slowdown_timer = Timer.new()
	slowdown_timer.one_shot = true
	slowdown_timer.wait_time = slowdown_duration
	slowdown_timer.timeout.connect(_deactivate_slowdown)
	add_child(slowdown_timer)
	slowdown_timer.start()
	
func _deactivate_slowdown():
	is_slowdown_active = false
	print("SLOWDOWN ENDED")
	$CanvasLayer/SlowdownButton.disabled = false


	# Reset speed
	for child in get_children():
		if child.is_in_group("poofable") and child.has_method("set_speed_multiplier"):
			child.set_speed_multiplier(1.0)

	# Animate shader back to normal
	var mat = $CanvasLayer/ColorRect.material as ShaderMaterial
	if mat:
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/slowdown_intensity", 0.0, 0.5)

	# Cleanup
	if slowdown_timer:
		slowdown_timer.queue_free()
		slowdown_timer = null
		
func _on_slowdown_button_pressed():
	_try_activate_slowdown()
	
func _try_activate_slowdown():
	if can_use_slowdown and not slowdown_used and not is_slowdown_active:
		_activate_slowdown()
		slowdown_used = true
		can_use_slowdown = false
		$CanvasLayer/SlowdownButton.disabled = true
		_start_slowdown_cooldown()
		
func _start_slowdown_cooldown():
	slowdown_cooldown = Timer.new()
	slowdown_cooldown.one_shot = true
	slowdown_cooldown.wait_time = SLOWDOWN_COOLDOWN_TIME
	slowdown_cooldown_time_left = SLOWDOWN_COOLDOWN_TIME
	slowdown_cooldown.timeout.connect(_on_slowdown_cooldown_finished)
	add_child(slowdown_cooldown)
	slowdown_cooldown.start()
	
func _on_slowdown_cooldown_finished():
	slowdown_cooldown.queue_free()
	slowdown_cooldown = null
	slowdown_used = false  # ✅ allow reuse again

	# Check if player already meets the combo threshold
	if combo_counter >= slowdown_combo_threshold:
		can_use_slowdown = true
		$CanvasLayer/SlowdownButton.disabled = false
