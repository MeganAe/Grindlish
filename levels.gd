extends RefCounted
## Données des parcs. Coordonnées en tuiles (1 tuile = 2,5 m). Hauteurs des lettres/pièces en mètres.
## Orientation d'une pièce : "n" = le côté haut est au nord (-z), "w" = -x, "s" = +z, "e" = +x.

static func rot(face: String) -> float:
	match face:
		"w":
			return 90.0
		"s":
			return 180.0
		"e":
			return 270.0
	return 0.0


## Rangée de pièces identiques : count pièces à partir de (x,z), pas (dx,dz).
static func row(name: String, x: float, z: float, count: int, dx: float, dz: float, face := "n", y := 0.0) -> Array:
	var out: Array = []
	for i in count:
		out.append([name, x + dx * i, z + dz * i, rot(face), y])
	return out


static func one(name: String, x: float, z: float, face := "n", y := 0.0) -> Array:
	return [[name, x, z, rot(face), y]]


## Cuvette (bowl) rectangulaire : intérieur de iw x id tuiles, coins en (cx,cz) = centre.
## `gap` : "" ou "n","s","e","w" pour laisser une entrée sans bord de ce côté.
static func bowl(cx: float, cz: float, iw: int, idp: int, gap := "") -> Array:
	var out: Array = []
	var x0 := cx - (iw + 1) / 2.0 + 0.5   # centre de la tuile du coin ouest
	var x1 := cx + (iw + 1) / 2.0 - 0.5
	var z0 := cz - (idp + 1) / 2.0 + 0.5
	var z1 := cz + (idp + 1) / 2.0 - 0.5
	out.append(["bowl-corner-inner", x0, z0, 0.0, 0.0])
	out.append(["bowl-corner-inner", x1, z0, 270.0, 0.0])
	out.append(["bowl-corner-inner", x1, z1, 180.0, 0.0])
	out.append(["bowl-corner-inner", x0, z1, 90.0, 0.0])
	for i in iw:
		var x := x0 + 1.0 + i
		if gap != "n":
			out.append(["bowl-side", x, z0, 0.0, 0.0])
		if gap != "s":
			out.append(["bowl-side", x, z1, 180.0, 0.0])
	for i in idp:
		var z := z0 + 1.0 + i
		if gap != "w":
			out.append(["bowl-side", x0, z, 90.0, 0.0])
		if gap != "e":
			out.append(["bowl-side", x1, z, 270.0, 0.0])
	return out


static func levels() -> Array:
	var L: Array = []

	# ------------------------------------------------------------------ 1
	var p1: Array = []
	p1.append_array(row("half-pipe", -6.5, -9.5, 14, 1, 0, "n"))
	p1.append_array(row("half-pipe", -9.5, -3.5, 6, 0, 1, "w"))
	p1.append_array(row("half-pipe", 9.5, -3.5, 6, 0, 1, "e"))
	p1.append_array(one("slope-smooth", 0, 5.0, "n"))
	p1.append_array(one("obstacle-box", 0, -1.0))
	p1.append_array(one("ramp", -4, 4.0, "n"))
	p1.append_array(one("ramp", 4, 4.0, "n"))
	p1.append_array(row("rail-low", -4, 1.5, 3, 0, -1, "n"))
	p1.append_array(row("rail-high", 4, 1.5, 3, 0, -1, "n"))
	p1.append_array(row("obstacle-box-grind", -7, 3.5, 3, 0, -1, "n"))
	p1.append_array(row("obstacle-box-grind", 7, 3.5, 3, 0, -1, "n"))
	p1.append_array(one("bench", -7.5, -4.0, "w"))
	p1.append_array(one("bench", 7.5, -4.0, "w"))
	p1.append_array(one("pallet", -2, -5.5))
	p1.append_array(one("pallet", 2, -5.5))
	L.append({
		"id": 1, "name": "Initiation", "desc": "Rampes, rails et murs : le terrain de jeu parfait",
		"size": [20, 20], "floor": "concrete", "time": 90, "pieces": p1,
		"spawn": [0.0, 8.0], "face": "n",
		"stars": [4500, 14000],
		"sky": [Color(0.45, 0.7, 0.95), Color(0.85, 0.92, 1.0)], "outer": Color(0.5, 0.68, 0.45),
		"letters": [[-4, 2.1, 0.5], [4, 2.7, 0.5], [0, 3.4, -1], [-3, 3.3, -8.6], [3, 3.3, -8.6]],
		"coins": _coins_line(0, 8, 0, 6, 5) + _coins_line(-1.5, -3.5, -1.5, -8, 4) + _coins_line(1.5, -3.5, 1.5, -8, 4)
			+ _coins_line(-8, 5, -8, -3, 5) + _coins_line(8, 5, 8, -3, 5),
	})

	# ------------------------------------------------------------------ 2
	var p2: Array = []
	p2.append_array(row("half-pipe-low", -8.5, -11.5, 18, 1, 0, "n"))
	p2.append_array(row("steps", -6, 6, 3, 1, 0, "n"))
	p2.append_array(row("obstacle-middle-rail", -6, 3.0, 1, 0, 0, "n"))
	p2.append_array(row("rail-high", 0, 7, 5, 0, -1, "n"))
	p2.append_array(row("rail-low", -9, 8, 6, 0, -1, "n"))
	p2.append_array(row("rail-low", 9, 8, 6, 0, -1, "n"))
	p2.append_array(one("ramp", -3, 9.5, "n"))
	p2.append_array(one("ramp", 3, 9.5, "n"))
	p2.append_array(row("obstacle-box-grind", 6, 2, 4, 0, -1, "n"))
	p2.append_array(row("obstacle-box-grind", -6, -3, 4, 0, -1, "n"))
	p2.append_array(one("slope-smooth", 0, -4.0, "n"))
	p2.append_array(row("bowl-platform", 0, -6.5, 1, 0, 0))
	p2.append_array(one("bench", -3, 0.0, "w"))
	p2.append_array(one("bench", 3, 0.0, "w"))
	p2.append_array(one("benches", 9, -2, "w"))
	p2.append_array(one("pallet", -9, -4))
	p2.append_array(one("vehicle", 10.5, -5.5, "n"))
	p2.append_array(row("obstacle-box", -9, -8.5, 2, 1, 0))
	p2.append_array(row("obstacle-box", 8, -8.5, 2, 1, 0))
	L.append({
		"id": 2, "name": "Plaza", "desc": "Rails, escaliers et boîtes dans une place urbaine",
		"size": [24, 26], "floor": "concrete", "time": 100, "pieces": p2,
		"spawn": [0.0, 11.0], "face": "n",
		"stars": [1800, 5000],
		"sky": [Color(0.95, 0.65, 0.45), Color(1.0, 0.9, 0.7)], "outer": Color(0.62, 0.58, 0.5),
		"letters": [[-6, 3.0, 4.0], [0, 2.5, 4.0], [9, 1.8, 3.0], [-6, 2.0, -5.0], [0, 4.2, -6.2]],
		"coins": _coins_line(0, 11, 0, 8, 4) + _coins_line(-9, 8, -9, 2, 5) + _coins_line(9, 8, 9, 2, 5)
			+ _coins_line(-9, -4, 9, -4, 8) + _coins_line(-4, 0, 4, 0, 6),
	})

	# ------------------------------------------------------------------ 3
	var p3: Array = []
	p3.append_array(row("half-pipe", -9.5, -12.5, 20, 1, 0, "n"))
	p3.append_array(row("half-pipe", -9.5, 12.5, 20, 1, 0, "s"))
	p3.append_array(row("half-pipe-low", -10.5, -9, 4, 0, 1, "w"))
	p3.append_array(row("half-pipe-low", 10.5, -9, 4, 0, 1, "e"))
	p3.append_array(row("half-pipe-low", -10.5, 5, 4, 0, 1, "w"))
	p3.append_array(row("half-pipe-low", 10.5, 5, 4, 0, 1, "e"))
	p3.append_array(row("rail-high", 0, 4, 8, 0, -1, "n"))
	p3.append_array(one("ramp", 0, 7.5, "n"))
	p3.append_array(one("ramp", 0, -7.5, "s"))
	p3.append_array(one("obstacle-box", -5, 0))
	p3.append_array(one("obstacle-box", 5, 0))
	p3.append_array(row("obstacle-box-grind", -5, 2, 4, 0, -1, "n"))
	p3.append_array(row("obstacle-box-grind", 5, 2, 4, 0, -1, "n"))
	L.append({
		"id": 3, "name": "Half-Pipe", "desc": "De grands murs face à face : monte haut et enchaîne !",
		"size": [24, 30], "floor": "wood", "time": 100, "pieces": p3,
		"spawn": [0.0, 9.0], "face": "n",
		"stars": [3800, 12000],
		"sky": [Color("639caf"), Color("cfdfce")], "outer": Color(0.55, 0.5, 0.6),
		"letters": [[-6, 3.6, -13.2], [6, 3.6, -13.2], [0, 4.0, 13.2], [-5, 2.4, 0], [5, 2.4, 0]],
		"coins": _coins_line(0, 10, 0, -10, 12) + _coins_line(-8, 8, -8, -8, 8) + _coins_line(8, 8, 8, -8, 8),
	})

	# ------------------------------------------------------------------ 4
	var p4: Array = []
	p4.append_array(row("half-pipe", -9.5, -11.5, 20, 1, 0, "n"))
	# grande rampe qui mène à un deck surélevé
	p4.append_array(one("slope-smooth", -4, 7.0, "n"))
	p4.append_array(row("bowl-platform", -4, 5.5, 1, 0, 0))
	p4.append_array(row("bowl-platform", -4, 4.5, 1, 0, 0))
	p4.append_array(row("bowl-platform", -4, 3.5, 1, 0, 0))
	p4.append_array(row("bowl-platform", -4, 2.5, 1, 0, 0))
	p4.append_array(row("half-pipe", -4, 1.5, 1, 0, 0, "s"))
	p4.append_array(one("slope-smooth", 4, 7.0, "n"))
	p4.append_array(row("bowl-platform", 4, 5.5, 1, 0, 0))
	p4.append_array(row("bowl-platform", 4, 4.5, 1, 0, 0))
	p4.append_array(row("bowl-platform", 4, 3.5, 1, 0, 0))
	p4.append_array(row("bowl-platform", 4, 2.5, 1, 0, 0))
	p4.append_array(row("half-pipe", 4, 1.5, 1, 0, 0, "s"))
	p4.append_array(row("rail-low", 0, 8, 6, 0, -1, "n"))
	p4.append_array(one("ramp", 0, 10, "n"))
	p4.append_array(row("obstacle-middle", -8, -2, 2, 1, 0))
	p4.append_array(row("obstacle-middle", 7, -2, 2, 1, 0))
	p4.append_array(row("rail-high", -8, -5, 4, 0, -1, "n"))
	p4.append_array(row("rail-high", 8, -5, 4, 0, -1, "n"))
	p4.append_array(one("steps", 0, -2, "n"))
	p4.append_array(one("steps", 0, -3, "n"))
	p4.append_array(one("bench", -2, 3, "w"))
	p4.append_array(one("bench", 2, 3, "w"))
	L.append({
		"id": 4, "name": "Skate Park", "desc": "Decks surélevés et grandes rampes",
		"size": [24, 26], "floor": "concrete", "time": 110, "pieces": p4,
		"spawn": [0.0, 12.0], "face": "n",
		"stars": [3000, 10000],
		"sky": [Color("546a87"), Color("e9bd99")], "outer": Color(0.4, 0.4, 0.5),
		"letters": [[-4, 5.0, 4.0], [4, 5.0, 4.0], [0, 2.4, 3.5], [-8, 3.0, -4.0], [8, 3.0, -4.0]],
		"coins": _coins_line(0, 12, 0, 6, 5) + _coins_line(-8, 6, -8, -4, 6) + _coins_line(8, 6, 8, -4, 6)
			+ _coins_line(-9, -8, 9, -8, 10),
	})

	# ------------------------------------------------------------------ 5
	var p5: Array = []
	p5.append_array(bowl(0, -3, 8, 6, "s"))
	p5.append_array(row("half-pipe", -9.5, -12.5, 20, 1, 0, "n"))
	p5.append_array(row("rail-high", -8, 11, 6, 0, -1, "n"))
	p5.append_array(row("rail-high", 8, 11, 6, 0, -1, "n"))
	p5.append_array(row("rail-low", -10, 11, 6, 0, -1, "n"))
	p5.append_array(row("rail-low", 10, 11, 6, 0, -1, "n"))
	p5.append_array(one("ramp", -8, 12.5, "n"))
	p5.append_array(one("ramp", 8, 12.5, "n"))
	p5.append_array(one("slope-smooth", 0, 10.0, "n"))
	p5.append_array(row("obstacle-box-grind", -3, 5, 3, 0, -1, "n"))
	p5.append_array(row("obstacle-box-grind", 3, 5, 3, 0, -1, "n"))
	p5.append_array(one("vehicle", -10, 3, "w"))
	p5.append_array(one("bench", 10, 3, "w"))
	L.append({
		"id": 5, "name": "Bowl", "desc": "Le grand bowl : le défi ultime",
		"size": [26, 30], "floor": "wood", "time": 120, "pieces": p5,
		"spawn": [0.0, 13.0], "face": "n",
		"stars": [6000, 19000],
		"sky": [Color(0.05, 0.08, 0.25), Color(0.4, 0.3, 0.6)], "outer": Color(0.2, 0.22, 0.32),
		"letters": [[-4, 3.6, -6], [4, 3.6, -6], [0, 4.5, -3], [-8, 2.4, 6], [8, 2.4, 6]],
		"coins": _coins_line(0, 13, 0, 4, 8) + _coins_line(-5, -3, 5, -3, 8) + _coins_line(-9, 10, -9, 3, 6)
			+ _coins_line(9, 10, 9, 3, 6),
	})
	# Bonus spots, authored from the same original kit, with clear floor routes.
	for bonus in 2:
		var id := 6 + bonus
		var pieces: Array = []
		pieces.append_array(row("half-pipe-low", -5.5, -7.5, 12, 1, 0, "n"))
		pieces.append_array(row("rail-low", -4 if bonus == 0 else 4, 3, 4, 0, -1))
		pieces.append_array(one("ramp", 4 if bonus == 0 else -4, 4))
		pieces.append_array(one("obstacle-box", 0, -3))
		pieces.append_array(one("bench", -6, 5, "w"))
		L.append({"id": id, "name": "Rooftop" if bonus == 0 else "Docks", "desc": "Session sur les toits" if bonus == 0 else "Une dernière escale au port", "size": [18, 20], "floor": "concrete" if bonus == 0 else "wood", "time": 150, "pieces": pieces, "spawn": [0.0, 7.0], "face": "n", "stars": [3300, 10000], "sky": [Color("284660"), Color("edb783")] if bonus == 0 else [Color("75b6c9"), Color("d3e9de")], "outer": Color("233e50") if bonus == 0 else Color("357d94"), "letters": [[0, 1.1, 0]], "coins": _coins_line(-5, 6, -5, -5, 7) + _coins_line(5, 6, 5, -5, 7)})
	# Eight principal worlds plus the two existing bonus IDs (6/7). Save IDs stay stable.
	for extra in 3:
		var pieces: Array = []
		if extra==0:
			pieces.append_array(row("half-pipe-low", -7.5, -8.5, 16, 1, 0))
			pieces.append_array(row("rail-low", -5, 4, 5, 0, -1))
			pieces.append_array(one("ramp", 4, 6))
			pieces.append_array(one("obstacle-box", 1, -4))
		elif extra==1:
			pieces.append_array(row("slope-smooth", -7.5, -8, 16, 1, 0))
			pieces.append_array(row("half-pipe-low", -7.5, 8, 16, 1, 0, "s"))
			pieces.append_array(row("rail-high", 5, 3, 6, 0, -1))
			pieces.append_array(one("ramp", -5, 0, "e"))
		else:
			pieces.append_array(row("half-pipe", -8, -8, 17, 1, 0))
			pieces.append_array(row("half-pipe-low", -8, -5, 12, 0, 1, "w"))
			pieces.append_array(row("rail-high", 4, 4, 6, 0, -1))
			pieces.append_array(one("ramp-rail", 7, 3, "w"))
			pieces.append_array(one("slope-smooth", 4, 6))
		pieces.append_array(one("bench", 8, 7, "w"))
		L.append({"id": 8+extra, "name": ["Prairie", "Alpages", "Stade"][extra], "desc": ["Moulins, vergers et grand air", "Chalets, télécabine et neige légère", "La finale sous les projecteurs"][extra], "size": [22,24], "floor": "wood" if extra==0 else "concrete", "floor_colour": [Color("74916c"),Color("7094a5"),Color("526a89")][extra], "time": 150+extra*10, "pieces": pieces, "spawn": [0.0,9.0], "face": "n", "stars": [3500+extra*500,12000+extra*1500], "sky": [[Color("669ed2"),Color("dce8df")],[Color("6a94ba"),Color("d4e2e8")],[Color("223a68"),Color("7993b6")]][extra], "outer": [Color("77a960"),Color("a6c6cd"),Color("38546c")][extra], "letters": [[0,1.1,0]], "coins": _coins_line(-7,8,-7,-5,8)+_coins_line(7,8,7,-5,8)})
	return L


static func _coins_line(x0: float, z0: float, x1: float, z1: float, n: int) -> Array:
	var out: Array = []
	for i in n:
		var t := float(i) / maxf(1.0, n - 1.0)
		out.append([lerpf(x0, x1, t), 1.1, lerpf(z0, z1, t)])
	return out


static func get_level(id: int) -> Dictionary:
	var all := levels()
	return all[clampi(id, 1, all.size()) - 1]


static func count() -> int:
	return 10
