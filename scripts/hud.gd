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

# Story / intro+outro UI
@onready var story_panel: PanelContainer = $StoryPanel
@onready var story_label: Label = $StoryPanel/VBoxContainer/StoryLabel
@onready var story_next_button: Button = $StoryPanel/VBoxContainer/StoryNextButton
@onready var choice_buttons: HBoxContainer = $StoryPanel/VBoxContainer/ChoiceButtons
@onready var call_home_button: Button = $StoryPanel/VBoxContainer/ChoiceButtons/CallHomeButton
@onready var stay_here_button: Button = $StoryPanel/VBoxContainer/ChoiceButtons/StayHereButton

# End screen
@onready var end_screen: Control = $EndScreen
@onready var end_label: Label = $EndScreen/VBoxContainer/EndLabel

var message_time_left: float = 0.0   # for short temporary messages
var current_alien: Node = null
var current_cost: int = 0
var current_has_enough: bool = false

var current_mode: String = "upgrade"   # "upgrade" or "tower"

# --- Intro story data (you can tweak text here) ---
var story_lines_intro := [
	"Mission Log 042: Emergency landing complete.",
	"I have crash-landed on an unknown planet.",
	"Most of my systems are damaged. I must gather resources to begin repairs.",
	"I should explore this place, seek help from the locals, and rebuild a tower to signal home."
]

# --- Outro story data ---
var story_lines_outro := [
	"Mission Log 099: Final tower segment complete.",
	"My connection back home is within reach.",
	"Yet this planet no longer feels unknown. Its stones, its skies, its people...",
	"This place could be my new home.",
	"I must decide: Do I call home, or stay here?"
]

var story_index: int = 0
var is_in_outro: bool = false

# --- Typewriter state (shared by intro & outro) ---
var is_typing: bool = false
var type_char_index: int = 0
var type_char_delay: float = 0.03  # seconds between characters
var type_accumulator: float = 0.0
var current_story_text: String = ""


func _ready() -> void:
	start_screen.visible = true

	story_panel.visible = false
	choice_buttons.visible = false

	end_screen.visible = false

	add_to_group("hud")
	interact_label.visible = false
	alien_dialog.visible = false

	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	start_button.pressed.connect(_on_start_button_pressed)

	story_next_button.pressed.connect(_on_story_next_pressed)
	call_home_button.pressed.connect(_on_call_home_pressed)
	stay_here_button.pressed.connect(_on_stay_here_pressed)

	# Listen for nodes being added so we can catch the rover even if it spawns later
	get_tree().node_added.connect(_on_node_added)

	# Try to disable rover right away (if it's already in the scene)
	_set_rover_input(false)

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


# ---------- TYPEWRITER ----------

func _update_typewriter(delta: float) -> void:
	if not is_typing:
		return

	type_accumulator += delta

	while is_typing and type_accumulator >= type_char_delay:
		type_accumulator -= type_char_delay
		type_char_index += 1

		if type_char_index >= current_story_text.length():
			story_label.text = current_story_text
			is_typing = false
			break
		else:
			story_label.text = current_story_text.substr(0, type_char_index)


func _start_typewriter(text: String) -> void:
	current_story_text = text
	story_label.text = ""
	type_char_index = 0
	type_accumulator = 0.0
	is_typing = true


# ---------- HUD REFRESH / MESSAGES ----------

func _refresh() -> void:
	var rocks := Inventory.get_count("rock")
	var sandstone := Inventory.get_count("sandstone")
	var metalscrap := Inventory.get_count("metalscrap")

	rocks_label.text = "Rocks: %d" % rocks
	sandstone_label.text = "Sandstones: %d" % sandstone
	metalscrap_label.text = "Metalscraps: %d" % metalscrap


func show_message(text: String, duration: float = 3.0) -> void:
	message_time_left = duration
	rocks_label.text = text


func show_interact_prompt() -> void:
	interact_label.visible = true


func hide_interact_prompt() -> void:
	interact_label.visible = false


# ---------- ALIEN DIALOGS ----------

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


# ---------- INTRO SEQUENCE ----------

func _on_start_button_pressed() -> void:
	start_screen.visible = false
	_set_rover_input(false)  # still blocked during intro
	_start_intro_sequence()


func _start_intro_sequence() -> void:
	is_in_outro = false
	story_index = 0
	story_panel.visible = true
	story_next_button.visible = true
	choice_buttons.visible = false
	_show_current_intro_line()


func _show_current_intro_line() -> void:
	_start_typewriter(story_lines_intro[story_index])

	if story_index == story_lines_intro.size() - 1:
		story_next_button.text = "Start mission"
	else:
		story_next_button.text = "Next"


# ---------- OUTRO SEQUENCE (PUBLIC ENTRY) ----------

func start_outro_sequence() -> void:
	is_in_outro = true
	story_index = 0
	story_panel.visible = true
	story_next_button.visible = true
	choice_buttons.visible = false
	_show_current_outro_line()


func _show_current_outro_line() -> void:
	_start_typewriter(story_lines_outro[story_index])

	if story_index == story_lines_outro.size() - 1:
		story_next_button.text = "Continue"
	else:
		story_next_button.text = "Next"


# ---------- STORY NEXT BUTTON (INTRO OR OUTRO) ----------

func _on_story_next_pressed() -> void:
	# If text is still typing, first click finishes it
	if is_typing:
		is_typing = false
		story_label.text = current_story_text
		return

	# Decide what we are in: intro or outro
	if is_in_outro:
		_outro_next_step()
	else:
		_intro_next_step()


func _intro_next_step() -> void:
	story_index += 1

	if story_index >= story_lines_intro.size():
		story_panel.visible = false
		# Intro finished -> allow player to move
		_set_rover_input(true)
	else:
		_show_current_intro_line()


func _outro_next_step() -> void:
	story_index += 1

	if story_index >= story_lines_outro.size():
		# Finished outro text, now show choice buttons
		story_next_button.visible = false
		choice_buttons.visible = true
	else:
		_show_current_outro_line()


# ---------- OUTRO CHOICES + THANK YOU SCREEN ----------

func _on_call_home_pressed() -> void:
	_show_thank_you(true)


func _on_stay_here_pressed() -> void:
	_show_thank_you(false)


func _show_thank_you(call_home: bool) -> void:
	story_panel.visible = false
	end_screen.visible = true
	end_label.text = "Thank you for playing our game"

	await get_tree().create_timer(3.0).timeout

	if call_home:
		# End the game completely
		get_tree().quit()
	else:
		# Hide thank-you screen, let player keep roaming
		end_screen.visible = false
		_set_rover_input(true)


# ---------- ROVER INPUT HELPERS ----------

func _on_node_added(node: Node) -> void:
	# If a rover appears while we are still before/inside intro,
	# make sure its input is disabled
	if node.is_in_group("rover") and node.has_method("set_input_enabled"):
		node.set_input_enabled(false)


func _set_rover_input(enabled: bool) -> void:
	var rover = get_tree().get_first_node_in_group("rover")
	if rover and rover.has_method("set_input_enabled"):
		rover.set_input_enabled(enabled)
