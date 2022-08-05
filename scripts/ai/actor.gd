extends KinematicBody
class_name Actor

signal hurt(perpetrator)
signal die(actor) #Played BEFORE the death animation
signal dead() #Played AFTER the death animation
signal shoot(shot, actor)

onready var anim:AnimationPlayer = get_node_or_null("Model/AnimationPlayer")
onready var turn_control = get_node("/root/World/%TurnControl")
onready var label:Label3D = $Label3D
onready var player_ui:Control = $PlayerUI
onready var stamina_bar:TextureProgress = get_node_or_null("PlayerUI/StaminaBar")

var active:bool = false
var max_move_speed:float = 10.0
var friction = 20.0
var gravity = 50.0
var snap_vec = Vector3(0.0, -6.0, 0.0)
var velocity:Vector3

var rotation_target = Vector3.FORWARD #Unit vector
var facing_direction = Vector3.FORWARD
var turn_speed = 20.0

export var max_movement_time:float = 5.0
var movement_time:float = max_movement_time
var move_input:Vector2 = Vector2.ZERO #Unit vector set by child classes to move the actor

var actions_per_turn = 1
var actions_left = actions_per_turn

var label_clear_timer:float = 0.0 #When set above zero, counts down and will clear label text on reaching zero

export var max_health:int = 3
onready var health:int = max_health
var hit:bool = false #Has the actor been damaged this turn?
var died = false

var acting = false

func start_acting():
	acting = true
	player_ui.visible = false
	
func stop_acting():
	acting = false
	player_ui.visible = true
	
func expend_action(amount:int = 1):
	actions_left = max(0, actions_left - amount)

func activate():
	actions_left = actions_per_turn
	movement_time = max_movement_time
	active = true
	player_ui.visible = true
	
func deactivate():
	active = false
	player_ui.visible = false
	
func hurt(damage:int, perpetrator:Spatial)->bool:
	if not hit:
		health = int(max(0, health - damage))
		hit = true
		emit_signal("hurt", perpetrator)
		show_health_stat()
		return true
	return false
	
func die():
	active = false
	died = true
	remove_from_group(Globals.GROUP_KILLABLE)
	emit_signal("die", self)
	if get_node_or_null("CollisionShape") != null:
		remove_child($CollisionShape)
	
func show_health_stat(time:float = 3.0):
	var bars:String = ""
	for _i in range(health):
		bars += "♥"
	for _i in range(max_health - health):
		bars += "♡"
	label.text = "HP [%s]" % bars
	label.modulate = Color.red
	label_clear_timer = time
		
func _on_start_turn(_team, actor:Actor):
	if actor == self:
		activate()
	hit = false
		
func _on_end_turn(_team, _actor):
	deactivate()

func _on_shot_hit(shot:Shot):
	if shot.shooter != self: 
		var _succ = hurt(1, shot.shooter)

func _ready():
	facing_direction = global_transform.basis * Vector3.FORWARD
	rotation_target = facing_direction
	label.text = ""
	player_ui.visible = false
	if stamina_bar != null:
		stamina_bar.max_value = max_movement_time
		stamina_bar.min_value = 0.0
		stamina_bar.value = movement_time
	
	var err:int = OK
	err += turn_control.connect("end_turn", self, "_on_end_turn")
	err += turn_control.connect("start_turn", self, "_on_start_turn")
	if err != OK: printerr("!!! Signal error in actor.gd")

func _physics_process(delta):
	if not died and active:
		var move = Vector2(velocity.x, velocity.z)
		var walk_speed = move.length()
		if is_zero_approx(move_input.length_squared()) or movement_time <= 0.0:
			#Apply friction
			move = move.normalized() * (walk_speed - min(walk_speed, friction * delta))
		elif active and movement_time > 0.0:
			move = move_input.normalized() * max_move_speed
			movement_time -= delta
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
	if stamina_bar != null:
		#Update stamina
		stamina_bar.value = movement_time
	
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
			
func play_multisound(group_name:String):
	var group = get_node_or_null(group_name)
	if group != null and group.get_child_count() > 0:
		group.get_child(randi() % group.get_child_count()).play()
