extends Control

@onready var mineral_label: Label = $MineralLabel

# This will be called by the Alien when it wants to show a message
func show_message(text: String) -> void:
	mineral_label.text = text

func _process(_delta: float) -> void:
	# Keep label always showing the mineral count
	mineral_label.text = "Minerals: %d" % Inventory.get_count("mineral")
