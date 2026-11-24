class_name NightSky
extends Node3D
## Nachthimmel: Umgebung (Farbe, Glow), Mondlicht und Hintergrundsterne.


func _ready() -> void:
	_build_environment()
	_build_sky_stars()
	_build_cloud_island()


func _build_environment() -> void:
	var env := Environment.new()
	# Verlauf: dunkles Blau oben, helleres Violett am Horizont (ProceduralSky, billig, Compatibility-tauglich)
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.015, 0.02, 0.09)
	psm.sky_horizon_color = Color(0.22, 0.17, 0.42)
	psm.ground_horizon_color = Color(0.22, 0.17, 0.42)
	psm.ground_bottom_color = Color(0.03, 0.03, 0.12)
	psm.sky_curve = 0.18
	psm.ground_curve = 0.08
	psm.sun_angle_max = 0.0
	var sky_res := Sky.new()
	sky_res.sky_material = psm
	sky_res.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky_res
	# sanfter Dunst in Himmelsfarbe, lässt die Ferne weich verschwimmen
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.16, 0.4)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.4, 0.7)
	env.ambient_light_energy = 0.4
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# Banding vermeiden (Dithering im Viewport)
	get_viewport().use_debanding = true

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.7, 0.8, 1.0)
	moon.light_energy = 0.55
	moon.rotation_degrees = Vector3(-50, 30, 0)
	add_child(moon)


func _build_sky_stars() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var m := SphereMesh.new()
	m.radius = 0.35
	m.height = 0.7
	m.radial_segments = 6
	m.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.4, 1.3, 1.0)
	m.material = mat
	mm.mesh = m
	mm.instance_count = 350
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in mm.instance_count:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1), rng.randf_range(-1, 1)).normalized()
		var t := Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(0.4, 1.5)), dir * 140.0)
		mm.set_instance_transform(i, t)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)


## Ferne Wolkeninsel: flache, weiche Kuppeln im Dunst (unbeleuchtet, kostet fast nichts).
func _build_cloud_island() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.45, 0.4, 0.72)
	var center := Vector3(-70, 12, -120)
	for i in 9:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = 12
		sm.rings = 6
		mi.mesh = sm
		mi.material_override = mat
		var r := rng.randf_range(6.0, 13.0)
		mi.scale = Vector3(r, r * 0.45, r * 0.8)
		mi.position = center + Vector3(rng.randf_range(-22, 22), rng.randf_range(-1, 2), rng.randf_range(-8, 8))
		add_child(mi)
