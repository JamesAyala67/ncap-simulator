extends CanvasLayer

@onready var panel = $Panel
@onready var tutorial_image = $TutorialImage
@onready var back_button = $BackButton
@onready var next_button = $NextButton
@onready var previous_button = $PreviousButton
@onready var tutorial_button = $Panel/TutorialButton
@onready var tutorial_overlay = $TutorialOverlay

@onready var credit_button = $Panel/CreditButton
@onready var credit_overlay = $CreditOverlay
@onready var credit_container = $CreditOverlay/CreditScrollContainer
@onready var credit_image1 = $CreditOverlay/CreditScrollContainer/CreditsImage1
@onready var credit_image2 = $CreditOverlay/CreditScrollContainer/CreditsImage2
@onready var credit_exit_button = $CreditOverlay/ExitCreditButton


var credit_tween: Tween

var tutorial_images = [
	preload("res://assets/images/tutorial1.png"),
	preload("res://assets/images/tutorial2.png")
]
var current_index = 0

func _ready():
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	previous_button.pressed.connect(_on_previous_button_pressed)
	credit_button.pressed.connect(_on_credit_button_pressed)
	credit_exit_button.pressed.connect(_on_credit_exit_button_pressed)

func _on_tutorial_button_pressed():
	current_index = 0
	tutorial_image.texture = tutorial_images[current_index]

	# Reset modulate for both
	tutorial_image.modulate = Color(1, 1, 1, 0)
	tutorial_overlay.modulate = Color(0, 0, 0, 0)

	# Make visible
	tutorial_image.visible = true
	tutorial_overlay.visible = true
	back_button.visible = true
	next_button.visible = true
	previous_button.visible = true

	# Fade both in
	fade_in_image()
	update_buttons()

	
func _on_back_button_pressed():
	var tween = get_tree().create_tween()
	tween.tween_property(tutorial_image, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.parallel().tween_property(tutorial_overlay, "modulate", Color(0, 0, 0, 0), 0.3)

	await tween.finished

	tutorial_image.visible = false
	tutorial_overlay.visible = false
	back_button.visible = false
	next_button.visible = false
	previous_button.visible = false


	
func _on_next_button_pressed():
	current_index += 1
	if current_index < tutorial_images.size():
		tutorial_image.texture = tutorial_images[current_index]
		fade_in_image()
	else:
		_on_back_button_pressed()
	update_buttons()
	
func _on_previous_button_pressed():
	current_index -= 1
	if current_index < 0:
		current_index = 0
	else:
		tutorial_image.texture = tutorial_images[current_index]
		fade_in_image()
	update_buttons()
	
func update_buttons():
	previous_button.disabled = current_index == 0
	next_button.disabled = current_index == tutorial_images.size() - 1
	
func fade_in_image():
	var tween = get_tree().create_tween()
	tween.tween_property(tutorial_image, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.parallel().tween_property(tutorial_overlay, "modulate", Color(0, 0, 0, 0.7), 0.5)

func _on_credit_button_pressed():
	# Hide all tutorial/menu UI
	panel.visible = false
	tutorial_image.visible = false
	back_button.visible = false
	next_button.visible = false
	previous_button.visible = false
	tutorial_overlay.visible = false

	# Show credits overlay
	credit_overlay.visible = true
	credit_container.position.y = credit_overlay.size.y

	var total_height = credit_image1.texture.get_height() + credit_image2.texture.get_height()

	credit_tween = get_tree().create_tween()
	credit_tween.tween_property(
		credit_container,
		"position:y",
		-total_height,
		20.0
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
func _on_credit_exit_button_pressed():
	if credit_tween:
		credit_tween.kill()

	credit_overlay.visible = false
	panel.visible = true
