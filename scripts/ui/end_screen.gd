extends Control

export var time:float = 2.0

onready var stars_anim = get_node_or_null("Stars/AnimationPlayer")

func _ready():
	var _err = get_tree().create_timer(time).connect("timeout", self, "_on_end")
	if stars_anim != null:
		stars_anim.play("%sstar" % Globals.stars_number)
		if Globals.stars_number == 3:
			$WinMusic.play()
			$ViewportContainer/Viewport/World/StrobePlayer.play("strobe")
	
func _on_end():
	var _err = get_tree().change_scene("res://scenes/title.tscn")
