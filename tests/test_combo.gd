extends SceneTree
## Test G-12: Kombo-Stufen steigen mit Serie, Bonus gedeckelt, Pause setzt zurück, kein Staub geht verloren.
func _init() -> void:
	var C = load("res://combo.gd")
	var c = C.new()
	var ok := true
	var total := 0
	var t := 0.0
	ok = ok and c.level == 0 and is_equal_approx(c.multiplier(), 1.0)
	# 60 Flecken in schneller Folge: Stufe 5 (60/12), Bonus +50 %
	for i in 60:
		t += 0.1
		total += c.hit(t, 1)
	ok = ok and c.level == 5 and is_equal_approx(c.multiplier(), 1.5) and is_equal_approx(c.pitch(), 1.3)
	# weiter wischen: Stufe bleibt bei Maximum
	for i in 40:
		t += 0.1
		total += c.hit(t, 1)
	ok = ok and c.level == C.MAX_LEVEL
	# Staub: erste 12 Flecken 1,0x, dann steigend, Rest übertragen -> Summe nahe an Soll
	ok = ok and total > 100 and total <= 150
	# Pause > WINDOW: Serie zurück
	t += 2.0
	c.tick(t)
	ok = ok and c.level == 0 and c.streak == 0
	# neue Serie beginnt bei 1,0x
	ok = ok and c.hit(t + 0.1, 1) == 1 and c.level == 0
	# 0 Flecken: kein Staub, Serie unverändert
	ok = ok and c.hit(t + 0.2, 0) == 0
	# Signal bei Stufenwechsel
	var seen := []
	c.level_changed.connect(func(l): seen.append(l))
	var c2 = C.new()
	c2.level_changed.connect(func(l): seen.append(l))
	c2.hit(0.0, 12)
	ok = ok and seen == [1]
	print("TEST_COMBO ", "OK" if ok else "FAIL total=%d level=%d" % [total, c.level])
	quit(0 if ok else 1)
