extends Spatial

export var bob_offset = 0.0
export var bob_speed = 1.0
export var bob_range = 1.0
enum BobFunc { COS, SIN }
export(BobFunc) var bob_func = BobFunc.COS
export var bob_axes = Vector3.FORWARD
var bob = 0.0

onready var origin = global_transform.origin

func _process(delta):
	bob += delta * bob_speed
	var offset:float
	match bob_func:
		BobFunc.COS:
			offset = cos(bob_offset + bob)
		BobFunc.SIN:
			offset = sin(bob_offset + bob)
	global_transform.origin = origin + bob_axes * bob_range * offset
