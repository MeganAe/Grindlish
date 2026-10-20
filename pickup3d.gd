extends Node3D
## Pièce ou lettre S-K-A-T-E à ramasser.

var kind := "coin"   # "coin" | "letter"
var idx := 0
var game: Node
var taken := false
var _t := 0.0
var _mesh: Node3D


func _ready() -> void:
	add_to_group("pickups")
	_t = randf() * 6.0
	if kind == "coin":
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.38
		cm.bottom_radius = 0.38
		cm.height = 0.1
		mi.mesh = cm
		mi.rotation.x = PI / 2.0
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1.0, 0.8, 0.15)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.65, 0.05)
		m.emission_energy_multiplier = 0.8
		m.metallic = 0.6
		m.roughness = 0.3
		mi.material_override = m
		_mesh = Node3D.new()
		_mesh.add_child(mi)
		add_child(_mesh)
	else:
		_mesh = Node3D.new()
		add_child(_mesh)
		# Label3D has a null-mesh destruction bug in Godot 4.3 dummy rendering.
		# Only omit its visual in headless tests; the same pickup Node and physics remain.
		if DisplayServer.get_name() == "headless":
			return
		var l := Label3D.new()
		l.text = "?" if kind == "decoy" else game.target_word[idx]
		l.font_size = 220
		l.pixel_size = 0.006
		l.outline_size = 48
		l.outline_modulate = Color(0.1, 0.05, 0.3)
		l.modulate = Color("b4e76a") if kind != "decoy" else Color("e9ad7f")
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = false
		l.shaded = false
		l.double_sided = true
		_mesh.add_child(l)



func _process(delta: float) -> void:
	_t += delta
	if kind == "coin":
		_mesh.rotation.y += delta * 3.0
	else:
		_mesh.position.y = sin(_t * 3.0) * 0.18
		_mesh.scale = Vector3.ONE * (1.0 + 0.06 * sin(_t * 6.0))


func collect() -> void:
	if taken or (game and not game.accept_pickup(kind, idx)):
		return
	taken = true
	remove_from_group("pickups")
	if game:
		game.on_pickup(kind, idx, global_position)
	queue_free()

func _exit_tree() -> void:
	for visual in find_children("*", "MeshInstance3D", true, false):
		visual.mesh = null
