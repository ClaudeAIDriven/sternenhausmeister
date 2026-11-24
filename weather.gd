class_name Weather
extends Node3D
## G-07: Wetter-Events der Nacht: Wolken ziehen vor die Sterne, eine Sternschnuppe kann einen Stern neu verschmutzen.
## Ablauf je Event: Wartezeit -> Vorwarnung (HUD-Text) -> aktiv -> Ende. Nie zerstörend: Fortschritt geht nie verloren,
## das Neu-Verschmutzen selbst führt nicht Weather aus, sondern der Besitzer über das Signal `meteor_strike`.
## Zen-Modus: `cosmetic = true` zeigt alles weiterhin, löst aber nie `meteor_strike` aus.
##
## Einbindung (Folgekarte, nicht Teil von G-07): `add_child(Weather.new())`, `weather.set_star_positions(...)`,
## `weather.warning.connect(...)` an das HUD, `meteor_strike` an das Neu-Verschmutzen des Sterns.

enum Kind { CLOUDS, METEOR }
enum State { IDLE, WARNING, ACTIVE }

signal warning(kind: int, text: String, seconds: float)
signal event_started(kind: int)
signal event_ended(kind: int)
## Nur wenn nicht kosmetisch. star_index zeigt in die Liste aus set_star_positions().
signal meteor_strike(star_index: int)

const DURATION := {Kind.CLOUDS: 20.0, Kind.METEOR: 5.0}
const WARN_TEXT := {
	Kind.CLOUDS: "Wolken ziehen auf …",
	Kind.METEOR: "Eine Sternschnuppe naht – ein Stern könnte wieder staubig werden.",
}
const WARN_TEXT_COSMETIC := {
	Kind.CLOUDS: "Wolken ziehen auf …",
	Kind.METEOR: "Eine Sternschnuppe naht!",
}

var cosmetic := false          # Zen: nur Optik, nie Folgen für das Spiel
var enabled := true
var warn_time := 6.0
var gap_min := 40.0
var gap_max := 90.0

var state := State.IDLE
var kind := Kind.CLOUDS
var running := false

var _rng := RandomNumberGenerator.new()
var _timer := 0.0
var _star_positions: Array[Vector3] = []
var _target := -1
var _clouds: Array[MeshInstance3D] = []
var _meteor: MeshInstance3D
var _strike_sent := false


func _ready() -> void:
	if _rng.seed == 0:
		_rng.randomize()
	if Engine.has_singleton("GameState") or get_tree().root.has_node("GameState"):
		var gs := get_tree().root.get_node("GameState")
		gs.night_started.connect(start)
		gs.night_ended.connect(stop)


func set_star_positions(positions: Array) -> void:
	_star_positions.clear()
	for p in positions:
		_star_positions.append(p)


func seed_rng(value: int) -> void:
	_rng.seed = value


func start() -> void:
	running = true
	_end_event(false)
	_timer = _rng.randf_range(gap_min, gap_max)


## Beendet laufende Events sofort (Nachtende) und plant nichts Neues.
func stop() -> void:
	running = false
	_end_event(true)


## Text für das HUD ("" wenn keine Vorwarnung/kein Event läuft).
func hud_text() -> String:
	if state == State.IDLE:
		return ""
	var t: Dictionary = WARN_TEXT_COSMETIC if cosmetic else WARN_TEXT
	return t[kind] if state == State.WARNING else ("Wolken verdecken die Sterne" if kind == Kind.CLOUDS else "")


func tick(delta: float) -> void:
	if not running or not enabled:
		return
	_timer -= delta
	match state:
		State.IDLE:
			if _timer <= 0.0:
				_begin_warning()
		State.WARNING:
			if _timer <= 0.0:
				_begin_active()
		State.ACTIVE:
			_update_visual()
			if kind == Kind.METEOR and not _strike_sent and _timer <= DURATION[Kind.METEOR] * 0.3:
				_strike_sent = true
				if not cosmetic and _target >= 0:
					meteor_strike.emit(_target)
			if _timer <= 0.0:
				_end_event(true)
				_timer = _rng.randf_range(gap_min, gap_max)


func _process(delta: float) -> void:
	tick(delta)


func _begin_warning() -> void:
	kind = Kind.METEOR if _rng.randf() < 0.4 and not _star_positions.is_empty() else Kind.CLOUDS
	_target = _rng.randi_range(0, _star_positions.size() - 1) if not _star_positions.is_empty() else -1
	state = State.WARNING
	_timer = warn_time
	warning.emit(kind, hud_text(), warn_time)


func _begin_active() -> void:
	state = State.ACTIVE
	_timer = DURATION[kind]
	_strike_sent = false
	_build_visual()
	event_started.emit(kind)


func _end_event(emit: bool) -> void:
	var was_active := state == State.ACTIVE
	var k := kind
	state = State.IDLE
	_target = -1
	for c in _clouds:
		c.queue_free()
	_clouds.clear()
	if _meteor != null:
		_meteor.queue_free()
		_meteor = null
	if emit and was_active:
		event_ended.emit(k)


## Optik: Wolken sind flache, halbtransparente Kugeln knapp vor den Sternen; die Sternschnuppe ein leuchtender Punkt.
func _build_visual() -> void:
	if kind == Kind.CLOUDS:
		var spots: Array = _star_positions if not _star_positions.is_empty() else [Vector3(0, 5, -7)]
		for p in spots:
			for i in 3:
				var mi := MeshInstance3D.new()
				var m := SphereMesh.new()
				m.radius = 2.2
				m.height = 2.6
				mi.mesh = m
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.85, 0.88, 0.95, 0.0)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mi.material_override = mat
				mi.position = p + Vector3(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-0.8, 0.8), 2.5 + i * 0.4)
				mi.scale = Vector3(1.3, 0.6, 1.0)
				add_child(mi)
				_clouds.append(mi)
	else:
		_meteor = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.25
		s.height = 0.5
		_meteor.mesh = s
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.95, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.9, 0.5)
		mat.emission_energy_multiplier = 4.0
		_meteor.material_override = mat
		add_child(_meteor)
	_update_visual()


func _update_visual() -> void:
	var f := 1.0 - clampf(_timer / maxf(0.001, DURATION[kind]), 0.0, 1.0)   # 0..1 über die Eventdauer
	if kind == Kind.CLOUDS:
		var a := sin(f * PI) * 0.75   # sanft ein- und ausblenden
		for c in _clouds:
			(c.material_override as StandardMaterial3D).albedo_color.a = a
			c.position.x += 0.003
	elif _meteor != null:
		var end := _star_positions[_target] if _target >= 0 else Vector3(0, 5, -7)
		_meteor.position = (end + Vector3(-18, 14, 0)).lerp(end, minf(1.0, f / 0.7))
		_meteor.visible = f < 0.75
