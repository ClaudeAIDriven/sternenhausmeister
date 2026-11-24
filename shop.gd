class_name Shop
extends Node
## Werkstatt-Shop (G-05): Upgrades für Wedelgröße, Lauftempo und Reichweite, bezahlt mit Sternenstaub (GameState.dust).
## Preise und Werte stehen als Daten in data/upgrades.json. Online entscheidet der Host: Clients fragen per `request_buy`,
## der Host bucht den Staub ab und verteilt die Stufen an alle. (Staub selbst verteilt GameState/Host, nicht dieser Shop.)
## Benutzung: Knoten "Shop" ins Spiel hängen; Spieler/Main lesen `value("wipe_radius" | "speed" | "reach")`.

signal purchased(id: String, level: int)
signal levels_changed

const DATA_PATH := "res://data/upgrades.json"

var stats_base := {}       # Stat -> Grundwert
var upgrades: Array = []   # Einträge aus der JSON-Datei
var levels := {}           # Upgrade-ID -> aktuelle Stufe


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
	levels = {}
	for u in upgrades:
		levels[u["id"]] = 0
	return ""


func _find(id: String) -> Dictionary:
	for u in upgrades:
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
	return c > 0 and GameState.dust >= c


## Aktueller Wert eines Stats (Grundwert plus Stufen aller Upgrades dafür).
func value(stat: String) -> float:
	var v: float = float(stats_base.get(stat, 0.0))
	for u in upgrades:
		if u["stat"] == stat:
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
	return true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_buy(id: String) -> void:
	if multiplayer.is_server():
		_buy_authoritative(id)


@rpc("authority", "call_remote", "reliable")
func _rpc_levels(l: Dictionary) -> void:
	levels = l
	levels_changed.emit()


## Nachzügler: Host schickt den Stand.
func send_state_to(peer: int) -> void:
	if multiplayer.is_server():
		_rpc_levels.rpc_id(peer, levels)
