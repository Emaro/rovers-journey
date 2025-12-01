extends Node3D

@export var anim_name : String = "Armature|Slime_Idle"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var anim : Animation= $AnimationPlayer.get_animation(anim_name)
	anim.loop_mode =(Animation.LOOP_LINEAR)
	$AnimationPlayer.play(anim_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
