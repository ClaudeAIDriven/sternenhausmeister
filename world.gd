class_name World
extends Node3D
## Wolkeninsel und die zu putzenden Sterne. Sendet Signale weiter, damit Main/HUD nur zuhören müssen.

signal star_scrubbed(star: Star, removed: int)
signal star_cleaned(star: Star)

const STAR_POSITIONS := [Vector3(0, 5.0, -7), Vector3(-9, 6.0, 1), Vector3(8, 5.5, 3),
	Vector3(4.5, 6.2, -11.0), Vector3(-12.0, 5.5, -6.0), Vector3(-3.0, 6.0, 9.5),
	Vector3(11.0, 6.0, 8.0), Vector3(-6.5, 6.5, -10.5)]
const MIN_STARS := 3
## Ein Spieler bekommt 3 Sterne, jeder weitere Spieler einen mehr (bis 8). Zeitlimit bleibt gleich, also mehr Arbeit für mehr Hände.
const STARS_PER_EXTRA_PLAYER := 1

signal layout_changed(star_count: int)
signal puzzle_changed(done: int, total: int)    # Fortschritt im Sternbild
signal puzzle_wrong(hint_star: int)             # falsche Reihenfolge: Sterne wurden zurückgesetzt, hint_star ist als Nächstes dran
signal puzzle_solved(bonus: int)                # Sternbild gelöst, Bonus-Staub gutgeschrieben (Host)

var puzzle: Constellation
var lines: ConstellationLines
var balloon: Balloon

var stars: Array[Star] = []


func _init() -> void:
	name = "World"   # fester Name: RPC-Pfade müssen bei allen Spielern gleich sein


func _ready() -> void:
	_build_island()
	_build_stars(star_count_for(_player_count()))
	GameState.player_count_changed.connect(func(_n): _rescale())
	NetworkManager.players_changed.connect(_rescale)
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.connected_to_host.connect(_request_state)
	if NetworkManager.is_online() and not multiplayer.is_server() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_request_state()


## Wischt an einem Weltpunkt über alle Sterne. Gibt die Zahl entfernter Flecken zurück.
## Online: Clients schicken nur eine Anfrage an den Host (Rückgabe 0); der Host wischt und repliziert die Fleck-IDs.
func wipe_at(point: Vector3, radius: float, tool: int = CleanTool.Kind.ANY) -> int:
	if NetworkManager.is_online() and not multiplayer.is_server():
		_rpc_wipe.rpc_id(1, point, radius, tool)
		return 0
	return _wipe_authoritative(point, radius, tool)


func _wipe_authoritative(point: Vector3, radius: float, tool: int) -> int:
	var removed := 0
	for i in stars.size():
		removed += stars[i].wipe(point, radius, tool)
		if NetworkManager.is_online() and not stars[i].last_removed.is_empty():
			_rpc_removed.rpc(i, stars[i].last_removed)
	return removed


@rpc("any_peer", "call_remote", "reliable")
func _rpc_wipe(point: Vector3, radius: float, tool: int) -> void:
	if not multiplayer.is_server():
		return
	# Host prüft die Anfrage: sinnvolle Größen, Punkt in Reichweite der Insel
	if not is_finite(radius) or radius <= 0.0 or radius > 100.0 or point.length() > 60.0:
		return
	if tool < 0 or tool >= CleanTool.Kind.size():
		return
	_wipe_authoritative(point, radius, tool)


@rpc("authority", "call_remote", "reliable")
func _rpc_removed(star_idx: int, ids: Array) -> void:
	if star_idx >= 0 and star_idx < stars.size():
		stars[star_idx].apply_removed(ids)


func _request_state() -> void:
	_rpc_request_state.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_state() -> void:
	if multiplayer.is_server():
		_send_state(multiplayer.get_remote_sender_id())


func _on_player_joined(id: int) -> void:
	if multiplayer.is_server() and id != 1:
		_send_state(id)


func _send_state(peer: int) -> void:
	_rpc_layout.rpc_id(peer, stars.size())   # zuerst das Layout, dann die entfernten Flecken
	if puzzle != null:
		_rpc_puzzle.rpc_id(peer, puzzle.done, puzzle.is_solved, [])
	for i in stars.size():
		if not stars[i].removed_ids.is_empty():
			_rpc_removed.rpc_id(peer, i, stars[i].removed_ids)


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
	mat.albedo_color = Palette.UI_IVORY.darkened(0.1)   # Wolkenränder
	mat.emission_enabled = true
	mat.emission = Palette.ISLAND
	mat.emission_energy_multiplier = 0.2
	mat.roughness = 0.9
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = IslandProps.ground_material(5.0)   # A-12: handgemalt wirkender Boden
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 14.0
	shape.height = 2.0
	cs.shape = shape
	body.add_child(cs)
	body.position.y = -1.0
	add_child(body)

	_decorate_island()
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


## Sternzahl für eine Spielerzahl (1–4+): 1 -> 3, 2 -> 4, 3 -> 5, 4 -> 6 … höchstens 8.
static func star_count_for(players: int) -> int:
	return clampi(MIN_STARS + (maxi(1, players) - 1) * STARS_PER_EXTRA_PLAYER, MIN_STARS, STAR_POSITIONS.size())


## Ereignisdichte (Wetter, Sternschnuppen): Faktor 1.0 bei einem Spieler, wächst mit der Spielerzahl, höchstens 2.5.
static func event_density_for(players: int) -> float:
	return minf(1.0 + (maxi(1, players) - 1) * 0.35, 2.5)


func event_density() -> float:
	return event_density_for(_player_count())


func _player_count() -> int:
	var n: int = GameState.player_count
	if NetworkManager.is_online():
		n = maxi(n, NetworkManager.players.size())
	return n


## Host/Solo: passt die Sternzahl an, solange noch nichts geputzt wurde (sonst ginge Fortschritt verloren).
func _rescale() -> void:
	if NetworkManager.is_online() and not multiplayer.is_server():
		return   # Clients bekommen das Layout vom Host
	var want := star_count_for(_player_count())
	if want == stars.size() or _touched():
		return
	_build_stars(want)
	if NetworkManager.is_online():
		_rpc_layout.rpc(want)


func _touched() -> bool:
	for s in stars:
		if s.progress > 0.0 or s.is_clean:
			return true
	return false


@rpc("authority", "call_remote", "reliable")
func _rpc_layout(count: int) -> void:
	if count != stars.size():
		_build_stars(count)


## Gras, Steine, Büsche, Laternen, Werkstatt und Schild (A-12, A-03). Rein optisch, ohne Kollision.
func _decorate_island() -> void:
	var deco := IslandProps.decorate(13.0, 42)
	deco.name = "Deko"
	add_child(deco)
	for p in [Vector3(4, 0, 6), Vector3(-5, 0, 7), Vector3(7, 0, -5)]:
		var lamp := IslandProps.lantern()
		lamp.position = p
		add_child(lamp)
	var shop_house := Props.workshop()
	shop_house.position = Vector3(-8, 0, -6)
	shop_house.rotation.y = 0.6
	add_child(shop_house)
	# Ballon (G-10): steigt mit Mitfahrern, so werden die hohen Sterne erreichbar
	balloon = Balloon.new()
	balloon.name = "Ballon"
	balloon.position = Vector3(9.5, 0.15, -2.0)
	add_child(balloon)
	var sign := IslandProps.sign_post("Werkstatt")
	sign.position = Vector3(-5, 0, -3.5)
	add_child(sign)


func _build_stars(count: int) -> void:
	for old in stars:
		old.queue_free()
	stars.clear()
	for i in count:
		var p: Vector3 = STAR_POSITIONS[i]
		var s := Star.new()
		s.position = p
		add_child(s)
		s.scrubbed.connect(func(n: int): star_scrubbed.emit(s, n))
		s.cleaned.connect(func():
			Effects.sparkle_burst(self, s.position, s.radius)   # A-05: Funkel-Burst beim Abschluss
			star_cleaned.emit(s)
			_on_star_cleaned(s))
		stars.append(s)
	_setup_puzzle()
	layout_changed.emit(count)


# ---------------------------------------------------------------- Sternbild-Rätsel (I-04)

## Größtes Beispiel-Sternbild, das zur Sternzahl passt (3 Sterne: Dreieck, 5-6: Kassiopeia, 7-8: Kleiner Wagen).
## Seine Sterne sind die ersten n Welt-Sterne; weitere Sterne sind frei (kein Rätsel).
func _setup_puzzle() -> void:
	if lines != null:
		lines.queue_free()
		lines = null
	puzzle = null
	var best: Dictionary = {}
	for d in ConstellationLoader.load_dir("res://data/constellations"):
		var n: int = d["stars"].size()
		if n <= stars.size() and (best.is_empty() or n > best["stars"].size()):
			best = d
	if best.is_empty():
		return
	puzzle = Constellation.from_data(best)
	puzzle.wrong.connect(func(_s: int, _h: int, red: Array): _last_redirty = red)
	lines = ConstellationLines.new()
	lines.name = "Sternbild"
	add_child(lines)
	var pts: Array[Vector3] = []
	for id in puzzle.order:
		pts.append(stars[id].position)
	lines.build(pts)
	_show_puzzle()
	puzzle_changed.emit(0, puzzle.total())


func _star_index(s: Star) -> int:
	return stars.find(s)


func _on_star_cleaned(s: Star) -> void:
	if puzzle == null or (NetworkManager.is_online() and not multiplayer.is_server()):
		return   # nur der Host entscheidet
	var idx := _star_index(s)
	if idx < 0 or not puzzle.positions.has(idx):
		return
	var result := puzzle.report_cleaned(idx)
	var redirty: Array = []
	if result == "wrong":
		# Sterne zurücksetzen (alle bisherigen plus der falsche); Hinweis = nächster richtiger
		redirty = _last_redirty
		for i in redirty:
			stars[i].reset()
	if result == "solved":
		GameState.add_dust(puzzle.bonus())
		puzzle_solved.emit(puzzle.bonus())
	_show_puzzle()
	if NetworkManager.is_online():
		_rpc_puzzle.rpc(puzzle.done, puzzle.is_solved, redirty)
	if result == "wrong":
		puzzle_wrong.emit(puzzle.hint())


var _last_redirty: Array = []


func _show_puzzle() -> void:
	if puzzle == null or lines == null:
		return
	var n := puzzle.total()
	if puzzle.is_solved:
		lines.finish()
	else:
		lines.set_progress(float(maxi(puzzle.done - 1, 0)) / float(maxi(n - 1, 1)))
	for i in stars.size():
		stars[i].set_hint(not puzzle.is_solved and puzzle.positions.has(i) and puzzle.hint() == i and puzzle.done > 0)
	puzzle_changed.emit(puzzle.done, n)


@rpc("authority", "call_remote", "reliable")
func _rpc_puzzle(done: int, solved: bool, redirty: Array) -> void:
	if puzzle == null:
		return
	for i in redirty:
		if i >= 0 and i < stars.size():
			stars[i].reset()
	puzzle.done = done
	puzzle.is_solved = solved
	_show_puzzle()
	if not redirty.is_empty():
		puzzle_wrong.emit(puzzle.hint())
