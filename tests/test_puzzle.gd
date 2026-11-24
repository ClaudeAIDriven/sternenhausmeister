extends SceneTree
## Test I-04: Sternbild-Rätsel im Spiel (offline): richtige Reihenfolge löst und zahlt Bonus, falsche setzt zurück.
var frames := 0

func _clean(w, i: int) -> void:
	w.wipe_at(w.stars[i].global_position, 3.0)

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var gs = root.get_node("GameState")
	gs.player_count = 1
	gs.dust = 0
	var w = load("res://world.gd").new()
	root.add_child(w)
	var ok: bool = w.stars.size() == 3 and w.puzzle != null and w.puzzle.id == "dreieck" and w.lines != null
	var ev := {"wrong": 0, "solved": 0, "hint": -1}
	w.puzzle_wrong.connect(func(h): ev["wrong"] += 1; ev["hint"] = h)
	w.puzzle_solved.connect(func(b): ev["solved"] = b)
	# Falsche Reihenfolge: 0 (richtig), dann 2 (falsch)
	_clean(w, 0)
	ok = ok and w.stars[0].is_clean and w.puzzle.done == 1
	_clean(w, 2)
	ok = ok and ev["wrong"] == 1 and ev["hint"] == 0   # nach dem Zurücksetzen beginnt das Sternbild wieder bei Stern 0
	ok = ok and not w.stars[0].is_clean and not w.stars[2].is_clean and w.stars[0].spots.size() == w.stars[0].total and w.stars[0].progress == 0.0
	ok = ok and w.puzzle.done == 0 and ev["solved"] == 0 and gs.dust == 0   # noch kein Bonus (Putzstaub bucht main.gd)
	# Richtige Reihenfolge löst und zahlt Bonus
	for i in [0, 1, 2]:
		_clean(w, i)
	ok = ok and w.puzzle.is_solved and ev["solved"] == w.puzzle.bonus() and w.cleaned_count() == 3
	ok = ok and gs.dust == w.puzzle.bonus()
	# Mehr Sterne -> größeres Sternbild
	gs.player_count = 3   # solange nichts geputzt: nicht möglich (alles geputzt), also neues World
	var w2 = load("res://world.gd").new()
	root.add_child(w2)
	ok = ok and w2.stars.size() == 5 and w2.puzzle.id == "kassiopeia"
	gs.player_count = 1
	gs.dust = 0
	print("TEST_PUZZLE OK" if ok else "TEST_PUZZLE FAIL")
	quit(0 if ok else 1)
	return false
