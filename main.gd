extends Node3D
## Einstieg: verbindet Himmel, Welt, Spieler, Ton und Anzeige. Die Details stecken in sky.gd, world.gd, hud.gd.

const DUST_PER_SPOT := 1
const PENTATONIC := [261.6, 293.7, 329.6, 392.0, 440.0, 523.3, 587.3, 659.3]

var sky: NightSky
var world: World
var player: Player
var players_root: Node3D
var spawner: PlayerSpawner
var hud: Hud
var sfx: Sfx
var dust: CPUParticles3D
var notes: Array[AudioStreamWAV] = []
var scrub_sound: AudioStreamWAV
var eat_sound: AudioStreamWAV
var hit_sound: AudioStreamWAV
var pop_sound: AudioStreamWAV
var pick_sound: AudioStreamWAV
var chime: Array[AudioStreamWAV] = []
var night: Night
var pause: Pause
var summary: NightSummary
var tutorial: Tutorial
var rules: Dictionary = {}   # I-08: gewählte Regeln (Presets)
var accessibility: Accessibility
var combo := Combo.new()   # G-12
var shop: Shop
var shop_ui: ShopUI
var health_ui: HealthUI
var minimap: Minimap
var weather: Weather        # M-01
var kitchen_ui: KitchenUI
var skills_ui: SkillsUI
var _rate_acc := 0.0
var achievements := Achievements.new()   # M-09
var _night_spots := 0
var _hat_index := -1
var swarm: FunItems.Swarm      # M-08
var _wish_timer := 60.0
var _trampolines: Array = []
var nights_played := 0              # M-02
var loaded_save := {}               # M-02: geladener Spielstand (Host/Solo)
var _peer_progress := {}            # Host: Spielername -> {xp, skills} der Mitspieler (für den Spielstand)
var note_idx := 0
var scrub_cooldown := 0.0


## Ohne Startoption (Kommandozeile oder Menü-Wahl) geht es ins Hauptmenü (U-01). `--nomenu` überspringt das Menü (Tests, Screenshots).
static func wants_menu(args: PackedStringArray, launch: Dictionary) -> bool:
	if not launch.is_empty():
		return false
	for a in ["--selftest", "--host", "--join", "--nomenu"]:
		if a in args:
			return false
	return true


func _ready() -> void:
	if wants_menu(OS.get_cmdline_user_args(), Menu.launch):
		get_tree().change_scene_to_file.call_deferred("res://menu.tscn")
		return
	_setup_input()
	sky = NightSky.new()
	add_child(sky)
	world = World.new()
	add_child(world)
	_build_sound()
	_build_player()
	hud = Hud.new()
	add_child(hud)
	shop = Shop.new()   # G-05: Upgrades (Wischradius wirkt hier, Tempo/Reichweite folgen mit player.gd)
	add_child(shop)
	add_child(HostInfo.new())   # I-07: eigene Adresse beim Hosten
	summary = NightSummary.new()   # U-05: Übersicht am Nachtende
	add_child(summary)
	summary.bind(world)
	accessibility = Accessibility.new()   # I-08: Untertitel, Farbenblind, UI-Größe (U-04)
	accessibility.load_options()
	add_child(accessibility)
	pause = Pause.new()   # U-03: Esc
	pause.accessibility = accessibility
	pause.achievements = achievements   # M-13
	add_child(pause)
	shop_ui = ShopUI.new()   # I-09: Werkstatt-Oberfläche (F an der Werkstatt, nach der Pause angelegt: Esc kommt zuerst hier an)
	add_child(shop_ui)
	shop_ui.bind(shop)
	health_ui = HealthUI.new()   # I-12
	add_child(health_ui)
	minimap = Minimap.new()   # I-14
	add_child(minimap)
	minimap.bind(world, night, players_root)
	NetworkManager.disconnected.connect(func(): get_tree().change_scene_to_file("res://menu.tscn"))
	_build_extras()
	_build_fun()
	_build_achievements()
	_build_saving()
	world.star_scrubbed.connect(_on_star_scrubbed)
	world.fruit_eaten.connect(func(_k: String): sfx.play(eat_sound, randf_range(0.95, 1.1), -3.0))
	world.fruit_picked.connect(func(_k: String): sfx.play(pick_sound, randf_range(0.95, 1.1), -6.0))
	world.enemy_removed.connect(func(_k: String, _w: int): sfx.play(pop_sound, randf_range(0.9, 1.2), -3.0))
	world.star_cleaned.connect(_on_star_cleaned)
	world.coop_bonus.connect(func(a: int): hud.show_puzzle_message("Teamarbeit! +%d Sternenstaub" % a, 4.0))   # G-13
	world.puzzle_changed.connect(func(done: int, total: int): hud.show_puzzle(world.puzzle.title if world.puzzle != null else "", done, total))
	world.puzzle_wrong.connect(func(_hint: int):
		_refresh_hud()   # geputzte Sterne zählen nach dem Zurücksetzen neu
		hud.show_puzzle_message("Falsche Reihenfolge! Die Sterne sind wieder schmutzig. Fang mit dem ersten Stern des Sternbilds von vorn an."))
	world.puzzle_solved.connect(func(bonus: int): hud.show_puzzle_message("Sternbild gelöst! +%d Sternenstaub ⭐" % bonus, 10.0))
	if world.puzzle != null:
		hud.show_puzzle(world.puzzle.title, world.puzzle.done, world.puzzle.total())
	_refresh_hud()
	night = Night.new()
	add_child(night)
	rules = Presets.effective(str(Menu.launch.get("preset", Presets.DEFAULT_ID)))   # I-08: Spielart aus dem Menü
	world.hint_mode = str(rules.get("hints", "after_mistake"))
	world._show_puzzle()
	tutorial = Tutorial.new()   # U-06: Anfängerhilfe, nur beim ersten Spiel
	add_child(tutorial)
	tutorial.bind(world, hud)
	night.start(float(rules.get("time_limit_s", Night.DEFAULT_DURATION)))   # G-01: Nacht mit sanftem Zeitlimit (Standard 10 Minuten)
	hud.bind_night(night)
	minimap.night = night
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
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var rm := InputEventMouseButton.new()
		rm.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("attack", rm)
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
	eat_sound = Sfx.make_melody([392.0, 523.3, 659.3], 0.07, 0.16, 0.35)   # Mampf: kleine aufsteigende Tonfolge
	hit_sound = Sfx.make_tone(95.0, 0.16, 0.6, 0.45)   # dumpfer Schlag
	pop_sound = Sfx.make_tone(620.0, 0.12, 0.4, 0.25)   # Gegner weggeputzt
	pick_sound = Sfx.make_tone(880.0, 0.07, 0.3)
	for f in [523.3, 659.3, 784.0, 1046.5]:
		chime.append(Sfx.make_tone(f, 1.4, 0.4))


func _build_player() -> void:
	players_root = Node3D.new()
	players_root.name = "Players"
	add_child(players_root)
	spawner = PlayerSpawner.new()
	add_child(spawner)
	spawner.setup(players_root)
	# Startart: Menü-Wahl (Menu.launch) oder Kommandozeile: -- --host   bzw.   -- --join <IP>
	var args := OS.get_cmdline_user_args()
	var pname := str(Settings.get_value("player_name"))
	var mode: String = str(Menu.launch.get("mode", ""))
	var ip: String = str(Menu.launch.get("ip", ""))
	if "--host" in args:
		mode = "host"
	elif "--join" in args and args.find("--join") + 1 < args.size():
		mode = "join"
		ip = args[args.find("--join") + 1]
	var err := OK
	if mode == "host":
		err = NetworkManager.host(NetworkManager.DEFAULT_PORT, pname)
	elif mode == "join":
		err = NetworkManager.join(ip, NetworkManager.DEFAULT_PORT, pname)
	if mode == "" or mode == "solo" or err != OK:
		if err != OK:
			push_warning("Netzwerkstart fehlgeschlagen (Fehler %d), starte allein." % err)
		spawner.spawn_offline()

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
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_H and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cycle_hat()
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not pause.is_open and not summary.is_open and not shop_ui.is_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	combo.tick(Time.get_ticks_msec() / 1000.0)
	scrub_cooldown = maxf(0.0, scrub_cooldown - delta)
	if player == null:   # eigenen Spieler suchen (online erscheint er erst nach der Replikation)
		player = spawner.local_player()
		if player != null:
			player.wipe_requested.connect(_on_wipe_requested)
			health_ui.bind(player)
			shop_ui.player_ref = player
			minimap.local_player = player
			_bind_player(player)
	if player != null:
		world.inventory.extra_slots = int(player.skills.add("bag_slots"))   # Fähigkeit: größerer Beutel
	_tick_fun(delta)
	dust.emitting = player != null and player.cleaning and player.aim_valid
	if dust.emitting:
		dust.global_position = player.aim_point


func _refresh_hud(extra := "") -> void:
	hud.show_status(world.cleaned_count(), world.stars.size(), extra)


func _on_wipe_requested(point: Vector3) -> void:
	var radius: float = shop.value("wipe_radius") * (player.wipe_factor() if player != null else 1.0)   # I-13: Rollen-Faktor
	var tool: int = player.tool_kind() if player != null else CleanTool.Kind.ANY   # G-25: Utensil bestimmt die Werkzeugart
	_rate_acc += player.wipe_rate() if player != null else 1.0   # Wischtempo: <1 lässt Frames aus, >1 wischt mehrfach
	var guard := 0
	while _rate_acc >= 1.0 and guard < 3:
		world.wipe_at(point, radius, tool)
		_rate_acc -= 1.0
		guard += 1
	_rate_acc = minf(_rate_acc, 2.0)
	if scrub_cooldown <= 0.0:
		sfx.play(scrub_sound, randf_range(0.9, 1.15), -6.0)
		scrub_cooldown = 0.11


func _on_star_scrubbed(_star: Star, removed: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var gain: float = float(combo.hit(now, removed, DUST_PER_SPOT)) * (player.mod("dust_gain") if player != null else 1.0)
	GameState.add_dust(int(round(gain)))   # G-04 + G-12: Staub beim Putzen, mit Kombo-Bonus; Fähigkeit dust_gain
	if player != null:
		player.xp.add_event("spot", removed)   # M-01: XP je Fleck
	achievements.count("spot", removed)
	_night_spots += removed
	sfx.play(notes[note_idx % notes.size()], combo.pitch(), -4.0)
	note_idx += 1


func _on_star_cleaned(star: Star) -> void:
	GameState.report_star_cleaned(star)
	achievements.count("star")
	if player != null:
		player.xp.add_event("star")
	for i in chime.size():
		sfx.play(chime[i], 1.0, -8.0)
	if world.cleaned_count() >= world.stars.size():
		_refresh_hud("Nacht geschafft! Der Himmel glänzt. ⭐")
	else:
		_refresh_hud("Stern geputzt!")


## M-01: Wetter, Küche, Fähigkeiten und XP-Quellen. Läuft einmal beim Start (Spieler kommt erst später, siehe _bind_player).
func _build_extras() -> void:
	weather = Weather.new()
	weather.name = "Weather"
	Presets.apply(Presets.effective(str(Menu.launch.get("preset", Presets.DEFAULT_ID))), null, weather)   # Zen/aus/normal
	add_child(weather)
	var pos: Array = []
	for s in world.stars:
		pos.append(s.position)
	weather.set_star_positions(pos)
	weather.seed_rng(4711)
	world.layout_changed.connect(func(_n: int):
		var p2: Array = []
		for s in world.stars:
			p2.append(s.position)
		weather.set_star_positions(p2))
	world.attach_weather(weather)
	weather.warning.connect(func(_k: int, text: String, secs: float): hud.show_puzzle_message(text, secs))
	kitchen_ui = KitchenUI.new()
	add_child(kitchen_ui)
	skills_ui = SkillsUI.new()
	add_child(skills_ui)
	world.enemy_removed.connect(func(kind: String, who: int):
		if player != null and who == NetworkManager.my_id():
			player.xp.add_event("enemy")
			hud.show_puzzle_message("%s besiegt! +XP" % kind.capitalize(), 3.0))
	world.puzzle_solved.connect(func(_b: int):
		if player != null:
			player.xp.add_event("constellation"))


## M-01: Sobald der eigene Spieler da ist: Küche/Fähigkeiten binden, XP für Kochen und Stufenaufstieg.
func _bind_player(p: Player) -> void:
	p.hit_landed.connect(func(_t: Player): sfx.play(hit_sound, randf_range(0.9, 1.1), 0.0))   # ich habe getroffen
	p.hurt.connect(func(_a: float): sfx.play(hit_sound, randf_range(0.7, 0.85), 0.0))        # ich wurde getroffen
	if not loaded_save.is_empty():   # Host/Solo: eigene Werte aus dem Spielstand
		SaveGame.restore_player(loaded_save.get("players", {}).get(str(Settings.get_value("player_name")), {}), p.xp, p.skills)
	p.kitchen = world.kitchen
	kitchen_ui.bind(world.kitchen, world.inventory, p)
	skills_ui.bind(p.skills)
	world.kitchen.cooked.connect(func(_id: String):
		p.xp.add_event("cook")
		achievements.count("cook")
		var bt: float = p.mod("buff_time") * Roles.factor(p.role, "buff_time")
		for st in world.kitchen.buffs:
			world.kitchen.buffs[st]["left"] = float(world.kitchen.buffs[st]["left"]) * bt
		var bonus_food: float = (p.mod("recipe_food") * Roles.factor(p.role, "recipe_food") - 1.0) * 30.0
		if bonus_food > 0.0:
			p.food.feed(bonus_food))
	p.helped_up.connect(func(_t): achievements.count("revive"))   # M-14: Erfolg "Retter"
	p.xp.leveled_up.connect(func(l: int): hud.show_puzzle_message("Stufe %d! Mit K Fähigkeiten lernen." % l, 5.0))


# ---------------------------------------------------------------- Speichern/Laden (M-02)

## Host/Solo: Pause-Knopf, Autosave am Nachtende, Laden aus dem Menü (launch["load"]). Mitspieler melden ihre Werte an den Host.
func _build_saving() -> void:
	var is_client := NetworkManager.is_online() and not multiplayer.is_server()
	if not is_client:
		pause.save_handler = func(): return save_now()
		pause.save_handler_ready()
		GameState.night_ended.connect(func():
			nights_played += 1
			save_now("autosave"))
		var map_choice := str(Menu.launch.get("map", Maps.DEFAULT_ID))
		world.set_map(map_choice)   # M-03: Karte aus dem Menü (Host/Solo)
		var seed_txt := str(Menu.launch.get("seed", ""))   # M-07: eigener Seed, sonst klassisch (Mondwiese) bzw. zufällig
		var seed_val := int(seed_txt) if seed_txt.is_valid_int() else (0 if map_choice == Maps.DEFAULT_ID else randi_range(1, 99999))
		if seed_val != 0 and str(Menu.launch.get("load", "")) == "":
			world.set_island_seed(seed_val)
		var slot := str(Menu.launch.get("load", ""))
		if slot != "":
			loaded_save = SaveGame.load_game(slot)
			if not loaded_save.is_empty():
				world.apply_map(str(loaded_save.get("map", Maps.DEFAULT_ID)))
				SaveGame.apply(loaded_save, world, GameState, shop)
				nights_played = int(loaded_save.get("night", 0))
	if not is_client and NetworkManager.is_online():
		NetworkManager.player_joined.connect(func(id: int):
			if id == 1 or loaded_save.is_empty():
				return
			var nm := str(NetworkManager.players.get(id, {}).get("name", ""))
			var pd: Dictionary = loaded_save.get("players", {}).get(nm, {})
			if not pd.is_empty():
				_rpc_restore_progress.rpc_id(id, pd))
	GameState.night_ended.connect(func():
		if is_client and player != null:
			_rpc_report_progress.rpc_id(1, str(Settings.get_value("player_name")), SaveGame.player_data(player.xp, player.skills)))


func _save_slot_name() -> String:
	return str(Menu.launch.get("slot", "")) if str(Menu.launch.get("slot", "")) != "" else "Spielstand"


## Speichert den Spielstand (Standard: Slot aus dem Menü oder "Spielstand"). Gibt OK oder einen Fehlercode zurück.
func save_now(slot: String = "") -> int:
	var pl := {}
	var my_name := str(Settings.get_value("player_name"))
	if player != null:
		pl[my_name] = {"xp": player.xp, "skills": player.skills}
	var data := SaveGame.capture(world, GameState, shop, pl, nights_played, world.island_seed)
	data["map"] = world.map_id
	for n in _peer_progress:   # Mitspieler: zuletzt gemeldeter Stand
		data["players"][n] = _peer_progress[n]
	return SaveGame.save(slot if slot != "" else _save_slot_name(), data)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_report_progress(pname: String, pdata: Dictionary) -> void:
	if multiplayer.is_server() and pname.length() <= 40:
		_peer_progress[pname] = pdata


## Host -> Spieler: gespeicherte Werte nach Spielername zurückgeben (beim Beitritt).
@rpc("authority", "call_remote", "reliable")
func _rpc_restore_progress(pdata: Dictionary) -> void:
	if player != null:
		SaveGame.restore_player(pdata, player.xp, player.skills)


# ---------------------------------------------------------------- Spaß (M-08)

func _build_fun() -> void:
	swarm = FunItems.Swarm.new()
	swarm.name = "Gluehwuermchen"
	add_child(swarm)
	_rebuild_trampolines()
	world.layout_changed.connect(func(_n: int): _rebuild_trampolines())


func _rebuild_trampolines() -> void:
	for t in _trampolines:
		if is_instance_valid(t):
			t.queue_free()
	_trampolines.clear()
	var pos: Array = []
	for s in world.stars:
		pos.append(s.position)
	for sp in FunItems.trampoline_spots(pos):
		var t := FunItems.Trampoline.new()
		t.position = sp
		world.add_child(t)
		_trampolines.append(t)


func _tick_fun(delta: float) -> void:
	if player == null:
		return
	swarm.update_swarm(player.global_position, world.stars, delta)
	_wish_timer -= delta
	if _wish_timer <= 0.0:   # alle 70–120 s eine Wunsch-Sternschnuppe in Reichweite des Spielers
		_wish_timer = randf_range(70.0, 120.0)
		var w := FunItems.WishStar.new()
		var a := randf() * TAU
		w.position = Vector3(player.global_position.x + cos(a) * 9.0, 2.2, player.global_position.z + sin(a) * 9.0)
		world.add_child(w)
		hud.show_puzzle_message("Eine Wunsch-Sternschnuppe! Fang sie!", 5.0)
		w.caught.connect(func(_p, stat: String):
			achievements.count("wish")
			hud.show_puzzle_message("Wunsch erfüllt: %s +20 %% für 60 s" % str(FunItems.WISH_STATS.get(stat, stat)), 5.0))


# ---------------------------------------------------------------- Erfolge (M-09)

func _build_achievements() -> void:
	achievements.load_file()
	achievements.unlocked.connect(func(_id: String, title: String, hat: String):
		hud.show_puzzle_message("Erfolg: %s%s" % [title, "  ·  neuer Hut (H wechselt)" if hat != "" else ""], 6.0))
	world.enemy_removed.connect(func(kind: String, who: int):
		if who == NetworkManager.my_id():
			achievements.count(kind))
	world.puzzle_solved.connect(func(_b: int): achievements.count("constellation"))
	world.fruit_picked.connect(func(_k: String): achievements.count("fruit"))
	GameState.dust_changed.connect(func(a: int): achievements.set_max("dust_max", GameState.dust))
	GameState.night_ended.connect(func():
		achievements.record_night(nights_played + 1, GameState.stars_cleaned, GameState.dust, _night_spots)
		_night_spots = 0)


## H: nächsten freigeschalteten Hut aufsetzen ("" = Rollenhut). M-13: über den Spieler repliziert, alle sehen ihn.
func cycle_hat() -> String:
	var opts: Array = [""] + achievements.hats
	_hat_index = (_hat_index + 1) % opts.size()
	var id: String = opts[_hat_index]
	if player != null and player.look != null:
		player.hat_override = id
		PlayerLook.update_hat(player.look, id if id != "" else player.role)
	return id


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
	var bonus: int = world.puzzle.bonus() if world.puzzle != null and world.puzzle.is_solved else 0   # I-04: Sternbild gelöst = Bonus-Staub
	# 6 = Rest aus dem GameState-Test oben; G-12: Kombo gibt je Stufe bis +50 % Staub (hier wischt der Test schnell am Stück)
	var base_dust := 6 + total_spots * DUST_PER_SPOT + bonus
	ok = ok and GameState.dust >= base_dust and GameState.dust <= base_dust + int(total_spots * DUST_PER_SPOT * Combo.MAX_LEVEL * Combo.BONUS_PER_LEVEL) + 1
	ok = ok and GameState.stars_cleaned == world.stars.size() and fired["cleaned"] == world.stars.size()
	print("SELFTEST cleaned=%d/%d progress_ok=%s" % [world.cleaned_count(), world.stars.size(), str(ok)])
	print("SELFTEST OK" if ok else "SELFTEST FAIL")
	get_tree().quit(0 if ok else 1)
