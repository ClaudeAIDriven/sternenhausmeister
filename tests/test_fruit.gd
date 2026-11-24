extends SceneTree
## Test G-22: Früchte aufheben (nur einmal), Beutel mit 6 Plätzen, Essen füllt die Sättigung, Nachwachsen nach 90 s, HUD-Text.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var w = load("res://world.gd").new()
	root.add_child(w)
	ok = ok and w.fruits.size() == 15 and w.inventory.items.is_empty()
	var pos: Vector3 = w.fruits[0].global_position
	# zu weit weg: nichts
	ok = ok and w.try_pick(pos + Vector3(10, 0, 0)) == -1
	# Aufheben
	ok = ok and w.try_pick(pos + Vector3(1, 0, 0)) == 0 and not w.fruits[0].available
	ok = ok and w.inventory.items == ["sternbeere"]
	# zweites Mal: dieselbe Frucht gibt es nicht mehr
	ok = ok and w.try_pick(pos) == -1 and w.inventory.items.size() == 1
	# Essen füllt die Leiste
	var p = load("res://player.gd").new()
	p.name = "1"
	root.add_child(p)
	p.food.value = 40.0
	ok = ok and w.eat_fruit(p) == "sternbeere" and is_equal_approx(p.food.value, 55.0) and w.inventory.items.is_empty()
	ok = ok and w.eat_fruit(p) == ""   # nichts mehr da
	# Nachwachsen
	w.fruits[0].tick(89.0)
	ok = ok and not w.fruits[0].available
	ok = ok and w.fruits[0].tick(1.5) and w.fruits[0].available
	# Beutel voll nach 6 Früchten, siebte bleibt liegen
	var count := 0
	for i in w.fruits.size():
		p.global_position = w.fruits[i].global_position
		if w.try_pick(w.fruits[i].global_position) >= 0 and not w.fruits[i].available:
			count += 1
	ok = ok and w.inventory.is_full() and w.inventory.items.size() == 6 and count == 6
	var left := 0
	for f in w.fruits:
		if f.available:
			left += 1
	ok = ok and left == w.fruits.size() - 6
	# Sorten füllen unterschiedlich
	ok = ok and Fruit.food_value("sternbeere") < Fruit.food_value("mondapfel") and Fruit.food_value("mondapfel") < Fruit.food_value("wolkenpilz")
	ok = ok and not w.inventory.add("gibt_es_nicht")
	# HUD
	var hud = load("res://hud.gd").new()
	root.add_child(hud)
	hud.bind_world(w)
	ok = ok and hud.inventory_text().contains("Beutel") and hud.inventory_text().contains("Sternbeere")
	print("TEST_FRUIT OK" if ok else "TEST_FRUIT FAIL")
	quit(0 if ok else 1)
	return true
