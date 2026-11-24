class_name FunItems
extends RefCounted
## M-08: Spaß-Zutaten. Trampolinwolken (hoher Sprung zu hohen Sternen), Wunsch-Sternschnuppen (fangen = 60 s Buff) und der
## Glühwürmchen-Schwarm, der dem Spieler folgt und zum nächsten schmutzigen Stern zeigt. Die Logik ist von Szenen getrennt testbar.

const BOOST := 15.0
const WISH_SECONDS := 60.0
const WISH_MULT := 1.2
const WISH_STATS := {"speed": "Tempo", "jump": "Sprung", "wipe": "Wischradius", "regen": "Heilung"}


## Trampolin-Plätze: neben jedem hohen Stern (y >= 5.5) ein Platz am Boden, nicht im Stern-Schatten (3 m seitlich).
static func trampoline_spots(star_positions: Array) -> Array:
	var out: Array = []
	for p in star_positions:
		if p.y >= 5.5:
			var side := Vector3(p.x, 0, p.z).normalized() if Vector2(p.x, p.z).length() > 0.5 else Vector3.RIGHT
			out.append(Vector3(p.x, 0.05, p.z) + side * 3.5)
	return out


## Gibt einem Spieler einen Wunsch (zufälliger Buff über die Küchen-Buffs). Gibt den Stat zurück.
static func grant_wish(player: Object, rng: RandomNumberGenerator = null) -> String:
	if player == null or player.kitchen == null:
		return ""
	var keys: Array = WISH_STATS.keys()
	var stat: String = keys[(rng.randi() if rng != null else randi()) % keys.size()]
	var buffs: Dictionary = player.kitchen.buffs
	buffs[stat] = {"mult": WISH_MULT, "left": WISH_SECONDS, "label": "Wunsch: " + str(WISH_STATS[stat])}
	player.kitchen.buffs_changed.emit()
	return stat


## Nächster nicht geputzter Stern zum Punkt `from` (null, wenn alle sauber).
static func nearest_dirty_star(stars: Array, from: Vector3) -> Node3D:
	var best: Node3D = null
	var bd := INF
	for s in stars:
		if s.is_clean:
			continue
		var d: float = (s.global_position - from).length()
		if d < bd:
			bd = d
			best = s
	return best


## Trampolinwolke: kurzer Sprungboost für den lokalen Spieler.
class Trampoline extends Area3D:
	var _cool := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 1.6
		sh.height = 0.8
		cs.shape = sh
		cs.position.y = 0.4
		add_child(cs)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.95, 0.95, 1.0)
		m.emission_enabled = true
		m.emission = Color(0.7, 0.8, 1.0)
		m.emission_energy_multiplier = 0.5
		for off in [Vector3.ZERO, Vector3(0.7, 0.0, 0.3), Vector3(-0.6, 0.0, -0.4)]:
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.9
			sm.height = 0.8
			mi.mesh = sm
			mi.material_override = m
			mi.position = off + Vector3(0, 0.2, 0)
			add_child(mi)
		body_entered.connect(_on_body)

	func _process(delta: float) -> void:
		_cool = maxf(_cool - delta, 0.0)

	func _on_body(b: Node3D) -> void:
		bounce(b)

	func bounce(b: Node3D) -> bool:
		var p := b as Player
		if p == null or not p.is_multiplayer_authority() or _cool > 0.0 or p.downed:
			return false
		p.velocity.y = FunItems.BOOST
		p._peak_y = p.global_position.y   # Sprungboost zählt nicht als Fall
		_cool = 0.4
		return true


## Wunsch-Sternschnuppe: schwebt kurz über der Insel, wer sie berührt, bekommt einen Wunsch.
class WishStar extends Area3D:
	signal caught(player: Node3D, stat: String)
	var life := 25.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1
		var cs := CollisionShape3D.new()
		var sh := SphereShape3D.new()
		sh.radius = 1.4
		cs.shape = sh
		add_child(cs)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1.0, 0.95, 0.6)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.9, 0.4)
		m.emission_energy_multiplier = 2.5
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.35
		sm.height = 0.7
		mi.mesh = sm
		mi.material_override = m
		add_child(mi)
		var tail := CPUParticles3D.new()
		tail.amount = 24
		tail.lifetime = 0.8
		tail.direction = Vector3(0, 0.2, 1)
		tail.spread = 20.0
		tail.initial_velocity_min = 0.5
		tail.initial_velocity_max = 1.5
		tail.gravity = Vector3.ZERO
		var tm := SphereMesh.new()
		tm.radius = 0.05
		tm.height = 0.1
		tm.material = m
		tail.mesh = tm
		add_child(tail)
		body_entered.connect(func(b): catch(b))

	func _process(delta: float) -> void:
		life -= delta
		position.y += sin(life * 2.0) * delta * 0.6
		if life <= 0.0:
			queue_free()

	func catch(b: Node3D) -> bool:
		var p := b as Player
		if p == null or not p.is_multiplayer_authority():
			return false
		var stat := FunItems.grant_wish(p)
		caught.emit(p, stat)
		queue_free()
		return true


## Glühwürmchen-Schwarm: umkreist den Spieler, zieht zum nächsten schmutzigen Stern (leuchtet nur, solange einer schmutzig ist).
class Swarm extends Node3D:
	var flies: Array[MeshInstance3D] = []
	var target: Node3D
	var _t := 0.0

	func _ready() -> void:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.9, 1.0, 0.5)
		m.emission_enabled = true
		m.emission = Color(0.9, 1.0, 0.4)
		m.emission_energy_multiplier = 2.0
		for i in 6:
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.07
			sm.height = 0.14
			mi.mesh = sm
			mi.material_override = m
			add_child(mi)
			flies.append(mi)

	## Zeigerrichtung (flach) zum Ziel von `from` aus; Nullvektor ohne Ziel.
	func direction_to_target(from: Vector3) -> Vector3:
		if target == null or not is_instance_valid(target):
			return Vector3.ZERO
		var d := target.global_position - from
		d.y = 0.0
		return d.normalized()

	func update_swarm(player_pos: Vector3, world_stars: Array, delta: float) -> void:
		_t += delta
		target = FunItems.nearest_dirty_star(world_stars, player_pos)
		visible = target != null
		var dir := direction_to_target(player_pos)
		global_position = global_position.lerp(player_pos + Vector3(0, 2.0, 0) + dir * 1.5, clampf(delta * 3.0, 0.0, 1.0))
		for i in flies.size():
			var a := _t * (1.0 + i * 0.15) + i
			flies[i].position = Vector3(cos(a) * 0.5, sin(a * 1.7) * 0.25, sin(a) * 0.5) + dir * (0.3 + 0.2 * sin(_t * 3.0 + i))
