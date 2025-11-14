extends VehicleBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@export var max_rpm = 450
@export var max_torque = 300
@export var turn_speed = 3
@export var turn_amound = 0.3
func _physics_process(delta: float) -> void:
	var dir = Input.get_axis("move_back", "move_forward")
	var steering_dir = Input.get_axis("move_right", "move_left")
	var rpm = abs($wheelBR.get_rpm() + $wheelBL.get_rpm()) / 2.0
	var torque = dir * max_torque * (1.0 - rpm / max_rpm)
	
	engine_force = torque
	steering = lerp(steering, steering_dir * turn_amound, turn_speed * delta)
