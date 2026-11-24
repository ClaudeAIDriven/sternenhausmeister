extends Node3D
## Block 1: Putz-Prototyp (solo). Baut die ganze Szene per Code auf.

const PENTATONIC := [261.6, 293.7, 329.6, 392.0, 440.0, 523.3, 587.3, 659.3]

var player: Player
var stars: Array[Star] = []
var sfx: Sfx
var notes: Array[AudioStreamWAV] = []
var scrub_sound: AudioStreamWAV
var chime: Array[AudioStreamWAV] = []
var hud: Label
var dust: CPUParticles3D
var note_idx := 0
var scrub_cooldown := 0.0
var cleaned_count := 0


func _ready() -> void:
	_setup_input()
	_build_environment()
	_build_island()
	_build_sky_stars()
	_build_sound()
	_build_player()
	_build_stars()
	_build_hud()
	if "--selftest" in OS.get_cmdline_user_args():
		call_deferred("_selftest")


func _setup_input() -> void:
	var map := {
		"move_forward": KEY_W, "move_back": KEY_S,
		"move_left": KEY_A, "move_right": KEY_D,
		"jump": KEY_SPACE,
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var e := InputEventKey.new()
			e.physical_keycode = map[action]
			InputMap.action_add_event(action, e)
	if not InputMap.has_action("clean"):
		InputMap.add_action("clean")
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("clean", m)
		var k := InputEventKey.new()
		k.physical_keycode = KEY_E
		InputMap.action_add_event("clean", k)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.1)
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

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.7, 0.8, 1.0)
	moon.light_energy = 0.55
	moon.rotation_degrees = Vector3(-50, 30, 0)
	add_child(moon)


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

	# Wolkenbäusche am Rand
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


func _build_sound() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	for f in PENTATONIC:
		notes.append(Sfx.make_tone(f, 0.45, 0.35))
	scrub_sound = Sfx.make_tone(180.0, 0.08, 0.18, 0.7)
	for f in [523.3, 659.3, 784.0, 1046.5]:
		chime.append(Sfx.make_tone(f, 1.4, 0.4))


func _build_player() -> void:
	player = Player.new()
	player.position = Vector3(0, 0.1, 6)
	add_child(player)
	player.wipe_requested.connect(_on_wipe_requested)

	dust = CPUParticles3D.new()
	dust.amount = 28
	dust.lifetime = 0.7
	dust.emitting = false
	dust.direction = Vector3(0, 1, 0)
	dust.spread = 70.0
	dust.initial_velocity_min = 1.0
	dust.initial_velocity_max = 2.5
	dust.gravity = Vector3(0, -1.5, 0)
	var dm := SphereMesh.new()
	dm.radius = 0.05
	dm.height = 0.1
	dm.radial_segments = 6
	dm.rings = 3
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(0.7, 0.6, 0.5)
	dm.material = dmat
	dust.mesh = dm
	add_child(dust)


func _build_stars() -> void:
	var positions := [Vector3(0, 5.0, -7), Vector3(-9, 6.0, 1), Vector3(8, 5.5, 3)]
	for p in positions:
		var s := Star.new()
		s.position = p
		add_child(s)
		s.scrubbed.connect(_on_scrubbed)
		s.cleaned.connect(_on_star_cleaned.bind(s))
		stars.append(s)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(20, 16)
	hud.add_theme_font_size_override("font_size", 22)
	layer.add_child(hud)
	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 28)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-8, -18)
	layer.add_child(cross)
	_update_hud()


func _update_hud(extra := "") -> void:
	var lines := "Sterne geputzt: %d / %d\n" % [cleaned_count, stars.size()]
	lines += "WASD laufen · Leertaste springen · Maus zielen\n"
	lines += "Linke Maustaste / E: putzen · Klick: Maus einfangen · Esc: loslassen"
	if extra != "":
		lines += "\n\n" + extra
	hud.text = lines


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	scrub_cooldown = maxf(0.0, scrub_cooldown - delta)
	dust.emitting = player.cleaning and player.aim_valid
	if dust.emitting:
		dust.global_position = player.aim_point


func _on_wipe_requested(point: Vector3) -> void:
	var removed := 0
	for s in stars:
		removed += s.wipe(point, 0.9)
	if scrub_cooldown <= 0.0:
		sfx.play(scrub_sound, randf_range(0.9, 1.15), -6.0)
		scrub_cooldown = 0.11


func _on_scrubbed(_removed: int) -> void:
	sfx.play(notes[note_idx % notes.size()], 1.0, -4.0)
	note_idx += 1


func _on_star_cleaned(_s: Star) -> void:
	cleaned_count += 1
	for i in chime.size():
		sfx.play(chime[i], 1.0, -8.0)
	if cleaned_count >= stars.size():
		_update_hud("Nacht geschafft! Der Himmel glänzt. ⭐")
	else:
		_update_hud("Stern geputzt!")


func _selftest() -> void:
	print("SELFTEST start: %d Sterne" % stars.size())
	var ok := true
	for s in stars:
		var guard := 0
		while not s.is_clean and guard < 5000:
			var spot := s.spots[0]
			s.wipe(s.to_global(spot.position), 0.9)
			guard += 1
		ok = ok and s.is_clean and is_equal_approx(s.progress, 1.0)
	ok = ok and cleaned_count == stars.size()
	print("SELFTEST cleaned=%d/%d progress_ok=%s" % [cleaned_count, stars.size(), str(ok)])
	print("SELFTEST OK" if ok else "SELFTEST FAIL")
	get_tree().quit(0 if ok else 1)
