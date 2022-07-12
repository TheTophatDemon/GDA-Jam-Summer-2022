extends Node

signal activate_player(player)
signal activate_enemy(enemy)

onready var players = $Players
onready var enemies = $Enemies
onready var turn_timer_ui = $TurnTimer
onready var player_ui = $PlayerUI

var enemy_turn = false
var turn_timer = 0.0
var turn_time = 30.0
var next_player = 0
var next_enemy = 0

func _ready():
	start_turn()

func start_turn():
	if enemy_turn:
		player_ui.visible = false
		#Activate enemy...
		if enemies.get_child_count() > 0:
			var enemy:Spatial = enemies.get_child(next_enemy)
			#players.player_path = players.get_path_to(enemy)
			#camera.target_path = camera.get_path_to(enemy)
			emit_signal("activate_enemy", enemy)
			#Mark next enemy
			next_enemy += 1
			if next_enemy >= enemies.get_child_count():
				next_enemy = 0
	else:
		player_ui.visible = true
		#Activate player
		var player:Spatial = players.get_child(next_player)
		#players.player_path = players.get_path_to(player)
		#camera.target_path = camera.get_path_to(player)
		emit_signal("activate_player", player)
		#Mark next player
		next_player += 1
		if next_player >= players.get_child_count():
			next_player = 0
	enemy_turn = not enemy_turn

func skip_turn():
	turn_timer = turn_time

func _process(delta):
	turn_timer += delta
	turn_timer_ui.value = turn_timer / turn_time
	if turn_timer > turn_time:
		start_turn()
		turn_timer = 0.0
