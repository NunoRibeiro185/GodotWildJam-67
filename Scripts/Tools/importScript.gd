@tool
extends  EditorScenePostImport

func _post_import(scene):
	iterate(scene)
	return scene
	
func iterate(node):
	if node != null:
		if node is MeshInstance3D:
			var body = StaticBody3D.new()
			var collision_shape = node.mesh.create_convex_shape()
			var shape = CollisionShape3D.new()
			shape.shape = collision_shape
			body.add_child(shape, true)
			node.add_child(body, true)
			body.set_collision_layer_value(1, true)
			body.set_collision_mask_value(1, true)
			body.set_collision_layer_value(2,true)
			body.set_collision_mask_value(2, true)
			
			body.owner = node.owner
			shape.owner = node.owner
	
		for child in node.get_children():
			iterate(child)
