extends RefCounted
## Conservative floor-only navigation. Physics is queried after the park enters the space.
## No baked map, teleport, collection callback, or collision bypass is used by the pilot.
var graph := AStar3D.new()
var cells := {}
var allowed: Array[int] = []
var step := 1.5
var origin := Vector3.ZERO
var space: PhysicsDirectSpaceState3D
var exclude: Array[RID] = []
var capsule := CapsuleShape3D.new()
var slots: Array[Vector3] = []

func build(game: Node3D) -> void:
	space = game.get_world_3d().direct_space_state
	exclude = [game.skater.get_rid()]
	capsule.radius = 0.85
	capsule.height = 1.8
	var bounds: Vector2 = game.info.bounds * 0.5 - Vector2.ONE * 2.2
	var nx := int(bounds.x / step)
	var nz := int(bounds.y / step)
	for x in range(-nx, nx + 1):
		for z in range(-nz, nz + 1):
			var at := Vector3(x * step, 0.08, z * step)
			if not clear(at):
				continue
			var near_rail := false
			for rail in game.info.grind:
				var near: Vector3 = rail.a + rail.dir * clampf((at - rail.a).dot(rail.dir), 0.0, rail.len)
				if Vector2(at.x - near.x, at.z - near.z).length() < 1.1:
					near_rail = true
			if near_rail:
				continue
			var id := graph.get_available_point_id()
			graph.add_point(id, at)
			cells[Vector2i(x, z)] = id
	for cell in cells:
		for shift in [Vector2i(1, 0), Vector2i(0, 1)]:
			var next: Vector2i = cell + shift
			if cells.has(next):
				graph.connect_points(cells[cell], cells[next])
	# Choose the largest connected region, not an isolated patch on a deck.
	var visited := {}
	for id in graph.get_point_ids():
		if visited.has(id):
			continue
		var component: Array[int] = [id]
		visited[id] = true
		var head := 0
		while head < component.size():
			for neighbour in graph.get_point_connections(component[head]):
				if not visited.has(neighbour):
					visited[neighbour] = true
					component.append(neighbour)
			head += 1
		if component.size() > allowed.size():
			allowed = component
	for id in graph.get_point_ids():
		if not allowed.has(id):
			graph.set_point_disabled(id)
	if allowed.is_empty():
		push_error("No safe connected learning route")
		return
	var start := nearest(game.skater.global_position)
	origin = graph.get_point_position(start)
	# Twelve distinct, spaced floor positions in the same component.
	var chosen: Array[int] = [start]
	for i in 12:
		var best := -1
		var distance := -1.0
		for id in allowed:
			var nearest_dist := INF
			for used in chosen:
				nearest_dist = minf(nearest_dist, graph.get_point_position(id).distance_squared_to(graph.get_point_position(used)))
			if nearest_dist > distance:
				distance = nearest_dist
				best = id
		chosen.append(best)
		slots.append(graph.get_point_position(best) + Vector3.UP * 1.05)

func clear(at: Vector3) -> bool:
	var floor_query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 7, at - Vector3.UP * 0.5)
	floor_query.exclude = exclude
	var floor_hit := space.intersect_ray(floor_query)
	if floor_hit.is_empty() or absf(float(floor_hit.position.y)) > 0.12 or floor_hit.normal.y < 0.98:
		return false
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsule
	q.exclude = exclude
	q.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 1.02)
	return space.intersect_shape(q, 1).is_empty()

func nearest(at: Vector3) -> int:
	var best := -1
	var distance := INF
	for id in allowed:
		var ds := graph.get_point_position(id).distance_squared_to(at)
		if ds < distance:
			distance = ds
			best = id
	return best

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if allowed.is_empty():
		return PackedVector3Array()
	return graph.get_point_path(nearest(from), nearest(to))
