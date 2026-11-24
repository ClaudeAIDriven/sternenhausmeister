extends SceneTree
## Test G-05: Kauf senkt Staub, Stufe steigt, Werte wirken; Preise wachsen; Grenzen werden eingehalten.
var done := false

func _process(_d: float) -> bool:
	if done:
		return false
	done = true
	var gs = root.get_node("GameState")
	var shop = load("res://shop.gd").new()
	root.add_child(shop)
	var ok := true
	ok = ok and shop.upgrades.size() == 3
	var base_r: float = shop.value("wipe_radius")
	var base_s: float = shop.value("speed")
	var base_reach: float = shop.value("reach")
	ok = ok and is_equal_approx(base_r, 0.9) and is_equal_approx(base_s, 6.0)
	gs.dust = 0
	ok = ok and not shop.can_buy("wipe_size") and not shop.request_buy("wipe_size")   # ohne Staub kein Kauf
	gs.dust = 100
	var c1: int = shop.cost("wipe_size")
	ok = ok and shop.request_buy("wipe_size")
	ok = ok and gs.dust == 100 - c1 and shop.level("wipe_size") == 1
	ok = ok and shop.value("wipe_radius") > base_r + 0.2          # spürbar größer
	ok = ok and shop.cost("wipe_size") > c1                        # nächste Stufe teurer
	ok = ok and shop.request_buy("speed") and shop.value("speed") > base_s
	ok = ok and shop.request_buy("reach") and shop.value("reach") > base_reach
	# bis zum Maximum kaufen, danach nicht mehr
	gs.dust = 100000
	while shop.request_buy("wipe_size"):
		pass
	ok = ok and shop.is_maxed("wipe_size") and shop.cost("wipe_size") == -1 and not shop.request_buy("wipe_size")
	ok = ok and shop.level("wipe_size") == 4
	ok = ok and not shop.request_buy("gibt_es_nicht")
	# fehlerhafte Daten werden abgelehnt
	var f := FileAccess.open("user://bad_upgrades.json", FileAccess.WRITE)
	f.store_string('{"stats":{"speed":6},"upgrades":[{"id":"a"}]}')
	f.close()
	ok = ok and shop.load_data("user://bad_upgrades.json") != ""
	gs.dust = 0
	print("TEST_SHOP OK" if ok else "TEST_SHOP FAIL")
	quit(0 if ok else 1)
	return false
