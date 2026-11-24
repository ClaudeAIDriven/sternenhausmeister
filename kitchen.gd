class_name Kitchen
extends Node3D
## G-23: Die Küche (Lagerfeuer mit Topf). Rezepte stehen in data/recipes.json: Zutaten (Früchte aus dem Beutel, G-22)
## werden verbraucht, das Gericht füllt die Sättigung (Food, G-21) und gibt einen Zeit-Buff.
## Buffs: `buff_mult("wipe" | "speed" | "jump")` liefert den aktuellen Faktor (1.0 = kein Buff). Wer ihn nutzt (Player/main),
## multipliziert damit; `tick(delta)` muss laufen (macht _process). Kochen passiert lokal im eigenen Beutel, ohne Netzwerk.

signal cooked(recipe_id: String)
signal buffs_changed

const DATA_PATH := "res://data/recipes.json"
const KITCHEN_POS := Vector3(8, 0, -14)
const RANGE := 5.0

var recipes: Array = []
var buffs := {}   # Stat -> {"mult": float, "left": float, "label": String}


func _init() -> void:
	name = "Kitchen"
	load_data()


## Lädt und prüft die Rezepte. Gibt "" bei Erfolg, sonst eine Fehlermeldung.
func load_data(path: String = DATA_PATH) -> String:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (d is Dictionary) or not d.has("recipes"):
		return "recipes.json ungültig"
	var seen := {}
	for r in d["recipes"]:
		for k in ["id", "name", "ingredients", "food", "buff"]:
			if not r.has(k):
				return "Rezept ohne Feld " + k
		if seen.has(r["id"]) or not (r["ingredients"] is Dictionary) or r["ingredients"].is_empty():
			return "Rezept fehlerhaft: " + str(r["id"])
		for kind in r["ingredients"]:
			if not Fruit.KINDS.has(kind) or int(r["ingredients"][kind]) < 1:
				return "Unbekannte Zutat in " + str(r["id"])
		var b: Dictionary = r["buff"]
		if not ["wipe", "speed", "jump"].has(str(b.get("stat", ""))) or float(b.get("mult", 0.0)) <= 1.0 or float(b.get("seconds", 0.0)) <= 0.0:
			return "Buff fehlerhaft in " + str(r["id"])
		seen[r["id"]] = true
	recipes = d["recipes"]
	return ""


func recipe(id: String) -> Dictionary:
	for r in recipes:
		if r["id"] == id:
			return r
	return {}


## Genug Zutaten im Beutel?
func can_cook(id: String, inv: Inventory) -> bool:
	var r := recipe(id)
	if r.is_empty() or inv == null:
		return false
	for kind in r["ingredients"]:
		if inv.items.count(kind) < int(r["ingredients"][kind]):
			return false
	return true


## Kocht: verbraucht die Zutaten, füllt die Sättigung, setzt den Buff. false, wenn Zutaten fehlen.
func cook(id: String, inv: Inventory, food: Food, role: String = "") -> bool:
	if not can_cook(id, inv):
		return false
	var r := recipe(id)
	for kind in r["ingredients"]:
		for i in int(r["ingredients"][kind]):
			inv.items.erase(kind)
	inv.changed.emit()
	if food != null:
		food.feed(float(r["food"]) * Roles.factor(role, "recipe_food"))
	var b: Dictionary = r["buff"]
	var stat := str(b["stat"])
	var cur: Dictionary = buffs.get(stat, {})
	if cur.is_empty() or float(b["mult"]) >= float(cur["mult"]):   # stärkerer Buff ersetzt, gleich starker erneuert die Zeit
		buffs[stat] = {"mult": float(b["mult"]), "left": float(b["seconds"]) * Roles.factor(role, "buff_time"), "label": str(b.get("label", stat))}
	else:
		cur["left"] = maxf(float(cur["left"]), float(b["seconds"]) * Roles.factor(role, "buff_time"))
	buffs_changed.emit()
	cooked.emit(id)
	return true


func buff_mult(stat: String) -> float:
	return float(buffs.get(stat, {}).get("mult", 1.0))


func tick(delta: float) -> void:
	var changed := false
	for stat in buffs.keys():
		buffs[stat]["left"] = float(buffs[stat]["left"]) - delta
		if float(buffs[stat]["left"]) <= 0.0:
			buffs.erase(stat)
			changed = true
	if changed:
		buffs_changed.emit()


func is_near(pos: Vector3) -> bool:
	return Vector2(pos.x - global_position.x, pos.z - global_position.z).length() <= RANGE


func _process(delta: float) -> void:
	tick(delta)
	if _flame != null:
		_flame.light_energy = 1.4 + sin(Time.get_ticks_msec() / 1000.0 * 11.0) * 0.25


var _flame: OmniLight3D


func _ready() -> void:
	if position == Vector3.ZERO:
		position = KITCHEN_POS
	_build_model()


## Lagerfeuer mit Topf: Steinring, Holzscheite, Flammen (leuchten), Topf auf Dreibein.
func _build_model() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.45, 0.45, 0.5)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.4, 0.26, 0.15)
	var fire := StandardMaterial3D.new()
	fire.albedo_color = Color(1.0, 0.55, 0.15)
	fire.emission_enabled = true
	fire.emission = Color(1.0, 0.5, 0.1)
	fire.emission_energy_multiplier = 2.0
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.12, 0.12, 0.15)
	for i in 8:
		var a := i * TAU / 8.0
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.22
		sm.height = 0.34
		s.mesh = sm
		s.material_override = stone
		s.position = Vector3(cos(a) * 0.95, 0.12, sin(a) * 0.95)
		add_child(s)
	for i in 3:
		var l := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.08
		cm.bottom_radius = 0.08
		cm.height = 1.0
		l.mesh = cm
		l.material_override = wood
		l.position = Vector3(0, 0.18, 0)
		l.rotation = Vector3(0, i * TAU / 3.0, PI * 0.5)
		add_child(l)
	var flame := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.0
	fm.bottom_radius = 0.3
	fm.height = 0.8
	flame.mesh = fm
	flame.material_override = fire
	flame.position = Vector3(0, 0.55, 0)
	add_child(flame)
	var pot := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.42
	pm.bottom_radius = 0.34
	pm.height = 0.5
	pot.mesh = pm
	pot.material_override = iron
	pot.position = Vector3(0, 1.25, 0)
	add_child(pot)
	for i in 3:
		var leg := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.03
		lm.bottom_radius = 0.03
		lm.height = 1.2
		leg.mesh = lm
		leg.material_override = iron
		var a2 := i * TAU / 3.0
		leg.position = Vector3(cos(a2) * 0.4, 0.62, sin(a2) * 0.4)
		leg.rotation = Vector3(-sin(a2) * 0.25, 0, cos(a2) * 0.25)
		add_child(leg)
	_flame = OmniLight3D.new()
	_flame.light_color = Color(1.0, 0.6, 0.25)
	_flame.omni_range = 9.0
	_flame.position = Vector3(0, 1.0, 0)
	add_child(_flame)
