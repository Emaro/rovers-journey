extends Area3D

@onready var env: Environment = $"../WorldEnvironment".environment

var fog : bool = false;
var t := 1.0
var start_val : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (fog and t < 1):
		t += delta * 0.2
		env.volumetric_fog_length = lerpf(start_val, 100, t)
	elif !fog and t < 1:
		t += delta * 0.2
		env.volumetric_fog_length = lerpf(start_val, 10, t)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Rover":
		fog = true
		t = 0.0
		start_val = env.volumetric_fog_length

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Rover":
		fog = false
		t = 0.0
		start_val = env.volumetric_fog_length
