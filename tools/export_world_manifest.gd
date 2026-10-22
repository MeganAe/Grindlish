extends SceneTree
func _initialize() -> void:
	var worlds := []
	for id in range(1,11):
		var level := preload("res://levels.gd").get_level(id)
		var profile := preload("res://worlds.gd").profile(id)
		profile["bonus"] = id in [6,7]
		profile["sky"] = [level.sky[0].to_html(),level.sky[1].to_html()]
		profile["outer"] = level.outer.to_html()
		profile["floor"] = level.get("floor_colour",Color("b9ad94") if level.floor=="wood" else Color("778b91")).to_html()
		profile["ambient_energy"] = .4 if id in [5,6] else .55
		profile["sun_energy"] = .45 if id in [5,6] else .85
		profile["arena_layout_sha256"] = var_to_bytes(level.pieces).hex_encode().sha256_text()
		profile["global_fog"] = false
		worlds.append(profile)
	var f := FileAccess.open("res://docs/rendu/worlds.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(worlds,"  "))
	f.close()
	quit()
