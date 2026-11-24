extends SceneTree
## Test C-04: 'clean' umbelegen, speichern, neu laden. Start: godot --headless -s tests/test_input_setup.gd

func _initialize() -> void:
	var IS = load("res://input_setup.gd")
	var s = root.get_node("Settings")
	s.config_path = "user://settings_test_input.cfg"
	s.reset_to_defaults()
	IS.apply(s)
	var ok := true
	# Standard: Maus links, E und RT lösen 'clean' aus; A springt; linker Stick bewegt
	var clean_events := InputMap.action_get_events("clean")
	ok = ok and clean_events.size() == 3
	var rt := InputEventJoypadMotion.new()
	rt.axis = JOY_AXIS_TRIGGER_RIGHT
	rt.axis_value = 1.0
	ok = ok and InputMap.event_is_action(rt, "clean")
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	ok = ok and InputMap.event_is_action(a, "jump")
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_Y
	stick.axis_value = -1.0
	ok = ok and InputMap.event_is_action(stick, "move_forward")
	# Umbelegen auf F
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	ok = ok and IS.rebind("clean", f, s) == OK
	ok = ok and InputMap.event_is_action(f, "clean")
	var e_key := InputEventKey.new()
	e_key.physical_keycode = KEY_E
	ok = ok and not InputMap.event_is_action(e_key, "clean")
	ok = ok and InputMap.event_is_action(rt, "clean")   # Gamepad bleibt
	# Konflikt, Esc, unbekannte Aktion
	var w := InputEventKey.new()
	w.physical_keycode = KEY_W
	ok = ok and IS.rebind("clean", w, s) == ERR_ALREADY_EXISTS
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	ok = ok and IS.rebind("clean", esc, s) == ERR_INVALID_PARAMETER
	ok = ok and IS.rebind("gibtsnicht", f, s) == ERR_INVALID_PARAMETER
	# Persistenz: Einstellungen neu von Platte laden, InputMap leeren, neu aufbauen
	s.load_settings()
	for act in IS.ACTIONS:
		InputMap.action_erase_events(act)
	IS.apply(s)
	ok = ok and InputMap.event_is_action(f, "clean") and not InputMap.event_is_action(e_key, "clean")
	# Gamepad-Umbelegung: jump auf Y
	var y := InputEventJoypadButton.new()
	y.button_index = JOY_BUTTON_Y
	ok = ok and IS.rebind("jump", y, s) == OK and InputMap.event_is_action(y, "jump") and not InputMap.event_is_action(a, "jump")
	# Zurücksetzen
	IS.reset_action("clean", s)
	ok = ok and InputMap.event_is_action(e_key, "clean") and not InputMap.event_is_action(f, "clean")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings_test_input.cfg"))
	print("TEST_INPUT_SETUP OK" if ok else "TEST_INPUT_SETUP FAIL")
	quit(0 if ok else 1)
