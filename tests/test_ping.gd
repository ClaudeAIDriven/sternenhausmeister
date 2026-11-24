extends SceneTree
## Test G-33: Ping erscheint auf der Minimap, hält 8 s, ersetzt den alten desselben Spielers, Abklingzeit; Randpfeil-Berechnung.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var holder := Node3D.new()
	root.add_child(holder)
	var a = load("res://player.gd").new()
	a.name = "1"
	holder.add_child(a)
	var b = load("res://player.gd").new()
	b.name = "2"
	holder.add_child(b)
	var mm = load("res://minimap.gd").new()
	root.add_child(mm)
	mm.players_root = holder
	mm.local_player = a
	mm._connect_players()
	# Ping von a
	ok = ok and a.send_ping(Vector3(5, 0, 3))
	ok = ok and mm.pings.size() == 1 and mm.pings[0]["pos"] == Vector3(5, 0, 3) and is_equal_approx(mm.pings[0]["left"], 8.0)
	# Abklingzeit
	ok = ok and not a.send_ping(Vector3(1, 0, 1)) and mm.pings.size() == 1
	# anderer Spieler: zweiter Ping; neuer Ping von a ersetzt den alten
	ok = ok and b.send_ping(Vector3(-4, 0, 2)) and mm.pings.size() == 2
	a._ping_cd = 0.0
	ok = ok and a.send_ping(Vector3(2, 0, 2)) and mm.pings.size() == 2
	# Ablauf nach 8 s
	mm.tick_pings(7.5)
	ok = ok and mm.pings.size() == 2
	mm.tick_pings(1.0)
	ok = ok and mm.pings.is_empty()
	# Ungültige Werte
	a._ping_cd = 0.0
	ok = ok and not a.send_ping(Vector3(INF, 0, 0))
	a.rpc_ping(Vector3(9999, 0, 0))   # zu weit weg: ignoriert
	ok = ok and mm.pings.is_empty()
	# Randpfeil: Punkt rechts außerhalb landet am rechten Rand, hinter dem Rand mit Abstand
	var size := Vector2(1000, 600)
	var e: Vector2 = mm.get_script().edge_point(Vector2(3000, 300), size, 36.0)
	ok = ok and is_equal_approx(e.x, 964.0) and is_equal_approx(e.y, 300.0)
	var e2: Vector2 = mm.get_script().edge_point(Vector2(500, -2000), size, 36.0)
	ok = ok and is_equal_approx(e2.y, 36.0) and is_equal_approx(e2.x, 500.0)
	var e3: Vector2 = mm.get_script().edge_point(size * 0.5, size)
	ok = ok and e3 == size * 0.5
	print("TEST_PING OK" if ok else "TEST_PING FAIL")
	quit(0 if ok else 1)
	return true
