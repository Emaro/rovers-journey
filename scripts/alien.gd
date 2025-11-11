extends Area3D

@export var cost_amount := 3
var rover_near := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Rover":
		rover_near = true

func _on_body_exited(body):
	if body.name == "Rover":
		rover_near = false

func _process(_delta):
	if rover_near and Input.is_action_just_pressed("interact"):
		_talk_to_player()

func _talk_to_player():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		return

	var minerals = Inventory.get_count("mineral")

	if minerals >= cost_amount:
		hud.show_message("I like your rocks! Press [U] to upgrade drivetrain.")
		# Wait for player to press U
		if Input.is_action_just_pressed("ui_upgrade"):
			_perform_upgrade()
	else:
		hud.show_message("Oh no, not enough rocks!")

func _perform_upgrade():
	Inventory.add_item("mineral", -cost_amount)
	var rover = get_tree().get_root().find_child("Rover", true, false)
	if rover:
		rover.move_speed *= 1.5
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_message("Upgrade complete! Your rover is faster now.")
	queue_free()  # Alien disappears
