extends SceneTree
## Test I-09: Werkstatt-Oberfläche: B öffnet/schließt, Zeilen zeigen Stufe und Preis, Kaufen-Knopf bucht Staub ab, Knöpfe sperren ohne Staub.
var frames := 0
var main

func _key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e

func _process(_d: float) -> bool:
	frames += 1
	if frames == 3:
		load("res://menu.gd").launch = {"mode": "solo", "ip": "", "name": "T"}
		main = load("res://main.tscn").instantiate()
		root.add_child(main)
	elif frames == 8:
		var ui = main.shop_ui
		var gs = root.get_node("GameState")
		var ok: bool = ui != null and not ui.is_open and ui.rows.size() == 3
		gs.dust = 0
		ui.refresh()
		ok = ok and ui.rows["wipe_size"]["button"].disabled and ("Stufe 0 von 4" in ui.rows["wipe_size"]["label"].text)
		ui._unhandled_input(_key(KEY_B))
		ok = ok and ui.is_open and ui._root.visible
		gs.add_dust(50)   # dust_changed -> refresh
		var b: Button = ui.rows["wipe_size"]["button"]
		ok = ok and not b.disabled and "Kaufen" in b.text
		var before: int = gs.dust
		b.pressed.emit()
		ok = ok and main.shop.level("wipe_size") == 1 and gs.dust < before and "Stufe 1 von 4" in ui.rows["wipe_size"]["label"].text
		ok = ok and ("Sternenstaub: %d" % gs.dust) in ui.dust_label.text
		ui._unhandled_input(_key(KEY_B))
		ok = ok and not ui.is_open
		ui.open()
		ui._unhandled_input(_key(KEY_ESCAPE))
		ok = ok and not ui.is_open
		print("TEST_SHOP_UI OK" if ok else "TEST_SHOP_UI FAIL")
		load("res://menu.gd").launch = {}
		quit(0 if ok else 1)
	return false
