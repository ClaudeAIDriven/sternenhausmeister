class_name Skills
extends RefCounted
## G-26: Fähigkeitsbaum aus data/skills.json. Allgemeine Fähigkeiten (role "") und je Rolle drei eigene. Jede Stufe kostet einen
## Punkt (Xp). Wirkung über `mult(stat)` / `add(stat)` / `apply(stat, base)`; wer sie nutzt (Player, Küche, Beutel), ruft das ab.
## Stats: hunger, regen, bag_slots, dust_gain, reach, fall_damage, double_jump, jump_cd, wipe, spider_fear, wipe_rate, speed,
## recipe_food, buff_time, climb, ladder_time, ladder_cd.

signal changed

const DATA_PATH := "res://data/skills.json"

var list: Array = []
var levels := {}        # Fähigkeit -> Stufe
var role := "allrounder"
var xp: Xp


func _init(experience: Xp = null, role_id: String = "allrounder") -> void:
	xp = experience if experience != null else Xp.new()
	role = role_id
	load_data()


func load_data(path: String = DATA_PATH) -> String:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (d is Dictionary) or not d.has("skills"):
		return "skills.json ungültig"
	var seen := {}
	for s in d["skills"]:
		for k in ["id", "name", "desc", "role", "max_level", "effect"]:
			if not s.has(k):
				return "Fähigkeit ohne Feld " + k
		var e: Dictionary = s["effect"]
		if seen.has(s["id"]) or int(s["max_level"]) < 1 or not e.has("stat") or not (e.has("mult") or e.has("add")):
			return "Fähigkeit fehlerhaft: " + str(s["id"])
		if str(s["role"]) != "" and not Roles.ALL.has(str(s["role"])):
			return "Unbekannte Rolle: " + str(s["role"])
		seen[s["id"]] = true
	list = d["skills"]
	levels = {}
	return ""


func skill(id: String) -> Dictionary:
	for s in list:
		if s["id"] == id:
			return s
	return {}


func level(id: String) -> int:
	return int(levels.get(id, 0))


## Gehört die Fähigkeit zum Baum dieses Spielers (allgemein oder eigene Rolle)?
func available(id: String) -> bool:
	var s := skill(id)
	return not s.is_empty() and (str(s["role"]) == "" or str(s["role"]) == role)


func can_learn(id: String) -> bool:
	return available(id) and level(id) < int(skill(id)["max_level"]) and xp.points > 0


## Eine Stufe lernen (kostet einen Punkt).
func learn(id: String) -> bool:
	if not can_learn(id) or not xp.spend_point():
		return false
	levels[id] = level(id) + 1
	changed.emit()
	return true


## Produkt aller Faktoren (mult-Effekte, je Stufe potenziert) für einen Stat; 1.0 = keine Wirkung.
func mult(stat: String) -> float:
	var m := 1.0
	for s in list:
		if s["effect"]["stat"] == stat and s["effect"].has("mult") and available(s["id"]):
			m *= pow(float(s["effect"]["mult"]), level(s["id"]))
	return m


## Summe aller Zuschläge (add-Effekte) für einen Stat.
func add(stat: String) -> float:
	var a := 0.0
	for s in list:
		if s["effect"]["stat"] == stat and s["effect"].has("add") and available(s["id"]):
			a += float(s["effect"]["add"]) * level(s["id"])
	return a


func apply(stat: String, base: float) -> float:
	return base * mult(stat) + add(stat)
