extends KinematicBody
class_name Actor

signal no_actions_left
signal hurt(perpetrator)

onready var anim:AnimationPlayer = $Model/AnimationPlayer
onready var turn_control = get_node("%TurnControl")

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

func activate():
	actions_left = actions_per_turn
	active = true
	
func deactivate():
	active = false
	
func _on_shot_hit(shot:Shot):
	emit_signal("hurt", shot.shooter)
	
func _on_turn_activate(actor:Actor):
	if actor.name != name:
		deactivate()

func _ready():
	facing_direction = global_transform.basis * Vector3.FORWARD
	rotation_target = facing_direction
	
	var _err
	_err = turn_control.connect("activate_player", self, "_on_turn_activate")
	_err = turn_control.connect("activate_enemy", self, "_on_turn_activate")

func expend_action(amount:int = 1):
	actions_left = max(0, actions_left - amount)
	if actions_left <= 0:
		emit_signal("no_actions_left")

func _physics_process(delta):
	var move = Vector2(velocity.x, velocity.z)
	var walk_speed = move.length()
	if is_zero_approx(move_input.length_squared()):
		#Apply friction
		move = move.normalized() * (walk_speed - min(walk_speed, friction * delta))
	elif active:
		move = move_input.normalized() * max_move_speed
	velocity.x = move.x
	velocity.z = move.y
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	
	var _moved = move_and_slide_with_snap(velocity, snap_vec, Vector3.UP, true)
	
func _process(delta):
	#Interpolate rotation
	var rot_dist = rotation_target.angle_to(facing_direction)
	if rot_dist > 0.0:
		var rot_change = turn_speed * delta / rot_dist
		if rot_change < 1.0:
			facing_direction = facing_direction.slerp(rotation_target, rot_change)
		else:
			facing_direction = rotation_target
	look_at(global_transform.origin - facing_direction, Vector3.UP)
