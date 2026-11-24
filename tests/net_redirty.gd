extends SceneTree
## Test G-15 (Netz): Host putzt Stern 0, Sternschnuppe verschmutzt ihn teilweise neu -> alle sehen 3..6 Flecken, nicht sauber.
## Argumente: host|a|b PORT
var started := false
var role := ""
var t := 0.0
var world
var nm
var phase := 0
var phase_t := 0.0
var saw_clean := false
var hit := 0

func _start() -> void:
	nm = root.get_node("NetworkManager")
	nm.drones_enabled = false
	nm.use_upnp = false
	root.get_node("GameState").player_count = 1
	world = load("res://world.gd").new()
	root.add_child(world)
	var a := OS.get_cmdline_user_args()
	role = a[0]
	var e: int = nm.host(int(a[1]), "Host") if role == "host" else nm.join("127.0.0.1", int(a[1]), role)
	if e != OK:
		print("NETZ ", role, " FAIL err=", e); quit(1)

func _process(delta: float) -> bool:
	if not started:
		started = true; _start(); return false
	t += delta
	var s = world.stars[0]
	if role == "host":
		if phase == 0 and nm.players.size() >= 3 and t > 2.5:
			phase = 1; phase_t = t
			world.wipe_at(s.global_position, 3.0)
		elif phase == 1 and t > phase_t + 2.0:
			phase = 2; phase_t = t
			hit = world.meteor_strike(0)
	saw_clean = saw_clean or s.is_clean
	var n: int = s.spots.size()
	if saw_clean and not s.is_clean and n >= 3 and n <= 6 and t > 5.0:
		if role != "host" or t > 8.0:
			print("NETZ ", role, " OK Flecken=", n, " IDs=", s.removed_ids.size(), "/", s.total)
			quit(0)
	if t > 30.0:
		print("NETZ ", role, " FAIL Timeout clean=", saw_clean, " spots=", n, " phase=", phase, " players=", nm.players.size())
		quit(1)
	return false
