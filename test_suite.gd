extends Node
## Reproducible integration tests. Failing assertions result in a nonzero exit code.
var host: Node
var failures := 0
var checks := 0

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + text)

func ready_game() -> void:
	for frame in 120:
		if host.game and host.game.ready_for_run:
			return
		await get_tree().physics_frame
	check(false, "park initialisation timed out")

func run(kind: String) -> void:
	Save.no_save = true
	Save.no_fall = false
	Save.no_timer = false
	Save.ordered_letters = false
	Engine.set_meta("auto", true)
	host.args["auto"] = "1"
	if kind == "learning":
		await learning()
	elif kind == "safety":
		await safety()
	elif kind == "systems":
		await systems()
	elif kind == "life":
		await life_tests()
	elif kind == "modes":
		await modes()
	print("SUITE ", kind, " checks=", checks, " failures=", failures)
	host._free_game()
	await get_tree().process_frame
	host._quit_cleanly(1 if failures else 0)

func learning() -> void:
	var themes := ["skate", "town", "sea", "industry", "night"]
	for entry in Lexicon.words:
		var id: int = themes.find(entry.theme) + 1
		Engine.set_meta("word", str(entry.word))
		Engine.set_meta("mode", "word")
		host._begin(id)
		await ready_game()
		var game: Node3D = host.game
		game.time_left = 180.0
		var start: Vector3 = game.skater.global_position
		var travelled := 0.0
		var previous := start
		for frame in 10810:
			await get_tree().physics_frame
			travelled += previous.distance_to(game.skater.global_position)
			previous = game.skater.global_position
			if game.ended:
				break
		check(game.completed_word and game.ended and game.bails == 0,
			"physical word=" + str(entry.word) + " park=" + str(id) + " letters=" + str(game.letters.count(true)) + "/" + str(game.letters.size()) + " elapsed=" + str(snappedf(game.total_time, 0.01)) + " bails=" + str(game.bails) + " travel=" + str(snappedf(travelled, 0.1)))
		check(travelled > 5.0, "pilot actually moved for " + str(entry.word))
		check(not str(entry.audio).is_empty() and ResourceLoader.exists(str(entry.audio)), "audio exists " + str(entry.word))
	Engine.remove_meta("word")

func safety() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 731913
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.25
	for level in range(1, host.Lv.count() + 1):
		Engine.set_meta("mode", "free")
		host._begin(level)
		await ready_game()
		var game: Node3D = host.game
		# Fuzz uses its own inputs, not the route pilot.
		for child in game.get_children():
			if child.get_script() == preload("res://autopilot.gd"):
				child.queue_free()
		var sk: CharacterBody3D = game.skater
		var bounds: Vector2 = game.info.bounds * 0.5
		var violations := {"finite": 0, "floor": 0, "bounds": 0, "overlap": 0, "stuck": 0, "respawn": 0}
		for trial in 150:
			var point: Vector3 = game.routes.graph.get_point_position(game.routes.allowed[rng.randi_range(0, game.routes.allowed.size() - 1)])
			# Valid empty airborne start, followed by regular gravity/collisions.
			point.y = rng.randf_range(2.5, 7.0)
			sk.place(point, Vector3.FORWARD.rotated(Vector3.UP, rng.randf_range(-PI, PI)))
			sk.velocity = sk.heading * rng.randf_range(4, 32)
			sk.velocity.y = rng.randf_range(-10, 16)
			sk.autopilot = true
			sk.ai_input = {"steer": rng.randf_range(-1, 1), "throttle": 1.0, "jump_p": false, "jump_h": true, "flip_p": false, "grab_h": false}
			var unmoving := 0.0
			var before := point
			for frame in 240:
				await get_tree().physics_frame
				var at: Vector3 = sk.global_position
				if not at.is_finite() or not sk.velocity.is_finite():
					violations.finite += 1
					break
				if at.y < -0.5:
					violations.floor += 1
					break
				if absf(at.x) > bounds.x + 0.5 or absf(at.z) > bounds.y + 0.5:
					violations.bounds += 1
					break
				# Shrunk capsule excludes normal skin contact, not bodies in a solid hull.
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = capsule
				query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.95)
				query.exclude = [sk.get_rid()]
				var overlaps := game.get_world_3d().direct_space_state.intersect_shape(query, 8)
				if sk.state != sk.S.GRIND and not overlaps.is_empty():
					violations.overlap += 1
					print("OVERLAP park=", level, " trial=", trial, " frame=", frame, " pos=", at, " collider=", overlaps[0].collider.name)
					break
				unmoving = unmoving + 1.0 / 60.0 if at.distance_to(before) < 0.003 else 0.0
				before = at
				if unmoving > 3.0:
					# A known wall explains stopping. Empty-space stuck is an anomaly.
					var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP, at + Vector3.UP + sk.heading * 1.2)
					ray.exclude = [sk.get_rid()]
					if game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
						violations.stuck += 1
					break
			if trial % 10 == 0:
				var safe: Vector3 = sk._safe_respawn()
				if not sk._space_clear(safe) or not sk._supported(safe):
					violations.respawn += 1
		var count := 0
		for value in violations.values():
			count += int(value)
		check(count == 0, "collision park=" + str(level) + " 150x240 frames " + str(violations))

func systems() -> void:
	await interface_checks()
	await audio_mix_checks()
	var saved := Lexicon.progress.duplicate(true)
	Lexicon.progress.clear()
	var entry: Dictionary = Lexicon.words[0]
	Lexicon.discover(entry)
	Lexicon.answer(entry.word, false)
	check(Lexicon.due_words().size() == 1, "failed word is selected for review")
	Lexicon.answer(entry.word, true)
	check(Lexicon.due_words().is_empty(), "successful word scheduled in the future")
	Lexicon.progress = saved
	var words_seen := {}
	for entry2 in Lexicon.words:
		check(not words_seen.has(entry2.word) and ResourceLoader.exists(entry2.audio) and ResourceLoader.exists(entry2.image), "unique/audio/image " + str(entry2.word))
		words_seen[entry2.word] = true
	Engine.set_meta("mode", "free")
	host._begin(1)
	await ready_game()
	var game: Node3D = host.game
	var time: float = game.time_left
	host._pause()
	for frame in 60:
		await get_tree().physics_frame
	check(is_equal_approx(time, game.time_left), "timer paused")
	host._resume()
	check(not get_tree().paused, "resume unpauses")
	for frame in 60:
		await get_tree().physics_frame
	check(is_equal_approx(time, game.time_left), "free mode really has no timer")
	await touch_checks()
	check(game.routes.slots.size() == 12, "twelve safe connected word slots")
	for point in game.routes.slots:
		check(game.routes.path(game.routes.origin, point).size() > 0, "letter has connected path")


func modes() -> void:
	for level in range(1, host.Lv.count() + 1):
		for mode in ["career", "jam", "word", "combo", "collect", "daily", "free"]:
			Engine.set_meta("mode", mode)
			host._begin(level)
			await ready_game()
			var game: Node3D = host.game
			for frame in 11000:
				await get_tree().physics_frame
				if mode == "free" and game.completed_word:
					game.end_now()
				if game.ended:
					break
			var passed: bool = game.ended and game.completed_word
			if mode == "collect":
				passed = game.ended and game.coins_run == game.get_coin_total()
			check(passed, "mode=" + str(mode) + " park=" + str(level) + " score=" + str(game.score) + " combo=" + str(game.best_combo) + " word=" + str(game.completed_word) + " coins=" + str(game.coins_run) + "/" + str(game.get_coin_total()) + " elapsed=" + str(snappedf(game.total_time, 0.01)))


func touch_checks() -> void:
	host.touch.visible = true
	host.touch._layout()
	var event := InputEventScreenTouch.new()
	event.index = 5
	event.position = host.touch.buttons.jump.c
	event.pressed = true
	host.touch._input(event)
	check(Input.is_action_pressed("jump"), "touch jump press")
	event.pressed = false
	host.touch._input(event)
	check(not Input.is_action_pressed("jump"), "touch jump release")
	event.pressed = true
	host.touch._input(event)
	host.touch.release_all()
	check(not Input.is_action_pressed("jump"), "touch clears on pause/resize")
	get_tree().paused = true
	host.touch._input(event)
	check(not Input.is_action_pressed("jump"), "touch ignored while paused")
	get_tree().paused = false
	host.touch.release_all()

func interface_checks() -> void:
	var coins_before: int = Save.coins
	var owned_before: Dictionary = Save.owned.duplicate()
	var character_before: int = Save.char_id
	var board_before: int = Save.board
	Save.coins = 0
	Save.owned = {"c0": true, "b0": true}
	check(not host.ui._purchase_style("c", 1, 150) and Save.coins == 0 and not Save.owned.has("c1"), "insufficient coins cannot purchase style")
	Save.coins = 200
	check(host.ui._purchase_style("c", 1, 150) and Save.coins == 50 and Save.char_id == 1, "style purchase charges exact price")
	check(host.ui._purchase_style("c", 1, 150) and Save.coins == 50, "owned style can be equipped without payment")
	host.ui.show_shop_preview()
	await get_tree().process_frame
	check(Save.coins == 50, "3D preview does not charge coins")
	Save.coins = coins_before
	Save.owned = owned_before
	Save.char_id = character_before
	Save.board = board_before
	Save.key_bindings["jump"] = {"kind": "key", "code": KEY_J}
	host._apply_saved_bindings()
	var mapped: Array = InputMap.action_get_events("jump")
	check(mapped.any(func(event): return event is InputEventKey and event.physical_keycode == KEY_J), "physical key remapping applies")
	host._on_action("reset_bindings", null)
	mapped = InputMap.action_get_events("jump")
	check(Save.key_bindings.is_empty() and mapped.any(func(event): return event is InputEventKey and event.keycode == KEY_SPACE) and not mapped.any(func(event): return event is InputEventKey and event.physical_keycode == KEY_J), "reset removes old bindings and restores defaults")
	var before_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var label: Label = host.ui._lbl("Réglages")
	check(label.text == "Settings", "English menu translation loads")
	label.free()
	TranslationServer.set_locale(before_locale)
	var b1: Array = Lexicon.words.filter(func(word): return word.level == "B1")
	check(b1.size() == 10, "ten indicative B1 entries supplied")

func audio_mix_checks() -> void:
	var volumes := []
	for index in AudioServer.bus_count:
		volumes.append([AudioServer.get_bus_volume_db(index), AudioServer.is_bus_mute(index)])
		AudioServer.set_bus_volume_db(index, 0)
		AudioServer.set_bus_mute(index, false)
	if Sfx.music_tween:
		Sfx.music_tween.kill()
	var recording := AudioEffectRecord.new()
	recording.format = AudioStreamWAV.FORMAT_16_BITS
	var slot := AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, recording)
	for kind in ["effect", "voice", "music", "rolling"]:
		Sfx.stop_run()
		Sfx.speech_player.stop()
		Sfx.music_player.stop()
		recording.set_recording_active(true)
		match kind:
			"effect": Sfx.play("coin")
			"voice": Sfx.speak("board")
			"music":
				Sfx.music_player.stream = load("res://audio/music/chill.ogg")
				Sfx.music_player.play()
			"rolling": Sfx.update_skate(10.0, false, true)
		# Audio mixer runs on real time, independently from fixed-fps physics.
		OS.delay_msec(350)
		recording.set_recording_active(false)
		var wave: AudioStreamWAV = recording.get_recording()
		var nonzero := false
		for sample in wave.data:
			if sample != 0:
				nonzero = true
				break
		check(wave.data.size() > 0 and nonzero, "audio mixer produces non-silent " + kind)
	AudioServer.remove_bus_effect(0, slot)
	Sfx.stop_run()
	Sfx.speech_player.stop()
	Sfx.music_player.stop()
	Sfx.current_music = ""
	for index in volumes.size():
		AudioServer.set_bus_volume_db(index, volumes[index][0])
		AudioServer.set_bus_mute(index, volumes[index][1])

func life_tests() -> void:
	var music := {}
	var ambience := {}
	var Reference := load("res://docs/rendu/reference/code/levels.gd")
	for id in range(1,8):
		check(host.Lv.get_level(id)==Reference.get_level(id),"original level data unchanged id="+str(id))
	for id in range(1,11):
		var profile: Dictionary = preload("res://worlds.gd").profile(id)
		check(ResourceLoader.exists(profile.music) and ResourceLoader.exists(profile.ambience),"world audio exists id="+str(id))
		music[profile.music] = true
		ambience[profile.ambience] = true
	check(music.size()==10 and ambience.size()==10,"ten unique music and ambience mappings")
	var rows := []
	for setting in 3:
		Save.life_density = setting
		for id in range(1,11):
			Engine.set_meta("mode","free")
			host._begin(id)
			await ready_game()
			var game: Node3D = host.game
			var life: Node3D = game.life
			game.set_physics_process(false)
			game.skater.set_physics_process(false)
			life.set_physics_process(false)
			var rng := RandomNumberGenerator.new()
			rng.seed = 741+id
			var equivalent := true
			for trial in 1000:
				var a := Vector3(rng.randf_range(-150,150),rng.randf_range(0,40),rng.randf_range(-150,150))
				var b := a+Vector3(rng.randf_range(-20,20),rng.randf_range(-5,5),rng.randf_range(-20,20))
				var radius := rng.randf_range(.2,3.5)
				var height := rng.randf_range(.3,2.5)
				equivalent = equivalent and life.clear_sweep(a,b,radius,height)==life.clear_sweep_brute(a,b,radius,height)
			check(equivalent,"spatial hash equals exhaustive sweep: 1000 segments id=%d density=%d" % [id,setting])

			var counts := {"arena":0,"solid":0,"skater":0,"pair":0,"sweep":0}
			var query := PhysicsShapeQueryParameters3D.new()
			var shape := BoxShape3D.new()
			query.shape = shape
			query.collide_with_areas = false
			for step in 1200:
				life.advance(.05)
				for i in life.agents.size():
					var agent: Dictionary = life.agents[i]
					var at: Vector3 = agent.node.position
					if absf(at.x)<life.half.x+agent.radius and absf(at.z)<life.half.y+agent.radius:
						counts.arena += 1
					if not life.clear_sweep(agent.previous,at,agent.radius,agent.height):
						counts.sweep += 1
					if at.distance_to(game.skater.position)<agent.radius+.55:
						counts.skater += 1
					for j in range(i+1,life.agents.size()):
						var other: Dictionary = life.agents[j]
						var there: Vector3 = other.node.position
						if absf(at.y-there.y)<minf(agent.height,other.height) and at.distance_to(there)<agent.radius+other.radius-.02:
							counts.pair += 1
					# Real physics overlap every second; feet remain 8 cm above ground.
					if step%20==0 and agent.type!="fish":
						shape.size = Vector3(agent.radius*2,agent.height,agent.radius*2)
						query.transform = Transform3D(Basis.IDENTITY,at+Vector3.UP*(agent.height*.5+.02))
						if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
							counts.solid += 1
			var moved := true
			var pedestrians := 0
			var pauses := 0
			for agent in life.agents:
				moved = moved and agent.moved>3
				if agent.type=="person":
					pedestrians += 1
					pauses += agent.stops
			check(counts.values().all(func(v): return v==0),"life safety id=%d density=%d violations=%s" % [id,setting,str(counts)])
			check(moved and pauses>0 and pedestrians==[4,8,12][setting],"life moves and pauses id=%d density=%d agents=%d" % [id,setting,life.agents.size()])
			game.bank.emit(800)
			life.advance(.1)
			check(life.reaction>2 and life.agents[0].state=="emote-yes","large figure reaction id="+str(id)+" density="+str(setting))
			rows.append({"world":id,"density":setting,"seconds":60,"agents":life.agents.size(),"violations":counts,"blocked_steps":life.blocked_steps,"conversations":life.conversations,"moving":moved})
			await get_tree().process_frame
	check(rows.any(func(row): return row.conversations>0),"nearby pedestrians really stop and talk in simulation")
	var file := FileAccess.open("res://docs/rendu/tests/life_details.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(rows,"  "))
	file.close()
	Save.life_density = 1
