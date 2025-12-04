extends VehicleBody3D

@export var max_rpm = 450
@export var max_torque = 300
@export var turn_speed = 3
@export var turn_amound = 0.3

var input_enabled: bool = true


func _ready() -> void:
	# Optional but useful later to find the rover:
	add_to_group("rover")
	# anything else you need here


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if not input_enabled:
		# When input is disabled, the rover just does nothing
		engine_force = 0
		steering = 0
		return

	var dir = Input.get_axis("move_back", "move_forward")
	var steering_dir = Input.get_axis("move_right", "move_left")
	var rpm = abs($wheelBR.get_rpm() + $wheelBL.get_rpm()) / 2.0
	var torque = dir * max_torque * (1.0 - rpm / max_rpm)

	engine_force = torque
	steering = lerp(steering, steering_dir * turn_amound, turn_speed * delta)
