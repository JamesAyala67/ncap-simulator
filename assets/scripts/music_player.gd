extends Node

@onready var music_player = $MusicPlayer
var fade_in_time := 5.0 # seconds
var target_volume := 0.0 # dB (0 is full volume)
var start_volume := -80.0 # minimum volume in dB

func _ready():
	music_player.volume_db = start_volume
	music_player.play()
	fade_in_music()

func fade_in_music():
	var tween := create_tween()
	tween.tween_property(
		music_player, "volume_db", target_volume, fade_in_time
	)
