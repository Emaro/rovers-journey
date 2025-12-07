extends Area3D

@onready var label3d: Label3D = $Label3D

func _ready() -> void:
	label3d.pixel_size = 0.01
	label3d.visible = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	for body in get_overlapping_bodies():
		if _is_rover(body):
			label3d.visible = true
			break

func _on_body_entered(body: Node3D) -> void:
	if _is_rover(body):
		label3d.visible = true

func _on_body_exited(body: Node3D) -> void:
	if _is_rover(body):
		label3d.visible = false

func _is_rover(body: Node) -> bool:
	if body.is_in_group("rover"):
		return true

	var parent := body.get_parent()
	while parent:
		if parent.is_in_group("rover"):
			return true
		parent = parent.get_parent()
	return false
