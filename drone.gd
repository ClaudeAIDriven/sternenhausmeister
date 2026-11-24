class_name Drone
extends Node3D
## Drohne als Ersatz für einen Spieler, der die Runde verlassen hat (N-05).
## Die Entscheidungen trifft nur der Host: Die Drohne fliegt zum nächsten Schmutzfleck und wischt ihn weg.
## Ihre Position wird vom Host an alle Spieler repliziert (Knotenname identisch auf allen Peers).

const SPEED := 3.5
const WIPE_RADIUS := 0.9
const WIPE_INTERVAL := 0.25
const REACH := 1.6

var world: World
var target := Vector3.ZERO
var has_target := false
var player_name := ""
var wipes := 0

var _retarget := 0.0
var _wipe_cd := 0.0


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.7, 0.85, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.65, 1.0)
	mat.emission_energy_multiplier = 0.6
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	body.mesh = sm
	body.material_override = mat
	add_child(body)
	var eye := MeshInstance3D.new()
	var em := SphereMesh.new()
	em.radius = 0.1
	em.height = 0.2
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color(1, 0.95, 0.7)
	emat.emission_enabled = true
	emat.emission = Color(1, 0.95, 0.7)
	eye.mesh = em
	eye.material_override = emat
	eye.position = Vector3(0, 0.05, -0.3)
	add_child(eye)

	var cfg := SceneReplicationConfig.new()
	cfg.add_property(^":position")
	cfg.property_set_replication_mode(^":position", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.root_path = NodePath("..")
	sync.replication_config = cfg
	add_child(sync)   # Autorität bleibt beim Host (Peer 1)


func _process(delta: float) -> void:
	# Schwebe-Wippen läuft überall; Bewegung nur auf dem Host
	if not multiplayer.is_server():
		return
	if world == null:
		world = get_tree().root.find_child("World", true, false) as World
		if world == null:
			return
	_retarget -= delta
	if _retarget <= 0.0:
		_retarget = 0.4
		_pick_target()
	if not has_target:
		return
	var to := target - global_position
	if to.length() > REACH * 0.5:
		global_position += to.normalized() * minf(SPEED * delta, to.length())
		if Vector2(to.x, to.z).length() > 0.1:
			look_at(global_position + Vector3(to.x, 0, to.z), Vector3.UP)
	_wipe_cd -= delta
	if to.length() <= REACH and _wipe_cd <= 0.0:
		_wipe_cd = WIPE_INTERVAL
		wipes += 1
		world.wipe_at(target, WIPE_RADIUS)


## Nächster übriger Schmutzfleck (Weltposition) über alle Sterne.
func _pick_target() -> void:
	has_target = false
	var best := INF
	for s in world.stars:
		if s.is_clean:
			continue
		for spot in s.spots:
			var p: Vector3 = spot.global_position
			var d := global_position.distance_to(p)
			if d < best:
				best = d
				target = p + (p - s.global_position).normalized() * 0.8   # etwas vor der Oberfläche schweben
				has_target = true
