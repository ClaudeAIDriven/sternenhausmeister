class_name Effects
extends RefCounted
## Partikel-Effekte (A-05): Funkel-Burst beim Stern-Abschluss und hübscherer Putzstaub.
## Nutzung (Einbau gehört nicht zu dieser Karte):
##   Effects.sparkle_burst(self, star.position)   # self = gleicher Parent wie der Stern   # einmalig, löscht sich selbst
##   var dust := Effects.make_dust(); add_child(dust)     # Dauer-Emitter, `emitting` per Hand steuern


## Einmaliger goldener Funkel-Burst. Gibt den Emitter zurück.
static func sparkle_burst(parent: Node, pos: Vector3, radius := 2.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 60
	p.lifetime = 1.2
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 7.0
	p.gravity = Vector3(0, -2.0, 0)
	p.damping_min = 1.5
	p.damping_max = 3.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	grad.set_color(1, Color(1.0, 0.6, 0.9, 0.0))
	p.color_ramp = grad
	p.mesh = _spark_mesh(0.18)
	parent.add_child(p)
	p.position = pos + Vector3(0, radius * 0.5, 0)   # lokal zum Parent; Parent ohne Drehung/Skalierung annehmen
	p.emitting = true
	# räumt sich selbst auf
	var timer := (Engine.get_main_loop() as SceneTree).create_timer(p.lifetime + 0.5)
	timer.timeout.connect(func() -> void: if is_instance_valid(p): p.queue_free())
	return p


## Putzstaub: weiche, helle Körnchen, die nach oben treiben und ausblenden.
static func make_dust() -> CPUParticles3D:
	var d := CPUParticles3D.new()
	d.emitting = false
	d.amount = 36
	d.lifetime = 0.8
	d.direction = Vector3.UP
	d.spread = 65.0
	d.initial_velocity_min = 1.0
	d.initial_velocity_max = 2.6
	d.gravity = Vector3(0, -1.0, 0)
	d.damping_min = 0.5
	d.damping_max = 1.5
	d.scale_amount_min = 0.5
	d.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	d.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.95, 0.9, 1.0, 0.9))
	grad.set_color(1, Color(0.7, 0.65, 0.9, 0.0))
	d.color_ramp = grad
	d.mesh = _spark_mesh(0.1)
	return d


static func _spark_mesh(size: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = size
	m.height = size * 2.0
	m.radial_segments = 6
	m.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.6, 1.5, 1.2)
	m.material = mat
	return m
