extends Node

onready var start_butt = $StartButton

func _ready():
	var _err = start_butt.connect("pressed", self, "_on_start_press")
	
func _on_start_press():
	var _err = get_tree().change_scene("res://scenes/battle.tscn")
