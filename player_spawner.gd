class_name PlayerSpawner
extends Node
## Erzeugt je Peer einen Spieler und repliziert ihn an alle (MultiplayerSpawner). Nur der Host spawnt.

var _root: Node3D
var _spawner: MultiplayerSpawner


func setup(players_root: Node3D) -> void:
	_root = players_root
	_spawner = MultiplayerSpawner.new()
	_spawner.name = "Spawner"
	add_child(_spawner)
	_spawner.spawn_path = _spawner.get_path_to(players_root)
	_spawner.spawn_function = _make_player
	NetworkManager.hosting_started.connect(func(): _spawner.spawn(1))
	NetworkManager.player_joined.connect(func(id: int): _spawner.spawn(id))
	NetworkManager.player_left.connect(_on_player_left)


## Offline (Solo): Spieler direkt erzeugen, ohne Netzwerk.
func spawn_offline() -> void:
	_root.add_child(_make_player(1))


func local_player() -> Player:
	var p := _root.get_node_or_null(str(NetworkManager.my_id()))
	return p as Player


func player_count() -> int:
	return _root.get_child_count()


func _make_player(peer_id: Variant) -> Node:
	var id := int(peer_id)
	var p := Player.new()
	p.name = str(id)   # Name = Peer-ID: daraus ergibt sich die Autorität (siehe Player._enter_tree)
	p.position = Vector3(float((id - 1) % 4) * 2.0 - 3.0, 0.1, 6.0)
	return p


func _on_player_left(id: int) -> void:
	var p := _root.get_node_or_null(str(id))
	if p != null:
		p.queue_free()
