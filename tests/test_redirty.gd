extends SceneTree
## Test G-15: Sternschnuppe bringt wenige Flecken auf einen geputzten Stern zurück; Zen = nichts; Sternbild zählt nicht doppelt.
var frames := 0

func _clean(w, i: int) -> void:
	w.wipe_at(w.stars[i].global_position, 3.0)

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var gs = root.get_node("GameState")
	gs.player_count = 1
	var w = load("res://world.gd").new()
	root.add_child(w)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ok := true
	# Nichts Sauberes: kein Effekt
	ok = ok and w.meteor_strike(0, rng) == 0
	# Ersten Stern des Sternbilds putzen, dann Treffer
	var first: int = w.puzzle.order[0]
	_clean(w, first)
	var s = w.stars[first]
	ok = ok and s.is_clean and w.puzzle.done == 1
	var seen := {"n": 0}
	w.star_redirtied.connect(func(_s, n): seen["n"] = n)
	var n: int = w.meteor_strike(first, rng)
	ok = ok and n >= 3 and n <= 6 and seen["n"] == n
	ok = ok and not s.is_clean and s.spots.size() == n and s.progress < 1.0 and s.progress > 0.9
	ok = ok and s.removed_ids.size() == s.total - n
	# Wieder putzen: wird sauber, Sternbild zählt ihn nicht doppelt (kein "wrong", done bleibt 1)
	var wrong := {"n": 0}
	w.puzzle_wrong.connect(func(_h): wrong["n"] += 1)
	_clean(w, first)
	ok = ok and s.is_clean and w.puzzle.done == 1 and wrong["n"] == 0
	# Ziel nicht sauber: trifft einen anderen geputzten Stern (hier nur `first` sauber)
	var other: int = w.puzzle.order[1]
	ok = ok and w.meteor_strike(other, rng) > 0 and not s.is_clean and w.stars[other].spots.size() == w.stars[other].total
	_clean(w, first)
	# Zen: nichts passiert
	w.zen = true
	ok = ok and w.meteor_strike(first, rng) == 0 and s.is_clean
	# Weather-Anbindung: cosmetic = Zen; Signal löst Treffer aus
	var wx = load("res://weather.gd").new()
	wx.cosmetic = false
	w.attach_weather(wx)
	ok = ok and w.zen == false
	wx.meteor_strike.emit(first)
	ok = ok and not s.is_clean
	_clean(w, first)
	var wz = load("res://weather.gd").new()
	wz.cosmetic = true
	w.attach_weather(wz)
	ok = ok and w.zen
	wz.meteor_strike.emit(first)
	ok = ok and s.is_clean
	# Gelöstes Sternbild bleibt gelöst
	w.zen = false
	for i in w.puzzle.order:
		if not w.stars[i].is_clean:
			_clean(w, i)
	ok = ok and w.puzzle.is_solved and w.meteor_strike(first, rng) == 0 and s.is_clean
	# apply_restored (Client-Weg): unbekannte/vorhandene IDs ignorieren
	var w2 = load("res://world.gd").new()
	root.add_child(w2)
	_clean(w2, 0)
	var st = w2.stars[0]
	ok = ok and st.apply_restored([9999, -1]) == 0 and st.is_clean
	ok = ok and st.apply_restored([st.removed_ids[0], st.removed_ids[0]]) == 1 and st.spots.size() == 1
	print("TEST_REDIRTY OK" if ok else "TEST_REDIRTY FAIL")
	quit(0 if ok else 1)
	return true
