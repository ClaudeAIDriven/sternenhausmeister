extends SceneTree
## Test G-03: richtige Reihenfolge löst, falsche nicht; Hinweis und Zurücksetzen; Bonus-Staub.

func _initialize() -> void:
	var ok := true
	var all: Array = ConstellationLoader.load_dir("res://data/constellations")
	ok = ok and all.size() == 8
	# richtige Reihenfolge löst jedes Beispiel und gibt Bonus
	for d in all:
		var c := Constellation.from_data(d)
		var bonus := [-1]
		c.solved.connect(func(b): bonus[0] = b)
		var r := ""
		for o in d["order"]:
			r = c.report_cleaned(int(o))
		ok = ok and r == "solved" and c.is_solved and bonus[0] == 5 * d["stars"].size() and c.hint() == -1
	# falsche Reihenfolge löst nicht
	var c2 := Constellation.from_data(all[1])   # Kassiopeia 0..4
	var info := {}
	c2.wrong.connect(func(s, h, red): info["s"] = s; info["h"] = h; info["red"] = red)
	ok = ok and c2.report_cleaned(0) == "ok" and c2.report_cleaned(1) == "ok"
	ok = ok and c2.hint() == 2
	ok = ok and c2.report_cleaned(4) == "wrong"
	ok = ok and info.get("s") == 4 and info.get("h") == 2 and info.get("red") == [0, 1, 4]
	ok = ok and c2.done == 0 and not c2.is_solved and c2.mistakes == 1
	# umgekehrte Reihenfolge von Anfang an löst nie
	var c3 := Constellation.from_data(all[0])
	var rev: Array = all[0]["order"].duplicate()
	rev.reverse()
	var res := ""
	for o in rev:
		res = c3.report_cleaned(int(o))
	ok = ok and not c3.is_solved
	# nach Fehler kann man es richtig neu versuchen
	var c4 := Constellation.from_data(all[1])
	c4.report_cleaned(3)
	for o in all[1]["order"]:
		res = c4.report_cleaned(int(o))
	ok = ok and res == "solved"
	# Unbekannter Stern und Doppelmeldung nach Lösung werden ignoriert; ungültige Daten -> null
	ok = ok and c4.report_cleaned(99) == "ignored" and c4.report_cleaned(0) == "ignored"
	ok = ok and Constellation.from_data({"id": "x"}) == null
	print("TEST_CONSTELLATION_LOGIC OK" if ok else "TEST_CONSTELLATION_LOGIC FAIL")
	quit(0 if ok else 1)
