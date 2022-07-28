extends Node

const DAGGER_PREFAB = preload("res://scenes/prefabs/dagger.tscn")

onready var actor:Actor = get_parent()
onready var anim:AnimationPlayer = get_node("../Model/AnimationPlayer")
onready var aim_butt = get_node("../PlayerUI/AimButt")
onready var knife_butt = get_node("../PlayerUI/KnifeButt")
onready var cancel_butt = get_node("../PlayerUI/CancelButt")
onready var move_region = get_node("../PlayerUI/MoveRegion")
onready var throw_point = get_node("../Model/rastera_rig/Skeleton/ThrowPoint")
onready var aim_trail:Particles = get_node("../AimTrail")

func _ready():
	var _err
	_err = anim.connect("animation_finished", self, "_anim_finished")
	_err = anim.connect("animation_started", self, "_anim_started")
	_err = get_node("/root/world/%TurnControl").connect("activate_player", self, "_on_player_activate")

	aim_trail.emitting = true

	aim_butt.connect("pressed", self, "_on_aim_button_press")
	knife_butt.connect("pressed", self, "_on_knife_button_press")
	cancel_butt.connect("pressed", self, "_on_cancel_button_press")
	
func _process(_delta):
	if actor.aiming:
		aim_butt.visible = false
		knife_butt.visible = true
		cancel_butt.visible = true
		aim_trail.visible = true
	else:
		aim_butt.visible = true
		knife_butt.visible = false
		cancel_butt.visible = false
		aim_trail.visible = false

func _on_aim_button_press():
	actor.aiming = true
	
func _on_knife_button_press():
	actor.aiming = false
	aim_butt.disabled = true
	anim.play("attack")
	actor.start_acting()
	
	yield(get_tree().create_timer(0.6), "timeout")
	var dagger = DAGGER_PREFAB.instance()
	get_node("/root/world").add_child(dagger)
	dagger.look_at_from_position(throw_point.global_transform.origin, \
		throw_point.global_transform.origin + actor.global_transform.basis * Vector3.BACK, Vector3.UP)
	dagger.scale = Vector3.ONE
	dagger.shooter = actor
	
func _on_cancel_button_press():
	actor.aiming = false

func _anim_finished(anim_name:String):
	match anim_name:
		"attack":
			actor.stop_acting()
			actor.expend_action()
	
func _anim_started(anim_name:String):
	pass
	
func _on_player_activate(player:Actor):
	if player == actor:
		actor.aiming = false
		aim_butt.disabled = false
