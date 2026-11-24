extends SceneTree
## Test C-03: Einstellungen speichern und neu laden. Start: godot --headless -s tests/test_settings.gd

func _initialize() -> void:
	var s = root.get_node("Settings")
	s.config_path = "user://settings_test.cfg"
	s.reset_to_defaults()
	var fired := [0]
	s.changed.connect(func(_k): fired[0] += 1)
	s.set_value("volume_master", 0.5)
	s.set_value("player_name", "Tester")
	s.set_value("volume_master", 0.5)   # unverändert: kein Signal
	var ok: bool = fired[0] == 2
	s.load_settings()                     # frisch von Platte laden
	ok = ok and is_equal_approx(s.get_value("volume_master"), 0.5) and s.get_value("player_name") == "Tester"
	ok = ok and s.get_value("fov") == 70.0
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings_test.cfg"))
	print("TEST_SETTINGS OK" if ok else "TEST_SETTINGS FAIL")
	quit(0 if ok else 1)
