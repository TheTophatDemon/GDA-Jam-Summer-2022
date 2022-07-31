extends TextureProgress

onready var timer = $Timer

func _process(_delta):
	value = 1.0 - (timer.time_left / timer.wait_time)
