extends SceneTree
## Test N-06: UPnP-Versuch beim Hosten darf das Hosten nie abbrechen (hier ohne Router: Fehlschlag wird nur gemeldet).
var t := 0.0
var started := false
var res := []
var nm

func _process(delta: float) -> bool:
	if not started:
		started = true
		nm = root.get_node("NetworkManager")
		nm.upnp_result.connect(func(ok, msg, ip): res.append([ok, msg, ip]))
		var port := 26000 + randi() % 1000
		var e: int = nm.host(port, "Host")
		if e != OK or not nm.is_host() or not nm.is_online():
			print("TEST_UPNP FAIL Hosten fehlgeschlagen")
			quit(1)
		return false
	t += delta
	if res.size() > 0 or t > 15.0:
		var ok: bool = res.size() == 1 and res[0][1] is String and nm.is_online() and nm.players.size() == 1
		if res.size() == 1:
			print("UPnP-Ergebnis: ok=", res[0][0], " ", res[0][1])
		nm.leave()
		ok = ok and not nm.is_online()
		print("TEST_UPNP OK" if ok else "TEST_UPNP FAIL")
		quit(0 if ok else 1)
	return false
