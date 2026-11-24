extends SceneTree
## Test I-04 (Netz): Client putzt falsch -> Host und andere Clients sehen das Zurücksetzen; dann richtig -> alle sehen "gelöst".
## Argumente: host|wiper|watcher PORT
var started := false
var role := ""
var t := 0.0
var world
var nm
var wrong_seen := 0
var solved_seen := false
var phase := 0
var phase_t := 0.0
var joined := 0

func _start() -> void:
	nm = root.get_node("NetworkManager")
	nm.drones_enabled = false
	nm.use_upnp = false
	root.get_node("GameState").player_count = 1
	world = load("res://world.gd").new()
	root.add_child(world)
	world.puzzle_wrong.connect(func(_h): wrong_seen += 1)
	nm.player_joined.connect(func(_id): joined += 1)
	var a := OS.get_cmdline_user_args()
	role = a[0]
	var e: int = nm.host(int(a[1]), "Host") if role == "host" else nm.join("127.0.0.1", int(a[1]), role)
	if e != OK:
		print("NETZ ", role, " FAIL err=", e); quit(1)

func _clean(i: int) -> void:
	world.wipe_at(world.stars[i].global_position, 3.0)

func _process(delta: float) -> bool:
	if not started:
		started = true; _start(); return false
	t += delta
	if role == "wiper":
		if phase == 0 and nm.players.size() >= 3 and t > 2.5:
			phase = 1; phase_t = t
			_clean(world.puzzle.order[0]); _clean(world.puzzle.order[2])   # 1. richtig, 3. falsch
		elif phase == 1 and t > phase_t + 3.0:
			phase = 2; phase_t = t
			for i in world.puzzle.order:
				_clean(i)
	solved_seen = solved_seen or (world.puzzle != null and world.puzzle.is_solved)
	if solved_seen and wrong_seen >= 1 and t > 5.0:
		if role != "host" or t > 9.0:
			var cleaned: int = world.cleaned_count()
			print("NETZ ", role, " OK falsch=", wrong_seen, " gelöst, geputzt=", cleaned)
			quit(0)
	if t > 30.0:
		print("NETZ ", role, " FAIL Timeout wrong=", wrong_seen, " solved=", solved_seen, " phase=", phase, " players=", nm.players.size())
		quit(1)
	return false
