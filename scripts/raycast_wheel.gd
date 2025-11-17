extends RayCast3D
class_name RaycastWheel

@export_group("Wheel properties")
@export var spring_strength := 100.0
@export var spring_damping := 2.0
@export var rest_dist := 0.5
@export var over_extend := 0.0
@export var wheel_radius := 0.3
@export var z_traction := 0.05
@export var z_brake_traction := 0.25

@export_group("Motor")
@export var is_motor := false
@export var is_steer := false
@export var grip_curve : Curve

@export_category("Debug")
@export var show_debug := false

@onready var wheel: Node3D = get_child(0)

var enigne_force := 0.0
var grip_factor := 0.0
var is_braking := false

func _ready() -> void:
	target_position.y = -(rest_dist + wheel_radius + over_extend)
	
func apply_wheel_physics(car: RaycastCar) -> void:
	target_position.y = -(rest_dist + wheel_radius + over_extend)
	
	# Rotates wheels visuals
	var forward_dir := global_basis.z
	var vel := forward_dir.dot(car.linear_velocity)
	wheel.rotate_x(vel * get_physics_process_delta_time() / wheel_radius)

	if not is_colliding(): return
	
	var contact := get_collision_point()
	var spring_length := maxf(0.0, global_position.distance_to(contact) - wheel_radius)
	var offset := rest_dist - spring_length
	
	wheel.position.y = move_toward(wheel.position.y, -spring_length, 5 * get_physics_process_delta_time())
	contact = wheel.global_position # Contact is now the wheel origin
	var force_pos := contact - car.global_position
	
	# Spring forces
	var spring_force := spring_strength * offset
	var tire_vel := car.get_point_velocity(contact)
	var spring_damp_force := spring_damping * global_basis.y.dot(tire_vel)
	
	var suspension_force := spring_force - spring_damp_force
	var y_force := suspension_force * get_collision_normal()
	
	# Acceleration
	if is_motor and car.motor_input:
		var speed_ratio := vel / car.max_speed
		var acc := car.acceleration_curve.sample_baked(speed_ratio)
		var acc_force := forward_dir * car.acceleration * car.motor_input * acc
		car.apply_force(acc_force, force_pos)
		if show_debug:
			DebugDraw3D.draw_arrow_ray(contact, acc_force/car.mass, 1.0, Color.RED, 0.1)
	
	# Tire X traction (steering)
	var steering_x_vel := global_basis.x.dot(tire_vel)
	
	grip_factor = absf(steering_x_vel / tire_vel.length())
	var x_traction := grip_curve.sample_baked(grip_factor)
	
	if not car.handbrake and grip_factor < 0.2:
		car.is_slipping = false
	if car.handbrake:
		x_traction = 0.01
	elif car.is_slipping:
		x_traction = 0.1
	
	var gravity := -car.get_gravity().y
	var x_force := -global_basis.x * steering_x_vel * x_traction * ((car.mass * gravity) / 4.0)
	
	var f_vel := forward_dir.dot(tire_vel)
	var z_friction := z_traction
	if absf(f_vel) < 0.1: z_friction = 2.0
	if is_braking: z_friction = z_brake_traction
	var z_force := -global_basis.z * f_vel * z_friction * (car.mass * gravity / 4.0)
	
	## counter sliding
	if absf(f_vel) < 0.1:
		var sus := global_basis.y * suspension_force
		z_force.z -= sus.z * car.global_basis.y.dot(Vector3.UP)
		x_force.x -= sus.x * car.global_basis.y.dot(Vector3.UP)
	
	car.apply_force(y_force, force_pos)
	car.apply_force(x_force, force_pos)
	car.apply_force(z_force, force_pos)
	
	if show_debug: DebugDraw3D.draw_arrow_ray(contact, y_force/car.mass, 1.0, Color.ORANGE, 0.1)
	if show_debug: DebugDraw3D.draw_arrow_ray(contact, x_force/car.mass, 1.0, Color.YELLOW, 0.1)
