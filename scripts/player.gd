extends "res://scripts/actor.gd"

func _ready():
	anim.set_blend_time("walk-loop", "battle_stance-loop", 0.5)
	anim.set_blend_time("battle_stance-loop", "walk-loop", 0.25)
	
func _on_shot_hit(shot:Shot):
	._on_shot_hit(shot)
	if shot.shooter != self:
		anim.play("hurt")
	
func _process(_delta):
	if active:
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
			var dx = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
			var dy = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
			move_input.x = dx
			move_input.y = dy
			if move_input.length_squared() != 0.0:
				rotation_target = Vector3(dx, 0.0, dy)
		else:
			move_input = Vector2.ZERO
		
		if anim.current_animation != "hurt":
			if !is_zero_approx(velocity.x + velocity.z):
				anim.play("walk-loop")
			else:
				anim.play("battle_stance-loop")
	else:
		if anim.current_animation != "hurt": anim.play("battle_stance-loop")
