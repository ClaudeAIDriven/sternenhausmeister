extends SceneTree
## Test U-05: Sternchen-Berechnung, Anzeige erscheint bei night_ended, eigener Staub wird gezählt, Weiterspielen schließt.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var NS = load("res://night_summary.gd")
	var ok := true
	ok = ok and NS.rating(8, 8, true, true) == 3 and NS.rating(8, 8, false, true) == 2 and NS.rating(3, 3, false, false) == 3
	ok = ok and NS.rating(5, 8, false, true) == 2 and NS.rating(4, 8, false, true) == 1 and NS.rating(0, 8, false, true) == 1 and NS.rating(0, 0, false, false) == 1
	ok = ok and NS.stars_text(2) == "★★☆" and NS.stars_text(3) == "★★★"
	var gs = root.get_node("GameState")
	var w = load("res://world.gd").new()
	root.add_child(w)
	var s = NS.new()
	root.add_child(s)
	s.bind(w)
	gs.dust = 0
	gs.start_night()
	gs.add_dust(7)
	gs.add_dust(3)
	ok = ok and s.earned == 10
	gs.spend_dust(4)        # Ausgeben zählt nicht als Verdienst
	ok = ok and s.earned == 10
	ok = ok and not s.is_open
	gs.end_night()
	ok = ok and s.is_open and s._root.visible
	ok = ok and "★" in s.stars_label.text and "Dein Sternenstaub in dieser Nacht: 10" in s.info_label.text
	ok = ok and ("von %d" % w.stars.size()) in s.info_label.text
	s.continue_button.pressed.emit()
	ok = ok and not s.is_open and not s._root.visible
	print("TEST_NIGHT_SUMMARY ", "OK" if ok else "FAIL")
	quit(0 if ok else 1)
	return false
