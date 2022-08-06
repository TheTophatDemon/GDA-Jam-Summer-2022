extends Actor
class_name Sentry

const EXPLOSION_PREFAB = preload("res://scenes/prefabs/effects/explosion_effect.tscn")
const SHOT_PREFAB = preload("res://scenes/prefabs/attacks/lazer_shot.tscn")

export(String, "EnemyTeam", "PlayerTeam") var target_team:String = Globals.NAME_ENEMY_TEAM
export(float) var spin_speed:float = 4.0
export(float) var spin_angle:float = 0.0 #The angle, in degrees, at which the sentry head spins in the other direction

onready var head:Spatial = $Model/sentry_head
onready var shooter:RayCast = $Model/sentry_head/Shooter

var target:Actor = null

var shoot_interval:float = 0.5
var shoot_timer:float = 0.0
var shooting:bool = false

var original_angle:float = 0.0

func _ready():
	shooter.add_exception(self)
	
	original_angle = rad2deg(global_transform.basis.get_euler().y)
	
	for enemy in get_node("/root/World/TurnControl/Teams/" + Globals.NAME_ENEMY_TEAM).get_children():
		enemy.connect("hurt", self, "_on_target_hit")
	
func hurt(damage:int, perpetrator:Spatial)->bool:
	var h = .hurt(damage, perpetrator)
	return h
	
func die():
	.die()
	var fx = EXPLOSION_PREFAB.instance()
	get_node("/root/World").add_child(fx)
	fx.global_transform = global_transform
	queue_free()
	emit_signal("dead")
	
func _on_start_turn(team:Team, actor:Actor):
	shooting = false
	if team.name == target_team:
		#Only target the enemy actively taking its turn
		activate()
		set_target(actor)
	else:
		set_target(null)
		deactivate()
		
func set_target(new_target:Actor):
#	if is_instance_valid(target):
#			target.disconnect("hurt", self, "_on_target_hit")
	target = new_target
#	if is_instance_valid(target) and !target.is_connected("hurt", self, "_on_target_hit"):
#		target.connect("hurt", self, "_on_target_hit")
		
#Stop shooting when an enemy is hit, regardless of whether it's the target or not.
func _on_target_hit(perp):
	if perp == self:
		shooting = false
		set_target(null)
		expend_action()

func shoot():
	var shot = SHOT_PREFAB.instance()
	get_node("/root/World").add_child(shot)
	shot.shooter = self
	shot.global_transform = shooter.global_transform
	shot.rotate_y(PI)
	emit_signal("shoot", shot, self)

func _process(delta):
	if not is_instance_valid(target):
		shooting = false
	if shooting:
		#Turn to face target
		head.rotation_target = (target.global_transform.origin - global_transform.origin).normalized()
		if head.facing_direction == head.rotation_target and shoot_timer <= 0.0:
			if shooter.get_collider() == target:
				shoot()
			shoot_timer = shoot_interval
		else:
			shoot_timer -= delta
	else:
		if active and actions_left > 0 and shooter.get_collider() == target:
			shooting = true
		if is_zero_approx(spin_angle):
			#Spin continously
			head.rotation_target = Quat(Vector3.UP, spin_speed * delta) * head.rotation_target
		else:
			if head.facing_direction == head.rotation_target:
				spin_speed = -spin_speed
				var a:float = 0.0
				if spin_speed > 0.0:
					a = deg2rad(original_angle + spin_angle)
				else:
					a = deg2rad(original_angle - spin_angle)
				head.rotation_target = Vector3(cos(a), 0.0, sin(a))
				head.turn_speed = spin_speed
