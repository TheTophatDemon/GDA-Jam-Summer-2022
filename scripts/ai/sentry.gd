extends Actor

const EXPLOSION_PREFAB = preload("res://scenes/prefabs/effects/explosion_effect.tscn")

func _ready():
	active = true
	
func die():
	.die()
	var fx = EXPLOSION_PREFAB.instance()
	get_node("/root/World").add_child(fx)
	fx.global_transform = global_transform
	queue_free()
	emit_signal("dead")
