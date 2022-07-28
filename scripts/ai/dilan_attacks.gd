extends Node

onready var actor:Actor = get_parent()
onready var anim:AnimationPlayer = get_node("../Model/AnimationPlayer")
onready var flame_butt:TextureButton = get_node("%FlameButt")
onready var flame_fx:Particles = get_node("../%FlameEffect/Particles")
onready var flame_hole:Spatial = get_node("../Model/dilan_rig/Skeleton/FlameAttach/FlameHole")
onready var flame_effect:Area = flame_hole.get_child(0)
onready var flame_sound:AudioStreamPlayer = get_node("../FlameSound")

func _ready():
	var _err
	_err = anim.connect("animation_finished", self, "_anim_finished")
	_err = anim.connect("animation_started", self, "_anim_started")
	_err = get_node("/root/world/%TurnControl").connect("activate_player", self, "_on_player_activate")
	_err = actor.connect("die", self, "_on_die")
	flame_effect.monitoring = false

func _on_die(_actor):
	flame_hole.queue_free() #Ensures enemies will not take damage from walking over the corpse

func _on_player_activate(player):
	if player == actor:
		flame_butt.disabled = false

func _flamethrower_activate():
	actor.start_acting()
	anim.animation_set_next("wield", "attack_wield")
	anim.play("wield")
	flame_butt.visible = false
	
func _anim_started(anim_name:String):
	match anim_name:
		"attack_wield":
			flame_sound.play()
			flame_fx.emitting = true
			flame_effect.monitoring = true
	
func _anim_finished(anim_name:String):
	match anim_name:
		"attack_wield":
			flame_fx.emitting = false
			flame_effect.monitoring = false
			anim.animation_set_next("wield", "")
			anim.play("wield", -1, -1.0, true)
			yield(anim, "animation_finished")
			actor.stop_acting()
			actor.expend_action()
			flame_butt.visible = true
			flame_butt.disabled = true

func _process(_delta):
	#We manually orient the flame particles to the weapon position
	#So that the scaling of the particles node does not distort the visual appearance
#	flame_fx.global_transform.origin = flame_hole.global_transform.origin
#	var new_basis = flame_hole.global_transform.basis
#	#Remove scaling
#	new_basis.x.x = 1.0
#	new_basis.y.y = 1.0
#	new_basis.z.z = 1.0
#	flame_fx.global_transform.basis = new_basis
#	#flame_fx.rotate_x(90.0)
	pass
