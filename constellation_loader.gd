class_name ConstellationLoader
extends RefCounted
## Lädt und prüft Sternbild-Dateien (data/constellations/*.json).
## Format: {"id","name","stars":[{"id":int,"pos":[x,y]}],"order":[Stern-IDs in Putzreihenfolge]}


## Gibt "" zurück, wenn gültig, sonst eine Fehlermeldung.
static func validate(d: Dictionary) -> String:
	for key in ["id", "name", "stars", "order"]:
		if not d.has(key):
			return "Feld fehlt: " + key
	if not (d["stars"] is Array) or d["stars"].size() < 3:
		return "Mindestens 3 Sterne nötig"
	var ids := {}
	for s in d["stars"]:
		if not (s is Dictionary) or not s.has("id") or not s.has("pos") or s["pos"].size() != 2:
			return "Stern ohne id oder pos [x,y]"
		if ids.has(int(s["id"])):
			return "Doppelte Stern-ID: %d" % int(s["id"])
		ids[int(s["id"])] = true
	if d["order"].size() != ids.size():
		return "Reihenfolge muss jeden Stern genau einmal enthalten"
	var seen := {}
	for o in d["order"]:
		if not ids.has(int(o)) or seen.has(int(o)):
			return "Reihenfolge enthält unbekannte oder doppelte ID: %d" % int(o)
		seen[int(o)] = true
	return ""


## Lädt alle gültigen Dateien eines Ordners. Ungültige werden gemeldet und übersprungen.
static func load_dir(dir_path: String = "res://data/constellations") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("Ordner nicht lesbar: " + dir_path)
		return result
	var files := Array(dir.get_files())
	files.sort()
	for f in files:
		if not f.ends_with(".json"):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(dir_path + "/" + f))
		if data is Dictionary:
			var err := validate(data)
			if err == "":
				result.append(data)
				continue
			push_warning("%s: %s" % [f, err])
		else:
			push_warning("%s: kein gültiges JSON" % f)
	return result
