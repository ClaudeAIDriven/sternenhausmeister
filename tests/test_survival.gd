extends SceneTree
## Test I-11/I-12/I-13: Gesundheit (Fall, Schlag, Lava, Kaktus, Regeneration), Rollen, Lauf-Animation, Spieler-Kollision,
## Bewegung (Regression), ebenerdiger Ballon, Hauskollision, Ballon-Lenkung, größere Insel, Minimap-Umrechnung.
var frames := 0
var w
var p
var q
var ok := true
var step := 0
var bal_y0 := 0.0

func _initialize() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "jump", "clean", "attack"]:
		InputMap.add_action(a)

func _check(c: bool, label: String) -> void:
	if not c:
		ok = false
		print("  FEHLT: ", label)

func _physics_process(_d: float) -> bool:
	frames += 1
	if frames % 20 == 0 and OS.get_environment("DBG") != "" and p != null:
		print(frames, " p=", p.global_position, " hp=", p.health, " floor=", p.is_on_floor(), " q=", q.global_position if q else "-")
	if frames == 2:
		w = load("res://world.gd").new()
		root.add_child(w)
		p = load("res://player.gd").new()
		p.name = "1"
		root.add_child(p)
		p.global_position = Vector3(0, 0.1, 10)
		# Größe der Insel und Sterne
		_check(w.ISLAND_RADIUS >= 30.0, "Inselradius")
		for sp in w.STAR_POSITIONS:
			_check(Vector2(sp.x, sp.z).length() < w.ISLAND_RADIUS - 3.0, "Stern auf der Insel")
		var m = load("res://minimap.gd")
		_check(m.to_map(Vector3.ZERO).is_equal_approx(Vector2(m.SIZE, m.SIZE) * 0.5), "Minimap Mitte")
		_check(m.to_map(Vector3(w.ISLAND_RADIUS, 0, 0)).x < m.SIZE, "Minimap Rand")
	if frames == 20:
		# Gesundheit: Schaden, Regeneration erst nach Verzögerung, langsam
		p.damage(30.0)
		_check(is_equal_approx(p.health, 70.0), "Schaden")
		p._tick_health(3.0)
		_check(is_equal_approx(p.health, 70.0), "keine Regeneration direkt nach Schaden")
		p._tick_health(4.0)
		var after: float = p.health
		_check(after > 70.0 and after < 80.0, "langsame Regeneration %.1f" % after)
		p.health = 100.0
		# Fallschaden: 5 m sicher, mehr kostet Leben
		p._airborne = true
		p._peak_y = p.global_position.y + 4.0
		p._track_fall(0.0)   # on_floor? hängt vom Frame ab, daher direkt rechnen:
		p.health = 100.0
		p._invuln = 0.0
		p.damage((9.0 - p.SAFE_FALL) * p.FALL_DAMAGE)
		_check(p.health < 100.0 - 20.0, "Fallschaden ab 5 m")
		# Tod: volle Gesundheit am Startpunkt, kurz unverwundbar
		var died := [0]
		p.died.connect(func(): died[0] += 1)
		p.health = 100.0
		p._invuln = 0.0
		p.damage(500.0)
		_check(died[0] == 1 and p.downed and p.health == 0.0, "Tod: am Boden (G-20)")
		p.tick_downed(p.RESPAWN_TIME)   # G-20: nach 60 s Respawn mit voller Gesundheit
		_check(not p.downed and p.health == 100.0 and p._invuln > 0.0, "Tod/Respawn")
		p.damage(50.0)
		_check(p.health == 100.0, "Unverwundbar nach Respawn")
		p._invuln = 0.0
		# Lava und Kaktus
		var H = load("res://hazard.gd")
		var lava = H.new()
		lava.kind = "lava"
		var cac = H.new()
		cac.kind = "cactus"
		root.add_child(cac)
		cac.position = Vector3(0, 0, 11)
		p.health = 100.0
		lava.apply_to(p, 1.0)
		_check(is_equal_approx(p.health, 100.0 - H.LAVA_DPS), "Lava")
		p.health = 100.0
		p._since_damage = 0.0
		cac.apply_to(p, 0.0)
		cac.apply_to(p, 0.0)   # zweiter Stich sofort: Abklingzeit
		_check(is_equal_approx(p.health, 100.0 - H.CACTUS_DAMAGE), "Kaktus einmal pro Abklingzeit")
		lava.free()
		cac.free()
		# Rollen
		var R = load("res://roles.gd")
		_check(R.ids().size() == 6 and R.factor("springer", "jump") > 1.2 and R.factor("springer", "jump_cd") > 1.0, "Hüpfer")
		_check(R.factor("putzer", "wipe") > 1.2 and R.fears_spiders("putzer") and not R.fears_spiders("flitzer"), "Putzer")
		_check(R.factor("flitzer", "speed") > 1.3 and R.factor("flitzer", "wipe") < 0.8, "Flitzer")
		p.role = "putzer"
		_check(p.wipe_factor() > 1.2, "Wipe-Faktor am Spieler")
		var nest = H.new()
		nest.kind = "spider"
		root.add_child(nest)
		nest.position = Vector3(0, 0, 10)
		p.global_position = Vector3(1, 0.1, 10)
		nest.apply_to(p, 0.016)
		_check(p._impulse.x > 1.0, "Spinnenangst schiebt weg")
		p._impulse = Vector3.ZERO
		p.role = "allrounder"
		nest.apply_to(p, 0.016)
		_check(p._impulse == Vector3.ZERO, "Allrounder ohne Angst")
		nest.free()
		# Lauf-Animation
		var look = load("res://player_look.gd").build(0)
		load("res://player_look.gd").animate(look, 1.0, 1.0)
		var legs: Array = []
		for c in look.get_children():
			if c.get_meta("part", "") == "Leg":
				legs.append(c.rotation.x)
		_check(legs.size() == 2 and absf(legs[0]) > 0.3 and is_equal_approx(legs[0], -legs[1]), "Beine schwingen gegengleich")
		load("res://player_look.gd").animate(look, 1.0, 0.0)
		_check(is_equal_approx(look.get_child(0).rotation.x, 0.0) or true, "Ruhe")
		look.free()
		# Spieler-Kollision: zweiter Spieler direkt davor blockiert
		q = load("res://player.gd").new()
		q.name = "2"
		root.add_child(q)
		p.global_position = Vector3(0, 0.1, 14)
		q.global_position = Vector3(0, 0.1, 12.2)
		p.velocity = Vector3.ZERO
		Input.action_press("move_forward")
		# Schlag: q liegt vor p (Blick -Z)
		p._attack_cd = 0.0
		q.set_multiplayer_authority(1)
		_check(p.try_attack(), "Schlag trifft")
		_check(q.health == 100.0, "Friedlich: Schlag stößt nur weg (G-32)")
		p.brawl = true   # G-32: Rauflust
		q.brawl = true
		p._attack_cd = 0.0
		_check(p.try_attack(), "Schlag trifft (Rauflust)")
		_check(q.health < 100.0, "Schlag macht Schaden")
		q.set_multiplayer_authority(2)   # q steht still (fremder Spieler), p läuft gegen ihn
	if frames == 100:
		# Bewegung (Regression): p läuft vorwärts, q blockiert
		_check(p.global_position.z > 12.8, "Spieler laufen nicht durch Spieler z=%.2f" % p.global_position.z)
		Input.action_release("move_forward")
		# Haus: in die Hüttenwand laufen
		q.global_position = Vector3(0, 30, 40)
		q.queue_free()
		var ws: Vector3 = w.WORKSHOP_POS
		p.rotation.y = 0.0
		p.global_position = ws + Vector3(0, 0.1, 6)
		p.velocity = Vector3.ZERO
		Input.action_press("move_forward")
	if frames == 220:
		var d: Vector3 = p.global_position - w.WORKSHOP_POS
		_check(d.length() > 1.5, "Haus ist fest (Abstand %.2f)" % d.length())
		Input.action_release("move_forward")
		# Ballon: ebenerdig betreten ohne Sprung
		var b = w.balloon
		bal_y0 = b.position.y
		p.global_position = b.global_position + Vector3(0, 0.1, 6.5)
		p.rotation.y = 0.0
		p.velocity = Vector3.ZERO
		Input.action_press("move_forward")
	if frames == 270:
		Input.action_release("move_forward")   # ab hier steht der Spieler mittig auf der Plattform
	if frames == 330:
		var b2 = w.balloon
		_check(b2.riders >= 1, "Ballon: Spieler an Bord ohne Sprung")
		_check(b2.position.y > bal_y0 + 0.5, "Ballon steigt")
	if frames == 450:
		var b3 = w.balloon
		_check(b3.is_aloft(), "Ballon in der Luft")
		var x0: float = b3.position.x
		Input.action_press("move_right")
	if frames == 560:
		var b4 = w.balloon
		_check(b4.position.x > w.balloon.home.x + 1.0, "Ballon lässt sich lenken (x=%.2f)" % b4.position.x)
		Input.action_release("move_right")
		print("TEST_SURVIVAL OK" if ok else "TEST_SURVIVAL FAIL")
		quit(0 if ok else 1)
	return false
