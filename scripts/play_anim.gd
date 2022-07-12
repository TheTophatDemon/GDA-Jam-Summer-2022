extends Spatial

export var animation = "default"

onready var anim = $AnimationPlayer

func _ready():
	anim.play(animation)
