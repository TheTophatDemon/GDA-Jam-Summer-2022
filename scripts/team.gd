extends Node
class_name Team

signal deaths_processed()

var active_idx:int = 0 setget ,get_active_idx
var dont_advance:bool = false

func get_active_idx()->int:
	return active_idx

func get_next_idx()->int:
	return (active_idx + 1) % get_child_count()

func advance_active_idx():
	if dont_advance:
		active_idx %= get_child_count()
		dont_advance = false
	else:
		active_idx = get_next_idx()

func get_active_actor()->Actor:
	return get_child(active_idx) as Actor

func _ready():
	var err:int = OK
	for actor in get_children():
		err += actor.connect("dead", self, "_on_actor_dead", [actor])
	if err: printerr("!!! Signal error in team ", name)
	
func _on_actor_dead(actor:Actor):
	if actor.get_index() == get_next_idx():
		#This preserves the order of turns even when the next actor is removed from play
		dont_advance = true
	#Remove the actor from the team and place it into the world
	remove_child(actor)
	get_node("/root/World").add_child(actor)
	
func start_death_animations():
	for child in get_children():
		if child.health == 0:
			child.die()
			yield(child, "dead")
			yield(get_tree().create_timer(2.0), "timeout")
	emit_signal("deaths_processed")
