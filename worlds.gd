extends RefCounted
## World identity. Existing seven sky/light/track materials stay in levels/game.
static func profile(id: int) -> Dictionary:
	var names := ["Quartier des érables", "Place des arcades", "Plage et jetée", "Fonderie orange", "Jardin des lucioles", "Toits à l'aube", "Port des cargos", "Prairie des moulins", "Village des cimes", "Stade des étoiles"]
	var kinds := ["suburb", "plaza", "beach", "factory", "garden", "rooftop", "harbor", "meadow", "alpine", "stadium"]
	var music := ["chill.ogg", "time_driving.ogg", "calm.mp3", "downtempo.ogg", "infinite_descent.ogg", "flowing_rocks.ogg", "night_beach.ogg", "farm_frolics.ogg", "polka_train.ogg", "alpha_dance.ogg"]
	var ambience := ["birds.ogg", "city.ogg", "waves.ogg", "../loops/machine_04.ogg", "forest.mp3", "wind.ogg", "harbor.ogg", "meadow.ogg", "alpine.ogg", "stadium.ogg"]
	var weather := ["breeze", "cloud", "waves", "steam", "fireflies", "breeze", "waves", "leaves", "snow", "confetti"]
	var i := clampi(id - 1, 0, names.size() - 1)
	return {"id": id, "name": names[i], "kind": kinds[i], "music": "res://audio/music/" + music[i], "ambience": ("res://audio/loops/machine_04.ogg" if i==3 else "res://audio/worlds/" + ambience[i]), "weather": weather[i]}
