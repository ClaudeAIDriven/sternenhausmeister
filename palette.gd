class_name Palette
extends RefCounted
## Verbindliche Farbpalette "Midnight Toy Garden" (A-06). Einzige Quelle für Farben in Himmel, Insel, Sternen, UI und Spielern.
## Weitere Abstufungen immer per `.lightened()/.darkened()` ableiten, nicht neu erfinden.

# Himmel (Tagesphasen)
const SKY_DUSK := Color("566DAB")
const SKY_MIDNIGHT := Color("202746")
const SKY_DAWN := Color("C17D91")

# Insel und Sterne
const ISLAND := Color("667D91")
const DIRT_GRAY := Color("777B83")
const STAR_GOLD := Color("FFD477")
const UI_IVORY := Color("F4EEDC")

# Spieler 1 bis 4 (Index 0..3)
const PLAYER_COLORS: Array[Color] = [Color("2878B8"), Color("E69F00"), Color("9B78C8"), Color("009E73")]
# Farbenblind-Modus: Spieler 3 heller, damit er von Spieler 1 bei Rot-Grün-Schwäche unterscheidbar bleibt (ΔE 28/38 statt 5/13).
const PLAYER_COLORS_CVD: Array[Color] = [Color("2878B8"), Color("E69F00"), Color("D8B4F0"), Color("009E73")]
# Zusätzliche Erkennung ohne Farbe (Pflicht, siehe docs/STYLEGUIDE.md): Symbol unter dem Namen und Fußring.
const PLAYER_SYMBOLS: Array[String] = ["circle", "square", "triangle", "diamond"]
const PLAYER_ACCESSORIES: Array[String] = ["none", "cap", "star_pendant", "scarf"]

# Schmutztypen (immer zusätzlich über Form unterscheiden)
const DIRT_SOOT := Color("2E3138")
const DIRT_STAIN := Color("6F7F93")
const DIRT_PATINA := Color("6E7550")

# UI
const UI_PANEL := Color("1B2140")
const UI_PANEL_ALT := Color("3A2F63")
const UI_ACCENT := STAR_GOLD


## Spielerfarbe, optional im Farbenblind-Modus.
static func player_color(index: int, cvd_mode := false) -> Color:
	var arr := PLAYER_COLORS_CVD if cvd_mode else PLAYER_COLORS
	return arr[posmod(index, arr.size())]


## Himmelsfarbe einer Phase ("dusk", "midnight", "dawn"); sonst Mitternacht.
static func sky_color(phase: String) -> Color:
	match phase:
		"dusk": return SKY_DUSK
		"dawn": return SKY_DAWN
		_: return SKY_MIDNIGHT


# --- Farbsehschwäche-Prüfung (Viénot-Näherung in linearem RGB, Abstand in CIE-Lab) ---
static func _lin(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


static func _gam(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 12.92 * x if x <= 0.0031308 else 1.055 * pow(x, 1.0 / 2.4) - 0.055


static func simulate(c: Color, mode: String) -> Color:
	var l := Vector3(_lin(c.r), _lin(c.g), _lin(c.b))
	var m: Array
	match mode:
		"prot": m = [Vector3(0.152286, 1.052583, -0.204868), Vector3(0.114503, 0.786281, 0.099216), Vector3(-0.003882, -0.048116, 1.051998)]
		"deut": m = [Vector3(0.367322, 0.860646, -0.227968), Vector3(0.280085, 0.672501, 0.047413), Vector3(-0.011820, 0.042940, 0.968881)]
		_: return c
	return Color(_gam(l.dot(m[0])), _gam(l.dot(m[1])), _gam(l.dot(m[2])))


static func _lab(c: Color) -> Vector3:
	var l := Vector3(_lin(c.r), _lin(c.g), _lin(c.b))
	var x := (0.4124 * l.x + 0.3576 * l.y + 0.1805 * l.z) / 0.95047
	var y := 0.2126 * l.x + 0.7152 * l.y + 0.0722 * l.z
	var z := (0.0193 * l.x + 0.1192 * l.y + 0.9505 * l.z) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	var fx: float = f.call(x)
	var fy: float = f.call(y)
	var fz: float = f.call(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


## Kleinster paarweiser Abstand (ΔE) der Spielerfarben unter einer Simulation ("normal", "prot", "deut").
static func min_player_distance(colors: Array[Color], mode := "normal") -> float:
	var best := INF
	for i in colors.size():
		for j in range(i + 1, colors.size()):
			best = minf(best, _lab(simulate(colors[i], mode)).distance_to(_lab(simulate(colors[j], mode))))
	return best


## Selbsttest: Hex-Werte laut Styleguide, 4 eindeutige Symbole/Accessoires, Abstände wie dokumentiert.
static func selftest() -> bool:
	var ok := true
	ok = ok and SKY_DUSK.to_html(false) == "566dab" and SKY_MIDNIGHT.to_html(false) == "202746" and SKY_DAWN.to_html(false) == "c17d91"
	ok = ok and ISLAND.to_html(false) == "667d91" and DIRT_GRAY.to_html(false) == "777b83"
	ok = ok and STAR_GOLD.to_html(false) == "ffd477" and UI_IVORY.to_html(false) == "f4eedc"
	var hex: Array[String] = []
	for c in PLAYER_COLORS:
		hex.append(c.to_html(false))
	ok = ok and hex == ["2878b8", "e69f00", "9b78c8", "009e73"]
	ok = ok and PLAYER_SYMBOLS.size() == 4 and PLAYER_ACCESSORIES.size() == 4
	var uniq := {}
	for s in PLAYER_SYMBOLS:
		uniq[s] = true
	ok = ok and uniq.size() == 4
	# normal sind alle gut unterscheidbar, CVD-Palette verbessert den schlechtesten Fall deutlich
	var n := min_player_distance(PLAYER_COLORS)
	var weak := min_player_distance(PLAYER_COLORS, "prot")
	var fixed := min_player_distance(PLAYER_COLORS_CVD, "prot")
	ok = ok and n > 25.0 and fixed > weak + 10.0 and fixed > 20.0
	print("SELFTEST Palette normal=%.0f prot(Standard)=%.0f prot(CVD-Palette)=%.0f -> %s" % [n, weak, fixed, "OK" if ok else "FAIL"])
	return ok
