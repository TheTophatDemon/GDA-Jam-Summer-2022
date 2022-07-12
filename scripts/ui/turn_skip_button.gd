extends TextureButton

onready var turn_control = get_node("../..")
onready var border = $Border

export var hold_time = 1.0
var hold_timer = 0.0
	
func _process(delta):
	if pressed:
		border.rect_scale.x = 1.0 + (1.0 - (hold_timer / hold_time))
		border.rect_scale.y = border.rect_scale.x
		hold_timer += delta
		if hold_timer > hold_time:
			turn_control.skip_turn()
			hold_timer = -INF
	else:
		hold_timer = 0.0
		border.rect_scale = Vector2.ONE
