extends Node
class_name TurnControl

signal transition(team, actor)
signal start_turn(team, actor)
signal end_turn(team, actor)

onready var turn_timer = $TurnTime/Timer
onready var countdown_timer = $Countdown/Timer
onready var camera = get_node("../Camera")

enum State { TRANSITION, ACTION, RESULTS }

var turn_num:int = 0 #The sequence of turns
var turn:int = 0 #Index of the team that is taking the current turn
var state:int = State.TRANSITION setget set_state

func _ready():
	var err:int = OK
	err += countdown_timer.connect("timeout", self, "_on_countdown_timeout")
	err += turn_timer.connect("timeout", self, "_on_turn_timeout")
	if err: printerr("!!! Signal error in turn_control.gd")
	
	set_state(State.TRANSITION)

#Handles state transitions
func set_state(new_state:int):
	var team = $Teams.get_child(turn)
	match state:
		State.ACTION:
			emit_signal("end_turn", team, team.get_active_actor())
			turn_num += 1
	match new_state:
		State.RESULTS:
			#Wait for projectiles to destroy themselves
			for proj in get_tree().get_nodes_in_group(Globals.GROUP_PROJECTILES):
				yield(proj, "tree_exited")
			#Allow actors to die one by one
			start_death_sequence()
		State.TRANSITION:
			#Check victory condition
			if $Teams/EnemyTeam.get_child_count() == 0:
				var _err = get_tree().change_scene("res://scenes/win.tscn")
			elif $Teams/PlayerTeam.get_child_count() == 0:
				var _err = get_tree().change_scene("res://scenes/lose.tscn")
			else:
				if turn_num > 0:
					#Advance the turn
					turn = (turn + 1) % $Teams.get_child_count()
				team = $Teams.get_child(turn)
				if turn_num > 0: 
					#Go to next team member
					team.advance_active_idx()
				countdown_timer.start()
				emit_signal("transition", team, team.get_active_actor())
		State.ACTION:
			turn_timer.start()
			emit_signal("start_turn", team, team.get_active_actor())
	state = new_state

func _on_countdown_timeout():
	set_state(State.ACTION)
	
func _on_turn_timeout():
	set_state(State.RESULTS)

#Causes the current turn to end early
func skip_turn():
	if state == State.ACTION:
		turn_timer.stop()
		_on_turn_timeout()

func start_death_sequence():
	for actor in get_tree().get_nodes_in_group(Globals.GROUP_KILLABLE):
		if actor.health == 0:
			actor.call_deferred("die")
			yield(actor, "dead")
			yield(get_tree().create_timer(2.0), "timeout")
#	for team in $Teams.get_children():
#		team.call_deferred("start_death_animations")
#		yield(team, "deaths_processed")
	set_state(State.TRANSITION)
