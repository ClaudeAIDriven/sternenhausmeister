class_name SootCloud
extends Enemy
## G-29: Rußwolke (Boss). Schwebt über einem Stern und zieht alle ROAM_TIME s zum nächsten. Schaden nur, wenn mindestens
## TEAM_SIZE verschiedene Spieler innerhalb TEAM_WINDOW s wischen. Solo-Ausweg: das Schild fällt in Wellen (alle SHIELD_PERIOD s
## für SHIELD_DOWN s) – nur dann trifft auch ein einzelner Wisch. Bei Besiegen: Staub und XP-Ereignis (Signal via World.enemy_removed).

const MAX_HP := 100.0
const HIT_DAMAGE := 10.0
const TEAM_SIZE := 2
const TEAM_WINDOW := 0.8
const SHIELD_PERIOD := 25.0
const SHIELD_DOWN := 6.0
const ROAM_TIME := 20.0
const REWARD_DUST := 200
const BOSS_RESPAWN := 150.0
const HIT_RADIUS := 3.0

var hp := MAX_HP
var shield_timer := 0.0   # läuft hoch; im Fenster [SHIELD_PERIOD - SHIELD_DOWN, SHIELD_PERIOD) ist das Schild unten
var _recent := {}         # Spieler-ID -> Zeitpunkt (s) des letzten Wischtreffers
var _clock := 0.0
var _roam_left := ROAM_TIME
var _puffs: Array[MeshInstance3D] = []
var _t := 0.0


func _init() -> void:
	kind = "russwolke"
	name = "Russwolke"


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.07, 0.09, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	for off in [Vector3.ZERO, Vector3(1.2, 0.4, 0.3), Vector3(-1.1, 0.2, -0.4), Vector3(0.2, 0.9, -0.9)]:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.2
		sm.height = 2.0
		mi.mesh = sm
		mi.material_override = mat
		mi.position = off
		add_child(mi)
		_puffs.append(mi)
	var eye_mat := StandardMaterial3D.new()   # M-06: zornige glühende Augen
	eye_mat.albedo_color = Color(1.0, 0.35, 0.1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.35, 0.1)
	eye_mat.emission_energy_multiplier = 2.0
	for sx in [-0.45, 0.45]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.2
		em.height = 0.4
		eye.mesh = em
		eye.material_override = eye_mat
		eye.position = Vector3(sx, 0.2, 1.05)
		add_child(eye)
	var rain := CPUParticles3D.new()   # Rußflocken
	rain.amount = 40
	rain.lifetime = 2.0
	rain.direction = Vector3(0, -1, 0)
	rain.spread = 25.0
	rain.gravity = Vector3(0, -2.0, 0)
	rain.initial_velocity_min = 0.5
	rain.initial_velocity_max = 1.2
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	rain.emission_sphere_radius = 1.6
	var rm := SphereMesh.new()
	rm.radius = 0.06
	rm.height = 0.12
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.05, 0.05, 0.06)
	rm.material = rmat
	rain.mesh = rm
	add_child(rain)


func shield_down() -> bool:
	return shield_timer >= SHIELD_PERIOD - SHIELD_DOWN


func team_active() -> bool:
	var n := 0
	for k in _recent:
		if _clock - float(_recent[k]) <= TEAM_WINDOW:
			n += 1
	return n >= TEAM_SIZE


## Host: ein Wischtreffer von `who`. Gibt true zurück, wenn die Wolke besiegt wurde.
func hit(who: int) -> bool:
	if not alive:
		return false
	_recent[who] = _clock
	if not (team_active() or shield_down()):
		return false
	hp -= HIT_DAMAGE
	if hp <= 0.0:
		return true
	return false


func on_wipe(world, who: int, _tool: int) -> bool:
	if hit(who):
		world.reward_boss(self, REWARD_DUST)
		remove()
		respawn_left = BOSS_RESPAWN
		return true
	return false


func set_alive(a: bool) -> void:
	super.set_alive(a)
	if a:
		hp = MAX_HP
		_recent.clear()


func hit_radius() -> float:
	return HIT_RADIUS


func act(delta: float, world) -> void:
	_clock += delta
	shield_timer = fmod(shield_timer + delta, SHIELD_PERIOD)
	_roam_left -= delta
	if _roam_left <= 0.0:
		_roam_left = ROAM_TIME
		world.hop_enemy(self)


func _process(delta: float) -> void:   # M-06: Wolke wabert; mit gefallenem Schild leuchten die Puffs auf
	_t += delta
	for i in _puffs.size():
		_puffs[i].scale = Vector3.ONE * (1.0 + sin(_t * 1.3 + i * 1.7) * 0.08)
