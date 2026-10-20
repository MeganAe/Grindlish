extends Node
## Offline vocabulary and review scheduler. Source JSON is never overwritten.
var words: Array = []
var progress: Dictionary = {}
var validation_errors: Array[String] = []
const PATH := "user://grindlish_words.json"
const CUSTOM := "user://custom_words.json"

func _ready() -> void:
	load_words()
	for file in [PATH, PATH + ".bak"]:
		if FileAccess.file_exists(file):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(file))
			if parsed is Dictionary:
				progress = parsed
				break

func load_words() -> void:
	words.clear()
	validation_errors.clear()
	var source := CUSTOM if FileAccess.file_exists(CUSTOM) else "res://data/words.json"
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(source))
	if not parsed is Array:
		validation_errors.append("Le fichier doit contenir un tableau JSON.")
		parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json"))
	var seen := {}
	var expression := RegEx.new()
	expression.compile("^[a-z]{1,12}$")
	for row in parsed:
		if not row is Dictionary:
			validation_errors.append("Entrée non structurée ignorée.")
			continue
		var word := str(row.get("word", ""))
		if expression.search(word) == null or seen.has(word) or str(row.get("fr", "")).is_empty():
			validation_errors.append("Mot invalide ou dupliqué : " + word)
			continue
		if not ["skate", "town", "sea", "industry", "night"].has(row.get("theme")):
			validation_errors.append("Thème invalide : " + word)
			continue
		seen[word] = true
		for key in ["definition", "example", "audio", "image"]:
			row[key] = str(row.get(key, ""))
		row.level = str(row.get("level", "A1"))
		words.append(row)

func choose(id: int) -> Dictionary:
	var themes := ["skate", "town", "sea", "industry", "night", "night", "sea"]
	var theme: String = themes[clampi(id - 1, 0, themes.size() - 1)]
	var pool: Array = words.filter(func(w): return w.theme == theme and (Save.vocabulary_level == "ALL" or w.level == Save.vocabulary_level))
	if pool.is_empty():
		pool = words.filter(func(w): return w.theme == theme)
	if pool.is_empty():
		pool = words
	if str(Engine.get_meta("mode", "")) == "daily":
		return pool[absi((Time.get_date_string_from_system() + str(id)).hash()) % pool.size()]
	for w in pool:
		if not progress.has(w.word):
			return w
	return pool[int(Save.runs) % pool.size()]

func discover(w: Dictionary) -> void:
	if not progress.has(w.word):
		progress[w.word] = {"mastery": 0, "due": 0, "attempts": 0, "correct": 0}
	persist()

func due_words(now := -1.0) -> Array:
	if now < 0:
		now = Time.get_unix_time_from_system()
	var out: Array = []
	for row in words:
		if progress.has(row.word) and float(progress[row.word].get("due", 0)) <= now:
			out.append(row)
	out.sort_custom(func(a, b):
		var pa: Dictionary = progress[a.word]
		var pb: Dictionary = progress[b.word]
		if int(pa.mastery) != int(pb.mastery):
			return int(pa.mastery) < int(pb.mastery)
		return float(pa.get("due", 0)) < float(pb.get("due", 0)))
	return out

func answer(word: String, correct: bool) -> void:
	if not progress.has(word):
		return
	var entry: Dictionary = progress[word]
	entry.mastery = clampi(int(entry.mastery) + (1 if correct else -1), 0, 5)
	entry.attempts = int(entry.get("attempts", 0)) + 1
	entry.correct = int(entry.get("correct", 0)) + (1 if correct else 0)
	entry.due = Time.get_unix_time_from_system() + (pow(2, entry.mastery - 1) * 86400 if correct else 0)
	persist()

func persist() -> void:
	if Save.no_save:
		return
	var f := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(progress))
		f.close()
		if FileAccess.file_exists(PATH):
			DirAccess.copy_absolute(PATH, PATH + ".bak")
		DirAccess.rename_absolute(PATH + ".tmp", PATH)

func export_csv(path: String) -> Error:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		return FileAccess.get_open_error()
	f.store_csv_line(PackedStringArray(["word", "fr", "level", "discovered", "mastery", "attempts", "correct", "next_review_unix"]))
	for row in words:
		var entry: Dictionary = progress.get(row.word, {})
		f.store_csv_line(PackedStringArray([row.word, row.fr, row.level, str(progress.has(row.word)), str(entry.get("mastery", 0)), str(entry.get("attempts", 0)), str(entry.get("correct", 0)), str(entry.get("due", 0))]))
	f.close()
	return OK

func import_custom(path: String) -> String:
	var candidate = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not candidate is Array or candidate.is_empty() or candidate.size() > 500:
		return "Import refusé : tableau JSON attendu (1–500 mots)."
	var old := FileAccess.get_file_as_string(CUSTOM) if FileAccess.file_exists(CUSTOM) else ""
	var file := FileAccess.open(CUSTOM, FileAccess.WRITE)
	if not file:
		return "Impossible d'écrire le vocabulaire local."
	file.store_string(JSON.stringify(candidate))
	file.close()
	load_words()
	if not validation_errors.is_empty() or words.is_empty():
		var errors := "; ".join(validation_errors)
		if old.is_empty():
			DirAccess.remove_absolute(CUSTOM)
		else:
			file = FileAccess.open(CUSTOM, FileAccess.WRITE)
			file.store_string(old)
			file.close()
		load_words()
		return "Import annulé : " + errors
	return "%d mots importés. Les prononciations non fournies restent silencieuses." % words.size()
