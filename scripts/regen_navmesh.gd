extends NavigationMeshInstance

onready var turn_control = get_node("%TurnControl")

func _ready():
	var err:int = OK
	err += turn_control.connect("transition", self, "_on_turn_transition")
	if err: printerr("!!! Signal error in regen_navmesh.gd")
	
func _on_turn_transition(team:Spatial, actor:Spatial):
	if team == turn_control.get_node("Teams/EnemyTeam"):
		for enemy in team.get_children():
			if enemy == actor:
				if enemy.is_in_group(Globals.GROUP_NAVMESH):
					enemy.remove_from_group(Globals.GROUP_NAVMESH)
			else:
				enemy.add_to_group(Globals.GROUP_NAVMESH)
	bake_navigation_mesh()
