class_name NightSky
extends Node3D
## Nachthimmel: Umgebung (Farbe, Glow), Mondlicht, Mond, Hintergrundsterne und Tagesphasen (A-07).
## Phasen: "dusk" (Dämmerung, Blauviolett), "midnight" (Mitternacht, tiefes Indigo), "dawn" (Morgenrot, Rosé/Violett).
## `set_phase(name, dauer)` blendet weich über; folgt automatisch `GameState.phase_changed`, falls der Autoload existiert.

## Je Phase: [Zenit, Horizont, Dunst, Mondlicht-Energie, Anteil sichtbarer Hintergrundsterne]
const PHASES := {
	"dusk": [Palette.SKY_DUSK, Palette.SKY_DUSK, Palette.SKY_DUSK, 0.45, 0.35],
	"midnight": [Palette.SKY_MIDNIGHT, Palette.SKY_MIDNIGHT, Palette.SKY_MIDNIGHT, 0.6, 1.0],
	"dawn": [Palette.SKY_MIDNIGHT, Palette.SKY_DAWN, Palette.SKY_DAWN, 0.4, 0.25],
}

var phase := "midnight"
var _psm: ProceduralSkyMaterial
var _env: Environment
var _moon_light: DirectionalLight3D
var _stars: MultiMesh
var _star_total := 0
var _tween: Tween


func _ready() -> void:
	_build_environment()
	_build_sky_stars()
	_build_moon()
	_build_cloud_island()
	set_phase(phase, 0.0)
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.has_signal("phase_changed"):
		gs.phase_changed.connect(_on_game_phase)


## GameState.Phase (0 Dämmerung, 1 Mitternacht, 2 Morgenrot, 3 Ende) auf Himmelsphase abbilden.
func _on_game_phase(p: int) -> void:
	set_phase(["dusk", "midnight", "dawn", "midnight"][clampi(p, 0, 3)], 4.0)


## Himmelsfarben pro Phase (statisch, testbar): Zenit ist dunkler als der Horizont.
static func phase_colors(name: String) -> Array[Color]:
	var d: Array = PHASES.get(name, PHASES["midnight"])
	var top: Color = (d[0] as Color).darkened(0.45) if name == "dusk" else (d[0] as Color).darkened(0.25)
	var hor: Color = (d[1] as Color).lightened(0.05) if name == "midnight" else (d[1] as Color)
	return [top, hor, d[2] as Color]


func set_phase(name: String, duration := 3.0) -> void:
	if not PHASES.has(name):
		name = "midnight"
	phase = name
	if _psm == null:
		return
	var c := phase_colors(name)
	var d: Array = PHASES[name]
	var count := int(round(_star_total * float(d[4])))
	if _tween:
		_tween.kill()
	if duration <= 0.0 or not is_inside_tree():
		_apply(c[0], c[1], c[2], d[3], count)
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_psm, "sky_top_color", c[0], duration)
	_tween.tween_property(_psm, "sky_horizon_color", c[1], duration)
	_tween.tween_property(_psm, "ground_horizon_color", c[1], duration)
	_tween.tween_property(_env, "fog_light_color", c[2], duration)
	_tween.tween_property(_moon_light, "light_energy", d[3], duration)
	_stars.visible_instance_count = count   # Sterne springen sichtbar, bleiben dezent


func _apply(top: Color, hor: Color, fog: Color, moon_energy: float, count: int) -> void:
	_psm.sky_top_color = top
	_psm.sky_horizon_color = hor
	_psm.ground_horizon_color = hor
	_env.fog_light_color = fog
	_moon_light.light_energy = moon_energy
	_stars.visible_instance_count = count


func _build_environment() -> void:
	var env := Environment.new()
	_env = env
	# Verlauf: dunkles Blau oben, helleres Violett am Horizont (ProceduralSky, billig, Compatibility-tauglich)
	var psm := ProceduralSkyMaterial.new()
	_psm = psm
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
	_moon_light = moon


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
	_stars = mm
	_star_total = mm.instance_count
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


## Mond: heller Elfenbein-Kreis mit weichem Hof, unbeleuchtet (kostet fast nichts).
func _build_moon() -> void:
	var dir := Vector3(-0.45, 0.5, -0.75).normalized()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Palette.UI_IVORY
	var moon := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 7.0
	sm.height = 14.0
	sm.radial_segments = 16
	sm.rings = 8
	moon.mesh = sm
	moon.material_override = mat
	moon.position = dir * 135.0
	add_child(moon)
	var halo := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 11.0
	hm.height = 22.0
	hm.radial_segments = 16
	hm.rings = 8
	var hmat := StandardMaterial3D.new()
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.albedo_color = Color(Palette.UI_IVORY, 0.12)
	halo.mesh = hm
	halo.material_override = hmat
	halo.position = moon.position
	add_child(halo)


## Koroutine-Selbsttest: `await NightSky.selftest(root)`. Prüft Phasenfarben, Sternanteil und dass sich die Phasen unterscheiden.
static func selftest(root: Node) -> bool:
	var sky := NightSky.new()
	root.add_child(sky)
	await (Engine.get_main_loop() as SceneTree).process_frame
	var seen := {}
	var ok := true
	for ph in ["dusk", "midnight", "dawn"]:
		sky.set_phase(ph, 0.0)
		var c := NightSky.phase_colors(ph)
		ok = ok and sky._psm.sky_horizon_color.is_equal_approx(c[1]) and sky._psm.sky_top_color.is_equal_approx(c[0])
		seen[ph] = sky._psm.sky_horizon_color.to_html(false)
	ok = ok and seen["dusk"] != seen["midnight"] and seen["midnight"] != seen["dawn"] and seen["dusk"] != seen["dawn"]
	sky.set_phase("midnight", 0.0)
	var full: int = sky._stars.visible_instance_count
	sky.set_phase("dawn", 0.0)
	ok = ok and full == 350 and sky._stars.visible_instance_count < full / 2
	sky.free()
	print("SELFTEST NightSky Phasen %s -> %s" % [str(seen), "OK" if ok else "FAIL"])
	return ok
