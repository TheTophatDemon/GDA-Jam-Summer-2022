extends Button

export(PackedScene) var destination

func _ready():
	var _err = connect("pressed", self, "_on_button_press")

func _on_button_press():
	var _err = get_tree().change_scene_to(destination)
