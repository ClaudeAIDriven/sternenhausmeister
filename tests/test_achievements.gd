extends SceneTree
## Test M-09: Erfolge lösen aus (inkl. Hut), Tagebuch, speichern und laden.
var frames := 0
func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var A = load("res://achievements.gd")
	var a = A.new()
	a.path = "user://test_ach.json"
	ok = ok and A.DEFS.size() == 20
	var ids := {}
	for d in A.DEFS:
		ids[d[0]] = true
	ok = ok and ids.size() == 20
	var fired := []
	a.unlocked.connect(func(id, _t, hat): fired.append([id, hat]))
	ok = ok and a.count("spot", 9).is_empty()
	ok = ok and a.count("spot", 1) == ["erste_schritte"]
	ok = ok and a.count("spot", 1).is_empty()   # nur einmal
	a.count("spot", 489)
	ok = ok and a.done.has("fleissig") and a.hats.has("zylinder")
	ok = ok and fired.size() == 2 and fired[1] == ["fleissig", "zylinder"]
	ok = ok and a.set_max("dust_max", 6000) == ["reicher_staub"] and a.hats.has("krone")
	ok = ok and a.set_max("dust_max", 100).is_empty()
	a.record_night(1, 3, 120, 140)
	a.record_night(2, 4, 300, 200)
	ok = ok and a.counts["night"] == 2 and a.diary_text(1) == "Nacht 2: 4 Sterne, 300 Staub, 200 Flecken"
	ok = ok and a.progress_text().begins_with("3 / 20")
	# Speichern/Laden
	ok = ok and a.save() == OK
	var b = A.new()
	b.path = "user://test_ach.json"
	ok = ok and b.load_file() and b.done.size() == a.done.size() and b.hats == a.hats and b.counts["spot"] == a.counts["spot"] and b.diary.size() == 2
	ok = ok and b.count("night", 1) == ["nachtwache"] and b.count("night", 1).is_empty()
	DirAccess.remove_absolute("user://test_ach.json")
	# Hut-Bauteile existieren
	var look = load("res://player_look.gd")
	var node := Node3D.new()
	for hid in ["zylinder", "krone", "sternmuetze", "schleife", "haube", "helm"]:
		look.update_hat(node, hid)
		ok = ok and node.get_node_or_null("Hat") != null and node.get_node("Hat").get_child_count() > 0
	look.update_hat(node, "allrounder")
	ok = ok and node.get_node_or_null("Hat") == null
	print("TEST_ACHIEVEMENTS OK" if ok else "TEST_ACHIEVEMENTS FAIL")
	quit(0 if ok else 1)
	return true
