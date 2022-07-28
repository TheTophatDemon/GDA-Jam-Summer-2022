extends Control

export var time:float = 2.0

func _ready():
	yield(get_tree().create_timer(time), "timeout")
	var _err = get_tree().change_scene("res://scenes/title.tscn")
