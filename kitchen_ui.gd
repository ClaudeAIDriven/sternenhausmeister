class_name KitchenUI
extends CanvasLayer
## G-23: Rezeptbuch an der Küche (Taste F in der Nähe, Esc schließt). Zeigt Rezepte, Zutaten (Beutel), Sättigung und Buffs;
## ein Knopf je Rezept kocht. Nutzung: `ui.bind(kitchen, inventory, player)`.

var is_open := false
var rows := {}   # Rezept-ID -> {"label": Label, "button": Button}
var buff_label: Label
var prompt_label: Label
var _kitchen: Kitchen
var _inv: Inventory
var _player: Player
var _root: Control
var _col: VBoxContainer


func _ready() -> void:
	layer = 31
	process_mode = Node.PROCESS_MODE_ALWAYS
	prompt_label = Label.new()
	prompt_label.text = "F: Küche (Rezepte)"
	prompt_label.add_theme_font_size_override("font_size", UiTheme.FONT_MENU)
	prompt_label.add_theme_color_override("font_color", Palette.STAR_GOLD)
	prompt_label.add_theme_color_override("font_outline_color", Palette.UI_PANEL)
	prompt_label.add_theme_constant_override("outline_size", 8)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_label.offset_top = -170
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
	panel.custom_minimum_size = Vector2(580, 0)
	center.add_child(panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	panel.add_child(_col)
	var title := Label.new()
	title.text = "Küche"
	title.add_theme_font_size_override("font_size", UiTheme.FONT_MENU)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(title)
	buff_label = Label.new()
	buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buff_label.add_theme_color_override("font_color", Palette.STAR_GOLD)
	_col.add_child(buff_label)


func bind(k: Kitchen, inv: Inventory, p: Player) -> void:
	_kitchen = k
	_inv = inv
	_player = p
	for r in k.recipes:
		var id: String = r["id"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(130, 0)
		button.text = "Kochen"
		button.pressed.connect(func(): cook(id))
		row.add_child(button)
		_col.add_child(row)
		rows[id] = {"label": label, "button": button}
	var close_button := Button.new()
	close_button.text = "Schließen (Esc)"
	close_button.pressed.connect(close)
	_col.add_child(close_button)
	inv.changed.connect(refresh)
	k.buffs_changed.connect(refresh)
	refresh()


func cook(id: String) -> bool:
	if _kitchen == null:
		return false
	return _kitchen.cook(id, _inv, _player.food if _player != null else null, _player.role if _player != null else "")


func refresh() -> void:
	if _kitchen == null:
		return
	for r in _kitchen.recipes:
		var id: String = r["id"]
		var need: Array[String] = []
		for kind in r["ingredients"]:
			need.append("%dx %s (%d)" % [int(r["ingredients"][kind]), Fruit.display_name(kind), _inv.items.count(kind)])
		var b: Dictionary = r["buff"]
		rows[id]["label"].text = "%s – %s\nZutaten (im Beutel): %s\nSättigung +%d, %s ×%.2f für %d s" % [r["name"], r["desc"], ", ".join(need), int(r["food"]), b.get("label", b["stat"]), float(b["mult"]), int(b["seconds"])]
		rows[id]["button"].disabled = not _kitchen.can_cook(id, _inv)
	var parts: Array[String] = []
	for stat in _kitchen.buffs:
		parts.append("%s ×%.2f (%d s)" % [_kitchen.buffs[stat]["label"], _kitchen.buffs[stat]["mult"], int(ceil(_kitchen.buffs[stat]["left"]))])
	buff_label.text = "Aktive Wirkungen: " + (", ".join(parts) if not parts.is_empty() else "keine")


func is_near() -> bool:
	if _player == null or not is_instance_valid(_player) or _kitchen == null:
		return false
	return _kitchen.is_near(_player.global_position)


func _process(_delta: float) -> void:
	prompt_label.visible = is_near() and not is_open
	if is_open and not is_near():
		close()
	if is_open:
		refresh()   # Restzeit der Buffs läuft mit


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F and (is_open or is_near()):
			toggle()
			get_viewport().set_input_as_handled()
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
