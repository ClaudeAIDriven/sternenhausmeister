class_name World
extends Node3D
## Wolkeninsel und die zu putzenden Sterne. Sendet Signale weiter, damit Main/HUD nur zuhören müssen.

signal star_scrubbed(star: Star, removed: int)
signal star_cleaned(star: Star)

## I-11: Die Insel ist ~2,3-mal so groß wie früher (Radius 32 statt 14). Sterne liegen weit verteilt; Werkstatt und Ballon bilden die Mitte.
const ISLAND_RADIUS := 32.0
const STAR_SPREAD := 2.0
const BASE_STAR_POSITIONS := [Vector3(0, 5.0, -7), Vector3(-9, 6.0, 1), Vector3(8, 5.5, 3),
	Vector3(4.5, 6.2, -11.0), Vector3(-12.0, 5.5, -6.0), Vector3(-3.0, 6.0, 9.5),
	Vector3(11.0, 6.0, 8.0), Vector3(-6.5, 6.5, -10.5)]
## Weltpositionen: Grundmuster (Sternbild-Formen bleiben erhalten) in x/z gestreckt.
static var STAR_POSITIONS: Array = _spread_stars()
const WORKSHOP_POS := Vector3(-8, 0, -6)
const WORKSHOP_RANGE := 6.0
const LAVA_SPOTS := [Vector3(24, 0, -4), Vector3(-20, 0, 20)]
const SPIDER_SPOTS := [Vector3(-9, 0, 17), Vector3(14, 0, -21), Vector3(-23, 0, -9)]
const CACTUS_SPOTS := [Vector3(12, 0, 12), Vector3(-3, 0, -25), Vector3(20, 0, -18), Vector3(-25, 0, 6), Vector3(4, 0, 25), Vector3(-14, 0, -2)]


static func _spread_stars() -> Array:
	var out: Array = []
	for p in BASE_STAR_POSITIONS:
		out.append(Vector3(p.x * STAR_SPREAD, p.y, p.z * STAR_SPREAD))
	return out
const MIN_STARS := 3
## Ein Spieler bekommt 3 Sterne, jeder weitere Spieler einen mehr (bis 8). Zeitlimit bleibt gleich, also mehr Arbeit für mehr Hände.
const STARS_PER_EXTRA_PLAYER := 1

signal layout_changed(star_count: int)
signal puzzle_changed(done: int, total: int)    # Fortschritt im Sternbild
signal puzzle_wrong(hint_star: int)             # falsche Reihenfolge: Sterne wurden zurückgesetzt, hint_star ist als Nächstes dran
signal puzzle_solved(bonus: int)                # Sternbild gelöst, Bonus-Staub gutgeschrieben (Host)
signal coop_bonus(amount: int)                  # G-13: Teamarbeit am selben Stern, Bonus-Staub gutgeschrieben (bei jedem Beteiligten)

## G-13: Putzen mindestens zwei Spieler denselben Stern (je >= COOP_MIN_SPOTS Flecken, innerhalb COOP_WINDOW Sekunden vor dem
## Abschluss), bekommen alle Beteiligten COOP_BONUS Sternenstaub. Nur der Host zählt mit.
const COOP_MIN_SPOTS := 4
const COOP_WINDOW := 90.0
const COOP_BONUS := 5
var _pending_coop: Array = []   # Sterne, die im laufenden Wisch fertig wurden
var _contrib: Dictionary = {}   # Stern-Index -> {Peer-ID: [Flecken, letzte Zeit]}

var hint_mode := "after_mistake"   # I-08: aus dem Preset ("none" | "after_mistake" | "always")
var puzzle: Constellation
var lines: ConstellationLines
var balloon: Balloon

var stars: Array[Star] = []

## G-22: Früchte an festen Plätzen (bei allen gleich), Aufheben mit F, Essen mit Q. Der Host entscheidet, wer eine Frucht bekommt.
const FRUIT_SPOTS := [
	[Vector3(12, 0, 10), "sternbeere"], [Vector3(-14, 0, 8), "sternbeere"], [Vector3(2, 0, -14), "sternbeere"],
	[Vector3(16, 0, -8), "mondapfel"], [Vector3(-16, 0, -12), "mondapfel"], [Vector3(-4, 0, 16), "mondapfel"],
	[Vector3(20, 0, 3), "wolkenpilz"], [Vector3(-20, 0, 0), "wolkenpilz"], [Vector3(6, 0, 22), "wolkenpilz"]]
const FRUIT_RANGE := 2.5
signal fruit_picked(kind: String)    # eine Frucht liegt jetzt im eigenen Inventar
signal fruit_eaten(kind: String)
signal fruit_message(text: String)
var fruits: Array[Fruit] = []
var inventory := Inventory.new()
var pick_log: Array = []             # Host: wer hat welche Frucht bekommen (für Tests)

## G-15: Sternschnuppen-Treffer bringen wenige Flecken auf einen geputzten Stern zurück (nur Host entscheidet, wird synchronisiert).
## Zen (`zen = true`) schaltet das ab. Beim erneuten Putzen zählt der Stern nicht noch einmal fürs Sternbild/den Team-Bonus.
const METEOR_SPOTS_MIN := 3
const METEOR_SPOTS_MAX := 6
signal star_redirtied(star: Star, restored: int)
var zen := false
var _recleaning := {}   # Stern-Index -> true, solange er nach einem Treffer wieder sauber gewischt werden muss


func _init() -> void:
	name = "World"   # fester Name: RPC-Pfade müssen bei allen Spielern gleich sein


func _ready() -> void:
	_build_island()
	_build_fruits()
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
	return _wipe_authoritative(point, radius, tool, NetworkManager.my_id())


func _wipe_authoritative(point: Vector3, radius: float, tool: int, who: int = 1) -> int:
	var removed := 0
	for i in stars.size():
		var n := stars[i].wipe(point, radius, tool)
		removed += n
		if n > 0:
			note_contribution(i, who, n, Time.get_ticks_msec() / 1000.0)
		if NetworkManager.is_online() and not stars[i].last_removed.is_empty():
			_rpc_removed.rpc(i, stars[i].last_removed)
	for idx in _pending_coop:   # erst jetzt: der letzte Wisch zählt noch für den Abschluss mit
		_pay_coop(idx)
	_pending_coop.clear()
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
	_wipe_authoritative(point, radius, tool, multiplayer.get_remote_sender_id())


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
	var avail: Array = []
	for f in fruits:
		avail.append(f.available)
	_rpc_fruit_state.rpc_id(peer, avail)
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
	mesh.top_radius = ISLAND_RADIUS
	mesh.bottom_radius = ISLAND_RADIUS * 0.65
	mesh.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Palette.UI_IVORY.darkened(0.1)   # Wolkenränder
	mat.emission_enabled = true
	mat.emission = Palette.ISLAND
	mat.emission_energy_multiplier = 0.2
	mat.roughness = 0.9
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = IslandProps.ground_material(5.0 * ISLAND_RADIUS / 14.0)   # A-12: handgemalt wirkender Boden
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = ISLAND_RADIUS
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
	for i in 40:
		var a := TAU * i / 40.0
		var p := MeshInstance3D.new()
		p.mesh = puff
		p.material_override = mat
		p.position = Vector3(cos(a) * (ISLAND_RADIUS - 0.5), -0.4 + rng.randf() * 0.6, sin(a) * (ISLAND_RADIUS - 0.5))
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


## Gras, Steine, Büsche, Laternen, Werkstatt und Schild (A-12, A-03). Haus, Laternen und Schild haben Kollision.
func _decorate_island() -> void:
	var deco := IslandProps.decorate(ISLAND_RADIUS - 1.0, 42, 700, 90, 36)
	deco.name = "Deko"
	add_child(deco)
	for p in [Vector3(4, 0, 6), Vector3(-5, 0, 7), Vector3(7, 0, -5)]:
		var lamp := IslandProps.lantern()
		lamp.position = p
		add_child(lamp)
		_add_cylinder_collider(lamp, 0.25, 2.5)
	var shop_house := Props.workshop()
	shop_house.position = WORKSHOP_POS
	shop_house.rotation.y = 0.6
	add_child(shop_house)
	# Kollision (I-11): Wände der Hütte und Werkbank sind fest; Maße wie in Props.workshop()
	_add_box_collider(shop_house, Vector3(4.0, 2.4, 3.0), Vector3(0, 1.2, 0))
	_add_box_collider(shop_house, Vector3(1.8, 0.9, 0.8), Vector3(3.0, 0.45, 0.0))
	# Ballon (G-10): steigt mit Mitfahrern, so werden die hohen Sterne erreichbar
	balloon = Balloon.new()
	balloon.name = "Ballon"
	balloon.position = Vector3(9.5, Balloon.GROUND_Y, -2.0)   # Plattform bündig mit dem Boden: man läuft einfach hinauf
	add_child(balloon)
	var sign := IslandProps.sign_post("Werkstatt")
	sign.position = Vector3(-5, 0, -3.5)
	add_child(sign)
	_add_cylinder_collider(sign, 0.3, 2.0)
	for sp in LAVA_SPOTS:   # Gefahren (I-12)
		var lava := Hazard.new()
		lava.kind = "lava"
		lava.radius = 3.0
		lava.position = sp
		lava.add_to_group("hazards")
		add_child(lava)
	for sp in SPIDER_SPOTS:   # Spinnennester (I-13): schrecken Rollen mit Spinnenangst zurück
		var nest := Hazard.new()
		nest.kind = "spider"
		nest.radius = 3.0
		nest.position = sp
		nest.add_to_group("hazards")
		add_child(nest)
	for sp in CACTUS_SPOTS:
		var c := Hazard.new()
		c.kind = "cactus"
		c.position = sp
		c.add_to_group("hazards")
		add_child(c)


func _add_box_collider(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = pos
	body.add_child(cs)
	parent.add_child(body)


func _add_cylinder_collider(parent: Node3D, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	cs.position.y = height * 0.5
	body.add_child(cs)
	parent.add_child(body)


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


## Merkt, wie viele Flecken `who` an Stern `idx` entfernt hat.
func note_contribution(idx: int, who: int, spots: int, now: float) -> void:
	var d: Dictionary = _contrib.get(idx, {})
	var e: Array = d.get(who, [0, now])
	d[who] = [int(e[0]) + spots, now]
	_contrib[idx] = d


## Wer bekommt den Co-op-Bonus? Leer, wenn weniger als zwei Spieler genug beigetragen haben.
static func coop_recipients(contrib: Dictionary, now: float) -> Array:
	var out := []
	for peer in contrib:
		var e: Array = contrib[peer]
		if int(e[0]) >= COOP_MIN_SPOTS and now - float(e[1]) <= COOP_WINDOW:
			out.append(peer)
	return out if out.size() >= 2 else []


func _pay_coop(idx: int) -> void:
	var who := coop_recipients(_contrib.get(idx, {}), Time.get_ticks_msec() / 1000.0)
	_contrib.erase(idx)
	for peer in who:
		if peer == NetworkManager.my_id():
			_apply_coop(COOP_BONUS)
		elif NetworkManager.is_online():
			_rpc_coop.rpc_id(peer, COOP_BONUS)


func _apply_coop(amount: int) -> void:
	GameState.add_dust(amount)
	coop_bonus.emit(amount)


@rpc("authority", "call_remote", "reliable")
func _rpc_coop(amount: int) -> void:
	if amount > 0 and amount <= 50:
		_apply_coop(amount)


func _on_star_cleaned(s: Star) -> void:
	var cidx := _star_index(s)
	if _recleaning.has(cidx):
		_recleaning.erase(cidx)
		return   # G-15: nur wieder sauber gemacht, Sternbild und Team-Bonus zählen den Stern nicht doppelt
	if not (NetworkManager.is_online() and not multiplayer.is_server()):
		_pending_coop.append(_star_index(s))
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
			_recleaning.erase(i)
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
		stars[i].set_hint(not puzzle.is_solved and puzzle.positions.has(i) and puzzle.hint() == i and hint_mode != "none" and (hint_mode == "always" or puzzle.done > 0))
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


# ---------------------------------------------------------------- Sternschnuppen (G-15)

## Meteor-Treffer (Host): `star_idx` ist das Ziel; ist er nicht sauber, trifft es einen zufälligen geputzten Stern.
## Gibt die Zahl zurückgekehrter Flecken zurück (0: Zen, Client, nichts Sauberes, Sternbild schon gelöst).
func meteor_strike(star_idx: int, rng: RandomNumberGenerator = null) -> int:
	if zen or (NetworkManager.is_online() and not multiplayer.is_server()):
		return 0
	if puzzle != null and puzzle.is_solved:
		return 0   # gelöstes Sternbild bleibt gelöst
	var clean: Array[int] = []
	for i in stars.size():
		if stars[i].is_clean:
			clean.append(i)
	if clean.is_empty():
		return 0
	var idx := star_idx
	if not clean.has(idx):
		idx = clean[(rng.randi() if rng != null else randi()) % clean.size()]
	var n := METEOR_SPOTS_MIN + (rng.randi() if rng != null else randi()) % (METEOR_SPOTS_MAX - METEOR_SPOTS_MIN + 1)
	var ids := stars[idx].redirty(n, rng)
	if ids.is_empty():
		return 0
	_recleaning[idx] = true
	if NetworkManager.is_online():
		_rpc_restored.rpc(idx, ids)
	star_redirtied.emit(stars[idx], ids.size())
	return ids.size()


@rpc("authority", "call_remote", "reliable")
func _rpc_restored(star_idx: int, ids: Array) -> void:
	if star_idx >= 0 and star_idx < stars.size():
		var n := stars[star_idx].apply_restored(ids)
		if n > 0:
			star_redirtied.emit(stars[star_idx], n)


## Verbindet ein Weather mit der Welt (Zen = `cosmetic` schaltet Treffer aus). Aufruf ersetzt keine Sternpositionen.
func attach_weather(w: Weather) -> void:
	w.meteor_strike.connect(func(i: int): meteor_strike(i))
	zen = w.cosmetic


# ---------------------------------------------------------------- Früchte (G-22)

func _build_fruits() -> void:
	for spot in FRUIT_SPOTS:
		var f := Fruit.new()
		f.kind = spot[1]
		f.position = spot[0]
		add_child(f)
		fruits.append(f)


## Index der nächsten verfügbaren Frucht in Reichweite um `pos` (-1: keine).
func nearest_fruit(pos: Vector3) -> int:
	var best := -1
	var best_d := FRUIT_RANGE
	for i in fruits.size():
		if not fruits[i].available:
			continue
		var d := Vector2(fruits[i].global_position.x - pos.x, fruits[i].global_position.z - pos.z).length()
		if d < best_d:
			best_d = d
			best = i
	return best


## Frucht aufheben (Taste F). Gibt den Index der angefragten Frucht zurück (-1: nichts in Reichweite oder Inventar voll).
## Online fragen Clients den Host; ob sie die Frucht wirklich bekommen, entscheidet der Host.
func try_pick(pos: Vector3) -> int:
	var idx := nearest_fruit(pos)
	if idx < 0:
		return -1
	if inventory.is_full():
		fruit_message.emit("Dein Beutel ist voll (6 Plätze). Iss mit Q etwas.")
		return -1
	if NetworkManager.is_online() and not multiplayer.is_server():
		_rpc_pick.rpc_id(1, idx)
		return idx
	_pick_authoritative(idx, NetworkManager.my_id())
	return idx


func _pick_authoritative(idx: int, who: int) -> bool:
	if idx < 0 or idx >= fruits.size() or not fruits[idx].available:
		return false
	var node := _player_node(who)
	if node != null and Vector2(node.global_position.x - fruits[idx].global_position.x, node.global_position.z - fruits[idx].global_position.z).length() > FRUIT_RANGE + 2.0:
		return false   # zu weit weg (Schummelschutz, großzügig wegen Verzögerung)
	var kind := fruits[idx].kind
	fruits[idx].set_available(false)
	pick_log.append([who, idx])
	if NetworkManager.is_online():
		_rpc_fruit.rpc(idx, false)
	if who == NetworkManager.my_id() or not NetworkManager.is_online():
		_receive_fruit(kind)
	else:
		_rpc_give.rpc_id(who, kind)
	return true


func _player_node(who: int) -> Node3D:
	for n in get_tree().get_nodes_in_group("players"):
		if str(n.name) == str(who):
			return n as Node3D
	return null


func _receive_fruit(kind: String) -> void:
	if inventory.add(kind):
		fruit_picked.emit(kind)
		fruit_message.emit("%s eingesammelt (Q: essen)" % Fruit.display_name(kind))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pick(idx: int) -> void:
	if multiplayer.is_server():
		_pick_authoritative(idx, multiplayer.get_remote_sender_id())


@rpc("authority", "call_remote", "reliable")
func _rpc_give(kind: String) -> void:
	_receive_fruit(kind)


@rpc("authority", "call_remote", "reliable")
func _rpc_fruit(idx: int, available: bool) -> void:
	if idx >= 0 and idx < fruits.size():
		fruits[idx].set_available(available)


@rpc("authority", "call_remote", "reliable")
func _rpc_fruit_state(avail: Array) -> void:
	for i in mini(avail.size(), fruits.size()):
		fruits[i].set_available(bool(avail[i]))


## Essen (Taste Q): die vorderste Frucht füllt die Sättigung des eigenen Spielers.
func eat_fruit(player: Player) -> String:
	if player == null:
		return ""
	var kind := inventory.eat(player.food)
	if kind != "":
		fruit_eaten.emit(kind)
		fruit_message.emit("%s gegessen" % Fruit.display_name(kind))
	return kind


func _local_player() -> Player:
	for n in get_tree().get_nodes_in_group("players"):
		var p := n as Player
		if p != null and p.is_multiplayer_authority():
			return p
	return null


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo) or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var p := _local_player()
	if p == null or p.downed:
		return
	if event.physical_keycode == KEY_F:
		try_pick(p.global_position)
	elif event.physical_keycode == KEY_Q:
		eat_fruit(p)


func _process(delta: float) -> void:
	if NetworkManager.is_online() and not multiplayer.is_server():
		return   # nur der Host lässt Früchte nachwachsen
	for i in fruits.size():
		if fruits[i].tick(delta) and NetworkManager.is_online():
			_rpc_fruit.rpc(i, true)
