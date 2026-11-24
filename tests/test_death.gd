extends SceneTree
## Test G-20: Tod zieht 10 % Sternenstaub ab, Respawn nach 60 s, Wiederbeleben durch Mitspieler (3 s F) verkürzt.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var gs = root.get_node("GameState")
	var ok := true
	var a = load("res://player.gd").new()
	a.name = "1"
	root.add_child(a)
	var b = load("res://player.gd").new()
	b.name = "2"
	root.add_child(b)
	a.set_multiplayer_authority(1)
	b.set_multiplayer_authority(1)   # Solo/Test: beide lokal steuerbar
	a.global_position = Vector3(0, 1, 0)
	b.global_position = Vector3(1.0, 1, 0)
	# Tod
	gs.dust = 200
	var died := {"n": 0}
	a.died.connect(func(): died["n"] += 1)
	a.damage(1000.0)
	ok = ok and a.downed and died["n"] == 1 and gs.dust == 180 and a.last_dust_lost == 20
	ok = ok and is_equal_approx(a.respawn_left, 60.0)
	# Schaden am Boden wirkt nicht, kein zweiter Staubverlust
	a.damage(50.0)
	ok = ok and gs.dust == 180 and died["n"] == 1
	# Zeit läuft: nach 59 s noch unten, nach 60 s oben, volle Gesundheit an der Laterne
	for i in 59:
		a.tick_downed(1.0)
	ok = ok and a.downed and is_equal_approx(a.respawn_left, 1.0)
	a.tick_downed(1.0)
	ok = ok and not a.downed and is_equal_approx(a.health, a.MAX_HEALTH) and a.global_position.is_equal_approx(a.SPAWN_POINT)
	# Wiederbeleben: zu kurz gehalten = nichts, losgelassen = Fortschritt weg
	a._invuln = 0.0
	a.global_position = Vector3(0, 1, 0)
	a.damage(1000.0)
	ok = ok and a.downed and gs.dust == 162
	ok = ok and not b.update_revive(2.0, true) and a.downed and b.revive_progress > 0.6
	b.update_revive(0.1, false)
	ok = ok and b.revive_progress == 0.0
	b.update_revive(2.0, true)
	ok = ok and a.downed   # nicht summiert über die Unterbrechung
	# 3 s am Stück: sofort auf, halbe Gesundheit, an Ort und Stelle
	var pos: Vector3 = a.global_position
	var rv := {"n": 0, "team": false}
	a.revived.connect(func(t): rv["n"] += 1; rv["team"] = t)
	ok = ok and b.update_revive(1.0, true) and not a.downed and rv["n"] == 1 and rv["team"]
	ok = ok and is_equal_approx(a.health, a.MAX_HEALTH * 0.5) and a.global_position.is_equal_approx(pos) and a.respawn_left == 0.0
	# Zu weit weg: kein Wiederbeleben
	a._invuln = 0.0
	a.damage(1000.0)
	b.global_position = Vector3(10, 1, 0)
	ok = ok and not b.update_revive(5.0, true) and a.downed and b.revive_target == null
	# Staubverlust ohne Staub
	gs.dust = 0
	ok = ok and gs.lose_dust_fraction(0.1) == 0
	# UI-Texte
	var ui = load("res://health_ui.gd").new()
	root.add_child(ui)
	ui.bind(a)
	b.global_position = Vector3(1.0, 1, 0)
	ui._update_down_texts()
	ok = ok and ui.down_label.text.contains("Aufstehen in 60 s") and ui.revive_label.text == ""
	ui._player = b
	ui._update_down_texts()
	ok = ok and ui.revive_label.text.contains("F halten")
	gs.dust = 0
	print("TEST_DEATH OK" if ok else "TEST_DEATH FAIL")
	quit(0 if ok else 1)
	return true
