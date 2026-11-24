extends SceneTree
## Test I-02: Spieler nutzt PlayerLook und ToolModels; Tempo/Reichweite folgen dem Shop, Maus-Empfindlichkeit/FOV den Einstellungen.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var st = root.get_node("Settings")
	var gs = root.get_node("GameState")
	st.reset_to_defaults()
	var p = load("res://player.gd").new()
	p.name = "1"
	root.add_child(p)
	ok = ok and p.look != null and p.look.has_meta("symbol") and p.look.get_parent() == p
	ok = ok and p.brush.get_child_count() == 1 and p.brush.get_child(0).get_meta("kind") == "duster"
	ok = ok and is_equal_approx(p.cam.fov, 70.0)
	# ohne Shop: Standardwerte
	ok = ok and is_equal_approx(p.stat("speed", p.SPEED), p.SPEED)
	# mit Shop: Werte wachsen
	var shop = load("res://shop.gd").new()
	root.add_child(shop)
	ok = ok and is_equal_approx(p.stat("speed", p.SPEED), 6.0)
	gs.dust = 1000
	shop.request_buy("speed")
	shop.request_buy("reach")
	ok = ok and p.stat("speed", p.SPEED) > 6.5 and p.stat("reach", p.REACH) > 9.5
	# anderer Platz = anderes Aussehen
	var p2 = load("res://player.gd").new()
	p2.name = "7"
	root.add_child(p2)
	var net = root.get_node("NetworkManager")
	net.players = {1: {"name": "A"}, 7: {"name": "B"}}
	p2._refresh_look()
	p._refresh_look()
	ok = ok and p.look_index == 0 and p2.look_index == 1 and p.look.get_meta("symbol") != p2.look.get_meta("symbol")
	net.players = {}
	st.reset_to_defaults()
	gs.dust = 0
	print("TEST_PLAYER_INTEGRATION OK" if ok else "TEST_PLAYER_INTEGRATION FAIL")
	quit(0 if ok else 1)
	return false
