extends SceneTree
## Test U-02: HUD zeigt Staub, Phase und Zeit. Start im ersten Frame (Autoloads im Baum).
var done := false

func _process(_d: float) -> bool:
	if done:
		return false
	done = true
	var gs = root.get_node("GameState")
	var night = load("res://night.gd").new()
	root.add_child(night)
	var hud = load("res://hud.gd").new()
	root.add_child(hud)
	night.start(125.0)
	hud.bind_night(night)
	hud.show_status(1, 3)
	gs.add_dust(7)
	var t: String = hud.text()
	var ok: bool = t.contains("Staub: 7") and t.contains("Sterne geputzt: 1 / 3") and t.contains("02:05") and t.contains("Dämmerung")
	night.tick(40.0)   # 32 %: Mitternacht
	hud.refresh()
	ok = ok and hud.text().contains("Mitternacht") and hud.text().contains("01:25")
	# I-05: Sternbild-Fortschritt und Meldungen
	hud.show_puzzle("Dreieck", 2, 3)
	ok = ok and hud.text().contains("Sternbild Dreieck: 2 / 3")
	hud.show_puzzle_message("Falsche Reihenfolge!", 1.0)
	ok = ok and hud.text().contains("Falsche Reihenfolge!")
	hud._process(1.5)
	ok = ok and not hud.text().contains("Falsche Reihenfolge!") and hud.text().contains("Esc: Pause")
	print("TEST_HUD OK" if ok else "TEST_HUD FAIL\n" + hud.text())
	quit(0 if ok else 1)
	return false
