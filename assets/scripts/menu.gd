extends Node3D

@onready var start_button = $MenuCanvas/Panel/StartButton
@onready var quit_button = $MenuCanvas/Panel/ExitButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_pressed():
	get_tree().quit()
