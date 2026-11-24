extends SceneTree
## Test I-07: Host-Info zeigt sich nur beim Hosten, listet Port, LAN-IPs und wertet upnp_result aus.
var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var nm = root.get_node("NetworkManager")
	var HI = load("res://host_info.gd")
	var ok := true
	# LAN-Filter
	var lan = HI.find_lan_ips(["127.0.0.1", "192.168.0.12", "10.1.2.3", "172.20.0.5", "172.32.0.1", "8.8.8.8", "fe80::1"])
	ok = ok and lan == ["192.168.0.12", "10.1.2.3", "172.20.0.5"]
	var hi = HI.new()
	root.add_child(hi)
	ok = ok and not hi._panel.visible   # Solo: unsichtbar
	nm.use_upnp = false
	hi.port = 25999
	ok = ok and nm.host(25999, "T") == OK
	hi.refresh()
	ok = ok and hi._panel.visible
	ok = ok and ("%d" % hi.port) in hi.info_text()
	ok = ok and "Suche Router" in hi.info_text()
	hi.lan_ips = ["192.168.0.12"]
	ok = ok and hi.best_address() == "192.168.0.12:%d" % hi.port
	nm.upnp_result.emit(true, "Port freigegeben.", "203.0.113.7")
	ok = ok and hi.external_ip == "203.0.113.7" and "Internet: 203.0.113.7:%d" % hi.port in hi.info_text()
	ok = ok and hi.best_address() == "203.0.113.7:%d" % hi.port
	ok = ok and "Port freigegeben." in hi.info_text()
	hi.copy_button.pressed.emit()
	nm.leave()
	hi.refresh()
	ok = ok and not hi._panel.visible
	print("TEST_HOST_INFO ", "OK" if ok else "FAIL")
	quit(0 if ok else 1)
	return false
