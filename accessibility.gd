class_name Accessibility
extends CanvasLayer
## U-04: Barrierefreiheit. Visuelle Klanganzeige (Untertitel), Farbenblind-Modus (Spielerfarben aus Palette) und
## UI-Skalierung 100–200 %. Optionen werden in user://accessibility.cfg gespeichert (eigene Datei: settings.gd gehört nicht zur Karte).
##
## Nutzung: `var a := Accessibility.new(); add_child(a)`; Untertitel: `a.announce("star_cleaned")` oder `a.show_caption("Text")`;
## UI: `a.apply_to(control)` setzt das skalierte Theme; Menü: `parent.add_child(a.build_panel())` zeigt die drei Optionen.
## Farbenblind-Modus: `PlayerLook.build(index, a.cvd_mode)` bzw. `a.player_color(index)`.

signal options_changed

const SCALE_MIN := 1.0
const SCALE_MAX := 2.0
const MAX_CAPTIONS := 3
## Klang-ID -> Untertitel. Das Symbol am Anfang unterscheidet Klangarten auch ohne Farbe.
const SOUNDS := {
	"scrub": "▒ Putzgeräusch",
	"star_cleaned": "✦ Glockenton: Stern strahlt",
	"constellation": "♪ Melodie: Sternbild gelöst",
	"wrong": "✖ Dumpfer Ton: falsche Reihenfolge",
	"weather_warning": "! Wind frischt auf: Wetter naht",
	"meteor": "☄ Zischen: Sternschnuppe",
	"night_end": "☀ Vögel: Morgenrot",
	"player_joined": "+ Spieler beigetreten",
}

var cfg_path := "user://accessibility.cfg"
var captions_enabled := true
var cvd_mode := false
var ui_scale := 1.0

var _box: VBoxContainer
var _active: Array = []   # {label: PanelContainer, left: float}


func _init() -> void:
	layer = 50
	name = "Accessibility"


func _ready() -> void:
	load_options()
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.offset_bottom = -40
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)


# --- Optionen ----------------------------------------------------------------

func set_scale_factor(v: float) -> void:
	ui_scale = clampf(v, SCALE_MIN, SCALE_MAX)
	_changed()


func set_cvd_mode(v: bool) -> void:
	cvd_mode = v
	_changed()


func set_captions(v: bool) -> void:
	captions_enabled = v
	if not v:
		clear_captions()
	_changed()


func _changed() -> void:
	save_options()
	options_changed.emit()


func save_options() -> Error:
	var cf := ConfigFile.new()
	cf.set_value("a11y", "captions", captions_enabled)
	cf.set_value("a11y", "cvd_mode", cvd_mode)
	cf.set_value("a11y", "ui_scale", ui_scale)
	return cf.save(cfg_path)


func load_options() -> Error:
	var cf := ConfigFile.new()
	var err := cf.load(cfg_path)
	if err != OK:
		return err
	captions_enabled = bool(cf.get_value("a11y", "captions", true))
	cvd_mode = bool(cf.get_value("a11y", "cvd_mode", false))
	ui_scale = clampf(float(cf.get_value("a11y", "ui_scale", 1.0)), SCALE_MIN, SCALE_MAX)
	return OK


## Skaliertes Theme (Schrift und Abstände), siehe UiTheme.
func make_theme() -> Theme:
	return UiTheme.build(ui_scale)


func apply_to(control: Control) -> void:
	control.theme = make_theme()


func player_color(index: int) -> Color:
	return Palette.player_color(index, cvd_mode)


# --- Visuelle Klanganzeige -------------------------------------------------------

## Zeigt den Untertitel zu einer Klang-ID (siehe SOUNDS). Unbekannte IDs werden ignoriert.
func announce(sound_id: String, seconds: float = 2.5) -> void:
	if SOUNDS.has(sound_id):
		show_caption(SOUNDS[sound_id], seconds)


func show_caption(text: String, seconds: float = 2.5) -> void:
	if not captions_enabled or _box == null:
		return
	while _active.size() >= MAX_CAPTIONS:
		_drop(0)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.panel_style(true, ui_scale))
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(UiTheme.FONT_BODY * ui_scale))
	l.add_theme_color_override("font_color", Palette.UI_IVORY)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(p)
	_active.append({"node": p, "left": seconds})


func caption_texts() -> Array[String]:
	var out: Array[String] = []
	for c in _active:
		out.append(((c["node"] as Node).get_child(0) as Label).text)
	return out


func clear_captions() -> void:
	while not _active.is_empty():
		_drop(0)


func tick(delta: float) -> void:
	for i in range(_active.size() - 1, -1, -1):
		_active[i]["left"] -= delta
		if _active[i]["left"] <= 0.0:
			_drop(i)


func _process(delta: float) -> void:
	tick(delta)


func _drop(i: int) -> void:
	(_active[i]["node"] as Node).queue_free()
	_active.remove_at(i)


# --- Menü-Bausteine ---------------------------------------------------------------

## Kleines Panel mit den drei Optionen zum Einbetten ins Optionsmenü.
func build_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "AccessibilityPanel"
	panel.theme = make_theme()   # skaliert Schrift und Abstände
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style(false, ui_scale))
	var v := VBoxContainer.new()
	panel.add_child(v)
	var title := Label.new()
	title.text = "Barrierefreiheit"
	title.add_theme_font_size_override("font_size", int(UiTheme.FONT_BODY * 1.3 * ui_scale))
	v.add_child(title)
	var cap := CheckBox.new()
	cap.text = "Untertitel für Klänge (visuelle Klanganzeige)"
	cap.button_pressed = captions_enabled
	cap.toggled.connect(set_captions)
	v.add_child(cap)
	var cb := CheckBox.new()
	cb.text = "Farbenblind-Modus (hellere Spielerfarben, Symbole bleiben)"
	cb.button_pressed = cvd_mode
	cb.toggled.connect(set_cvd_mode)
	v.add_child(cb)
	var row := HBoxContainer.new()
	v.add_child(row)
	var lab := Label.new()
	lab.text = "UI-Größe"
	row.add_child(lab)
	var sl := HSlider.new()
	sl.min_value = SCALE_MIN * 100.0
	sl.max_value = SCALE_MAX * 100.0
	sl.step = 25.0
	sl.value = ui_scale * 100.0
	sl.custom_minimum_size.x = 220.0 * ui_scale
	sl.value_changed.connect(func(x): set_scale_factor(x / 100.0))
	row.add_child(sl)
	return panel
