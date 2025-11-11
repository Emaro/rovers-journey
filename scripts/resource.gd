extends Area3D

@export var item_id := "mineral"
@export var amount := 1
var picked := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if picked:
		return
	if body.name == "Rover" or body is CharacterBody3D:
		Inventory.add_item(item_id, amount)
		picked = true
		queue_free()
