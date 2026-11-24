class_name Balloon
extends AnimatableBody3D
## Ballon-Plattform (G-10): steigt, solange mindestens ein Spieler an Bord ist, bis zur Zielhöhe
## und sinkt sanft zurück, wenn leer. Mehrere Spieler können gleichzeitig mitfahren (Koop).
## Einbau (nicht Teil dieser Karte): `var b := Balloon.new(); b.position = ...; add_child(b)`.
## Als AnimatableBody3D nimmt er CharacterBody3D-Spieler auf der Plattform mit.

signal reached_top
signal returned

const GROUND_Y := -0.13   # Oberkante der Plattform liegt 2 cm über dem Boden (y=0): ebenerdig betretbar
const RISE_SPEED := 2.5   # m/s aufwärts
const FALL_SPEED := 1.5   # m/s abwärts, wenn leer
const BOARD_SIZE := Vector3(3.0, 0.3, 3.0)

const STEER_SPEED := 4.5
const MAX_DRIFT := 22.0         # so weit darf der Ballon von seinem Startpunkt wegtreiben
const ALOFT_HEIGHT := 1.5       # ab dieser Höhe lenkt WASD den Ballon, statt den Spieler zu bewegen

@export var top_height := 14.0   # Höhe der Plattform über dem Start (Sterne in 12 m sind so erreichbar)
var base_y := 0.0
var riders := 0
var at_top := false
var steer := Vector3.ZERO       # vom mitfahrenden Spieler gesetzt (Weltrichtung, Länge 0..1)
var home := Vector3.ZERO
var _area: Area3D
## M-12: Online rechnet nur der Host (Steigen, Sinken, Lenken). Clients schicken ihre Lenkung an den Host und
## übernehmen die Position, die der Host ~30-mal pro Sekunde sendet.
const SEND_INTERVAL := 1.0 / 30.0
const STEER_TIMEOUT := 0.25      # Lenk-Eingaben von Clients gelten so lange
var _remote_steer := {}          # Host: Peer-ID -> [Richtung, Zeit]
var _target := Vector3.ZERO
var _has_target := false
var _send_acc := 0.0


func _ready() -> void:
	base_y = position.y
	home = position
	sync_to_physics = false
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = BOARD_SIZE
	cs.shape = box
	add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = BOARD_SIZE
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.55, 0.3)
	mi.mesh = bm
	mi.material_override = mat
	add_child(mi)
	# Ballonhülle (nur Optik) über der Plattform
	var env := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.0
	sm.height = 4.0
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color(0.9, 0.35, 0.4)
	env.mesh = sm
	env.material_override = emat
	env.position.y = 5.0
	add_child(env)
	# Zone knapp über der Plattform zählt Mitfahrer
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = 1
	var acs := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(BOARD_SIZE.x, 1.5, BOARD_SIZE.z)
	acs.shape = abox
	acs.position.y = 1.0
	_area.add_child(acs)
	add_child(_area)
	_area.body_entered.connect(func(b: Node3D) -> void: if b is Player: riders += 1)
	_area.body_exited.connect(func(b: Node3D) -> void: if b is Player: riders = maxi(riders - 1, 0))


func _online() -> bool:
	return multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer \
		and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Rechnet dieser Rechner den Ballon? Solo immer, online nur der Host.
func is_simulating() -> bool:
	return not _online() or multiplayer.is_server()


## Mitfahrender Spieler lenkt (Weltrichtung). Host/Solo direkt, Client per RPC an den Host.
func request_steer(dir: Vector3) -> void:
	if is_simulating():
		steer = dir
	else:
		_rpc_steer.rpc_id(1, dir)


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_steer(dir: Vector3) -> void:
	if not multiplayer.is_server() or not dir.is_finite() or dir.length() > 1.5:
		return
	_remote_steer[multiplayer.get_remote_sender_id()] = [dir, Time.get_ticks_msec() / 1000.0]


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_state(pos: Vector3) -> void:
	if pos.is_finite():
		_target = pos
		_has_target = true


func _physics_process(delta: float) -> void:
	if not is_simulating():
		if _has_target:
			position = position.lerp(_target, clampf(delta * 15.0, 0.0, 1.0))
		steer = Vector3.ZERO
		_check_events()
		return
	var now := Time.get_ticks_msec() / 1000.0
	for peer in _remote_steer.keys():
		var e: Array = _remote_steer[peer]
		if now - float(e[1]) > STEER_TIMEOUT:
			_remote_steer.erase(peer)
		else:
			steer += e[0]
	if steer.length() > 1.0:
		steer = steer.normalized()
	position.y = next_height(position.y, riders, delta)
	if riders > 0 and steer.length() > 0.01:
		var np := position + Vector3(steer.x, 0, steer.z) * STEER_SPEED * delta
		var off := Vector2(np.x - home.x, np.z - home.z)
		if off.length() > MAX_DRIFT:
			off = off.normalized() * MAX_DRIFT
		position.x = home.x + off.x
		position.z = home.z + off.y
	steer = Vector3.ZERO
	_check_events()
	if _online():
		_send_acc += delta
		if _send_acc >= SEND_INTERVAL:
			_send_acc = 0.0
			_rpc_state.rpc(position)


## Reine Logik (testbar ohne Physik): neue Höhe nach `delta` Sekunden.
func next_height(y: float, rider_count: int, delta: float) -> float:
	if rider_count > 0:
		return minf(y + RISE_SPEED * delta, base_y + top_height)
	return maxf(y - FALL_SPEED * delta, base_y)


func is_aloft() -> bool:
	return position.y > base_y + ALOFT_HEIGHT


func _check_events() -> void:
	var top := position.y >= base_y + top_height - 0.001
	if top and not at_top:
		reached_top.emit()
	if not top and at_top and position.y <= base_y + 0.001:
		returned.emit()
	if top != at_top and (top or position.y <= base_y + 0.001):
		at_top = top


## Selbsttest: Mit Mitfahrer erreicht die Plattform die Höhe von 12 m, ohne Mitfahrer sinkt sie zurück.
## Reine Rechnung, keine Physik. Aufruf: `Balloon.selftest()`.
static func selftest() -> bool:
	var b := Balloon.new()
	b.base_y = 0.0
	var y := 0.0
	var t := 0.0
	var reached_12 := -1.0
	while t < 30.0:
		y = b.next_height(y, 1, 1.0 / 60.0)
		t += 1.0 / 60.0
		if reached_12 < 0.0 and y >= 12.0:
			reached_12 = t
	var capped := is_equal_approx(y, b.top_height)
	var down := y
	for i in 3600:
		down = b.next_height(down, 0, 1.0 / 60.0)
	var ok := reached_12 > 0.0 and reached_12 < 10.0 and capped and is_zero_approx(down)
	b.free()
	print("SELFTEST Balloon 12m nach %.1fs, oben=%s, unten=%s -> %s" % [reached_12, capped, is_zero_approx(down), "OK" if ok else "FAIL"])
	return ok
