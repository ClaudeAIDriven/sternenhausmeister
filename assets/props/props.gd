class_name Props
extends RefCounted
## Low-Poly-Props aus Grundformen (A-03): Ballon, Leiter, Werkstatt. Alles eigene Arbeit (siehe docs/CREDITS.md).
## Nutzung: `add_child(Props.balloon())`, `Props.ladder(6.0)`, `Props.workshop()`. Gibt je ein Node3D mit Ursprung am Boden zurück.
## Farben flach, ungeteilt von Licht-Tricks; passen zum Toon-Shader (shaders/toon.gdshader), sind aber normale Materialien.


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


static func _mesh(parent: Node3D, mesh: Mesh, c: Color, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


static func _cyl(top: float, bottom: float, h: float, seg := 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


## Heißluftballon: Hülle, Korb, Seile. Korbboden bei y=0, Hülle ca. 5 m darüber.
static func balloon() -> Node3D:
	var n := Node3D.new()
	n.name = "BalloonProp"
	var env := SphereMesh.new()
	env.radius = 2.0
	env.height = 4.2
	env.radial_segments = 10
	env.rings = 6
	_mesh(n, env, Color(0.9, 0.35, 0.4), Vector3(0, 5.2, 0))
	_mesh(n, _cyl(0.0, 1.0, 1.0, 10), Color(0.9, 0.35, 0.4), Vector3(0, 2.9, 0))   # Hals zum Korb
	_mesh(n, _cyl(2.02, 2.02, 0.6, 10), Color(1.0, 0.85, 0.4), Vector3(0, 5.2, 0))   # Zierband
	_mesh(n, _box(Vector3(1.6, 0.9, 1.6)), Color(0.55, 0.35, 0.2), Vector3(0, 0.45, 0))   # Korb
	for sx in [-0.7, 0.7]:
		for sz in [-0.7, 0.7]:
			_mesh(n, _cyl(0.025, 0.025, 2.6, 4), Color(0.8, 0.75, 0.6), Vector3(sx * 0.7, 2.1, sz * 0.7), Vector3(sz * 0.25, 0, -sx * 0.25))
	return n


## Leiter: zwei Holme, Sprossen alle 0.4 m. Höhe `height`, Fuß bei y=0.
static func ladder(height := 4.0) -> Node3D:
	var n := Node3D.new()
	n.name = "LadderProp"
	var wood := Color(0.6, 0.4, 0.22)
	for sx in [-0.3, 0.3]:
		_mesh(n, _box(Vector3(0.08, height, 0.08)), wood, Vector3(sx, height * 0.5, 0))
	var rungs := int(height / 0.4)
	for i in rungs:
		_mesh(n, _box(Vector3(0.6, 0.06, 0.06)), wood.lightened(0.15), Vector3(0, 0.3 + i * 0.4, 0))
	return n


## Werkstatt: kleine Hütte mit Satteldach, Tür, leuchtendem Fenster und Werkbank.
static func workshop() -> Node3D:
	var n := Node3D.new()
	n.name = "WorkshopProp"
	_mesh(n, _box(Vector3(4.0, 2.4, 3.0)), Color(0.55, 0.5, 0.75), Vector3(0, 1.2, 0))   # Wände
	for s in [-1.0, 1.0]:   # Satteldach
		_mesh(n, _box(Vector3(4.4, 0.15, 2.0)), Color(0.8, 0.3, 0.35), Vector3(0, 2.9, s * 0.8), Vector3(s * 0.6, 0, 0))
	_mesh(n, _box(Vector3(0.9, 1.7, 0.1)), Color(0.4, 0.27, 0.17), Vector3(-0.9, 0.85, 1.52))   # Tür
	var win := _mesh(n, _box(Vector3(0.9, 0.7, 0.1)), Color(1.0, 0.9, 0.5), Vector3(0.9, 1.4, 1.52))
	(win.material_override as StandardMaterial3D).emission_enabled = true
	(win.material_override as StandardMaterial3D).emission = Color(1.0, 0.85, 0.4)
	_mesh(n, _box(Vector3(1.8, 0.1, 0.8)), Color(0.55, 0.38, 0.22), Vector3(3.0, 0.9, 0.0))   # Werkbank Platte
	for sx in [2.2, 3.8]:
		_mesh(n, _box(Vector3(0.1, 0.9, 0.7)), Color(0.45, 0.3, 0.18), Vector3(sx, 0.45, 0.0))
	_mesh(n, _cyl(0.0, 0.3, 0.5, 6), Color(0.85, 0.85, 0.9), Vector3(2.8, 1.2, 0.0))   # Staubwedel-Attrappe
	return n


## Selbsttest: alle Props lassen sich bauen und haben Meshes.
static func selftest() -> bool:
	var ok := true
	for p in [balloon(), ladder(6.0), workshop()]:
		var count := 0
		for c in (p as Node3D).get_children():
			if c is MeshInstance3D:
				count += 1
		ok = ok and count >= 4
		(p as Node3D).free()
	print("SELFTEST Props -> %s" % ("OK" if ok else "FAIL"))
	return ok
