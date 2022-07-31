extends Node

onready var turn_control = get_node("/root/World/%TurnControl")

onready var actor:Actor = get_parent()
onready var anim:AnimationPlayer = get_node("../Model/AnimationPlayer")
onready var flame_butt:TextureButton = get_node("%FlameButt")
onready var flame_fx:Particles = get_node("../%FlameEffect/Particles")
onready var flame_hole:Spatial = get_node("../Model/dilan_rig/Skeleton/FlameAttach/FlameHole")
onready var flame_effect:Area = flame_hole.get_child(0)
onready var flame_sound:AudioStreamPlayer = get_node("../FlameSound")


func _ready():
	flame_effect.monitoring = false
	
	var err:int = OK
	err += anim.connect("animation_finished", self, "_anim_finished")
	err += anim.connect("animation_started", self, "_anim_started")
	err += turn_control.connect("start_turn", self, "_on_turn_start")
	err += actor.connect("die", self, "_on_die")
	if err: printerr("!!! Signal error in dilan_attacks.gd")

func _on_die(_actor):
	flame_hole.queue_free() #Ensures enemies will not take damage from walking over the corpse

func _on_turn_start(_team, actor_:Actor):
	if actor == actor_:
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
