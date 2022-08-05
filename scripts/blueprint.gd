extends Area

const NO_PLACE_COLOR:Color = Color(1.0, 0.0, 0.0, 0.5)
const PLACE_COLOR:Color = Color(0.5, 0.5, 1.0, 0.5)

export(SpatialMaterial) var blueprint_material:SpatialMaterial

var n_intersects = 0

func _ready():
	var err:int = OK
	err += connect("body_entered", self, "_on_body_entered")
	err += connect("body_exited", self, "_on_body_exited")
	if err: printerr("!!! Signal error in blueprint.gd")

func _on_body_entered(_body:CollisionObject):
	n_intersects += 1
	blueprint_material.albedo_color = NO_PLACE_COLOR

func _on_body_exited(_body:CollisionObject):
	n_intersects -= 1
	if n_intersects <= 0:
		blueprint_material.albedo_color = PLACE_COLOR

func can_place()->bool:
	return (n_intersects == 0)
