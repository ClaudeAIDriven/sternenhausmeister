class_name Menu
extends Node
## Hauptmenü (U-01): Solo, Hosten, Beitreten (IP), Einstellungen, Beenden. Hintergrund: MenuBackdrop (A-16), Theme: UiTheme (A-15).
## Die Wahl steht danach in `Menu.launch` = {"mode": "solo"|"host"|"join", "ip": String, "name": String}
## und wird per Signal `start_requested` gemeldet. Mit `auto_start` wechselt das Menü danach zu `game_scene`.
## 🟡 Noch offen (Folgekarte): main.gd soll `Menu.launch` auswerten (Host/Join starten) und project.godot main_scene auf menu.tscn zeigen.

signal start_requested(mode: String, ip: String, player_name: String)

static var launch := {}

@export var auto_start := true
@export var game_scene := "res://main.tscn"
@export var port_hint := 24680   # = NetworkManager.DEFAULT_PORT

var name_edit: LineEdit
var ip_edit: LineEdit
var status: Label
var buttons := {}   # "solo" | "host" | "join" | "settings" | "quit" -> Button
var main_box: VBoxContainer
var role_option: OptionButton    # I-13: Rolle
var brawl_check: CheckBox   # G-32: Rauflust (Schubsen macht Schaden), Standard aus
var preset_option: OptionButton   # I-08: Spielart (Presets aus G-09)
var settings_box: VBoxContainer
var _canvas: CanvasLayer
var _root: Control


func _ready() -> void:
	add_child(MenuBackdrop.new())
	_canvas = CanvasLayer.new()
	add_child(_canvas)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(_root)
	_build_ui()
	_apply_scale()


func _apply_scale() -> void:
	_root.theme = UiTheme.build(float(Settings.get_value("ui_scale")))


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = 48
	panel.offset_right = 48 + 440
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var logo := load("res://assets/ui/logo.svg") as Texture2D
	if logo != null:
		var tr := TextureRect.new()
		tr.texture = logo
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(0, 110)
		col.add_child(tr)
	else:
		col.add_child(_label("StarScrubber", UiTheme.FONT_MENU))

	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 10)
	col.add_child(main_box)
	main_box.add_child(_label("Dein Name"))
	name_edit = LineEdit.new()
	name_edit.name = "NameEdit"
	name_edit.text = str(Settings.get_value("player_name"))
	name_edit.max_length = 16
	main_box.add_child(name_edit)
	main_box.add_child(_label("Rolle"))
	role_option = OptionButton.new()
	role_option.name = "RoleOption"
	for rid in Roles.ids():
		role_option.add_item("%s – %s" % [Roles.data(rid)["name"], Roles.data(rid)["desc"]])
		role_option.set_item_metadata(role_option.item_count - 1, rid)
		if rid == str(Settings.get_value("role")):
			role_option.select(role_option.item_count - 1)
	main_box.add_child(role_option)
	main_box.add_child(_label("Spielart"))
	preset_option = OptionButton.new()
	preset_option.name = "PresetOption"
	var all := Presets.load_all()
	var ids: Array = all.keys()
	ids.sort_custom(func(a, b): return str(all[a]["name"]) < str(all[b]["name"]))
	if ids.has(Presets.DEFAULT_ID):   # Standard steht vorn
		ids.erase(Presets.DEFAULT_ID)
		ids.push_front(Presets.DEFAULT_ID)
	for id in ids:
		preset_option.add_item(str(all[id]["name"]))
		preset_option.set_item_metadata(preset_option.item_count - 1, id)
	main_box.add_child(preset_option)
	brawl_check = CheckBox.new()
	brawl_check.name = "BrawlCheck"
	brawl_check.text = "Rauflust: Schubsen macht Schaden (nur Host)"
	brawl_check.tooltip_text = "Aus = Friedlich: Schubsen stößt nur weg."
	main_box.add_child(brawl_check)
	buttons["solo"] = _button(main_box, "Allein putzen", func(): start("solo"))
	buttons["host"] = _button(main_box, "Raum eröffnen (Host)", func(): start("host"))
	main_box.add_child(_label("Beitreten: Adresse des Hosts"))
	ip_edit = LineEdit.new()
	ip_edit.name = "IpEdit"
	ip_edit.placeholder_text = "z. B. 192.168.0.12"
	ip_edit.max_length = 64
	ip_edit.text_submitted.connect(func(_t): start("join"))
	main_box.add_child(ip_edit)
	buttons["join"] = _button(main_box, "Beitreten", func(): start("join"))
	buttons["settings"] = _button(main_box, "Einstellungen", func(): _show_settings(true))
	buttons["quit"] = _button(main_box, "Beenden", func(): get_tree().quit())
	status = _label("", UiTheme.FONT_HINT)
	status.name = "Status"
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(status)
	_set_status("Host braucht freien UDP-Port %d (Router-Freigabe fürs Internet)." % port_hint)

	settings_box = VBoxContainer.new()
	settings_box.name = "SettingsBox"
	settings_box.visible = false
	settings_box.add_theme_constant_override("separation", 8)
	col.add_child(settings_box)
	_slider("Gesamtlautstärke", "volume_master", 0.0, 1.0, 0.05)
	_slider("Musik", "volume_music", 0.0, 1.0, 0.05)
	_slider("Effekte", "volume_sfx", 0.0, 1.0, 0.05)
	_slider("Maus-Empfindlichkeit", "mouse_sens", 0.001, 0.008, 0.0005)
	_slider("Sichtfeld", "fov", 60.0, 100.0, 1.0)
	_slider("UI-Größe", "ui_scale", 0.8, 1.5, 0.05, true)
	_button(settings_box, "Zurück", func(): _show_settings(false)).name = "BackButton"


func _label(t: String, size := 0) -> Label:
	var l := Label.new()
	l.text = t
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	return l


func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _slider(text: String, key: String, lo: float, hi: float, step: float, rescale := false) -> void:
	settings_box.add_child(_label(text, UiTheme.FONT_HINT))
	var s := HSlider.new()
	s.name = "Slider_" + key
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(Settings.get_value(key))
	s.custom_minimum_size = Vector2(0, 24)
	s.value_changed.connect(func(v: float):
		Settings.set_value(key, v)
	)
	if rescale:   # UI-Größe erst beim Loslassen anwenden, sonst springt der Regler unter der Maus
		s.drag_ended.connect(func(_c): _apply_scale())
	settings_box.add_child(s)


func _show_settings(on: bool) -> void:
	main_box.visible = not on
	settings_box.visible = on


func _set_status(t: String) -> void:
	if status != null:
		status.text = t


## Gültige Host-Adresse: IPv4, Hostname oder IPv6 (ohne Leerzeichen), nicht leer.
static func valid_address(a: String) -> bool:
	a = a.strip_edges()
	if a.is_empty() or a.contains(" ") or a.length() > 253:
		return false
	var re := RegEx.new()
	re.compile("^[A-Za-z0-9\\.\\-:\\[\\]]+$")
	return re.search(a) != null


## Startet den gewählten Modus ("solo", "host", "join"). Gibt false zurück, wenn die Eingabe nicht passt.
func start(mode: String) -> bool:
	var pname := name_edit.text.strip_edges()
	if pname.is_empty():
		pname = str(Settings.get_value("player_name"))
	var ip := ip_edit.text.strip_edges()
	if mode == "join" and not valid_address(ip):
		_set_status("Bitte die Adresse des Hosts eintragen, z. B. 192.168.0.12.")
		ip_edit.grab_focus()
		return false
	Settings.set_value("player_name", pname)
	var preset: String = Presets.DEFAULT_ID
	if preset_option != null and preset_option.selected >= 0:
		preset = str(preset_option.get_item_metadata(preset_option.selected))
	var role: String = Roles.DEFAULT_ID
	if role_option != null and role_option.selected >= 0:
		role = str(role_option.get_item_metadata(role_option.selected))
	Settings.set_value("role", role)
	launch = {"mode": mode, "ip": ip if mode == "join" else "", "name": pname, "preset": preset, "brawl": brawl_check != null and brawl_check.button_pressed}
	start_requested.emit(mode, launch["ip"], pname)
	if auto_start:
		get_tree().change_scene_to_file(game_scene)
	return true
