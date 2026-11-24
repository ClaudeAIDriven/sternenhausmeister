class_name DustBunny
extends Enemy
## G-28: Wollmaus. Wuselt über einen Stern und verschmutzt dort alle DIRTY_INTERVAL Sekunden einen geputzten Fleck neu.
## Mit jedem Werkzeug wegputzbar. Hat der Stern nichts Geputztes, zieht sie zum nächsten Stern mit Putzspuren weiter.

const DIRTY_INTERVAL := 4.0
const SPEED := 0.5           # rad/s auf der Kugel
const HOP_AFTER := 12.0      # so lange ohne Beute, dann Sternwechsel

var _axis := Vector3.RIGHT
var _turn_left := 0.0
var _dirty_left := DIRTY_INTERVAL
var _idle := 0.0
var _body: MeshInstance3D
var _t := 0.0


func _init() -> void:
	kind = "wollmaus"
	name = "Wollmaus"


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.6, 0.64)
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.6
	mi.mesh = sm
	mi.material_override = mat
	add_child(mi)
	_body = mi
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.72, 0.7, 0.74)
	fur.roughness = 1.0
	for k in 9:   # Fusselbüschel
		var tuft := MeshInstance3D.new()
		var tm := SphereMesh.new()
		tm.radius = 0.13
		tm.height = 0.26
		tuft.mesh = tm
		tuft.material_override = fur
		var ang := TAU * k / 9.0
		tuft.position = Vector3(cos(ang) * 0.3, 0.05 + 0.12 * sin(k * 2.0), sin(ang) * 0.3)
		mi.add_child(tuft)
	for sx in [-0.12, 0.12]:   # Augen
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.06
		em.height = 0.12
		eye.mesh = em
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.05, 0.05, 0.08)
		eye.material_override = dark
		eye.position = Vector3(sx, 0.1, 0.3)
		add_child(eye)


func act(delta: float, world) -> void:
	_turn_left -= delta
	if _turn_left <= 0.0:
		_axis = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5)
		if _axis.length() < 0.05:
			_axis = Vector3.RIGHT
		_turn_left = 1.0 + randf() * 2.0
	rotate_dir(_axis.cross(dir) if _axis.cross(dir).length() > 0.01 else Vector3.UP, SPEED * delta)
	if star == null or star.removed_ids.is_empty():
		_idle += delta
		if _idle >= HOP_AFTER:
			_idle = 0.0
			world.hop_enemy(self)
		return
	_idle = 0.0
	_dirty_left -= delta
	if _dirty_left <= 0.0:
		_dirty_left = DIRTY_INTERVAL
		if not world.zen:
			world.enemy_redirty(star)


func _process(delta: float) -> void:   # M-06: hüpft und wackelt beim Wuseln
	_t += delta
	if _body != null:
		var hop: float = absf(sin(_t * 7.0)) * 0.12
		_body.position.y = hop
		_body.scale = Vector3(1.0 + sin(_t * 14.0) * 0.04, 1.0 - sin(_t * 14.0) * 0.04, 1.0)
