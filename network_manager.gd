extends Node
## Autoload "NetworkManager": Host/Join per ENet, bis zu max_players (Standard 4).
## Der Host (Peer-ID 1) ist maßgeblich. Die Spielerliste wird vom Host an alle verteilt.

signal hosting_started
signal connected_to_host
signal connection_failed
signal disconnected
signal player_joined(id: int)
signal player_left(id: int)
signal players_changed
## UPnP-Versuch beim Hosten abgeschlossen. ok=false ist kein Fehler des Spiels (kein Router/UPnP aus), Hosten läuft trotzdem.
signal upnp_result(ok: bool, message: String, external_ip: String)

const DEFAULT_PORT := 24680

var use_upnp := true   # Beim Hosten versuchen, den Port automatisch am Router freizugeben
var max_players := 4
var players: Dictionary = {}   # peer_id -> {"name": String}
var _pending_name := "Spieler"
var drones_enabled := true   # Tests können die Drohnen abschalten
var drones := {}        # Drohnen-ID (= Peer-ID des Gegangenen) -> Drone
var drone_names := {}   # Drohnen-ID -> Spielername (Host: für Rejoin)


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(func(): connection_failed.emit())
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_online() -> bool:
	return multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer


func is_host() -> bool:
	return not is_online() or multiplayer.is_server()


func my_id() -> int:
	return multiplayer.get_unique_id() if is_online() else 1


func host(port: int = DEFAULT_PORT, host_name: String = "Host") -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_players - 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	players = {1: {"name": host_name}}
	if use_upnp:
		_start_upnp(port)
	hosting_started.emit()
	players_changed.emit()
	return OK


func join(ip: String, port: int = DEFAULT_PORT, my_name: String = "Spieler") -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_pending_name = my_name
	return OK


func leave() -> void:
	_stop_upnp()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()
	_clear_drones()


func _on_connected_to_server() -> void:
	connected_to_host.emit()
	_register.rpc_id(1, _pending_name)


@rpc("any_peer", "reliable")
func _register(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	players[id] = {"name": player_name}
	# Rejoin: Drohne mit demselben Namen geht, der Spieler ist wieder da
	for did in drone_names.keys():
		if drone_names[did] == player_name:
			_rpc_remove_drone.rpc(did)
	# Neuer Spieler sieht bereits vorhandene Drohnen
	for did in drones:
		if is_instance_valid(drones[did]):
			_rpc_spawn_drone.rpc_id(id, did, drones[did].position, drone_names.get(did, ""))
	_sync_players.rpc(players)
	player_joined.emit(id)
	players_changed.emit()


@rpc("authority", "call_remote", "reliable")
func _sync_players(p: Dictionary) -> void:
	players = p
	players_changed.emit()


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	var pos := _player_position(id)
	var pname: String = str(players.get(id, {}).get("name", ""))
	players.erase(id)
	if drones_enabled:
		_rpc_spawn_drone.rpc(id, pos, pname)   # Drohne übernimmt (Host entscheidet, alle sehen sie)
	_sync_players.rpc(players)
	player_left.emit(id)
	players_changed.emit()


func _on_server_disconnected() -> void:
	players.clear()
	_clear_drones()
	multiplayer.multiplayer_peer = null
	disconnected.emit()
	players_changed.emit()


## Drohnen: Host löst aus, alle Peers erzeugen sie lokal unter "Drones" (gleicher Pfad für die Synchronisation).
@rpc("authority", "call_local", "reliable")
func _rpc_spawn_drone(drone_id: int, pos: Vector3, pname: String) -> void:
	if drones.has(drone_id) and is_instance_valid(drones[drone_id]):
		return
	var d := Drone.new()
	d.name = "Drone%d" % drone_id
	d.player_name = pname
	d.position = pos
	_drone_parent().add_child(d)
	drones[drone_id] = d
	drone_names[drone_id] = pname


@rpc("authority", "call_local", "reliable")
func _rpc_remove_drone(drone_id: int) -> void:
	var d = drones.get(drone_id)
	if d != null and is_instance_valid(d):
		d.queue_free()
	drones.erase(drone_id)
	drone_names.erase(drone_id)


func _drone_parent() -> Node:
	var base: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	var p := base.get_node_or_null("Drones")
	if p == null:
		p = Node.new()
		p.name = "Drones"
		base.add_child(p)
	return p


func _player_position(id: int) -> Vector3:
	var n := get_tree().root.find_child(str(id), true, false) as Node3D
	return n.global_position + Vector3(0, 1.0, 0) if n != null else Vector3(0, 3.0, 6.0)


func _clear_drones() -> void:
	for d in drones.values():
		if is_instance_valid(d):
			d.queue_free()
	drones.clear()
	drone_names.clear()


## UPnP: läuft in einem eigenen Thread (Suche dauert ein paar Sekunden), damit das Spiel nicht hängt.
## Jeder Fehler wird nur gemeldet (Signal upnp_result), das Hosten wird nie abgebrochen.
var _upnp_thread: Thread
var _upnp: UPNP
var _upnp_port := 0


func _start_upnp(port: int) -> void:
	if _upnp_thread != null:
		_upnp_thread.wait_to_finish()
	_upnp_thread = Thread.new()
	_upnp_thread.start(_upnp_worker.bind(port))


func _upnp_worker(port: int) -> void:
	var up := UPNP.new()
	var err := up.discover(2000, 2, "InternetGatewayDevice")
	if err != UPNP.UPNP_RESULT_SUCCESS or up.get_gateway() == null or not up.get_gateway().is_valid_gateway():
		call_deferred("_upnp_done", false, "Kein UPnP-Router gefunden (Fehler %d). Port %d UDP bitte von Hand freigeben, siehe docs/INTERNET.md." % [err, port], "", null, 0)
		return
	var map_err := up.add_port_mapping(port, port, "Sternenhausmeister", "UDP", 3600)
	if map_err != UPNP.UPNP_RESULT_SUCCESS:
		call_deferred("_upnp_done", false, "Router erlaubt keine automatische Freigabe (Fehler %d). Port %d UDP von Hand freigeben, siehe docs/INTERNET.md." % [map_err, port], "", null, 0)
		return
	call_deferred("_upnp_done", true, "Port %d UDP automatisch freigegeben." % port, up.query_external_address(), up, port)


func _upnp_done(ok: bool, message: String, ext_ip: String, up: UPNP, port: int) -> void:
	if ok:
		_upnp = up
		_upnp_port = port
	if not ok:
		push_warning("UPnP: " + message)
	upnp_result.emit(ok, message, ext_ip)


## Gibt die Freigabe beim Beenden des Raums wieder frei (im Thread, blockiert nichts).
func _stop_upnp() -> void:
	if _upnp_thread != null:
		_upnp_thread.wait_to_finish()   # Suche ggf. erst fertig werden lassen (max. wenige Sekunden)
		_upnp_thread = null
	if _upnp != null and _upnp_port > 0:
		var up := _upnp
		var port := _upnp_port
		_upnp = null
		_upnp_port = 0
		var t := Thread.new()
		t.start(func(): up.delete_port_mapping(port, "UDP"))
		t.wait_to_finish()


func _exit_tree() -> void:
	_stop_upnp()
