class_name ShopUI
extends CanvasLayer
## Werkstatt-Oberfläche (I-09): Taste B öffnet/schließt die Liste der Upgrades (Shop, G-05). Zeigt Staub, Stufe, Preis und
## einen Kaufen-Knopf je Upgrade. Unten links steht dauerhaft ein kleiner Hinweis auf die Taste. Esc schließt ebenfalls.
## Nutzung: `var ui := ShopUI.new(); add_child(ui); ui.bind(shop)`.

var is_open := false
var player_ref: Node3D            # I-11: eigener Spieler; null = keine Nähe-Prüfung (Tests)
var workshop_pos := World.WORKSHOP_POS
var prompt_label: Label
var rows := {}        # Upgrade-ID -> {"label": Label, "button": Button}
var dust_label: Label
var hint_label: Label
var _shop: Shop
var _root: Control
var _col: VBoxContainer
var _list: VBoxContainer   # G-25: scrollbare Liste (Utensilien + Upgrades)


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	hint_label = Label.new()
	hint_label.text = "In der Nähe der Werkstatt: F"
	hint_label.add_theme_font_size_override("font_size", UiTheme.FONT_HINT)
	hint_label.add_theme_color_override("font_color", Palette.UI_IVORY)
	hint_label.add_theme_color_override("font_outline_color", Palette.UI_PANEL)
	hint_label.add_theme_constant_override("outline_size", 6)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint_label.offset_left = 14
	hint_label.offset_top = -34
	add_child(hint_label)
	prompt_label = Label.new()
	prompt_label.text = "F: Werkstatt betreten (Upgrades)"
	prompt_label.add_theme_font_size_override("font_size", UiTheme.FONT_MENU)
	prompt_label.add_theme_color_override("font_color", Palette.STAR_GOLD)
	prompt_label.add_theme_color_override("font_outline_color", Palette.UI_PANEL)
	prompt_label.add_theme_constant_override("outline_size", 8)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_label.offset_top = -120
	prompt_label.visible = false
	add_child(prompt_label)
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
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	panel.add_child(_col)
	var title := Label.new()
	title.text = "Werkstatt"
	title.add_theme_font_size_override("font_size", UiTheme.FONT_MENU)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(title)
	dust_label = Label.new()
	dust_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dust_label.add_theme_color_override("font_color", Palette.STAR_GOLD)
	_col.add_child(dust_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)
	GameState.dust_changed.connect(func(_a): refresh())


func bind(shop: Shop) -> void:
	_shop = shop
	for u in shop._all():
		var id: String = u["id"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(170, 0)
		button.pressed.connect(func(): _on_row_pressed(id))
		row.add_child(button)
		_list.add_child(row)
		rows[id] = {"label": label, "button": button}
	var close_button := Button.new()
	close_button.text = "Schließen (B)"
	close_button.pressed.connect(close)
	_col.add_child(close_button)
	shop.levels_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if _shop == null:
		return
	dust_label.text = "Sternenstaub: %d" % GameState.dust
	for u in _shop._all():
		var id: String = u["id"]
		var r: Dictionary = rows[id]
		var lv := _shop.level(id)
		var b: Button = r["button"]
		if u.has("utensil_item"):   # G-25: Utensil kaufen / ausrüsten
			var uid: String = u["utensil_item"]
			r["label"].text = "%s%s\n%s" % [u["name"], "  (in der Hand)" if _shop.equipped == uid else "", u["desc"]]
			if _shop.owns(uid):
				b.text = "Ausgerüstet" if _shop.equipped == uid else "Ausrüsten"
				b.disabled = _shop.equipped == uid
			else:
				b.text = "Kaufen: %d ⭐" % _shop.cost(id)
				b.disabled = not _shop.can_buy(id)
			continue
		r["label"].text = "%s  (Stufe %d von %d)\n%s" % [u["name"], lv, int(u["max_level"]), u["desc"]]
		if _shop.is_maxed(id):
			b.text = "Maximal"
			b.disabled = true
		elif str(u.get("requires", "")) != "" and _shop.level(str(u["requires"])) <= 0:
			b.text = "Utensil fehlt"
			b.disabled = true
		else:
			b.text = "Kaufen: %d ⭐" % _shop.cost(id)
			b.disabled = not _shop.can_buy(id)


func _on_row_pressed(id: String) -> void:
	var u := _shop._find(id)
	if u.has("utensil_item") and _shop.owns(str(u["utensil_item"])):
		_shop.equip(str(u["utensil_item"]))
	else:
		_shop.request_buy(id)


## Nähe zur Werkstatt (waagerecht). Ohne Spieler-Referenz (Tests, Menü) gilt: immer nah.
func is_near() -> bool:
	if player_ref == null or not is_instance_valid(player_ref):
		return true
	var d := player_ref.global_position - workshop_pos
	d.y = 0.0
	return d.length() <= World.WORKSHOP_RANGE


func _process(_delta: float) -> void:
	prompt_label.visible = player_ref != null and is_near() and not is_open
	hint_label.visible = not prompt_label.visible
	if is_open and not is_near():
		close()   # zu weit weggeschubst oder gelaufen


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B or event.physical_keycode == KEY_F:
			if is_open or is_near():
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
