extends SceneTree
## Test G-07: Event startet, warnt, endet planmäßig; Zen (kosmetisch) löst keinen Strike aus. Start: godot --headless -s tests/test_weather.gd

func _run(cosmetic: bool) -> Dictionary:
	var W = load("res://weather.gd")
	var w = W.new()
	w.cosmetic = cosmetic
	w.gap_min = 10.0
	w.gap_max = 10.0
	w.warn_time = 3.0
	w.seed_rng(7)
	root.add_child(w)
	w.set_star_positions([Vector3(0, 5, -7), Vector3(-9, 6, 1), Vector3(8, 5.5, 3)])
	var log := {"warn": 0, "start": 0, "end": 0, "strike": 0, "kinds": []}
	w.warning.connect(func(k, _t, _s): log.warn += 1)
	w.event_started.connect(func(k): log.start += 1; log.kinds.append(k))
	w.event_ended.connect(func(_k): log.end += 1)
	w.meteor_strike.connect(func(_i): log.strike += 1)
	w.start()
	w.running = true
	log["state_before_gap"] = w.state
	for i in 3000:   # 300 s in 0,1-s-Schritten
		w.tick(0.1)
	log["children_idle_ok"] = true
	w.stop()
	log["state_after_stop"] = w.state
	var alive := 0
	for c in w.get_children():
		if not c.is_queued_for_deletion():
			alive += 1
	log["children_after_stop"] = alive
	w.queue_free()
	return log


func _initialize() -> void:
	var a := _run(false)
	var b := _run(true)
	var ok: bool = a.start >= 3 and a.end == a.start and a.warn >= a.start
	ok = ok and a.state_before_gap == 0 and a.state_after_stop == 0
	ok = ok and a.children_after_stop == 0
	var meteors: int = a.kinds.count(1)
	ok = ok and meteors > 0 and a.strike == meteors   # Nicht-Zen: jeder Meteor trifft genau einmal
	ok = ok and b.kinds.count(1) > 0 and b.strike == 0   # Zen: gleiche Events, keine Folgen
	print("WEATHER a=", a, " b=", b)
	print("TEST_WEATHER OK" if ok else "TEST_WEATHER FAIL")
	quit(0 if ok else 1)
