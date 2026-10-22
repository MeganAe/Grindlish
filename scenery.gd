extends RefCounted
## Original low-poly scenery, batched by mesh/material with MultiMesh.
class Decor extends RefCounted:
	var root: Node3D
	var batches := {}
	var obstacles: Array = []

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
				"trunk", "cone", "peak":
					var cylinder := CylinderMesh.new()
					cylinder.radial_segments = 5 if kind=="peak" else 7
					cylinder.top_radius = 0.0 if kind in ["cone","peak"] else 0.4
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
			batches[key] = {"mesh": mesh, "transforms": [], "kind": kind}
		batches[key].transforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(size), at))
		if solid:
			obstacles.append(AABB(at - size * 0.5, size))
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
			instance.set_meta("decor_kind",batch.kind)

			root.add_child(instance)

static func _house(b: Decor, at: Vector3, wall: Color, alpine := false) -> void:
	b.add("box", at + Vector3.UP * 3, Vector3(9, 6, 7), wall, true)
	b.add("roof", at + Vector3.UP * 7.2, Vector3(10.5, 3.3, 8.5), Color("e4eef3") if alpine else Color("c75e43"))
	for x in [-2.5, 2.5]:
		b.add("box", at + Vector3(x, 3.7, 3.55), Vector3(1.5, 1.7, 0.15), Color("a9daea"))
	b.add("box", at + Vector3(0, 1.4, 3.55), Vector3(1.5, 2.8, 0.2), Color("36566b"))

	if alpine:
		b.add("box",at+Vector3(0,2.5,4.2),Vector3(7,.35,2),Color("8c654c"),true)
		b.add("box",at+Vector3(0,3.4,5.1),Vector3(7,.3,.2),Color("8c654c"))
		for x in [-3,-1,1,3]:
			b.add("box",at+Vector3(x,2.9,5.1),Vector3(.16,1,.16),Color("8c654c"))

static func _peak(b: Decor, at: Vector3, height: float, width: float) -> void:
	b.add("peak",at+Vector3.UP*height*.5,Vector3(width,height,width),Color("7391aa"))
	b.add("peak",at+Vector3.UP*(height*.8+.08),Vector3(width*.407,height*.4,width*.407),Color("e0edf2"))

static func _tree(b: Decor, at: Vector3, conifer := false) -> void:
	b.add("trunk", at + Vector3.UP * 2.5, Vector3(0.8, 5, 0.8), Color("825339"), true)
	if conifer:
		for j in 3:
			b.add("cone", at + Vector3.UP * (4.0 + j * 1.5), Vector3(5.5 - j, 4, 5.5 - j), Color("32765a"))
	else:
		b.add("crown", at + Vector3.UP * 6, Vector3(6, 5, 6), Color("4d9d65"))
		b.add("crown", at + Vector3(1, 7.5, 0), Vector3(4, 3, 4), Color("7ebc65"))

static func build(root: Node3D, lv: Dictionary) -> void:
	var b := Decor.new()
	b.root = root
	var h := Vector2(float(lv.size[0]), float(lv.size[1])) * 1.25
	var id: int = lv.id
	var kind: String = preload("res://worlds.gd").profile(id).kind
	# Reserved pedestrian and traffic rings: offset 5 and 14 metres.
	# No solid is placed in these lanes. Every world has its own architecture.
	for side in [-1.0, 1.0]:
		b.add("box", Vector3(side * (h.x + 4.5), -0.055, 0), Vector3(8, 0.1, h.y * 2 + 16), Color("d6d4bd"))
		b.add("box", Vector3(0, -0.055, side * (h.y + 4.5)), Vector3(h.x * 2 + 16, 0.1, 8), Color("d6d4bd"))
		if id not in [3, 7, 9]:
			b.add("box", Vector3(side * (h.x + 14), -0.06, 0), Vector3(9, 0.1, h.y * 2 + 36), Color("415b65"))
			b.add("box", Vector3(0, -0.06, side * (h.y + 14)), Vector3(h.x * 2 + 36, 0.1, 9), Color("415b65"))
			for j in 9:
				b.add("box", Vector3((j-4)*7, 0.005, side*(h.y+14)), Vector3(3, 0.025, 0.15), Color("e8dd9c"))
		for j in 4:
			var lamp := Vector3(side * (h.x + 8), 0, (j - 1.5) * 13)
			b.add("trunk", lamp + Vector3.UP * 3.4, Vector3(0.17, 6.8, 0.17), Color("345468"), true)
			b.add("glow", lamp + Vector3.UP * 6.8, Vector3(1.2, 0.15, 1.2), Color("fff0af"))
	match kind:
		"suburb":
			for j in 5:
				_house(b, Vector3((j-2)*14, 0, -h.y-30), [Color("edbd73"),Color("df9279"),Color("9acba1")][j%3])
			for side in [-1,1]:
				for j in 6:
					_tree(b, Vector3(side*(h.x+22),0,(j-2.5)*14))
			for j in 6:
				b.add("hill", Vector3((j-2.5)*32, 7, -110), Vector3(52,28+j%2*8,38), Color("4b9465"))
		"plaza":
			for j in 7:
				var at := Vector3((j-3)*14,0,-h.y-32)
				var colour: Color = [Color("d78d69"),Color("8babc0"),Color("d5b779")][j%3]
				b.add("box",at+Vector3.UP*9,Vector3(12,18+j%2*5,10),colour,true)
				b.add("box",at+Vector3(0,3,5.6),Vector3(12.8,0.5,3),Color("c74b4b"))
				for x in [-3,0,3]:
					for y in [5,9,13]:
						b.add("box",at+Vector3(x,y,5.08),Vector3(1.6,2,0.15),Color("b6e1e4"))
					b.add("trunk",at+Vector3(x,1.7,6.7),Vector3(.35,3.4,.35),Color("e6c998"),true)
			# Raised fountain/monument beyond traffic, not in a walking lane.
			b.add("trunk",Vector3(h.x+30,0.4,0),Vector3(12,.8,12),Color("74acbc"),true)
			b.add("trunk",Vector3(h.x+30,3,0),Vector3(.7,5.2,.7),Color("88d1de"))
			b.add("crown",Vector3(h.x+30,5.6,0),Vector3(2,2,2),Color("f3c762"))
		"beach":
			b.add("box",Vector3(0,-.18,-h.y-80),Vector3(310,.3,150),Color("258eaf"))
			b.add("box",Vector3(0,-.025,-h.y-14),Vector3(180,.04,26),Color("d7b56f"))
			for j in 7:
				var at := Vector3((j-3)*16,0,-h.y-28)
				b.add("trunk",at+Vector3.UP*4,Vector3(.65,8,.65),Color("ab794a"),true)
				for leaf in 6:
					var a := leaf*TAU/6
					b.add("box",at+Vector3(sin(a)*2,8,cos(a)*2),Vector3(.8,.25,6),Color("31936a"),false,a)
			b.add("box",Vector3(0,.3,-h.y-26),Vector3(5,.6,28),Color("b17c4e"),true)
			for j in 5:
				b.add("trunk",Vector3(2,-.3,-h.y-16-j*5),Vector3(.4,3,.4),Color("765645"),true)
			_house(b,Vector3(h.x+30,0,8),Color("e7b661"))
		"factory":
			for j in 3:
				var at := Vector3((j-1)*26,0,-h.y-34)
				b.add("box",at+Vector3.UP*6,Vector3(24,12,15),Color("ac6650"),true)
				for tooth in 4:
					b.add("roof",at+Vector3((tooth-1.5)*6,13,0),Vector3(6,4,16),Color("5c7d89"))
				for x in [-7,0,7]:
					b.add("box",at+Vector3(x,5,7.6),Vector3(3,5,.2),Color("e7bc69"))
			for side in [-1,1]:
				for j in 3:
					b.add("trunk",Vector3(side*(h.x+28),7,(j-1)*17),Vector3(10,14,10),Color("aac0bf"),true)
			b.add("trunk",Vector3(-18,19,-h.y-39),Vector3(3.2,38,3.2),Color("c97e4d"),true)
			b.add("box",Vector3(h.x+30,14,-8),Vector3(2,28,2),Color("f3b848"),true)
			b.add("box",Vector3(h.x+25,27,-8),Vector3(25,1.5,2),Color("f3b848"))
		"garden":
			for side in [-1,1]:
				for j in 8:
					_tree(b,Vector3(side*(h.x+26+j%2*7),0,(j-3.5)*14),true)
			for j in 7:
				_tree(b,Vector3((j-3)*16,0,-h.y-30),true)
				b.add("glow",Vector3((j-3)*12,1.4,-h.y-22),Vector3(.45,.5,.45),Color("d5f586"))
			b.add("box",Vector3(h.x+33,.05,0),Vector3(15,.12,25),Color("3b8eaa"))
			b.add("glow",Vector3(-34,43,-110),Vector3(9,9,1),Color("fff0c4"))
			for j in 35:
				b.add("glow",Vector3((j*37%160)-80,33+j%6*7,-120),Vector3.ONE*.2,Color("d5e2f4"))
		"rooftop":
			# Parapets, water tower, ventilation and solar arrays: no street-city copy.
			for side in [-1,1]:
				b.add("box",Vector3(side*(h.x+21),-.8,0),Vector3(4,1.5,h.y*2+45),Color("556a87"),true)
			for j in 5:
				b.add("box",Vector3((j-2)*13,1.5,-h.y-27),Vector3(9,3,5),Color("8ba1b2"),true)
				b.add("box",Vector3((j-2)*13,3.3,-h.y-27),Vector3(9,.4,5),Color("364d81"),false,.1)
			for x in [-4,4]:
				b.add("trunk",Vector3(h.x+31+x,5,-8),Vector3(.6,10,.6),Color("727985"),true)
			b.add("trunk",Vector3(h.x+31,12,-8),Vector3(11,8,11),Color("b76c57"),true)
			b.add("cone",Vector3(h.x+31,17,-8),Vector3(12,3,12),Color("637f94"))
			for j in 13:
				b.add("box",Vector3((j-6)*22,3+j%5*3,-130),Vector3(15,10+j%5*6,14),Color("425b79"))
		"harbor":
			b.add("box",Vector3(0,-.2,-h.y-100),Vector3(330,.3,190),Color("267f9a"))
			# Large cargo ship, not palm trees and houses reused from the beach.
			b.add("box",Vector3(0,2.5,-h.y-41),Vector3(22,5,35),Color("ad5547"),true)
			b.add("box",Vector3(0,5.2,-h.y-41),Vector3(23,.5,36),Color("345e76"))
			for j in 4:
				for k in 3:
					b.add("box",Vector3((k-1)*6.5,7,-h.y-30-j*7),Vector3(6,3,6.5),[Color("ce9554"),Color("518c9a"),Color("bb6863")][(j+k)%3],true)
			for side in [-1,1]:
				b.add("box",Vector3(side*(h.x+30),15,-6),Vector3(2,30,2),Color("e3ad48"),true)
				b.add("box",Vector3(side*(h.x+30),29,-8),Vector3(3,2,44),Color("e3ad48"))
		"meadow":
			_house(b,Vector3(-h.x-30,0,-8),Color("c95d4d"))
			b.add("box",Vector3(14,8,-h.y-30),Vector3(8,16,8),Color("efe0ba"),true)
			b.add("roof",Vector3(14,18,-h.y-30),Vector3(10,6,10),Color("a55343"))
			for j in 10:
				_tree(b,Vector3((j-5)*15,0,-h.y-58-j%2*8))
				b.add("trunk",Vector3(h.x+28,1.6,(j-5)*7),Vector3(3,3.2,3),Color("ddb75f"),true)
			for j in 7:
				b.add("hill",Vector3((j-3)*35,5,-120),Vector3(60,26,40),Color("5eae6d"))
			# Red barn doors, orchard and wheat fields, not a recoloured town.
			var barn := Vector3(-h.x-30,0,-8)
			b.add("box",barn+Vector3(0,2,3.6),Vector3(4,4,.15),Color("764f3d"))
			for x in [-2,2]:
				b.add("box",barn+Vector3(x,2.2,3.7),Vector3(.3,4.4,.15),Color("efe0bd"))
			b.add("box",barn+Vector3(0,4.3,3.7),Vector3(4.4,.3,.15),Color("efe0bd"))
			for row in 8:
				for col in 12:
					var wheat := Vector3(-h.x-54+(col-5.5)*1.2,0,(row-3.5)*2.6)
					b.add("trunk",wheat+Vector3.UP*.65,Vector3(.1,1.3,.1),Color("ae9459"))
					b.add("box",wheat+Vector3.UP*1.35,Vector3(.22,.4,.16),Color("c9a555"))

		"alpine":
			for j in 5:
				_house(b,Vector3((j-2)*17,0,-h.y-30),Color("6f9da9") if j%2 else Color("c68157"),true)
			for j in 9:
				_peak(b,Vector3((j-4)*28,0,-120-j%2*20),55+j%3*10,47)
			for side in [-1,1]:
				for j in 5:
					_tree(b,Vector3(side*(h.x+22),0,(j-2)*17),true)
			for side in [-1,1]:
				b.add("trunk",Vector3(side*(h.x+10),10,-h.y-14),Vector3(1.3,20,1.3),Color("5a7183"),true)
			b.add("box",Vector3(0,21,-h.y-14),Vector3(h.x*2+22,.1,.1),Color("456173"))
		"stadium":
			for side in [-1,1]:
				for tier in 4:
					b.add("box",Vector3(0,1+tier*1.4,side*(h.y+24+tier*5)),Vector3(h.x*2+30,2,5),Color("d58b59") if tier%2 else Color("497f9c"),true)
				for x in [-h.x-25,h.x+25]:
					b.add("box",Vector3(x,13,side*(h.y+25)),Vector3(1.5,26,1.5),Color("6e8898"),true)
					b.add("glow",Vector3(x,26,side*(h.y+25)),Vector3(7,2,1.5),Color("fff1b2"))
			b.add("box",Vector3(0,16,-h.y-46),Vector3(22,10,1),Color("26485f"),true)
			for j in 5:
				b.add("glow",Vector3((j-2)*3.7,17,-h.y-45.4),Vector3(2,2.5,.15),Color("b4e76a"))
	# The game camera can face any edge: identity must not exist only northward.
	for side in [-1, 1]:
		match kind:
			"suburb":
				for j in 4:
					_house(b, Vector3(side*(h.x+31),0,(j-1.5)*19), [Color("edbd73"),Color("df9279"),Color("9acba1")][j%3])
			"plaza":
				for j in 5:
					var at := Vector3(side*(h.x+32),8+j%2*3,(j-2)*18)
					b.add("box",at,Vector3(13,at.y*2,15),Color("ce9873") if j%2 else Color("86a5b7"),true)
					for y in [4,8,12]:
						b.add("box",Vector3(side*(h.x+25.4),y,at.z),Vector3(.15,1.7,10),Color("b8dfe7"))
			"beach", "harbor":
				b.add("box",Vector3(side*(h.x+90),-.16,0),Vector3(140,.3,260),Color("258eaf") if kind=="beach" else Color("267f9a"))
				b.add("box",Vector3(side*(h.x+22),-.015,0),Vector3(12,.04,h.y*2+50),Color("d7b56f") if kind=="beach" else Color("82999e"))
				for j in 4:
					var at := Vector3(side*(h.x+31),0,(j-1.5)*18)
					if kind=="beach":
						_house(b,at,Color("e4aa65") if j%2 else Color("81bfc2"))
					else:
						for layer in 2:
							b.add("box",at+Vector3.UP*(1.6+layer*3.1),Vector3(8,3,13),Color("bd7754") if (layer+j)%2 else Color("407d96"),true)
			"rooftop":
				for j in 6:
					b.add("box",Vector3(side*(h.x+54),8+j%3*6,(j-2.5)*20),Vector3(15,16+j%3*12,15),Color("59758e"),true)
			"alpine":
				for j in 4:
					_house(b,Vector3(side*(h.x+32),0,(j-1.5)*20),Color("8bb3b9") if j%2 else Color("c8825a"),true)
			"stadium":
				for tier in 4:
					b.add("box",Vector3(side*(h.x+24+tier*5),1+tier*1.4,0),Vector3(5,2,h.y*2+30),Color("d58b59") if tier%2 else Color("497f9c"),true)
	if kind in ["suburb", "meadow", "alpine"]:
		for j in 16:
			var a := j*TAU/16.0
			var at := Vector3(cos(a)*115,7,sin(a)*115)
			if kind=="alpine":
				_peak(b,Vector3(at.x,0,at.z),55+j%3*8,45)
			else:
				b.add("hill",at,Vector3(55,32+j%3*7,48),Color("4b9465") if kind=="suburb" else Color("5eae6d"))

	b.finish()
	root.set_meta("decor_solids", b.obstacles)
