extends SceneTree
## Test G-22 (Netz): Zwei Clients greifen gleichzeitig dieselbe Frucht -> nur einer bekommt sie; alle sehen sie verschwunden.
## Argumente: host|a|b PORT
var started := false
var role := ""
var t := 0.0
var world
var nm
var tried := false

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
	if role != "host" and not tried and nm.players.size() >= 3 and t > 3.0:
		tried = true
		world.try_pick(world.fruits[0].global_position)
	if t > 7.0:
		var gone: bool = not world.fruits[0].available
		var items: int = world.inventory.items.size()
		var host_ok: bool = role != "host" or world.pick_log.size() == 1
		print("NETZ ", role, (" OK" if gone and host_ok else " FAIL"), " items=", items, " gone=", gone, " log=", world.pick_log.size())
		quit(0 if gone and host_ok else 1)
	return false
