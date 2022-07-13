extends TextureButton

export var left_action:String
export var right_action:String
export var up_action:String
export var down_action:String
	
func _process(_delta):
	if pressed:
		var offset:Vector2 = (2.0 * (get_viewport().get_mouse_position() - rect_global_position) / rect_size) - Vector2.ONE
		if not is_zero_approx(offset.length_squared()): offset = offset.normalized()
		if offset.x < 0.0:
			Input.action_press(left_action, abs(offset.x))
			Input.action_release(right_action)
		elif offset.x > 0.0:
			Input.action_press(right_action, offset.x)
			Input.action_release(left_action)
		if offset.y < 0.0:
			Input.action_press(up_action, abs(offset.y))
			Input.action_release(down_action)
		elif offset.y > 0.0:
			Input.action_press(down_action, offset.y)
			Input.action_release(up_action)
	else:
		Input.action_release(up_action)
		Input.action_release(down_action)
		Input.action_release(left_action)
		Input.action_release(right_action)
	
