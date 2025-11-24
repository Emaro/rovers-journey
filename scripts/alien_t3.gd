extends Area3D

@export var required_sandstone: int = 1
@export var required_rocks: int = 1
@export var required_metalscrap: int = 1
@export var tower_part: Node3D

var rover_near := false
var rover_body: Node = null

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


func _talk() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("show_alien_dialog_tower"):
		return

	var available_sandstone := Inventory.get_count("sandstone")
	var available_rocks := Inventory.get_count("rock")
	var available_metalscrap := Inventory.get_count("metalscrap")

	var has_enough := (
		available_sandstone >= required_sandstone
		and available_rocks >= required_rocks
		and available_metalscrap >= required_metalscrap
	)

	hud.show_alien_dialog_tower(
		self,
		"third",
		"sandstones",
		required_sandstone,
		available_sandstone,
		"rocks",
		required_rocks,
		available_rocks,
		has_enough,
		"metalscraps",
		required_metalscrap,
		available_metalscrap
	)


func perform_build() -> void:
	if Inventory.get_count("sandstone") < required_sandstone \
		or Inventory.get_count("rock") < required_rocks \
		or Inventory.get_count("metalscrap") < required_metalscrap:
		print("AlienT3: not enough resources at build time.")
		return

	Inventory.add_item("sandstone", -required_sandstone)
	Inventory.add_item("rock", -required_rocks)
	Inventory.add_item("metalscrap", -required_metalscrap)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_resource_labels"):
		hud.update_resource_labels()

	if tower_part:
		tower_part.visible = true
		print("AlienT3: Tower part 3 constructed.")
		if hud and hud.has_method("show_message"):
			hud.show_message("Communication tower completed!", 4.0)

	hide()
	queue_free()
