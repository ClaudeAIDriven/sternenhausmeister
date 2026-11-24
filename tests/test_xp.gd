extends SceneTree
## Test G-26: XP-Kurve, Punkt bei Aufstieg, Fähigkeit wirkt (nur eigene Rolle), Daten prüfen, Oberfläche.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var x := Xp.new()
	# Kurve: wächst, Summen stimmen
	ok = ok and Xp.total_for(1) == 0 and Xp.total_for(2) == 40 and Xp.total_for(3) == 100 and Xp.need(5) > Xp.need(1)
	ok = ok and x.level == 1 and x.points == 0 and x.progress() == 0.0
	# Quellen
	ok = ok and x.add_event("spot", 10) == 0 and x.xp == 10
	var lv_seen := {"n": 0}
	x.leveled_up.connect(func(_l): lv_seen["n"] += 1)
	var x2 := Xp.new()
	x2.leveled_up.connect(func(_l): lv_seen["n"] += 1)
	ok = ok and x2.add_xp(40) == 1 and x2.level == 2 and x2.points == 1 and lv_seen["n"] == 1   # genau bei 40
	ok = ok and x2.add_xp(500) >= 3 and x2.points == x2.level - 1                              # mehrere Stufen auf einmal
	ok = ok and x2.add_xp(-5) == 0 and x2.add_event("gibt_es_nicht") == 0
	var x3 := Xp.new()
	x3.add_xp(1000000)
	ok = ok and x3.level == Xp.MAX_LEVEL and x3.progress() == 1.0 and x3.add_xp(10) == 0
	# Fähigkeiten
	var xp := Xp.new()
	var s := Skills.new(xp, "putzer")
	ok = ok and s.list.size() == 21 and s.mult("wipe") == 1.0
	ok = ok and not s.can_learn("putzer_glanz")   # keine Punkte
	xp.add_xp(40)
	ok = ok and s.learn("putzer_glanz") and xp.points == 0 and s.level("putzer_glanz") == 1
	ok = ok and is_equal_approx(s.mult("wipe"), 1.1) and not s.learn("putzer_glanz")   # kein Punkt mehr
	xp.add_xp(300)
	ok = ok and s.learn("putzer_glanz") and is_equal_approx(s.mult("wipe"), 1.21)      # Stufen potenzieren
	ok = ok and not s.learn("koch_festmahl") and s.mult("recipe_food") == 1.0          # fremde Rolle
	ok = ok and s.learn("taschen") and is_equal_approx(s.add("bag_slots"), 1.0) and is_equal_approx(s.apply("bag_slots", 6.0), 7.0)
	ok = ok and s.learn("ausdauer") and is_equal_approx(s.mult("hunger"), 0.9)
	# Maximalstufe
	xp.add_xp(100000)
	while s.learn("taschen"):
		pass
	ok = ok and s.level("taschen") == 2 and not s.can_learn("taschen")
	# Rolle Koch sieht ihre eigenen
	var sk := Skills.new(xp, "koch")
	ok = ok and sk.learn("koch_festmahl") and is_equal_approx(sk.mult("recipe_food"), 1.2) and not sk.learn("putzer_glanz")
	# jede Rolle hat genau 3 eigene
	for rid in Roles.ids():
		var n := 0
		for e in s.list:
			if e["role"] == rid:
				n += 1
		ok = ok and n == 3
	# Daten prüfen
	var f := FileAccess.open("user://bad_skills.json", FileAccess.WRITE)
	f.store_string('{"skills":[{"id":"a","name":"A","desc":"","role":"keinerolle","max_level":1,"effect":{"stat":"x","mult":1.1}}]}')
	f.close()
	ok = ok and s.load_data("user://bad_skills.json") != ""
	s.load_data()
	# Oberfläche
	var xp2 := Xp.new()
	var s2 := Skills.new(xp2, "springer")
	var ui = load("res://skills_ui.gd").new()
	root.add_child(ui)
	ui.bind(s2)
	ok = ok and ui.rows.size() == 21 and ui.rows["springer_doppel"]["row"].visible and not ui.rows["koch_festmahl"]["row"].visible
	ok = ok and ui.rows["springer_doppel"]["button"].disabled
	xp2.add_xp(40)
	ok = ok and not ui.rows["springer_doppel"]["button"].disabled and ui.head_label.text.contains("1 freie")
	s2.learn("springer_doppel")
	ok = ok and is_equal_approx(s2.add("double_jump"), 1.0) and ui.head_label.text.contains("0 freie")
	print("TEST_XP OK" if ok else "TEST_XP FAIL")
	quit(0 if ok else 1)
	return true
