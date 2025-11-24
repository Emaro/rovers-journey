extends Area3D

@export var cost_amount := 3
@export var cost_item_id := "rock"   # which resource the alien wants
@export var next_alien: Node3D       # NEW: assign AlienT1 here in the editor

var rover_near := false
var rover_body: Node = null
var disappear := false

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

	var available := Inventory.get_count(cost_item_id)
	var has_enough := available >= cost_amount
	hud.show_alien_dialog(self, cost_amount, has_enough)
	$AnimationPlayer.play("alien_interaction")


func perform_upgrade() -> void:
	if Inventory.get_count(cost_item_id) < cost_amount:
		print("Alien: not enough %s at upgrade time." % cost_item_id)
		return

	# pay the cost
	Inventory.add_item(cost_item_id, -cost_amount)

	# actual rover upgrade logic
	if rover_body != null:
		if rover_body is RaycastCar:
			var car := rover_body as RaycastCar
			car.max_speed *= 2
			car.acceleration *= 2
			print("Alien: upgraded rover. New max_speed = %s new acceleration = %s"
				% [car.max_speed, car.acceleration])
		else:
			if rover_body.has_variable("max_speed"):
				rover_body.max_speed *= 1.3
			if rover_body.has_variable("acceleration"):
				rover_body.acceleration *= 1.3
			print("Alien: upgraded generic rover body.")
	else:
		print("Alien: no rover_body set during upgrade.")

	# ---------------------
	# NEW: Activate next alien (AlienT1)
	# ---------------------
	if next_alien:
		next_alien.visible = true
		if next_alien is Area3D:
			next_alien.monitoring = true

	disappear = true
	$AnimationPlayer.play("alien_interaction")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if disappear:
		queue_free()
