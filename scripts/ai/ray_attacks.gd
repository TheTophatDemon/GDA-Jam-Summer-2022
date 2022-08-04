extends Node

const SENTRY_PREFAB = preload("res://scenes/prefabs/attacks/sentry.tscn")

const UNLOAD_DISTANCE:float = 6.0
const UNLOAD_ARROW_HEIGHT:float = 7.0

onready var actor:Actor = get_parent()
onready var anim:AnimationPlayer = get_node("../Model/AnimationPlayer")

onready var sentry_butt:TextureButton = get_node("../PlayerUI/SentryButt")
onready var build_butt:TextureButton = get_node("../PlayerUI/BuildButt")
onready var cancel_butt:TextureButton = get_node("../PlayerUI/CancelButt")
onready var unload_butt:TextureButton = get_node("../PlayerUI/UnloadButt")

onready var unload_arrow:MeshInstance = get_node("../UnloadArrow")
onready var sentry_place:Area = get_node("../SentryPlace")

var active_sentries = []

var placing:bool = false
var sentries_left:int = 1

var nearest_sentry:Spatial = null
var nearest_sentry_dist:float = 10000.0

func _ready():
	var err:int = OK
	err += sentry_butt.connect("pressed", self, "_on_sentry_butt_pressed")
	err += build_butt.connect("pressed", self, "_on_build_butt_pressed")
	err += cancel_butt.connect("pressed", self, "_on_cancel_butt_pressed")
	err += unload_butt.connect("pressed", self, "_on_unload_butt_pressed")
	err += get_node("/root/World/%TurnControl").connect("start_turn", self, "_on_start_turn")
	if err: printerr("!!! Signal error in ray_attacks.gd")
	
	sentry_place.visible = false
	unload_arrow.visible = false
	
func _process(_delta):
	if placing:
		actor.move_input = Vector2.ZERO
		build_butt.visible = true
		cancel_butt.visible = true
		sentry_butt.visible = false
		sentry_place.visible = true
		unload_butt.visible = false
		
		build_butt.disabled = not sentry_place.can_place()
	else:
		sentry_butt.visible = true
		if sentries_left <= 0 or actor.actions_left == 0:
			sentry_butt.disabled = true
		else:
			sentry_butt.disabled = false
		build_butt.visible = false
		cancel_butt.visible = false
		sentry_place.visible = false
		unload_butt.visible = true
		
		#Mark nearest sentry for potential unloading
		nearest_sentry = null
		nearest_sentry_dist = 10000.0
		for sentry in active_sentries:
			var dist:float = (sentry.global_transform.origin - actor.global_transform.origin).length()
			if dist < nearest_sentry_dist:
				nearest_sentry = sentry
				nearest_sentry_dist = dist
		if is_instance_valid(nearest_sentry) and nearest_sentry_dist < UNLOAD_DISTANCE:
			unload_butt.disabled = false
			unload_arrow.visible = true
			unload_arrow.global_transform.origin = nearest_sentry.transform.origin
			unload_arrow.global_transform.origin.y += UNLOAD_ARROW_HEIGHT
			unload_arrow.get_node("AnimationPlayer").play("spin")
		else:
			unload_butt.disabled = true
			unload_arrow.visible = false

func _on_sentry_butt_pressed():
	placing = true
	get_node("../BuildSound").play()

func _on_build_butt_pressed():
	var sentry = SENTRY_PREFAB.instance()
	get_node("/root/World").add_child(sentry)
	sentry.global_transform = sentry_place.global_transform
	placing = false
	active_sentries.push_back(sentry)
	var _err = sentry.connect("die", self, "_on_sentry_die")
	_err = sentry.connect("hurt", self, "_on_sentry_hurt")
	get_node("../PlaceSound").play()
	sentries_left -= 1
	actor.expend_action()
	
func _on_cancel_butt_pressed():
	placing = false
	
func _on_unload_butt_pressed():
	active_sentries.remove(active_sentries.find(nearest_sentry))
	sentries_left += 1
	nearest_sentry.queue_free()
	get_node("../UnloadSound").play()

func _on_start_turn(_team, actor_:Actor):
	sentry_place.visible = false
	unload_arrow.visible = false

func _on_sentry_hurt(perp):
	if perp.get_parent().name == Globals.NAME_PLAYER_TEAM and not actor.died:
		get_node("../BetrayalSound").play()

func _on_sentry_die(sentry):
	sentries_left += 1
	var idx = active_sentries.find(sentry)
	if idx >= 0:
		active_sentries.remove(idx)
	else:
		print("Unowned sentry?")
