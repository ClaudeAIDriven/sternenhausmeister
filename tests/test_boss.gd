extends SceneTree
## Test G-29: Rußwolke nimmt nur Schaden bei 2 gleichzeitigen Wischern; solo nur bei gefallenem Schild; Belohnung; Respawn.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var gs = root.get_node("GameState")
	gs.player_count = 1
	var w = load("res://world.gd").new()
	root.add_child(w)
	var c = w.enemies[w.enemies.size() - 1]
	ok = ok and c.kind == "russwolke" and c.alive and is_equal_approx(c.hp, 100.0)
	var pt: Vector3 = c.global_position
	# Solo bei Schild: kein Schaden
	c.act(0.1, w)
	ok = ok and not c.shield_down()
	w._wipe_authoritative(pt, 1.0, 0, 5)
	ok = ok and is_equal_approx(c.hp, 100.0)
	# Zweiter Spieler gleichzeitig: Schaden
	c.act(1.0, w)
	w._wipe_authoritative(pt, 1.0, 0, 5)
	w._wipe_authoritative(pt, 1.0, 0, 6)
	ok = ok and is_equal_approx(c.hp, 90.0)
	# Zu spät (außerhalb Fenster): nur Spieler 6, 5 ist alt -> kein Schaden
	c.act(2.0, w)
	w._wipe_authoritative(pt, 1.0, 0, 6)
	ok = ok and is_equal_approx(c.hp, 90.0)
	# Schild in Welle gefallen: Solo trifft
	c.shield_timer = SootCloud.SHIELD_PERIOD - SootCloud.SHIELD_DOWN + 0.1
	ok = ok and c.shield_down()
	c._recent.clear()
	w._wipe_authoritative(pt, 1.0, 0, 5)
	ok = ok and is_equal_approx(c.hp, 80.0)
	# Besiegen: Staub + Signal, danach weg
	var got := {"kind": ""}
	w.enemy_removed.connect(func(k, _who): got["kind"] = k)
	var dust0: int = gs.dust
	for i in 8:
		w._wipe_authoritative(pt, 1.0, 0, 5)
	ok = ok and not c.alive and got["kind"] == "russwolke" and gs.dust == dust0 + 200
	# Respawn nach 150 s mit vollen HP
	c.sim(149.0, w)
	ok = ok and not c.alive
	c.sim(2.0, w)
	ok = ok and c.alive and is_equal_approx(c.hp, 100.0)
	print("TEST_BOSS OK" if ok else "TEST_BOSS FAIL")
	quit(0 if ok else 1)
	return true
