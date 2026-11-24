class_name Pause
extends CanvasLayer
## Pause- und Einstellungsmenü (U-03): Esc öffnet/schließt. Regler für Lautstärke, Maus-Empfindlichkeit, Sichtfeld, UI-Größe;
## Einstellungen wirken sofort (soweit möglich, siehe unten) und werden über Settings gespeichert. Außerdem Tastenübersicht,
## "Weiter", "Zum Hauptmenü" und "Beenden". Nutzung: `add_child(Pause.new())` in der Spielszene.
## Solo: Esc hält das Spiel an. Online läuft das Spiel für die anderen weiter (kein Pausieren im Netz).
## Wirkung: Gesamtlautstärke -> Master-Bus; Musik/Effekte -> Busse "Music"/"SFX", falls vorhanden; Sichtfeld -> Kamera des eigenen Spielers.
## 🟡 Maus-Empfindlichkeit wird gespeichert, wirkt aber erst, wenn player.gd `Settings.get_value("mouse_sens")` statt der Konstante nutzt.

signal opened
signal closed

const KEYS := [["Bewegen", "W A S D"], ["Springen", "Leertaste"], ["Putzen", "Linke Maustaste oder E"], ["Pause", "Esc"]]
const MENU_SCENE := "res://menu.tscn"

## G-27: Callable ohne Argumente, speichert den Spielstand und gibt OK (0) oder einen Fehlercode zurück; nur der Host/Solo setzt sie.
var save_handler: Callable
var save_label: Label
var seed_label: Label
var accessibility: Node   # I-08: optional, bringt das Barrierefreiheit-Panel mit
var is_open := false
var buttons := {}
var sliders := {}
var _root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	_build_ui()
	_apply_scale()
	apply_all()
	Settings.changed.connect(func(k: String): _apply(k))


func _apply_scale() -> void:
	_root.theme = UiTheme.build(float(Settings.get_value("ui_scale")))


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.06, 0.14, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var title := Label.new()
	title.text = "Pause"
	title.add_theme_font_size_override("font_size", UiTheme.FONT_MENU)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_slider(col, "Gesamtlautstärke", "volume_master", 0.0, 1.0, 0.05)
	_slider(col, "Musik", "volume_music", 0.0, 1.0, 0.05)
	_slider(col, "Effekte", "volume_sfx", 0.0, 1.0, 0.05)
	_slider(col, "Maus-Empfindlichkeit", "mouse_sens", 0.001, 0.008, 0.0005)
	_slider(col, "Sichtfeld", "fov", 60.0, 100.0, 1.0)
	_slider(col, "UI-Größe", "ui_scale", 0.8, 1.5, 0.05, true)
	if accessibility != null and accessibility.has_method("build_panel"):
		col.add_child(accessibility.build_panel())
	var keys := Label.new()
	keys.text = "Tasten:  " + "   ·   ".join(KEYS.map(func(k): return "%s: %s" % [k[0], k[1]]))
	keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keys.add_theme_font_size_override("font_size", UiTheme.FONT_HINT)
	col.add_child(keys)
	buttons["save"] = _button(col, "Spiel speichern", func(): save_now())
	buttons["save"].visible = save_handler.is_valid()
	seed_label = Label.new()   # M-02: Insel-Seed zum Weitergeben
	seed_label.add_theme_font_size_override("font_size", UiTheme.FONT_HINT)
	col.add_child(seed_label)
	save_label = Label.new()
	save_label.add_theme_font_size_override("font_size", UiTheme.FONT_HINT)
	col.add_child(save_label)
	buttons["resume"] = _button(col, "Weiter", func(): close())
	buttons["menu"] = _button(col, "Zum Hauptmenü", func(): to_menu())
	buttons["quit"] = _button(col, "Beenden", func(): get_tree().quit())


func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _slider(parent: Node, text: String, key: String, lo: float, hi: float, step: float, rescale := false) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", UiTheme.FONT_HINT)
	parent.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(Settings.get_value(key))
	s.custom_minimum_size = Vector2(0, 24)
	s.value_changed.connect(func(v: float): Settings.set_value(key, v))
	if rescale:
		s.drag_ended.connect(func(_c): _apply_scale())
	parent.add_child(s)
	sliders[key] = s


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	_root.visible = true
	for k in sliders:   # Werte aktuell halten (z. B. nach Änderung anderswo)
		sliders[k].set_value_no_signal(float(Settings.get_value(k)))
	if not NetworkManager.is_online():
		get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if seed_label != null:
		var w = get_tree().root.find_child("World", true, false)
		var sv: int = int(w.island_seed) if w != null and "island_seed" in w else 0
		seed_label.text = "Insel-Seed: %s" % (str(sv) if sv != 0 else "klassisch")
	opened.emit()


## Speichert über `save_handler`; zeigt das Ergebnis im Pausenmenü. Gibt true bei Erfolg zurück.
## Nach dem Setzen von save_handler aufrufen: zeigt den Speichern-Knopf.
func save_handler_ready() -> void:
	if buttons.has("save"):
		buttons["save"].visible = save_handler.is_valid()


func save_now() -> bool:
	if not save_handler.is_valid():
		return false
	var err: int = int(save_handler.call())
	if save_label != null:
		save_label.text = "Gespeichert." if err == OK else "Speichern fehlgeschlagen (Fehler %d)." % err
	return err == OK


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func to_menu() -> void:
	NetworkManager.leave()
	is_open = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU_SCENE)


func apply_all() -> void:
	for k in ["volume_master", "volume_music", "volume_sfx", "fov"]:
		_apply(k)


func _apply(key: String) -> void:
	var v := float(Settings.get_value(key))
	match key:
		"volume_master":
			AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.0001)))
			AudioServer.set_bus_mute(0, v <= 0.001)
		"volume_music", "volume_sfx":
			var bus := AudioServer.get_bus_index("Music" if key == "volume_music" else "SFX")
			if bus >= 0:
				AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))
		"fov":
			var p := get_tree().root.find_children("*", "Player", true, false)
			for n in p:
				if n.is_multiplayer_authority() and n.cam != null:
					n.cam.fov = v
