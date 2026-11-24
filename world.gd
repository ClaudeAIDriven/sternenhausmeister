class_name World
extends Node3D
## Wolkeninsel und die zu putzenden Sterne. Sendet Signale weiter, damit Main/HUD nur zuhören müssen.

signal star_scrubbed(star: Star, removed: int)
signal star_cleaned(star: Star)

const STAR_POSITIONS := [Vector3(0, 5.0, -7), Vector3(-9, 6.0, 1), Vector3(8, 5.5, 3)]

var stars: Array[Star] = []


func _init() -> void:
	name = "World"   # fester Name: RPC-Pfade müssen bei allen Spielern gleich sein


func _ready() -> void:
	_build_island()
	_build_stars()
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
