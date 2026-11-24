extends SceneTree
## Test M-12 (Netz): Der Host rechnet den Ballon, der Client lenkt per RPC und übernimmt die Position vom Host.
## Argumente: host|client PORT
var started := false
var role := ""
var t := 0.0
var nm
var b
var ok_msg := ""

func _start() -> void:
	nm = root.get_node("NetworkManager")
	nm.drones_enabled = false
	nm.use_upnp = false
	var w := Node3D.new()
	w.name = "World"
	root.add_child(w)
	b = load("res://balloon.gd").new()
	b.name = "Ballon"
	b.position = Vector3(0, 0, 0)
	w.add_child(b)
	var a := OS.get_cmdline_user_args()
	role = a[0]
	var e: int = nm.host(int(a[1]), "Host") if role == "host" else nm.join("127.0.0.1", int(a[1]), "Gast")
	if e != OK:
		print("NETL ", role, " FAIL err=", e); quit(1)

func _physics_process(delta: float) -> bool:
	if not started:
		started = true; _start(); return false
	t += delta
	if ok_msg != "" and (t > 12.0 or nm.players.size() < 2):
		print(ok_msg); quit(0); return false
	if nm.players.size() < 2:
		if t > 25.0:
			print("NETL ", role, " FAIL keine Verbindung"); quit(1)
		return false
	if role == "host":
		b.riders = 1            # jemand steht drauf (ohne Spielerfiguren im Test)
		if b.position.x > 2.0 and b.position.y > 3.0 and t > 4.0:
			if ok_msg == "":
				ok_msg = "NETL host OK Ballon gelenkt x=%.1f y=%.1f" % [b.position.x, b.position.y]
	else:
		b.riders = 1            # lokal egal: der Client rechnet nicht selbst
		if b.position.y > 1.0:
			b.request_steer(Vector3(1, 0, 0))
		if b.position.x > 2.0 and b.position.y > 3.0 and not b.is_simulating() and t > 9.0:
			print("NETL client OK Position vom Host x=%.1f y=%.1f" % [b.position.x, b.position.y]); quit(0)
	if t > 25.0:
		print("NETL ", role, " FAIL Timeout x=%.2f y=%.2f" % [b.position.x, b.position.y]); quit(1)
	return false
