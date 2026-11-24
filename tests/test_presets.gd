extends SceneTree
## Test G-09: Presets laden, Regeln ändern nachweislich Nacht und Wetter, Slider überschreiben, Ungültiges wird abgelehnt.

class FakeWeather:
	extends RefCounted
	var enabled := true
	var cosmetic := false

var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var all := Presets.load_all()
	ok = ok and all.size() == 3 and all.has("standard") and all.has("zen") and all.has("kinder")
	var night = load("res://night.gd").new()
	var w := FakeWeather.new()
	# Standard
	Presets.apply(Presets.effective("standard", {}, all), night, w)
	ok = ok and night.duration == 600.0 and w.enabled and not w.cosmetic
	# Zen: längeres Limit, Wetter nur kosmetisch
	var zen := Presets.apply(Presets.effective("zen", {}, all), night, w)
	ok = ok and night.duration == 1800.0 and w.enabled and w.cosmetic and zen["hints"] == "always"
	# Kinder: Wetter aus
	Presets.apply(Presets.effective("kinder", {}, all), night, w)
	ok = ok and night.duration == 900.0 and not w.enabled
	# Slider überschreibt Preset; ungültiger Slider-Wert wird ignoriert
	var r := Presets.effective("zen", {"time_limit_s": 1200}, all)
	ok = ok and r["time_limit_s"] == 1200 and r["weather"] == "cosmetic"
	var bad := Presets.effective("zen", {"time_limit_s": 5, "weather": "sturm", "unbekannt": 1}, all)
	ok = ok and bad["time_limit_s"] == 1800 and bad["weather"] == "cosmetic" and not bad.has("unbekannt")
	# Unbekanntes Preset -> Standard
	ok = ok and Presets.effective("gibtsnicht", {}, all)["time_limit_s"] == 600
	# Validierung
	ok = ok and Presets.validate({"id": "x", "name": "X", "rules": {"time_limit_s": 600, "weather": "normal"}}) != ""
	ok = ok and Presets.validate(5) != ""
	# Hinweise
	ok = ok and Presets.hint_visible(zen, false) and not Presets.hint_visible({"hints": "none"}, true)
	ok = ok and Presets.hint_visible({"hints": "after_mistake"}, true) and not Presets.hint_visible({"hints": "after_mistake"}, false)
	night.free()
	print("TEST_PRESETS OK" if ok else "TEST_PRESETS FAIL")
	quit(0 if ok else 1)
	return true
