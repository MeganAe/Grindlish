extends Node
## Follows a measured A* floor route by ordinary steer/brake input.
## No transforms, velocity assignment, invulnerability or direct collection calls.
var game: Node3D
var target: Node3D
var waypoints := PackedVector3Array()
var waypoint := 0
var replanning := 0.0
var initialised := false

func _physics_process(delta: float) -> void:
	if not game.ready_for_run or game.ended or game.waiting_quiz:
		return
	var sk: CharacterBody3D = game.skater
	if not initialised:
		# This is the same speed available via the learning-assist setting.
		sk.cruise = 4.0
		sk.boost = 4.0
		initialised = true
	if not is_instance_valid(target) or target.taken:
		target = null
		var best := INF
		for pickup in get_tree().get_nodes_in_group("pickups"):
			if pickup.game != game or pickup.kind == "decoy":
				continue
			if pickup.kind == "letter" and Save.ordered_letters and pickup.idx != game.letters.find(false):
				continue
			var distance: float = sk.global_position.distance_to(pickup.global_position)
			if pickup.kind == "letter":
				distance -= 1000.0
			if distance < best:
				best = distance
				target = pickup
		if target:
			waypoints = game.routes.path(sk.global_position, target.global_position)
			waypoint = mini(1, waypoints.size() - 1)
	replanning -= delta
	var inp := {"steer": 0.0, "throttle": -1.0, "jump_p": false, "jump_h": false, "flip_p": false, "grab_h": false}
	if target and not waypoints.is_empty():
		while waypoint < waypoints.size() - 1 and sk.global_position.distance_to(waypoints[waypoint]) < 0.8:
			waypoint += 1
		var to: Vector3 = waypoints[waypoint] - sk.global_position
		to.y = 0.0
		var angle: float = sk.heading.signed_angle_to(to.normalized(), Vector3.UP)
		inp.steer = clampf(-angle * 3.0, -1.0, 1.0)
		inp.throttle = -1.0 if absf(angle) > 0.25 else 0.0
		if replanning <= 0.0 and sk.global_position.distance_to(waypoints[waypoint]) > 4.5:
			waypoints = game.routes.path(sk.global_position, target.global_position)
			waypoint = mini(1, waypoints.size() - 1)
			replanning = 1.0
	if game.completed_word and game.mode in ["career", "combo", "jam", "daily"]:
		var clock := Engine.get_physics_frames() % 180
		if sk.state == sk.S.GROUND and clock == 0:
			inp.jump_p = true
			inp.flip_p = true
		inp.jump_h = true
		if sk.state == sk.S.AIR:
			inp.steer = 0.0
			inp.grab_h = true
	sk.ai_input = inp
