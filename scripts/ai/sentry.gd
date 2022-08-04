extends Actor
class_name Sentry

const EXPLOSION_PREFAB = preload("res://scenes/prefabs/effects/explosion_effect.tscn")
const SHOT_PREFAB = preload("res://scenes/prefabs/attacks/lazer_shot.tscn")

export(float) var spin_speed:float = 3.0

onready var head:Spatial = $Model/sentry_head
onready var shooter:RayCast = $Model/sentry_head/Shooter

var target:Actor = null

var shoot_interval:float = 0.5
var shoot_timer:float = 0.0
var shooting:bool = false

func _ready():
	shooter.add_exception(self)
	actions_per_turn = 3
	
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
	if team.name != Globals.NAME_PLAYER_TEAM:
		#Only target the enemy actively taking its turn
		activate()
		target = actor
	else:
		target = null
		deactivate()

func shoot():
	var shot = SHOT_PREFAB.instance()
	get_node("/root/World").add_child(shot)
	shot.shooter = self
	shot.global_transform = shooter.global_transform
	shot.rotate_y(PI)
	emit_signal("shoot", shot, self)
	expend_action()

func _process(delta):
	if not is_instance_valid(target):
		shooting = false
	if shooting:
		#Turn to face target
		head.rotation_target = (target.global_transform.origin - global_transform.origin).normalized()
		if head.facing_direction == head.rotation_target and actions_left > 0 and shoot_timer <= 0.0:
			shoot()
			shoot_timer = shoot_interval
		elif actions_left == 0:
			shooting = false
		else:
			shoot_timer -= delta
	else:
		if active and actions_left > 0 and shooter.get_collider() == target:
			shooting = true
		head.rotation_target = Quat(Vector3.UP, spin_speed * delta) * head.rotation_target
