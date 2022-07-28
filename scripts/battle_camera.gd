extends Camera

export var move_speed:float = 75.0
var target_path:NodePath
var temp_target_path:NodePath

var offset:Vector3 = Vector3(0.0, 28.0, 14.0)
var target_pos:Vector3

func _ready():
	var _err
	_err = get_node("%TurnControl").connect("turn_switch", self, "set_target")
	for player in get_node("%AlivePlayers").get_children():
		_err = player.connect("hurt", self, "_on_actor_hurt", [player])
		_err = player.connect("die", self, "_on_actor_hurt", [player])
		_err = player.connect("shoot", self, "_on_actor_shoot")
	for enemy in get_node("%AliveEnemies").get_children():
		_err = enemy.connect("hurt", self, "_on_actor_hurt", [enemy])
		_err = enemy.connect("die", self, "_on_actor_hurt", [enemy])
		_err = enemy.connect("shoot", self, "_on_actor_shoot")

func _on_actor_shoot(shot, _actor):
	temp_target_path = get_path_to(shot)

func _on_actor_hurt(_perpetrator, actor):
	if actor.health <= 0:
		if actor is Player: temp_target_path = "%DeadPlayers/" + actor.name
		elif actor is Enemy: temp_target_path = "%DeadEnemies/" + actor.name
	else:
		temp_target_path = get_path_to(actor)
	#Temporarily look at the hurt actor
	yield(get_tree().create_timer(2.0), "timeout")
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
		else:
			global_transform.origin = target_pos
			look_at(node.global_transform.origin, Vector3.UP)
