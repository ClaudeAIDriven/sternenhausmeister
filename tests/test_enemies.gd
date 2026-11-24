extends SceneTree
## Test G-28: Wollmaus (verschmutzt neu, mit jedem Werkzeug wegputzbar), Spinne (beißt 8, nur mit Staubsauger), Respawn, Zen.
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
	var bunnies := []
	var spiders := []
	for e in w.enemies:
		(bunnies if e.kind == "wollmaus" else spiders).append(e)
	ok = ok and bunnies.size() == w.stars.size() and spiders.size() >= 1 and w.enemies[0].id == 0
	var b = bunnies[0]
	var star = b.star
	# Wollmaus verschmutzt geputzte Flecken neu (nur wo etwas geputzt ist)
	b.dir = Vector3.DOWN   # weit weg vom Wischpunkt oben
	b._update_pos()
	b.act(10.0, w)
	ok = ok and star.removed_ids.is_empty()
	w.wipe_at(star.global_position + Vector3(0, star.radius, 0), 1.2)
	var cleaned_before: int = star.removed_ids.size()
	ok = ok and cleaned_before > 0
	b._dirty_left = 0.01
	b.act(0.1, w)
	ok = ok and star.removed_ids.size() == cleaned_before - 1
	# Zen: nichts
	w.zen = true
	b._dirty_left = 0.01
	b.act(0.1, w)
	ok = ok and star.removed_ids.size() == cleaned_before - 1
	w.zen = false
	# Wollmaus wegputzen: mit jedem Werkzeug (hier Tuch = CLOTH = 2)
	var removed := {"n": 0, "kind": ""}
	w.enemy_removed.connect(func(k, _who): removed["n"] += 1; removed["kind"] = k)
	var near: Vector3 = b.global_position
	ok = ok and b.alive and b.is_in_group("enemies")
	w.wipe_at(near, 1.0, CleanTool.Kind.CLOTH)
	ok = ok and not b.alive and removed["n"] == 1 and removed["kind"] == "wollmaus" and not b.is_in_group("enemies")
	# Respawn nach 45 s
	b.sim(44.0, w)
	ok = ok and not b.alive
	b.sim(1.5, w)
	ok = ok and b.alive and b.is_in_group("enemies")
	# Spinne: Tuch/Wedel prallen ab, Staubsauger entfernt
	var sp = spiders[0]
	var sp_pos: Vector3 = sp.global_position
	w.wipe_at(sp_pos, 1.0, CleanTool.Kind.CLOTH)
	w.wipe_at(sp_pos, 1.0, CleanTool.Kind.ANY)
	ok = ok and sp.alive
	w.wipe_at(sp_pos, 1.0, CleanTool.Kind.VACUUM)
	ok = ok and not sp.alive and removed["kind"] == "spinne"
	sp.sim(46.0, w)
	ok = ok and sp.alive
	# Spinne beißt: Spieler daneben bekommt 8 Schaden, dann Abklingzeit
	var pl = load("res://player.gd").new()
	pl.name = "1"
	root.add_child(pl)
	pl.global_position = sp.global_position + Vector3(0, -1.0, 0)
	pl.health = 100.0
	pl._invuln = 0.0
	sp.act(0.1, w)
	ok = ok and is_equal_approx(pl.health, 92.0)
	sp.act(0.1, w)
	ok = ok and is_equal_approx(pl.health, 92.0)   # noch Abklingzeit
	pl._invuln = 0.0
	sp.act(2.1, w)
	ok = ok and is_equal_approx(pl.health, 84.0)
	# Weit weg: kein Biss
	pl.global_position = sp.global_position + Vector3(20, 0, 0)
	pl._invuln = 0.0
	sp.act(2.5, w)
	sp.act(0.1, w)
	ok = ok and is_equal_approx(pl.health, 84.0)
	# Zen: kein Biss
	pl.global_position = sp.global_position
	w.zen = true
	sp._bite_cd = 0.0
	sp.act(0.1, w)
	ok = ok and is_equal_approx(pl.health, 84.0)
	# Wollmaus bewegt sich auf der Kugel und bleibt auf Abstand
	w.zen = false
	var d0: Vector3 = b.dir
	for i in 20:
		b.sim(0.5, w)
	ok = ok and not b.dir.is_equal_approx(d0) and is_equal_approx(b.dir.length(), 1.0)
	ok = ok and is_equal_approx(b.position.length(), b.star.radius * b.SURFACE)
	print("TEST_ENEMIES OK" if ok else "TEST_ENEMIES FAIL")
	quit(0 if ok else 1)
	return true
