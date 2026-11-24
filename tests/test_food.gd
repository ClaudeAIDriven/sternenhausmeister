extends SceneTree
## Test G-21: Sättigung sinkt mit Bewegung/Springen/Putzen; satt = Regeneration x2 und Putzen +10 %; leer = keine Regeneration, Tempo -20 %, kein Tod.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var f := Food.new()
	ok = ok and is_equal_approx(f.value, 100.0) and f.is_sated()
	f.tick(10.0, false, false)
	var idle := f.value
	ok = ok and idle < 100.0 and idle > 99.0
	var g := Food.new()
	g.tick(10.0, true, false)
	var h := Food.new()
	h.tick(10.0, true, true)
	ok = ok and g.value < idle and h.value < g.value   # Laufen und Putzen kosten mehr
	var j := Food.new()
	j.on_jump()
	ok = ok and is_equal_approx(j.value, 100.0 - Food.DRAIN_JUMP)
	# Schwellen
	var s := Food.new()
	s.value = 61.0
	ok = ok and s.is_sated() and s.regen_factor() == 2.0 and s.clean_factor() == 1.1 and s.speed_factor() == 1.0
	s.value = 60.0
	ok = ok and not s.is_sated() and s.regen_factor() == 1.0 and s.clean_factor() == 1.0
	s.value = 0.0
	ok = ok and s.is_empty() and s.regen_factor() == 0.0 and is_equal_approx(s.speed_factor(), 0.8)
	s.tick(100.0, true, true)
	ok = ok and s.value == 0.0   # nie negativ
	s.feed(50.0)
	ok = ok and is_equal_approx(s.value, 50.0)
	s.feed(500.0)
	ok = ok and s.value == Food.MAX
	# Im Spieler
	var p = load("res://player.gd").new()
	p.name = "1"
	root.add_child(p)
	ok = ok and p.food != null and is_equal_approx(p.wipe_factor(), p.food.clean_factor() * Roles.factor(p.role, "wipe"))
	var base: float = Roles.factor(p.role, "wipe")
	ok = ok and is_equal_approx(p.wipe_factor(), base * 1.1)   # voll = satt
	p.health = 50.0
	p._since_damage = 100.0
	p._tick_health(1.0)
	ok = ok and is_equal_approx(p.health, 50.0 + Player.REGEN_RATE * 2.0)   # satt: x2
	p.food.value = 30.0
	p.health = 50.0
	p._tick_health(1.0)
	ok = ok and is_equal_approx(p.health, 50.0 + Player.REGEN_RATE)
	p.food.value = 0.0
	p.health = 50.0
	p._tick_health(1.0)
	ok = ok and p.health == 50.0 and is_equal_approx(p.wipe_factor(), base)   # leer: keine Regeneration, kein Putzbonus
	# Leer tötet nicht
	p.food.tick(1000.0, true, true)
	ok = ok and p.health > 0.0
	# UI
	var ui = load("res://health_ui.gd").new()
	root.add_child(ui)
	ui.bind(p)
	p.food.value = 40.0
	ui._process(0.1)
	ok = ok and is_equal_approx(ui.food_bar.value, 40.0)
	print("TEST_FOOD OK" if ok else "TEST_FOOD FAIL")
	quit(0 if ok else 1)
	return true
