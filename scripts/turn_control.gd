extends Node

signal activate_player(player)
signal activate_enemy(enemy)
signal turn_switch(actor)

onready var players = $Players
onready var enemies = $Enemies
onready var turn_timer_ui = $TurnTimer
onready var player_ui = $PlayerUI
onready var countdown_label = $TurnTimer/Countdown
onready var countdown_timer = $TurnTimer/Countdown/Timer

var enemy_turn = false
var turn_timer = 0.0
var turn_time = 30.0
var turn_started = false
var transition_time = 3.0
var next_player = 0
var next_enemy = 0
var active_actor:Spatial = null #Points to character currently moving in the turn

func _ready():
	switch_turn()
	countdown_timer.connect("timeout", self, "start_turn")

func start_turn():
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
	if enemy_turn:
		#Activate enemy...
		if enemies.get_child_count() > 0:
			var enemy:Spatial = enemies.get_child(next_enemy)
			active_actor = enemy
			emit_signal("turn_switch", enemy)
			#Mark next enemy
			next_enemy += 1
			if next_enemy >= enemies.get_child_count():
				next_enemy = 0
	else:
		#Activate player
		var player:Spatial = players.get_child(next_player)
		active_actor = player
		emit_signal("turn_switch", player)
		#Mark next player
		next_player += 1
		if next_player >= players.get_child_count():
			next_player = 0
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
