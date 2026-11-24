extends SceneTree
## Test N-03: Host + Clients; ein Client wischt, alle sehen dieselben Flecken verschwinden; Nachzügler bekommt den Stand.
## Argumente nach --: host|wiper|watcher PORT
var started := false
var role := ""
var t := 0.0
var world
var nm
var done_at := -1.0
var wiped := false
var joined := 0

func _start() -> void:
	nm = root.get_node("NetworkManager")
	world = load("res://world.gd").new()
	root.add_child(world)
	nm.drones_enabled = false
	nm.player_joined.connect(func(_id): joined += 1)
	var a := OS.get_cmdline_user_args()
	role = a[0]
	var e: int = nm.host(int(a[1]), "Host") if role == "host" else nm.join("127.0.0.1", int(a[1]), role)
	if e != OK:
		print("NETS ", role, " FAIL err=", e)
		quit(1)

func _report() -> void:
	print("NETS ", role, " RESULT clean0=", world.stars[0].is_clean, " spots1=", world.stars[1].spots.size(), " spots2=", world.stars[2].spots.size())

func _process(delta: float) -> bool:
	if not started:
		started = true
		_start()
		return false
	t += delta
	if role == "wiper" and not wiped and nm.players.size() >= 2 and t > 2.0:
		wiped = true
		world.wipe_at(world.stars[0].global_position, 3.0)
		world.wipe_at(world.stars[1].global_position + Vector3(1.5, 0, 0), 1.2)
	if world.stars[0].is_clean and world.stars[1].spots.size() < 140 and done_at < 0.0:
		done_at = t
	# Host wartet, bis auch der Nachzügler (4. Spieler) da war
	var need := 3 if role == "host" else 0
	if done_at >= 0.0 and t > done_at + 3.0 and joined >= need:
		if role == "host":
			if t > done_at + 8.0:
				_report(); quit(0)
		else:
			_report(); quit(0)
	if t > 30.0:
		print("NETS ", role, " FAIL Timeout")
		quit(1)
	return false
