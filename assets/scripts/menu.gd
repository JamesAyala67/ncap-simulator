extends Node3D

@onready var start_button = $MenuCanvas/Panel/StartButton
@onready var quit_button = $MenuCanvas/Panel/ExitButton
@onready var menu_ost = $MenuOST

@export_range(0, 100) var menu_volume_percent := 100  # Set in Inspector

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Set bus volume from exported value
	var bus_index = AudioServer.get_bus_index("MenuOst")
	var volume_db = lerp(-30.0, 0.0, menu_volume_percent / 100.0)
	AudioServer.set_bus_volume_db(bus_index, volume_db)

	menu_ost.play()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_pressed():
	get_tree().quit()
