extends Control

@onready var interact_label: Label = $InteractLabel

@onready var rocks_label: Label = $RocksLabel
@onready var sandstone_label: Label = $SandstoneLabel
@onready var metalscrap_label: Label = $MetalscrapLabel

@onready var alien_dialog: PanelContainer = $AlienDialog
@onready var msg_label: Label = $AlienDialog/VBox/Msg
@onready var upgrade_btn: Button = $AlienDialog/VBox/Buttons/UpgradeBtn
@onready var cancel_btn: Button = $AlienDialog/VBox/Buttons/CancelBtn

var message_time_left: float = 0.0   # for short temporary messages
var current_alien: Node = null
var current_cost: int = 0
var current_has_enough: bool = false

var current_mode: String = "upgrade"   # "upgrade" or "tower"   <<< NEW

func _ready() -> void:
	add_to_group("hud")
	interact_label.visible = false
	alien_dialog.visible = false

	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

	_refresh()
	Inventory.changed.connect(_refresh)

func _process(delta: float) -> void:
	if alien_dialog.visible:
		return

	if message_time_left > 0.0:
		message_time_left -= delta
		if message_time_left <= 0.0:
			_refresh()
	else:
		_refresh()

func _refresh() -> void:
	var rocks := Inventory.get_count("rock")
	var sandstone := Inventory.get_count("sandstone")
	var metalscrap := Inventory.get_count("metalscrap")

	rocks_label.text = "Rocks: %d" % rocks
	sandstone_label.text = "Sandstones: %d" % sandstone
	metalscrap_label.text = "Metalscraps: %d" % metalscrap

# --- Small temporary messages ---
func show_message(text: String, duration: float = 3.0) -> void:
	message_time_left = duration
	# Show messages in the rocks label for now
	rocks_label.text = text

# --- Alien interaction ---
func show_interact_prompt() -> void:
	interact_label.visible = true

func hide_interact_prompt() -> void:
	interact_label.visible = false

# ====== EXISTING DIALOG FOR ALIEN_1 (UPGRADE) ======
func show_alien_dialog(alien: Node, cost: int, has_enough: bool) -> void:
	current_mode = "upgrade"                   # <<< NEW
	current_alien = alien
	current_cost = cost
	current_has_enough = has_enough
	message_time_left = 0.0

	interact_label.visible = false
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

# ====== NEW DIALOG FOR ALIEN_T1 (TOWER BUILD) ======
func show_alien_dialog_tower(
	alien: Node,
	part_name: String,
	res1_label: String,
	required_res1: int,
	available_res1: int,
	res2_label: String,
	required_res2: int,
	available_res2: int,
	has_enough: bool,
	res3_label: String = "",
	required_res3: int = 0,
	available_res3: int = 0
) -> void:
	current_mode = "tower"
	current_alien = alien
	current_has_enough = has_enough
	message_time_left = 0.0

	interact_label.visible = false
	alien_dialog.visible = true

	var msg := "To build the %s tower part I need:\n" % part_name
	msg += "- %d %s (you have %d)\n" % [required_res1, res1_label, available_res1]
	msg += "- %d %s (you have %d)" % [required_res2, res2_label, available_res2]

	if res3_label != "" and required_res3 > 0:
		msg += "\n- %d %s (you have %d)" % [required_res3, res3_label, available_res3]

	if has_enough:
		msg_label.text = msg
		upgrade_btn.disabled = false
		upgrade_btn.text = "Build"
		cancel_btn.text = "Cancel"
	else:
		msg_label.text = msg + "\n\nCome back when you have enough."
		upgrade_btn.disabled = true
		upgrade_btn.text = "Build"
		cancel_btn.text = "Close"



func _on_upgrade_pressed() -> void:
	if not current_has_enough or current_alien == null:
		return

	if current_mode == "upgrade":
		if current_alien.has_method("perform_upgrade"):
			current_alien.perform_upgrade()
	elif current_mode == "tower":
		if current_alien.has_method("perform_build"):
			current_alien.perform_build()

	alien_dialog.visible = false
	_refresh()
	interact_label.visible = true

func _on_cancel_pressed() -> void:
	alien_dialog.visible = false
	_refresh()
	interact_label.visible = true
