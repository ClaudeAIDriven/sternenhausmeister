class_name NightSummary
extends CanvasLayer
## Nacht-Zusammenfassung (U-05): Am Nachtende erscheint eine Übersicht mit 1 bis 3 Sternchen, geputzten Sternen, Sternbild
## und dem Staub, den du in dieser Nacht gesammelt hast. Kein Game Over, keine Rangliste: mindestens ein Sternchen immer.
## Nutzung: `var s := NightSummary.new(); add_child(s); s.bind(world)` in der Spielszene. Zeigt sich bei GameState.night_ended.
## Hinweis: Der Beitrag anderer Spieler wird nicht angezeigt (nur dein eigener Staub); eine Spielerübersicht bräuchte Netzdaten.

var is_open := false
var earned := 0
var stars_label: Label
var info_label: Label
var continue_button: Button
var menu_button: Button
var _world: World
var _root: Control


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	_root.theme = UiTheme.build(float(Settings.get_value("ui_scale")))
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.06, 0.14, 0.7)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var title := Label.new()
	title.text = "Die Nacht ist vorbei"
	title.add_theme_font_size_override("font_size", UiTheme.FONT_MENU)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	stars_label = Label.new()
	stars_label.add_theme_font_size_override("font_size", 56)
	stars_label.add_theme_color_override("font_color", Palette.STAR_GOLD)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(stars_label)
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(info_label)
	continue_button = Button.new()
	continue_button.text = "Weiter putzen"
	continue_button.pressed.connect(close)
	col.add_child(continue_button)
	menu_button = Button.new()
	menu_button.text = "Zum Hauptmenü"
	menu_button.pressed.connect(_to_menu)
	col.add_child(menu_button)
	GameState.night_started.connect(func(): earned = 0)
	GameState.dust_changed.connect(_on_dust)
	GameState.night_ended.connect(show_summary)


func bind(world: World) -> void:
	_world = world


var _last_dust := 0

func _on_dust(amount: int) -> void:
	if amount > _last_dust and GameState.night_running:
		earned += amount - _last_dust
	_last_dust = amount


## 3 Sternchen: alle Sterne sauber und (falls vorhanden) Sternbild gelöst. 2: mindestens 60 % der Sterne. Sonst 1.
static func rating(cleaned: int, total: int, puzzle_solved: bool, has_puzzle: bool) -> int:
	if total <= 0:
		return 1
	if cleaned >= total and (puzzle_solved or not has_puzzle):
		return 3
	if float(cleaned) / total >= 0.6:
		return 2
	return 1


static func stars_text(n: int) -> String:
	return "★".repeat(n) + "☆".repeat(3 - n)


func show_summary() -> void:
	var total := _world.stars.size() if _world != null else 0
	var cleaned := _world.cleaned_count() if _world != null else 0
	var has_puzzle := _world != null and _world.puzzle != null
	var solved: bool = has_puzzle and _world.puzzle.is_solved
	var r := rating(cleaned, total, solved, has_puzzle)
	stars_label.text = stars_text(r)
	var lines := ["Geputzte Sterne: %d von %d" % [cleaned, total]]
	if has_puzzle:
		lines.append("Sternbild „%s“: %s" % [_world.puzzle.title, "gelöst ✔" if solved else "noch offen"])
	lines.append("Dein Sternenstaub in dieser Nacht: %d" % earned)
	lines.append("Das Spiel geht weiter, putz in Ruhe zu Ende." if r < 3 else "Der Himmel glänzt!")
	info_label.text = "\n".join(lines)
	is_open = true
	_root.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	is_open = false
	_root.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _to_menu() -> void:
	NetworkManager.leave()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://menu.tscn")
