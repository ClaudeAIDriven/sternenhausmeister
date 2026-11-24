extends SceneTree
## Test G-28 (Netz): Client putzt eine Wollmaus weg -> der Host entfernt sie, alle sehen sie verschwunden; die Spinne
## übersteht den Wedel-Wisch (nur Staubsauger). Argumente: host|a|b PORT
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
	if role == "a" and not tried and nm.players.size() >= 3 and t > 3.0:
		tried = true
		var spider = null
		for e in world.enemies:
			if e.kind == "spinne":
				spider = e
		world.wipe_at(spider.global_position, 1.5, 0)             # Wedel: Spinne bleibt
		world.wipe_at(world.enemies[0].global_position, 2.0, 0)   # Wollmaus weg
	if t > (11.0 if role == "host" else 8.0):
		var bunny_gone: bool = not world.enemies[0].alive
		var spider_alive := true
		for e in world.enemies:
			if e.kind == "spinne":
				spider_alive = spider_alive and e.alive
		var good := bunny_gone and spider_alive
		print("NETZ ", role, (" OK" if good else " FAIL"), " wollmaus_weg=", bunny_gone, " spinne_da=", spider_alive)
		quit(0 if good else 1)
	return false
