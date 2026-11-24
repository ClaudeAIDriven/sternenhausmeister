class_name Shop
extends Node
## Werkstatt-Shop (G-05): Upgrades für Wedelgröße, Lauftempo und Reichweite, bezahlt mit Sternenstaub (GameState.dust).
## Preise und Werte stehen als Daten in data/upgrades.json. Online entscheidet der Host: Clients fragen per `request_buy`,
## der Host bucht den Staub ab und verteilt die Stufen an alle. (Staub selbst verteilt GameState/Host, nicht dieser Shop.)
## Benutzung: Knoten "Shop" ins Spiel hängen; Spieler/Main lesen `value("wipe_radius" | "speed" | "reach")`.

signal purchased(id: String, level: int)
signal levels_changed
signal equipped_changed(id: String)

const DATA_PATH := "res://data/upgrades.json"

var stats_base := {}       # Stat -> Grundwert
var upgrades: Array = []   # Einträge aus der JSON-Datei
var levels := {}           # Upgrade-ID -> aktuelle Stufe (Utensilien: "u_<id>" = 1, wenn gekauft)
## G-25: Putz-Utensilien nacheinander (Wedel -> ... -> Sternpolierer). Jedes hat 3 eigene Upgrades (Breite, Tempo, Reichweite).
var utensils: Array = []         # Einträge der Utensilien (aus JSON)
var utensil_upgrades: Array = [] # daraus erzeugt: "<id>_width|_tempo|_reach"
var equipped := "wedel"          # nur lokal: welches Utensil dieser Spieler in der Hand hält


func _init() -> void:
	name = "Shop"   # fester Name: RPC-Pfad muss bei allen Spielern gleich sein
	load_data()


## Lädt und prüft die Daten. Gibt "" bei Erfolg, sonst eine Fehlermeldung.
func load_data(path: String = DATA_PATH) -> String:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (d is Dictionary) or not d.has("stats") or not d.has("upgrades"):
		return "upgrades.json ungültig"
	var seen := {}
	for u in d["upgrades"]:
		for k in ["id", "name", "stat", "per_level", "max_level", "base_cost", "cost_growth"]:
			if not u.has(k):
				return "Upgrade ohne Feld " + k
		if seen.has(u["id"]) or not d["stats"].has(u["stat"]) or float(u["base_cost"]) <= 0.0:
			return "Upgrade fehlerhaft: " + str(u["id"])
		seen[u["id"]] = true
	stats_base = d["stats"]
	upgrades = d["upgrades"]
	utensils = []
	utensil_upgrades = []
	var prev := ""
	for ut in d.get("utensils", []):
		for k in ["id", "name", "price", "tool_kind", "model"]:
			if not ut.has(k):
				return "Utensil ohne Feld " + k
		var uid := "u_" + str(ut["id"])
		var item: Dictionary = ut.duplicate(true)
		item["item_id"] = uid
		item["requires"] = prev
		utensils.append(item)
		if float(ut["price"]) > 0.0:
			for part in [["width", "wipe_radius", "Breite"], ["tempo", "wipe_rate", "Tempo"], ["reach", "reach", "Reichweite"]]:
				if not ut.has(part[0]):
					return "Utensil ohne Upgrade " + part[0]
				utensil_upgrades.append({"id": "%s_%s" % [ut["id"], part[0]], "name": "%s: %s" % [ut["name"], part[2]],
					"desc": "Nur mit diesem Utensil in der Hand.", "stat": part[1], "per_level": float(ut[part[0]]), "max_level": 3,
					"base_cost": maxf(float(ut["price"]) * 0.25, 1.0), "cost_growth": 1.6, "utensil": str(ut["id"]), "requires": uid})
		prev = uid
	levels = {}
	for u in _all():
		levels[u["id"]] = 0
	levels["u_wedel"] = 1
	equipped = "wedel"
	return ""


## Alle kaufbaren Einträge: die drei allgemeinen Upgrades, Utensilien (als Einträge "u_<id>", Stufe 1 = gekauft) und deren Upgrades.
func _all() -> Array:
	var out: Array = []
	out.append_array(upgrades)
	for ut in utensils:
		out.append({"id": ut["item_id"], "name": ut["name"], "desc": ut.get("desc", ""), "stat": "", "per_level": 0.0, "max_level": 1,
			"base_cost": maxf(float(ut["price"]), 1.0), "cost_growth": 1.0, "requires": ut["requires"], "utensil_item": str(ut["id"])})
	out.append_array(utensil_upgrades)
	return out


func _find(id: String) -> Dictionary:
	for u in _all():
		if u["id"] == id:
			return u
	return {}


func level(id: String) -> int:
	return int(levels.get(id, 0))


func is_maxed(id: String) -> bool:
	var u := _find(id)
	return u.is_empty() or level(id) >= int(u["max_level"])


## Preis der nächsten Stufe (-1 wenn ausgereizt oder unbekannt).
func cost(id: String) -> int:
	var u := _find(id)
	if u.is_empty() or is_maxed(id):
		return -1
	return int(round(float(u["base_cost"]) * pow(float(u["cost_growth"]), level(id))))


func can_buy(id: String) -> bool:
	var c := cost(id)
	if c <= 0 or GameState.dust < c:
		return false
	var req: String = str(_find(id).get("requires", ""))
	return req == "" or level(req) > 0   # Utensilien nacheinander, Upgrades erst nach dem Utensil


func owns(utensil_id: String) -> bool:
	return level("u_" + utensil_id) > 0


## Ausrüsten (nur lokal). Gibt false zurück, wenn unbekannt oder nicht gekauft.
func equip(utensil_id: String) -> bool:
	if _utensil(utensil_id).is_empty() or not owns(utensil_id):
		return false
	equipped = utensil_id
	equipped_changed.emit(utensil_id)
	levels_changed.emit()
	return true


func _utensil(utensil_id: String) -> Dictionary:
	for ut in utensils:
		if ut["id"] == utensil_id:
			return ut
	return {}


## Daten des ausgerüsteten Utensils (leer, wenn keine definiert sind).
func equipped_utensil() -> Dictionary:
	return _utensil(equipped)


## Besondere Fähigkeit des ausgerüsteten Utensils ("spiders" = Staubsauger, "tough" = Dampfreiniger) vorhanden?
func has_ability(special: String) -> bool:
	return str(equipped_utensil().get("special", "")) == special


## Aktueller Wert eines Stats (Grundwert plus Stufen aller Upgrades dafür).
func value(stat: String) -> float:
	var v: float = float(stats_base.get(stat, 0.0))
	for u in upgrades:
		if u["stat"] == stat:
			v += float(u["per_level"]) * level(u["id"])
	var ut := equipped_utensil()   # G-25: Grundwerte und Upgrades des Utensils in der Hand
	if not ut.is_empty():
		v += float(ut.get("bonus", {}).get(stat, 0.0))
		for u in utensil_upgrades:
			if u["stat"] == stat and u["utensil"] == equipped:
				v += float(u["per_level"]) * level(u["id"])
	return v


## Kauf versuchen. Online fragt der Client den Host (Rückgabe false = noch unbestätigt).
func request_buy(id: String) -> bool:
	if NetworkManager.is_online() and not multiplayer.is_server():
		_rpc_buy.rpc_id(1, id)
		return false
	return _buy_authoritative(id)


func _buy_authoritative(id: String) -> bool:
	if not can_buy(id):
		return false
	var c := cost(id)
	if not GameState.spend_dust(c):
		return false
	levels[id] = level(id) + 1
	purchased.emit(id, levels[id])
	levels_changed.emit()
	if NetworkManager.is_online():
		_rpc_levels.rpc(levels)
		_rpc_spent.rpc(c)   # I-10: auch die anderen buchen den Preis ab (Staub wird bei allen gleich mitgezählt)
	return true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_buy(id: String) -> void:
	if multiplayer.is_server():
		_buy_authoritative(id)


@rpc("authority", "call_remote", "reliable")
func _rpc_spent(amount: int) -> void:
	if amount > 0 and amount <= 100000:
		GameState.spend_dust(amount)


@rpc("authority", "call_remote", "reliable")
func _rpc_levels(l: Dictionary) -> void:
	levels = l
	levels_changed.emit()


## Nachzügler: Host schickt den Stand.
func send_state_to(peer: int) -> void:
	if multiplayer.is_server():
		_rpc_levels.rpc_id(peer, levels)
