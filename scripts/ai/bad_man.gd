extends "res://scripts/actor.gd"
class_name Enemy

const CAST_OFFSET = Vector3(0.0, 1.0, 0.0)

const SHOT_PREFAB = preload("res://scenes/prefabs/lazer_shot.tscn")
const EXPLOSION_PREFAB = preload("res://scenes/prefabs/explosion_effect.tscn")
const GIBS_PREFAB = preload("res://gfx/models/characters/bad_man_gibs.glb")

onready var players = get_node("%AlivePlayers")
onready var nav:NavigationAgent = $NavigationAgent
onready var shooter:Spatial = $Model/badman_rig/Skeleton/Shooter
onready var cast1 = get_node("Cast1")
onready var cast2 = get_node("Cast2")
onready var cast3 = get_node("Cast3")
onready var smoke_fx = $Smoke

enum Action { PURSUE, ATTACK }
var action = Action.PURSUE

var target_player:Spatial = null
var attack_timer:float = 0.0

var shoot_range = 25.0

func _ready():
	anim.set_blend_time("walk-loop", "battle_stance-loop", 0.5)
	anim.set_blend_time("battle_stance-loop", "walk-loop", 0.25)
	var _err
	_err = anim.connect("animation_finished", self, "_on_animation_finish")
	_err = anim.connect("animation_started", self, "_on_animation_start")
	
	nav.set_target_location(global_transform.origin)
	_err = nav.connect("velocity_computed", self, "_on_velocity_computed")
	nav.max_speed = max_move_speed

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
	
func _on_animation_finish(anim_name:String):
	match anim_name:
		"die":
			smoke_fx.emitting = false
			if died:
				#Spawn explosion
				var ex = EXPLOSION_PREFAB.instance()
				get_node("/root/world").add_child(ex)
				ex.global_transform.origin = global_transform.origin
				#Spawn gibs
				var gibs = GIBS_PREFAB.instance()
				get_node("/root/world").add_child(gibs)
				gibs.global_transform.origin = global_transform.origin
				#Apply impulse to gibs so they fly out
				for child in gibs.get_children():
					var rb = child as RigidBody
					rb.apply_impulse(Vector3.ZERO, (rb.global_transform.origin - gibs.global_transform.origin) * 2.0)
					rb.apply_torque_impulse(Vector3(randf() * 10.0 - 5.0, randf() * 10.0 - 5.0, randf() * 10.0 - 5.0))
				#Delete actor
				queue_free()
	
func hurt(damage:int, perpetrator:Spatial)->bool:
	var h = .hurt(damage, perpetrator)
	if h and not died:
		anim.play("die")
	return h
	
func die():
	.die()
	var dead_enemies = get_node("/root/world/%DeadEnemies")
	get_parent().remove_child(self)
	dead_enemies.add_child(self)
	anim.play("die")
	
func _process(delta):
	if active and not died:
		#Target nearest player
		var nearest_ply:Spatial = null
		var nearest_sqdist:float = 100000.0
		for ply in players.get_children():
			var d = (ply.global_transform.origin - global_transform.origin).length_squared()
			if is_instance_valid(ply) and d < nearest_sqdist:
				nearest_sqdist = d
				nearest_ply = ply
		if is_instance_valid(nearest_ply):
			target_player = nearest_ply
			if nav.get_target_location() != nearest_ply.global_transform.origin:
				nav.set_target_location(nearest_ply.global_transform.origin)
				action = Action.PURSUE
		
		match action:
			Action.ATTACK:
				move_input = Vector2.ZERO
				var target_diff = (target_player.global_transform.origin - global_transform.origin)
				rotation_target = Vector3(target_diff.x, 0.0, target_diff.z).normalized()
				attack_timer += delta
				if actions_left > 0:
					anim.play("shoot")
					if anim.current_animation_position > 0.5:
						var shot = SHOT_PREFAB.instance()
						shot.global_transform = shooter.global_transform
						shot.rotate_y(PI / 2.0)
						#shot.owner = owner
						shot.shooter = self
						get_tree().root.add_child(shot)
						emit_signal("shoot", shot, self)
						expend_action()
					
				elif anim.current_animation != "shoot":
					anim.play("battle_stance-loop")
					
				if actions_left <= 0:
					action = Action.PURSUE
			Action.PURSUE:
				if !is_zero_approx(velocity.x + velocity.z):
					anim.play("walk-loop")
				else:
					anim.play("battle_stance-loop")
					
				if movement_time <= 0.0:
					turn_control.skip_turn()
	elif not died:
		if anim.current_animation != "die": anim.play("battle_stance-loop")
	
func _physics_process(_delta):
	if active:
		match action:
			Action.PURSUE:
				#Sight test
				var in_sight = true
				for cast in [cast1, cast2, cast3]:
					if cast.is_colliding():
						if (cast.get_collider().collision_layer & Globals.LAYER_BIT_PLAYERS) > 0:
							#print("Hit: " + String(cast.get_collision_point()))
							continue
					in_sight = false
					break
				
				if not nav.is_target_reached() and not in_sight:
					var next_pos = nav.get_next_location()
					var vel_to_pos = (next_pos - global_transform.origin)
					if vel_to_pos.length() >= nav.path_desired_distance:
						if nav.avoidance_enabled:
							nav.set_velocity(vel_to_pos)
						else:
							_on_velocity_computed(vel_to_pos)
					rotation_target = Vector3(vel_to_pos.x, 0.0, vel_to_pos.z)
				else:
					if nav.avoidance_enabled:
						nav.set_velocity(Vector3.ZERO)
					else:
						_on_velocity_computed(Vector3.ZERO)
					if actions_left > 0: 
						action = Action.ATTACK
					else:
						turn_control.skip_turn()
			Action.ATTACK:
				pass
