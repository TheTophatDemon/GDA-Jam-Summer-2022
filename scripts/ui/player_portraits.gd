extends Control

const DEAD_TEXTURES = {
	"Dilan": preload("res://gfx/ui/portraits/dead_dilan_portrait.png"),
	"Rastera": preload("res://gfx/ui/portraits/dead_rastera_portrait.png"),
	"Ray": preload("res://gfx/ui/portraits/dead_ray_portrait.png")
}

onready var turn_control:TurnControl = get_parent()
onready var outline:TextureRect = $Dilan/Outline

func _ready():
	var err:int = OK
	err += turn_control.connect("transition", self, "_on_turn_transition")
	for player in turn_control.get_node("Teams/" + Globals.NAME_PLAYER_TEAM).get_children():
		err += player.connect("hurt", self, "_on_player_hurt", [player])
		err += player.connect("die", self, "_on_player_die")
		call_deferred("update_portrait_health", player)
	if err: printerr("!!! Signal error in player_portraits.gd")
	
func _on_player_hurt(_perp, actor:Actor):
	update_portrait_health(actor)
	
func _on_player_die(actor:Actor):
	var portrait:TextureRect = find_node(actor.name, false)
	if portrait != null:
		portrait.texture = DEAD_TEXTURES[actor.name]
	else:
		printerr("Portrait not found")
	
func update_portrait_health(actor:Actor):
	var portrait:Control = find_node(actor.name, false)
	if portrait != null:
		var label:Label = portrait.get_node("Health")
		label.text = "∧\n"
		for _i in range(actor.health):
			label.text += "♥" + "\n"
		for _i in range(actor.max_health - actor.health):
			label.text += "♡" + "\n"
		label.text += "∨"
	else:
		printerr("Portrait not found")
	
func _on_turn_transition(team:Team, actor:Actor):
	match team.name:
		Globals.NAME_PLAYER_TEAM:
			#Put the circle on the player whose turn it is
			var portrait:Control = find_node(actor.name, false)
			highlight_portrait(portrait)
		Globals.NAME_ENEMY_TEAM:
			#Put the circle on the player next in line
			var player_team:Team = turn_control.get_node("Teams/" + Globals.NAME_PLAYER_TEAM)
			var next_player_name:String = player_team.get_child(player_team.get_next_idx()).name
			highlight_portrait(find_node(next_player_name, false))

func highlight_portrait(portrait:Control):
	if portrait != null:
		outline.get_parent().remove_child(outline)
		portrait.add_child(outline)
		outline.rect_position = Vector2.ZERO
