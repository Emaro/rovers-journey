extends VehicleBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("move_right", "move_left"), delta * 50)
	engine_force = Input.get_axis("move_back", "move_forward") * 5000
	if (Input.get_axis("move_back", "move_forward") > 0):
		print(Input.get_axis("move_back", "move_forward"))
