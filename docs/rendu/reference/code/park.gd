extends RefCounted
## Construit un parc de skate à partir d'une liste de pièces Kenney.
## Les positions du niveau sont en "tuiles" (1 tuile = K mètres).

const K := 2.5

# col : "ramp" (collision sans chute), "solid" (obstacle : chute si on le percute), "none" (visuel seulement)
# grind : segments [[x,y,z],[x,y,z]] en coordonnées locales de la pièce (avant échelle)
const PIECES := {
	"half-pipe": {"col": "ramp"}, "half-pipe-low": {"col": "ramp"},
	"slope-smooth": {"col": "ramp"}, "ramp": {"col": "ramp"},
	"steps": {"col": "ramp"}, "obstacle-box": {"col": "ramp"},
	"obstacle-middle": {"col": "ramp"}, "obstacle-corner": {"col": "ramp"},
	"obstacle-end": {"col": "ramp"}, "plank": {"col": "ramp"},
	"obstacle-box-grind": {"col": "ramp", "grind": [[[0, 0.21, -0.5], [0, 0.21, 0.5]]]},
	"obstacle-middle-rail": {"col": "ramp", "grind": [[[0, 0.55, -0.5], [0, 0.55, 0.5]]]},
	"bowl-side": {"col": "ramp"}, "bowl-side-low": {"col": "ramp"},
	"bowl-corner-inner": {"col": "ramp"}, "bowl-corner-inner-low": {"col": "ramp"},
	"bowl-corner-outer": {"col": "ramp"}, "bowl-corner-outer-low": {"col": "ramp"},
	"bowl-platform": {"col": "ramp"},
	"structure-wood": {"col": "ramp"}, "structure-wood-platform": {"col": "ramp"},
	"structure-platform": {"col": "ramp"},
	"bench": {"col": "solid"}, "benches": {"col": "solid"}, "pallet": {"col": "solid"},
	"vehicle": {"col": "solid"},
	"rail-low": {"col": "none", "grind": [[[0, 0.25, -0.5], [0, 0.25, 0.5]]]},
	"rail-low-end": {"col": "none", "grind": [[[0, 0.25, -0.5], [0, 0.25, 0.5]]]},
	"rail-high": {"col": "none", "grind": [[[0, 0.45, -0.5], [0, 0.45, 0.5]]]},
	"rail-slope": {"col": "none", "grind": [[[0, 0.45, -0.5], [0, 0.25, 0.5]]]},
	"rail-slope-smooth": {"col": "none", "grind": [[[0, 0.45, -0.5], [0, 0.25, 0.5]]]},
	"fence": {"col": "none"},
}

static var _scenes := {}


static func _scene(name: String) -> PackedScene:
	if not _scenes.has(name):
		_scenes[name] = load("res://models/%s.glb" % name)
	return _scenes[name]


static func _faces(n: Node, xf: Transform3D, out: PackedVector3Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var f: PackedVector3Array = (n as MeshInstance3D).mesh.get_faces()
		for p in f:
			out.append(xf * p)
	for c in n.get_children():
		if c is Node3D:
			_faces(c, xf * (c as Node3D).transform, out)


static func _first_mesh(n: Node) -> Mesh:
	if n is MeshInstance3D:
		return (n as MeshInstance3D).mesh
	for c in n.get_children():
		var m := _first_mesh(c)
		if m:
			return m
	return null


static func _body(root: Node3D, faces: PackedVector3Array, solid: bool, name: String) -> void:
	if faces.is_empty():
		return
	var body := StaticBody3D.new()
	body.name = name
	body.set_meta("solid", solid)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)


## Construit le parc dans `root`. Retourne {"grind": [...], "bounds": Vector2}.
static func build(root: Node3D, lv: Dictionary) -> Dictionary:
	var size: Array = lv["size"]
	var w: float = size[0]
	var d: float = size[1]
	var ramp_faces := PackedVector3Array()
	var solid_faces := PackedVector3Array()
	var grind: Array = []

	# --- sol : tuiles en MultiMesh + une grosse boîte de collision
	var floor_visual := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(w * K, 0.24, d * K)
	floor_visual.mesh = slab
	floor_visual.position.y = -0.12
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color("b9ad94") if lv.get("floor") == "wood" else Color("778b91")
	surface.roughness = 0.97
	floor_visual.material_override = surface
	root.add_child(floor_visual)

	var fb := StaticBody3D.new()
	var fcs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w * K + 40.0, 2.0, d * K + 40.0)
	fcs.shape = box
	fcs.position = Vector3(0, -1.0, 0)
	fb.add_child(fcs)
	root.add_child(fb)

	# grand sol extérieur (horizon)
	var outer := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 600)
	outer.mesh = pm
	var om := StandardMaterial3D.new()
	om.albedo_color = lv.get("outer", Color(0.45, 0.62, 0.4))
	om.roughness = 1.0
	outer.material_override = om
	outer.position = Vector3(0, -0.06, 0)
	root.add_child(outer)

	# --- clôture visuelle + murs invisibles
	var fence_scene := _scene("fence")
	for ix in int(w):
		var px := (ix - w / 2.0 + 0.5) * K
		for sgn in [-1.0, 1.0]:
			var f: Node3D = fence_scene.instantiate()
			root.add_child(f)
			f.transform = Transform3D(Basis(Vector3.UP, 0.0 if sgn < 0 else PI).scaled(Vector3.ONE * K), Vector3(px, 0, sgn * d / 2.0 * K))
	for iz in int(d):
		var pz := (iz - d / 2.0 + 0.5) * K
		for sgn in [-1.0, 1.0]:
			var f2: Node3D = fence_scene.instantiate()
			root.add_child(f2)
			f2.transform = Transform3D(Basis(Vector3.UP, PI / 2.0 if sgn < 0 else -PI / 2.0).scaled(Vector3.ONE * K), Vector3(sgn * w / 2.0 * K, 0, pz))
	var walls := StaticBody3D.new()
	walls.set_meta("solid", false)
	var half := Vector3(w * K / 2.0, 0, d * K / 2.0)
	var defs := [
		[Vector3(0, 10, -half.z - 1.0), Vector3(w * K + 4, 20, 2)],
		[Vector3(0, 10, half.z + 1.0), Vector3(w * K + 4, 20, 2)],
		[Vector3(-half.x - 1.0, 10, 0), Vector3(2, 20, d * K + 4)],
		[Vector3(half.x + 1.0, 10, 0), Vector3(2, 20, d * K + 4)],
	]
	for df in defs:
		var wcs := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		wb.size = df[1]
		wcs.shape = wb
		wcs.position = df[0]
		walls.add_child(wcs)
	root.add_child(walls)

	# --- pièces
	for e in lv["pieces"]:
		var name: String = e[0]
		var rot: float = e[3] if e.size() > 3 else 0.0
		var y: float = e[4] if e.size() > 4 else 0.0
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(rot)).scaled(Vector3.ONE * K), Vector3(float(e[1]) * K, y * K, float(e[2]) * K))
		var inst: Node3D = _scene(name).instantiate()
		root.add_child(inst)
		inst.transform = xf
		var info: Dictionary = PIECES.get(name, {"col": "ramp"})
		match info.get("col", "ramp"):
			"ramp":
				_faces(inst, xf, ramp_faces)
			"solid":
				var local_faces := PackedVector3Array()
				_faces(inst, Transform3D.IDENTITY, local_faces)
				var sb := StaticBody3D.new()
				sb.name = "Solid_" + name
				sb.transform = xf
				sb.set_meta("solid", true)
				sb.add_to_group("solid_obstacles")
				var collision := CollisionShape3D.new()
				var hull := ConvexPolygonShape3D.new()
				hull.points = local_faces
				collision.shape = hull
				sb.add_child(collision)
				root.add_child(sb)
		for seg in info.get("grind", []):
			var a: Vector3 = xf * Vector3(seg[0][0], seg[0][1], seg[0][2])
			var b: Vector3 = xf * Vector3(seg[1][0], seg[1][1], seg[1][2])
			grind.append(_seg(a, b))
	_body(root, ramp_faces, false, "Ramps")
	_body(root, solid_faces, true, "Solids")
	# fusionne les rails alignés bout à bout pour un grind continu
	grind = _merge(grind)
	preload("res://scenery.gd").build(root, lv)
	return {"grind": grind, "bounds": Vector2(w * K, d * K)}


static func _seg(a: Vector3, b: Vector3) -> Dictionary:
	var dir := (b - a)
	var len := dir.length()
	return {"a": a, "b": b, "dir": dir / maxf(len, 0.001), "len": len}


## Joint les segments dont une extrémité touche l'extrémité d'un autre (même direction).
static func _merge(segs: Array) -> Array:
	var out: Array = segs.duplicate()
	var changed := true
	while changed:
		changed = false
		for i in out.size():
			for j in out.size():
				if i == j:
					continue
				var s: Dictionary = out[i]
				var t: Dictionary = out[j]
				if s["b"].distance_to(t["a"]) < 0.15 and absf(s["dir"].dot(t["dir"])) > 0.97:
					out[i] = _seg(s["a"], t["b"])
					out.remove_at(j)
					changed = true
					break
			if changed:
				break
	return out
