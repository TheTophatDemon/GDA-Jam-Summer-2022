extends KinematicBody

onready var nav = $NavigationAgent
onready var anim = $model/AnimationPlayer

func _ready():
	nav.set_target_location(global_transform.origin)
	anim.play("battle_stance-loop")
