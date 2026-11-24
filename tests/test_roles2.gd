extends SceneTree
## Test G-24: Rollen Koch und Kletterer (Faktoren), Leiter (8 s, alle können klettern), Wandklettern nur für Kletterer, Hunger-Faktor.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	ok = ok and Roles.ids().size() == 6 and Roles.ids().has("koch") and Roles.ids().has("kletterer")
	# Faktoren
	ok = ok and is_equal_approx(Roles.factor("koch", "recipe_food"), 1.5) and is_equal_approx(Roles.factor("koch", "buff_time"), 1.5)
	ok = ok and absf(Roles.factor("koch", "hunger") * 1.5 - 1.0) < 0.01 and Roles.factor("kletterer", "hunger") == 1.5
	ok = ok and Roles.can("kletterer", "climb") and Roles.can("kletterer", "ladder") and not Roles.can("koch", "ladder") and not Roles.can("allrounder", "climb")
	ok = ok and Roles.factor("allrounder", "hunger") == 1.0   # Standard
	# Hunger: Kletterer verbraucht mehr, Koch weniger (gleiche Zeit)
	var fk = load("res://food.gd").new()
	var fc = load("res://food.gd").new()
	var fa = load("res://food.gd").new()
	fk.tick(60.0 * Roles.factor("koch", "hunger"), true, true)
	fc.tick(60.0 * Roles.factor("kletterer", "hunger"), true, true)
	fa.tick(60.0, true, true)
	ok = ok and fk.value > fa.value and fa.value > fc.value
	# Leiter
	var l = load("res://ladder.gd").new()
	l.position = Vector3(5, 0, 5)
	root.add_child(l)
	ok = ok and l.is_in_group("ladders") and l.can_climb(Vector3(5.3, 2.0, 5.0)) and not l.can_climb(Vector3(8, 2.0, 5.0)) and not l.can_climb(Vector3(5, 9.0, 5))
	ok = ok and l.get_script().find_for(self, Vector3(5, 1, 5)) == l
	l.tick(7.0)
	ok = ok and l.can_climb(Vector3(5, 1, 5))
	l.tick(1.5)
	ok = ok and not l.can_climb(Vector3(5, 1, 5))   # abgelaufen
	# Spieler: Kletterer stellt Leiter auf (Abklingzeit), Allrounder nicht
	var k = load("res://player.gd").new()
	k.name = "1"
	root.add_child(k)
	k.role = "kletterer"   # nach _ready (das liest die Rolle aus den Einstellungen)
	var a = load("res://player.gd").new()
	a.name = "2"
	root.add_child(a)
	ok = ok and not a.place_ladder()
	var before := get_nodes_in_group("ladders").size()
	ok = ok and k.place_ladder() and get_nodes_in_group("ladders").size() == before + 1
	ok = ok and not k.place_ladder()   # Abklingzeit
	# Alle können an der Leiter hoch: Allrounder neben der neuen Leiter
	var nl: Node3D
	for n in get_nodes_in_group("ladders"):
		if n != l and not n.is_queued_for_deletion():
			nl = n
	ok = ok and nl != null
	a.global_position = nl.global_position + Vector3(0, 0.5, 0)
	a.velocity = Vector3.ZERO
	a._apply_climb(Vector2(0, -1))
	ok = ok and is_equal_approx(a.velocity.y, Ladder.CLIMB_SPEED)
	# Ohne Vorwärtsdruck: keine Kletterbewegung
	a.velocity = Vector3.ZERO
	a._apply_climb(Vector2(0, 0))
	ok = ok and a.velocity.y == 0.0
	# Wandklettern nur mit Rolle (hier ohne Wand: is_on_wall false, also nur Rollencheck der Fähigkeit)
	ok = ok and Roles.can(k.role, "climb") and not Roles.can(a.role, "climb")
	print("TEST_ROLES2 OK" if ok else "TEST_ROLES2 FAIL")
	quit(0 if ok else 1)
	return true
