extends SceneTree
## Test U-01: Menü startet Solo, Host, Join (Eingabe wird geprüft); Name wird gespeichert.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var m = load("res://menu.tscn").instantiate()
	m.auto_start = false
	root.add_child(m)
	var got := []
	m.start_requested.connect(func(mode, ip, n): got.append([mode, ip, n]))
	for k in ["solo", "host", "join", "settings", "quit"]:
		ok = ok and m.buttons.has(k) and m.buttons[k] is Button
	m.name_edit.text = "Mia"
	m.buttons["solo"].pressed.emit()
	ok = ok and got.size() == 1 and got[0] == ["solo", "", "Mia"]
	ok = ok and root.get_node("Settings").get_value("player_name") == "Mia"
	m.buttons["host"].pressed.emit()
	ok = ok and got.size() == 2 and got[1][0] == "host" and m.launch["mode"] == "host"
	m.ip_edit.text = ""
	m.buttons["join"].pressed.emit()
	ok = ok and got.size() == 2 and m.status.text.contains("Adresse")   # leere IP wird abgelehnt
	m.ip_edit.text = "bad ip!"
	m.buttons["join"].pressed.emit()
	ok = ok and got.size() == 2
	m.ip_edit.text = "192.168.0.12"
	m.buttons["join"].pressed.emit()
	ok = ok and got.size() == 3 and got[2] == ["join", "192.168.0.12", "Mia"] and m.launch["ip"] == "192.168.0.12"
	ok = ok and m.valid_address("host.example.org") and not m.valid_address("") and not m.valid_address("a b")
	# Einstellungen umschalten
	m.buttons["settings"].pressed.emit()
	ok = ok and m.settings_box.visible and not m.main_box.visible
	m.settings_box.get_node("Slider_volume_master").value = 0.5
	ok = ok and is_equal_approx(float(root.get_node("Settings").get_value("volume_master")), 0.5)
	root.get_node("Settings").reset_to_defaults()
	print("TEST_MENU OK" if ok else "TEST_MENU FAIL")
	quit(0 if ok else 1)
	return false
