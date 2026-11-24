extends SceneTree
## Test G-32: Friedlich (Standard): Schubsen stößt nur weg, kein Schaden. Rauflust: Schaden wie bisher. Menü-Schalter und Preset-Regel.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	# Preset-Regel: Standardwert false, gültig/ungültig
	var rules: Dictionary = Presets.effective("standard")
	ok = ok and rules.get("brawl") == false
	ok = ok and Presets.effective("standard", {"brawl": true}).get("brawl") == true
	ok = ok and Presets.effective("standard", {"brawl": "ja"}).get("brawl") == false   # ungültig wird ignoriert
	ok = ok and Presets.check_rules({"time_limit_s": 600, "weather": "off", "hints": "none", "brawl": 1}) != ""
	# Menü
	var menu = load("res://menu.gd").new()
	root.add_child(menu)
	await process_frame
	ok = ok and menu.brawl_check != null and not menu.brawl_check.button_pressed
	# Spieler: Standard friedlich
	var a = load("res://player.gd").new()
	a.name = "1"
	root.add_child(a)
	var b = load("res://player.gd").new()
	b.name = "2"
	root.add_child(b)
	a.set_multiplayer_authority(1)
	b.set_multiplayer_authority(1)
	a.global_position = Vector3(0, 0, 0)
	b.global_position = Vector3(0, 0, -1.0)   # Blick -Z: b liegt vor a
	ok = ok and not a.brawl and not b.room_brawl()
	ok = ok and a.try_attack()
	ok = ok and b.health == 100.0 and (b._impulse.length() > 0.0 or b.velocity.y > 0.0)   # weggestoßen, kein Schaden
	# Rauflust: der Wert des Hosts ("1") zählt, nicht der des Opfers
	a.brawl = true
	a._attack_cd = 0.0
	b._invuln = 0.0
	ok = ok and b.room_brawl() and a.try_attack() and b.health < 100.0
	# Opfer mit eigenem brawl=true, Host friedlich: kein Schaden
	a.brawl = false
	b.brawl = true
	a._attack_cd = 0.0
	var hp: float = b.health
	ok = ok and not b.room_brawl() and a.try_attack() and is_equal_approx(b.health, hp)
	print("TEST_PEACE OK" if ok else "TEST_PEACE FAIL")
	quit(0 if ok else 1)
	return true
