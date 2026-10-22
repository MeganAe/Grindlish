extends Node3D
## Peripheral life: shared Kenney animations, reserved lanes, swept obstacle checks.
## No CollisionObject is added: the skater can never be blocked by an extra NPC.
const Worlds := preload("res://worlds.gd")
var agents: Array = []
var effects: Array = []
var foliage: Array = []
var obstacles: Array = []
var obstacle_grid := {}
const CELL := 12.0
var game: Node3D
var half := Vector2.ZERO
var world_id := 1
var clock := 0.0
var reaction := 0.0
var accumulator := 0.0
var blocked_steps := 0
var conversations := 0
var crowd: MultiMeshInstance3D
var crowd_bases: Array[Vector3] = []
var density := 1
var ready_for_life := false
var kind := ""
var _materials := {}
var _meshes := {}

func _material(colour: Color, glow := false) -> StandardMaterial3D:
	var key := colour.to_html() + str(glow)
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = colour
		m.roughness = .95
		if glow:
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_materials[key] = m
	return _materials[key]

func _part(parent: Node3D, at: Vector3, size: Vector3, colour: Color, sphere := false, glow := false) -> MeshInstance3D:
	var key := str(sphere) + colour.to_html() + str(glow)
	if not _meshes.has(key):
		var mesh: Mesh
		if sphere:
			var ball := SphereMesh.new()
			ball.radius = .5
			ball.height = 1
			ball.radial_segments = 8
			ball.rings = 4
			mesh = ball
		else:
			mesh = BoxMesh.new()
		mesh.surface_set_material(0, _material(colour, glow))
		_meshes[key] = mesh
	var instance := MeshInstance3D.new()
	instance.mesh = _meshes[key]
	instance.position = at
	instance.scale = size
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

func _ring(offset: float, y := 0.08) -> Array[Vector3]:
	return [Vector3(-half.x-offset,y,half.y+offset),Vector3(-half.x-offset,y,-half.y-offset),Vector3(half.x+offset,y,-half.y-offset),Vector3(half.x+offset,y,half.y+offset)]

func _sample(path: Array, distance: float, closed: bool) -> Dictionary:
	var length := 0.0
	var count := path.size() if closed else path.size()-1
	for i in count:
		length += path[i].distance_to(path[(i+1)%path.size()])
	var value := fposmod(distance, length if closed else length*2)
	var backwards := not closed and value > length
	if backwards:
		value = length*2-value
	for i in count:
		var a: Vector3 = path[i]
		var b: Vector3 = path[(i+1)%path.size()]
		var segment := a.distance_to(b)
		if value <= segment or i==count-1:
			var dir := (b-a).normalized() * (-1 if backwards else 1)
			return {"position": a.lerp(b,clampf(value/segment,0,1)),"heading":dir}
		value -= segment
	return {"position":path[0],"heading":Vector3.FORWARD}

func _index_obstacles() -> void:
	obstacle_grid.clear()
	for index in obstacles.size():
		var box: AABB = obstacles[index]
		for x in range(floori(box.position.x/CELL),floori(box.end.x/CELL)+1):
			for z in range(floori(box.position.z/CELL),floori(box.end.z/CELL)+1):
				var key := Vector2i(x,z)
				if not obstacle_grid.has(key):
					obstacle_grid[key] = []
				obstacle_grid[key].append(index)

func _nearby(a: Vector3, b: Vector3, radius: float) -> Array:
	var found := {}
	for x in range(floori((minf(a.x,b.x)-radius)/CELL),floori((maxf(a.x,b.x)+radius)/CELL)+1):
		for z in range(floori((minf(a.z,b.z)-radius)/CELL),floori((maxf(a.z,b.z)+radius)/CELL)+1):
			for index in obstacle_grid.get(Vector2i(x,z),[]):
				found[index] = true
	return found.keys()

func clear_sweep(a: Vector3, b: Vector3, radius: float, height: float) -> bool:
	return _sweep_indices(a,b,radius,height,_nearby(a,b,radius))

func clear_sweep_brute(a: Vector3, b: Vector3, radius: float, height: float) -> bool:
	return _sweep_indices(a,b,radius,height,range(obstacles.size()))

func _sweep_indices(a: Vector3, b: Vector3, radius: float, height: float, indices: Array) -> bool:
	for index in indices:
		var obstacle: AABB = obstacles[index]
		var box: AABB = obstacle
		var expanded := AABB(box.position-Vector3(radius,height,radius),box.size+Vector3(radius*2,height,radius*2))
		if expanded.has_point(b) or expanded.intersects_segment(a,b) != null:
			return false
	return true

func _actor(type: String, path: Array, phase: float, speed: float, closed := true, variant := 0) -> void:
	var root := Node3D.new()
	root.name = "Life_" + type + "_" + str(agents.size())
	add_child(root)
	var height := 1.8
	var radius := .48
	var animation: AnimationPlayer
	var wings: Array = []
	match type:
		"person":
			var model: Node3D = load("res://models/character-skate-%s.glb" % ("boy" if variant%2==0 else "girl")).instantiate()
			model.scale = Vector3.ONE * (2.05 + (variant%3)*.12)
			root.add_child(model)
			animation = model.find_child("AnimationPlayer",true,false)
			for mesh in model.find_children("*","MeshInstance3D",true,false):
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if animation:
				for name in ["walk","idle","interact-left","emote-yes"]:
					if animation.has_animation(name):
						animation.get_animation(name).loop_mode = Animation.LOOP_LINEAR
				animation.play("walk")
			# Small original accessories vary without modifying shared Kenney materials.
			if variant%3==0:
				_part(root,Vector3(0,1.15,-.25),Vector3(.4,.48,.2),Color("7fbda1"))
		"car":
			radius = 2.3
			height = 1.8
			var car: Node3D = load("res://models/vehicle.glb").instantiate()
			car.scale = Vector3.ONE*2.0
			root.add_child(car)
			for mesh in car.find_children("*","MeshInstance3D",true,false):
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		"bus", "cablecar":
			radius = 3.5 if type=="bus" else 2.3
			height = 2.5
			var length := 6.5 if type=="bus" else 3.5
			_part(root,Vector3(0,1.2,0),Vector3(2.3,2.2,length),Color("e2ae51") if type=="bus" else Color("bb6156"))
			_part(root,Vector3(0,1.6,0),Vector3(2.37,.9,length-.5),Color("739fb9"))
			if type=="cablecar":
				_part(root,Vector3(0,3,0),Vector3(.12,2,.12),Color("4d6678"))
			else:
				for x in [-1.15,1.15]:
					for z in [-2.1,2.1]:
						_part(root,Vector3(x,.4,z),Vector3(.35,.85,.85),Color("304a5a"),true)
		"bicycle":
			radius = 1.25
			height = 2
			for z in [-.8,.8]:
				_part(root,Vector3(0,.5,z),Vector3(.12,.95,.95),Color("385366"),true)
			var frame := _part(root,Vector3(0,.8,0),Vector3(.15,.15,1.8),Color("dc8e58"))
			frame.rotation.x = .2
			_part(root,Vector3(0,1.4,0),Vector3(.4,.7,.35),Color("8bc29a"))
			_part(root,Vector3(0,1.95,0),Vector3.ONE*.4,Color("e7bd93"),true)
		"boat":
			radius = 3
			height = 3
			_part(root,Vector3(0,.4,0),Vector3(2.8,.8,5.5),Color("d38e59"))
			_part(root,Vector3(0,1.3,0),Vector3(2,1.2,2),Color("e9e3c2"))
			_part(root,Vector3(0,2.5,0),Vector3(.12,3,.12),Color("537381"))
		"dog", "cat":
			radius = .5
			height = .8
			_part(root,Vector3(0,.42,0),Vector3(.4,.38,.8),Color("b88656") if type=="dog" else Color("70869b"))
			_part(root,Vector3(0,.7,-.37),Vector3(.35,.35,.35),Color("d6ae7c") if type=="dog" else Color("8299a9"),true)
			for x in [-.15,.15]:
				for z in [-.25,.25]:
					wings.append(_part(root,Vector3(x,.2,z),Vector3(.1,.4,.1),Color("765741")))
		"bird", "butterfly", "fish":
			radius = .25
			height = .3
			var col := Color("eee5c3") if type=="bird" else (Color("e8b15f") if type=="butterfly" else Color("9bccb9"))
			_part(root,Vector3.ZERO,Vector3(.18,.18,.5),col,true)
			for side in [-1,1]:
				wings.append(_part(root,Vector3(side*.25,0,0),Vector3(.48,.04,.3),col))
	var info := _sample(path,phase,closed)
	root.position = info.position
	agents.append({"node":root,"type":type,"path":path,"distance":phase,"speed":speed,"closed":closed,"radius":radius,"height":height,"animation":animation,"wings":wings,"state":"walk","moved":0.0,"previous":root.position,"stops":0,"variant":variant,"talk_until":0.0,"next_talk":5.0,"peer":null})

func setup(owner_game: Node3D, lv: Dictionary) -> void:
	game = owner_game
	world_id = lv.id
	kind = Worlds.profile(world_id).kind
	half = Vector2(float(lv.size[0]),float(lv.size[1]))*1.25
	density = clampi(Save.life_density,0,2)
	obstacles = game.get_node("Park").get_meta("decor_solids",[])
	_index_obstacles()
	var count: int = [4,8,12][density]
	for i in count:
		_actor("person",_ring(3),i*(half.x+half.y+6)*4/count,.65+(i%4)*.16,true,i)
	var vehicles: int = [1,2,3][density]
	for i in vehicles:
		if world_id in [3,7]:
			var route := [Vector3(-half.x-10,.1,-half.y-(54 if world_id==3 else 76)-i*8),Vector3(half.x+10,.1,-half.y-(54 if world_id==3 else 76)-i*8)]
			_actor("boat",route,i*25.0,1.5+i*.2,false,i)
		elif world_id==9:
			if i>0:
				continue
			_actor("cablecar",[Vector3(-half.x-4,17.5,-half.y-14),Vector3(half.x+4,17.5,-half.y-14)],i*32.0,1.1,false,i)
		else:
			_actor("bus" if world_id in [2,10] and i==0 else ("bicycle" if world_id in [1,8] and i==0 else "car"),_ring(14),i*100.0,3.0+i*.2,true,i)
	for i in [3,5,8][density]:
		var animal := "butterfly" if world_id in [1,5,8] else "bird"
		if animal=="fish":
			_actor(animal,[Vector3(-half.x-15,-.3,-half.y-62-i*1.5),Vector3(half.x+15,-.3,-half.y-62-i*1.5)],i*8,1.1,false,i)
		else:
			_actor(animal,_ring(7,2.2 if animal=="butterfly" else 33.0),i*35.0,1.2 if animal=="butterfly" else 3.8,true,i)
	if world_id in [1,2,5,8,9]:
		_actor("cat" if world_id in [2,9] else "dog",_ring(6.6),20,1.0,true,1)
	_build_effects()
	if world_id in [5,10]:
		_build_crowd()
	for instance in game.get_node("Park").find_children("*","MultiMeshInstance3D",true,false):
		if instance.get_meta("decor_kind","") in ["crown","cone"]:
			var bases := []
			for index in instance.multimesh.instance_count:
				bases.append(instance.multimesh.get_instance_transform(index))
			foliage.append({"mm":instance.multimesh,"bases":bases})
	ready_for_life = true

func _build_effects() -> void:
	# All weather is outside the game rectangle. No full-screen fog/colour grading.
	var weather: String = Worlds.profile(world_id).weather
	for i in (0 if Save.quality==0 else [8,16,28][density]):
		var node := Node3D.new()
		add_child(node)
		var pos := Vector3(-half.x-7-(i%3)*2,3+(i%6)*1.8,(i-8)*4)
		var col := Color("a8c965")
		var size := Vector3(.14,.04,.25)
		if weather in ["snow","fireflies","confetti"]:
			col = Color("edf5f5") if weather=="snow" else (Color("ddf77c") if weather=="fireflies" else Color("ebc37a"))
			size = Vector3.ONE*(.09 if weather=="snow" else .14)
		elif weather=="waves":
			pos = Vector3((i-8)*6,0,-half.y-48-(i%3)*6)
			col = Color("78c8d6")
			size = Vector3(3,.05,.25)
		elif weather=="steam":
			pos = Vector3(-18,39+i%5,-half.y-39)
			col = Color("cddcda")
			size = Vector3.ONE*(.8+i%3*.5)
		elif weather=="cloud":
			pos = Vector3((i-8)*16,38+i%3*4,-110)
			col = Color("dde5dc")
			size = Vector3(12,2.5,5)
		_part(node,Vector3.ZERO,size,col,true,weather in ["fireflies","snow"])
		effects.append({"node":node,"base":pos,"weather":weather,"phase":float(i)*1.8})
	if world_id==8:
		var mill := Node3D.new()
		mill.position = Vector3(14,14,-half.y-25.8)
		add_child(mill)
		for i in 4:
			var a := i*PI*.5
			var blade := _part(mill,Vector3(sin(a)*5,cos(a)*5,0),Vector3(1.2,10,.25),Color("ead8ac"))
			blade.rotation.z = -a
		effects.append({"node":mill,"base":mill.position,"weather":"mill","phase":0.0})
	if world_id in [4,7]:
		var hook := Node3D.new()
		hook.position = Vector3(half.x+(25 if world_id==4 else 30),27 if world_id==4 else 29,-8)
		add_child(hook)
		_part(hook,Vector3(0,-3,0),Vector3(.1,6,.1),Color("58717b"))
		_part(hook,Vector3(0,-6.2,0),Vector3(.8,.3,.3),Color("e4b85d"))
		effects.append({"node":hook,"base":hook.position,"weather":"hook","phase":0.0})

	# Flags at competition/rooftop, moving without a new expensive shader.
	if world_id in [6,10]:
		for side in [-1,1]:
			var flag := Node3D.new()
			flag.position = Vector3(side*(half.x+23),12,0)
			add_child(flag)
			_part(flag,Vector3.ZERO,Vector3(3,1.2,.08),Color("e5b56a") if side==1 else Color("a4cbac"))
			effects.append({"node":flag,"base":flag.position,"weather":"flag","phase":float(side)})

func _build_crowd() -> void:
	crowd = MultiMeshInstance3D.new()
	crowd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(.45,.9,.35)
	var crowd_material := _material(Color.WHITE).duplicate()
	crowd_material.vertex_color_use_as_albedo = true
	mesh.material = crowd_material
	mm.mesh = mesh
	var count: int = [12,24,48][density]
	mm.instance_count = count*4
	for i in count:
		var at := Vector3((i%12-5.5)*2.2,2.8+(i/12)*1.4,-half.y-24-(i/12)*5)
		if world_id==5:
			at = Vector3(-half.x-23,0.9,(i-count*.5)*1.8)
		crowd_bases.append(at)
		for part in 4:
			mm.set_instance_transform(i*4+part,Transform3D(Basis.IDENTITY,at+Vector3(0,part*.4,0)))
			mm.set_instance_color(i*4+part,(Color("d68b59") if i%2 else Color("78a9b1")) if part==0 else Color("e2bd96"))
	crowd.multimesh = mm
	add_child(crowd)

func react(points: int) -> void:
	if points>=400:
		reaction = 2.4

func _physics_process(delta: float) -> void:
	if not ready_for_life:
		return
	accumulator += delta
	if accumulator < .05:
		return
	var dt := accumulator
	accumulator = 0
	advance(dt)

func advance(dt: float) -> void:
	clock += dt
	reaction = maxf(0,reaction-dt)
	var eye: Vector3 = game.cam.global_position if game and game.cam else Vector3.ZERO
	for agent in agents:
		var node: Node3D = agent.node
		agent.previous = node.position
		if agent.type=="person" and clock>=agent.next_talk:
			for peer in agents:
				if peer==agent or peer.type!="person" or clock<peer.next_talk:
					continue
				if node.position.distance_to(peer.node.position)<2.6:
					agent.talk_until = clock+1.8
					peer.talk_until = clock+1.8
					agent.next_talk = clock+15
					peer.next_talk = clock+15
					agent.peer = peer.node
					peer.peer = node
					conversations += 1
					break
		var talking: bool = agent.type=="person" and clock<agent.talk_until
		var stop: bool = agent.type=="person" and fposmod(clock+agent.variant*1.7,12.0)<1.3
		stop = stop or talking or (agent.type=="person" and reaction>0)
		var sample := _sample(agent.path,agent.distance+agent.speed*dt,agent.closed)
		var proposed: Vector3 = sample.position
		var allowed := clear_sweep(node.position,proposed,agent.radius,agent.height)
		if allowed:
			for other in agents:
				if other==agent:
					continue
				var other_node: Node3D = other.node
				if absf(proposed.y-other_node.position.y)<minf(agent.height,other.height) and proposed.distance_to(other_node.position)<agent.radius+other.radius+.25:
					allowed = false
					break
		if game and game.skater and proposed.distance_to(game.skater.position)<agent.radius+1.2:
			allowed = false
		if allowed and not stop:
			agent.distance += agent.speed*dt
			agent.moved += node.position.distance_to(proposed)
			node.position = proposed
			if sample.heading.length_squared()>.1:
				node.rotation.y = atan2(sample.heading.x,sample.heading.z) if agent.type in ["person","car"] else atan2(-sample.heading.x,-sample.heading.z)
		else:
			agent.stops += 1
			if not allowed:
				blocked_steps += 1
		node.visible = node.position.distance_to(eye)<(145 if agent.type in ["boat","bird"] else 105)
		var animation: AnimationPlayer = agent.animation
		if animation:
			var wanted := "emote-yes" if reaction>0 else ("interact-left" if talking else ("idle" if stop or not allowed else "walk"))
			if wanted!=agent.state:
				animation.play(wanted)
				agent.state = wanted
			if talking and is_instance_valid(agent.peer):
				node.look_at(agent.peer.position,Vector3.UP,true)
			animation.active = node.visible and node.position.distance_to(eye)<65
		for index in agent.wings.size():
			var wing: Node3D = agent.wings[index]
			wing.rotation.z = sin(clock*9+agent.variant)*(.45 if index%2 else -.45)
	for effect in ([] if Save.quality==0 else effects):
		var node: Node3D = effect.node
		var phase: float = clock+effect.phase
		node.position = effect.base
		match effect.weather:
			"mill": node.rotation.z = clock*.5
			"flag": node.rotation.y = sin(phase*2)*.22
			"hook":
				node.position.z += sin(phase*.25)*4
				node.rotation.x = sin(phase*.6)*.04
			"snow","leaves","breeze","confetti":
				node.position.y = 1+fposmod(effect.base.y-clock*.45,10)
				node.position.x += sin(phase)*.7
			"steam":
				node.position.y += fposmod(clock*.5+effect.phase,7)
				node.position.x += sin(phase*.3)
			"cloud": node.position.x += sin(phase*.025)*18
			"waves": node.position.z += sin(phase*.6)*1.4
			"fireflies":
				node.position += Vector3(sin(phase),sin(phase*1.2),cos(phase))*.6
				node.scale = Vector3.ONE*(.6+.4*sin(phase*2))
	for batch in ([] if Save.quality==0 else foliage):
		var mm: MultiMesh = batch.mm
		for index in batch.bases.size():
			var base: Transform3D = batch.bases[index]
			base.origin.x += sin(clock*.9+index)*.07
			mm.set_instance_transform(index,base)
	if crowd:
		for i in crowd_bases.size():
			var at: Vector3 = crowd_bases[i]
			var bounce := absf(sin(clock*8+i))*.32 if reaction>0 else sin(clock+i)*.025
			crowd.multimesh.set_instance_transform(i*4,Transform3D(Basis.IDENTITY,at+Vector3.UP*bounce))
			crowd.multimesh.set_instance_transform(i*4+1,Transform3D(Basis.IDENTITY.scaled(Vector3(.8,.45,.8)),at+Vector3.UP*(.75+bounce)))
			for hand in 2:
				var side := -1 if hand==0 else 1
				var pose := at+Vector3(side*(.12+absf(sin(clock*9+i))*.2),.8+bounce,0)
				crowd.multimesh.set_instance_transform(i*4+hand+2,Transform3D(Basis.IDENTITY.scaled(Vector3(.25,.35,.4)),pose))

func _exit_tree() -> void:
	for instance in find_children("*","MeshInstance3D",true,false):
		instance.mesh = null
	for instance in find_children("*","MultiMeshInstance3D",true,false):
		instance.multimesh = null
