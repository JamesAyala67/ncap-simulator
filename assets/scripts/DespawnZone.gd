extends Area3D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if not body.is_in_group("poofable") or not body.has_method("get_lane_index"):
		return  # Ignore unrelated bodies

	var lane_index = body.get_lane_index()
	var category = body.category if "category" in body else "unknown"

	var main_node = get_tree().root.get_node("main")  # Replace with actual node path
	if not main_node:
		return

	var expected_lanes = main_node.get_expected_lanes_for_category(category)

	if expected_lanes.has(lane_index):
		body.queue_free()
	else:
		body.queue_free()
		main_node._on_wrong_lane_entity_exit(body)

	# Reset airplane rarity state if needed
	if "category" in body and body.category == "airplane":
		main_node.is_special_active = false  # Adjust if variable is named differently
