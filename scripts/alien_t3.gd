extends Area3D

@export var required_crystal: int = 3
@export var required_metalscrap: int = 5
@export var required_rocks: int = 3
@export var tower_part: Node3D

var rover_near := false
var rover_body: Node = null
var part_built := false

func _ready() -> void:
	monitoring = false
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
	if rover_body:
		look_at(rover_body.global_position, Vector3.UP, true)

func _talk() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("show_alien_t3_dialog"):
		return

	var available_crystal := Inventory.get_count("crystal")
	var available_metalscrap := Inventory.get_count("metalscrap")
	var available_rocks := Inventory.get_count("rock")

	var has_enough := (
		available_crystal >= required_crystal
		and available_metalscrap >= required_metalscrap
		and available_rocks >= required_rocks
	)

	hud.show_alien_t3_dialog(
		self,
		has_enough,
		required_crystal,
		required_metalscrap,
		required_rocks,
		available_crystal,
		available_metalscrap,
		available_rocks,
		part_built
	)

func perform_build() -> void:
	if Inventory.get_count("crystal") < required_crystal \
		or Inventory.get_count("metalscrap") < required_metalscrap \
		or Inventory.get_count("rock") < required_rocks:
		return

	Inventory.add_item("crystal", -required_crystal)
	Inventory.add_item("metalscrap", -required_metalscrap)
	Inventory.add_item("rock", -required_rocks)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_resource_labels"):
		hud.update_resource_labels()

	if tower_part:
		tower_part.visible = true

	if hud and hud.has_method("on_tower_completed"):
		hud.on_tower_completed()

	part_built = true
