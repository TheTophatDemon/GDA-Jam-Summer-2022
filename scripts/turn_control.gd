extends Node
class_name TurnControl

signal activate_player(player)
signal activate_enemy(enemy)
signal turn_switch(actor)

onready var players = get_node("%AlivePlayers")
onready var enemies = get_node("%AliveEnemies")
onready var turn_timer_ui = $TurnTimer
onready var player_ui = $PlayerUI
onready var countdown_label = $TurnTimer/Countdown
onready var countdown_timer = $TurnTimer/Countdown/Timer
onready var navmesh:NavigationMeshInstance = get_node("../NavMesh")
onready var camera = get_node("../Camera")

var enemy_turn = false
var turn_timer = 0.0
var turn_time = 30.0
var turn_started = false
var transition_time = 3.0
var next_player = 0
var next_enemy = 0
var active_actor:Actor = null #Points to character currently moving in the turn

func _ready():
	switch_turn()
	var _err
	_err = countdown_timer.connect("timeout", self, "start_turn")

func start_turn():
	active_actor.activate()
	if active_actor.get_parent() == enemies:
		emit_signal("activate_enemy", active_actor)
	elif active_actor.get_parent() == players:
		emit_signal("activate_player", active_actor)
		player_ui.visible = true
	else:
		print("Actor misplaced!")
	turn_started = true
	countdown_label.visible = false

func switch_turn():
	if players.get_child_count() <= 0 or enemies.get_child_count() <= 0:
		#Activate win/lose conditions
		player_ui.visible = false
		turn_timer_ui.visible = false
		countdown_timer.stop()
		camera.target_path = camera.temp_target_path
		yield(get_tree().create_timer(2.0), "timeout")
		if players.get_child_count() <= 0: get_tree().change_scene("res://scenes/lose.tscn")
	else:
		if enemy_turn:
			#Activate enemy...
			#Add enemies to be baked into navmesh. Active enemy will be removed later.
			for enemy in enemies.get_children():
				enemy.add_to_group(Globals.NAVMESH_GROUP)
			if enemies.get_child_count() > 0:
				if next_enemy >= enemies.get_child_count():
					next_enemy = 0
				var enemy:Spatial = enemies.get_child(next_enemy)
				active_actor = enemy
				enemy.remove_from_group(Globals.NAVMESH_GROUP)
				emit_signal("turn_switch", enemy)
				#Mark next enemy
				next_enemy += 1
			navmesh.bake_navigation_mesh()
		else:
			#Activate player
			if next_player >= players.get_child_count():
				next_player = 0
			var player:Spatial = players.get_child(next_player)
			active_actor = player
			emit_signal("turn_switch", player)
			#Mark next player
			next_player += 1
		enemy_turn = not enemy_turn
		countdown_timer.wait_time = transition_time
		countdown_timer.start()
		turn_started = false
		turn_timer_ui.value = turn_timer_ui.max_value
		player_ui.visible = false
		countdown_label.visible = true

func skip_turn():
	turn_timer = turn_time

func _process(delta):
	if turn_started:
		turn_timer += delta
		turn_timer_ui.value = turn_timer / turn_time
		if turn_timer > turn_time:
			switch_turn()
			turn_timer = 0.0
	else:
		countdown_label.text = str(ceil(countdown_timer.time_left))
