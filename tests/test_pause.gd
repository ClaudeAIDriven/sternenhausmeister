extends SceneTree
## Test U-03: Esc öffnet/schließt die Pause, Regler ändern Einstellungen sofort (Lautstärke, FOV), Solo pausiert das Spiel.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var st = root.get_node("Settings")
	st.reset_to_defaults()
	var p = load("res://pause.gd").new()
	root.add_child(p)
	ok = ok and not p.is_open
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	p._unhandled_input(esc)
	ok = ok and p.is_open and paused
	# Regler wirken sofort
	p.sliders["volume_master"].value = 0.5
	ok = ok and is_equal_approx(float(st.get_value("volume_master")), 0.5)
	ok = ok and absf(AudioServer.get_bus_volume_db(0) - linear_to_db(0.5)) < 0.01
	p.sliders["mouse_sens"].value = 0.005
	ok = ok and is_equal_approx(float(st.get_value("mouse_sens")), 0.005)
	# FOV wirkt auf die Kamera des eigenen Spielers
	var pl = load("res://player.gd").new()
	pl.name = "1"
	root.add_child(pl)
	p.sliders["fov"].value = 90.0
	ok = ok and is_equal_approx(pl.cam.fov, 90.0) and is_equal_approx(float(st.get_value("fov")), 90.0)
	# gespeichert: Neuladen von Platte
	st.load_settings()
	ok = ok and is_equal_approx(float(st.get_value("fov")), 90.0)
	p._unhandled_input(esc)
	ok = ok and not p.is_open and not paused
	p.open()
	p.buttons["resume"].pressed.emit()
	ok = ok and not p.is_open and not paused
	st.reset_to_defaults()
	AudioServer.set_bus_volume_db(0, 0.0)
	print("TEST_PAUSE OK" if ok else "TEST_PAUSE FAIL")
	quit(0 if ok else 1)
	return false
