extends KinematicBody
class_name Actor

signal no_actions_left
signal hurt(perpetrator)
signal die(actor)

onready var anim:AnimationPlayer = $Model/AnimationPlayer
onready var turn_control = get_node("%TurnControl")
onready var label:Label3D = $Label3D

var active:bool = false
var max_move_speed:float = 10.0
var friction = 20.0
var gravity = 50.0
var snap_vec = Vector3(0.0, -6.0, 0.0)
var velocity:Vector3
var rotation_target = Vector3.FORWARD #Unit vector
var facing_direction = Vector3.FORWARD
var turn_speed = 20.0

var move_input:Vector2 = Vector2.ZERO #Unit vector set by child classes to move the actor

var actions_per_turn = 1
var actions_left = actions_per_turn

var label_clear_timer:float = 0.0 #When set above zero, counts down and will clear label text on reaching zero

export var max_health:int = 3
onready var health:int = max_health
var hit_cooldown:float = 1.0
var hit_timer:float = 0.0
var died = false

func activate():
	if not died:
		actions_left = actions_per_turn
		active = true
	
func deactivate():
	active = false
	
func _on_shot_hit(shot:Shot):
	if shot.shooter != self: 
		hurt(1, shot.shooter)
	
func hurt(damage:int, perpetrator:Spatial)->bool:
	if hit_timer <= 0.0 and not died:
		emit_signal("hurt", perpetrator)
		health -= damage
		hit_timer = hit_cooldown
		if health <= 0:
			health = 0
			die()
		show_health_stat()
		return true
	return false
	
func die():
	active = false
	died = true
	emit_signal("die", self)
	if get_node_or_null("CollisionShape") != null:
		remove_child($CollisionShape)
	
func show_health_stat():
	var bars:String = ""
	for _i in range(health):
		bars += "♥"
	for _i in range(max_health - health):
		bars += "♡"
	label.text = "HP [%s]" % bars
	label.modulate = Color.red
	label_clear_timer = 3.0
	
func _on_turn_activate(actor:Actor):
	if actor.name != name:
		deactivate()

func _ready():
	facing_direction = global_transform.basis * Vector3.FORWARD
	rotation_target = facing_direction
	label.text = ""
	
	var _err
	_err = turn_control.connect("activate_player", self, "_on_turn_activate")
	_err = turn_control.connect("activate_enemy", self, "_on_turn_activate")

func expend_action(amount:int = 1):
	actions_left = max(0, actions_left - amount)
	if actions_left <= 0:
		emit_signal("no_actions_left")

func _physics_process(delta):
	if not died and active:
		var move = Vector2(velocity.x, velocity.z)
		var walk_speed = move.length()
		if is_zero_approx(move_input.length_squared()):
			#Apply friction
			move = move.normalized() * (walk_speed - min(walk_speed, friction * delta))
		elif active:
			move = move_input.normalized() * max_move_speed
		velocity.x = move.x
		velocity.z = move.y
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if is_on_floor() or died:
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	
	var _moved = move_and_slide_with_snap(velocity, snap_vec, Vector3.UP, true)
	
func _process(delta):
	if hit_timer > 0.0:
		hit_timer = max(0.0, hit_timer - delta)
	
	#Interpolate rotation
	var rot_dist = rotation_target.angle_to(facing_direction)
	if rot_dist > 0.0:
		var rot_change = turn_speed * delta / rot_dist
		if rot_change < 1.0:
			facing_direction = facing_direction.slerp(rotation_target, rot_change)
		else:
			facing_direction = rotation_target
	look_at(global_transform.origin - facing_direction, Vector3.UP)
	
	#Clear label
	if label_clear_timer > 0.0:
		label_clear_timer -= delta
		if label_clear_timer < 0.0:
			label_clear_timer = 0.0
			label.text = ""
