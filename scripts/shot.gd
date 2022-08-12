extends Area
class_name Shot

export var rotate_speed = 10.0
export var move_speed = 30.0

var shooter:Node = null
var dying = false
var timer:float = 0.0

func _ready():
	var _err
	_err = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body:Node):
	if body != shooter:
		if body.has_method("_on_shot_hit"):
			body._on_shot_hit(self)
		dying = true

func _process(delta):
	rotate_object_local(Vector3.FORWARD, rotate_speed * delta)
	translate_object_local(Vector3.FORWARD * move_speed * delta)
	timer += delta
	if dying or timer > 5.0:
		scale_object_local(Vector3(1.0, 1.0, 0.8))
		if scale.z < 0.1:
			if get_node_or_null("AudioStreamPlayer") != null and $AudioStreamPlayer.playing:
				yield($AudioStreamPlayer, "finished")
			queue_free()
