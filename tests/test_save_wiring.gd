extends SceneTree
## Test M-02: Spiel starten, putzen, speichern (Pause-Knopf/Autosave), neu starten mit launch["load"] -> gleicher Zustand inkl. Seed.
var frames := 0
var main
var phase := 0
var star_removed := 0

func _spawn(load_slot: String) -> void:
	var menu = load("res://menu.gd")
	menu.launch = {"mode": "solo", "name": "Tester", "preset": "standard", "load": load_slot}
	main = load("res://main.gd").new()
	root.add_child(main)

func _process(_d: float) -> bool:
	frames += 1
	if frames == 2:
		load("res://save_game.gd").base_dir = "user://test_saves2"
		_spawn("")
		return false
	if phase == 0 and frames == 8:
		var ok := true
		ok = ok and main.pause.buttons["save"].visible
		ok = ok and main.world.set_island_seed(777)
		var star = main.world.stars[0]
		star.apply_removed([star.spots[0].get_meta("id"), star.spots[1].get_meta("id"), star.spots[2].get_meta("id")])
		star_removed = star.removed_ids.size()
		root.get_node("GameState").dust = 250
		main.player.xp.add_xp(300)
		main.shop.levels["u_besen"] = 1
		ok = ok and main.pause.save_now() and load("res://save_game.gd").list().has("Spielstand")
		root.get_node("GameState").night_ended.emit()
		ok = ok and main.nights_played == 1 and load("res://save_game.gd").list().has("autosave")
		main.pause.open()
		ok = ok and main.pause.seed_label.text == "Insel-Seed: 777"
		if not ok:
			print("TEST_SAVE_WIRING FAIL (phase 0)")
			quit(1)
			return true
		var lvl: int = main.player.xp.level
		main.pause.close()
		main.free()
		root.get_node("GameState").dust = 0
		phase = 1
		frames = 100
		set_meta("lvl", lvl)
		_spawn("autosave")
		return false
	if phase == 1 and frames >= 108 and main.player != null or phase == 1 and frames > 400:
		var ok := true
		ok = ok and main.world.island_seed == 777
		ok = ok and main.world.stars[0].removed_ids.size() == star_removed
		ok = ok and root.get_node("GameState").dust == 250
		ok = ok and main.shop.levels.get("u_besen") == 1
		ok = ok and main.nights_played == 1
		ok = ok and main.player.xp.level == int(get_meta("lvl"))
		for n in ["Spielstand", "autosave"]:
			DirAccess.remove_absolute(load("res://save_game.gd").path_for(n))
		print("TEST_SAVE_WIRING OK" if ok else "TEST_SAVE_WIRING FAIL (phase 1)")
		quit(0 if ok else 1)
		return true
	return false
