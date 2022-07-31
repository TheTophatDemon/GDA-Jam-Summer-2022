extends Label

onready var timer = $Timer

func _process(_delta):
	match int(ceil(timer.time_left)):
		2: text = "READY"
		1: text = "GO!"
		_: text = ""
