class_name Achievements
extends RefCounted
## M-09: 20 Erfolge, Hut-Belohnungen und das Putz-Tagebuch (eine Zeile je Nacht). Zähler sind lokal je Spieler und liegen in
## user://profile_achievements.json (Pfad für Tests änderbar). Quellen rufen `count(event, n)` bzw. `set_max(event, n)`.

signal unlocked(id: String, title: String, hat: String)

const FILE := "user://profile_achievements.json"

## id, Titel, Ereignis, Schwelle, Hut-Belohnung ("" = keine)
const DEFS := [
	["erste_schritte", "Erste Schritte: 10 Flecken geputzt", "spot", 10, ""],
	["fleissig", "Fleißig: 500 Flecken", "spot", 500, "zylinder"],
	["putzteufel", "Putzteufel: 5000 Flecken", "spot", 5000, "krone"],
	["erster_stern", "Erster Stern geputzt", "star", 1, ""],
	["sternfreund", "Sternfreund: 25 Sterne", "star", 25, "sternmuetze"],
	["himmelsputzer", "Himmelsputzer: 100 Sterne", "star", 100, ""],
	["wollmausjaeger", "Wollmausjäger: 10 Wollmäuse", "wollmaus", 10, ""],
	["spinnenfresser", "Spinnenfresser: 5 Spinnen", "spinne", 5, "schleife"],
	["bosskiller", "Rußwolke besiegt", "russwolke", 1, "zylinder"],
	["boss_serie", "Rußwolken-Schreck: 5 Siege", "russwolke", 5, ""],
	["koch", "Hobbykoch: 5 Gerichte", "cook", 5, "kochmuetze"],
	["sternekoch", "Sternekoch: 30 Gerichte", "cook", 30, ""],
	["sammler", "Sammler: 25 Früchte", "fruit", 25, ""],
	["obsthain", "Obsthain: 100 Früchte", "fruit", 100, "schleife"],
	["sternbild", "Sternbild gelöst", "constellation", 1, ""],
	["astronom", "Astronom: 5 Sternbilder", "constellation", 5, "sternmuetze"],
	["retter", "Retter: 3 Mitspieler wiederbelebt", "revive", 3, ""],
	["nachtwache", "Nachtwache: 3 Nächte überstanden", "night", 3, ""],
	["wunschkind", "Wunschkind: 3 Wünsche gefangen", "wish", 3, ""],
	["reicher_staub", "Staubkönig: 5000 Staub auf einmal", "dust_max", 5000, "krone"],
]

var counts := {}            # Ereignis -> Zähler
var done := {}              # Erfolgs-ID -> true
var hats: Array[String] = []   # freigeschaltete Hüte
var diary: Array = []       # je Nacht: {"night", "stars", "dust", "spots"}
var path := FILE


static func find(id: String) -> Array:
	for d in DEFS:
		if d[0] == id:
			return d
	return []


## Zählt ein Ereignis hoch und prüft Erfolge. Gibt die frisch freigeschalteten IDs zurück.
func count(event: String, n: int = 1) -> Array[String]:
	counts[event] = int(counts.get(event, 0)) + n
	return _check(event)


## Wie count, aber für Höchstwerte (z. B. Staub auf einmal).
func set_max(event: String, value: int) -> Array[String]:
	if value > int(counts.get(event, 0)):
		counts[event] = value
		return _check(event)
	return []


func _check(event: String) -> Array[String]:
	var fresh: Array[String] = []
	for d in DEFS:
		if d[2] == event and not done.has(d[0]) and int(counts.get(event, 0)) >= int(d[3]):
			done[d[0]] = true
			if d[4] != "" and not hats.has(d[4]):
				hats.append(d[4])
			fresh.append(d[0])
			unlocked.emit(d[0], d[1], d[4])
	if not fresh.is_empty():
		save()
	return fresh


## Nacht abschließen: Tagebuchzeile + Ereignis "night".
func record_night(night: int, stars: int, dust: int, spots: int) -> void:
	diary.append({"night": night, "stars": stars, "dust": dust, "spots": spots})
	if diary.size() > 100:
		diary = diary.slice(diary.size() - 100)
	count("night", 1)
	save()


func diary_text(last: int = 5) -> String:
	var lines: Array[String] = []
	for e in diary.slice(maxi(0, diary.size() - last)):
		lines.append("Nacht %d: %d Sterne, %d Staub, %d Flecken" % [int(e["night"]), int(e["stars"]), int(e["dust"]), int(e["spots"])])
	return "\n".join(lines)


func progress_text() -> String:
	return "%d / %d Erfolge · %d Hüte" % [done.size(), DEFS.size(), hats.size()]


func to_dict() -> Dictionary:
	return {"counts": counts, "done": done, "hats": hats, "diary": diary}


func from_dict(d: Dictionary) -> void:
	counts = {}
	for k in d.get("counts", {}):
		counts[k] = int(d["counts"][k])
	done = {}
	for k in d.get("done", {}):
		done[k] = true
	hats = []
	for h in d.get("hats", []):
		hats.append(str(h))
	diary = d.get("diary", [])


func save() -> int:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(to_dict()))
	return OK


func load_file() -> bool:
	if not FileAccess.file_exists(path):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY:
		return false
	from_dict(d)
	return true
