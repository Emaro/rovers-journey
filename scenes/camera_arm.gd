extends Camera3D

@export var min_dist := 4.0
@export var max_dist := 8.0
@export var height := 3.0
@export var camera_sensibility := 0.001
@export var hud : Node

@onready var target : Node3D = get_parent().get_parent()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and !hud.get_node("AlienDialog").visible:
		top_level = false
		get_parent().rotate_y(-event.relative.x * camera_sensibility)
		top_level = true
		
func _physics_process(delta: float) -> void:
	var from_target := global_position - target.global_position
	
	if from_target.length() < min_dist:
		from_target = from_target.normalized() * min_dist
	elif from_target.length() > max_dist:
		from_target = from_target.normalized() * max_dist
		
	from_target.y = height
	global_position = target.global_position + from_target
	
	var look_dir := global_position.direction_to(target.global_position).abs() - Vector3.UP
	if not look_dir.is_zero_approx():
		look_at_from_position(global_position, target.global_position, Vector3.UP)
	
	
