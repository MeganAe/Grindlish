extends CanvasLayer
## Tous les écrans (menus, options, boutique, pause, fin de partie) et le HUD.

signal action(name: String, arg: Variant)

const Lv := preload("res://levels.gd")

const GREEN := Color("b4e76a")
const GREEN_D := Color("517e54")
const INK := Color("173b48")
const PANEL := Color("f5f1e8")
const GOLD := Color(1.0, 0.82, 0.2)
const RED := Color(0.93, 0.3, 0.32)
const BLUE := Color(0.35, 0.65, 1.0)

var bound_game: WeakRef
var objectives_label: Label
var tutorial_label: Label
var ui_theme: Theme
var screen: Control
var hud: Control
var fade: ColorRect
var flash: ColorRect

# HUD

var _reset_step := 0
var _reset_btn: Button
var _first_focus: Control


# ================================================================= icônes

class Icon extends Control:
	var kind := "star"
	var filled := true
	var px := 40.0

	func _init(k := "star", s := 40.0, f := true) -> void:
		kind = k
		px = s
		filled = f
		custom_minimum_size = Vector2(s, s)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Vector2(px, px) / 2.0
		var r := px / 2.0
		match kind:
			"star":
				var pts := PackedVector2Array()
				for i in 10:
					var a := -PI / 2.0 + i * PI / 5.0
					var rr := r if i % 2 == 0 else r * 0.45
					pts.append(c + Vector2(cos(a), sin(a)) * rr)
				if filled:
					draw_colored_polygon(pts, Color(1.0, 0.82, 0.2))
					draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.8, 0.55, 0.05), 2.5)
				else:
					draw_colored_polygon(pts, Color(0.85, 0.85, 0.9))
					draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.65, 0.65, 0.72), 2.5)
			"coin":
				draw_circle(c, r, Color(0.85, 0.62, 0.1))
				draw_circle(c, r * 0.75, Color(1.0, 0.82, 0.2))
				draw_rect(Rect2(c + Vector2(-px * 0.06, -r * 0.45), Vector2(px * 0.12, r * 0.9)), Color(0.85, 0.62, 0.1))
			"skull":
				draw_circle(c + Vector2(0, -r * 0.1), r * 0.78, Color(0.2, 0.28, 0.2))
				draw_rect(Rect2(c + Vector2(-r * 0.4, r * 0.3), Vector2(r * 0.8, r * 0.55)), Color(0.2, 0.28, 0.2))
				draw_circle(c + Vector2(-r * 0.32, -r * 0.15), r * 0.2, Color.WHITE)
				draw_circle(c + Vector2(r * 0.32, -r * 0.15), r * 0.2, Color.WHITE)
			"clock":
				draw_circle(c, r * 0.9, Color(0.2, 0.28, 0.2))
				draw_circle(c, r * 0.75, Color.WHITE)
				draw_line(c, c + Vector2(0, -r * 0.55), Color(0.2, 0.28, 0.2), 3.0)
				draw_line(c, c + Vector2(r * 0.4, 0), Color(0.2, 0.28, 0.2), 3.0)
			"heart":
				var col := Color(0.93, 0.3, 0.32)
				draw_circle(c + Vector2(-r * 0.4, -r * 0.2), r * 0.5, col)
				draw_circle(c + Vector2(r * 0.4, -r * 0.2), r * 0.5, col)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.88, -r * 0.05), c + Vector2(r * 0.88, -r * 0.05), c + Vector2(0, r * 0.9)]), col)
			"pip":
				draw_circle(c, r, Color(0.36, 0.6, 0.15) if filled else Color(0.84, 0.84, 0.9))
			"check":
				draw_circle(c, r, Color(0.36, 0.6, 0.15) if filled else Color(0.84, 0.84, 0.9))
				if filled:
					draw_polyline(PackedVector2Array([c + Vector2(-r * 0.45, 0), c + Vector2(-r * 0.1, r * 0.4), c + Vector2(r * 0.5, -r * 0.4)]), Color.WHITE, 4.0)


# ================================================================= init

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_theme()
	if not OS.has_feature("mobile") and DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(preload("res://assets/ui/cursor.png"), Input.CURSOR_ARROW, Vector2(6, 4))
	screen = Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.theme = ui_theme
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	_build_hud()
	get_viewport().size_changed.connect(_safe_ui)
	_safe_ui()
	fade = ColorRect.new()
	fade.color = Color(0.06, 0.06, 0.16, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)


class UiSkin extends StyleBoxTexture:
	# Compatibility knobs from the old flat UI; all painting is now textured.
	var border_width_top := 0
	var border_width_bottom := 0

func _box(bg: Color, _border := Color(0, 0, 0, 0), _radius := 24, _bw := 0, pad := 0) -> UiSkin:
	var skin := UiSkin.new()
	skin.texture = preload("res://assets/ui/skin.png")
	skin.modulate_color = bg
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		skin.set_texture_margin(side, 24)
		skin.set_content_margin(side, pad)
	return skin


func _circle_tex(d: int, col: Color, ring: Color) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var c := Vector2(d, d) / 2.0
	for x in d:
		for y in d:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if dist < d / 2.0 - 5.0:
				img.set_pixel(x, y, col)
			elif dist < d / 2.0 - 1.0:
				img.set_pixel(x, y, ring)
	return ImageTexture.create_from_image(img)


func _make_theme() -> void:
	var t := Theme.new()
	t.default_font = preload("res://assets/ui/DejaVuSans.ttf")
	t.default_font_size = 32
	t.set_color("font_color", "Label", INK)
	t.set_font_size("font_size", "Label", 36)
	var normal := _box(GREEN, GREEN_D, 24, 0, 18)
	normal.border_width_bottom = 8
	var hover := _box(GREEN.lightened(0.18), GREEN_D, 24, 0, 18)
	hover.border_width_bottom = 8
	var pressed := _box(GREEN.darkened(0.08), GREEN_D, 24, 0, 18)
	pressed.border_width_top = 6
	var disabled := _box(Color(0.84, 0.84, 0.88), Color(0.7, 0.7, 0.76), 24, 0, 18)
	disabled.border_width_bottom = 8
	var focus := _box(Color(0, 0, 0, 0), INK, 24, 6)
	normal.texture = preload("res://assets/ui/button_normal.png")
	normal.modulate_color = Color.WHITE
	hover.texture = preload("res://assets/ui/button_hover.png")
	hover.modulate_color = Color.WHITE
	pressed.texture = preload("res://assets/ui/button_pressed.png")
	pressed.modulate_color = Color.WHITE
	disabled.texture = preload("res://assets/ui/button_disabled.png")
	disabled.modulate_color = Color.WHITE
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	focus.texture = preload("res://assets/ui/focus.png")
	focus.modulate_color = Color.WHITE
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.58))
	t.set_font_size("font_size", "Button", 40)
	# Sliders
	var track := _box(Color(0.12, 0.12, 0.27, 0.18), Color(0, 0, 0, 0), 10, 0)
	track.content_margin_top = 9
	track.content_margin_bottom = 9
	var fill := _box(GREEN, Color(0, 0, 0, 0), 10, 0)
	fill.content_margin_top = 9
	fill.content_margin_bottom = 9
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var g := _circle_tex(48, GREEN, GREEN_D)
	t.set_icon("grabber", "HSlider", g)
	t.set_icon("grabber_highlight", "HSlider", g)
	t.set_icon("grabber_disabled", "HSlider", g)
	t.set_constant("center_grabber", "HSlider", 0)
	ui_theme = t


# ================================================================= helpers

func _lbl(text: String, size := 36, color := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = tr(text)
	l.add_theme_font_size_override("font_size", int(size * Save.text_scale))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


func _title(text: String, size := 120) -> Label:
	var l := _lbl(text, size, INK, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 0)
	return l


func _btn(text: String, cb: Callable, w := 460.0, h := 88.0, size := 40, primary := true) -> Button:
	var b := Button.new()
	b.text = tr(text)
	b.custom_minimum_size = Vector2(w, h)
	b.add_theme_font_size_override("font_size", size)
	if not primary:
		var n := _box(Color(0.95, 0.95, 1.0), Color(0.72, 0.72, 0.86), 24, 0, 18)
		n.border_width_bottom = 8
		var hv := _box(Color(1, 1, 1), Color(0.72, 0.8, 0.66), 24, 0, 18)
		hv.border_width_bottom = 8
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", hv)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.focus_entered.connect(func(): Sfx.play("click", 1.4, 0.08))
	b.mouse_entered.connect(func():
		b.pivot_offset = b.size * 0.5
		b.create_tween().tween_property(b, "scale", Vector2.ONE * 1.012, 0.12))
	b.mouse_exited.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))
	return b


func _panel(pad := 44) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _box(PANEL, GREEN_D, 40, 6, pad)
	p.add_theme_stylebox_override("panel", s)
	return p


func _clear() -> void:
	for c in screen.get_children():
		c.hide()
		c.queue_free()
	hud.visible = false
	_first_focus = null
	_reset_step = 0


func _center(node: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(node)
	screen.add_child(c)
	return c


func _focus(c: Control) -> void:
	if c:
		c.call_deferred("grab_focus")


func _dim(alpha := 0.5) -> void:
	var d := ColorRect.new()
	d.color = Color(0.06, 0.06, 0.16, alpha)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(d)


@warning_ignore("integer_division")
func fmt_time(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _coin_chip() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(PANEL, GREEN_D, 30, 4, 14))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.add_child(Icon.new("coin", 44))
	h.add_child(_lbl(str(Save.coins), 42))
	p.add_child(h)
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.position = Vector2(-60, 40)
	p.offset_left = -300
	p.offset_right = -50
	p.offset_top = 40
	return p


func transition(cb: Callable) -> void:
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.15)
	tw.tween_callback(cb)
	tw.tween_property(fade, "color:a", 0.0, 0.2)
	tw.tween_callback(func(): fade.mouse_filter = Control.MOUSE_FILTER_IGNORE)


func hide_all() -> void:
	_clear()


func clear_for_play() -> void:
	_clear()
	start_hud()


func close_overlay() -> void:
	_clear()
	hud.visible = true




# ================================================================= données boutique

const SHOP := [
	{"id": "speed", "name": "Vitesse", "desc": "Glisse plus vite", "max": 5, "cost": [60, 110, 180, 280, 420]},
	{"id": "jump", "name": "Saut", "desc": "Saute plus haut", "max": 5, "cost": [60, 110, 180, 280, 420]},
	{"id": "magnet", "name": "Aimant", "desc": "Ramasse de plus loin", "max": 4, "cost": [50, 100, 180, 300]},
	{"id": "time", "name": "Temps", "desc": "+10 s par partie", "max": 4, "cost": [80, 150, 260, 400]},
]
const CHARS := ["Max", "Lou"]
const BOARDS := [
	{"name": "Classique", "col": Color(0.9, 0.9, 0.95), "cost": 0},
	{"name": "Rouge", "col": Color(1, 0.3, 0.3), "cost": 80},
	{"name": "Bleu", "col": Color(0.3, 0.6, 1.0), "cost": 80},
	{"name": "Vert", "col": Color(0.4, 1.0, 0.5), "cost": 80},
	{"name": "Or", "col": Color(1.0, 0.8, 0.2), "cost": 160},
	{"name": "Violet", "col": Color(0.8, 0.4, 1.0), "cost": 160},
]
var _shop_tab := 0
var preview_character := 0
var preview_board := 0


# ================================================================= menu principal

func show_menu() -> void:
	_clear()
	var art := TextureRect.new()
	art.texture = preload("res://assets/ui/menu_background.svg")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(art)
	var v := VBoxContainer.new()
	v.position = Vector2(92, 108)
	v.custom_minimum_size = Vector2(570, 0)
	v.add_theme_constant_override("separation", 15)
	screen.add_child(v)
	var eyebrow := _lbl("SKATE. LEARN. REPEAT.", 22, GREEN)
	v.add_child(eyebrow)
	v.add_child(_lbl("GRINDLISH", 73, Color("f5f1e8")))
	v.add_child(_lbl("Prends de l'élan. Trouve tes mots.", 25, Color("b9cece")))
	var gap := Control.new()
	gap.custom_minimum_size.y = 26
	v.add_child(gap)
	var play := _btn("C'est parti  →", func(): action.emit("modes", null), 565, 90, 34)
	v.add_child(play)
	for item in [["Carnet & révisions", "notebook"], ["Comment jouer", "help"], ["Garage", "shop"], ["Réglages", "options"]]:
		var act: String = item[1]
		v.add_child(_btn(item[0], func(): action.emit(act, null), 565, 65, 27, false))
	var row := HBoxContainer.new()
	v.add_child(row)
	row.add_child(_btn("Professeur", func(): action.emit("teacher", null), 275, 60, 24, false))
	row.add_child(_btn("Crédits", show_credits, 275, 60, 24, false))
	v.add_child(_btn("Quitter", func(): action.emit("quit", null), 565, 60, 25, false))
	v.add_child(_lbl(tr("%d mots appris  •  série : %d jour(s)") % [Lexicon.progress.size(), Save.streak], 23, Color("b9cece")))
	screen.add_child(_coin_chip())
	_focus(play)


# ================================================================= choix du niveau

func show_levels() -> void:
	_clear()
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 110)
	m.add_theme_constant_override("margin_top", 35)
	m.add_theme_constant_override("margin_bottom", 60)
	screen.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	m.add_child(v)
	var tt := _title("Choisis un parc", 100)
	v.add_child(tt)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 30)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)
	var first: Button = null
	for i in Lv.count():
		var card := _level_card(Lv.get_level(i + 1))
		grid.add_child(card)
		if first == null and not card.disabled:
			first = card
		if i + 1 == mini(Save.unlocked, Lv.count()):
			first = card
	var back := _btn("Retour", func(): action.emit("menu", null), 340, 80, 38, false)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_child(back)
	screen.add_child(_coin_chip())
	_focus(first)


func _level_card(lv: Dictionary) -> Button:
	var id: int = lv["id"]
	var locked := id > Save.unlocked and str(Engine.get_meta("mode", "career")) == "career"
	var b := Button.new()
	b.custom_minimum_size = Vector2(540, 250)
	var bg: Color = (lv["sky"] as Array)[0]
	bg = bg.lerp(Color.WHITE, 0.3)
	for st in ["normal", "hover", "pressed"]:
		var s := _box(bg if st != "hover" else bg.lightened(0.2), bg.darkened(0.4), 30, 0, 28)
		s.border_width_bottom = 10
		b.add_theme_stylebox_override(st, s)
	var grey := Color(0.12, 0.12, 0.27, 0.45)
	var name_l := _lbl("%d · %s" % [id, lv["name"]], 46, grey if locked else INK)
	name_l.position = Vector2(28, 18)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(name_l)
	var sub_l := _lbl("Verrouillé" if locked else tr("%d s  ·  record %d") % [int(lv["time"]), Save.get_best(id)], 30, grey if locked else Color(0.12, 0.12, 0.27, 0.8))
	sub_l.position = Vector2(28, 86)
	sub_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(sub_l)
	b.disabled = locked
	if not locked:
		b.pressed.connect(func():
			Sfx.play("click")
			action.emit("play", id))
		b.focus_entered.connect(func(): Sfx.play("click", 1.4, 0.08))
		var row := HBoxContainer.new()
		row.position = Vector2(28, 164)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)
		for i in 3:
			row.add_child(Icon.new("star", 52, i < Save.get_stars(id)))
		b.add_child(row)
	return b


# ================================================================= boutique

func show_shop(focus_idx := 0) -> void:
	_clear()
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 220)
	m.add_theme_constant_override("margin_top", 40)
	m.add_theme_constant_override("margin_bottom", 40)
	screen.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	v.add_child(_title("Boutique", 76))
	v.add_child(_btn("Aperçu 3D — essayer sans acheter", show_shop_preview, 1000, 66, 28, false))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 20)
	var tb1 := _btn("Améliorations", func():
		_shop_tab = 0
		show_shop(), 360, 70, 32, _shop_tab == 0)
	var tb2 := _btn("Style", func():
		_shop_tab = 1
		show_shop(), 360, 70, 32, _shop_tab == 1)
	tabs.add_child(tb1)
	tabs.add_child(tb2)
	v.add_child(tabs)
	var pnl := _panel(28)
	v.add_child(pnl)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	pnl.add_child(rows)
	var btns: Array[Button] = []
	if _shop_tab == 0:
		for item in SHOP:
			var lvl := Save.shop_level(item["id"])
			var maxl: int = item["max"]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 24)
			var info := VBoxContainer.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_theme_constant_override("separation", 0)
			info.add_child(_lbl(item["name"], 38))
			info.add_child(_lbl(item["desc"], 27, Color(0.12, 0.12, 0.27, 0.7)))
			row.add_child(info)
			var pips := HBoxContainer.new()
			pips.add_theme_constant_override("separation", 6)
			for i in maxl:
				var cc := CenterContainer.new()
				cc.add_child(Icon.new("pip", 26, i < lvl))
				pips.add_child(cc)
			row.add_child(pips)
			var maxed := lvl >= maxl
			var cost := 0 if maxed else int(item["cost"][lvl])
			var idx := btns.size()
			var b := _btn("Max" if maxed else tr("Acheter  %d") % cost, func(): _buy(item, idx), 300, 76, 34, not maxed)
			b.disabled = maxed or Save.coins < cost
			row.add_child(b)
			btns.append(b)
			rows.add_child(row)
	else:
		rows.add_child(_lbl("Personnage", 34))
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 20)
		for ci in CHARS.size():
			var owned: bool = Save.owned.get("c%d" % ci, false)
			var sel: bool = Save.char_id == ci
			var txt: String = CHARS[ci] + ("  ✓" if sel else ("" if owned else "  (150)"))
			var idx2 := btns.size()
			var b2 := _btn(txt, func(): _pick_style("c", ci, 150, idx2), 300, 76, 34, sel)
			b2.disabled = not owned and Save.coins < 150
			crow.add_child(b2)
			btns.append(b2)
		rows.add_child(crow)
		rows.add_child(_lbl("Couleur de planche", 34))
		var brow := GridContainer.new()
		brow.columns = 3
		brow.add_theme_constant_override("h_separation", 20)
		brow.add_theme_constant_override("v_separation", 12)
		for bi in BOARDS.size():
			var bd: Dictionary = BOARDS[bi]
			var owned2: bool = Save.owned.get("b%d" % bi, false)
			var sel2: bool = Save.board == bi
			var txt2: String = String(bd["name"]) + ("  ✓" if sel2 else ("" if owned2 else "  (%d)" % int(bd["cost"])))
			var idx3 := btns.size()
			var b3 := _btn(txt2, func(): _pick_style("b", bi, int(bd["cost"]), idx3), 300, 76, 32, sel2)
			var sw: Color = bd["col"]
			for st in ["normal", "hover", "pressed"]:
				var sbx := _box(sw if st != "hover" else sw.lightened(0.2), sw.darkened(0.4), 24, 0, 18)
				sbx.border_width_bottom = 8
				b3.add_theme_stylebox_override(st, sbx)
			b3.disabled = not owned2 and Save.coins < int(bd["cost"])
			brow.add_child(b3)
			btns.append(b3)
		rows.add_child(brow)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	var back := _btn("Retour", func(): action.emit("menu", null), 340, 80, 38, false)
	bottom.add_child(back)
	v.add_child(bottom)
	screen.add_child(_coin_chip())
	var target: Control = back
	if btns.size() > 0:
		target = btns[clampi(focus_idx, 0, btns.size() - 1)]
		if target is Button and target.disabled:
			target = back
	_focus(target)


func _buy(item: Dictionary, idx: int) -> void:
	var lvl := Save.shop_level(item["id"])
	if lvl >= int(item["max"]):
		return
	var cost := int(item["cost"][lvl])
	if Save.coins < cost:
		Sfx.play("deny")
		return
	Save.coins -= cost
	Save.shop[item["id"]] = lvl + 1
	Save.save_data()
	Sfx.play("buy")
	show_shop(idx)


func _purchase_style(kind: String, i: int, cost: int) -> bool:
	var key := "%s%d" % [kind, i]
	if not Save.owned.get(key, false):
		if Save.coins < cost:
			Sfx.play("deny")
			return false
		Save.coins -= cost
		Save.owned[key] = true
		Sfx.play("buy")
	else:
		Sfx.play("click")
	if kind == "c":
		Save.char_id = i
	else:
		Save.board = i
	Save.save_data()
	return true

func _pick_style(kind: String, i: int, cost: int, idx: int) -> void:
	if _purchase_style(kind, i, cost):
		show_shop(idx)

func show_shop_preview(reset := true) -> void:
	if reset:
		preview_character = Save.char_id
		preview_board = Save.board
	var v := _text_page("Essaie ton style", show_shop)
	var view := preload("res://shop_preview.gd").new()
	view.custom_minimum_size = Vector2(1000, 300)
	v.add_child(view)
	view.appearance(preview_character, BOARDS[preview_board].col)
	v.add_child(_lbl("Glisse pour tourner. Aucun achat pendant l'essayage.", 23, INK))
	_choice_row(v, "Personnage", CHARS, preview_character, func(i):
		preview_character = i
		show_shop_preview(false))
	_choice_row(v, "Planche", BOARDS.map(func(b): return b.name), preview_board, func(i):
		preview_board = i
		show_shop_preview(false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var char_owned: bool = Save.owned.get("c%d" % preview_character, false)
	var board_owned: bool = Save.owned.get("b%d" % preview_board, false)
	row.add_child(_btn("Équiper personnage" if char_owned else "Acheter personnage : 150", func():
		_purchase_style("c", preview_character, 150)
		show_shop_preview(false), 520, 64, 25))
	row.add_child(_btn("Équiper planche" if board_owned else tr("Acheter planche : %d") % int(BOARDS[preview_board].cost), func():
		_purchase_style("b", preview_board, int(BOARDS[preview_board].cost))
		show_shop_preview(false), 520, 64, 25))


# ================================================================= options

func show_options(from_pause := false) -> void:
	var v := _text_page("Réglages", func(): action.emit("options_back", null))
	v.add_child(_lbl("Audio & affichage", 34, INK))
	_slider_row(v, "Musique", Save.music, func(x): Save.music = x; Save.apply_settings())
	_slider_row(v, "Effets / voix", Save.sfx, func(x): Save.sfx = x; Save.apply_settings())
	_toggle_row(v, "Plein écran", Save.fullscreen, func(on): Save.fullscreen = on; Save.apply_settings())
	_toggle_row(v, "Secousse d'écran", Save.shake, func(on): Save.shake = on)
	_choice_row(v, "Qualité", ["Basse", "Moyenne", "Haute"], Save.quality, func(i):
		Save.quality = i
		Save.apply_settings()
		action.emit("quality_changed", null))
	_choice_row(v, "Limite FPS", ["30", "60"], 0 if Save.fps_limit == 30 else 1, func(i): Save.fps_limit = 30 if i == 0 else 60; Save.apply_settings())
	_choice_row(v, "Taille du texte", ["100 %", "115 %"], 0 if Save.text_scale < 1.1 else 1, func(i): Save.text_scale = 1.0 if i == 0 else 1.15)
	_choice_row(v, "Langue des menus", ["Français", "English"], 0 if Save.locale == "fr" else 1, func(i): Save.locale = "fr" if i == 0 else "en"; Save.apply_settings())
	v.add_child(_lbl("Apprendre à ton rythme", 34, INK))
	_toggle_row(v, "Sans chrono", Save.no_timer, func(on): Save.no_timer = on)
	_toggle_row(v, "Sans chute", Save.no_fall, func(on):
		Save.no_fall = on
		action.emit("quality_changed", null))
	_toggle_row(v, "Traduction / indices", Save.hints, func(on): Save.hints = on)
	_toggle_row(v, "Lettres dans l'ordre", Save.ordered_letters, func(on): Save.ordered_letters = on)
	_choice_row(v, "Niveau de vocabulaire", ["Tous", "A1", "A2", "B1"], ["ALL", "A1", "A2", "B1"].find(Save.vocabulary_level), func(i): Save.vocabulary_level = ["ALL", "A1", "A2", "B1"][i])
	v.add_child(_lbl("Commandes", 34, INK))
	_toggle_row(v, "Tactile", Save.touch, func(on): Save.touch = on; action.emit("touch_changed", on))
	_toggle_row(v, "Gaucher", Save.left_handed, func(on): Save.left_handed = on; action.emit("touch_changed", Save.touch))
	_choice_row(v, "Taille des boutons", ["100 %", "120 %"], 0 if Save.touch_scale < 1.1 else 1, func(i): Save.touch_scale = 1.0 if i == 0 else 1.2; action.emit("touch_changed", Save.touch))
	v.add_child(_btn("Remapper clavier / manette", func(): show_controls(from_pause), 1000, 72, 29, false))
	v.add_child(_lbl("Le niveau de vocabulaire et l'ordre s'appliquent à la prochaine session.", 24, INK))
	_reset_btn = _btn("Effacer la progression de carrière", _on_reset_pressed, 1000, 70, 29, false)
	v.add_child(_reset_btn)

func _choice_row(parent: Control, text: String, values: Array, selected: int, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)
	var label := _lbl(text, 30, INK)
	label.custom_minimum_size.x = 560
	row.add_child(label)
	var choice := OptionButton.new()
	choice.custom_minimum_size = Vector2(420, 66)
	choice.add_theme_font_size_override("font_size", 29)
	for value in values:
		choice.add_item(tr(str(value)))
	choice.selected = maxi(0, selected)
	choice.item_selected.connect(func(index): callback.call(index); Save.save_data())
	row.add_child(choice)

func show_controls(from_pause := false) -> void:
	var v := _text_page("Tes commandes", func(): show_options(from_pause))
	v.add_child(_lbl("Choisis une action, puis une touche physique ou un bouton manette.", 25, INK))
	for item in [["move_left", "Tourner à gauche"], ["move_right", "Tourner à droite"], ["move_up", "Accélérer"], ["move_down", "Freiner"], ["jump", "Saut"], ["flip", "Flip"], ["grab", "Grab"], ["pause", "Pause"]]:
		var key: String = item[0]
		var caption: String = item[1]
		var names: Array[String] = []
		for event in InputMap.action_get_events(key):
			if event is InputEventKey:
				names.append(OS.get_keycode_string(event.physical_keycode))
			elif event is InputEventJoypadButton:
				names.append(tr("Manette %d") % event.button_index)
		var button := _btn(tr(caption) + "  ·  " + " / ".join(names), func(): action.emit("rebind", key), 1000, 64, 28, false)
		v.add_child(button)
	v.add_child(_btn("Rétablir les commandes", func(): action.emit("reset_bindings", null); show_controls(from_pause), 1000, 66, 28, false))
	v.add_child(_lbl("Échap annule l'écoute. Le stick et les gâchettes restent disponibles.", 24, INK))

func _slider_row(parent: Control, label: String, value: float, cb: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	var l := _lbl(label, 30)
	l.custom_minimum_size = Vector2(560, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(560, 56)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s)
	var pct := _lbl("%d %%" % roundi(value * 100.0), 34)
	pct.custom_minimum_size = Vector2(110, 0)
	row.add_child(pct)
	s.value_changed.connect(func(x: float):
		pct.text = "%d %%" % roundi(x * 100.0)
		cb.call(x))
	s.drag_ended.connect(func(_c: bool): Save.save_data())
	parent.add_child(row)
	return s


func _toggle_row(parent: Control, label: String, value: bool, cb: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	var l := _lbl(label, 30)
	l.custom_minimum_size = Vector2(560, 0)
	row.add_child(l)
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = value
	b.custom_minimum_size = Vector2(250, 70)
	b.add_theme_font_size_override("font_size", 34)
	b.text = tr("Activé") if value else tr("Désactivé")
	var off_n := _box(Color(0.88, 0.9, 0.85), Color(0.72, 0.76, 0.68), 24, 0, 18)
	off_n.border_width_bottom = 8
	var on_n := _box(GREEN, GREEN_D, 24, 0, 18)
	on_n.border_width_bottom = 8
	b.add_theme_stylebox_override("normal", off_n)
	b.add_theme_stylebox_override("hover", off_n)
	b.add_theme_stylebox_override("pressed", on_n)
	b.add_theme_stylebox_override("hover_pressed", on_n)
	b.toggled.connect(func(on: bool):
		b.text = tr("Activé") if on else tr("Désactivé")
		Sfx.play("click")
		cb.call(on)
		Save.save_data())
	row.add_child(b)
	parent.add_child(row)


func _on_reset_pressed() -> void:
	_reset_step += 1
	if _reset_step == 1:
		_reset_btn.text = tr("Es-tu sûr ?")
	elif _reset_step == 2:
		_reset_btn.text = tr("Dernière confirmation !")
	else:
		Save.reset_progress()
		Sfx.play("deny")
		_reset_step = 0
		_reset_btn.text = tr("Progression effacée")
		_reset_btn.disabled = true
		return
	var tw := create_tween()
	var step := _reset_step
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		if is_instance_valid(_reset_btn) and _reset_step == step:
			_reset_step = 0
			_reset_btn.text = tr("Effacer la progression"))


# ================================================================= pause

func show_pause() -> void:
	_clear()
	hud.visible = true
	_dim(0.5)
	var pnl := _panel(48)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	pnl.add_child(v)
	v.add_child(_title("Pause", 100))
	var resume := _btn("Reprendre", func(): action.emit("resume", null), 520, 96, 44)
	v.add_child(resume)
	v.add_child(_btn("Recommencer", func(): action.emit("restart", null), 520, 84, 38, false))
	v.add_child(_btn("Options", func(): action.emit("options_pause", null), 520, 84, 38, false))
	v.add_child(_btn("Abandonner", func(): action.emit("abandon", null), 520, 84, 38, false))
	_center(pnl)
	_focus(resume)


# ================================================================= fin de partie

func show_end(r: Dictionary, info: Dictionary) -> void:
	_clear()
	hud.visible = true
	_dim(0.55)
	var pnl := _panel(36)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pnl.add_child(v)
	var st: int = r["stars"]
	v.add_child(_title("Session terminée", 65))
	v.add_child(_lbl(str(r.get("mode", "career")).to_upper() + "  ·  " + str(snappedf(float(r.get("elapsed", 0)), 0.1)) + " s", 26, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var sr := HBoxContainer.new()
	sr.alignment = BoxContainer.ALIGNMENT_CENTER
	sr.add_theme_constant_override("separation", 10)
	for i in 3:
		sr.add_child(Icon.new("star", 76, i < st))
	v.add_child(sr)
	var big := _lbl("%d pts" % int(r["score"]), 70, Color(0.95, 0.4, 0.1), HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(big)
	if info.get("new_record", false):
		v.add_child(_lbl("Nouveau record !", 36, GREEN_D, HORIZONTAL_ALIGNMENT_CENTER))
	for objective in r.get("objectives", []):
		v.add_child(_lbl(("✓  " if objective.done else "○  ") + str(objective.text), 26, GREEN_D if objective.done else INK))
	if r.get("mode") == "career":
		v.add_child(_lbl("Sans le mot : aucune étoile. Avec le mot : 1 ; score cible : +1 ; combo ≥ 400 : +1.", 20, INK))
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 70)
	stats.add_theme_constant_override("v_separation", 2)
	stats.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(stats)
	_stat(stats, "Meilleur combo", str(int(r["best_combo"])))
	_stat(stats, "Tricks", str(int(r["tricks"])))
	_stat(stats, "Lettres", "%d / %d  %s" % [int(r["letters"]), int(r.get("word_size", 5)), str(r.get("word", ""))])
	_stat(stats, "Pièces collectées", "%d%s" % [int(r["coins"]), (tr(" + %d bonus") % int(info.get("bonus", 0))) if int(info.get("bonus", 0)) > 0 else ""])
	if info.get("unlocked_new", false):
		v.add_child(_lbl("Nouveau parc débloqué !", 38, GREEN_D, HORIZONTAL_ALIGNMENT_CENTER))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	v.add_child(gap)
	var first: Button
	if st > 0 and info.get("has_next", false):
		first = _btn("Parc suivant", func(): action.emit("next", null), 560, 84, 40)
	else:
		first = _btn("Rejouer", func(): action.emit("restart", null), 560, 84, 40)
	first.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(first)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 14)
	v.add_child(brow)
	if st > 0 and info.get("has_next", false):
		brow.add_child(_btn("Rejouer", func(): action.emit("restart", null), 180, 70, 30, false))
	brow.add_child(_btn("Parcs", func(): action.emit("levels", null), 180, 70, 30, false))
	brow.add_child(_btn("Menu", func(): action.emit("menu", null), 180, 70, 30, false))
	_center(pnl)
	_focus(first)


func _stat(grid: GridContainer, k: String, val: String) -> void:
	grid.add_child(_lbl(k, 30, Color(0.12, 0.12, 0.27, 0.75)))
	var l := _lbl(val, 34)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(l)


# ================================================================= HUD

var score_label: Label
var time_label: Label
var coins_label: Label
var banner: Label
var _banner_tw: Tween
var combo_box: Control
var combo_pts: Label
var combo_names: Label
var letter_labels: Array[Label] = []
var pause_btn: Button
var _combo_tw: Tween
var _score_shown := 0.0
var _score_target := 0
var touch_layer: Control


func _outline(l: Label, size := 10) -> Label:
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", size)
	return l


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.theme = ui_theme
	hud.visible = false
	add_child(hud)
	flash = ColorRect.new()
	flash.color = Color(0.9, 0.1, 0.1, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flash)

	# Score (haut gauche)
	var sbox := VBoxContainer.new()
	sbox.position = Vector2(40, 24)
	sbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(sbox)
	score_label = _outline(_lbl("0", 84, Color.WHITE), 16)
	sbox.add_child(score_label)
	var cb := HBoxContainer.new()
	cb.add_theme_constant_override("separation", 10)
	cb.add_child(Icon.new("coin", 40))
	coins_label = _outline(_lbl("0", 40, Color.WHITE), 10)
	cb.add_child(coins_label)
	sbox.add_child(cb)

	# Chrono + pause (haut droite)
	var tbox := HBoxContainer.new()
	tbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tbox.offset_left = -520
	tbox.offset_right = -36
	tbox.offset_top = 26
	tbox.alignment = BoxContainer.ALIGNMENT_END
	tbox.add_theme_constant_override("separation", 20)
	tbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(tbox)
	time_label = _outline(_lbl("0:00", 76, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT), 16)
	tbox.add_child(time_label)
	pause_btn = Button.new()
	pause_btn.text = "II"
	pause_btn.custom_minimum_size = Vector2(84, 84)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.add_theme_font_size_override("font_size", 40)
	pause_btn.pressed.connect(func(): action.emit("pause", null))
	tbox.add_child(pause_btn)

	# Lettres S-K-A-T-E (haut centre)
	var lrow := HBoxContainer.new()
	lrow.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lrow.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lrow.offset_top = 30
	lrow.add_theme_constant_override("separation", 10)
	lrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(lrow)
	for i in 12:
		var l := _lbl("", 72, Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_CENTER)
		l.custom_minimum_size = Vector2(66, 0)
		_outline(l, 14)
		lrow.add_child(l)
		letter_labels.append(l)

	# Combo (centre gauche)
	combo_box = VBoxContainer.new()
	combo_box.position = Vector2(40, 430)
	combo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(combo_box)
	combo_pts = _outline(_lbl("", 64, Color(1.0, 0.85, 0.2)), 14)
	combo_names = _outline(_lbl("", 34, Color.WHITE), 10)
	combo_box.add_child(combo_pts)
	combo_box.add_child(combo_names)
	combo_box.modulate.a = 0.0

	objectives_label = _outline(_lbl("", 26, Color.WHITE), 7)
	objectives_label.position = Vector2(40, 215)
	objectives_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(objectives_label)
	tutorial_label = _outline(_lbl("", 28, Color("e1f5c4")), 8)
	tutorial_label.position = Vector2(40, 940)
	tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(tutorial_label)
	# Bandeau central
	banner = _outline(_lbl("", 120, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER), 24)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.offset_left = -600
	banner.offset_right = 600
	banner.offset_top = -260
	banner.offset_bottom = -100
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(banner)


func start_hud() -> void:
	hud.visible = true
	for l in letter_labels:
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	_score_shown = 0.0
	_score_target = 0
	score_label.text = "0"
	coins_label.text = "0"
	combo_box.modulate.a = 0.0
	banner.modulate.a = 0.0
	pause_btn.visible = true


func bind_game(g: Node) -> void:
	bound_game = weakref(g)
	for i in letter_labels.size():
		letter_labels[i].visible = i < g.target_word.length()
		if i < g.target_word.length():
			letter_labels[i].text = g.target_word[i]
	announce(tr("Mot : ") + g.target_word + (" = " + str(g.word_data.fr) if Save.hints else ""), Color(0.8, 1.0, 0.6), 60)
	g.score_changed.connect(func(s: int): _score_target = s)
	g.coin_got.connect(func(n: int): coins_label.text = str(n))
	g.time_changed.connect(func(t: float):
		time_label.text = fmt_time(maxf(t, 0.0))
		time_label.add_theme_color_override("font_color", Color(1, 0.4, 0.35) if t <= 10.0 else Color.WHITE))
	g.letter_got.connect(func(i: int):
		letter_labels[i].add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		var tw := create_tween()
		letter_labels[i].pivot_offset = Vector2(33, 36)
		tw.tween_property(letter_labels[i], "scale", Vector2(1.5, 1.5), 0.1)
		tw.tween_property(letter_labels[i], "scale", Vector2.ONE, 0.2))
	g.combo_changed.connect(_on_combo)
	g.popup.connect(func(t: String, c: Color): announce(t, c))
	g.bank.connect(func(p: int): announce("+%d" % p, Color(0.5, 1.0, 0.6), 80))
	g.bailed_sig.connect(on_hurt)


func _on_combo(pending: int, mult: int, label: String, active: bool) -> void:
	if pending <= 0:
		if _combo_tw:
			_combo_tw.kill()
		_combo_tw = create_tween()
		_combo_tw.tween_property(combo_box, "modulate:a", 0.0, 0.25)
		return
	combo_pts.text = "%d × %d" % [pending, mult]
	combo_names.text = label
	if _combo_tw:
		_combo_tw.kill()
	combo_box.modulate.a = 1.0
	combo_pts.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if active else Color(0.6, 1.0, 0.7))


func announce(text: String, color: Color, size := 120) -> void:
	banner.text = text
	banner.add_theme_font_size_override("font_size", size)
	banner.add_theme_color_override("font_color", color)
	banner.pivot_offset = Vector2(600, 80)
	if _banner_tw:
		_banner_tw.kill()
	banner.modulate.a = 1.0
	banner.scale = Vector2(1.3, 1.3)
	_banner_tw = create_tween()
	_banner_tw.tween_property(banner, "scale", Vector2.ONE, 0.15)
	_banner_tw.tween_interval(0.7)
	_banner_tw.tween_property(banner, "modulate:a", 0.0, 0.3)


func on_hurt() -> void:
	if flash == null:
		return
	flash.color.a = 0.35
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.4)


func _process(delta: float) -> void:
	var game: Node = bound_game.get_ref() if bound_game else null
	if game and hud.visible:
		var lines: Array[String] = []
		for objective in game.objectives():
			lines.append(("✓ " if objective.done else "○ ") + str(objective.text))
		objectives_label.text = "\n".join(lines)
		if game.mode == "free" or Save.no_timer:
			time_label.text = "∞"
		tutorial_label.text = game.tutorial_text()
		for index in letter_labels.size():
			if index < game.letters.size() and not game.letters[index]:
				letter_labels[index].add_theme_color_override("font_color", Color("b4e76a") if index == game.letters.find(false) else Color(1, 1, 1, 0.45))
	if _score_shown < _score_target:
		_score_shown = minf(float(_score_target), _score_shown + maxf(40.0, (_score_target - _score_shown) * 6.0 * delta))
		score_label.text = str(int(_score_shown))
	elif _score_shown > _score_target:
		_score_shown = float(_score_target)
		score_label.text = str(_score_target)


func _text_page(title: String, back := Callable()) -> VBoxContainer:
	_clear()
	_dim(0.85)
	var panel := _panel(32)
	panel.custom_minimum_size = Vector2(1250, 860)
	panel.size = panel.custom_minimum_size
	_center(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	scroll.add_child(v)
	v.add_child(_title(title, 64))
	v.add_child(_btn("Retour", back if back.is_valid() else func(): action.emit("menu", null), 300, 66, 30, false))
	return v

func show_modes() -> void:
	var v := _text_page("À toi de choisir")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 16)
	v.add_child(grid)
	for item in [["career", "Carrière", "Un mot, trois objectifs, une nouvelle étape."], ["jam", "Jam", "Le meilleur score avant la fin du chrono."], ["word", "Défi du mot", "180 s pour compléter ton mot, puis un quiz."], ["free", "Sans pression", "Pas de chrono. Aucune récompense de carrière."], ["combo", "Combo Challenge", "Seul ton meilleur combo compte."], ["collect", "Chasse aux pièces", "Ramasse toutes les pièces le plus vite possible."], ["daily", "Mot du jour", "Un mot déterministe par parc et par date."]]:
		var key: String = item[0]
		var card := VBoxContainer.new()
		grid.add_child(card)
		card.add_child(_btn(item[1], func(): action.emit("mode", key), 550, 72, 30))
		var caption := _lbl(item[2], 21, INK)
		caption.custom_minimum_size.x = 530
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(caption)

func show_help() -> void:
	var v := _text_page("Comment jouer")
	for text in ["Max et Lou préparent leur premier tournoi international.", "Leur défi : progresser en skate ET apprendre des mots anglais.", "1. Choisis un mode puis un parc. Le mot est annoncé au départ.", "2. Ramasse les lettres dorées, dans n'importe quel ordre.", "3. Saute, fais des figures puis atterris pour encaisser le combo.", "4. En carrière : le score détermine les étoiles et ouvre le parc suivant.", "5. Chaque mot complété est ajouté au Carnet. Révise sa traduction !", "ZQSD physiques / flèches : tourner, accélérer, freiner.", "Espace : saut · X / Maj : flip · C / Ctrl : grab · Échap : pause.", "Manette : stick gauche, gâchettes, A saut, X flip, B grab.", "Chute : combo perdu, pénalité de 2 secondes. Pièce : +10.", "Mot complet : +3000. Sans pression : aucune limite de temps."]:
		v.add_child(_lbl(text, 29, INK))

func show_notebook() -> void:
	var v := _text_page("Carnet & révisions")
	var due: Array = Lexicon.due_words()
	v.add_child(_lbl(tr("%d / %d mots découverts  •  %d à réviser") % [Lexicon.progress.size(), Lexicon.words.size(), due.size()], 27, INK))
	if not due.is_empty():
		v.add_child(_btn("Réviser maintenant", _review_next, 1000, 74, 30))
	for w in Lexicon.words:
		if not Lexicon.progress.has(w.word):
			continue
		var row: Dictionary = w
		var state: Dictionary = Lexicon.progress[w.word]
		v.add_child(_btn(str(w.word).to_upper() + "  ·  " + str(w.fr) + "  ·  " + str(state.mastery) + "/5", func(): show_word_quiz(row), 1000, 66, 28, false))
	if Lexicon.progress.is_empty():
		v.add_child(_lbl("Complète un mot dans un parc pour commencer ton carnet.", 27, INK))

func _review_next() -> void:
	var due: Array = Lexicon.due_words()
	if due.is_empty():
		var v := _text_page("Révisions terminées !")
		v.add_child(_lbl("Tes prochains mots reviendront à leur échéance.", 30, INK))
	else:
		show_word_quiz(due[0], _review_next)

func show_word_quiz(w: Dictionary, on_done := Callable()) -> void:
	var v := _text_page(tr("Révision : %s") % str(w.word).to_upper())
	v.add_theme_constant_override("separation", 8)
	v.get_child(0).add_theme_font_size_override("font_size", 48)
	v.get_child(1).custom_minimum_size.y = 54
	if on_done.is_valid() and on_done.get_method() == "_review_next":
		v.add_child(_btn("Terminer les révisions", show_notebook, 800, 60, 25, false))
	if on_done.is_valid():
		v.get_child(1).hide()
		v.add_child(_btn("Continuer sans quiz", on_done, 800, 54, 28, false))
	v.add_child(_btn("Écouter", func(): Sfx.speak(w.word), 600, 54, 28, false))
	if not str(w.image).is_empty() and ResourceLoader.exists(w.image):
		var image := TextureRect.new()
		image.texture = load(w.image)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(110, 100)
		v.add_child(image)
	v.add_child(_lbl(str(w.definition), 30, INK))
	v.add_child(_lbl(str(w.example), 30, INK))
	v.add_child(_lbl("Quelle est la bonne traduction ?", 34, INK))
	var choices: Array = [w.fr]
	var peers: Array = Lexicon.words.filter(func(other): return other.word != w.word and other.level == w.level and other.theme == w.theme)
	var fallback: Array = Lexicon.words.duplicate()
	peers.shuffle()
	fallback.shuffle()
	for other in peers + fallback:
		if not choices.has(other.fr) and choices.size() < 3:
			choices.append(other.fr)
	choices.shuffle()
	for choice in choices:
		var answer: String = choice
		v.add_child(_btn(answer, func():
			Lexicon.answer(w.word, answer == w.fr)
			var result := _text_page("Bien joué !" if answer == w.fr else "On réessaie bientôt")
			if on_done.is_valid():
				result.get_child(1).hide()
			result.add_child(_lbl(str(w.word) + " = " + str(w.fr), 48, INK))
			result.add_child(_btn("Continuer" if on_done.is_valid() else "Carnet", on_done if on_done.is_valid() else show_notebook, 500, 80, 32)), 800, 64, 32))


func show_credits() -> void:
	var v := _text_page("Crédits & licences")
	for text in ["Grindlish — jeu original de skate et de vocabulaire.", "Modèles Mini Skate : Kenney (CC0).", "Effets et jingles : Kenney (CC0).", "Boucles sonores : rubberduck / OpenGameArt (CC0).", "Musique : omfgdude + qubodup, wipics, Nostromo (CC0).", "Voix anglaise : Piper, modèle LJSpeech de Bryce Beattie (domaine public).", "Données d'origine : Linda Johnson / Keith Ito, domaine public.", "Police DejaVu Sans : licence Bitstream/DejaVu fournie.", "Moteur : Godot 4.3, licence MIT.", "Jeu hors ligne. Aucun compte, publicité, télémétrie ou suivi.", "Détails fichier par fichier : CREDITS.md et docs/ASSETS_LEDGER.csv."]:
		v.add_child(_lbl(text, 25, INK))

func show_briefing(id: int) -> void:
	var level := Lv.get_level(id)
	var word := Lexicon.choose(id)
	var v := _text_page(tr("Étape %d · %s") % [id, level.name])
	var stories := ["Max et Lou commencent leur entraînement pour le tournoi international.", "Lou explore la plaza : chaque rencontre est une occasion de parler anglais.", "Sur la côte, Max apprend les mots qui décrivent le paysage.", "Le crew prépare ses figures dans les anciens entrepôts.", "Sous les lumières de la ville, place à la finale !", "Une session sur les toits pour fêter le chemin parcouru.", "Dernière escale aux docks : le voyage ne fait que commencer."]
	var story := _lbl(stories[clampi(id - 1, 0, stories.size() - 1)], 29, INK)
	story.custom_minimum_size.x = 1100
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(story)
	v.add_child(_lbl(str(word.word).to_upper() + ("  =  " + str(word.fr) if Save.hints else ""), 55, INK))
	v.add_child(_btn("Écouter le mot", func(): Sfx.speak(word.word), 650, 70, 29, false))
	v.add_child(_lbl("Lettres : dans l'ordre" if Save.ordered_letters else "Lettres : dans n'importe quel ordre", 27, INK))
	v.add_child(_lbl("Carrière : 1 étoile = mot complété ; 2 = score cible ; 3 = combo ≥ 400.", 25, INK))
	v.add_child(_lbl(tr("Score cible : %d. Le quiz ne bloque jamais ta progression.") % int(level.stars[0]), 25, INK))
	var mode: String = str(Engine.get_meta("mode", "career"))
	v.add_child(_lbl("Mode : " + mode + "  ·  Record : " + str(Save.records.get(mode + ":" + str(id), "—")), 26, INK))
	v.add_child(_btn("Rouler !", func(): action.emit("launch", id), 1000, 90, 36))

func show_teacher() -> void:
	var v := _text_page("Espace professeur / parent")
	v.add_child(_lbl("Données locales uniquement. Le PIN n'est pas un chiffrement.", 25, INK))
	if Save.teacher_pin_hash.is_empty():
		v.add_child(_lbl("Définis un PIN de 4 à 8 chiffres pour activer cet espace.", 27, INK))
	else:
		v.add_child(_lbl("Saisis le PIN pour ouvrir le bilan.", 27, INK))
	var pin := LineEdit.new()
	pin.secret = true
	pin.placeholder_text = "PIN"
	pin.max_length = 8
	pin.custom_minimum_size = Vector2(600, 70)
	pin.add_theme_font_size_override("font_size", 34)
	v.add_child(pin)
	var message := _lbl("", 25, RED)
	v.add_child(message)
	v.add_child(_btn("Valider", func():
		if pin.text.length() < 4 or not pin.text.is_valid_int():
			message.text = tr("Utilise 4 à 8 chiffres.")
			return
		var hash_value := ("Grindlish-local:" + pin.text).sha256_text()
		if Save.teacher_pin_hash.is_empty():
			Save.teacher_pin_hash = hash_value
			Save.save_data()
		if Save.teacher_pin_hash != hash_value:
			message.text = tr("PIN incorrect.")
			return
		show_teacher_unlocked(), 650, 75, 30))
	pin.grab_focus()

func show_teacher_unlocked() -> void:
	var v := _text_page("Bilan local")
	v.add_child(_lbl(tr("%d mots découverts  ·  %d révisions en attente") % [Lexicon.progress.size(), Lexicon.due_words().size()], 28, INK))
	var message := _lbl("", 23, INK)
	message.custom_minimum_size.x = 1100
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(message)
	v.add_child(_btn("Exporter le bilan CSV", func():
		var path := "user://grindlish_progress.csv"
		var err := Lexicon.export_csv(path)
		message.text = (tr("Export : ") + ProjectSettings.globalize_path(path)) if err == OK else tr("Erreur d'export : ") + str(err), 1000, 75, 30))
	v.add_child(_btn("Importer un vocabulaire JSON", func():
		var dialog := FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.json ; Vocabulaire Grindlish"])
		screen.add_child(dialog)
		dialog.file_selected.connect(func(path):
			message.text = Lexicon.import_custom(path)
			dialog.queue_free())
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered(Vector2i(1100, 700)), 1000, 75, 30, false))
	v.add_child(_lbl("Schéma et limites : docs/WORDS.md. L'original n'est jamais modifié.", 25, INK))
	v.add_child(_btn("Restaurer les mots d'origine", func():
		if FileAccess.file_exists(Lexicon.CUSTOM):
			DirAccess.remove_absolute(Lexicon.CUSTOM)
		Lexicon.load_words()
		message.text = tr("Vocabulaire d'origine restauré. Le carnet est conservé."), 1000, 75, 30, false))


func _safe_ui() -> void:
	if not OS.has_feature("mobile"):
		return
	var safe := DisplayServer.get_display_safe_area()
	var window := Vector2(DisplayServer.window_get_size())
	var scale_factor := get_viewport().get_visible_rect().size / window
	var left: float = maxf(0, safe.position.x) * scale_factor.x
	var right: float = maxf(0, window.x - safe.end.x) * scale_factor.x
	var top: float = maxf(0, safe.position.y) * scale_factor.y
	var bottom: float = maxf(0, window.y - safe.end.y) * scale_factor.y
	for root in [screen, hud]:
		root.offset_left = left
		root.offset_right = -right
		root.offset_top = top
		root.offset_bottom = -bottom

func _exit_tree() -> void:
	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(null)
