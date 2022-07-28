extends Particles

onready var sound:AudioStreamPlayer = get_node_or_null("Sound")

func _ready():
	emitting = true
	one_shot = true

func _process(_delta):
	if not emitting and (sound == null or not sound.playing):
		queue_free()
