class_name World
extends Node3D
## Wolkeninsel und die zu putzenden Sterne. Sendet Signale weiter, damit Main/HUD nur zuhören müssen.

signal star_scrubbed(star: Star, removed: int)
signal star_cleaned(star: Star)

const STAR_POSITIONS := [Vector3(0, 5.0, -7), Vector3(-9, 6.0, 1), Vector3(8, 5.5, 3)]

var stars: Array[Star] = []


func _ready() -> void:
	_build_island()
	_build_stars()


## Wischt an einem Weltpunkt über alle Sterne. Gibt die Zahl entfernter Flecken zurück.
func wipe_at(point: Vector3, radius: float) -> int:
	var removed := 0
	for s in stars:
		removed += s.wipe(point, radius)
	return removed


func cleaned_count() -> int:
	var n := 0
	for s in stars:
		if s.is_clean:
			n += 1
	return n


func _build_island() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var mesh := CylinderMesh.new()
	mesh.top_radius = 14.0
	mesh.bottom_radius = 9.0
	mesh.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.58, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.5, 0.9)
	mat.emission_energy_multiplier = 0.15
	mat.roughness = 0.9
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 14.0
	shape.height = 2.0
	cs.shape = shape
	body.add_child(cs)
	body.position.y = -1.0
	add_child(body)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var puff := SphereMesh.new()
	puff.radius = 1.6
	puff.height = 3.2
	for i in 18:
		var a := TAU * i / 18.0
		var p := MeshInstance3D.new()
		p.mesh = puff
		p.material_override = mat
		p.position = Vector3(cos(a) * 13.5, -0.4 + rng.randf() * 0.6, sin(a) * 13.5)
		p.scale = Vector3.ONE * rng.randf_range(0.8, 1.4)
		add_child(p)


func _build_stars() -> void:
	for p in STAR_POSITIONS:
		var s := Star.new()
		s.position = p
		add_child(s)
		s.scrubbed.connect(func(n: int): star_scrubbed.emit(s, n))
		s.cleaned.connect(func(): star_cleaned.emit(s))
		stars.append(s)
