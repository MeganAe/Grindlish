extends Node
## Navigation entre les écrans, lancement des parties, sauvegarde des résultats, harnais de test.

const GameScript := preload("res://game.gd")
const UiScript := preload("res://ui.gd")
const TouchScript := preload("res://touch.gd")
const Lv := preload("res://levels.gd")

var ui: CanvasLayer
var touch: Control
var game: Node3D
var rebind_action := ""
var state := "menu"
var level_id := 1
var args := {}
var options_from_pause := false
var _ended_flow := false
var _auto_quit := false
var _test_failures := 0
var quitting := false
var last_result := {}


func _ready() -> void:
	get_tree().auto_accept_quit = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_apply_saved_bindings()
	_parse_args()
	ui = UiScript.new()
	add_child(ui)
	ui.action.connect(_on_action)
	var tl := CanvasLayer.new()
	tl.layer = 9
	add_child(tl)
	touch = TouchScript.new()
	tl.add_child(touch)
	touch.visible = false
	_apply_test_flags()
	match str(args.get("screen", "menu")):
		"play":
			_begin(int(args.get("level", 1)))
		"levels":
			_show_levels()
		"briefing":
			_backdrop(1)
			ui.show_briefing(int(args.get("level", 1)))
		"quiz":
			_backdrop(1)
			ui.show_word_quiz(Lexicon.words[0])
		"credits":
			_backdrop(1)
			ui.show_credits()
		"teacher":
			_backdrop(1)
			ui.show_teacher()
		"modes":
			_backdrop(1)
			ui.show_modes()
		"controls":
			_backdrop(1)
			ui.show_controls()
		"help":
			_backdrop(1)
			ui.show_help()
		"notebook":
			_backdrop(1)
			ui.show_notebook()
		"shop3d":
			_backdrop(1)
			ui.show_shop_preview()
		"shop":
			_show_shop()
		"options":
			_show_options(false)
		"pause", "end":
			_begin(int(args.get("level", 1)))
		_:
			_show_menu()
	if str(args.get("test", "")) in ["learning", "safety", "systems", "modes", "collision", "vocabulary", "life"]:
		var suite := preload("res://test_suite.gd").new()
		suite.host = self
		add_child(suite)
		suite.run("safety" if str(args.test) == "collision" else ("systems" if str(args.test) == "vocabulary" else str(args.test)))
	elif str(args.get("test", "")) == "flow":
		_flow_test()
	elif str(args.get("test", "")) == "collision":
		_collision_test()
	elif str(args.get("test", "")) == "vocabulary":
		_vocabulary_test()
	elif args.has("shot"):
		_shot()
	elif args.has("run"):
		_run()


# ================================================================= entrées

func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_LEFT], "move_right": [KEY_RIGHT], "move_up": [KEY_UP], "move_down": [KEY_DOWN],
		"jump": [KEY_SPACE], "flip": [KEY_X, KEY_SHIFT], "grab": [KEY_C, KEY_CTRL],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.5)
		InputMap.action_erase_events(a)
		for k in keys[a]:
			var e := InputEventKey.new()
			e.keycode = k
			InputMap.action_add_event(a, e)
	# ZQSD sur AZERTY = touches physiques WASD
	var phys := {"move_left": KEY_A, "move_right": KEY_D, "move_up": KEY_W, "move_down": KEY_S}
	for a in phys:
		var e := InputEventKey.new()
		e.physical_keycode = phys[a]
		InputMap.action_add_event(a, e)
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_TRIGGER_RIGHT, 1.0], "move_down": [JOY_AXIS_TRIGGER_LEFT, 1.0]}
	for a in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = axes[a][0]
		m.axis_value = axes[a][1]
		InputMap.action_add_event(a, m)
	var btn := {"jump": JOY_BUTTON_A, "flip": JOY_BUTTON_X, "grab": JOY_BUTTON_B, "pause": JOY_BUTTON_START,
		"move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT}
	for a in btn:
		var b := InputEventJoypadButton.new()
		b.button_index = btn[a]
		InputMap.action_add_event(a, b)


func _parse_args() -> void:
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Engine.set_meta("mode", str(args.get("mode", "career")))
	if args.has("density"):
		Save.life_density = clampi(int(args.density),0,2)
	if args.has("quality"):
		Save.quality = clampi(int(args.quality),0,2)
		Save.apply_settings()
	if args.has("locale"):
		Save.locale = str(args.locale)
		TranslationServer.set_locale(Save.locale)
	if args.has("word"):
		Engine.set_meta("word", str(args["word"]))
	if args.has("res"):
		var dims := str(args["res"]).split("x")
		if dims.size() == 2:
			get_window().size = Vector2i(int(dims[0]), int(dims[1]))
	if args.has("auto"):
		Engine.set_meta("auto", true)
	if args.has("god"):
		Engine.set_meta("god", true)
	if args.has("nosave"):
		Save.no_save = true


func _apply_test_flags() -> void:
	if args.has("unlock"):
		Save.unlocked = int(args["unlock"])
	if args.has("coins"):
		Save.coins = int(args["coins"])
	if args.has("stars"):
		for i in Lv.count():
			Save.stars[str(i + 1)] = int(args["stars"])
	if args.has("touch"):
		Save.touch = true
	if args.has("cheat"):
		Save.unlocked = Lv.count()
	if args.has("seed-words"):
		for index in mini(8, Lexicon.words.size()):
			Lexicon.discover(Lexicon.words[index])


func _unhandled_input(event: InputEvent) -> void:
	if not rebind_action.is_empty():
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
			rebind_action = ""
			ui.show_controls(options_from_pause)
		elif (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed):
			Save.key_bindings[rebind_action] = {"kind": "key", "code": event.physical_keycode} if event is InputEventKey else {"kind": "pad", "code": event.button_index}
			_apply_saved_bindings()
			Save.save_data()
			rebind_action = ""
			ui.show_controls(options_from_pause)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_T and state == "play" and game:
		game.tutorial_skipped = true
	if event.is_action_pressed("pause"):
		if state == "play":
			_pause()
		elif state == "pause":
			_resume()
		elif state == "options" and options_from_pause:
			_on_action("options_back", null)
		get_viewport().set_input_as_handled()


# ================================================================= écrans

func _free_game() -> void:
	Sfx.stop_run()
	get_tree().paused = false
	if game:
		game.queue_free()
		game = null
	touch.release_all()
	touch.visible = false


func _backdrop(id: int) -> void:
	_free_game()
	game = GameScript.new()
	game.demo = true
	add_child(game)
	game.setup(id)


func _show_menu() -> void:
	if quitting:
		return
	state = "menu"
	_backdrop(clampi(Save.unlocked, 1, Lv.count()) if args.has("cheat") else 1 + (Time.get_ticks_msec() / 1000) % mini(Save.unlocked, Lv.count()))
	ui.show_menu()
	Sfx.play_music("menu")


func _show_levels() -> void:
	state = "levels"
	if game == null or not game.demo:
		_backdrop(1)
	ui.show_levels()


func _show_shop() -> void:
	state = "shop"
	if game == null or not game.demo:
		_backdrop(1)
	ui.show_shop()


func _show_options(from_pause: bool) -> void:
	options_from_pause = from_pause
	state = "options"
	if game == null:
		_backdrop(1)
	ui.show_options(from_pause)


func _begin(id: int) -> void:
	if quitting:
		return
	level_id = id
	_free_game()
	game = GameScript.new()
	game.debug_lines = args.has("debug")
	add_child(game)
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.setup(id)
	game.finished.connect(_on_finished)
	game.word_completed.connect(_word_quiz)
	ui.clear_for_play()
	ui.bind_game(game)
	ui.time_label.text = ui.fmt_time(game.time_left)
	state = "play"
	_ended_flow = false
	touch.visible = Save.touch or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	Sfx.play_music("park" + str(id))
	Sfx.set_ambience(id)
	if args.has("auto"):
		var ap := preload("res://autopilot.gd").new()
		ap.game = game
		game.add_child(ap)
	if args.has("overview") or args.has("life-camera"):
		game.cam.set_process(false)
		if args.has("life-camera"):
			var h := Vector2(float(game.lv.size[0]),float(game.lv.size[1]))*1.25
			game.cam.position = Vector3(-h.x-12,5,h.y+12)
			game.cam.look_at(Vector3(-h.x-3,1,h.y-5),Vector3.UP)
		else:
			game.cam.position = Vector3(65,39,75)
			if args.has("overview-camera"):
				var xyz := str(args["overview-camera"]).split(",")
				if xyz.size()==3:
					game.cam.position = Vector3(float(xyz[0]),float(xyz[1]),float(xyz[2]))
			game.cam.look_at(Vector3(0,2,-12),Vector3.UP)
		ui.screen.visible = false
		ui.hud.visible = false
		touch.visible = false
	if str(args.get("screen", "")) == "pause" and not _ended_flow:
		get_tree().create_timer(0.1).timeout.connect(_pause)
	if str(args.get("screen", "")) == "end":
		get_tree().create_timer(0.3).timeout.connect(func(): if game: game.end_now())
	_ended_flow = false


func _pause() -> void:
	if state != "play" or game.ended:
		return
	state = "pause"
	get_tree().paused = true
	touch.release_all()
	touch.visible = false
	ui.show_pause()


func _resume() -> void:
	state = "play"
	get_tree().paused = false
	ui.close_overlay()
	touch.visible = Save.touch or OS.has_feature("mobile")


func _on_finished(res: Dictionary) -> void:
	state = "end_wait"
	last_result = res
	Sfx.play("go", 0.8)
	ui.announce("MOT COMPLÉTÉ !" if res.get("mode") == "word" and res.get("skate") else "FIN DE SESSION", Color.WHITE)
	touch.release_all()
	touch.visible = false
	var finished_game_id := game.get_instance_id()
	get_tree().create_timer(1.0, true, true).timeout.connect(func():
		if is_instance_valid(game) and game.get_instance_id() == finished_game_id and state == "end_wait":
			_show_end(res))


func _show_end(res: Dictionary) -> void:
	if _ended_flow or game == null:
		return
	_ended_flow = true
	if str(res.get("mode", "career")) != "career":
		Save.record(res)
		Save.save_data()
		state = "end"
		ui.show_end(res, {"has_next": false, "unlocked_new": false, "new_record": false, "bonus": 0})
		return
	var id: int = res["level"]
	var stars: int = res["stars"]
	var old_best := Save.get_best(id)
	Save.record(res)
	var bonus: int = stars * 25 + (60 if res["skate"] else 0)
	Save.coins += int(res["coins"]) + bonus
	Save.set_stars(id, stars)
	Save.update_best(id, int(res["score"]))
	Save.total_score += int(res["score"])
	Save.runs += 1
	var unlocked_new := false
	if stars >= 1 and id >= Save.unlocked and id < Lv.count():
		Save.unlocked = id + 1
		unlocked_new = true
	Save.save_data()
	state = "end"
	Sfx.play("win" if stars > 0 else "lose")
	ui.show_end(res, {
		"has_next": id < Lv.count() and id < Save.unlocked, "unlocked_new": unlocked_new,
		"new_record": int(res["score"]) > old_best, "bonus": bonus,
	})
	if args.has("autoflow"):
		_auto_quit = true


func _on_action(act: String, arg: Variant) -> void:
	match act:
		"reset_bindings":
			Save.key_bindings.clear()
			_setup_input()
			Save.save_data()
		"menu":
			ui.transition(_show_menu)
		"teacher":
			state = "teacher"
			ui.show_teacher()
		"modes":
			state = "modes"
			ui.show_modes()
		"mode":
			Engine.set_meta("mode", str(arg))
			_show_levels()
		"notebook":
			ui.show_notebook()
		"help":
			ui.show_help()
		"levels":
			ui.transition(_show_levels)
		"shop":
			ui.transition(_show_shop)
		"options":
			ui.transition(func(): _show_options(false))
		"options_pause":
			_show_options(true)
		"options_back":
			Save.save_data()
			if options_from_pause and game and not game.demo:
				ui.show_pause()
				state = "pause"
			else:
				ui.transition(_show_menu)
		"life_changed":
			if game:
				game.make_life()
		"quality_changed":
			if game:
				game.make_life()
				game.skater.god = Engine.has_meta("god") or Save.no_fall
				for child in game.get_children():
					if child is DirectionalLight3D:
						child.shadow_enabled = Save.quality > 0
		"rebind":
			rebind_action = str(arg)
			ui.announce("Appuie sur une touche / un bouton", Color.WHITE, 42)
		"touch_changed":
			touch.release_all()
			touch._layout()
		"play":
			if args.has("test") or args.has("auto"):
				ui.transition(func(): _begin(int(arg)))
			else:
				state = "briefing"
				ui.show_briefing(int(arg))
		"launch":
			ui.transition(func(): _begin(int(arg)))
		"restart":
			ui.transition(func(): _begin(level_id))
		"next":
			ui.transition(func(): _begin(mini(level_id + 1, Lv.count())))
		"pause":
			_pause()
		"resume":
			_resume()
		"abandon":
			ui.transition(_show_levels)
		"quit":
			_quit_cleanly()


# ================================================================= tests

func _shot() -> void:
	var fr := int(args.get("frame", 120))
	for i in fr:
		await get_tree().physics_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args["shot"])
	if game and game.skater:
		var s: CharacterBody3D = game.skater
		print("STATE pos=", s.global_position, " st=", s.state, " score=", game.score, " coins=", game.coins_run, " letters=", game.letters)
	_quit_cleanly()


func _run() -> void:
	var n := int(args.get("run", 600))
	var t0 := Time.get_ticks_msec()
	for i in n:
		await get_tree().physics_frame
		if i % 120 == 0 and game and game.skater:
			var s: CharacterBody3D = game.skater
			print("T=", i / 60, " pos=", s.global_position.snapped(Vector3.ONE * 0.1), " v=", snappedf(s.velocity.length(), 0.1), " st=", s.state, " score=", game.score, " coins=", game.coins_run, " L=", game.letters.count(true), " bails=", game.bails, " st=", state)
		if _auto_quit:
			break
	print("DONE ms=", Time.get_ticks_msec() - t0, " state=", state, " res=", last_result)
	print("RENDER fps=", Engine.get_frames_per_second(), " drawcalls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	_quit_cleanly()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _check(cond: bool, what: String) -> void:
	if not cond:
		_test_failures += 1
	print(("OK   " if cond else "FAIL ") + what)


func _flow_test() -> void:
	Save.no_save = true
	await _wait(0.5)
	_check(state == "menu", "menu au démarrage")
	_on_action("levels", null)
	await _wait(0.6)
	_check(state == "levels", "écran niveaux")
	_on_action("play", 1)
	await _wait(0.6)
	_check(state == "play" and game != null and not game.demo, "partie lancée")
	await _wait(3.0)
	_check(not game.skater.frozen, "compte à rebours fini")
	_on_action("pause", null)
	_check(state == "pause" and get_tree().paused, "pause")
	var p0: Vector3 = game.skater.global_position
	await _wait(0.5)
	_check(game.skater.global_position.distance_to(p0) < 0.01, "jeu figé en pause")
	_on_action("options_pause", null)
	await _wait(0.2)
	_check(state == "options", "options depuis pause")
	_on_action("options_back", null)
	_check(state == "pause", "retour à la pause")
	_on_action("resume", null)
	_check(state == "play" and not get_tree().paused, "reprise")
	Input.action_press("move_up")
	Input.action_press("jump")
	await _wait(0.5)
	Input.action_release("jump")
	await _wait(0.8)
	Input.action_release("move_up")
	_check(game.skater.hspeed > 5.0 or game.skater.state != 0, "le skateur avance avec les touches")
	game.score = 15000
	# Synthetic fixture for objective/transition testing, not a reachability proof.
	game.completed_word = true
	game.best_combo = 500
	game.end_now()
	await _wait(2.0)
	_check(state == "end", "écran de fin")
	_check(last_result.get("stars", 0) == 3, "3 étoiles à 15000 pts (parc 1)")
	_check(Save.unlocked >= 2, "parc 2 débloqué")
	_on_action("next", null)
	await _wait(0.7)
	_check(state == "play" and level_id == 2, "parc suivant")
	_on_action("pause", null)
	_on_action("abandon", null)
	await _wait(0.7)
	_check(state == "levels", "abandon -> niveaux")
	_on_action("shop", null)
	await _wait(0.6)
	_check(state == "shop", "boutique")
	_on_action("menu", null)
	await _wait(0.6)
	_check(state == "menu", "retour menu")
	print("FLOW failures=", _test_failures)
	_quit_cleanly(1 if _test_failures else 0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_cleanly()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and state == "play":
		_pause()
	if what == NOTIFICATION_APPLICATION_PAUSED:
		Save.save_data()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play" and not args.has("test") and not args.has("shot") and not args.has("auto"):
		_pause()

func _vocabulary_test() -> void:
	Save.no_save = true
	var failed := 0
	var seen := {}
	for row in Lexicon.words:
		if str(row.word).is_empty() or str(row.fr).is_empty() or seen.has(row.word) or str(row.word).length() > 12:
			failed += 1
		seen[row.word] = true
		Lexicon.discover(row)
		Lexicon.answer(row.word, true)
		Lexicon.answer(row.word, false)
	for id in Lv.count():
		_begin(id + 1)
		for idx in game.target_word.length():
			game.on_pickup("letter", idx, Vector3.ZERO)
		if game.letters.has(false) or not Lexicon.progress.has(game.word_data.word):
			failed += 1
	print("VOCABULARY words=", Lexicon.words.size(), " invalid=", failed, " five park collection callbacks=checked; physical reachability not checked")
	_quit_cleanly(1 if failed > 0 else 0)


func _collision_test() -> void:
	Save.no_save = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 23817
	var anomalies := 0
	for id in Lv.count():
		_begin(id + 1)
		await get_tree().physics_frame
		game.countdown = 0.0
		game.skater.frozen = false
		game.time_left = 100000.0
		var sk: CharacterBody3D = game.skater
		var bounds: Vector2 = game.info.bounds * 0.5
		var checked := 0
		for trial in 100:
			var pos := Vector3(rng.randf_range(-bounds.x + 2, bounds.x - 2), 5, rng.randf_range(-bounds.y + 2, bounds.y - 2))
			sk.place(pos, Vector3.FORWARD.rotated(Vector3.UP, rng.randf_range(-PI, PI)))
			sk.velocity = sk.heading * rng.randf_range(4, 24)
			sk.velocity.y = rng.randf_range(-3, 12)
			sk.ai_input = {"steer": rng.randf_range(-1, 1), "throttle": 1.0, "jump_p": false, "jump_h": true, "flip_p": false, "grab_h": false}
			sk.autopilot = true
			for frame in 90:
				await get_tree().physics_frame
				var at: Vector3 = sk.global_position
				if not at.is_finite() or not sk.velocity.is_finite() or at.y < -0.5 or absf(at.x) > bounds.x + 0.5 or absf(at.z) > bounds.y + 0.5:
					anomalies += 1
					print("ANOMALY level=", id + 1, " trial=", trial, " pos=", at)
					break
			checked += 1
		print("COLLISION level=", id + 1, " trajectories=", checked, " cumulative_anomalies=", anomalies)
	print("COLLISION DONE anomalies=", anomalies, " checks=finite,ground,bounds; overlap and stuck not covered")
	_quit_cleanly(1 if anomalies else 0)


func _word_quiz(data: Dictionary) -> void:
	state = "quiz"
	touch.release_all()
	touch.visible = false
	if args.has("auto") or args.has("test"):
		# The AI run does not claim to validate pupil knowledge.
		_finish_word_quiz.call_deferred()
	else:
		Sfx.speak(data.word)
		ui.show_word_quiz(data, _finish_word_quiz)

func _finish_word_quiz() -> void:
	if not game or not game.waiting_quiz:
		return
	ui.close_overlay()
	state = "play"
	touch.visible = Save.touch or OS.has_feature("mobile")
	game.resume_after_word()


func _apply_saved_bindings() -> void:
	for action in Save.key_bindings:
		if not InputMap.has_action(action):
			continue
		var binding: Dictionary = Save.key_bindings[action]
		for old in InputMap.action_get_events(action):
			if (binding.kind == "key" and old is InputEventKey) or (binding.kind == "pad" and old is InputEventJoypadButton):
				InputMap.action_erase_event(action, old)
		var event: InputEvent
		if binding.kind == "key":
			var key := InputEventKey.new()
			key.physical_keycode = int(binding.code)
			event = key
		else:
			var pad := InputEventJoypadButton.new()
			pad.button_index = int(binding.code)
			event = pad
		InputMap.action_add_event(action, event)


func _quit_cleanly(code := 0) -> void:
	if quitting:
		return
	quitting = true
	Sfx.shutdown()
	_free_game()
	await get_tree().process_frame
	await get_tree().process_frame
	# The dummy audio driver's mixer also runs on its own real-time clock.
	OS.delay_msec(80)
	await get_tree().process_frame
	get_tree().quit(code)
