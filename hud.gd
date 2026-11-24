class_name Hud
extends CanvasLayer
## Anzeige: Staub, Nachtzeit und -phase, geputzte Sterne, Spielerliste (online), Steuerungshinweis.

const PHASE_NAMES := ["Dämmerung", "Mitternacht", "Morgenrot", "Ende"]

var _label: Label
var _night: Night
var _cleaned := 0
var _total := 0
var _extra := ""
var _puzzle := ""        # Zeile mit Sternbild-Fortschritt
var _puzzle_msg := ""    # Hinweis nach falscher Reihenfolge / Lösung
var _puzzle_msg_left := 0.0
var _since_refresh := 0.0
var _inv_label: Label    # G-22: Beutel unten links, 6 Plätze
var _msg_label: Label    # G-22: kurze Frucht-Meldung
var _msg_left := 0.0
var _world: World


func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(20, 16)
	_label.add_theme_font_size_override("font_size", 22)
	add_child(_label)
	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 28)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-8, -18)
	add_child(cross)
	_inv_label = Label.new()
	_inv_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_inv_label.offset_left = 14
	_inv_label.offset_top = -92
	_inv_label.add_theme_font_size_override("font_size", 18)
	_inv_label.add_theme_color_override("font_color", Palette.UI_IVORY)
	_inv_label.add_theme_color_override("font_outline_color", Palette.UI_PANEL)
	_inv_label.add_theme_constant_override("outline_size", 6)
	add_child(_inv_label)
	_msg_label = Label.new()
	_msg_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_msg_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_msg_label.offset_top = -150
	_msg_label.add_theme_color_override("font_color", Palette.STAR_GOLD)
	_msg_label.add_theme_color_override("font_outline_color", Palette.UI_PANEL)
	_msg_label.add_theme_constant_override("outline_size", 6)
	add_child(_msg_label)
	GameState.dust_changed.connect(func(_a): refresh())
	GameState.phase_changed.connect(func(_p): refresh())
	NetworkManager.players_changed.connect(refresh)
	refresh()


func bind_night(n: Night) -> void:
	_night = n


func show_status(cleaned: int, total: int, extra: String = "") -> void:
	_cleaned = cleaned
	_total = total
	_extra = extra
	refresh()


## Sternbild-Fortschritt (I-04): z. B. "Sternbild Dreieck: 2 / 3".
func show_puzzle(title: String, done: int, total: int) -> void:
	_puzzle = "Sternbild %s: %d / %d" % [title, done, total]
	refresh()


## Kurze Meldung (Hinweis bei falscher Reihenfolge, Bonus bei Lösung), verschwindet nach `seconds`.
func show_puzzle_message(msg: String, seconds := 6.0) -> void:
	_puzzle_msg = msg
	_puzzle_msg_left = seconds
	refresh()


func text() -> String:
	return _label.text if _label else ""


## G-22: Beutel und Meldungen einer Welt anzeigen (wird in _process automatisch gesucht, wenn nicht gesetzt).
func bind_world(w: World) -> void:
	_world = w
	w.fruit_message.connect(func(t: String):
		_msg_label.text = t
		_msg_left = 3.0)


## Beutel als Text: "Beutel (F aufheben, Q essen): [Sternbeere] [-] ..."
func inventory_text() -> String:
	if _world == null:
		return ""
	var parts: Array[String] = []
	for i in Inventory.SLOTS:
		parts.append("[%s]" % (Fruit.display_name(_world.inventory.items[i]) if i < _world.inventory.items.size() else "–"))
	return "Beutel (F: aufheben, Q: essen)\n" + " ".join(parts)


func _process(delta: float) -> void:
	if _world == null and get_tree() != null:
		var w := get_tree().root.find_child("World", true, false) as World
		if w != null:
			bind_world(w)
	if _msg_left > 0.0:
		_msg_left -= delta
		if _msg_left <= 0.0:
			_msg_label.text = ""
	_inv_label.text = inventory_text()
	_since_refresh += delta
	if _puzzle_msg_left > 0.0:
		_puzzle_msg_left -= delta
		if _puzzle_msg_left <= 0.0:
			_puzzle_msg = ""
	if _since_refresh >= 0.25:
		_since_refresh = 0.0
		refresh()


func refresh() -> void:
	if _label == null:
		return
	var lines := ""
	if _night != null:
		var secs := int(ceil(_night.time_left()))
		lines += "Zeit: %02d:%02d  ·  %s\n" % [secs / 60, secs % 60, PHASE_NAMES[GameState.night_state]]
	lines += "Staub: %d  ·  Sterne geputzt: %d / %d\n" % [GameState.dust, _cleaned, _total]
	var lp := _local_player()
	if lp != null:
		lines += "Stufe %d · XP %d%s\n" % [lp.xp.level, lp.xp.xp, (" · %d Punkt(e) – K drücken" % lp.xp.points) if lp.xp.points > 0 else ""]
	if _puzzle != "":
		lines += _puzzle + "\n"
	if _puzzle_msg != "":
		lines += _puzzle_msg + "\n"
	if NetworkManager.is_online():
		var names: Array[String] = []
		for id in NetworkManager.players:
			names.append(str(NetworkManager.players[id].get("name", id)))
		lines += "Spieler (%d): %s\n" % [names.size(), ", ".join(names)]
	lines += "WASD laufen · Leertaste springen · Maus zielen\n"
	lines += "Linke Maustaste / E: putzen · Rechte Maustaste: schubsen · F an der Werkstatt: Upgrades · Esc: Pause"
	if _extra != "":
		lines += "\n\n" + _extra
	_label.text = lines


func _local_player() -> Player:
	if get_tree() == null:
		return null
	for n in get_tree().get_nodes_in_group("players"):
		var p := n as Player
		if p != null and p.is_multiplayer_authority():
			return p
	return null
