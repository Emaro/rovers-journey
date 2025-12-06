extends RigidBody3D
class_name RaycastCar

@export var wheels: Array[RaycastWheel]
@export var acceleration := 600.0
@export var max_speed := 20.0
@export var acceleration_curve : Curve
@export var lower_center_of_mass := 0.5
@export var tire_turn_speed := 2.0
@export var tire_max_turn_degrees := 25

@export var skid_marks : Array[GPUParticles3D]
@export var show_debug := false
@export var disable_nav := false

@onready var total_wheels := wheels.size()

var motor_input := 0.0
var handbrake := false # probably remove
var is_slipping := false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("handbrake"):
		is_slipping = true
	
func _process(delta: float) -> void:
	motor_input = Input.get_axis("move_back", "move_forward")
	handbrake = Input.is_action_pressed("handbrake")

func basic_steering_rotation(wheel: RaycastWheel, delta: float) -> void:
	if not wheel.is_steer: return
	
	var turn_input := Input.get_axis("move_right", "move_left") * tire_turn_speed
	if turn_input:
		wheel.rotation.y = clampf(wheel.rotation.y + turn_input * delta,
			deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
	else:
		wheel.rotation.y = move_toward(wheel.rotation.y, 0, tire_turn_speed * delta)

func do_single_wheel_traction(ray: RaycastWheel,id : int):
	if not ray.is_colliding(): return
	
	var steer_side_dir := ray.global_basis.x
	var tire_vel := get_point_velocity(ray.wheel.global_position)
	var steering_x_vel := steer_side_dir.dot(tire_vel)
	var grip_factor := absf(steering_x_vel / tire_vel.length())
	var x_traction := ray.grip_curve.sample_baked(grip_factor)
	
	if not handbrake and grip_factor < 0.2:
		is_slipping = false
		skid_marks[id].emitting = false
	
	if handbrake:
		x_traction = 0.05
		if not skid_marks[id].emitting:
			skid_marks[id].emitting = true
	elif is_slipping:
		x_traction = 0.1
		 
	# F = M * A
	var g : float = ProjectSettings.get_setting("physics/3d/default_gravity")
	# make more responsive by applying to global_basis.x instead of steer_side_dir
	# var x_force := -global_basis.x * steering_x_vel * x_traction * (mass*g/4)
	var x_force := -steer_side_dir * steering_x_vel * x_traction * (mass*g/4)
	
	# z force traction
	var f_vel := -ray.global_basis.z.dot(tire_vel)
	var z_traction := 0.05
	# can also use ray.global_basis
	var z_force := global_basis.z * f_vel * z_traction * (mass*g/4)
	
	var force_pos := ray.wheel.global_position - global_position
	apply_force(x_force, force_pos)
	apply_force(z_force, force_pos)
	DebugDraw3D.draw_arrow_ray(ray.wheel.global_position, x_force/mass, 1.0, Color.GREEN, 0.05)
	DebugDraw3D.draw_arrow_ray(ray.wheel.global_position, z_force/mass, 1.0, Color.PURPLE, 0.05)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if show_debug: DebugDraw3D.draw_arrow_ray(global_position, linear_velocity, 1.0, Color.YELLOW, 0.05)
	
	var id := 0
	var grounded := false
	for wheel in wheels:
		wheel.apply_wheel_physics(self)
		basic_steering_rotation(wheel, delta)
		
		wheel.is_braking = disable_nav || Input.is_action_pressed("full_brake")
		skid_marks[id].global_position = wheel.get_collision_point() + Vector3.UP * 0.01
		skid_marks[id].look_at(skid_marks[id].global_position + global_basis.z)
	
		if not handbrake and wheel.grip_factor < 0.2:
			is_slipping = false
			skid_marks[id].emitting = false
		
		if handbrake and not skid_marks[id].emitting:
			skid_marks[id].emitting = true

		if wheel.is_colliding():
			grounded = true

		id += 1
	
	if grounded:
		center_of_mass = Vector3.ZERO
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * lower_center_of_mass

func do_single_wheel_acceleration(ray: RaycastWheel) -> void:		
	var forward_dir := ray.global_basis.z
	var vel := forward_dir.dot(linear_velocity)
	ray.wheel.rotate_x((vel * get_process_delta_time()) /  ray.wheel_radius)
			
	
	if ray.is_colliding():
		var contact := ray.wheel.global_position
		var force_pos := contact - global_position
		
		if ray.is_motor and motor_input:
			var speed_ratio := signf(vel) * vel / max_speed
			var acc := acceleration_curve.sample_baked(speed_ratio)
			var force_vector := forward_dir * acceleration * motor_input * acc
			apply_force(force_vector, force_pos)
			DebugDraw3D.draw_arrow_ray(contact, force_vector/mass, 1.0, Color.RED, 0.05)
			
func do_single_wheel_suspension(ray: RaycastWheel) -> void:
	if (ray.is_colliding()):
		# remove pulling force
		ray.target_position.y = -(ray.rest_dist + ray.wheel_radius + ray.over_extend)
		
		var contact := ray.get_collision_point()
		var spring_up_dir := ray.global_transform.basis.y
		var spring_len := ray.global_position.distance_to(contact) - ray.wheel_radius
		var offset := ray.rest_dist - spring_len
		
		ray.wheel.position.y = -spring_len
		
		var spring_force := ray.spring_strength * offset
		
		var world_velocity := get_point_velocity(contact)
		var relative_velocity := spring_up_dir.dot(world_velocity)
		var spring_damp_force := ray.spring_damping * relative_velocity
		
		var force_vector := (spring_force - spring_damp_force) * ray.get_collision_normal()
		
		contact = ray.wheel.global_position
		
		var force_pos_offset := contact - global_position
		apply_force(force_vector, force_pos_offset)

		DebugDraw3D.draw_arrow_ray(contact, force_vector/mass, 1.0, Color.BLUE, 0.05)
		
func get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
