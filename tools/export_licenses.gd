extends SceneTree
func _initialize() -> void:
	var file := FileAccess.open("res://docs/licenses/GODOT_4.3.txt", FileAccess.WRITE)
	file.store_string(Engine.get_license_text() + "\n\n")
	file.store_string("THIRD PARTY COPYRIGHT NOTICES\n" + JSON.stringify(Engine.get_copyright_info(), "  ") + "\n\n")
	var licenses := Engine.get_license_info()
	for key in licenses:
		file.store_string("\n=== " + str(key) + " ===\n" + str(licenses[key]) + "\n")
	file.close()
	quit()
