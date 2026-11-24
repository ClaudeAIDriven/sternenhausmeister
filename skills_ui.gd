class_name SkillsUI
extends CanvasLayer
## G-26: Fähigkeiten-Fenster (Taste K, Esc schließt). Zeigt Stufe, XP-Balken, freie Punkte und die Fähigkeiten (allgemein + eigene Rolle).

var is_open := false
var rows := {}   # Fähigkeit -> {"label": Label, "button": Button}
var head_label: Label
var xp_bar: ProgressBar
var _skills: Skills
var _xp: Xp
var _root: Control
var _col: VBoxContainer


func _ready() -> void:
	layer = 32
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	_root.theme = UiTheme.build(float(Settings.get_value("ui_scale")))
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.06, 0.14, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 8)
	panel.add_child(_col)
	head_label = Label.new()
	head_label.add_theme_font_size_override("font_size", UiTheme.FONT_MENU)
	head_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(head_label)
	xp_bar = ProgressBar.new()
	xp_bar.max_value = 1.0
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(0, 14)
	_col.add_child(xp_bar)


func bind(s: Skills) -> void:
	_skills = s
	_xp = s.xp
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for sk in s.list:
		var id: String = sk["id"]
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(120, 0)
		button.text = "Lernen"
		button.pressed.connect(func(): s.learn(id))
		row.add_child(button)
		list.add_child(row)
		rows[id] = {"label": label, "button": button, "row": row}
	var close_button := Button.new()
	close_button.text = "Schließen (Esc)"
	close_button.pressed.connect(close)
	_col.add_child(close_button)
	s.changed.connect(refresh)
	_xp.changed.connect(refresh)
	refresh()


func refresh() -> void:
	if _skills == null:
		return
	head_label.text = "Stufe %d  ·  %d freie Punkte" % [_xp.level, _xp.points]
	xp_bar.value = _xp.progress()
	for sk in _skills.list:
		var id: String = sk["id"]
		var r: Dictionary = rows[id]
		r["row"].visible = _skills.available(id)   # nur allgemeine und eigene Rolle
		r["label"].text = "%s (Stufe %d von %d)\n%s" % [sk["name"], _skills.level(id), int(sk["max_level"]), sk["desc"]]
		r["button"].disabled = not _skills.can_learn(id)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_K:
			toggle()
		elif event.physical_keycode == KEY_ESCAPE and is_open:
			close()
			get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	is_open = true
	_root.visible = true
	refresh()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	is_open = false
	_root.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
