extends Control

@onready var mineral_label: Label = $MineralLabel

func _ready() -> void:
	Inventory.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	mineral_label.text = "Mineral: %d" % Inventory.get_count("mineral")
