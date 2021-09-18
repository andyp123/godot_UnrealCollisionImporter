tool
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
	s += "_" + object_name + "_[0-9]"
	var regex = RegEx.new()
	regex.compile(s)
	return regex


func post_import(scene):
	var objects = []
	var colliders = []
	
	# Sort objects from their colliders
	# Only meshes are supported
	for node in scene.get_children():
		if !(node is MeshInstance):
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
				add_collider(scene, ob, col)

	# Delete all the collider nodes
	for col in colliders:
		col.queue_free()

	# Return the modified imported scene
	return scene


func add_collider(scene: Node, node : MeshInstance, collider : MeshInstance):
	# Ensure node has a static body
	var body : StaticBody = null
	for c in node.get_children():
		if c is StaticBody:
			body = c
			break
	if body == null:
		body = StaticBody.new()
		node.add_child(body)
		body.set_owner(scene)

	# Figure out what type of collision to add, and attach it
	var pref = collider.name.substr(0, 4)
	if pref == SHAPE.BOX:
		add_box_collider(scene, body, collider)
	elif pref == SHAPE.SPHERE:
		add_sphere_collider(scene, body, collider)
	elif pref == SHAPE.CAPSULE:
		add_capsule_collider(scene, body, collider)
	else: # SHAPE.CONVEX
		add_convex_collider(scene, body, collider)


func add_convex_collider(scene: Node, body : StaticBody, collider: MeshInstance):
	var collision_shape = CollisionShape.new()
	var offset = collider.transform.origin - body.get_parent().transform.origin
	collision_shape.transform.origin = offset
	collision_shape.rotation = collider.rotation
	collision_shape.shape = collider.mesh.create_convex_shape()
	collision_shape.name = "ConvexShape"
	body.add_child(collision_shape)
	collision_shape.set_owner(scene)


func add_box_collider(scene : Node, body : StaticBody, collider : MeshInstance):
	# AABB: size = full size (not half), position = min corner, end = max corner
	var aabb : AABB = collider.mesh.get_aabb()
	var box : BoxShape = BoxShape.new()
	box.extents = aabb.size * 0.5
	var collision_shape : CollisionShape = CollisionShape.new()
	var offset = collider.transform.origin - body.get_parent().transform.origin
	collision_shape.transform.origin = offset + aabb.position + box.extents
	collision_shape.rotation = collider.rotation
	collision_shape.shape = box
	collision_shape.name = "BoxShape"
	body.add_child(collision_shape)
	collision_shape.set_owner(scene)


func add_sphere_collider(scene : Node, body : StaticBody, collider : MeshInstance):
	var aabb : AABB = collider.mesh.get_aabb()
	var sphere : SphereShape = SphereShape.new()
	sphere.radius = aabb.size.x * 0.5 # should be same on x, y and z
	var collision_shape : CollisionShape = CollisionShape.new()
	# No need to deal with rotation :)
	var offset = collider.transform.origin - body.get_parent().transform.origin
	collision_shape.transform.origin = offset + aabb.position + aabb.size * 0.5
	collision_shape.shape = sphere
	collision_shape.name = "SphereShape"
	body.add_child(collision_shape)
	collision_shape.set_owner(scene)


func add_capsule_collider(scene : Node, body : StaticBody, collider : MeshInstance):
	var aabb : AABB = collider.mesh.get_aabb()
	var size : Vector3 = aabb.size
	var capsule: CapsuleShape = CapsuleShape.new()
	var collision_shape : CollisionShape = CollisionShape.new()
	var offset = collider.transform.origin - body.get_parent().transform.origin
	collision_shape.transform.origin = offset + aabb.position + size * 0.5
	# Use longest side to determine capsule orientation etc.
	# By default, z is the axis of the capsule's height
	# Need to fix rotation with Quaternions for sanity
	var rot : Quat = collider.transform.basis.get_rotation_quat()
	var average_length = (size.x + size.y + size.z) / 3
	if size.x > average_length:
		var r90 = Quat(Vector3(0, deg2rad(90), 0))
		collision_shape.transform.basis = Basis(rot * r90)
		capsule.height = size.x - size.y
		capsule.radius = size.y * 0.5
	elif size.y > average_length:
		var r90 = Quat(Vector3(deg2rad(90), 0, 0))
		collision_shape.transform.basis = Basis(rot * r90)
		capsule.height = size.y - size.x
		capsule.radius = size.x * 0.5
	else:
		collision_shape.rotation = collider.rotation
		capsule.height = size.z - size.x
		capsule.radius = size.x * 0.5
	collision_shape.shape = capsule
	collision_shape.name = "CapsuleShape"
	body.add_child(collision_shape)
	collision_shape.set_owner(scene)

