extends SceneTree
## Test U-04: Optionen speichern/laden, Untertitel erscheinen und verschwinden, Farbenblind-Palette, UI-Skalierung.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var a = load("res://accessibility.gd").new()
	a.cfg_path = "user://a11y_test.cfg"
	root.add_child(a)
	# Standard
	ok = ok and a.captions_enabled and not a.cvd_mode and a.ui_scale == 1.0
	# Skalierung wird auf 100..200 % begrenzt
	a.set_scale_factor(3.0)
	ok = ok and a.ui_scale == 2.0
	a.set_scale_factor(0.5)
	ok = ok and a.ui_scale == 1.0
	a.set_scale_factor(1.5)
	a.set_cvd_mode(true)
	a.set_captions(true)
	# Theme skaliert die Schrift
	var th: Theme = a.make_theme()
	var big: int = th.get_default_font_size()
	a.set_scale_factor(1.0)
	var small: int = a.make_theme().get_default_font_size()
	ok = ok and big > small
	a.set_scale_factor(1.5)
	# Farbenblind-Modus: Spieler 3 heller als im Normalmodus
	ok = ok and a.player_color(2) == Palette.player_color(2, true) and a.player_color(2) != Palette.player_color(2, false)
	# Speichern und neu laden
	var b = load("res://accessibility.gd").new()
	b.cfg_path = "user://a11y_test.cfg"
	root.add_child(b)
	ok = ok and b.cvd_mode and b.ui_scale == 1.5 and b.captions_enabled
	# Untertitel: erscheinen, begrenzt auf 3, verschwinden nach Ablauf
	b.announce("star_cleaned", 1.0)
	b.announce("constellation", 1.0)
	b.announce("wrong", 1.0)
	b.announce("scrub", 1.0)
	b.announce("gibtsnicht")
	ok = ok and b.caption_texts().size() == 3 and not b.caption_texts().has(Accessibility.SOUNDS["star_cleaned"])
	b.tick(0.5)
	ok = ok and b.caption_texts().size() == 3
	b.tick(0.6)
	ok = ok and b.caption_texts().is_empty()
	# Aus: keine Untertitel
	b.set_captions(false)
	b.announce("scrub")
	ok = ok and b.caption_texts().is_empty()
	# Panel baut sich mit drei Bedienelementen
	var p: Control = b.build_panel()
	root.add_child(p)
	ok = ok and p.find_children("*", "CheckBox", true, false).size() == 2 and p.find_children("*", "HSlider", true, false).size() == 1
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://a11y_test.cfg"))
	print("TEST_ACCESSIBILITY OK" if ok else "TEST_ACCESSIBILITY FAIL")
	quit(0 if ok else 1)
	return true
