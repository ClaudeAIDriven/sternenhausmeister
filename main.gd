extends Node3D
## Einstieg: verbindet Himmel, Welt, Spieler, Ton und Anzeige. Die Details stecken in sky.gd, world.gd, hud.gd.

const DUST_PER_SPOT := 1
const PENTATONIC := [261.6, 293.7, 329.6, 392.0, 440.0, 523.3, 587.3, 659.3]

var sky: NightSky
var world: World
var player: Player
var hud: Hud
var sfx: Sfx
var dust: CPUParticles3D
var notes: Array[AudioStreamWAV] = []
var scrub_sound: AudioStreamWAV
var chime: Array[AudioStreamWAV] = []
var note_idx := 0
var scrub_cooldown := 0.0


func _ready() -> void:
	_setup_input()
	sky = NightSky.new()
	add_child(sky)
	world = World.new()
	add_child(world)
	_build_sound()
	_build_player()
	hud = Hud.new()
	add_child(hud)
	world.star_scrubbed.connect(_on_star_scrubbed)
	world.star_cleaned.connect(_on_star_cleaned)
	_refresh_hud()
	GameState.start_night()
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


func _refresh_hud(extra := "") -> void:
	hud.show_status(world.cleaned_count(), world.stars.size(), extra)


func _on_wipe_requested(point: Vector3) -> void:
	world.wipe_at(point, 0.9)
	if scrub_cooldown <= 0.0:
		sfx.play(scrub_sound, randf_range(0.9, 1.15), -6.0)
		scrub_cooldown = 0.11


func _on_star_scrubbed(_star: Star, removed: int) -> void:
	GameState.add_dust(removed * DUST_PER_SPOT)   # G-04: Sternenstaub fällt beim Putzen an
	sfx.play(notes[note_idx % notes.size()], 1.0, -4.0)
	note_idx += 1


func _on_star_cleaned(star: Star) -> void:
	GameState.report_star_cleaned(star)
	for i in chime.size():
		sfx.play(chime[i], 1.0, -8.0)
	if world.cleaned_count() >= world.stars.size():
		_refresh_hud("Nacht geschafft! Der Himmel glänzt. ⭐")
	else:
		_refresh_hud("Stern geputzt!")


func _selftest() -> void:
	print("SELFTEST start: %d Sterne" % world.stars.size())
	var ok := true
	# GameState-Test (C-02): Signale und Zähler
	var fired := {"dust": 0, "cleaned": 0, "players": 0, "phase": 0}
	GameState.dust_changed.connect(func(_a): fired["dust"] += 1)
	GameState.star_cleaned.connect(func(_s): fired["cleaned"] += 1)
	GameState.player_count_changed.connect(func(_n): fired["players"] += 1)
	GameState.phase_changed.connect(func(_p): fired["phase"] += 1)
	GameState.add_dust(10)
	ok = ok and GameState.dust == 10 and GameState.spend_dust(4) and GameState.dust == 6 and not GameState.spend_dust(99)
	GameState.player_count = 4
	GameState.set_phase(GameState.Phase.MITTERNACHT)
	ok = ok and GameState.player_count == 4 and fired["players"] == 1 and fired["phase"] == 1 and fired["dust"] == 2
	for s in world.stars:
		var guard := 0
		while not s.is_clean and guard < 5000:
			s.wipe(s.to_global(s.spots[0].position), 0.9)
			guard += 1
		ok = ok and s.is_clean and is_equal_approx(s.progress, 1.0)
	ok = ok and world.cleaned_count() == world.stars.size()
	var total_spots := 0
	for st in world.stars:
		total_spots += st.total
	ok = ok and GameState.dust == 6 + total_spots * DUST_PER_SPOT   # 6 = Rest aus dem GameState-Test oben
	ok = ok and GameState.stars_cleaned == world.stars.size() and fired["cleaned"] == world.stars.size()
	print("SELFTEST cleaned=%d/%d progress_ok=%s" % [world.cleaned_count(), world.stars.size(), str(ok)])
	print("SELFTEST OK" if ok else "SELFTEST FAIL")
	get_tree().quit(0 if ok else 1)
