extends Control

@onready var interact_label: Label = $InteractLabel

@onready var rocks_label: Label = $Resources/RocksLabel
@onready var sandstone_label: Label = $Resources/SandstoneLabel
@onready var metalscrap_label: Label = $Resources/MetalscrapLabel
@onready var wood_label: Label = $Resources/WoodLabel
@onready var crystal_label: Label = $Resources/CrystalLabel
@onready var health_label: Label = $Health/HealthLabel
@onready var alien_dialog: PanelContainer = $AlienDialog
@onready var msg_label: Label = $AlienDialog/VBox/Msg
@onready var upgrade_btn: Button = $AlienDialog/VBox/Buttons/UpgradeBtn
@onready var cancel_btn: Button = $AlienDialog/VBox/Buttons/CancelBtn

@onready var start_screen: Control = $StartScreen
@onready var start_button: Button = $StartScreen/VBoxContainer/StartButton

@onready var story_panel: PanelContainer = $StoryPanel
@onready var story_label: Label = $StoryPanel/VBoxContainer/MarginContainer/StoryLabel
@onready var story_next_button: Button = $StoryPanel/VBoxContainer/StoryNextButton
@onready var start_mission_button: Button = $StoryPanel/VBoxContainer/StartMissionButton
@onready var story_decide_button: Button = $StoryPanel/VBoxContainer/StoryDecideButton
@onready var choice_buttons: HBoxContainer = $StoryPanel/VBoxContainer/ChoiceButtons
@onready var call_home_button: Button = $StoryPanel/VBoxContainer/ChoiceButtons/CallHomeButton
@onready var stay_here_button: Button = $StoryPanel/VBoxContainer/ChoiceButtons/StayHereButton

@onready var end_screen: Control = $EndScreen
@onready var end_label: Label = $EndScreen/VBoxContainer/EndLabel

var message_time_left: float = 0.0
var current_alien: Node = null
var current_cost: int = 0
var current_has_enough: bool = false
var current_mode: String = "upgrade"
var tower_completed: bool = false

var story_lines_intro := [
	"Mission Log 042: Emergency landing complete.",
	"I have crash-landed on an unknown planet.",
	"Most of my systems are damaged. I must gather resources to begin repairs.",
	"I should explore this place and build a communication tower to signal home."
]

var story_lines_outro := [
	"Mission Log 099: Final tower segment complete.",
	"My connection back home is within reach.",
	"Yet this planet no longer feels unknown...",
	"This place could be my new home.",
	"I must decide: Do I call home, or stay here?"
]

var story_index: int = 0
var is_in_outro: bool = false

var is_typing: bool = false
var type_char_index: int = 0
var type_char_delay: float = 0.03
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
	# start_button.pressed.connect(_on_start_button_pressed)

	story_next_button.pressed.connect(_on_story_next_pressed)
	start_mission_button.pressed.connect(_on_story_next_pressed)
	story_decide_button.pressed.connect(_on_story_next_pressed)
	call_home_button.pressed.connect(_on_call_home_pressed)
	stay_here_button.pressed.connect(_on_stay_here_pressed)

	get_tree().node_added.connect(_on_node_added)

	_set_rover_navigation_enabled(false)
	$Health/RespawnButton.focus_mode = FocusMode.FOCUS_NONE

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


func _refresh() -> void:
	var rocks := Inventory.get_count("rock")
	var sandstone := Inventory.get_count("sandstone")
	var metalscrap := Inventory.get_count("metalscrap")
	var wood := Inventory.get_count("wood")
	var crystal := Inventory.get_count("crystal")

	rocks_label.text = "Rocks: %d" % rocks
	sandstone_label.text = "Sandstones: %d" % sandstone
	metalscrap_label.text = "Metalscraps: %d" % metalscrap
	wood_label.text = "Wood: %d" % wood
	crystal_label.text = "Crystal: %d" % crystal


func update_resource_labels() -> void:
	_refresh()


func show_message(text: String, duration: float = 3.0) -> void:
	message_time_left = duration
	rocks_label.text = text


func show_interact_prompt() -> void:
	interact_label.visible = true


func hide_interact_prompt() -> void:
	interact_label.visible = false


func show_alien1_dialog(
	alien: Node,
	has_enough: bool,
	required_metalscrap: int,
	required_rocks: int,
	available_metalscrap: int,
	available_rocks: int,
	drivetrain_upgraded: bool
) -> void:
	current_mode = "upgrade"
	current_alien = alien
	current_has_enough = has_enough
	message_time_left = 0.0

	_set_rover_navigation_enabled(false)

	interact_label.visible = false
	alien_dialog.visible = true
	upgrade_btn.visible = true
 
	if drivetrain_upgraded:
		msg_label.text = "Your drivetrain is fixed now.\n" \
			+ "You should be able to drive as fast as before your crash!\n" \
			+ "If you follow the path up into the mountains, you might " \
			+ "find someone who knows how to build a communication tower.\n"
		upgrade_btn.visible = false
		upgrade_btn.disabled = true
		cancel_btn.text = "Close"
	else:
		upgrade_btn.visible = true
		if has_enough:
			msg_label.text = "Whoa, I saw you crash-land!\n" \
				+ "Your drivetrain looks really beat up.\n" \
				+ "I can fix it for you.\n" \
				+ "Bring me 5 metal scraps and 2 rocks.\n"
			upgrade_btn.disabled = false
			upgrade_btn.text = "Upgrade"
			cancel_btn.text = "Cancel"
		else:
			msg_label.text = "Whoa, I saw you crash-land!\n" \
				+ "Your drivetrain looks really beat up.\n" \
				+ "I can fix it for you.\n" \
				+ "Bring me 5 metal scraps and 2 rocks.\n" \
				+ "Come back when you've gathered enough.\n"
			upgrade_btn.disabled = true
			upgrade_btn.text = "Upgrade"
			cancel_btn.text = "Close"



func show_alien_t1_dialog(
	alien: Node,
	has_enough: bool,
	required_rock: int,
	required_sandstone: int,
	available_rock: int,
	available_sandstone: int,
	part_built: bool
) -> void:
	current_mode = "tower1"
	current_alien = alien
	current_has_enough = has_enough
	message_time_left = 0.0

	_set_rover_navigation_enabled(false)

	interact_label.visible = false
	alien_dialog.visible = true
	upgrade_btn.visible = true

	if part_built:
		msg_label.text = (
			"I built the Foundation Core near your crash site.\n"
			+ "Take a look when you have a moment!\n"
			+ "If you cross the grass plains, you’ll find someone\n"
			+ "who can help you build the tower frame.\n"
		)
		upgrade_btn.visible = false
		upgrade_btn.disabled = true
		cancel_btn.text = "Close"
		return

	upgrade_btn.visible = true
	if has_enough:
		msg_label.text = (
			"Oh, my friend near your crash site told me about you.\n"
			+ "I'd love to help you build the Foundation Core!\n"
			+ "Bring me 4 rocks and 3 sandstones.\n"
		) % [required_rock, required_sandstone]
		upgrade_btn.disabled = false
		upgrade_btn.text = "Build"
		cancel_btn.text = "Cancel"
		return

	msg_label.text = (
		"Oh, my friend near your crash site told me about you.\n"
		+ "I'd love to help you build the Foundation Core!\n"
		+ "Bring me 4 rocks and 3 sandstones.\n"
		+ "Come back when you've gathered enough.\n"
	) % [required_rock, available_rock, required_sandstone, available_sandstone]
	upgrade_btn.disabled = true
	upgrade_btn.text = "Build"
	cancel_btn.text = "Close"




func show_alien_t2_dialog(
	alien: Node,
	has_enough: bool,
	required_wood: int,
	available_wood: int,
	part_built: bool
) -> void:
	current_mode = "tower2"
	current_alien = alien
	current_has_enough = has_enough
	message_time_left = 0.0

	_set_rover_navigation_enabled(false)

	interact_label.visible = false
	alien_dialog.visible = true
	upgrade_btn.visible = true

	if part_built:
		msg_label.text = (
			"The tower frame is in place now.\n"
			+ "Once you add the transmitter, your signal will finally reach out.\n"
			+ "Deep in the crystal fields, someone can help you build that part.\n"
		)
		upgrade_btn.visible = false
		upgrade_btn.disabled = true
		cancel_btn.text = "Close"
		return

	upgrade_btn.visible = true
	if has_enough:
		msg_label.text = (
			"I got a message from the mountains about you.\n"
			+ "I can help you build the tower frame!\n"
			+ "Bring me 7 pieces of wood.\n"
		) % required_wood
		upgrade_btn.disabled = false
		upgrade_btn.text = "Build"
		cancel_btn.text = "Cancel"
		return

	msg_label.text = (
		"I got a message from the mountains about you.\n"
		+ "I can help you build the tower frame!\n"
		+ "Bring me 7 wood.\n"
		+ "Come back when you've gathered enough.\n"
	) % [required_wood, available_wood]
	upgrade_btn.disabled = true
	upgrade_btn.text = "Build"
	cancel_btn.text = "Close"



func show_alien_t3_dialog(
	alien: Node,
	has_enough: bool,
	required_crystal: int,
	required_metalscrap: int,
	required_rocks: int,
	available_crystal: int,
	available_metalscrap: int,
	available_rocks: int,
	part_built: bool
) -> void:
	current_mode = "tower3"
	current_alien = alien
	current_has_enough = has_enough
	message_time_left = 0.0

	_set_rover_navigation_enabled(false)

	interact_label.visible = false
	alien_dialog.visible = true

	if part_built:
		msg_label.text = (
			"The tower transmitter is complete.\n"
			+ "Your signal now reaches the stars.\n\n"
			+ "When you're ready, return to your crash site.\n"
		)
		upgrade_btn.visible = false
		upgrade_btn.disabled = true
		cancel_btn.text = "Close"
		return

	if has_enough:
		msg_label.text = (
			"So, you found me.\n"
			+ "I can help you build the tower transmitter.\n"
			+ "Bring me 3 crystals, 5 metal scraps and 3 rocks.\n"
		) % [required_crystal, required_metalscrap, required_rocks]
		upgrade_btn.visible = true
		upgrade_btn.disabled = false
		upgrade_btn.text = "Build"
		cancel_btn.text = "Cancel"
		return

	msg_label.text = (
		"So, you found me.\n"
		+ "I can help you build the tower transmitter.\n"
		+ "Bring me 3 crystals, 5 metal scraps and 3 rocks.\n"
		+ "Come back when you've gathered enough.\n"
	) % [
		required_crystal,  available_crystal,
		required_metalscrap, available_metalscrap,
		required_rocks, available_rocks
	]
	upgrade_btn.disabled = true
	upgrade_btn.text = "Build"
	cancel_btn.text = "Close"



func _on_upgrade_pressed() -> void:
	if not current_has_enough or current_alien == null:
		return

	if current_mode == "upgrade":
		if current_alien.has_method("perform_upgrade"):
			current_alien.perform_upgrade()

			if current_alien.name == "Alien_1":
				show_alien1_dialog(
					current_alien,
					true,
					0,
					0,
					0,
					0,
					true
				)
				return

	if current_mode == "tower1":
		if current_alien.has_method("perform_build"):
			current_alien.perform_build()
			show_alien_t1_dialog(
				current_alien,
				true,
				0,
				0,
				0,
				0,
				true
			)
			return

	if current_mode == "tower2":
		if current_alien.has_method("perform_build"):
			current_alien.perform_build()
			show_alien_t2_dialog(
				current_alien,
				true,
				0,
				0,
				true
			)
			return

	if current_mode == "tower3":
		if current_alien.has_method("perform_build"):
			current_alien.perform_build()
			show_alien_t3_dialog(
				current_alien,
				true,
				0,
				0,
				0,
				0,
				0,
				0,
				true
			)
			return

	alien_dialog.visible = false
	_refresh()
	interact_label.visible = true
	_set_rover_navigation_enabled(true)


func _on_cancel_pressed() -> void:
	alien_dialog.visible = false
	_refresh()
	if current_mode != "hint":
		interact_label.visible = true

	_set_rover_navigation_enabled(true)



func _on_start_button_pressed() -> void:
	start_screen.visible = false
	_set_rover_navigation_enabled(false)
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
		story_next_button.visible = false
		start_mission_button.visible = true
	else:
		story_next_button.text = "Next"
		story_next_button.reset_size()


func start_outro_sequence() -> void:
	if not tower_completed:
		return

	is_in_outro = true
	story_index = 0
	story_panel.visible = true
	story_next_button.visible = true
	choice_buttons.visible = false
	_set_rover_navigation_enabled(false)
	_show_current_outro_line()


func _show_current_outro_line() -> void:
	_start_typewriter(story_lines_outro[story_index])

	if story_index == story_lines_outro.size() - 1:
		story_next_button.visible = false
		story_decide_button.visible = true
		
	else:
		story_next_button.text = "Next"


func _on_story_next_pressed() -> void:
	if is_typing:
		is_typing = false
		story_label.text = current_story_text
		return

	if is_in_outro:
		_outro_next_step()
	else:
		_intro_next_step()

func _intro_next_step() -> void:
	story_index += 1

	if story_index >= story_lines_intro.size():
		start_mission_button.visible = false
		story_panel.visible = false
		_set_rover_navigation_enabled(true)
		show_start_hint_popup()
	else:
		_show_current_intro_line()



func _outro_next_step() -> void:
	story_index += 1

	if story_index >= story_lines_outro.size():
		story_next_button.visible = false
		choice_buttons.visible = true
	else:
		_show_current_outro_line()


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
		get_tree().quit()
	else:
		end_screen.visible = false
		_set_rover_navigation_enabled(true)


func _on_node_added(node: Node) -> void:
	if node.is_in_group("rover"):
		var rover := node as RaycastCar
		if rover:
			rover.disable_nav = true


func _set_rover_navigation_enabled(enabled: bool) -> void:
	var rover := get_tree().get_first_node_in_group("rover") as RaycastCar
	if rover:
		rover.disable_nav = not enabled


func on_tower_completed() -> void:
	if tower_completed:
		return
	tower_completed = true


func _on_dark_area_body_entered(body: Node3D) -> void:
	pass


func _on_rover_health_changed(old_health: Variant, new_health: Variant) -> void:
	health_label.text = "<3 ".repeat(new_health).trim_suffix(" ")


func _on_button_pressed() -> void:
	var rover := get_tree().get_first_node_in_group("rover") as RaycastCar
	if rover:
		rover.kill()
		
func show_start_hint_popup() -> void:
	await get_tree().create_timer(5.0).timeout

	if alien_dialog.visible:
		return

	current_mode = "hint"

	interact_label.visible = false
	alien_dialog.visible = true
	upgrade_btn.visible = false
	upgrade_btn.disabled = true
	cancel_btn.text = "Close"

	msg_label.text = (
		"HOW TO PLAY\n\n"
		+ "Movement:\n"
		+ "  W / ↑  – Move forward\n"
		+ "  S / ↓  – Move back\n"
		+ "  A / ←  – Turn left\n"
		+ "  D / →  – Turn right\n\n"
		+ "Interaction:\n"
		+ "  E – Talk to aliens\n\n"
		+ "Driving:\n"
		+ "  Space – Drift mode\n"
		+ "  X – Full brake\n\n"
		+ "Explore the crash site and look for someone who can help you!\n"
	)
