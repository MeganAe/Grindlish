extends Node
## Sauvegarde (autoload "Save") : progression, boutique, réglages.

const PATH := "user://skate_jam.cfg"

var ordered_letters := false
var no_timer := false
var no_fall := false
var hints := true
var quality := 1
var fps_limit := 60
var left_handed := false
var touch_scale := 1.0
var text_scale := 1.0
var vocabulary_level := "ALL"
var locale := "fr"
var records := {}
var key_bindings := {}
var teacher_pin_hash := ""
var streak := 0
var last_day := ""
var coins := 0
var unlocked := 1
var stars := {}      # "1" -> 0..3
var best := {}       # "1" -> score max
var shop := {}       # id -> niveau acheté
var total_score := 0
var board := 0
var char_id := 0
var touch := false
var owned := {"c0": true, "b0": true}
var invert_cam := false
var runs := 0

var music := 0.7
var sfx := 0.8
var fullscreen := false
var shake := true
var numbers := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_migrate_legacy()
	load_data()
	apply_settings()


func load_data() -> void:
	if not FileAccess.file_exists(PATH) and not FileAccess.file_exists(PATH + ".bak"):
		return
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		if cfg.load(PATH + ".bak") != OK:
			return
	for key in ["ordered_letters", "no_timer", "no_fall", "hints", "quality", "fps_limit", "left_handed", "touch_scale", "text_scale", "vocabulary_level", "locale", "key_bindings", "teacher_pin_hash"]:
		if cfg.has_section_key("v2", key):
			set(key, cfg.get_value("v2", key))
	records = cfg.get_value("v2", "records", {})
	streak = int(cfg.get_value("v2", "streak", 0))
	last_day = str(cfg.get_value("v2", "last_day", ""))
	coins = int(cfg.get_value("progress", "coins", 0))
	unlocked = maxi(1, int(cfg.get_value("progress", "unlocked", 1)))
	stars = cfg.get_value("progress", "stars", {})
	best = cfg.get_value("progress", "best", {})
	shop = cfg.get_value("progress", "shop", {})
	total_score = int(cfg.get_value("progress", "total_score", 0))
	board = int(cfg.get_value("progress", "board", 0))
	owned = cfg.get_value("progress", "owned", {"c0": true, "b0": true})
	char_id = int(cfg.get_value("progress", "char_id", 0))
	touch = bool(cfg.get_value("settings", "touch", false))
	runs = int(cfg.get_value("progress", "runs", 0))
	music = float(cfg.get_value("settings", "music", 0.7))
	sfx = float(cfg.get_value("settings", "sfx", 0.8))
	fullscreen = bool(cfg.get_value("settings", "fullscreen", false))
	shake = bool(cfg.get_value("settings", "shake", true))
	numbers = bool(cfg.get_value("settings", "numbers", true))


var no_save := false


func save_data() -> void:
	if no_save:
		return
	var cfg := ConfigFile.new()
	for key in ["ordered_letters", "no_timer", "no_fall", "hints", "quality", "fps_limit", "left_handed", "touch_scale", "text_scale", "vocabulary_level", "locale", "records", "key_bindings", "teacher_pin_hash", "streak", "last_day"]:
		cfg.set_value("v2", key, get(key))
	cfg.set_value("v2", "schema", 2)
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "stars", stars)
	cfg.set_value("progress", "best", best)
	cfg.set_value("progress", "shop", shop)
	cfg.set_value("progress", "total_score", total_score)
	cfg.set_value("progress", "board", board)
	cfg.set_value("progress", "owned", owned)
	cfg.set_value("progress", "char_id", char_id)
	cfg.set_value("settings", "touch", touch)
	cfg.set_value("progress", "runs", runs)
	cfg.set_value("settings", "music", music)
	cfg.set_value("settings", "sfx", sfx)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.set_value("settings", "shake", shake)
	cfg.set_value("settings", "numbers", numbers)
	if cfg.save(PATH + ".tmp") == OK:
		if FileAccess.file_exists(PATH):
			DirAccess.copy_absolute(PATH, PATH + ".bak")
		DirAccess.rename_absolute(PATH + ".tmp", PATH)


func apply_settings() -> void:
	Sfx.apply_volumes(music, sfx)
	Engine.max_fps = fps_limit
	TranslationServer.set_locale(locale)
	if get_viewport():
		get_viewport().scaling_3d_scale = [0.65, 0.85, 1.0][clampi(quality, 0, 2)]
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)


func shop_level(id: String) -> int:
	return int(shop.get(id, 0))


func get_stars(level_id: int) -> int:
	return int(stars.get(str(level_id), 0))


func set_stars(level_id: int, n: int) -> void:
	if n > get_stars(level_id):
		stars[str(level_id)] = n


func update_best(level_id: int, score: int) -> void:
	best[str(level_id)] = maxi(int(best.get(str(level_id), 0)), score)


func get_best(level_id: int) -> int:
	return int(best.get(str(level_id), 0))


func reset_progress() -> void:
	coins = 0
	unlocked = 1
	stars = {}
	best = {}
	shop = {}
	owned = {"c0": true, "b0": true}
	board = 0
	char_id = 0
	total_score = 0
	runs = 0
	save_data()


func record(result: Dictionary) -> void:
	var key := str(result.mode) + ":" + str(result.level) + (":assist" if no_fall or no_timer else "")
	var value := float(result.score)
	if result.mode == "combo":
		value = float(result.best_combo)
	if result.mode in ["word", "collect"]:
		if result.mode == "word" and not result.skate:
			return
		if result.mode == "collect" and int(result.coins) < int(result.coin_total):
			return
		value = float(result.elapsed)
		records[key] = minf(float(records.get(key, INF)), value)
	elif result.mode != "free":
		records[key] = maxf(float(records.get(key, 0)), value)
	var today := Time.get_date_string_from_system()
	if today != last_day:
		var midnight := Time.get_unix_time_from_datetime_string(today + "T00:00:00")
		var previous := Time.get_unix_time_from_datetime_string(last_day + "T00:00:00") if not last_day.is_empty() else 0
		streak = streak + 1 if midnight - previous == 86400 else 1
		last_day = today

func _migrate_legacy() -> void:
	if FileAccess.file_exists(PATH):
		return
	var parent := OS.get_user_data_dir().get_base_dir()
	var legacy := parent.path_join("Skate Jam/skate_jam.cfg")
	if FileAccess.file_exists(legacy) and not OS.get_cmdline_user_args().has("--nosave"):
		DirAccess.copy_absolute(legacy, PATH)
