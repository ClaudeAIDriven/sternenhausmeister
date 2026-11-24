extends SceneTree
## Test G-23: Rezepte laden/prüfen, Kochen verbraucht Zutaten, füllt die Sättigung, gibt Buff mit Ablauf; Nähe; Rezeptbuch-Oberfläche.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var k = load("res://kitchen.gd").new()
	root.add_child(k)
	ok = ok and k.recipes.size() == 4 and k.position.is_equal_approx(Kitchen.KITCHEN_POS)
	var inv := Inventory.new()
	var food := Food.new()
	food.value = 20.0
	# ohne Zutaten
	ok = ok and not k.can_cook("mondapfel_kompott", inv) and not k.cook("mondapfel_kompott", inv, food) and food.value == 20.0
	inv.add("mondapfel")
	ok = ok and not k.can_cook("mondapfel_kompott", inv)   # braucht 2
	inv.add("mondapfel")
	inv.add("sternbeere")
	ok = ok and k.can_cook("mondapfel_kompott", inv)
	ok = ok and k.buff_mult("wipe") == 1.0
	ok = ok and k.cook("mondapfel_kompott", inv, food)
	ok = ok and inv.items == ["sternbeere"]                       # zwei Äpfel weg, Beere bleibt
	ok = ok and is_equal_approx(food.value, 60.0)                  # +40
	ok = ok and is_equal_approx(k.buff_mult("wipe"), 1.15) and k.buff_mult("speed") == 1.0
	# Buff läuft ab
	k.tick(119.0)
	ok = ok and k.buff_mult("wipe") > 1.0
	k.tick(2.0)
	ok = ok and k.buff_mult("wipe") == 1.0 and k.buffs.is_empty()
	# Gemischtes Rezept, Sprung-Buff
	inv.add("wolkenpilz")
	ok = ok and k.cook("pilzpfanne", inv, food) and inv.items.is_empty() and is_equal_approx(k.buff_mult("jump"), 1.2)
	# Stärkerer Buff ersetzt, schwächerer nicht
	for kind in ["sternbeere", "sternbeere", "mondapfel", "wolkenpilz"]:
		inv.add(kind)
	ok = ok and k.cook("sternenmus", inv, food) and is_equal_approx(k.buff_mult("wipe"), 1.25)
	for kind in ["mondapfel", "mondapfel"]:
		inv.add(kind)
	ok = ok and k.cook("mondapfel_kompott", inv, food) and is_equal_approx(k.buff_mult("wipe"), 1.25)   # 1,15 < 1,25: bleibt
	# Sättigung nie über Maximum
	ok = ok and food.value <= Food.MAX
	# Nähe
	ok = ok and k.is_near(Kitchen.KITCHEN_POS + Vector3(3, 0, 0)) and not k.is_near(Kitchen.KITCHEN_POS + Vector3(9, 0, 0))
	# Fehlerhafte Daten werden abgelehnt
	var f := FileAccess.open("user://bad_recipes.json", FileAccess.WRITE)
	f.store_string('{"recipes":[{"id":"x","name":"X","ingredients":{"gibt_es_nicht":1},"food":5,"buff":{"stat":"wipe","mult":1.1,"seconds":10}}]}')
	f.close()
	ok = ok and k.load_data("user://bad_recipes.json") != ""
	k.load_data()
	ok = ok and k.recipes.size() == 4
	# Oberfläche
	var p = load("res://player.gd").new()
	p.name = "1"
	root.add_child(p)
	p.global_position = Kitchen.KITCHEN_POS + Vector3(2, 0, 0)
	var inv2 := Inventory.new()
	var ui = load("res://kitchen_ui.gd").new()
	root.add_child(ui)
	ui.bind(k, inv2, p)
	ok = ok and ui.rows.size() == 4 and ui.rows["pilzpfanne"]["button"].disabled and ui.is_near()
	inv2.add("wolkenpilz")
	inv2.add("sternbeere")
	ok = ok and not ui.rows["pilzpfanne"]["button"].disabled
	p.food.value = 10.0
	ok = ok and ui.cook("pilzpfanne") and is_equal_approx(p.food.value, 60.0) and inv2.items.is_empty() and ui.rows["pilzpfanne"]["button"].disabled
	ok = ok and ui.buff_label.text.contains("Sprung")
	print("TEST_KITCHEN OK" if ok else "TEST_KITCHEN FAIL")
	quit(0 if ok else 1)
	return true
