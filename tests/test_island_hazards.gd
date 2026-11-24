extends SceneTree
## Test M-04: Gefahren aus dem Seed: gleiche Seeds = gleich, Mindestabstände, nichts auf Orten/Sternen-Boden, alles erreichbar (Flood-Fill).
var frames := 0
func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var G = load("res://island_gen.gd")
	var M = load("res://maps.gd")
	var bad := 0
	var short := 0
	for id in M.ids():
		var prof: Dictionary = M.profile(id)
		for s in range(1, 101):
			var lay: Dictionary = G.generate(s)
			var hz: Dictionary = G.generate_hazards(s, prof, lay)
			if not G.reachable(hz, lay):
				bad += 1
			# Abstände Lava/Lava >= 9, Orte >= Radius+3
			for i in hz["lava"].size():
				for j in range(i + 1, hz["lava"].size()):
					if Vector2(hz["lava"][i].x, hz["lava"][i].z).distance_to(Vector2(hz["lava"][j].x, hz["lava"][j].z)) < 9.0 - 0.01:
						bad += 1
				for k in lay["pois"]:
					var q: Vector3 = lay["pois"][k]
					if Vector2(hz["lava"][i].x, hz["lava"][i].z).distance_to(Vector2(q.x, q.z)) < 6.0 - 0.01:
						bad += 1
				if Vector2(hz["lava"][i].x, hz["lava"][i].z).length() < 6.0:
					bad += 1
			if hz["lava"].size() < int(prof["lava"]) or hz["cactus"].size() < int(prof["cactus"]) - 2:
				short += 1
	ok = ok and bad == 0
	ok = ok and short < 60   # selten dürfen Gefahren der Erreichbarkeit weichen
	# Determinismus
	var lay2: Dictionary = G.generate(4242)
	ok = ok and G.generate_hazards(4242, M.profile("lavafelder"), lay2) == G.generate_hazards(4242, M.profile("lavafelder"), lay2)
	# Absichtlich blockierter Weg wird erkannt (Ring aus Lava um den Start)
	var ring: Array = []
	for i in 16:
		ring.append(Vector3(cos(TAU * i / 16.0) * 8.0, 0, sin(TAU * i / 16.0) * 8.0))
	ok = ok and not G.reachable({"lava": ring, "cactus": [], "nests": []}, lay2)
	# Welt übernimmt
	root.get_node("GameState").player_count = 1
	var w = load("res://world.gd").new()
	root.add_child(w)
	w.set_map("lavafelder")
	var classic_lava := 0
	for h in w.hazard_nodes:
		if h.kind == "lava":
			classic_lava += 1
	w.set_island_seed(31337)
	var seeded := 0
	for h in w.hazard_nodes:
		if is_instance_valid(h) and h.kind == "lava":
			seeded += 1
	ok = ok and classic_lava == 8 and seeded >= 3
	print("TEST_ISLAND_HAZARDS ", "OK" if ok else "FAIL", " bad=", bad, " short=", short, " seeded_lava=", seeded)
	quit(0 if ok else 1)
	return true
