extends SceneTree
## Test G-02: Beispiel-Sternbilder laden und Validierung prüfen.

func _initialize() -> void:
	var L = load("res://constellation_loader.gd")
	var all: Array = L.load_dir("res://data/constellations")
	var ok: bool = all.size() == 8
	for d in all:
		ok = ok and L.validate(d) == ""
	var bad := {"id": "x", "name": "X", "stars": [{"id": 0, "pos": [0, 0]}, {"id": 1, "pos": [1, 0]}, {"id": 1, "pos": [2, 0]}], "order": [0, 1, 1]}
	ok = ok and L.validate(bad) != ""
	var bad2 := {"id": "y", "name": "Y", "stars": [{"id": 0, "pos": [0, 0]}, {"id": 1, "pos": [1, 0]}, {"id": 2, "pos": [2, 0]}], "order": [0, 1, 5]}
	ok = ok and L.validate(bad2) != ""
	ok = ok and L.validate({"id": "z"}) != ""
	print("TEST_CONSTELLATIONS OK" if ok else "TEST_CONSTELLATIONS FAIL (%d geladen)" % all.size())
	quit(0 if ok else 1)
