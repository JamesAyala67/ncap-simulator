extends Node

@export_range(0.0, 1.0, 0.01)
var volume_violators: float = 1.0
@export_range(0.0, 1.0, 0.01)
var volume_non_violators: float = 1.0
@export_range(0.0, 1.0, 0.01)
var volume_normal: float = 1.0

var cooldown_end_time := {
	"violators": 0.0,
	"non_violators": 0.0,
	"normal": 0.0
}

var voices := {
	"violators": [],
	"non_violators": [],
	"normal": []
}

var extra_cooldown_time := {
	"violators": 1.5,
	"non_violators": 1.0,
	"normal": 2.0
}

func _ready():
	_load_voices()

func _load_voices():
	var base_path = "res://voices/"
	for category in voices.keys():
		var dir = DirAccess.open(base_path + category)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					var ext = file_name.get_extension().to_lower()
					if ext in ["wav", "ogg"]:
						var full_path = base_path + category + "/" + file_name
						var stream = load(full_path)
						if stream is AudioStream:
							voices[category].append(stream)
				file_name = dir.get_next()

func _can_play(category: String) -> bool:
	return Time.get_ticks_msec() / 1000.0 >= cooldown_end_time[category]

func _play_random(category: String, volume: float):
	if not _can_play(category):
		return
	var list = voices[category]
	if list.size() == 0:
		return
	var stream: AudioStream = list.pick_random()
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	player.bus = "Master"
	add_child(player)
	player.play()

	# Cooldown logic using end time
	var extra_cooldown: float = extra_cooldown_time.get(category, 1.0)
	var total_cooldown: float = stream.get_length() + extra_cooldown
	cooldown_end_time[category] = Time.get_ticks_msec() / 1000.0 + total_cooldown

	# Optional: Timer for cleanup
	var cooldown_timer := Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = total_cooldown
	add_child(cooldown_timer)
	cooldown_timer.timeout.connect(func():
		cooldown_timer.queue_free()
	)
	cooldown_timer.start()

	player.finished.connect(player.queue_free)

func play_violator_voice():
	_play_random("violators", volume_violators)

func play_non_violator_voice():
	_play_random("non_violators", volume_non_violators)

func play_normal_voice():
	_play_random("normal", volume_normal)

func is_any_active() -> bool:
	for category in cooldown_end_time.keys():
		if not _can_play(category):
			return true
	return false
