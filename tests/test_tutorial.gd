extends SceneTree
## Test U-06: Hilfe läuft in Schritten (Start -> erster Wisch -> erster Stern), pulsiert den ersten Sternbild-Stern, merkt sich "fertig".
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var st = root.get_node("Settings")
	st.reset_to_defaults()
	var w = load("res://world.gd").new()
	root.add_child(w)
	var h = load("res://hud.gd").new()
	root.add_child(h)
	var t = load("res://tutorial.gd").new()
	root.add_child(t)
	t.bind(w, h)
	var ok: bool = t.active and t.step == 0 and "Willkommen" in h.text()
	var first: int = w.puzzle.hint()
	ok = ok and w.stars[first]._hint
	# erster Wisch -> Schritt 2
	var s = w.stars[0]
	w.wipe_at(s.to_global(s.spots[0].position), 0.9)
	ok = ok and t.step == 1 and "ganzen Stern" in h.text()
	# Stern ganz sauber -> Schritt 3, danach gespeichert
	var guard := 0
	while not s.is_clean and guard < 5000:
		w.wipe_at(s.to_global(s.spots[0].position), 0.9)
		guard += 1
	ok = ok and t.step == 3 and bool(st.get_value("tutorial_done")) and "Sternbild" in h.text()
	# nächster Start: Hilfe bleibt aus
	var t2 = load("res://tutorial.gd").new()
	root.add_child(t2)
	t2.bind(w, h)
	ok = ok and not t2.active and t2.step == 4
	st.reset_to_defaults()
	print("TEST_TUTORIAL ", "OK" if ok else "FAIL step=%d" % t.step)
	quit(0 if ok else 1)
	return false
