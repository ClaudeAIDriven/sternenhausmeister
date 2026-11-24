class_name SkyFx
extends Node3D
## Himmelseffekte (A-14): weiche, runde, langsam ziehende Wolken und Sternschnuppen. Ergänzt NightSky (sky.gd).
## Nutzung (Einbau gehört nicht zu dieser Karte): `var fx := SkyFx.new(); add_child(fx)`; `fx.spawn_shooting_star()`;
## `fx.reduced_motion = true` hält Wolken still und lässt Sternschnuppen nur kurz aufleuchten (ohne Flug). Wetter-Logik (G-07) ruft das nur auf.

@export var reduced_motion := false
@export var cloud_count := 9
@export var drift_speed := 1.2   # m/s, sehr langsam
@export var auto_shooting_stars := false   # true = zufällig alle 25 bis 50 s
const RING_MIN := 95.0
const RING_MAX := 125.0

var clouds: Array[Node3D] = []
var _cloud_mat: StandardMaterial3D
var _stars: Array[Node3D] = []
var _next_star := 30.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 5
	build_clouds()


func build_clouds() -> void:
	for c in clouds:
		c.queue_free()
	clouds.clear()
	_cloud_mat = StandardMaterial3D.new()
	_cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cloud_mat.albedo_color = Palette.SKY_DUSK.lightened(0.3)
	var puff := SphereMesh.new()
	puff.radius = 1.0
	puff.height = 2.0
	puff.radial_segments = 12
	puff.rings = 6
	for i in cloud_count:
		var cloud := Node3D.new()
		cloud.name = "Cloud"
		var a := TAU * (float(i) + _rng.randf_range(-0.3, 0.3)) / cloud_count
		var r := _rng.randf_range(RING_MIN, RING_MAX)
		cloud.position = Vector3(cos(a) * r, _rng.randf_range(14.0, 42.0), sin(a) * r)
		var s := _rng.randf_range(4.0, 8.0)
		for k in 4:   # Häufchen aus überlappenden, flachen Kugeln = weiche runde Wolke
			var mi := MeshInstance3D.new()
			mi.mesh = puff
			mi.material_override = _cloud_mat
			var w := s * _rng.randf_range(0.7, 1.2)
			mi.scale = Vector3(w, w * 0.5, w * 0.75)
			mi.position = Vector3((k - 1.5) * s * 0.9, _rng.randf_range(-0.3, 0.6) * s * 0.3, _rng.randf_range(-0.4, 0.4))
			cloud.add_child(mi)
		add_child(cloud)
		clouds.append(cloud)


## Wolkenfarbe passend zur Himmelsphase ("dusk", "midnight", "dawn").
func set_phase(name: String) -> void:
	if _cloud_mat:
		_cloud_mat.albedo_color = Palette.sky_color(name).lightened(0.3)


## Startet eine Sternschnuppe: Streifen mit Schweif, fliegt ca. 1,2 s. Gibt den Knoten zurück.
func spawn_shooting_star(from := Vector3(-40, 55, -110), dir := Vector3(1, -0.35, 0)) -> Node3D:
	var n := Node3D.new()
	n.name = "ShootingStar"
	var d := dir.normalized()
	n.position = from
	n.set_meta("vel", d * 85.0)
	n.set_meta("life", 1.2)
	n.set_meta("age", 0.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(Palette.UI_IVORY.r * 1.2, Palette.UI_IVORY.g * 1.1, Palette.STAR_GOLD.b, 0.9)
	var x := d.cross(Vector3.UP).normalized()
	var z := x.cross(d).normalized()
	for i in 4:   # Kopf + 3 abnehmende Schweifteile
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.8 * (1.0 - i * 0.22)
		cm.height = 5.0 + i * 3.0
		cm.radial_segments = 6
		cm.rings = 1
		cone.mesh = cm
		var m := mat.duplicate() as StandardMaterial3D
		m.albedo_color.a = 0.9 - i * 0.22
		cone.material_override = m
		# Kegelspitze in Flugrichtung (Spitze liegt bei +Y des Kegels), Schweif dahinter
		cone.transform = Transform3D(Basis(x, d, z), -d * (cm.height * 0.5 + i * 1.5))
		n.add_child(cone)
	add_child(n)
	_stars.append(n)
	return n


func active_shooting_stars() -> int:
	return _stars.size()


## Zeit vorrücken (auch direkt aufrufbar, z. B. im Test).
func advance(delta: float) -> void:
	if not reduced_motion:
		for c in clouds:
			c.position.x += drift_speed * delta
			if c.position.x > RING_MAX * 1.2:
				c.position.x = -RING_MAX * 1.2
	for s in _stars.duplicate():
		var age: float = s.get_meta("age") + delta
		s.set_meta("age", age)
		if not reduced_motion:
			s.position += (s.get_meta("vel") as Vector3) * delta
		if age >= float(s.get_meta("life")):
			_stars.erase(s)
			s.queue_free()
	if auto_shooting_stars:
		_next_star -= delta
		if _next_star <= 0.0:
			_next_star = _rng.randf_range(25.0, 50.0)
			spawn_shooting_star(Vector3(_rng.randf_range(-60, 20), _rng.randf_range(45, 70), -110))


func _process(delta: float) -> void:
	advance(delta)


## Selbsttest: Wolken ziehen, reduced_motion hält sie an, Sternschnuppe fliegt und verschwindet.
static func selftest() -> bool:
	var fx := SkyFx.new()
	fx._rng.seed = 5
	fx.build_clouds()
	var x0 := fx.clouds[0].position.x
	fx.advance(10.0)
	var moved := fx.clouds[0].position.x - x0
	var ok := fx.clouds.size() == 9 and moved > 5.0 and moved < 30.0
	fx.reduced_motion = true
	var x1 := fx.clouds[0].position.x
	fx.advance(10.0)
	ok = ok and is_equal_approx(fx.clouds[0].position.x, x1)
	fx.reduced_motion = false
	var s := fx.spawn_shooting_star()
	var p0 := s.position
	fx.advance(0.5)
	ok = ok and s.position.distance_to(p0) > 30.0 and fx.active_shooting_stars() == 1
	fx.advance(1.0)
	ok = ok and fx.active_shooting_stars() == 0
	fx.free()
	print("SELFTEST SkyFx Wolken zogen %.1f m, Sternschnuppe -> %s" % [moved, "OK" if ok else "FAIL"])
	return ok
