extends RefCounted
## Original low-poly scenery, batched by mesh/material with MultiMesh.
class Decor extends RefCounted:
	var root: Node3D
	var batches := {}

	func add(kind: String, at: Vector3, size: Vector3, colour: Color, solid := false, yaw := 0.0) -> void:
		var key := kind + colour.to_html()
		if not batches.has(key):
			var mesh: Mesh
			match kind:
				"crown", "hill":
					var sphere := SphereMesh.new()
					sphere.radial_segments = 9
					sphere.rings = 4
					sphere.radius = 0.5
					sphere.height = 1.0
					mesh = sphere
				"roof":
					var prism := PrismMesh.new()
					prism.size = Vector3.ONE
					mesh = prism
				"trunk":
					var cylinder := CylinderMesh.new()
					cylinder.radial_segments = 7
					cylinder.top_radius = 0.4
					cylinder.bottom_radius = 0.5
					cylinder.height = 1.0
					mesh = cylinder
				_:
					var box := BoxMesh.new()
					box.size = Vector3.ONE
					mesh = box
			var material := StandardMaterial3D.new()
			material.albedo_color = colour
			material.roughness = 0.95
			if kind == "glow":
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mesh.surface_set_material(0, material)
			batches[key] = {"mesh": mesh, "transforms": []}
		batches[key].transforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(size), at))
		if solid:
			var body := StaticBody3D.new()
			body.position = at
			body.rotation.y = yaw
			var cs := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = size
			cs.shape = shape
			body.add_child(cs)
			root.add_child(body)

	func finish() -> void:
		for batch in batches.values():
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = batch.mesh
			mm.instance_count = batch.transforms.size()
			for index in batch.transforms.size():
				mm.set_instance_transform(index, batch.transforms[index])
			var instance := MultiMeshInstance3D.new()
			instance.multimesh = mm
			root.add_child(instance)

static func build(root: Node3D, lv: Dictionary) -> void:
	var builder := Decor.new()
	builder.root = root
	var half := Vector2(float(lv.size[0]), float(lv.size[1])) * 1.25
	var id: int = int(lv.id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 67218 + id
	var seaside: bool = id in [3, 7]
	var night: bool = id in [5, 6]
	# A credible sidewalk and street just outside the closed playable boundary.
	builder.add("box", Vector3(0, -0.03, half.y + 4), Vector3(half.x * 2 + 14, 0.1, 7), Color("b6b7a5"))
	builder.add("box", Vector3(0, -0.04, half.y + 10), Vector3(half.x * 2 + 40, 0.1, 5), Color("445c63"))
	for i in 13:
		builder.add("box", Vector3((i - 6) * 5, 0.03, half.y + 10), Vector3(2.5, 0.05, 0.12), Color("dbd7b9"))
	# Two rings of scenery, with a large open seafront on the north side.
	for i in 30:
		var angle := float(i) / 30.0 * TAU
		var radius := maxf(half.x, half.y) + rng.randf_range(16, 30)
		var pos := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		if seaside and pos.z < -half.y:
			continue
		if id in [1, 3] or (id == 7 and i % 2 == 0):
			builder.add("trunk", pos + Vector3.UP * 2.3, Vector3(0.65, 4.6, 0.65), Color("86684c"), true)
			if seaside:
				for leaf in 5:
					var yaw := leaf * TAU / 5.0
					var spread := Vector3(sin(yaw) * 1.3, 4.7, cos(yaw) * 1.3)
					builder.add("box", pos + spread, Vector3(0.8, 0.2, 4.2), Color("428b68"), false, yaw)
			else:
				builder.add("crown", pos + Vector3.UP * 5.0, Vector3(5.5, 5.0, 5.0), Color("4b8865"))
				builder.add("crown", pos + Vector3(1, 6, 0), Vector3(3.7, 3.5, 3.7), Color("68a17a"))
			if id == 1 and i % 3 == 0:
				var house := pos + Vector3(8, 0, 4)
				builder.add("box", house + Vector3.UP * 2, Vector3(6, 4, 6), Color("d6bd98"), true)
				builder.add("roof", house + Vector3.UP * 4.9, Vector3(7, 2, 7), Color("b47961"))
				builder.add("box", house + Vector3(0, 1.2, 3.03), Vector3(1.1, 2.4, 0.15), Color("44676d"))
		else:
			var height := rng.randf_range(7, 22) if night else rng.randf_range(5, 11)
			var colour: Color = [Color("768d8e"), Color("b19e87"), Color("63828b")][i % 3]
			builder.add("box", pos + Vector3.UP * height * 0.5, Vector3(7, height, 7), colour, true)
			builder.add("box", pos + Vector3.UP * (height + 0.2), Vector3(7.5, 0.4, 7.5), colour.darkened(0.15))
			for row in int(height / 2.7):
				for column in 3:
					builder.add("glow" if night else "box", pos + Vector3((column - 1) * 1.9, 2 + row * 2.5, 3.53), Vector3(0.9, 1.3, 0.08), Color("f4cf8a") if night else Color("bdd9cc"))
	# Hills in the distance, not single-colour empty horizon.
	for i in 16:
		var angle := i * TAU / 16.0
		if seaside and sin(angle) < -0.2:
			continue
		var radius := 100.0
		builder.add("hill", Vector3(cos(angle) * radius, 3, sin(angle) * radius), Vector3(55, 25 + i % 3 * 8, 45), Color("517f76") if not night else Color("344b62"))
	# Lamps, parked cars, and small stationary spectators outside the fence.
	for side in [-1.0, 1.0]:
		for i in 5:
			var at := Vector3(side * (half.x + 4), 0, (i - 2) * 10)
			builder.add("trunk", at + Vector3.UP * 3.5, Vector3(0.18, 7, 0.18), Color("335260"), true)
			builder.add("glow", at + Vector3.UP * 7, Vector3(1.1, 0.2, 1.1), Color("ffe2a2"))
			if night and i % 2 == 0:
				var lamp := OmniLight3D.new()
				lamp.position = at + Vector3.UP * 6
				lamp.light_color = Color("ffd6a1")
				lamp.light_energy = 1.0
				lamp.omni_range = 11
				root.add_child(lamp)
	for i in 4:
		var at := Vector3((i - 1.5) * 10, 0, half.y + 10)
		builder.add("box", at + Vector3.UP * 0.7, Vector3(3.7, 1.0, 1.8), Color("cd9970") if i % 2 == 0 else Color("729c9d"), true)
		builder.add("box", at + Vector3.UP * 1.4, Vector3(1.8, 0.65, 1.7), Color("abc8bd"))
		for sign_x in [-1.0, 1.0]:
			for sign_z in [-1.0, 1.0]:
				builder.add("crown", at + Vector3(sign_x * 1.15, 0.35, sign_z * 0.85), Vector3(0.7, 0.7, 0.3), Color("2d454e"))
		var person := Vector3((i - 1.5) * 6, 0, half.y + 3)
		builder.add("box", person + Vector3.UP * 0.9, Vector3(0.65, 1.1, 0.4), Color("deaa79"))
		builder.add("crown", person + Vector3.UP * 1.75, Vector3(0.5, 0.55, 0.5), Color("ecc59e"))
	if seaside:
		builder.add("box", Vector3(0, -0.2, -half.y - 65), Vector3(230, 0.25, 120), Color("397f95"))
		builder.add("box", Vector3(0, 0.01, -half.y - 7), Vector3(half.x * 2 + 10, 0.1, 12), Color("d7c296"))
		for i in 5:
			builder.add("box", Vector3(0, 0.2, -half.y - 12 - i * 3), Vector3(4, 0.35, 2.9), Color("9c896b"), true)
			builder.add("trunk", Vector3(1.5, -0.6, -half.y - 12 - i * 3), Vector3(0.3, 2, 0.3), Color("6b6d5a"), true)
	if id in [4, 7]:
		for i in 6:
			var at := Vector3(half.x + 9, 1.5, (i - 3) * 7)
			builder.add("box", at, Vector3(5, 3, 6), Color("b77958") if i % 2 == 0 else Color("477f88"), true)
			for rib in 8:
				builder.add("box", at + Vector3(-2.54, 0, (rib - 3.5) * 0.65), Vector3(0.08, 2.7, 0.08), Color("305865"))
		var crane := Vector3(-half.x - 23, 0, -half.y - 15)
		builder.add("box", crane + Vector3.UP * 14, Vector3(1.1, 28, 1.1), Color("d8ad66"), true)
		builder.add("box", crane + Vector3(8, 27, 0), Vector3(32, 1.0, 1.0), Color("d8ad66"))
		builder.add("box", crane + Vector3(21, 19, 0), Vector3(0.08, 15, 0.08), Color("365061"))
	if night:
		for i in 70:
			builder.add("glow", Vector3(rng.randf_range(-170, 170), rng.randf_range(45, 110), rng.randf_range(-150, -60)), Vector3.ONE * rng.randf_range(0.15, 0.4), Color("e6dfb7"))
	builder.finish()
