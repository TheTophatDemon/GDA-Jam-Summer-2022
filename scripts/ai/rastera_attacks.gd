extends Node

const DAGGER_PREFAB = preload("res://scenes/prefabs/attacks/dagger.tscn")

onready var actor:Actor = get_parent()
onready var anim:AnimationPlayer = get_node("../Model/AnimationPlayer")
onready var aim_butt = get_node("../PlayerUI/AimButt")
onready var knife_butt = get_node("../PlayerUI/KnifeButt")
onready var cancel_butt = get_node("../PlayerUI/CancelButt")
onready var move_region = get_node("../PlayerUI/MoveRegion")
onready var throw_point = get_node("../Model/rastera_rig/Skeleton/ThrowPoint")
onready var aim_trail:Particles = get_node("../AimTrail")

var aiming:bool = false

func _ready():
	aim_trail.emitting = true
	
	var err:int = OK
	err += anim.connect("animation_finished", self, "_anim_finished")
	err += anim.connect("animation_started", self, "_anim_started")
	err += get_node("/root/World/%TurnControl").connect("start_turn", self, "_on_start_turn")
	err += aim_butt.connect("pressed", self, "_on_aim_button_press")
	err += knife_butt.connect("pressed", self, "_on_knife_button_press")
	err += cancel_butt.connect("pressed", self, "_on_cancel_button_press")
	if err: printerr("!!! Signal error in rastera_attacks.gd")
	
func _process(_delta):
	if aiming:
		aim_butt.visible = false
		knife_butt.visible = true
		cancel_butt.visible = true
		aim_trail.visible = true
		actor.move_input = Vector2.ZERO
	else:
		aim_butt.visible = true
		knife_butt.visible = false
		cancel_butt.visible = false
		aim_trail.visible = false

func _on_aim_button_press():
	aiming = true
	
func _on_knife_button_press():
	aiming = false
	aim_butt.disabled = true
	anim.play("attack")
	actor.start_acting()
	
	yield(get_tree().create_timer(0.6), "timeout")
	var dagger = DAGGER_PREFAB.instance()
	get_node("/root/World").add_child(dagger)
	dagger.look_at_from_position(throw_point.global_transform.origin, \
		throw_point.global_transform.origin + actor.global_transform.basis * Vector3.BACK, Vector3.UP)
	dagger.scale = Vector3.ONE
	dagger.shooter = actor
	actor.emit_signal("shoot", dagger, actor)
	
func _on_cancel_button_press():
	aiming = false

func _anim_finished(anim_name:String):
	match anim_name:
		"attack":
			#yield(get_tree().get_viewport().get_camera(), "target_reached")
			actor.stop_acting()
			actor.expend_action()
	
func _anim_started(_anim_name:String):
	pass
	
func _on_start_turn(_team, actor_:Actor):
	if actor == actor_:
		aiming = false
		aim_butt.disabled = false
