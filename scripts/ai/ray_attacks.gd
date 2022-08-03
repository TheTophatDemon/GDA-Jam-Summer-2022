extends Node

const SENTRY_PREFAB = preload("res://scenes/prefabs/attacks/sentry.tscn")

onready var actor:Actor = get_parent()
onready var anim:AnimationPlayer = get_node("../Model/AnimationPlayer")

onready var sentry_butt:TextureButton = get_node("../PlayerUI/SentryButt")
onready var build_butt:TextureButton = get_node("../PlayerUI/BuildButt")
onready var cancel_butt:TextureButton = get_node("../PlayerUI/CancelButt")

onready var sentry_place:Area = get_node("../SentryPlace")

var placing:bool = false

func _ready():
	var err:int = OK
	err += sentry_butt.connect("pressed", self, "_on_sentry_butt_pressed")
	err += build_butt.connect("pressed", self, "_on_build_butt_pressed")
	err += cancel_butt.connect("pressed", self, "_on_cancel_butt_pressed")
	err += get_node("/root/World/%TurnControl").connect("start_turn", self, "_on_start_turn")
	if err: printerr("!!! Signal error in ray_attacks.gd")
	
	sentry_place.visible = false
	
func _process(_delta):
	if placing:
		actor.move_input = Vector2.ZERO
		build_butt.visible = true
		cancel_butt.visible = true
		sentry_butt.visible = false
		sentry_place.visible = true
		
		build_butt.disabled = not sentry_place.can_place()
	else:
		sentry_butt.visible = true
		build_butt.visible = false
		cancel_butt.visible = false
		sentry_place.visible = false

func _on_sentry_butt_pressed():
	placing = true

func _on_build_butt_pressed():
	var sentry = SENTRY_PREFAB.instance()
	get_node("/root/World").add_child(sentry)
	sentry.global_transform = sentry_place.global_transform
	placing = false
	get_node("../PlaceSound").play()
	sentry_butt.disabled = true
	
func _on_cancel_butt_pressed():
	placing = false

func _on_start_turn(_team, actor_:Actor):
	sentry_place.visible = false
