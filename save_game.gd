class_name SaveGame
extends RefCounted
## G-27: Spielstand des Hosts als JSON unter user://saves/<Name>.json. Enthält: Seed, Sternzustand (entfernte Flecken je Stern),
## Staub, Shop-Stufen und Utensil, Nacht, XP/Fähigkeiten je Spielername. Reine Logik; Menü/Pause rufen nur save()/load_game()/list().
## 🟡 Die Anbindung an main.gd (Autosave am Nachtende, "Laden" starten) ist noch nicht verdrahtet – siehe PLAN.md.

const DIR := "user://saves"
const VERSION := 1

static var base_dir := DIR   # Tests dürfen umlenken


static func safe_name(n: String) -> String:
	var s := ""
	for c in n.strip_edges():
		s += c if (c.is_valid_identifier() or c in " -_" or (c >= "0" and c <= "9")) else "_"
	return s.substr(0, 40) if s != "" else "spielstand"


static func path_for(n: String) -> String:
	return base_dir.path_join(safe_name(n) + ".json")


## Spielerdaten (XP/Fähigkeiten) als einfaches Dictionary.
static func player_data(xp, skills) -> Dictionary:
	var d := {}
	if xp != null:
		d["xp"] = {"xp": xp.xp, "level": xp.level, "points": xp.points}
	if skills != null:
		d["skills"] = {"levels": skills.levels.duplicate(), "role": skills.role}
	return d


## Stellt den Spielstand aus den Teilen zusammen. `players`: Spielername -> {"xp": Xp, "skills": Skills} (beide optional).
static func capture(world, game_state, shop, players: Dictionary, night: int, seed_value: int = 7) -> Dictionary:
	var stars_state: Array = []
	for s in world.stars:
		stars_state.append((s.removed_ids as Array).duplicate())
	var pl := {}
	for pname in players:
		var e: Dictionary = players[pname]
		pl[str(pname)] = player_data(e.get("xp"), e.get("skills"))
	return {
		"version": VERSION, "seed": seed_value, "night": night, "dust": game_state.dust,
		"stars": stars_state,
		"shop": {"levels": shop.levels.duplicate(), "equipped": shop.equipped},
		"players": pl,
	}


## Schreibt den Spielstand. Gibt OK oder einen Fehlercode zurück.
static func save(n: String, data: Dictionary) -> int:
	DirAccess.make_dir_recursive_absolute(base_dir)
	var f := FileAccess.open(path_for(n), FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data, "  "))
	return OK


## Liest einen Spielstand; leeres Dictionary bei Fehler/ungültiger Datei.
static func load_game(n: String) -> Dictionary:
	if not FileAccess.file_exists(path_for(n)):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path_for(n)))
	if typeof(d) != TYPE_DICTIONARY or int(d.get("version", 0)) != VERSION or not d.has("stars"):
		return {}
	return d


## Namen aller Spielstände, neueste zuerst.
static func list() -> Array[String]:
	var found: Array = []
	var da := DirAccess.open(base_dir)
	if da == null:
		return []
	for fn in da.get_files():
		if fn.ends_with(".json"):
			found.append([FileAccess.get_modified_time(base_dir.path_join(fn)), fn.get_basename()])
	found.sort_custom(func(a, b): return a[0] > b[0])
	var out: Array[String] = []
	for e in found:
		out.append(e[1])
	return out


## Wendet den Spielstand an: Staub, Shop, Sterne (Flecken, die im Stand entfernt sind, werden entfernt). Gibt die Spielerdaten zurück.
## JSON macht aus Zahlen Floats, deshalb werden IDs/Stufen hier zurückgewandelt.
static func apply(data: Dictionary, world, game_state, shop) -> Dictionary:
	if data.is_empty():
		return {}
	if int(data.get("seed", 0)) != int(world.island_seed) and world.has_method("apply_seed"):
		world.apply_seed(int(data.get("seed", 0)))   # gleiche Insel wie beim Speichern
	game_state.dust = int(data.get("dust", 0))
	var sh: Dictionary = data.get("shop", {})
	shop.levels = {}
	for k in sh.get("levels", {}):
		shop.levels[k] = int(sh["levels"][k])
	shop.equipped = str(sh.get("equipped", "wedel"))
	var st: Array = data.get("stars", [])
	for i in mini(st.size(), world.stars.size()):
		var star = world.stars[i]
		star.apply_removed(st[i])
	return data.get("players", {})


## Gespeicherte XP/Fähigkeiten eines Spielernamens in Xp/Skills zurückschreiben.
static func restore_player(pdata: Dictionary, xp, skills) -> void:
	var x: Dictionary = pdata.get("xp", {})
	if xp != null and not x.is_empty():
		xp.xp = int(x.get("xp", 0))
		xp.level = int(x.get("level", 1))
		xp.points = int(x.get("points", 0))
	var s: Dictionary = pdata.get("skills", {})
	if skills != null and not s.is_empty():
		skills.levels = {}
		for k in s.get("levels", {}):
			skills.levels[k] = int(s["levels"][k])
		skills.role = str(s.get("role", skills.role))
