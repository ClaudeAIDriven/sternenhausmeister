extends SceneTree
## Test M-03: Jede Karte baut sich, Gefahren/Gegner gemäß Profil, Bodenfarbe, Wechsel nur vor dem Putzen.
var frames := 0
func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var M = load("res://maps.gd")
	root.get_node("GameState").player_count = 2
	var w = load("res://world.gd").new()
	root.add_child(w)
	ok = ok and M.ids()[0] == "mondwiese" and M.ids().size() == 4
	var counts := {}
	for id in M.ids():
		ok = ok and w.set_map(id) and w.map_id == id
		var prof: Dictionary = M.profile(id)
		var c := {"lava": 0, "cactus": 0, "spider": 0}
		for h in w.hazard_nodes:
			if is_instance_valid(h) and not h.is_queued_for_deletion():
				c[h.kind] += 1
		ok = ok and c["lava"] == prof["lava"] and c["cactus"] == prof["cactus"] and c["spider"] == prof["nests"]
		var sp := 0
		var bn := 0
		for e in w.enemies:
			if e.kind == "spinne":
				sp += 1
			elif e.kind == "wollmaus":
				bn += 1
		counts[id] = [sp, bn]
		ok = ok and (w.ground_mesh.material_override as StandardMaterial3D).albedo_color == prof["ground"]
	ok = ok and counts["spinnenhoehle"][0] > counts["mondwiese"][0] and counts["lavafelder"][1] < counts["mondwiese"][1]
	ok = ok and not M.valid("quatsch")
	w.apply_map("quatsch")
	ok = ok and w.map_id == "mondwiese"
	w.set_map("lavafelder")
	w.wipe_at(w.stars[0].global_position + Vector3(0, w.stars[0].radius, 0), 1.5)
	ok = ok and not w.set_map("kaktuswueste") and w.map_id == "lavafelder"
	print("TEST_MAPS OK" if ok else "TEST_MAPS FAIL")
	quit(0 if ok else 1)
	return true
