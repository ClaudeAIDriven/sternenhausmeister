class_name HostInfo
extends CanvasLayer
## Host-Info (I-07): Beim Hosten zeigt eine kleine Karte oben links, unter welcher Adresse Mitspieler beitreten können:
## LAN-IP (im selben WLAN), öffentliche IP (sobald UPnP sie kennt), Port und die UPnP-Meldung. "Adresse kopieren" legt
## "IP:Port" in die Zwischenablage. Ohne Hosten (Solo/Client) bleibt die Karte unsichtbar.
## Nutzung: `add_child(HostInfo.new())` in der Spielszene.

var port := 24680
var lan_ips: Array = []
var external_ip := ""
var upnp_message := ""
var copy_button: Button
var _label: Label
var _panel: PanelContainer


func _ready() -> void:
	layer = 20
	port = NetworkManager.DEFAULT_PORT
	_panel = PanelContainer.new()
	_panel.position = Vector2(12, 12)
	_panel.theme = UiTheme.build(float(Settings.get_value("ui_scale")))
	add_child(_panel)
	var col := VBoxContainer.new()
	_panel.add_child(col)
	_label = Label.new()
	col.add_child(_label)
	copy_button = Button.new()
	copy_button.text = "Adresse kopieren"
	copy_button.pressed.connect(copy_address)
	col.add_child(copy_button)
	NetworkManager.hosting_started.connect(refresh)
	NetworkManager.upnp_result.connect(_on_upnp)
	NetworkManager.disconnected.connect(refresh)
	refresh()


func _on_upnp(_ok: bool, message: String, ext_ip: String) -> void:
	upnp_message = message
	external_ip = ext_ip
	refresh()


## Private IPv4-Adressen dieses Rechners (192.168.x.x, 10.x.x.x, 172.16-31.x.x).
static func find_lan_ips(addresses: Array) -> Array:
	var out := []
	for a in addresses:
		var s := str(a)
		var p := s.split(".")
		if p.size() != 4:
			continue
		var b := int(p[1])
		if s.begins_with("192.168.") or s.begins_with("10.") or (p[0] == "172" and b >= 16 and b <= 31):
			out.append(s)
	return out


## Beste Adresse zum Weitergeben: öffentliche IP, sonst erste LAN-IP, sonst leer.
func best_address() -> String:
	var ip := external_ip if external_ip != "" else (str(lan_ips[0]) if not lan_ips.is_empty() else "")
	return "%s:%d" % [ip, port] if ip != "" else ""


func info_text() -> String:
	var lines := ["Du hostest (UDP-Port %d) – Mitspieler treten bei mit:" % port]
	if external_ip != "":
		lines.append("Internet: %s:%d" % [external_ip, port])
	for ip in lan_ips:
		lines.append("Gleiches WLAN: %s:%d" % [ip, port])
	lines.append(upnp_message if upnp_message != "" else "Suche Router (UPnP) …")
	return "\n".join(lines)


func refresh() -> void:
	lan_ips = find_lan_ips(IP.get_local_addresses())
	if _panel == null:
		return
	_panel.visible = NetworkManager.is_online() and NetworkManager.is_host()
	_label.text = info_text()


func copy_address() -> void:
	var a := best_address()
	if a != "":
		DisplayServer.clipboard_set(a)
