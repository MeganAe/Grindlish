extends Node
## File-backed audio only: CC0 effects/music and offline public-domain-model speech.
const SOUND_MAP := {
	"jump": "pluck_001", "trick": "select_002", "coin": "select_001", "letter": "confirmation_001",
	"combo": "select_002", "bank": "confirmation_001", "click": "click_001", "back": "back_001",
	"buy": "confirmation_001", "deny": "question_001", "tick": "tick_001", "go": "select_002",
	"grind_on": "impactMetal_light_000", "grind": "impactMetal_light_001", "bail": "impactSoft_heavy_000",
	"land": "impactPlank_medium_000"
}
var shutting_down := false
var players: Array[AudioStreamPlayer] = []
var sounds := {}
var music_player: AudioStreamPlayer
var speech_player: AudioStreamPlayer
var rolling_player: AudioStreamPlayer
var grind_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var current_music := ""
var _last_play := {}
var _next := 0
var music_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX", "Interface", "Voice", "Ambience"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, bus)
	for i in 8:
		players.append(_player("SFX"))
	music_player = _player("Music")
	speech_player = _player("Voice")
	rolling_player = _player("SFX")
	grind_player = _player("SFX")
	ambience_player = _player("Ambience")
	for key in SOUND_MAP:
		sounds[key] = load("res://audio/sfx/" + SOUND_MAP[key] + ".ogg")
	sounds.win = load("res://audio/music/jingles_HIT00.ogg")
	sounds.lose = load("res://audio/music/jingles_HIT01.ogg")
	rolling_player.stream = _loop("res://audio/loops/rolling.ogg")
	grind_player.stream = _loop("res://audio/loops/noise_03.ogg")

func _player(bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player

func _loop(path: String) -> AudioStream:
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	return stream

func apply_volumes(music: float, sfx: float) -> void:
	for bus in ["Music", "SFX", "Interface", "Voice", "Ambience"]:
		var value := music if bus == "Music" else sfx
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.set_bus_volume_db(index, -80.0 if value <= 0.001 else linear_to_db(value))

func play(key: String, pitch := 1.0, min_gap := 0.0) -> void:
	if shutting_down or not sounds.has(key) or (get_tree().paused and key not in ["click", "back", "buy", "deny"]):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_play.get(key, -10.0)) < maxf(min_gap, 0.025):
		return
	_last_play[key] = now
	var player := players[_next]
	_next = (_next + 1) % players.size()
	player.bus = "Interface" if key in ["click", "back", "buy", "deny", "tick"] else "SFX"
	player.stream = sounds[key]
	player.pitch_scale = pitch * randf_range(0.97, 1.03)
	player.volume_db = -10.0
	player.play()

func play_music(key: String) -> void:
	if shutting_down:
		return
	if key == current_music:
		return
	current_music = key
	if music_tween:
		music_tween.kill()
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", -45.0, 0.25)
	music_tween.tween_callback(func():
		if key.is_empty():
			music_player.stop()
			return
		var path: String = "res://audio/music/chill.ogg" if key=="menu" else preload("res://worlds.gd").profile(int(key.trim_prefix("park"))).music
		music_player.stream = _loop(path)
		music_player.play())
	music_tween.tween_property(music_player, "volume_db", -12.0, 0.4)

func speak(word: String) -> void:
	if shutting_down:
		return
	var path := "res://audio/words/" + word.to_lower() + ".wav"
	for row in Lexicon.words:
		if row.word == word.to_lower() and not str(row.audio).is_empty():
			path = row.audio
	if ResourceLoader.exists(path):
		speech_player.stream = load(path)
		speech_player.volume_db = -3.0
		speech_player.play()

func update_skate(speed: float, grinding: bool, active: bool) -> void:
	var should_roll := active and not grinding and speed > 0.8
	if should_roll and not rolling_player.playing:
		rolling_player.play()
	rolling_player.stream_paused = not should_roll
	rolling_player.pitch_scale = clampf(speed / 10.0, 0.65, 1.6)
	rolling_player.volume_db = lerpf(-32.0, -17.0, clampf(speed / 18.0, 0, 1))
	if active and grinding and not grind_player.playing:
		grind_player.play()
	grind_player.stream_paused = not active or not grinding
	grind_player.volume_db = -23.0

func set_ambience(level: int) -> void:
	var path: String = preload("res://worlds.gd").profile(level).ambience
	ambience_player.stream = _loop(path)
	ambience_player.volume_db = -28.0
	ambience_player.play()

func stop_run() -> void:
	rolling_player.stop()
	grind_player.stop()
	ambience_player.stop()
	for player in players:
		player.stop()

func _process(_delta: float) -> void:
	var paused := get_tree().paused
	rolling_player.stream_paused = paused or rolling_player.stream_paused
	grind_player.stream_paused = paused or grind_player.stream_paused
	ambience_player.stream_paused = paused
	if music_tween == null or not music_tween.is_running():
		music_player.volume_db = -23.0 if speech_player.playing else -12.0

func shutdown() -> void:
	shutting_down = true
	if music_tween:
		music_tween.kill()
	for player in get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	sounds.clear()

func _exit_tree() -> void:
	shutdown()
