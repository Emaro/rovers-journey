extends Area3D

@export var cost_amount := 3

var rover_near := false
var rover_body: Node = null

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	var parent := body.get_parent()
	if parent != null and parent.name == "Rover":
		rover_near = true
		rover_body = parent

		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_interact_prompt"):
			hud.show_interact_prompt()

func _on_body_exited(body: Node) -> void:
	var parent := body.get_parent()
	if parent == rover_body:
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
	if hud == null or not hud.has_method("show_message"):
		return

	var minerals := Inventory.get_count("mineral")
	if minerals >= cost_amount:
		hud.show_message("I like your rocks! Give me %d and I'll upgrade your drivetrain (buttons later)." % cost_amount)
	else:
		hud.show_message("Oh no, not enough rocks. Need %d." % cost_amount)
