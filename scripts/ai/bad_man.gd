extends "res://scripts/ai/actor.gd"
class_name Enemy

const SHOT_PREFAB = preload("res://scenes/prefabs/attacks/lazer_shot.tscn")
const EXPLOSION_PREFAB = preload("res://scenes/prefabs/effects/explosion_effect.tscn")
const GIBS_PREFAB = preload("res://gfx/models/characters/bad_man_gibs.glb")

onready var players = get_node("%TurnControl/Teams/PlayerTeam")
onready var nav:NavigationAgent = $NavigationAgent
onready var shooter:Spatial = $Model/badman_rig/Skeleton/Shooter
onready var cast1 = get_node("Cast1")
onready var cast2 = get_node("Cast2")
onready var cast3 = get_node("Cast3")
onready var cast4 = get_node("Cast4")
onready var smoke_fx = $Smoke

enum Action { PURSUE, ATTACK, SHRUG, STUN }
var action = Action.PURSUE

var target_actor:Spatial = null
var attack_timer:float = 0.0

var shoot_range = 25.0

var step_speed = 0.5
var step_timer = 0.0

func _ready():
	anim.set_blend_time("walk-loop", "battle_stance-loop", 0.5)
	anim.set_blend_time("battle_stance-loop", "walk-loop", 0.25)
	
	nav.set_target_location(global_transform.origin)
	nav.max_speed = max_move_speed
	
	var err:int = OK
	err += anim.connect("animation_finished", self, "_on_animation_finish")
	err += anim.connect("animation_started", self, "_on_animation_start")
	err += nav.connect("velocity_computed", self, "_on_velocity_computed")
	if err: printerr("!!! Signal error in bad_man.gd")

func activate():
	.activate()
	action = Action.PURSUE

func _on_velocity_computed(new_velocity:Vector3):
	if active and movement_time > 0.0: 
		move_input = Vector2(new_velocity.x, new_velocity.z).normalized()
	
func _on_animation_start(anim_name:String):
	match anim_name:
		"die":
			smoke_fx.emitting = true
		_:
			smoke_fx.emitting = false
	
func _on_animation_finish(anim_name:String):
	match anim_name:
		"die":
			smoke_fx.emitting = false
			if died:
				#Spawn explosion
				var ex = EXPLOSION_PREFAB.instance()
				get_node("/root/World").add_child(ex)
				ex.global_transform.origin = global_transform.origin
				#Spawn gibs
				var gibs = GIBS_PREFAB.instance()
				get_node("/root/World").add_child(gibs)
				gibs.global_transform.origin = global_transform.origin
				#Apply impulse to gibs so they fly out
				for child in gibs.get_children():
					var rb = child as RigidBody
					rb.apply_impulse(Vector3.ZERO, (rb.global_transform.origin - gibs.global_transform.origin) * 2.0)
					rb.apply_torque_impulse(Vector3(randf() * 10.0 - 5.0, randf() * 10.0 - 5.0, randf() * 10.0 - 5.0))
				#Delete actor
				queue_free()
				emit_signal("dead")
			elif action == Action.STUN:
				action = Action.PURSUE
		"shrug":
			turn_control.skip_turn()
			action = Action.STUN
				
func _on_start_turn(team, actor):
	._on_start_turn(team, actor)
	if actor == self: play_multisound("ReadySounds")
	
func hurt(damage:int, perpetrator:Spatial)->bool:
	var h = .hurt(damage, perpetrator)
	if h:
		anim.play("die")
		play_multisound("PainSounds")
		$SoundShock.play()
		if active:
			move_input = Vector2.ZERO
			if perpetrator.health > 0:
				set_target_actor(perpetrator)
			action = Action.STUN
	return h
	
func die():
	.die()
	anim.play("die")
	play_multisound("DeathSounds")
	
func shoot():
	var shot = SHOT_PREFAB.instance()
	shot.global_transform = shooter.global_transform
	shot.rotate_y(PI / 2.0)
	#shot.owner = owner
	shot.shooter = self
	get_tree().root.add_child(shot)
	emit_signal("shoot", shot, self)
	expend_action()
	yield(shot, "tree_exited")
	action = Action.PURSUE
	target_actor = null
	
func set_target_actor(new_target:Actor):
	target_actor = new_target
	if nav.get_target_location() != target_actor.global_transform.origin:
		nav.set_target_location(target_actor.global_transform.origin)
	
func _process(delta):
	if active and not died:
		#Target nearest player (unless getting revenge on a sentry)
		if not is_instance_valid(target_actor) or !(target_actor is Sentry):
			var nearest_ply:Spatial = null
			var nearest_sqdist:float = 100000.0
			for ply in players.get_children():
				var d = (ply.global_transform.origin - global_transform.origin).length_squared()
				if is_instance_valid(ply) and d < nearest_sqdist:
					nearest_sqdist = d
					nearest_ply = ply
			if is_instance_valid(nearest_ply):
				set_target_actor(nearest_ply)
		
		match action:
			Action.ATTACK:
				move_input = Vector2.ZERO
				var target_diff = (target_actor.global_transform.origin - global_transform.origin)
				rotation_target = Vector3(target_diff.x, 0.0, target_diff.z).normalized()
				attack_timer += delta
				if actions_left > 0:
					anim.play("shoot")
					if anim.current_animation_position > 0.5:
						shoot()
					
				elif anim.current_animation != "shoot":
					anim.play("battle_stance-loop")
			Action.PURSUE:
				if !is_zero_approx(velocity.x + velocity.z):
					anim.play("walk-loop")
				else:
					anim.play("battle_stance-loop")
					
				if movement_time <= 0.0:
					turn_control.skip_turn()
			Action.SHRUG:
				if anim.current_animation != "shrug":
					anim.play("shrug")
					$SoundConfused.play()
				var vec_to_camera = (get_viewport().get_camera().global_transform.origin - global_transform.origin).normalized()
				rotation_target = Vector3(vec_to_camera.x, 0.0, vec_to_camera.z)
	elif not died:
		if anim.current_animation != "die": anim.play("battle_stance-loop")
		show_health_stat(0.5)
	
	#Footstep sounds
	if anim.current_animation == "walk-loop":
		step_timer -= delta
		if step_timer <= 0.0:
			step_timer = step_speed
			$SoundStep.pitch_scale = 1.0 + (randf() * 0.25 - 0.125)
			$SoundStep.play()
	else:
		step_timer = 0.0
	
func _physics_process(_delta):
	if active:
		match action:
			Action.PURSUE:
				#Sight test
				var in_sight = true
				#If casts 1,2, and 3 are hitting the player, the shoot.
				#This ensures that there is room around the gun for the shot to travel
				for cast in [cast1, cast2, cast3]:
					if cast.is_colliding():
						if (cast.get_collider().collision_layer & Globals.LAYER_BIT_PLAYERS) > 0:
								continue
					in_sight = false
					break
				#Cast 4 is for close proximity and overrides the other 3
				if cast4.is_colliding() and \
					(cast4.get_collider().collision_layer & Globals.LAYER_BIT_PLAYERS) > 0:
					in_sight = true
				if nav.is_target_reached() or in_sight: #When in range of the target
					if nav.avoidance_enabled:
						nav.set_velocity(Vector3.ZERO)
					else:
						_on_velocity_computed(Vector3.ZERO)
					if actions_left > 0: 
						action = Action.ATTACK
					else:
						turn_control.skip_turn()
				else:
					#Move where the nav tells us to
					var next_pos = nav.get_next_location()
					if not nav.is_target_reachable() and next_pos == nav.get_final_location():
						_on_velocity_computed(Vector3.ZERO)
						action = Action.SHRUG
					else:
						var vel_to_pos = (next_pos - global_transform.origin)
						if vel_to_pos.length() >= nav.path_desired_distance:
							if nav.avoidance_enabled:
								nav.set_velocity(vel_to_pos)
							else:
								_on_velocity_computed(vel_to_pos)
						rotation_target = Vector3(vel_to_pos.x, 0.0, vel_to_pos.z)
			Action.ATTACK:
				pass
			Action.SHRUG, Action.STUN:
				move_input = Vector2.ZERO
