extends Camera

signal target_reached(target_node)

onready var turn_control = get_node("/root/World/%TurnControl")

export var move_speed:float = 75.0
var target_path:NodePath
var temp_target_path:NodePath

var offset:Vector3 = Vector3(0.0, 28.0, 14.0)
var target_pos:Vector3

var at_target:bool = false

func _ready():
	var err:int = OK
	err += turn_control.connect("transition", self, "_on_turn_transition")
	for player in turn_control.get_node("Teams/PlayerTeam").get_children():
		err += player.connect("hurt", self, "_on_actor_hurt", [player])
		err += player.connect("die", self, "_on_actor_hurt", [player])
		err += player.connect("shoot", self, "_on_actor_shoot")
	for enemy in turn_control.get_node("Teams/EnemyTeam").get_children():
		err += enemy.connect("hurt", self, "_on_actor_hurt", [enemy])
		err += enemy.connect("die", self, "_on_actor_hurt", [enemy])
		err += enemy.connect("shoot", self, "_on_actor_shoot")
	if err: printerr("!!! Signal error in battle_camera.gd")

func _on_actor_shoot(shot, _actor):
	temp_target_path = get_path_to(shot)

func _on_actor_hurt(_perpetrator, actor):
	temp_target_path = get_path_to(actor)
	#Temporarily look at the hurt actor
	yield(get_tree().create_timer(2.0), "timeout")
	temp_target_path = ""

func _on_turn_transition(_team, actor:Spatial):
	set_target(actor)
	temp_target_path = ""

func set_target(node:Spatial):
	if is_instance_valid(node): target_path = get_path_to(node)

func _process(delta):
	var node:Spatial = null
	if not temp_target_path.is_empty():
		node = get_node_or_null(temp_target_path)
		if node == null: temp_target_path = ""
	if temp_target_path.is_empty() and not target_path.is_empty():
		node = get_node_or_null(target_path)
	if is_instance_valid(node):
		target_pos = node.global_transform.origin + offset
		var move_diff = target_pos - global_transform.origin
		var move_dist = move_diff.length()
		var move_amount = delta * move_speed
		if move_dist > move_amount:
			var move_dir = move_diff / move_dist
			global_translate(move_dir * move_amount)
			at_target = false
		else:
			global_transform.origin = target_pos
			look_at(node.global_transform.origin, Vector3.UP)
			if not at_target:
				emit_signal("target_reached", node)
			at_target = true
