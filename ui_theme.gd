class_name UiTheme
extends RefCounted
## UI-Theme "Notizbuch des Hausmeisters" (A-15): abgerundete Panels, Dunkelblau/Violett, goldene Akzente, Elfenbein-Text.
## Nutzung: `control.theme = UiTheme.build()`; `UiTheme.build(1.25)` skaliert Schrift und Abstände (UI-Skalierung).
## Schriftgrößen laut docs/STYLEGUIDE.md: HUD 20–24, Menü 32–44, Fließtext 18–22, Hinweise mindestens 16.
## Schriftart: Standardfont von Godot, solange keine Font-Datei (Nunito/Fredoka/Atkinson, SIL OFL) im Repo liegt.

const FONT_HUD := 22
const FONT_MENU := 40
const FONT_BODY := 20
const FONT_HINT := 16
const RADIUS := 14


static func panel_style(alt := false, scale := 1.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Palette.UI_PANEL_ALT if alt else Palette.UI_PANEL
	s.bg_color.a = 0.92
	s.set_corner_radius_all(int(RADIUS * scale))
	s.set_border_width_all(maxi(1, int(2 * scale)))
	s.border_color = Palette.STAR_GOLD.darkened(0.2)
	s.content_margin_left = 14 * scale
	s.content_margin_right = 14 * scale
	s.content_margin_top = 10 * scale
	s.content_margin_bottom = 10 * scale
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_size = int(4 * scale)
	return s


static func button_style(state: String, scale := 1.0) -> StyleBoxFlat:
	var s := panel_style(false, scale)
	s.content_margin_top = 8 * scale
	s.content_margin_bottom = 8 * scale
	match state:
		"hover":
			s.bg_color = Palette.UI_PANEL_ALT.lightened(0.1)
			s.border_color = Palette.STAR_GOLD
		"pressed":
			s.bg_color = Palette.STAR_GOLD.darkened(0.45)
			s.border_color = Palette.STAR_GOLD
		"disabled":
			s.bg_color = Palette.UI_PANEL.darkened(0.3)
			s.border_color = Color(0.4, 0.4, 0.45)
		"focus":
			s.bg_color = Color(0, 0, 0, 0)
			s.border_color = Palette.UI_IVORY   # deutlicher Fokusrahmen (Tastatur/Gamepad)
			s.set_border_width_all(maxi(2, int(3 * scale)))
		_:
			s.bg_color = Palette.UI_PANEL_ALT
	return s


static func build(scale := 1.0) -> Theme:
	var t := Theme.new()
	t.default_font_size = int(round(FONT_BODY * scale))
	for ctl in ["Label", "Button", "CheckBox", "LineEdit", "RichTextLabel"]:
		t.set_color("font_color", ctl, Palette.UI_IVORY)
	t.set_color("font_color_hover", "Button", Palette.STAR_GOLD.lightened(0.3))
	t.set_color("font_color_pressed", "Button", Palette.UI_IVORY)
	t.set_color("font_color_disabled", "Button", Palette.UI_IVORY.darkened(0.5))
	t.set_font_size("font_size", "Label", int(round(FONT_BODY * scale)))
	t.set_font_size("font_size", "Button", int(round(FONT_BODY * scale)))
	t.set_stylebox("panel", "PanelContainer", panel_style(false, scale))
	t.set_stylebox("panel", "Panel", panel_style(false, scale))
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(st, "Button", button_style(st, scale))
	# Fortschrittsbalken (Putzfortschritt): dunkle Rinne, goldene Füllung, abgerundet
	var bg := StyleBoxFlat.new()
	bg.bg_color = Palette.UI_PANEL.darkened(0.3)
	bg.set_corner_radius_all(int(8 * scale))
	bg.set_border_width_all(maxi(1, int(2 * scale)))
	bg.border_color = Palette.STAR_GOLD.darkened(0.45)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Palette.STAR_GOLD
	fill.set_corner_radius_all(int(8 * scale))
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_font_size("font_size", "ProgressBar", int(round(FONT_HINT * scale)))
	t.set_color("font_color", "ProgressBar", Palette.UI_IVORY)
	# Varianten für Überschriften und Hinweise (Label mit theme_type_variation)
	t.add_type("HeadingLabel")
	t.set_type_variation("HeadingLabel", "Label")
	t.set_font_size("font_size", "HeadingLabel", int(round(FONT_MENU * scale)))
	t.set_color("font_color", "HeadingLabel", Palette.STAR_GOLD)
	t.add_type("HudLabel")
	t.set_type_variation("HudLabel", "Label")
	t.set_font_size("font_size", "HudLabel", int(round(FONT_HUD * scale)))
	t.add_type("HintLabel")
	t.set_type_variation("HintLabel", "Label")
	t.set_font_size("font_size", "HintLabel", int(round(FONT_HINT * scale)))
	t.set_color("font_color", "HintLabel", Palette.UI_IVORY.darkened(0.15))
	return t


## Selbsttest: Schriftgrößen im Styleguide-Rahmen, Panels abgerundet, Skalierung wirkt, Kontrast Text/Panel >= 7:1 (WCAG AAA).
static func selftest() -> bool:
	var t := build()
	var ok := t.default_font_size == 20 and t.get_font_size("font_size", "HeadingLabel") == 40 and t.get_font_size("font_size", "HudLabel") == 22
	ok = ok and t.get_font_size("font_size", "HintLabel") >= 16
	ok = ok and (t.get_stylebox("panel", "PanelContainer") as StyleBoxFlat).corner_radius_top_left == RADIUS
	var big := build(1.5)
	ok = ok and big.default_font_size == 30 and (big.get_stylebox("panel", "PanelContainer") as StyleBoxFlat).corner_radius_top_left == 21
	var ratio := contrast(Palette.UI_IVORY, Palette.UI_PANEL)
	ok = ok and ratio >= 7.0
	print("SELFTEST UiTheme Kontrast Elfenbein/Panel %.1f:1 -> %s" % [ratio, "OK" if ok else "FAIL"])
	return ok


static func _rel_lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


## WCAG-Kontrastverhältnis zweier Farben.
static func contrast(a: Color, b: Color) -> float:
	var la := _rel_lum(a)
	var lb := _rel_lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)
