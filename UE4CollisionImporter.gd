@tool
extends EditorScenePostImport
# UE4 Collision Converter
# Script to convert scenes made for Unreal collision to Godot by Andrew Palmer
# For usage, updates, etc. check Github:
#		https://github.com/andyp123/godot_UnrealCollisionImporter/

# Unreal uses the following prefixes, and optionally a numeric
# postfix for multiple colliders on a single object.
const SHAPE = {
	CONVEX = "UCX_",
	BOX = "UBX_",
	SPHERE = "USP_",
	CAPSULE = "UCP_"
}


func get_regex(object_name : String) -> RegEx:
	var s: String = ""
	for v in SHAPE.values():
		s += "(" + v + ")*"
	s += "_" + object_name + "(_{1}[0-9]{1,})?\\b"
	var regex = RegEx.new()
	regex.compile(s)
	return regex


func _post_import(scene):
	var path = get_source_file()
	
	print("Running post import script on file '{file}'".format({'file': path}))
	
	path = path.substr(0, path.rfind('/'));
	
	var objects = []
	var colliders = []
	
	# Sort objects from their colliders
	# Only meshes are supported
	for node in scene.get_children():
		if !(node is MeshInstance3D):
			continue

		var name : String = node.name
		if name.length() > 4:
			var pref = name.substr(0, 4)
			if pref in SHAPE.values():
				colliders.append(node)
				continue
		objects.append(node)

	# Organise objects in the scene
	for ob in objects:
		print(ob.name)
		var regex = get_regex(ob.name)
		for col in colliders:
			var result = regex.search(col.name)
			if result:
				print(" - ", col.name)
				add_collider(ob, col)
		
		# Save each object to a scene file
		var packed = PackedScene.new()
		packed.pack(ob)
		var scene_path = "{path}/{name}.scn".format({'path': path, 'name': ob.name})
		print(" -> ", scene_path)
		ResourceSaver.save(packed, scene_path)

	# Delete all the collider nodes
	for col in colliders:
		col.queue_free()

	# Scan for newly added files
	var plugin = EditorPlugin.new()
	plugin.get_editor_interface().get_resource_filesystem().scan()

	# Return the modified imported scene
	return scene


func add_collider(node : MeshInstance3D, collider : MeshInstance3D):
	# Ensure node has a static body
	var body : StaticBody3D = null
	for c in node.get_children():
		if c is StaticBody3D:
			body = c
			break
	if body == null:
		body = StaticBody3D.new()
		node.add_child(body)
		body.name = "StaticBody3D"
		body.owner = node

	# Figure out what type of collision to add, and attach it
	var pref = String(collider.name).substr(0, 4)
	if pref == SHAPE.BOX:
		add_box_collider(body, collider)
	elif pref == SHAPE.SPHERE:
		add_sphere_collider(body, collider)
	elif pref == SHAPE.CAPSULE:
		add_capsule_collider(body, collider)
	else: # SHAPE.CONVEX
		add_convex_collider(body, collider)


func add_convex_collider(body : StaticBody3D, collider: MeshInstance3D):
	var collision_shape = CollisionShape3D.new()
	var offset = collider.transform.origin - body.get_parent().transform.origin
	collision_shape.transform.origin = offset
	collision_shape.rotation = collider.rotation
	collision_shape.shape = collider.mesh.create_convex_shape()
	body.add_child(collision_shape)
	collision_shape.name = "ConvexShape"
	collision_shape.owner = body.owner


func add_box_collider(body : StaticBody3D, collider : MeshInstance3D):
	# AABB: size = full size (not half), position = min corner, end = max corner
	var aabb : AABB = collider.mesh.get_aabb()
	var box : BoxShape3D = BoxShape3D.new()
	box.extents = aabb.size * 0.5
	var collision_shape : CollisionShape3D = CollisionShape3D.new()
	var offset = collider.transform.origin - body.get_parent().transform.origin
	collision_shape.transform.origin = offset + aabb.position + box.extents
	collision_shape.rotation = collider.rotation
	collision_shape.shape = box
	body.add_child(collision_shape)
	collision_shape.name = "BoxShape"
	collision_shape.owner = body.owner


func add_sphere_collider(body : StaticBody3D, collider : MeshInstance3D):
	var aabb : AABB = collider.mesh.get_aabb()
	var sphere : SphereShape3D = SphereShape3D.new()
	sphere.radius = aabb.size.x * 0.5 # should be same on x, y and z
	var collision_shape : CollisionShape3D = CollisionShape3D.new()
	# No need to deal with rotation :)
	var offset = collider.transform.origin - body.get_parent().transform.origin
	collision_shape.transform.origin = offset + aabb.position + aabb.size * 0.5
	collision_shape.shape = sphere
	body.add_child(collision_shape)
	collision_shape.name = "SphereShape"
	collision_shape.owner = body.owner


func add_capsule_collider(body : StaticBody3D, collider : MeshInstance3D):
	var aabb : AABB = collider.mesh.get_aabb()
	var size : Vector3 = aabb.size
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	var collision_shape : CollisionShape3D = CollisionShape3D.new()
	var offset = collider.transform.origin - body.get_parent().transform.origin
	collision_shape.transform.origin = offset + aabb.position + size * 0.5
	# Use longest side to determine capsule orientation etc.
	# By default, z is the axis of the capsule's height
	# Need to fix rotation with Quaternions for sanity
	var rot : Quaternion = collider.transform.basis.get_rotation_quaternion()
	var average_length = (size.x + size.y + size.z) / 3
	if size.x > average_length:
		var r90 = Quaternion(Vector3(0, deg_to_rad(90), 0))
		collision_shape.transform.basis = Basis(rot * r90)
		capsule.height = size.x - size.y
		capsule.radius = size.y * 0.5
	elif size.y > average_length:
		var r90 = Quaternion(Vector3(deg_to_rad(90), 0, 0))
		collision_shape.transform.basis = Basis(rot * r90)
		capsule.height = size.y - size.x
		capsule.radius = size.x * 0.5
	else:
		collision_shape.rotation = collider.rotation
		capsule.height = size.z - size.x
		capsule.radius = size.x * 0.5
	collision_shape.shape = capsule
	body.add_child(collision_shape)
	collision_shape.name = "CapsuleShape"
	collision_shape.owner = body.owner

