extends Spatial

export(NodePath) var target_path:NodePath
export(float) var follow_dist:float = 10.0

#Assumes that the parent node is a 3D Path
onready var path_node:Path = get_parent()

var target_node:Spatial = null

func _process(delta):
	if !target_path.is_empty():
		target_node = get_node(target_path)
	if is_instance_valid(target_node):
		#Go to nearest position along the camera curve
		var curve_target:Vector3 = (path_node.global_transform.inverse() * target_node.global_transform.origin)
		
		var ofs:float = path_node.curve.get_closest_offset(curve_target)
		translation = path_node.curve.interpolate_baked(ofs - follow_dist, true)
		#Look in the direction of the target at all times.
		look_at(target_node.global_transform.origin, Vector3.UP)
