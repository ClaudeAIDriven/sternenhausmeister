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


func _process(delta: float) -> void:
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
	lines += "Linke Maustaste / E: putzen · B: Werkstatt · Esc: Pause"
	if _extra != "":
		lines += "\n\n" + _extra
	_label.text = lines
