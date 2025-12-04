extends Control

@onready var interact_label: Label = $InteractLabel

@onready var rocks_label: Label = $RocksLabel
@onready var sandstone_label: Label = $SandstoneLabel
@onready var metalscrap_label: Label = $MetalscrapLabel

@onready var alien_dialog: PanelContainer = $AlienDialog
@onready var msg_label: Label = $AlienDialog/VBox/Msg
@onready var upgrade_btn: Button = $AlienDialog/VBox/Buttons/UpgradeBtn
@onready var cancel_btn: Button = $AlienDialog/VBox/Buttons/CancelBtn

@onready var start_screen: Control = $StartScreen
@onready var start_button: Button = $StartScreen/VBoxContainer/StartButton

@onready var story_panel: PanelContainer = $StoryPanel
@onready var story_label: Label = $StoryPanel/VBoxContainer/StoryLabel
@onready var story_next_button: Button = $StoryPanel/VBoxContainer/StoryNextButton

var message_time_left: float = 0.0   # for short temporary messages
var current_alien: Node = null
var current_cost: int = 0
var current_has_enough: bool = false

var current_mode: String = "upgrade"   # "upgrade" or "tower"

# --- Intro story data ---
var intro_lines := [
	"Mission Log 042: Emergency landing complete.",
	"I have crash-landed on an unknown planet.",
	"Most of my systems are damaged. I must gather resources to begin repairs.",
	"I should explore this place, maybe I can build a tower to call home..."
]

var intro_index: int = 0

# --- Typewriter state ---
var is_typing: bool = false
var type_char_index: int = 0
var type_char_delay: float = 0.03  # seconds between characters
var type_accumulator: float = 0.0
var current_intro_text: String = ""


func _ready() -> void:
	start_screen.visible = true
	story_panel.visible = false

	add_to_group("hud")
	interact_label.visible = false
	alien_dialog.visible = false

	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	story_next_button.pressed.connect(_on_story_next_pressed)

	_refresh()
	Inventory.changed.connect(_refresh)


func _process(delta: float) -> void:
	_update_typewriter(delta)

	if alien_dialog.visible:
		return

	if message_time_left > 0.0:
		message_time_left -= delta
		if message_time_left <= 0.0:
			_refresh()
	else:
		_refresh()


func _update_typewriter(delta: float) -> void:
	if not is_typing:
		return

	type_accumulator += delta

	while is_typing and type_accumulator >= type_char_delay:
		type_accumulator -= type_char_delay
		type_char_index += 1

		if type_char_index >= current_intro_text.length():
			story_label.text = current_intro_text
			is_typing = false
			break
		else:
			story_label.text = current_intro_text.substr(0, type_char_index)


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
	rocks_label.text = text


# --- Alien interaction ---
func show_interact_prompt() -> void:
	interact_label.visible = true


func hide_interact_prompt() -> void:
	interact_label.visible = false


# ====== EXISTING DIALOG FOR ALIEN_1 (UPGRADE) ======
func show_alien_dialog(alien: Node, cost: int, has_enough: bool) -> void:
	current_mode = "upgrade"
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


# --- Start screen + intro sequence ---
func _on_start_button_pressed() -> void:
	start_screen.visible = false
	_start_intro_sequence()


func _start_intro_sequence() -> void:
	intro_index = 0
	story_panel.visible = true
	_show_current_intro_line()


func _show_current_intro_line() -> void:
	current_intro_text = intro_lines[intro_index]
	story_label.text = ""                 # clear
	type_char_index = 0
	type_accumulator = 0.0
	is_typing = true

	if intro_index == intro_lines.size() - 1:
		story_next_button.text = "Start mission"
	else:
		story_next_button.text = "Next"


func _on_story_next_pressed() -> void:
	# If text is still typing, first click finishes it instantly
	if is_typing:
		is_typing = false
		story_label.text = current_intro_text
		return

	# Otherwise go to next line
	intro_index += 1

	if intro_index >= intro_lines.size():
		# Intro finished – hide story panel, player can now play
		story_panel.visible = false
	else:
		_show_current_intro_line()
