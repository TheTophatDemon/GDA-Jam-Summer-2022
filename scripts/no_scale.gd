extends Spatial

export(Vector3) var scale_lock = Vector3.ONE

func _process(_delta): 
	var new_basis = global_transform.basis
	new_basis.x.x = scale_lock.x
	new_basis.y.y = scale_lock.y
	new_basis.z.z = scale_lock.z
	global_transform.basis = new_basis
