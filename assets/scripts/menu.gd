extends Node3D

@onready var start_button = $MenuCanvas/Panel/StartButton
@onready var quit_button = $MenuCanvas/Panel/ExitButton
@onready var menu_ost = $MenuOST

@export_range(0, 100) var menu_volume_percent := 100  # Editable in Inspector

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_update_volume()
	menu_ost.play()

func _process(_delta):
	# Check for volume change every frame (if edited live in the Inspector)
	_update_volume()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _update_volume():
	# Map 0–100% to -30dB to 0dB
	menu_ost.volume_db = lerp(-30.0, 0.0, menu_volume_percent / 100.0)
