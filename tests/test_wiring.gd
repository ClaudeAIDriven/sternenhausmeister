extends SceneTree
## Test M-01: Verdrahtung im echten Spielaufbau (main.gd): XP beim Putzen, Fähigkeit wirkt, Küchen-Buff und Schrein wirken,
## Utensil-Werkzeugart erreicht die Welt (Spinne nur mit Sauger), Wetter/Küche/Fähigkeiten-UI hängen im Spiel.
var frames := 0
var main

func _process(_d: float) -> bool:
	frames += 1
	if frames == 2:
		var menu = load("res://menu.gd")
		menu.launch = {"mode": "solo", "name": "Tester", "preset": "standard"}
		main = load("res://main.gd").new()
		root.add_child(main)
		return false
	if frames < 6:
		return false
	var ok := true
	var p = main.player
	ok = ok and p != null and main.weather != null and main.kitchen_ui != null and main.skills_ui != null
	if p == null:
		print("TEST_WIRING FAIL (kein Spieler)")
		quit(1)
		return true
	ok = ok and p.kitchen == main.world.kitchen and p.skills != null
	# XP beim Putzen
	var star = main.world.stars[0]
	var xp0: int = p.xp.xp
	main._on_star_scrubbed(star, 5)
	ok = ok and p.xp.xp == xp0 + 5
	# Fähigkeit wirkt (z. B. Wischradius) -> mod ändert sich
	p.xp.add_xp(2000)
	p.role = "putzer"
	var base_wipe: float = p.wipe_factor()
	var learned := false
	for sk in p.skills.list:
		if sk["effect"]["stat"] == "wipe" and p.skills.available(sk["id"]) and p.skills.learn(sk["id"]):
			learned = true
			break
	ok = ok and learned and p.wipe_factor() > base_wipe
	# Küchen-Buff
	var w0: float = p.wipe_factor()
	main.world.kitchen.buffs["wipe"] = {"mult": 1.15, "left": 100.0, "label": "x"}
	ok = ok and is_equal_approx(p.wipe_factor(), w0 * 1.15)
	main.world.kitchen.buffs.clear()
	# Schrein
	var Poi_ = load("res://poi.gd")
	Poi_.shrine_left = 30.0
	ok = ok and is_equal_approx(p.wipe_factor(), w0 * 1.25)
	Poi_.reset_state()
	# Utensil: Staubsauger entfernt die Spinne, Wedel nicht
	var spider = null
	for e in main.world.enemies:
		if e.kind == "spinne":
			spider = e
	ok = ok and spider != null
	main.shop.levels["u_staubsauger"] = 1
	main.shop.levels["u_besen"] = 1
	main.shop.levels["u_schwamm"] = 1
	var got_equipped: bool = main.shop.equip("staubsauger")
	ok = ok and got_equipped and p.tool_kind() == CleanTool.Kind.VACUUM
	main.world._wipe_authoritative(spider.global_position, 1.0, CleanTool.Kind.CLOTH, 1)
	ok = ok and spider.alive
	main._on_wipe_requested(spider.global_position)
	main._on_wipe_requested(spider.global_position)
	ok = ok and not spider.alive and p.xp.xp > xp0 + 5
	# Doppelsprung: Fähigkeit "double_jump" gelernt -> Luftsprünge
	p.skills.levels["springer_doppel"] = 1
	p.role = "springer"
	p.mod("x")   # gleicht die Rolle in den Fähigkeiten ab
	ok = ok and int(p.skills.add("double_jump")) == 1
	# Beutel-Fähigkeit
	print("TEST_WIRING OK" if ok else "TEST_WIRING FAIL")
	quit(0 if ok else 1)
	return true
