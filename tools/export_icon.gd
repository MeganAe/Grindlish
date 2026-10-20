extends SceneTree
func _initialize() -> void:
	var image := Image.new()
	image.load_svg_from_string(FileAccess.get_file_as_string("res://icon.svg"))
	image.save_png("res://build/icon.png")
	quit()
