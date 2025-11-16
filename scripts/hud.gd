extends Control

@onready var mineral_label: Label = $MineralLabel
@onready var interact_label: Label = $InteractLabel

func _ready() -> void:
	add_to_group("hud")              # allow alien to find us
	interact_label.visible = false   # hide [E] prompt at start
	_refresh()
	Inventory.changed.connect(_refresh)

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	mineral_label.text = "Minerals: %d" % Inventory.get_count("mineral")

# --- Called by Alien ---

func show_interact_prompt() -> void:
	interact_label.visible = true

func hide_interact_prompt() -> void:
	interact_label.visible = false

func show_message(text: String) -> void:
	mineral_label.text = text
