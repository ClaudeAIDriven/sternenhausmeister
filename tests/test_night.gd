extends SceneTree
## Test G-01: Nachtphasen und Ende. Start im ersten Frame, damit Autoloads im Baum sind.
var done := false

func _process(_d: float) -> bool:
	if done:
		return false
	done = true
	var gs = root.get_node("GameState")
	var n = load("res://night.gd").new()
	root.add_child(n)
	var phases := []
	var ended := [0]
	gs.phase_changed.connect(func(p): phases.append(p))
	gs.night_ended.connect(func(): ended[0] += 1)
	n.start(10.0)
	n.tick(1.0)    # 10 %
	var ok: bool = gs.night_state == gs.Phase.DAEMMERUNG
	n.tick(2.0)    # 30 %
	ok = ok and gs.night_state == gs.Phase.MITTERNACHT
	n.tick(5.5)    # 85 %
	ok = ok and gs.night_state == gs.Phase.MORGENROT and is_equal_approx(n.time_left(), 1.5)
	n.tick(2.0)    # über 100 %: Ende
	ok = ok and gs.night_state == gs.Phase.ENDE and ended[0] == 1 and not n.running
	n.tick(5.0)    # nach dem Ende passiert nichts mehr
	ok = ok and ended[0] == 1 and phases == [0, 1, 2, 3]
	print("TEST_NIGHT OK" if ok else "TEST_NIGHT FAIL phases=%s" % str(phases))
	quit(0 if ok else 1)
	return false
