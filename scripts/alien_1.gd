extends Area3D

@export var required_metalscrap: int = 5
@export var required_rocks: int = 2
@export var next_alien: Node3D   # Assign Alien_T1 (mountain alien) in the editor

var rover_near := false
var rover_body: Node3D = null
var drivetrain_upgraded: bool = false


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("Alien_1 ready at:", global_position)


func _is_rover(body: Node) -> bool:
	if body.is_in_group("rover"):
		return true

	var parent := body.get_parent()
	while parent:
		if parent.is_in_group("rover"):
			return true
		parent = parent.get_parent()

	return false


func _get_rover_root(body: Node3D) -> Node3D:
	if body.is_in_group("rover"):
		return body

	var parent := body.get_parent()
	while parent and not parent.is_in_group("rover"):
		parent = parent.get_parent()

	return parent


func _on_body_entered(body: Node3D) -> void:
	if _is_rover(body):
		rover_near = true
		rover_body = _get_rover_root(body)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_interact_prompt()


func _on_body_exited(body: Node3D) -> void:
	if _is_rover(body):
		rover_near = false
		rover_body = null
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.hide_interact_prompt()


func _process(_delta: float) -> void:
	if rover_near and Input.is_action_just_pressed("interact"):
		_talk()
	if rover_body:
		look_at(rover_body.global_position, Vector3.UP, true)


func _talk() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("show_alien1_dialog"):
		print("HUD missing or show_alien1_dialog missing!")
		return

	var available_metalscrap := Inventory.get_count("metalscrap")
	var available_rocks := Inventory.get_count("rock")

	var has_enough := (
		available_metalscrap >= required_metalscrap
		and available_rocks >= required_rocks
	)

	hud.show_alien1_dialog(
		self,
		has_enough,
		required_metalscrap,
		required_rocks,
		available_metalscrap,
		available_rocks,
		drivetrain_upgraded
	)


func perform_upgrade() -> void:
	if drivetrain_upgraded:
		print("Alien_1: Drivetrain already upgraded.")
		return

	var have_metalscrap := Inventory.get_count("metalscrap")
	var have_rocks := Inventory.get_count("rock")

	if have_metalscrap < required_metalscrap or have_rocks < required_rocks:
		print("Alien_1: Not enough resources at upgrade time.")
		return

	Inventory.add_item("metalscrap", -required_metalscrap)
	Inventory.add_item("rock", -required_rocks)

	if rover_body and rover_body is RaycastCar:
		var car := rover_body as RaycastCar
		car.max_speed *= 2.0
		car.acceleration *= 2.0
		print("Alien_1: Upgraded rover drivetrain.")
	else:
		print("Alien_1: Rover body missing or incompatible.")

	drivetrain_upgraded = true

	if next_alien:
		next_alien.visible = true
		if next_alien is Area3D:
			next_alien.monitoring = true

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_alien1_dialog"):
		var new_metals := Inventory.get_count("metalscrap")
		var new_rocks := Inventory.get_count("rock")
		hud.show_alien1_dialog(
			self,
			true,
			required_metalscrap,
			required_rocks,
			new_metals,
			new_rocks,
			true
		)
