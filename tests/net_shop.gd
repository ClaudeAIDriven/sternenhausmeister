extends SceneTree
## Test I-10 (Netz): Client kauft ein Upgrade, Host bucht ab, alle sehen die neue Stufe und beide ziehen den Preis vom Staub ab.
## Argumente: host|buyer PORT
var started := false
var role := ""
var t := 0.0
var shop
var nm
var gs
var bought := false

func _start() -> void:
	nm = root.get_node("NetworkManager")
	gs = root.get_node("GameState")
	nm.drones_enabled = false
	nm.use_upnp = false
	shop = load("res://shop.gd").new()
	shop.name = "Shop"
	root.add_child(shop)
	gs.dust = 50
	var a := OS.get_cmdline_user_args()
	role = a[0]
	var e: int = nm.host(int(a[1]), "Host") if role == "host" else nm.join("127.0.0.1", int(a[1]), role)
	if e != OK:
		print("NETB ", role, " FAIL err=", e); quit(1)

func _process(delta: float) -> bool:
	if not started:
		started = true; _start(); return false
	t += delta
	if role == "buyer" and not bought and nm.players.size() >= 2 and t > 2.0:
		bought = true
		shop.request_buy("wipe_size")
	var price: int = 6   # base_cost wipe_size, Stufe 0
	if shop.level("wipe_size") == 1 and gs.dust == 50 - price and t > 4.0:
		print("NETB ", role, " OK Stufe 1, Staub ", gs.dust)
		quit(0)
	if t > 25.0:
		print("NETB ", role, " FAIL Timeout Stufe=", shop.level("wipe_size"), " Staub=", gs.dust)
		quit(1)
	return false
