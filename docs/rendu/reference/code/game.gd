extends Node3D
## Une partie : parc, skateur, caméra, score, combos, lettres, pièces, chrono.

signal word_completed(data: Dictionary)
signal ready_to_skate
signal score_changed(score: int)
signal combo_changed(pending: int, mult: int, label: String, active: bool)
signal letter_got(idx: int)
signal coin_got(total: int)
signal bank(points: int)
signal time_changed(t: float)
signal bailed_sig
signal finished(result: Dictionary)
signal popup(text: String, color: Color)

const Park := preload("res://park.gd")
const Levels := preload("res://levels.gd")
const Skater := preload("res://skater.gd")
const Cam := preload("res://cam.gd")
const Pickup := preload("res://pickup3d.gd")
const K := 2.5

var routes: RefCounted
var ready_for_run := false
var waiting_quiz := false
var completed_word := false
var word_data: Dictionary
var target_word := "BOARD"
var mode := "career"
var lv: Dictionary
var level_id := 1
var skater: CharacterBody3D
var cam: Camera3D
var info: Dictionary
var score := 0
var pending := 0
var mult := 0
var combo_names: Array = []
var combo_grace := 0.0
var letters := [false, false, false, false, false]
var coins_run := 0
var time_left := 0.0
var running := false
var ended := false
var paused := false
var countdown := 0.0
var best_combo := 0
var tricks := 0
var bails := 0
var total_time := 0.0
var _last_tick := -1
var _grind_pts_acc := 0.0
var debug_lines := false
var demo := false
var _orbit := 0.0


func setup(id: int) -> void:
	level_id = id
	lv = Levels.get_level(id)
	mode = str(Engine.get_meta("mode", "career"))
	word_data = Lexicon.choose(id)
	if Engine.has_meta("word"):
		for entry in Lexicon.words:
			if str(entry.word) == str(Engine.get_meta("word")):
				word_data = entry
	target_word = str(word_data["word"]).to_upper()
	letters = []
	letters.resize(target_word.length())
	letters.fill(false)
	time_left = (180.0 if mode in ["word", "collect"] else float(lv["time"])) + Save.shop_level("time") * 10.0
	_environment()
	var root := Node3D.new()
	root.name = "Park"
	add_child(root)
	info = Park.build(root, lv)

	skater = Skater.new()
	skater.name = "Skater"
	add_child(skater)
	skater.setup_visuals(["character-skate-boy", "character-skate-girl"][clampi(Save.char_id, 0, 1)],
		[Color.WHITE, Color(1, 0.3, 0.3), Color(0.3, 0.6, 1.0), Color(0.4, 1.0, 0.5), Color(1.0, 0.8, 0.2), Color(0.8, 0.4, 1.0)][clampi(Save.board, 0, 5)])
	skater.grind_segments = info["grind"]
	skater.arena_half = info.bounds * 0.5
	skater.cruise = 10.0 + Save.shop_level("speed") * 0.8
	skater.boost = 16.0 + Save.shop_level("speed") * 1.0
	skater.jump_speed = 12.0 + Save.shop_level("jump") * 0.6
	skater.pickup_radius = 2.6 + Save.shop_level("magnet") * 0.9
	skater.god = Engine.has_meta("god") or Save.no_fall
	skater.autopilot = Engine.has_meta("auto")
	var sp: Array = lv["spawn"]
	var face: Vector3 = Vector3(0, 0, -1).rotated(Vector3.UP, deg_to_rad(Levels.rot(lv["face"])))
	skater.place(Vector3(sp[0] * K, 0.2, sp[1] * K), face)
	skater.trick.connect(_on_trick)
	skater.landed.connect(_on_landed)
	skater.bailed.connect(_on_bail)
	skater.grind_ended.connect(_on_grind_end)
	skater.grind_started.connect(func(): combo_grace = 0.0)

	cam = Cam.new()
	cam.name = "Cam"
	add_child(cam)
	cam.target = skater
	cam.snap(face)

	_prepare_route.call_deferred()


func _prepare_route() -> void:
	skater.frozen = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	routes = preload("res://route_map.gd").new()
	routes.build(self)
	if routes.slots.size() < 12:
		return
	skater.place(routes.origin, skater.heading)
	for c in lv["coins"]:
		var at := Vector3(c[0] * K, 0.08, c[2] * K)
		var near: int = routes.nearest(at)
		if near >= 0:
			_spawn("coin", 0, routes.graph.get_point_position(near) + Vector3.UP * 1.0)
	# Every letter lies in the same measured connected component as the spawn.
	for i in target_word.length():
		_spawn("letter", i, routes.slots[i])
	if Save.ordered_letters and target_word.length() > 3:
		_spawn("decoy", 0, routes.slots[11] + Vector3(0, 0.0, 0))
	if debug_lines:
		_draw_debug()
	countdown = 0.0 if Engine.has_meta("auto") else 2.4
	running = not demo
	ready_for_run = true
	skater.frozen = demo
	score_changed.emit(0)
	ready_to_skate.emit()
	if demo:
		skater.autopilot = false
		cam.set_process(false)


func _process(delta: float) -> void:
	if demo and cam:
		_orbit += delta * 0.12
		var c := Vector3(0, 0, 0)
		var r: float = float(lv["size"][0]) * K * 0.42
		cam.global_position = c + Vector3(sin(_orbit) * r, 9.0, cos(_orbit) * r)
		cam.look_at(Vector3(0, 0.5, 0), Vector3.UP)


func _spawn(kind: String, idx: int, pos: Vector3) -> void:
	var p := Pickup.new()
	p.kind = kind
	p.idx = idx
	p.game = self
	add_child(p)
	p.position = pos


func _environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	var cols: Array = lv["sky"]
	sm.sky_top_color = cols[0]
	sm.sky_horizon_color = cols[1]
	sm.ground_horizon_color = cols[1]
	sm.ground_bottom_color = lv["outer"]
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("bbced1")
	env.ambient_light_energy = 0.55 if level_id not in [5, 6] else 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 0.85 if level_id not in [5, 6] else 0.45
	sun.shadow_enabled = Save.quality > 0
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)


func _draw_debug() -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for s in info["grind"]:
		im.surface_add_vertex(s["a"] + Vector3.UP * 0.05)
		im.surface_add_vertex(s["b"] + Vector3.UP * 0.05)
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.RED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	add_child(mi)


# ------------------------------------------------------------------ boucle

func _physics_process(delta: float) -> void:
	if not running or ended or waiting_quiz:
		return
	if countdown > 0.0:
		var before := ceili(countdown)
		countdown -= delta
		skater.frozen = true
		if ceili(countdown) != before and countdown > 0.0:
			Sfx.play("tick")
		if countdown <= 0.0:
			skater.frozen = false
			Sfx.play("go")
			popup.emit("GO !", Color(0.4, 1, 0.5))
		time_changed.emit(time_left)
		return
	Sfx.update_skate(skater.hspeed, skater.state == Skater.S.GRIND, skater.state != Skater.S.BAIL and not skater.frozen)
	total_time += delta
	if mode != "free" and not Save.no_timer:
		time_left -= delta
	var tl := ceili(time_left)
	if tl != _last_tick:
		_last_tick = tl
		if tl <= 5 and tl > 0:
			Sfx.play("tick", 1.4)
		time_changed.emit(time_left)
	if skater.state == Skater.S.GRIND:
		_grind_pts_acc += delta
		var step := int(_grind_pts_acc * 10.0)
		if step > 0:
			_grind_pts_acc -= step / 10.0
			pending += step * 4
			_emit_combo(true)
	if combo_grace > 0.0:
		combo_grace -= delta
		if combo_grace <= 0.0:
			_bank()
	if mode == "collect" and coins_run >= get_coin_total():
		_finish()
	if time_left <= 0.0 and mode != "free" and not Save.no_timer:
		_finish()


func _on_trick(trick_name: String, pts: int) -> void:
	tricks += 1
	pending += pts
	if not trick_name.is_valid_int() or trick_name == "180":
		mult = mini(mult + 1, 6)
	combo_names.append(trick_name)
	if combo_names.size() > 3:
		combo_names.pop_front()
	combo_grace = 0.0
	Sfx.play("combo", 1.0 + mult * 0.04, 0.05)
	_emit_combo(true)


func _on_landed(_clean: bool, _air: float) -> void:
	if pending > 0:
		combo_grace = 1.6
		_emit_combo(false)


func _on_grind_end(_d: float) -> void:
	combo_grace = 1.6


func _on_bail(_reason: String) -> void:
	bails += 1
	if pending > 0:
		popup.emit(tr("RATÉ !"), Color(1, 0.4, 0.4))
	pending = 0
	mult = 0
	combo_names.clear()
	combo_grace = 0.0
	if mode != "free" and not Save.no_timer:
		time_left = maxf(0.0, time_left - 2.0)
	_emit_combo(false)
	cam.shake = 2.5 if Save.shake else 0.0
	bailed_sig.emit()


func _emit_combo(active: bool) -> void:
	var label := " + ".join(combo_names.map(func(x): return str(x)))
	combo_changed.emit(pending, maxi(mult, 1), label, active)


func _bank() -> void:
	if pending > 0:
		var pts := pending * maxi(mult, 1)
		best_combo = maxi(best_combo, pts)
		score += pts
		Sfx.play("bank")
		bank.emit(pts)
		score_changed.emit(score)
	pending = 0
	mult = 0
	combo_names.clear()
	combo_grace = 0.0
	_emit_combo(false)


func on_pickup(kind: String, idx: int, pos: Vector3) -> void:
	if kind == "coin":
		coins_run += 1
		score += 10
		Sfx.play("coin", 1.0 + (coins_run % 8) * 0.04, 0.03)
		coin_got.emit(coins_run)
		score_changed.emit(score)
	elif kind == "decoy":
		time_left = maxf(1.0, time_left - 2.0)
		Sfx.play("deny")
		popup.emit("Essaie la lettre suivante", Color(1, 0.8, 0.6))
	else:
		if ended or completed_word or idx < 0 or idx >= letters.size() or letters[idx]:
			return
		letters[idx] = true
		Sfx.play("letter")
		letter_got.emit(idx)
		popup.emit("%s !" % target_word[idx], Color(1, 0.9, 0.3))
		score += 250
		score_changed.emit(score)
		if not letters.has(false):
			score += 3000 - 250 * target_word.length()
			completed_word = true
			Lexicon.discover(word_data)
			popup.emit(target_word + " = " + str(word_data["fr"]) + "  +3000", Color(1, 0.5, 0.9))
			waiting_quiz = true
			Sfx.update_skate(0.0, false, false)
			skater.frozen = true
			word_completed.emit(word_data)
			score_changed.emit(score)


func stars_for(s: int) -> int:
	var a: Array = lv["stars"]
	if s >= a[1]:
		return 3
	if s >= (a[0] + a[1]) / 2:
		return 2
	if s >= a[0]:
		return 1
	return 0


func _finish() -> void:
	if ended:
		return
	_bank()
	ended = true
	Sfx.stop_run()
	var st := stars_for(score)
	if mode == "career":
		st = (1 + (1 if score >= int(lv.stars[0]) else 0) + (1 if best_combo >= 400 else 0)) if completed_word else 0
	elif mode == "word":
		st = 3 if completed_word else 0
	elif mode == "combo":
		st = 3 if best_combo >= 1200 else (2 if best_combo >= 700 else (1 if best_combo >= 400 else 0))
	elif mode == "collect":
		st = 3 if coins_run >= get_coin_total() else 0
	elif mode == "free":
		st = 0
	var res := {
		"word": target_word, "word_size": target_word.length(), "mode": mode, "elapsed": total_time, "level": level_id, "score": score, "stars": st, "coins": coins_run,
		"letters": letters.count(true), "best_combo": best_combo, "tricks": tricks, "bails": bails,
		"max_air": skater.stats["max_air"], "max_speed": skater.stats["max_speed"], "grinds": skater.stats["grinds"],
		"skate": not letters.has(false), "objectives": objectives(), "coin_total": get_coin_total(), "thresholds": lv.stars,
	}
	skater.frozen = true
	finished.emit(res)


func end_now() -> void:
	_finish()


func accept_pickup(kind: String, idx: int) -> bool:
	if ended or demo or waiting_quiz or not running:
		return false
	return kind != "letter" or not Save.ordered_letters or idx == letters.find(false)

func resume_after_word() -> void:
	if not waiting_quiz:
		return
	waiting_quiz = false
	skater.frozen = false
	if mode == "word":
		_finish()

func get_coin_total() -> int:
	var remaining := 0
	for item in get_tree().get_nodes_in_group("pickups"):
		if item.game == self and item.kind == "coin" and not item.taken:
			remaining += 1
	return coins_run + remaining

func objectives() -> Array:
	var star_score: int = int(lv.stars[0])
	return [{"text": tr("Mot ") + target_word, "done": completed_word}, {"text": "Score ≥ " + str(star_score), "done": score >= star_score}, {"text": "Combo ≥ 400", "done": best_combo >= 400}]

var tutorial_step := 0
var tutorial_skipped := false
func tutorial_text() -> String:
	if mode != "career" or level_id != 1 or Save.runs > 0 or tutorial_skipped:
		return ""
	var instructions := ["1/6 · Avance avec Z / ↑ puis tourne avec Q/D.  (T : passer)", "2/6 · Espace : saute !  (T : passer)", "3/6 · X ou Maj : fais un flip dans les airs.", "4/6 · C ou Ctrl : maintiens un grab pendant le saut.", "5/6 · Saute sur un rail dans son axe pour grinder.", "6/6 · Ramasse les lettres dorées pour compléter le mot.", "À toi de jouer ! Atterris proprement pour encaisser tes combos."]
	if tutorial_step == 0 and total_time > 3 and skater.hspeed > 5:
		tutorial_step += 1
	elif tutorial_step == 1 and skater.state == Skater.S.AIR:
		tutorial_step += 1
	elif tutorial_step == 2 and skater.flips > 0:
		tutorial_step += 1
	elif tutorial_step == 3 and skater.grab_time > 0.3:
		tutorial_step += 1
	elif tutorial_step == 4 and int(skater.stats.grinds) > 0:
		tutorial_step += 1
	elif tutorial_step == 5 and completed_word:
		tutorial_step += 1
	return tr(instructions[clampi(tutorial_step, 0, 6)])

func _exit_tree() -> void:
	# Godot 4.3's dummy renderer logs mesh_get_surface_count(null) during
	# MeshInstance3D destruction if the mesh remains bound. Release explicitly.
	for visual in find_children("*", "MeshInstance3D", true, false):
		visual.mesh = null
	for visual in find_children("*", "MultiMeshInstance3D", true, false):
		visual.multimesh = null
