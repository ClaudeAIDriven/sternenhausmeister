extends SceneTree
## Test G-25: Utensilien nacheinander kaufen (teurer), eigene Upgrades wirken nur ausgerüstet, Werkzeugart/Modell folgen dem Utensil.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var gs = root.get_node("GameState")
	var ok := true
	var shop = load("res://shop.gd").new()
	root.add_child(shop)
	ok = ok and shop.upgrades.size() == 3 and shop.utensils.size() == 6 and shop.utensil_upgrades.size() == 15
	ok = ok and shop.owns("wedel") and shop.equipped == "wedel"
	# Preise steigen von Utensil zu Utensil
	var prev := -1
	for ut in shop.utensils.slice(1):
		var c: int = shop.cost(ut["item_id"])
		ok = ok and c > prev
		prev = c
	# Nacheinander: Besen nicht vor Schwamm
	gs.dust = 100000
	ok = ok and not shop.request_buy("u_besen") and not shop.owns("besen")
	ok = ok and shop.request_buy("u_schwamm") and shop.owns("schwamm")
	# Upgrade erst mit Utensil
	ok = ok and not shop.request_buy("besen_width")
	var r0: float = shop.value("wipe_radius")
	ok = ok and is_equal_approx(r0, 0.9)   # Wedel in der Hand: Grundwert
	# Ausrüsten wirkt
	ok = ok and not shop.equip("besen") and shop.equip("schwamm")
	ok = ok and shop.value("wipe_radius") > r0 and is_equal_approx(shop.value("wipe_radius"), 0.9 + 0.2)
	# Utensil-Upgrade: wirkt nur im ausgerüsteten Zustand
	var r1: float = shop.value("wipe_radius")
	ok = ok and shop.request_buy("schwamm_width") and shop.value("wipe_radius") > r1
	ok = ok and shop.request_buy("schwamm_tempo") and shop.value("wipe_rate") > 1.0
	ok = ok and shop.request_buy("schwamm_reach") and shop.value("reach") > 9.0
	shop.equip("wedel")
	ok = ok and is_equal_approx(shop.value("wipe_radius"), 0.9) and is_equal_approx(shop.value("wipe_rate"), 1.0)
	# Maximum je Upgrade (3 Stufen)
	shop.equip("schwamm")
	while shop.request_buy("schwamm_width"):
		pass
	ok = ok and shop.level("schwamm_width") == 3 and shop.is_maxed("schwamm_width")
	# Alle Utensilien nacheinander, Sondereigenschaften
	for id in ["besen", "staubsauger", "dampfreiniger", "sternpolierer"]:
		ok = ok and shop.request_buy("u_" + id) and shop.equip(id)
	shop.equip("staubsauger")
	ok = ok and shop.has_ability("spiders") and not shop.has_ability("tough")
	shop.equip("dampfreiniger")
	ok = ok and shop.has_ability("tough")
	# Zu wenig Staub
	gs.dust = 0
	ok = ok and not shop.request_buy("sternpolierer_width")
	# Spieler: Werkzeugart und Modell folgen dem Utensil
	var p = load("res://player.gd").new()
	p.name = "1"
	root.add_child(p)
	shop.name = "Shop"
	shop.equip("wedel")
	ok = ok and p.tool_kind() == CleanTool.Kind.ANY
	shop.equip("staubsauger")
	ok = ok and p.tool_kind() == CleanTool.Kind.VACUUM
	p._refresh_tool()
	ok = ok and p.brush.get_child(p.brush.get_child_count() - 1).get_meta("kind") == "vacuum"
	shop.equip("sternpolierer")
	ok = ok and p.tool_kind() == CleanTool.Kind.POLISH and p.wipe_rate() >= 1.0
	# UI: Zeilen für alle Einträge
	var ui = load("res://shop_ui.gd").new()
	root.add_child(ui)
	ui.bind(shop)
	ok = ok and ui.rows.size() == 3 + 6 + 15
	gs.dust = 0
	print("TEST_UTENSILS OK" if ok else "TEST_UTENSILS FAIL")
	quit(0 if ok else 1)
	return true
