extends SceneTree
## Test I-08: Menü bietet Spielarten, wählt eine in Menu.launch; Spiel wendet Zeitlimit/Hinweise an; Pause enthält das Barrierefreiheit-Panel.
var frames := 0
var main

func _process(_d: float) -> bool:
	frames += 1
	if frames == 3:
		var M = load("res://menu.gd")
		var menu = M.new()
		menu.auto_start = false
		root.add_child(menu)
		var opt: OptionButton = menu.preset_option
		var names := []
		for i in opt.item_count:
			names.append(opt.get_item_text(i))
		var ok: bool = opt != null and opt.item_count >= 3 and "Zen" in names and opt.get_item_metadata(0) == "standard"
		for i in opt.item_count:
			if opt.get_item_metadata(i) == "zen":
				opt.select(i)
		menu.start("solo")
		ok = ok and M.launch.get("preset") == "zen"
		if not ok:
			print("TEST_PRESETS_WIRED FAIL menu ", names, M.launch)
			quit(1)
		menu.queue_free()
		main = load("res://main.tscn").instantiate()
		root.add_child(main)
	elif frames == 8:
		var ok: bool = absf(main.night.duration - 1800.0) < 0.1 and main.world.hint_mode == "always"
		ok = ok and main.accessibility != null and main.pause.accessibility == main.accessibility
		ok = ok and main.pause.find_child("AccessibilityPanel", true, false) != null
		print("TEST_PRESETS_WIRED OK" if ok else "TEST_PRESETS_WIRED FAIL dauer=%s hints=%s" % [main.night.duration, main.world.hint_mode])
		load("res://menu.gd").launch = {}
		quit(0 if ok else 1)
	return false
