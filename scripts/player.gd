extends KinematicBody

onready var turn_control = get_node("../..")
onready var anim = $Model/AnimationPlayer

var active:bool = false
var max_move_speed:float = 10.0
var friction = 20.0
var gravity = 50.0
var snap_vec = Vector3(0.0, -6.0, 0.0)
var velocity:Vector3
var rotation_target = Vector3.FORWARD #Unit vector
var facing_direction = Vector3.FORWARD
var turn_speed = 20.0

func _ready():
	anim.set_blend_time("walk-loop", "battle_stance-loop", 0.5)
	anim.set_blend_time("battle_stance-loop", "walk-loop", 0.25)
	
	turn_control.connect("activate_player", self, "_on_activate_player")
	turn_control.connect("activate_enemy", self, "_on_activate_enemy")
	
func _on_activate_player(player:Spatial):
	if player.get_instance_id() == get_instance_id():
		active = true
	else:
		active = false
		
func _on_activate_enemy(_enemy):
	active = false
	
func _process(delta):
	if active:
		var move = Vector2(velocity.x, velocity.z)
		var walk_speed = move.length()
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
			var dx = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
			var dy = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
			move.x = dx * max_move_speed
			move.y = dy * max_move_speed
			if move.length_squared() != 0.0:
				rotation_target = Vector3(dx, 0.0, dy)
		else:
			#Apply friction
			move = move.normalized() * (walk_speed - min(walk_speed, friction * delta))
		velocity.x = move.x
		velocity.z = move.y
		if is_on_floor():
			velocity.y = 0.0
		else:
			velocity.y -= gravity * delta
		
		var moved = move_and_slide_with_snap(velocity, snap_vec, Vector3.UP, true)
		if !is_zero_approx(moved.length_squared()):
			anim.play("walk-loop")
		else:
			anim.play("battle_stance-loop")

		#Interpolate rotation
		var rot_dist = rotation_target.angle_to(facing_direction)
		if rot_dist > 0.0:
			var rot_change = turn_speed * delta / rot_dist
			if rot_change < 1.0:
				facing_direction = facing_direction.slerp(rotation_target, rot_change)
			else:
				facing_direction = rotation_target
		look_at(global_transform.origin - facing_direction, Vector3.UP)
	else:
		anim.play("battle_stance-loop")
