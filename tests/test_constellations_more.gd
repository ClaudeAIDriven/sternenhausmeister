extends SceneTree
## Test G-14: Alle Sternbild-Dateien laden und sind gültig; die fünf neuen haben 3 bis 7 Sterne, eindeutige IDs und Titel.
## Außerdem: bestehende Auswahl bleibt (3 Sterne = Dreieck, 5 = Kassiopeia, 7 = Kleiner Wagen).

func _initialize() -> void:
	var L = load("res://constellation_loader.gd")
	var all: Array = L.load_dir("res://data/constellations")
	var ok: bool = all.size() == 8
	var ids := {}
	var sizes := {}
	for d in all:
		ok = ok and L.validate(d) == "" and not ids.has(d["id"]) and str(d["name"]) != ""
		ids[d["id"]] = true
		var n: int = d["stars"].size()
		ok = ok and n >= 3 and n <= 7
		sizes[n] = int(sizes.get(n, 0)) + 1
		# Sterne dürfen sich nicht überlagern (mind. 0,5 Abstand)
		for i in n:
			for j in range(i + 1, n):
				var a: Array = d["stars"][i]["pos"]
				var b: Array = d["stars"][j]["pos"]
				ok = ok and Vector2(a[0], a[1]).distance_to(Vector2(b[0], b[1])) >= 0.5
	for k in ["pfeil", "kreuz_des_suedens", "leier", "schwan", "orion"]:
		ok = ok and ids.has(k)
	for n in [3, 4, 5, 6, 7]:
		ok = ok and sizes.has(n)
	# Auswahl in der Welt: größtes passendes, bei Gleichstand das alphabetisch erste (bestehendes Verhalten)
	for pair in [[3, "dreieck"], [4, "kreuz_des_suedens"], [5, "kassiopeia"], [6, "schwan"], [7, "kleiner_wagen"]]:
		var best: Dictionary = {}
		for d in all:
			var n: int = d["stars"].size()
			if n <= pair[0] and (best.is_empty() or n > best["stars"].size()):
				best = d
		ok = ok and best["id"] == pair[1]
	print("TEST_CONSTELLATIONS_MORE OK" if ok else "TEST_CONSTELLATIONS_MORE FAIL")
	quit(0 if ok else 1)
