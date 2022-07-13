extends Camera

export var actors_path:NodePath = "../TurnControl"
export var move_speed:float = 50.0
var target_path:NodePath

var offset:Vector3 = Vector3(0.0, 28.0, 14.0)
var target_pos:Vector3

func _ready():
	var _err = get_node(actors_path).connect("turn_switch", self, "set_target")

func set_target(node:Spatial):
	target_path = get_path_to(node)

func _process(delta):
	if not target_path.is_empty():
		var node = get_node(target_path) as Spatial
		if is_instance_valid(node):
			target_pos = node.global_transform.origin + offset
			var move_diff = target_pos - global_transform.origin
			var move_dist = move_diff.length()
			var move_amount = delta * move_speed
			if move_dist > move_amount:
				var move_dir = move_diff / move_dist
				global_translate(move_dir * move_amount)
			else:
				global_transform.origin = target_pos
			look_at(node.global_transform.origin, Vector3.UP)
