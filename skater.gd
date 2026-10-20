extends CharacterBody3D
## Contrôleur du skateur : glisse automatique, saut, tricks, grind, chute.

signal trick(name: String, points: int)
signal landed(clean: bool, air_time: float)
signal bailed(reason: String)
signal grind_started
signal grind_ended(duration: float)

enum S { GROUND, AIR, GRIND, BAIL }

const K := 2.5
const GRAVITY := 32.0
const SPIN_RATE := 9.0
const FLIP_TIME := 0.45
const ANIM_LOOPS := ["skate", "skate-stand", "skate-air", "skate-grab", "crouch"]

var arena_half := Vector2(1000, 1000)
var boundary_corrections := 0
var state := S.GROUND
var cruise := 10.0
var boost := 16.0
var jump_speed := 12.0
var pickup_radius := 3.0
var god := false
var autopilot := false
var ai_input := {"steer": 0.0, "throttle": 0.0, "jump_p": false, "jump_h": false, "flip_p": false, "grab_h": false}
var frozen := false

var heading := Vector3(0, 0, -1)
var grind_segments: Array = []
var air_time := 0.0
var total_air := 0.0
var spin := 0.0
var spin_done := 0
var flipping := false
var flip_t := 0.0
var flips := 0
var grab_time := 0.0
var jumped := false
var cut_jump := false
var coyote := 0.0
var jump_buffer := 0.0
var bail_t := 0.0
var invuln := 0.0
var spawn_point := Vector3.ZERO
var last_safe := Vector3.ZERO
var last_safe_heading := Vector3(0, 0, -1)
var safe_timer := 0.0
var grind_idx := -1
var grind_t := 0.0
var grind_sign := 1.0
var grind_speed := 8.0
var grind_time := 0.0
var grind_cd := 0.0
var was_on_floor := true
var hspeed := 0.0
var max_air_height := 0.0
var air_start_y := 0.0
var stats := {"max_air": 0.0, "max_speed": 0.0, "grinds": 0, "bails": 0}

var rig: Node3D
var char_node: Node3D
var board: Node3D
var anim: AnimationPlayer
var _cur_anim := ""
var _vis_yaw := 0.0
var _lean := 0.0
var spin_off := 0.0


func _ready() -> void:
	add_to_group("skater")
	floor_max_angle = deg_to_rad(76.0)
	max_slides = 8
	safe_margin = 0.008
	floor_snap_length = 0.6
	floor_stop_on_slope = false
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	add_child(cs)
	rig = Node3D.new()
	rig.scale = Vector3.ONE * K
	add_child(rig)
	last_safe = global_position


func setup_visuals(character: String, tint: Color) -> void:
	char_node = load("res://models/%s.glb" % character).instantiate()
	rig.add_child(char_node)
	board = load("res://models/skateboard.glb").instantiate()
	rig.add_child(board)
	anim = char_node.find_child("AnimationPlayer", true, false)
	if anim:
		for n in ANIM_LOOPS:
			if anim.has_animation(n):
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	if tint != Color.WHITE:
		for m in board.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			var mat := mi.get_active_material(0)
			if mat:
				mat = mat.duplicate()
				if mat is StandardMaterial3D:
					(mat as StandardMaterial3D).albedo_color = tint
				mi.set_surface_override_material(0, mat)


func place(pos: Vector3, face: Vector3) -> void:
	global_position = pos
	velocity = face * 4.0
	heading = face
	_vis_yaw = atan2(face.x, face.z)
	last_safe = pos
	spawn_point = pos
	last_safe_heading = face
	state = S.GROUND
	was_on_floor = false
	air_time = 0.0


func _inp() -> Dictionary:
	if autopilot:
		return ai_input
	return {
		"steer": Input.get_axis("move_left", "move_right"),
		"throttle": Input.get_axis("move_down", "move_up"),
		"jump_p": Input.is_action_just_pressed("jump"),
		"jump_h": Input.is_action_pressed("jump"),
		"flip_p": Input.is_action_just_pressed("flip"),
		"grab_h": Input.is_action_pressed("grab"),
	}


func _physics_process(delta: float) -> void:
	if frozen:
		return
	var inp := _inp()
	invuln = maxf(0.0, invuln - delta)
	match state:
		S.GRIND:
			_grind(delta, inp)
		S.BAIL:
			_bail_step(delta)
		_:
			_move(delta, inp)
	_constrain_arena()
	_visual(delta, inp)
	_collect()
	_track_safe(delta)
	stats["max_speed"] = maxf(stats["max_speed"], hspeed)
	if global_position.y < -12.0 and state != S.BAIL:
		_bail("fall")


# ------------------------------------------------------------------ sol / air

func _move(delta: float, inp: Dictionary) -> void:
	var on_floor := is_on_floor()
	var steer: float = inp["steer"]
	var throttle: float = inp["throttle"]
	coyote = 0.12 if on_floor else maxf(0.0, coyote - delta)
	jump_buffer = 0.14 if inp["jump_p"] or inp["flip_p"] else maxf(0.0, jump_buffer - delta)
	grind_cd = maxf(0.0, grind_cd - delta)

	var vh := Vector3(velocity.x, 0, velocity.z)
	var hs := vh.length()
	hspeed = hs

	if on_floor:
		var n := get_floor_normal()
		var rate := lerpf(3.4, 1.9, clampf(hs / 16.0, 0.0, 1.0))
		if absf(steer) > 0.05:
			if hs > 0.4:
				velocity = velocity.rotated(n, -steer * rate * delta)
			else:
				heading = heading.rotated(Vector3.UP, -steer * rate * delta)
		vh = Vector3(velocity.x, 0, velocity.z)
		hs = vh.length()
		if n.y > 0.94:
			var target := boost if throttle > 0.5 else cruise
			var braking := throttle < -0.5
			if braking:
				target = 0.0
			var dirv := vh / hs if hs > 0.3 else heading
			if braking:
				hs = maxf(0.0, hs - 24.0 * delta)
			elif hs < target:
				hs = minf(target, hs + 9.0 * delta)
			elif hs > target:
				hs = maxf(target, hs - 3.0 * delta)
			velocity.x = dirv.x * hs
			velocity.z = dirv.z * hs
		else:
			velocity *= 1.0 - 0.12 * delta
		if hs > 1.0:
			heading = Vector3(velocity.x, 0, velocity.z).normalized()
		air_time = 0.0
	else:
		air_time += delta
		if state == S.AIR:
			total_air += delta
			max_air_height = maxf(max_air_height, global_position.y - air_start_y)

	# --- tricks en l'air
	if state == S.AIR:
		spin += steer * SPIN_RATE * delta
		var half_turns := int(absf(spin) / (PI * 0.9))
		while spin_done < half_turns:
			spin_done += 1
			var p: int = 60
			trick.emit("%d" % (spin_done * 180), p)
			Sfx.play("trick", 1.0 + 0.05 * spin_done)
		if (inp["flip_p"]) and not flipping:
			flipping = true
			flip_t = 0.0
		if inp["grab_h"]:
			grab_time += delta
		if flipping:
			flip_t += delta
			if flip_t >= FLIP_TIME:
				flipping = false
				flips += 1
				trick.emit("Kickflip" if flips == 1 else "Double Flip", 150 * flips)
				Sfx.play("trick", 1.3)
		# saut variable
		if jumped and not cut_jump and velocity.y > 4.0 and not inp["jump_h"]:
			velocity.y *= 0.55
			cut_jump = true

	# --- gravité, saut
	velocity.y -= GRAVITY * delta
	if jump_buffer > 0.0 and coyote > 0.0 and state != S.AIR:
		velocity.y = minf(maxf(velocity.y, 0.0) + jump_speed, 26.0)
		jump_buffer = 0.0
		coyote = 0.0
		jumped = true
		cut_jump = false
		_enter_air()
		Sfx.play("jump")
		if inp["flip_p"]:
			flipping = true
			flip_t = 0.0
	floor_snap_length = 0.6 if velocity.y <= 0.5 and state != S.AIR else 0.0

	# --- grind
	if state == S.AIR or not on_floor:
		if _try_grind():
			return

	velocity = velocity.limit_length(34.0)
	var pre_v := velocity
	move_and_slide()

	# collision frontale avec un obstacle solide -> chute
	if invuln <= 0.0 and not god:
		for i in get_slide_collision_count():
			var c := get_slide_collision(i)
			var col := c.get_collider()
			var nrm := c.get_normal()
			if col and col.has_meta("solid") and col.get_meta("solid") and nrm.y < 0.35:
				var hv := Vector3(pre_v.x, 0, pre_v.z)
				if hv.length() > 6.0 and hv.normalized().dot(-nrm) > 0.55:
					_bail("wall")
					return

	var now_floor := is_on_floor()
	if now_floor:
		if not was_on_floor and state == S.AIR:
			_land()
		elif state == S.AIR and air_time == 0.0:
			_land()
		if state != S.AIR:
			jumped = false
		air_time = 0.0
	elif air_time > 0.09 and state == S.GROUND:
		_enter_air()
	was_on_floor = now_floor


func _enter_air() -> void:
	state = S.AIR
	total_air = 0.0
	spin = 0.0
	spin_done = 0
	flips = 0
	flipping = false
	grab_time = 0.0
	spin_off = 0.0
	air_start_y = global_position.y
	max_air_height = 0.0
	was_on_floor = false


func _land() -> void:
	state = S.GROUND
	var tricked := absf(spin) > 0.6 or flips > 0 or grab_time > 0.3
	var err := fposmod(absf(spin) + PI * 0.5, PI) - PI * 0.5
	var clean := absf(err) < 0.8
	stats["max_air"] = maxf(stats["max_air"], max_air_height)
	if not clean and (tricked or total_air > 0.35) and not god and invuln <= 0.0:
		_bail("land")
		return
	if grab_time > 0.3:
		trick.emit("Grab", 100 + int(grab_time * 80.0))
	landed.emit(true, total_air)
	Sfx.play("land", clampf(1.2 - total_air * 0.3, 0.7, 1.2))
	# la rotation visuelle revient doucement vers l'avant
	spin_off = -(spin - roundf(spin / PI) * PI)
	spin = 0.0
	flipping = false
	jumped = false


# ------------------------------------------------------------------ grind

func _try_grind() -> bool:
	if grind_cd > 0.0 or velocity.y > 5.0 or grind_segments.is_empty():
		return false
	var vh := Vector3(velocity.x, 0, velocity.z)
	var hs := vh.length()
	if hs < 3.0:
		return false
	var p := global_position
	for i in grind_segments.size():
		var s: Dictionary = grind_segments[i]
		var t := clampf((p - s["a"]).dot(s["dir"]), 0.0, s["len"])
		var q: Vector3 = s["a"] + s["dir"] * t
		var dh := Vector2(p.x - q.x, p.z - q.z).length()
		var dy := p.y - q.y
		if dh < 0.85 and dy > -0.2 and dy < 1.0:
			var align := vh.normalized().dot(s["dir"])
			if absf(align) > 0.4:
				grind_idx = i
				grind_t = t
				grind_sign = 1.0 if align > 0.0 else -1.0
				grind_speed = clampf(hs, 6.0, 14.0)
				grind_time = 0.0
				state = S.GRIND
				stats["grinds"] += 1
				trick.emit("Grind", 100)
				grind_started.emit()
				Sfx.play("grind_on")
				spin = 0.0
				return true
	return false


func _grind(delta: float, inp: Dictionary) -> void:
	var s: Dictionary = grind_segments[grind_idx]
	grind_t += grind_sign * grind_speed * delta
	grind_time += delta
	var tt := clampf(grind_t, 0.0, s["len"])
	global_position = s["a"] + s["dir"] * tt
	heading = s["dir"] * grind_sign
	velocity = heading * grind_speed
	hspeed = grind_speed
	if int(grind_time * 8.0) != int((grind_time - delta) * 8.0):
		Sfx.play("grind", randf_range(0.9, 1.1), 0.05)
	if inp["jump_p"] or inp["flip_p"]:
		_end_grind(true)
	elif grind_t < 0.0 or grind_t > s["len"]:
		_end_grind(false)


func _end_grind(with_jump: bool) -> void:
	grind_ended.emit(grind_time)
	if with_jump:
		velocity.y = jump_speed * 0.85
		jumped = true
		cut_jump = false
		Sfx.play("jump")
	else:
		velocity.y = 4.0
		jumped = false
	grind_cd = 0.45
	_enter_air()
	air_time = 0.2
	global_position += Vector3.UP * 0.15


# ------------------------------------------------------------------ chute

func _bail(reason: String) -> void:
	if state == S.GRIND:
		grind_ended.emit(grind_time)
	state = S.BAIL
	bail_t = 1.4
	stats["bails"] += 1
	spin = 0.0
	spin_off = 0.0
	flipping = false
	bailed.emit(reason)
	Sfx.play("bail")


func _bail_step(delta: float) -> void:
	bail_t -= delta
	velocity.x *= 1.0 - 2.5 * delta
	velocity.z *= 1.0 - 2.5 * delta
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if bail_t <= 0.0:
		global_position = _safe_respawn()
		heading = last_safe_heading
		velocity = heading * 5.0
		state = S.GROUND
		invuln = 1.2
		was_on_floor = false
		air_time = 0.0


func _track_safe(delta: float) -> void:
	if state == S.GROUND and is_on_floor() and get_floor_normal().y > 0.97 and hspeed > 3.0:
		safe_timer += delta
		if safe_timer > 0.5:
			safe_timer = 0.0
			if _space_clear(global_position + Vector3.UP * 0.15) and _supported(global_position):
				last_safe = global_position
			last_safe_heading = heading
	elif state != S.GROUND:
		safe_timer = 0.0


# ------------------------------------------------------------------ visuel

func _visual(delta: float, inp: Dictionary) -> void:
	var h_yaw := atan2(heading.x, heading.z)
	_vis_yaw = lerp_angle(_vis_yaw, h_yaw, 1.0 - exp(-16.0 * delta))
	if state == S.AIR:
		spin_off = -spin
	else:
		spin_off = lerpf(spin_off, 0.0, 1.0 - exp(-10.0 * delta))
	rig.rotation.y = _vis_yaw + spin_off
	var steer: float = inp["steer"]
	_lean = lerpf(_lean, -steer * 0.28 if state == S.GROUND else 0.0, 1.0 - exp(-8.0 * delta))
	if char_node:
		char_node.rotation.z = _lean
	if board:
		board.rotation.z = (flip_t / FLIP_TIME) * TAU if flipping else 0.0
	if state == S.BAIL:
		rig.rotation.x = lerpf(rig.rotation.x, -1.2, 1.0 - exp(-10.0 * delta))
	else:
		rig.rotation.x = lerpf(rig.rotation.x, 0.0, 1.0 - exp(-12.0 * delta))
	if anim == null:
		return
	var want := "skate"
	match state:
		S.GROUND:
			want = "skate" if hspeed > 1.0 else "skate-stand"
		S.AIR:
			want = "skate-grab" if inp["grab_h"] else "skate-air"
		S.GRIND:
			want = "crouch"
		S.BAIL:
			want = "die"
	if want != _cur_anim:
		_cur_anim = want
		anim.play(want, 0.08)
	anim.speed_scale = clampf(hspeed / 8.0, 0.6, 1.8) if want == "skate" else 1.0


func _collect() -> void:
	if state == S.BAIL:
		return
	var c := global_position + Vector3.UP * 1.0
	for p in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(p) and p.game == get_parent() and p.global_position.distance_to(c) < pickup_radius:
			p.collect()


func _space_clear(at: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.7
	query.shape = cap
	query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.9)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _safe_respawn() -> Vector3:
	for base in [last_safe, spawn_point]:
		for offset in [Vector3.ZERO, Vector3(2, 0, 0), Vector3(-2, 0, 0), Vector3(0, 0, 2), Vector3(0, 0, -2)]:
			var at: Vector3 = base + offset + Vector3.UP * 0.3
			if _space_clear(at) and _supported(at):
				return at
	var game := get_parent()
	if game.routes and not game.routes.allowed.is_empty():
		return game.routes.graph.get_point_position(game.routes.nearest(last_safe)) + Vector3.UP * 0.1
	return spawn_point + Vector3.UP * 2



func _supported(at: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.3, at - Vector3.UP * 1.0)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.normal.y > 0.97 and absf(float(hit.position.y)) < 0.15


func _constrain_arena() -> void:
	# Ramp recovery can push a capsule slightly through a simultaneous perimeter contact.
	# Keep the capsule (not just its centre) inside the closed arena in all states.
	var at := global_position
	var safe_x := clampf(at.x, -arena_half.x + 0.45, arena_half.x - 0.45)
	var safe_z := clampf(at.z, -arena_half.y + 0.45, arena_half.y - 0.45)
	if not is_equal_approx(safe_x, at.x):
		velocity.x = 0.0
		boundary_corrections += 1
	if not is_equal_approx(safe_z, at.z):
		velocity.z = 0.0
		boundary_corrections += 1
	global_position = Vector3(safe_x, at.y, safe_z)
