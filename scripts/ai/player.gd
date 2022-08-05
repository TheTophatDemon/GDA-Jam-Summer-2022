extends "res://scripts/ai/actor.gd"
class_name Player

var aiming:bool = false

func _ready():
	anim.set_blend_time("walk-loop", "battle_stance-loop", 0.5)
	anim.set_blend_time("battle_stance-loop", "walk-loop", 0.25)
	
	var err:int = OK
	err += anim.connect("animation_finished", self, "_on_animation_finished")
	if err: printerr("!!! Signal error in player.gd")
	
func _on_start_turn(team, actor):
	._on_start_turn(team, actor)
	if actor == self: play_multisound("ReadySounds")
	
func hurt(damage:int, perpetrator:Spatial)->bool:
	var h = .hurt(damage, perpetrator)
	if h:
		anim.play("hurt")
		if perpetrator.get_parent().name == Globals.NAME_PLAYER_TEAM:
			play_multisound("BetrayalSounds")
		else:
			play_multisound("PainSounds")
	return h
	
func die():
	.die()
	anim.play("die")
	play_multisound("DeathSounds")
	
func _on_animation_finished(anim_name:String):
	match anim_name:
		"die":
			emit_signal("dead")
	
func _process(_delta):
	if active:
		if not acting and (\
			Input.is_action_pressed("move_left") or \
			Input.is_action_pressed("move_right") or \
			Input.is_action_pressed("move_up") or \
			Input.is_action_pressed("move_down") \
			):
			
			var dx = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
			var dy = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
			if not aiming:
				move_input.x = dx
				move_input.y = dy
			if not is_zero_approx(dx + dy):
				rotation_target = Vector3(dx, 0.0, dy)
		else:
			move_input = Vector2.ZERO
		
		if anim.current_animation != "hurt" and not acting:
			if !is_zero_approx(velocity.x + velocity.z):
				anim.play("walk-loop")
			else:
				anim.play("battle_stance-loop")
	elif not died:
		if anim.current_animation != "hurt": anim.play("battle_stance-loop")
