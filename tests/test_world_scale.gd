extends SceneTree
## Test G-08: Sternzahl und Ereignisdichte hängen von der Spielerzahl ab; Fortschritt geht beim Umskalieren nicht verloren.
var done := false

func _process(_d: float) -> bool:
	if done:
		return false
	done = true
	var gs = root.get_node("GameState")
	var ok := true
	var W = load("res://world.gd")
	ok = ok and W.star_count_for(1) == 3 and W.star_count_for(2) == 4 and W.star_count_for(4) == 6
	ok = ok and W.star_count_for(0) == 3 and W.star_count_for(99) == W.STAR_POSITIONS.size()
	ok = ok and W.event_density_for(1) == 1.0 and W.event_density_for(4) > W.event_density_for(2) and W.event_density_for(99) <= 2.5
	gs.player_count = 1
	var w = W.new()
	root.add_child(w)
	ok = ok and w.stars.size() == 3
	gs.player_count = 4
	ok = ok and w.stars.size() == 6 and w.event_density() > 1.5
	gs.player_count = 2
	ok = ok and w.stars.size() == 4
	# nach dem ersten Wisch keine Neuskalierung mehr
	w.wipe_at(w.stars[0].global_position, 3.0)
	ok = ok and w.cleaned_count() == 1
	gs.player_count = 4
	ok = ok and w.stars.size() == 4 and w.cleaned_count() == 1
	# alle Sternpositionen verschieden
	var seen := {}
	for p in W.STAR_POSITIONS:
		seen[p] = true
	ok = ok and seen.size() == W.STAR_POSITIONS.size()
	gs.player_count = 1
	print("TEST_WORLD_SCALE OK" if ok else "TEST_WORLD_SCALE FAIL")
	quit(0 if ok else 1)
	return false
