extends SceneTree
## Test I-01: Menü-Start ohne Optionen, Menu.launch wird ausgewertet, Pause und Shop hängen im Spiel.
var frames := 0
var main

func _process(_d: float) -> bool:
	frames += 1
	if frames == 3:
		var M = load("res://main.gd")
		var ok: bool = M.wants_menu(PackedStringArray([]), {}) and not M.wants_menu(PackedStringArray(["--selftest"]), {}) \
			and not M.wants_menu(PackedStringArray(["--host"]), {}) and not M.wants_menu(PackedStringArray([]), {"mode": "solo"}) \
			and not M.wants_menu(PackedStringArray(["--nomenu"]), {})
		if not ok:
			print("TEST_MAIN_FLOW FAIL wants_menu")
			quit(1)
		var Mn = load("res://menu.gd")
		Mn.launch = {"mode": "solo", "ip": "", "name": "Test"}
		main = load("res://main.tscn").instantiate()
		root.add_child(main)
	elif frames == 8:
		var ok: bool = main.pause != null and main.shop != null and main.world != null and main.spawner.player_count() == 1
		ok = ok and main.shop.value("wipe_radius") == 0.9
		main.shop.levels["wipe_size"] = 2
		ok = ok and main.shop.value("wipe_radius") > 1.3
		print("TEST_MAIN_FLOW OK" if ok else "TEST_MAIN_FLOW FAIL")
		load("res://menu.gd").launch = {}
		quit(0 if ok else 1)
	return false
