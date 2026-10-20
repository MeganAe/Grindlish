extends Control
## Commandes tactiles : stick flottant à gauche, boutons à droite.

const R_STICK := 150.0
var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_pos := Vector2.ZERO
var buttons := {}   # nom -> {"c": Vector2, "r": float, "id": int, "action": String, "label": String}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	release_all()
	var sz := get_viewport_rect().size
	buttons = {
		"jump": {"c": Vector2(sz.x - 230, sz.y - 230), "r": 120.0, "id": -1, "action": "jump", "label": "SAUT"},
		"flip": {"c": Vector2(sz.x - 470, sz.y - 150), "r": 84.0, "id": -1, "action": "flip", "label": "FLIP"},
		"grab": {"c": Vector2(sz.x - 120, sz.y - 470), "r": 84.0, "id": -1, "action": "grab", "label": "GRAB"},
		"boost": {"c": Vector2(sz.x - 400, sz.y - 360), "r": 76.0, "id": -1, "action": "move_up", "label": "VITE"},
	}
	var inset := Vector2.ZERO
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var window := Vector2(DisplayServer.window_get_size())
		inset = Vector2(maxf(safe.position.x, window.x - safe.end.x), maxf(safe.position.y, window.y - safe.end.y)) * sz / window
	for button in buttons.values():
		button.r *= Save.touch_scale
		button.c.x -= inset.x
		button.c.y -= inset.y
		if Save.left_handed:
			button.c.x = sz.x - button.c.x
	queue_redraw()


func release_all() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "jump", "flip", "grab"]:
		Input.action_release(a)
	stick_id = -1
	for b in buttons.values():
		b["id"] = -1
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	var sz := get_viewport_rect().size
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			for b in buttons.values():
				if b["id"] == -1 and p.distance_to(b["c"]) < b["r"] * 1.25:
					b["id"] = event.index
					Input.action_press(b["action"])
					queue_redraw()
					get_viewport().set_input_as_handled()
					return
			if stick_id == -1 and ((p.x < sz.x * 0.45 and not Save.left_handed) or (p.x > sz.x * 0.55 and Save.left_handed)) and p.y > sz.y * 0.2:
				stick_id = event.index
				stick_origin = p
				stick_pos = p
				queue_redraw()
				get_viewport().set_input_as_handled()
		else:
			for b in buttons.values():
				if b["id"] == event.index:
					b["id"] = -1
					Input.action_release(b["action"])
					queue_redraw()
			if event.index == stick_id:
				stick_id = -1
				_apply_stick(Vector2.ZERO)
				queue_redraw()
	elif event is InputEventScreenDrag and event.index == stick_id:
		stick_pos = event.position
		var d := stick_pos - stick_origin
		if d.length() > R_STICK:
			stick_origin = stick_pos - d.normalized() * R_STICK
			d = stick_pos - stick_origin
		_apply_stick(d / R_STICK)
		queue_redraw()


func _apply_stick(v: Vector2) -> void:
	_set_axis("move_left", "move_right", v.x)
	if v.y > 0.55:
		Input.action_press("move_down", v.y)
	else:
		Input.action_release("move_down")


func _set_axis(neg: String, pos: String, x: float) -> void:
	if x < -0.12:
		Input.action_press(neg, minf(1.0, -x * 1.2))
		Input.action_release(pos)
	elif x > 0.12:
		Input.action_press(pos, minf(1.0, x * 1.2))
		Input.action_release(neg)
	else:
		Input.action_release(neg)
		Input.action_release(pos)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	if stick_id != -1:
		draw_circle(stick_origin, R_STICK, Color(1, 1, 1, 0.18))
		draw_arc(stick_origin, R_STICK, 0, TAU, 48, Color(1, 1, 1, 0.5), 5.0)
		draw_circle(stick_pos, 62, Color(1, 1, 1, 0.55))
	else:
		var sz := get_viewport_rect().size
		var c := Vector2(sz.x - 260 if Save.left_handed else 260, sz.y - 240)
		draw_arc(c, R_STICK, 0, TAU, 48, Color(1, 1, 1, 0.25), 5.0)
		draw_circle(c, 62, Color(1, 1, 1, 0.2))
	for b in buttons.values():
		var down: bool = b["id"] != -1
		draw_circle(b["c"], b["r"], Color(1.0, 0.64, 0.2, 0.75 if down else 0.4))
		draw_arc(b["c"], b["r"], 0, TAU, 40, Color(1, 1, 1, 0.8), 5.0)
		var fs := 34 if b["r"] > 100 else 28
		var w := font.get_string_size(b["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, b["c"] + Vector2(-w / 2.0, fs * 0.35), b["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
