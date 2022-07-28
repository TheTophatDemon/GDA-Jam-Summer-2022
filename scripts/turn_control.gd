extends Node
class_name TurnControl

signal activate_player(player)
signal activate_enemy(enemy)
signal turn_switch(actor)

onready var players = get_node("%AlivePlayers")
onready var enemies = get_node("%AliveEnemies")
onready var turn_timer_ui = $TurnTimer
onready var countdown_label = $Countdown
onready var countdown_timer = $Countdown/Timer
onready var navmesh:NavigationMeshInstance = get_node("../NavMesh")
onready var camera = get_node("../Camera")

var enemy_turn = false
var turn_timer = 0.0
var turn_time = 30.0
var turn_started = false
var transition_time = 2.0
var next_player = 0
var next_enemy = 0
var active_actor:Actor = null #Points to character currently moving in the turn

var end_timer = Timer.new()

func _ready():
	switch_turn()
	var _err
	_err = countdown_timer.connect("timeout", self, "start_turn")
	add_child(end_timer)
	end_timer.one_shot = true
	_err = end_timer.connect("timeout", self, "_on_game_end")

func start_turn():
	active_actor.activate()
	if active_actor.get_parent() == enemies:
		emit_signal("activate_enemy", active_actor)
	elif active_actor.get_parent() == players:
		emit_signal("activate_player", active_actor)
	else:
		print("Actor misplaced!")
	turn_started = true
	countdown_label.visible = false

func switch_turn():
	if players.get_child_count() <= 0 or enemies.get_child_count() <= 0:
		#Activate win/lose conditions
		turn_timer_ui.visible = false
		countdown_timer.stop()
		end_timer.start(2.0)
		camera.target_path = camera.temp_target_path
		emit_signal("turn_switch", null)
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
		turn_timer_ui.value = turn_timer_ui.max_value
		countdown_label.visible = true
	turn_started = false

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
		match int(ceil(countdown_timer.time_left)):
			2: countdown_label.text = "READY"
			1: countdown_label.text = "GO!"
			_: countdown_label.text = ""

func _on_game_end():
	if players.get_child_count() <= 0: 
		var _succ = get_tree().change_scene("res://scenes/lose.tscn")
	elif enemies.get_child_count() <= 0:
		var _succ = get_tree().change_scene("res://scenes/win.tscn")
