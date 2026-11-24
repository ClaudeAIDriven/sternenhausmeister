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

const DEFAULT_PORT := 24680

var max_players := 4
var players: Dictionary = {}   # peer_id -> {"name": String}
var _pending_name := "Spieler"


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
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()


func _on_connected_to_server() -> void:
	connected_to_host.emit()
	_register.rpc_id(1, _pending_name)


@rpc("any_peer", "reliable")
func _register(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	players[id] = {"name": player_name}
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
	players.erase(id)
	_sync_players.rpc(players)
	player_left.emit(id)
	players_changed.emit()


func _on_server_disconnected() -> void:
	players.clear()
	multiplayer.multiplayer_peer = null
	disconnected.emit()
	players_changed.emit()
