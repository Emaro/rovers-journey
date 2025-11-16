extends Control

@onready var mineral_label: Label = $MineralLabel
@onready var interact_label: Label = $InteractLabel

@onready var alien_dialog: PanelContainer = $AlienDialog
@onready var msg_label: Label = $AlienDialog/VBox/Msg
@onready var upgrade_btn: Button = $AlienDialog/VBox/Buttons/UpgradeBtn
@onready var cancel_btn: Button = $AlienDialog/VBox/Buttons/CancelBtn

var message_time_left: float = 0.0   # for short corner messages
var current_alien: Node = null
var current_cost: int = 0
var current_has_enough: bool = false

func _ready() -> void:
	add_to_group("hud")
	interact_label.visible = false
	alien_dialog.visible = false

	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

	_refresh()
	Inventory.changed.connect(_refresh)

func _process(delta: float) -> void:
	# If the dialog is open, don't override anything
	if alien_dialog.visible:
		return

	# Otherwise handle short messages + mineral counter
	if message_time_left > 0.0:
		message_time_left -= delta
		if message_time_left <= 0.0:
			_refresh()
	else:
		_refresh()

func _refresh() -> void:
	mineral_label.text = "Minerals: %d" % Inventory.get_count("mineral")

# --- Small temporary messages, if you need them somewhere else ---
func show_message(text: String, duration: float = 3.0) -> void:
	message_time_left = duration
	mineral_label.text = text

# --- Alien interaction ---

func show_interact_prompt() -> void:
	interact_label.visible = true

func hide_interact_prompt() -> void:
	interact_label.visible = false

func show_alien_dialog(alien: Node, cost: int, has_enough: bool) -> void:
	current_alien = alien
	current_cost = cost
	current_has_enough = has_enough
	message_time_left = 0.0  # stop any old message

	interact_label.visible = false        # hide [E] while dialog is open
	alien_dialog.visible = true

	if has_enough:
		msg_label.text = "I like your rocks! Give me %d and I'll upgrade your drivetrain." % cost
		upgrade_btn.disabled = false
		upgrade_btn.text = "Upgrade"
		cancel_btn.text = "Cancel"
	else:
		msg_label.text = "Oh no, not enough rocks. You need %d." % cost
		upgrade_btn.disabled = true
		upgrade_btn.text = "Upgrade"
		cancel_btn.text = "Close"

func _on_upgrade_pressed() -> void:
	if not current_has_enough or current_alien == null:
		return

	if current_alien.has_method("perform_upgrade"):
		current_alien.perform_upgrade()

	alien_dialog.visible = false
	_refresh()               # update minerals in corner
	interact_label.visible = true   # show [E] again if still near

func _on_cancel_pressed() -> void:
	alien_dialog.visible = false
	_refresh()
	interact_label.visible = true   # show [E] again if still near
