extends SceneTree
## Test G-13: Co-op-Bonus nur bei >= 2 Beteiligten (je genug Flecken, rechtzeitig), einmal pro Stern, Alleinputzen gibt nichts.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var W = load("res://world.gd")
	var ok := true
	# reine Logik
	ok = ok and W.coop_recipients({}, 10.0) == []
	ok = ok and W.coop_recipients({1: [10, 5.0]}, 10.0) == []                       # allein
	ok = ok and W.coop_recipients({1: [10, 5.0], 2: [3, 5.0]}, 10.0) == []           # zweiter hat zu wenig getan
	ok = ok and W.coop_recipients({1: [10, 5.0], 2: [4, 5.0]}, 10.0) == [1, 2]
	ok = ok and W.coop_recipients({1: [10, 5.0], 2: [9, 5.0]}, 200.0) == []          # zu lange her
	# in der Welt
	var gs = root.get_node("GameState")
	gs.dust = 0
	var w = W.new()
	root.add_child(w)
	var got := []
	w.coop_bonus.connect(func(a): got.append(a))
	# Stern 0 allein geputzt: kein Bonus
	var s = w.stars[0]
	var guard := 0
	while not s.is_clean and guard < 5000:
		w.wipe_at(s.to_global(s.spots[0].position), 0.9)
		guard += 1
	ok = ok and s.is_clean and got.is_empty() and w._contrib.get(0, {}).is_empty()
	# Stern 1: Peer 7 hat vorher mitgeholfen (simuliert), Peer 1 putzt den Rest: beide bekommen Bonus (hier lokal = Peer 1)
	var s1 = w.stars[1]
	var now := Time.get_ticks_msec() / 1000.0
	w.note_contribution(1, 7, 20, now)
	var before: int = gs.dust
	guard = 0
	while not s1.is_clean and guard < 5000:
		w.wipe_at(s1.to_global(s1.spots[0].position), 0.9)
		guard += 1
	ok = ok and s1.is_clean and got == [W.COOP_BONUS]
	ok = ok and gs.dust >= before + W.COOP_BONUS
	ok = ok and w._contrib.get(1, {}).is_empty()    # nur einmal pro Stern
	print("TEST_COOP_BONUS ", "OK" if ok else "FAIL got=%s" % str(got))
	quit(0 if ok else 1)
	return false
