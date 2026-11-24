class_name Poi
extends Node3D
## G-30: Orte mit Vorteilen. Wirkung nur für den eigenen Spieler (jeder Peer wendet sie lokal an).
##  brunnen: heilt HEAL_PER_SECOND je Sekunde in Reichweite · obstgarten: viele Früchte (legt World an) ·
##  turm: zeigt Gegner auf der Minimap, solange man oben steht · schrein: F aktiviert 60 s Wischradius x1,25 (Abklingzeit 120 s) ·
##  kueche: das Kitchen-Objekt der Welt (nur Minimap-Symbol/Ort).
## Auf der Minimap erscheinen alle Orte mit Symbol (Gruppe "pois", `map_color`/`map_shape`).

const KINDS := {
	"brunnen": {"name": "Brunnen", "color": Color(0.4, 0.7, 1.0), "shape": "circle", "range": 4.0},
	"obstgarten": {"name": "Obstgarten", "color": Color(0.95, 0.55, 0.2), "shape": "square", "range": 7.0},
	"turm": {"name": "Aussichtsturm", "color": Color(0.8, 0.8, 0.85), "shape": "triangle", "range": 3.0},
	"schrein": {"name": "Sternenschrein", "color": Color(1.0, 0.85, 0.3), "shape": "diamond", "range": 3.5},
	"kueche": {"name": "Küche", "color": Color(0.9, 0.3, 0.25), "shape": "square", "range": 5.0},
}
const HEAL_PER_SECOND := 2.0
const SHRINE_SECONDS := 60.0
const SHRINE_COOLDOWN := 120.0
const SHRINE_WIPE := 1.25

## Gemeinsamer lokaler Zustand (ein Spieler pro Programm).
static var tower_active := false     # Minimap zeigt Gegner
static var shrine_left := 0.0        # Restzeit des Schrein-Buffs
static var shrine_cd := 0.0

@export var kind := "brunnen"
var _ready_done := false


static func reset_state() -> void:
	tower_active = false
	shrine_left = 0.0
	shrine_cd = 0.0


## Buff-Faktor aus dem Schrein (1.0 = kein Buff). Gleiche Schnittstelle wie Kitchen.buff_mult.
static func buff_mult(stat: String) -> float:
	return SHRINE_WIPE if stat == "wipe" and shrine_left > 0.0 else 1.0


func reach() -> float:
	return float(KINDS[kind]["range"])


func map_color() -> Color:
	return KINDS[kind]["color"]


func map_shape() -> String:
	return KINDS[kind]["shape"]


func is_near(pos: Vector3) -> bool:
	return Vector2(pos.x - global_position.x, pos.z - global_position.z).length() <= reach()


## Wirkung auf den lokalen Spieler für einen Zeitschritt.
func local_tick(player: Player, delta: float) -> void:
	var near := player != null and is_near(player.global_position)
	match kind:
		"brunnen":
			if near and not player.downed and player.health < Player.MAX_HEALTH:
				player.health = minf(player.health + HEAL_PER_SECOND * delta, Player.MAX_HEALTH)
				player.health_changed.emit(player.health)
		"turm":
			tower_active = near
		"schrein":
			shrine_left = maxf(shrine_left - delta, 0.0)
			shrine_cd = maxf(shrine_cd - delta, 0.0)


## Schrein aktivieren (F in der Nähe). false = zu weit, noch Abklingzeit oder kein Schrein.
func activate(player: Player) -> bool:
	if kind != "schrein" or player == null or not is_near(player.global_position) or shrine_cd > 0.0:
		return false
	shrine_left = SHRINE_SECONDS
	shrine_cd = SHRINE_COOLDOWN
	return true


func _ready() -> void:
	add_to_group("pois")
	_build_model()


func _process(delta: float) -> void:
	for n in get_tree().get_nodes_in_group("players"):
		var p := n as Player
		if p != null and p.is_multiplayer_authority():
			local_tick(p, delta)
			return


func _unhandled_input(event: InputEvent) -> void:
	if kind == "schrein" and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		for n in get_tree().get_nodes_in_group("players"):
			var p := n as Player
			if p != null and p.is_multiplayer_authority():
				activate(p)
				return


func _mat(c: Color, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if glow:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.5
	return m


func _add(mesh: Mesh, mat: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func _build_model() -> void:
	var stone := _mat(Color(0.5, 0.5, 0.55))
	match kind:
		"brunnen":
			var ring := CylinderMesh.new()
			ring.top_radius = 1.1
			ring.bottom_radius = 1.2
			ring.height = 0.7
			_add(ring, stone, Vector3(0, 0.35, 0))
			var water := CylinderMesh.new()
			water.top_radius = 0.95
			water.bottom_radius = 0.95
			water.height = 0.05
			_add(water, _mat(Color(0.3, 0.6, 0.95), true), Vector3(0, 0.66, 0))
		"obstgarten":
			for i in 5:   # kleine Bäume im Kreis
				var a := i * TAU / 5.0
				var trunk := CylinderMesh.new()
				trunk.top_radius = 0.15
				trunk.bottom_radius = 0.2
				trunk.height = 1.4
				_add(trunk, _mat(Color(0.4, 0.27, 0.15)), Vector3(cos(a) * 4.0, 0.7, sin(a) * 4.0))
				var crown := SphereMesh.new()
				crown.radius = 0.9
				crown.height = 1.4
				_add(crown, _mat(Color(0.25, 0.55, 0.3)), Vector3(cos(a) * 4.0, 1.9, sin(a) * 4.0))
		"turm":
			var t := CylinderMesh.new()
			t.top_radius = 0.9
			t.bottom_radius = 1.2
			t.height = 6.0
			_add(t, stone, Vector3(0, 3.0, 0))
			var roof := CylinderMesh.new()
			roof.top_radius = 0.0
			roof.bottom_radius = 1.3
			roof.height = 1.2
			_add(roof, _mat(Color(0.7, 0.3, 0.3)), Vector3(0, 6.6, 0))
		"schrein":
			var base := CylinderMesh.new()
			base.top_radius = 0.7
			base.bottom_radius = 0.9
			base.height = 0.5
			_add(base, stone, Vector3(0, 0.25, 0))
			var star := SphereMesh.new()
			star.radius = 0.3
			star.height = 0.6
			_add(star, _mat(Color(1.0, 0.85, 0.3), true), Vector3(0, 1.2, 0))
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.85, 0.4)
			l.omni_range = 7.0
			l.position.y = 1.2
			add_child(l)
		_:
			pass   # Küche: Modell kommt von Kitchen
