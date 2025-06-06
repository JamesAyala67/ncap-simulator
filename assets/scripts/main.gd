extends Node3D

@export var spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.3  # Prevents it from getting too fast
@export var spawn_speed: float = 5.0
@export var speed_increment: float = 1.0
@export var spawn_speed_variance: float = 2.0  # Speed +/- variance
@export var spawn_entities: Array[PackedScene]  # Drag scenes here
@export var spawn_points_group: NodePath = "SpawnPoints"  # Path to your spawn points node
@export var default_spawn_indexes: Array[int] = [0, 1]  # Specific spawn point indexes
@export var random_spawn_chance: float = 0.35  # 35% of the time use random spawn

var spawn_points: Array[Marker3D] = []

func _ready():
	randomize()
	var group_node = get_node_or_null(spawn_points_group)
	if group_node:
		for child in group_node.get_children():
			if child is Marker3D:
				spawn_points.append(child as Marker3D)
	_start_spawn_timer()
	_start_speed_timer()

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
	timer.wait_time = 5.0  # How often speed & rate increases
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
		# Spawn at random (non-repeating) markers
		var shuffled = spawn_points.duplicate()
		shuffled.shuffle()
		for i in range(min(num_to_spawn, shuffled.size())):
			_spawn_entity_at(shuffled[i])
	else:
		# Spawn at specific default markers
		for i in range(min(num_to_spawn, default_spawn_indexes.size())):
			var idx = default_spawn_indexes[i]
			if idx >= 0 and idx < spawn_points.size():
				_spawn_entity_at(spawn_points[idx])

func _spawn_entity_at(spawn_point: Marker3D):
	var entity_scene = spawn_entities.pick_random()
	var entity = entity_scene.instantiate()
	entity.global_transform = spawn_point.global_transform
	var Violator = randi() % 2 == 0
	print(Violator)

	var randomized_speed = spawn_speed + randf_range(-spawn_speed_variance, spawn_speed_variance)
	entity.set("speed", max(randomized_speed, 0.1))
	entity.set_meta("violator", Violator)
	print(entity)
	print(entity.speed)
	print(entity)
	add_child(entity)
	#entity.is_violator = Violator
	#print(entity.is_violator)

func _on_speed_timer():
	# Increase base speed
	spawn_speed += speed_increment
	
	# Decrease spawn interval over time
	spawn_interval = max(spawn_interval - 0.1, min_spawn_interval)

	# Update the timer with new interval
	var timer = get_node("SpawnTimer") as Timer
	timer.wait_time = spawn_interval
