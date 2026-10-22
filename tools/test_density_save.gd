extends SceneTree
## Isolated persistence/migration test. Refuses to touch normal user data.
var store: Node
func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var sandbox := OS.get_environment("XDG_DATA_HOME")
	if not sandbox.ends_with("density_save_test") or not OS.get_user_data_dir().begins_with(sandbox):
		printerr("Refusing non-isolated save test")
		quit(2)
		return
	store = get_root().get_node("Save")
	store.no_save = false
	var config := ConfigFile.new()
	config.set_value("progress","unlocked",7)
	config.set_value("progress","coins",123)
	config.set_value("progress","best",{"4":8000})
	assert(config.save(store.PATH)==OK)
	store.life_density = 1
	store.load_data()
	assert(store.life_density==1 and store.unlocked==7 and store.coins==123 and store.best["4"]==8000)
	print("PASS legacy save without density retains progress and medium default")
	store.life_density = 2
	store.save_data()
	store.life_density = 0
	store.load_data()
	assert(store.life_density==2 and store.unlocked==7 and store.coins==123 and store.best["4"]==8000)
	print("PASS high density round trip retains legacy progress")
	store.life_density = -7
	store.save_data()
	store.load_data()
	assert(store.life_density==0)
	print("PASS invalid density clamped on load")
	print("SAVE DENSITY checks=3 failures=0 isolated=",OS.get_user_data_dir())
	quit()
