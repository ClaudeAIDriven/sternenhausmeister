extends SceneTree
## Test G-24: Rollenfaktoren Koch/Kletterer, Food-Leiste, Kochen mit Rollenbonus, Leiter (8 s, für alle nutzbar), Kletterer-Spieler.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	ok = ok and Roles.ids().has("koch") and Roles.ids().has("kletterer")
	ok = ok and Roles.factor("koch", "food_max") == 1.5 and Roles.factor("koch", "recipe_food") == 1.5 and Roles.factor("koch", "buff_time") == 1.5
	ok = ok and Roles.factor("kletterer", "food_drain") == 1.5 and Roles.can_climb("kletterer") and Roles.can_ladder("kletterer")
	ok = ok and not Roles.can_climb("koch") and not Roles.can_ladder("allrounder") and Roles.factor("allrounder", "food_max") == 1.0
	# Food: Koch
	var f := Food.new()
	f.apply_role("koch")
	ok = ok and is_equal_approx(f.capacity, 150.0) and is_equal_approx(f.value, 150.0)
	f.feed(100.0)
	ok = ok and f.value == 150.0
	# Food: Kletterer verbraucht 50 % mehr
	var a := Food.new()
	var k2 := Food.new()
	k2.apply_role("kletterer")
	a.tick(10.0, true, false)
	k2.tick(10.0, true, false)
	ok = ok and is_equal_approx(Food.MAX - k2.value, (Food.MAX - a.value) * 1.5)
	# Kochen mit Rolle
	var k = load("res://kitchen.gd").new()
	root.add_child(k)
	var inv := Inventory.new()
	var fd := Food.new()
	fd.value = 20.0
	inv.add("mondapfel")
	inv.add("mondapfel")
	ok = ok and k.cook("mondapfel_kompott", inv, fd, "koch")
	ok = ok and is_equal_approx(fd.value, 20.0 + 40.0 * 1.5)
	k.tick(120.0)
	ok = ok and k.buff_mult("wipe") > 1.0           # Basis 120 s, Koch 180 s
	k.tick(61.0)
	ok = ok and k.buff_mult("wipe") == 1.0
	# Leiter
	var l := Ladder.new()
	root.add_child(l)
	l.global_position = Vector3(10, 0, 10)
	ok = ok and l.can_use(Vector3(10.5, 1.0, 10.0)) and not l.can_use(Vector3(14, 1.0, 10)) and not l.can_use(Vector3(10, 9.0, 10))
	ok = ok and Ladder.find_usable(self, Vector3(10, 2, 10)) == l
	ok = ok and l.tick(7.0) and l.can_use(Vector3(10, 1, 10))
	ok = ok and not l.tick(1.5) and not l.can_use(Vector3(10, 1, 10))
	# Player: Kletterer stellt Leiter auf, Allrounder nicht
	var pl = load("res://player.gd").new()
	root.add_child(pl)
	pl.role = "allrounder"
	ok = ok and pl.place_ladder() == null
	pl.role = "kletterer"
	var lad = pl.place_ladder()
	ok = ok and lad != null and lad.is_in_group("ladders") and pl.place_ladder() == null   # Abklingzeit
	print("TEST_ROLES2 " + ("OK" if ok else "FAIL"))
	quit(0 if ok else 1)
	return true
