extends Spatial

var rotation_target = Vector3.FORWARD #Unit vector
var facing_direction = Vector3.FORWARD
var turn_speed = 20.0

func _ready():
	facing_direction = global_transform.basis * Vector3.FORWARD
	rotation_target = facing_direction

func _process(delta):
	var rot_dist = rotation_target.angle_to(facing_direction)
	if rot_dist > 0.0:
		var rot_change = turn_speed * delta / rot_dist
		if rot_change < 1.0:
			facing_direction = facing_direction.slerp(rotation_target, rot_change)
		else:
			facing_direction = rotation_target
	look_at(global_transform.origin - facing_direction, Vector3.UP)
