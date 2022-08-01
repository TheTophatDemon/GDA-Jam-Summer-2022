extends KinematicBody

const BURN_MAT = preload("res://gfx/materials/ash.tres")
const DESTROY_EFFECT = preload("res://scenes/prefabs/effects/explosion_effect.tscn")

export(float) var speed = 10.0
export(NodePath) var mesh_path:NodePath = ""

onready var area:Area = $Area

var intersections:Array = []

var burn_material:SpatialMaterial = BURN_MAT.duplicate()
var burning = false
var burn_speed:float = 1.0

func _ready():
	var err:int = OK
	err = area.connect("body_entered", self, "_on_body_entered")
	err = area.connect("body_exited", self, "_on_body_exited")
	err = area.connect("area_entered", self, "_on_area_entered")
	if err: printerr("!!! Signal error in prop.gd")
	
func _on_body_entered(body:CollisionObject):
	if (body.collision_layer & Globals.LAYER_BIT_PLAYERS) > 0:
		intersections.push_back(body)
		
func _on_area_entered(o_area:CollisionObject):
	if (o_area.collision_layer & Globals.LAYER_BIT_HAZARDS) > 0:
		#Apply burn animation to mesh
		if not mesh_path.is_empty() and not burning:
			var mesh:MeshInstance = get_node(mesh_path)
			mesh.material_overlay = burn_material
			burn_material.albedo_color = Color.black
			burning = true
	
func _process(delta):
	if burning:
		burn_material.albedo_color.r += delta * burn_speed
		burn_material.albedo_color.g += delta * burn_speed
		burn_material.albedo_color.b += delta * burn_speed
		if burn_material.albedo_color.r > 0.99:
			var fx = DESTROY_EFFECT.instance()
			get_parent().add_child(fx)
			fx.global_transform.origin = global_transform.origin
			queue_free()
	
func _on_body_exited(body:CollisionObject):
	if (body.collision_layer & Globals.LAYER_BIT_PLAYERS) > 0:
		intersections.remove(intersections.find(body))
	
func _physics_process(_delta):
	var vel = Vector3.ZERO
	if intersections.size() > 0:
		var push:Vector3 = Vector3.ZERO
		for body in intersections:
			push += (global_transform.origin - body.global_transform.origin).normalized()
		push.y = 0.0
		vel = (push / intersections.size()).normalized() * speed
	var _new_vel = move_and_slide_with_snap(vel, Vector3.DOWN * 6.0)
	
#	n_intersections = 0
#	for i in range(get_slide_count()):
#		var col = get_slide_collision(i)
#		if (col.collider.collision_layer & Globals.LAYER_BIT_PLAYERS) > 0:
#			n_intersections += 1
#			push += (col.position - col.collider.global_transform.origin).normalized()
