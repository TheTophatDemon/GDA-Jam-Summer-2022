extends Control

onready var anim = $Loading/AnimationPlayer
onready var ads = $Ads

func _ready():
	randomize()
	for child in ads.get_children():
		child.hide()
	anim.play("load")
	var _err = anim.connect("animation_finished", self, "_on_anim_finish")
	
func _on_anim_finish(_anim_name:String):
	ads.get_child(randi() % ads.get_child_count()).show()
