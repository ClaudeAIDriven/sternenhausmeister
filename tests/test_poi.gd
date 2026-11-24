extends SceneTree
## Test G-30: Jeder Ort wirkt: Brunnen heilt 2/s, Obstgarten trägt Früchte, Turm zeigt Gegner, Schrein gibt 60 s Buff mit Abklingzeit, Küche steht; Minimap-Symbole.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var P = load("res://poi.gd")
	P.reset_state()
	var w = load("res://world.gd").new()
	root.add_child(w)
	ok = ok and w.pois.size() == 5 and w.kitchen != null and w.kitchen.position.is_equal_approx(w.kitchen.KITCHEN_POS)
	var kinds := {}
	for p in w.pois:
		kinds[p.kind] = p
	for k in ["brunnen", "obstgarten", "turm", "schrein", "kueche"]:
		ok = ok and kinds.has(k)
	var pl = load("res://player.gd").new()
	pl.name = "1"
	root.add_child(pl)
	# Brunnen
	var b = kinds["brunnen"]
	pl.global_position = b.global_position + Vector3(1, 0, 0)
	pl.health = 50.0
	b.local_tick(pl, 5.0)
	ok = ok and is_equal_approx(pl.health, 60.0)
	pl.global_position = b.global_position + Vector3(20, 0, 0)
	b.local_tick(pl, 5.0)
	ok = ok and is_equal_approx(pl.health, 60.0)   # zu weit weg
	pl.global_position = b.global_position
	pl.health = 99.0
	b.local_tick(pl, 5.0)
	ok = ok and pl.health == pl.MAX_HEALTH
	# Obstgarten: viele Früchte in der Nähe
	var og = kinds["obstgarten"]
	var near := 0
	for f in w.fruits:
		if og.is_near(f.global_position):
			near += 1
	ok = ok and near >= 6
	# Turm
	var t = kinds["turm"]
	ok = ok and not P.tower_active
	pl.global_position = t.global_position + Vector3(1, 0, 0)
	t.local_tick(pl, 0.1)
	ok = ok and P.tower_active
	pl.global_position = t.global_position + Vector3(15, 0, 0)
	t.local_tick(pl, 0.1)
	ok = ok and not P.tower_active
	# Schrein
	var s = kinds["schrein"]
	ok = ok and P.buff_mult("wipe") == 1.0 and not s.activate(pl)   # zu weit
	pl.global_position = s.global_position + Vector3(1, 0, 0)
	ok = ok and s.activate(pl) and is_equal_approx(P.buff_mult("wipe"), 1.25) and P.buff_mult("speed") == 1.0
	ok = ok and not s.activate(pl)   # Abklingzeit
	s.local_tick(pl, 59.0)
	ok = ok and P.buff_mult("wipe") > 1.0
	s.local_tick(pl, 2.0)
	ok = ok and P.buff_mult("wipe") == 1.0
	ok = ok and not s.activate(pl)   # 61 s von 120 s Abklingzeit
	s.local_tick(pl, 60.0)
	ok = ok and s.activate(pl)
	# Symbole für die Karte: je Ort eigene Farbe und gültige Form
	var cols := {}
	for p in w.pois:
		ok = ok and ["circle", "square", "triangle", "diamond"].has(p.map_shape()) and p.is_in_group("pois")
		cols[p.map_color()] = true
	ok = ok and cols.size() == 5
	P.reset_state()
	print("TEST_POI OK" if ok else "TEST_POI FAIL")
	quit(0 if ok else 1)
	return true
