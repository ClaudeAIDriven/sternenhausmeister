extends SceneTree
## Test N-02: 4 Instanzen, je ein Spieler; Host bewegt seinen Spieler, Clients sehen die neue Position.
## Argumente nach --: host|client PORT [NAME]
var started := false
var role := ""
var t := 0.0
var players_root: Node3D
var spawner
var moved_at := -1.0

func _start() -> void:
	var nm = root.get_node("NetworkManager")
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	players_root = Node3D.new()
	players_root.name = "Players"
	root.add_child(players_root)
	spawner = load("res://player_spawner.gd").new()
	root.add_child(spawner)
	spawner.setup(players_root)
	var a := OS.get_cmdline_user_args()
	role = a[0]
	var e: int = nm.host(int(a[1]), "Host") if role == "host" else nm.join("127.0.0.1", int(a[1]), a[2])
	if e != OK:
		print("NETP ", role, " FAIL err=", e)
		quit(1)

func _process(delta: float) -> bool:
	if not started:
		started = true
		_start()
		return false
	t += delta
	var n: int = spawner.player_count()
	if int(t) != int(t - delta) and OS.get_environment("NETP_DEBUG") != "":
		print("NETP dbg ", role, " t=", int(t), " n=", n, " status=", root.multiplayer.multiplayer_peer.get_connection_status() if root.multiplayer.multiplayer_peer else -1, " players=", NetworkManager.players.size())
	if role == "host":
		if n == 4 and moved_at < 0.0:
			moved_at = t
			players_root.get_node("1").global_position = Vector3(5.0, 0.1, 6.0)
		if moved_at >= 0.0 and t > moved_at + 2.5:
			print("NETP host OK 4 Spieler, Position gesendet")
			quit(0)
	else:
		var h := players_root.get_node_or_null("1")
		if n == 4 and h != null and absf(h.position.x - 5.0) < 0.3:
			print("NETP client OK 4 Spieler, Host-Position angekommen x=", snappedf(h.position.x, 0.01))
			quit(0)
	if t > 25.0:
		print("NETP ", role, " FAIL Timeout, Spieler=", n)
		quit(1)
	return false
