extends SceneTree
## Test G-31: gleicher Seed = gleiche Insel, Mindestabstände, alles auf der Insel und erreichbar; Welt übernimmt Seed.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var G = load("res://island_gen.gd")
	var a: Dictionary = G.generate(12345)
	var b: Dictionary = G.generate(12345)
	var c: Dictionary = G.generate(54321)
	ok = ok and a["stars"] == b["stars"] and a["pois"] == b["pois"]
	ok = ok and a["stars"] != c["stars"]
	ok = ok and a["stars"].size() == 8 and a["pois"].size() == 4
	# Viele Seeds: immer gültig (Abstände >= 9, innerhalb, nicht auf Bauten)
	var bad := 0
	for s in range(1, 301):
		var lay: Dictionary = G.generate(s)
		var errs: Array = G.validate(lay)
		if not errs.is_empty():
			bad += 1
			if bad < 4:
				print("SEED ", s, " ", errs)
	ok = ok and bad == 0
	# Echte Mindestabstände (ohne Entspannung) für einen Beispielseed prüfen
	var minst := 1e9
	for i in a["stars"].size():
		for j in range(i + 1, a["stars"].size()):
			minst = minf(minst, Vector2(a["stars"][i].x, a["stars"][i].z).distance_to(Vector2(a["stars"][j].x, a["stars"][j].z)))
	ok = ok and minst >= 9.0 * 0.6
	# Validate erkennt Fehler
	var broken: Dictionary = {"stars": a["stars"].duplicate(), "pois": a["pois"].duplicate()}
	broken["stars"][1] = broken["stars"][0] + Vector3(1, 0, 0)
	ok = ok and not G.validate(broken).is_empty()
	# Welt übernimmt den Seed (Sterne + Orte), Seed 0 = klassisch
	root.get_node("GameState").player_count = 1
	var w = load("res://world.gd").new()
	root.add_child(w)
	var classic: Vector3 = w.stars[0].position
	ok = ok and w.set_island_seed(12345)
	ok = ok and w.island_seed == 12345 and w.stars[0].position == a["stars"][0]
	var found := {}
	for p in w.pois:
		found[p.kind] = p.position
	ok = ok and found["brunnen"] == a["pois"]["brunnen"] and found.has("kueche") and found.size() == 5
	ok = ok and w.enemies.size() > 0
	ok = ok and w.set_island_seed(0) and w.stars[0].position == classic
	# Nach dem Putzen kein Seedwechsel mehr
	w.wipe_at(w.stars[0].global_position + Vector3(0, w.stars[0].radius, 0), 1.5)
	ok = ok and not w.set_island_seed(99)
	print("TEST_ISLAND_GEN OK" if ok else "TEST_ISLAND_GEN FAIL")
	quit(0 if ok else 1)
	return true
