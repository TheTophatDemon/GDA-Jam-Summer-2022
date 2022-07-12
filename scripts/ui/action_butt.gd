extends TextureButton

export var action:String

func _ready():
	connect("button_down", self, "_on_button_down")
	connect("button_up", self, "_on_button_up")
	
func _on_button_down():
	Input.action_press(action)
	
func _on_button_up():
	Input.action_release(action)
