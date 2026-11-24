extends SceneTree
## Test G-21: Sättigung sinkt durch Laufen, Springen, Putzen (nicht im Stillstand); satt = Heilung x2 und Putzen +10 %,
## leer = keine Heilung, Tempo -20 %, aber nie Schaden.
var frames := 0
var ok := true

func _check(c: bool, what: String) -> void:
	if not c:
		ok = false
		print("FEHLER: ", what)

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var f := Food.new()
	_check(is_equal_approx(f.value, Food.MAX) and f.is_fed(), "Start voll und satt")
	f.tick(10.0, 0.0, false)
	_check(is_equal_approx(f.value, Food.MAX), "Stillstand kostet nichts")
	f.tick(10.0, 1.0, false)
	_check(is_equal_approx(f.value, Food.MAX - 1.2), "Laufen kostet")
	var before := f.value
	f.tick(10.0, 0.0, true)
	_check(is_equal_approx(f.value, before - 1.0), "Putzen kostet")
	before = f.value
	f.jumped()
	_check(is_equal_approx(f.value, before - Food.JUMP_COST), "Springen kostet")
	_check(f.regen_factor() == 2.0 and is_equal_approx(f.wipe_factor(), 1.1) and f.speed_factor() == 1.0, "Satt-Boni")
	f.value = 40.0
	_check(not f.is_fed() and f.regen_factor() == 1.0 and f.wipe_factor() == 1.0 and f.speed_factor() == 1.0, "Mittel ohne Boni")
	f.tick(10000.0, 1.0, true)
	_check(f.value == 0.0 and f.is_empty(), "nicht unter 0")
	_check(f.regen_factor() == 0.0 and is_equal_approx(f.speed_factor(), 0.8), "Leer-Mali")
	f.eat(70.0)
	_check(f.is_fed(), "Essen füllt")
	f.eat(500.0)
	_check(f.value == Food.MAX, "nicht über Max")
	# Am Spieler: Heilung, Wischfaktor, kein Schaden durch Hunger
	var p = load("res://player.gd").new()
	p.name = "1"
	root.add_child(p)
	p.set_multiplayer_authority(1)
	var base_wipe: float = Roles.factor(p.role, "wipe")
	_check(is_equal_approx(p.wipe_factor(), base_wipe * 1.1), "Spieler satt putzt +10 %")
	p.health = 50.0
	p._since_damage = 100.0
	p._tick_health(1.0)
	_check(is_equal_approx(p.health, 50.0 + 2.0 * p.REGEN_RATE), "satte Heilung x2")
	p.food.value = 0.0
	p._tick_health(5.0)
	_check(is_equal_approx(p.health, 52.0), "leer keine Heilung")
	for i in 100:
		p._tick_health(10.0)
	_check(p.health > 0.0 and not p.downed, "Hunger tötet nicht")
	_check(is_equal_approx(p.wipe_factor(), base_wipe), "leer ohne Putz-Bonus")
	# Anzeige
	var ui = load("res://health_ui.gd").new()
	root.add_child(ui)
	ui.bind(p)
	ui._process(0.016)
	_check(is_equal_approx(ui.food_bar.value, 0.0) and ui.food_label.text.begins_with("Hungrig"), "Anzeige leer")
	p.food.value = 90.0
	ui._process(0.016)
	_check(ui.food_label.text.begins_with("Satt"), "Anzeige satt")
	print("TEST_FOOD OK" if ok else "TEST_FOOD FAIL")
	quit(0 if ok else 1)
	return true
