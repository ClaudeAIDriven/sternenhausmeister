extends SceneTree
## Test N-01/N-04: ein Prozess pro Spieler. Argumente nach --: host|client PORT [NAME]
var nm
var role := ""
var t := 0.0

var started := false
var seen4_at := -1.0

func _start() -> void:
	nm = root.get_node("NetworkManager")
	var a := OS.get_cmdline_user_args()
	role = a[0]
	var port := int(a[1])
	var e: int
	if role == "host":
		e = nm.host(port, "Host")
	else:
		e = nm.join("127.0.0.1", port, a[2])
	if e != OK:
		print("NET4 ", role, " FAIL err=", e)
		quit(1)

func _process(delta: float) -> bool:
	if not started:   # erst im ersten Frame: Autoloads sind dann im Baum (multiplayer verfügbar)
		started = true
		_start()
	t += delta
	if nm.players.size() == 4 and seen4_at < 0.0:
		seen4_at = t
	if seen4_at >= 0.0 and (role != "host" or t > seen4_at + 1.5):   # Host wartet kurz, damit alle die Liste erhalten
		print("NET4 ", role, " OK 4 Spieler")
		quit(0)
	if t > 20.0:
		print("NET4 ", role, " FAIL Timeout, Spieler=", nm.players.size())
		quit(1)
	return false
