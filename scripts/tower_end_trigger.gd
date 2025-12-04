extends Area3D

var activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if activated:
		return

	var rover := _get_rover_root(body)
	if rover == null:
		return

	activated = true
	monitoring = false  # stop further triggers

	# 1) disable rover input
	if rover.has_method("set_input_enabled"):
		rover.set_input_enabled(false)

	# 2) start the outro story on the HUD (we’ll hook this up next)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("start_outro_sequence"):
		hud.start_outro_sequence()


func _get_rover_root(body: Node) -> Node:
	# Change "Rover" if your rover root node has a different name
	if body.name == "Rover":
		return body

	var parent := body.get_parent()
	while parent != null:
		if parent.name == "Rover":
			return parent
		parent = parent.get_parent()

	return null
