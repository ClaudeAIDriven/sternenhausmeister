extends SceneTree
## Test A-02: 4 Spieler -> 4 verschiedene Farben und Namensschilder mit dem Namen aus der Spielerliste.

var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var nm = root.get_node("NetworkManager")
	nm.players = {1: {"name": "Anna"}, 2: {"name": "Ben"}, 3: {"name": "Cem"}, 4: {"name": "Dora"}}
	var host := Node3D.new()
	root.add_child(host)
	var ps := []
	for id in [1, 2, 3, 4]:
		var p = load("res://player.gd").new()
		p.name = str(id)
		host.add_child(p)
		ps.append(p)
	var ok := true
	var names := []
	var cols := []
	for p in ps:
		ok = ok and p.nameplate != null and p.nameplate.billboard == BaseMaterial3D.BILLBOARD_ENABLED
		names.append(p.nameplate.text)
		cols.append(p.nameplate.modulate.to_html())
	ok = ok and names == ["Anna", "Ben", "Cem", "Dora"]
	var uniq := {}
	for c in cols:
		uniq[c] = true
	ok = ok and uniq.size() == 4
	# Umbenennen in der Liste aktualisiert das Schild
	nm.players[2] = {"name": "Bert"}
	nm.players_changed.emit()
	ok = ok and ps[1].nameplate.text == "Bert"
	print("NAMEPLATES ", names, cols)
	print("TEST_NAMEPLATES OK" if ok else "TEST_NAMEPLATES FAIL")
	quit(0 if ok else 1)
	return true
