extends Node

var items := {}
signal changed

func add_item(id: String, count: int = 1) -> void:
	items[id] = items.get(id, 0) + count
	emit_signal("changed")

func get_count(id: String) -> int:
	return items.get(id, 0)

func reset() -> void:
	items.clear()
	emit_signal("changed")
