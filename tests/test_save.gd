extends SceneTree
## Test G-27: Speichern, neu laden, Werte gleich (Staub, Shop, Sternzustand, XP/Fähigkeiten je Name); ungültige Datei; Pause-Knopf.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var SG = load("res://save_game.gd")
	SG.base_dir = "user://test_saves"
	var gs = root.get_node("GameState")
	gs.player_count = 1
	var w = load("res://world.gd").new()
	root.add_child(w)
	var shop = load("res://shop.gd").new()
	shop.load_data()
	var xp = load("res://xp.gd").new()
	xp.add_xp(500)
	var skills = load("res://skills.gd").new(xp)
	skills.load_data()
	# Zustand herstellen
	var star = w.stars[0]
	var ids: Array = [star.spots[0].get_meta("id"), star.spots[1].get_meta("id")]
	star.apply_removed(ids)
	gs.dust = 321
	shop.levels["u_besen"] = 1
	shop.equipped = "besen"
	var first_skill: String = str(skills.list[0]["id"])
	skills.levels[first_skill] = 1
	var data: Dictionary = SG.capture(w, gs, shop, {"Jan": {"xp": xp, "skills": skills}}, 3)
	ok = ok and SG.save("Test Slot!", data) == OK
	ok = ok and SG.list().has("Test Slot_")
	# Zustand zurücksetzen und laden
	star.reset()
	gs.dust = 0
	shop.levels = {}
	shop.equipped = "wedel"
	var xp2 = load("res://xp.gd").new()
	var sk2 = load("res://skills.gd").new(xp2)
	sk2.load_data()
	var loaded: Dictionary = SG.load_game("Test Slot!")
	ok = ok and int(loaded["night"]) == 3 and int(loaded["seed"]) == 0
	var pl: Dictionary = SG.apply(loaded, w, gs, shop)
	ok = ok and gs.dust == 321 and shop.levels.get("u_besen") == 1 and shop.equipped == "besen"
	ok = ok and star.removed_ids.size() == 2 and star.removed_ids.has(ids[0]) and star.removed_ids.has(ids[1])
	SG.restore_player(pl["Jan"], xp2, sk2)
	ok = ok and xp2.xp == xp.xp and xp2.level == xp.level and xp2.points == xp.points
	ok = ok and sk2.levels.get(first_skill) == 1 and sk2.role == skills.role
	# Defekte/fehlende Datei
	ok = ok and SG.load_game("gibts_nicht").is_empty()
	var f := FileAccess.open(SG.path_for("kaputt"), FileAccess.WRITE)
	f.store_string("{nicht json")
	f.close()
	ok = ok and SG.load_game("kaputt").is_empty()
	# Pause-Knopf
	var pause = load("res://pause.gd").new()
	var res := {"n": 0}
	pause.save_handler = func(): res["n"] += 1; return OK
	root.add_child(pause)
	ok = ok and pause.buttons["save"].visible and pause.save_now() and res["n"] == 1
	# Aufräumen
	for n in ["Test Slot!", "kaputt"]:
		DirAccess.remove_absolute(SG.path_for(n))
	print("TEST_SAVE OK" if ok else "TEST_SAVE FAIL")
	quit(0 if ok else 1)
	return true
