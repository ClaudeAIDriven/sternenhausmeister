extends SceneTree
## Test N-05: Host + 2 Clients; Client "leaver" trennt -> Drohne erscheint bei Host und Watcher, wischt Flecken weg,
## Rejoin mit gleichem Namen entfernt die Drohne. Argumente: host|watcher|leaver|rejoin PORT
var started := false
var role := ""
var t := 0.0
var world
var nm
var phase := 0
var phase_t := 0.0
var joined := 0
var base_spots := 0

func _start() -> void:
	nm = root.get_node("NetworkManager")
	world = load("res://world.gd").new()
	root.add_child(world)
	nm.player_joined.connect(func(_id): joined += 1)
	var a := OS.get_cmdline_user_args()
	role = a[0]
	var e: int = nm.host(int(a[1]), "Host") if role == "host" else nm.join("127.0.0.1", int(a[1]), "Gast" if role != "rejoin" else "Leaver")
	if role == "leaver":
		e = nm.join("127.0.0.1", int(a[1]), "Leaver")
	if e != OK:
		print("NETD ", role, " FAIL err=", e); quit(1)

func _spots() -> int:
	var n := 0
	for s in world.stars: n += s.spots.size()
	return n

func _drone_count() -> int:
	var n := 0
	for d in nm.drones.values():
		if is_instance_valid(d): n += 1
	return n

func _process(delta: float) -> bool:
	if not started:
		started = true; _start(); return false
	t += delta
	if role == "leaver":
		if t > 3.0:
			nm.leave(); print("NETD leaver OK getrennt"); quit(0)
	elif role == "host":
		# Phase 0: warte auf Drohne, 1: Flecken sinken, 2: Rejoin entfernt Drohne
		if phase == 0 and _drone_count() == 1:
			phase = 1; base_spots = _spots(); phase_t = t
		elif phase == 1 and _spots() < base_spots - 5:
			phase = 2; phase_t = t
			print("NETD host Drohne wischt: ", base_spots, " -> ", _spots())
		elif phase == 2 and not nm.drone_names.values().has("Leaver"):
			print("NETD host OK Drohne erschien, wischte, wurde nach Rejoin entfernt"); quit(0)
	else:  # watcher / rejoin
		if role == "rejoin" and t > 8.0:
			print("NETD rejoin OK"); quit(0)
		if role == "watcher":
			if phase == 0 and _drone_count() == 1:
				var d = nm.drones.values()[0]
				phase = 1; phase_t = t; base_spots = _spots()
				print("NETD watcher sieht Drohne")
			elif phase == 1 and _spots() < base_spots - 5:
				print("NETD watcher OK Flecken der Drohne repliziert"); quit(0)
	if t > 40.0:
		print("NETD ", role, " FAIL Timeout phase=", phase, " drones=", _drone_count() if nm else -1); quit(1)
	return false
