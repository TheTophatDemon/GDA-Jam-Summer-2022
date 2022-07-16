extends Spatial

export(float) var speed = 10.0
export(int, "X", "Y", "Z") var axis 

var real_axis:Vector3

func _ready():
	real_axis = Vector3.ZERO
	match axis:
		0: real_axis.x = 1.0
		1: real_axis.y = 1.0
		2: real_axis.z = 1.0

func _process(delta):
	rotate_object_local(real_axis, speed * delta)
