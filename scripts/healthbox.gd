extends Area

onready var anim = $AnimationPlayer

func _ready():
	anim.play("default")
	
	var _err:int = OK
	_err = connect("body_entered", self, "_on_body_entered")
	
func _on_body_entered(body:CollisionObject):
	if body is Actor:
		if body.heal(3):
			consume()
			
func consume():
	$AudioStreamPlayer.play()
	yield($AudioStreamPlayer, "finished")
	queue_free()
