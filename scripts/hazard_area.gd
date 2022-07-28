#Area node that hurts actors that are inside of it
extends Area

export var perpetrator_path:NodePath = "."
onready var perpetrator = get_node(perpetrator_path)

func _ready():
	var _err
	_err = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body:CollisionObject):
	if body != perpetrator and (body.collision_layer & collision_mask) > 0 and body is Actor:
		body.hurt(1, perpetrator)
