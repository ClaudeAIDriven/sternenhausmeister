extends SceneTree
## Test M-10: Durchlauf je Karte (Solo): Spiel starten, Spieler da, alle Sterne putzen, Sternbild/Staub, Gegner entfernen, Boss im Team,
## Speichern und Laden, Nachtende ohne Fehler. Kein Ersatz für Menschentests.
var frames := 0
var maps: Array = []
var idx := -1
var main
var phase := 0
var failed := false

func _spawn() -> void:
	var menu = load("res://menu.gd")
	menu.launch = {"mode": "solo", "name": "Tester", "preset": "standard", "map": maps[idx], "seed": "" if idx == 0 else str(1000 + idx)}
	main = load("res://main.gd").new()
	root.add_child(main)

func _process(_d: float) -> bool:
	frames += 1
	if frames == 2:
		load("res://save_game.gd").base_dir = "user://test_play"
		maps = load("res://maps.gd").ids()
		idx = 0
		_spawn()
		return false
	if main == null or main.player == null:
		return false
	var gs = root.get_node("GameState")
	var ok := true
	var w = main.world
	ok = ok and w.map_id == maps[idx] and w.stars.size() >= 3 and w.enemies.size() > 0
	if idx > 0:
		ok = ok and w.island_seed == 1000 + idx
	# alle Sterne putzen
	for s in w.stars:
		var guard := 0
		while not s.is_clean and guard < 5000:
			w._wipe_authoritative(s.to_global(s.spots[0].position), 1.0, 0, 1)
			guard += 1
		ok = ok and s.is_clean
	ok = ok and w.cleaned_count() == w.stars.size() and gs.dust > 0
	# Gegner: Wollmaus (jedes Werkzeug) und Spinne (nur Sauger)
	var bunny
	var spider
	for e in w.enemies:
		if e.kind == "wollmaus" and bunny == null:
			bunny = e
		if e.kind == "spinne" and spider == null:
			spider = e
	w._wipe_enemies(bunny.global_position, 1.0, 2, 1)
	ok = ok and not bunny.alive
	w._wipe_enemies(spider.global_position, 1.0, 2, 1)
	ok = ok and spider.alive
	w._wipe_enemies(spider.global_position, 1.0, CleanTool.Kind.VACUUM, 1)
	ok = ok and not spider.alive
	# Boss nur im Team
	var cloud = w.enemies[w.enemies.size() - 1]
	var hp0: float = cloud.hp
	w._wipe_enemies(cloud.global_position, 1.0, 0, 1)
	ok = ok and cloud.hp == hp0
	w._wipe_enemies(cloud.global_position, 1.0, 0, 2)
	ok = ok and cloud.hp < hp0 or cloud.hp == hp0 - 10.0
	# Speichern, Nachtende (Autosave), Karte im Spielstand
	ok = ok and main.save_now("durchlauf") == OK
	var data: Dictionary = load("res://save_game.gd").load_game("durchlauf")
	ok = ok and data.get("map") == maps[idx] and data["stars"].size() == w.stars.size()
	gs.night_ended.emit()
	ok = ok and main.nights_played == 1
	DirAccess.remove_absolute(load("res://save_game.gd").path_for("durchlauf"))
	DirAccess.remove_absolute(load("res://save_game.gd").path_for("autosave"))
	print("PLAYTHROUGH ", maps[idx], " ", "OK" if ok else "FAIL")
	if not ok:
		failed = true
	main.free()
	main = null
	idx += 1
	if idx >= maps.size():
		print("TEST_PLAYTHROUGH OK" if not failed else "TEST_PLAYTHROUGH FAIL")
		quit(1 if failed else 0)
		return true
	gs.dust = 0
	gs.stars_cleaned = 0
	_spawn()
	return false
