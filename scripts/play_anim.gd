extends Spatial

export var animation = "default"
export var offset:float = 0.0
export var pause:bool = false

onready var anim = $AnimationPlayer

func _ready():
	anim.play(animation)
	anim.advance(offset)
	if pause:
		anim.stop(false)
