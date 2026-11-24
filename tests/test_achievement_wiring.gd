extends SceneTree
## Test M-14: Jeder Erfolg hat eine Quelle im Spiel (kein Erfolg, der nie freigeschaltet werden kann).
## Ereignisse kommen aus main.gd (count/set_max), "night" aus record_night, Gegner-Arten über enemy_removed -> count(kind).
const ENEMY_KINDS := ["wollmaus", "spinne", "russwolke"]

func _initialize() -> void:
	var src := FileAccess.get_file_as_string("res://main.gd")
	var A = load("res://achievements.gd")
	var ok := true
	var missing: Array = []
	for d in A.DEFS:
		var ev: String = d[2]
		var wired := ('count("%s"' % ev) in src or ('set_max("%s"' % ev) in src
		if ev == "night":
			wired = "record_night(" in src
		elif ev in ENEMY_KINDS:
			wired = "achievements.count(kind)" in src and "enemy_removed" in src
		if not wired:
			missing.append(ev)
	ok = missing.is_empty()
	print("TEST_ACHIEVEMENT_WIRING OK" if ok else "TEST_ACHIEVEMENT_WIRING FAIL ohne Quelle: %s" % [missing])
	quit(0 if ok else 1)
