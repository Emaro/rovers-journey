extends Area3D

@export var cost_amount := 3

var rover_near := false
var rover_body: Node = null

func _ready() -> void:
	monitoring = true
	print("Alien ready (interaction v3)")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _is_rover_body(body: Node) -> bool:
	if body.name == "Rover":
		return true
	var parent := body.get_parent()
	return parent != null and parent.name == "Rover"

func _get_rover_root(body: Node) -> Node:
	if body.name == "Rover":
		return body
	return body.get_parent()

func _on_body_entered(body: Node) -> void:
	if _is_rover_body(body):
		rover_near = true
		rover_body = _get_rover_root(body)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_interact_prompt"):
			hud.show_interact_prompt()

func _on_body_exited(body: Node) -> void:
	if _is_rover_body(body):
		rover_near = false
		rover_body = null
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("hide_interact_prompt"):
			hud.hide_interact_prompt()

func _process(_delta: float) -> void:
	if rover_near and Input.is_action_just_pressed("interact"):
		_talk()

func _talk() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("show_alien_dialog"):
		return

	var minerals := Inventory.get_count("mineral")
	var has_enough := minerals >= cost_amount
	hud.show_alien_dialog(self, cost_amount, has_enough)

func perform_upgrade() -> void:

	if Inventory.get_count("mineral") < cost_amount:
		print("Alien: not enough minerals at upgrade time.")
		return

	Inventory.add_item("mineral", -cost_amount)

	if rover_body != null:
		if rover_body is RaycastCar:
			var car := rover_body as RaycastCar
			car.max_speed *= 1.3
			car.acceleration *= 1.3
			print("Alien: upgraded rover. New max_speed =", car.max_speed, "new acceleration =", car.acceleration)
		else:
			if rover_body.has_variable("max_speed"):
				rover_body.max_speed *= 1.3
			if rover_body.has_variable("acceleration"):
				rover_body.acceleration *= 1.3
			print("Alien: upgraded generic rover body.")
	else:
		print("Alien: no rover_body set during upgrade.")

	queue_free()
