class_name Presets
extends RefCounted
## G-09: Regel-Presets (Zen, Kinder, Standard) als JSON in data/presets/. Slider-Werte überschreiben das Preset.
## Regeln: time_limit_s (Sekunden bis Sonnenaufgang, 30..7200), weather ("normal" | "cosmetic" | "off"),
## hints ("none" | "after_mistake" | "always": Rätsel-Hinweis auf den nächsten Stern).
## Nutzung: `var rules := Presets.effective("zen", {"time_limit_s": 1200})`, dann `Presets.apply(rules, night, weather)`.

const DIR := "res://data/presets"
const DEFAULT_ID := "standard"
const WEATHER_VALUES := ["normal", "cosmetic", "off"]
const HINT_VALUES := ["none", "after_mistake", "always"]
const TIME_MIN := 30.0
const TIME_MAX := 7200.0


## Alle gültigen Presets als {id: Dictionary(id, name, rules)}. Ungültige Dateien werden übersprungen (Warnung).
static func load_all(dir: String = DIR) -> Dictionary:
	var out := {}
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".json"):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
		var err := validate(d)
		if err != "":
			push_warning("Preset %s ungültig: %s" % [f, err])
			continue
		out[str(d["id"])] = d
	return out


## Leerer String = gültig, sonst Fehlertext.
static func validate(d: Variant) -> String:
	if not (d is Dictionary):
		return "kein Objekt"
	if str(d.get("id", "")) == "" or str(d.get("name", "")) == "":
		return "id/name fehlt"
	var r = d.get("rules")
	if not (r is Dictionary):
		return "rules fehlt"
	return check_rules(r)


static func check_rules(r: Dictionary) -> String:
	for k in ["time_limit_s", "weather", "hints"]:
		if not r.has(k):
			return "Regel fehlt: " + k
	if not (r["time_limit_s"] is float or r["time_limit_s"] is int) or float(r["time_limit_s"]) < TIME_MIN or float(r["time_limit_s"]) > TIME_MAX:
		return "time_limit_s außerhalb %d..%d" % [TIME_MIN, TIME_MAX]
	if not WEATHER_VALUES.has(r["weather"]):
		return "weather unbekannt"
	if not HINT_VALUES.has(r["hints"]):
		return "hints unbekannt"
	return ""


## Regeln eines Presets (unbekannte ID -> Standard), darüber die Slider-Werte. Ungültige Überschreibungen werden ignoriert.
static func effective(preset_id: String, overrides: Dictionary = {}, all: Dictionary = {}) -> Dictionary:
	if all.is_empty():
		all = load_all()
	var base: Dictionary = all.get(preset_id, all.get(DEFAULT_ID, {}))
	var rules: Dictionary = (base.get("rules", {}) as Dictionary).duplicate()
	for k in overrides:
		if not rules.has(k):
			continue
		var test := rules.duplicate()
		test[k] = overrides[k]
		if check_rules(test) == "":
			rules[k] = overrides[k]
	return rules


## Wendet Regeln auf laufende Teile an (lose gekoppelt, fehlt etwas, wird es übersprungen):
## night: `duration` (und `elapsed` bleibt), weather: `enabled` und `cosmetic`, hints: Rückgabe "hints" im Ergebnis.
## Gibt die tatsächlich angewendeten Regeln zurück.
static func apply(rules: Dictionary, night: Object = null, weather: Object = null) -> Dictionary:
	if check_rules(rules) != "":
		return {}
	if night != null and "duration" in night:
		night.duration = float(rules["time_limit_s"])
	if weather != null:
		if "enabled" in weather:
			weather.enabled = rules["weather"] != "off"
		if "cosmetic" in weather:
			weather.cosmetic = rules["weather"] == "cosmetic"
	return rules.duplicate()


## Soll nach einem Fehler / immer ein Hinweis gezeigt werden? (für Constellation-Nutzer)
static func hint_visible(rules: Dictionary, after_mistake: bool) -> bool:
	match rules.get("hints", "after_mistake"):
		"always":
			return true
		"after_mistake":
			return after_mistake
	return false
