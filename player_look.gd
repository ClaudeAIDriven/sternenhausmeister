class_name PlayerLook
extends RefCounted
## Aussehen der vier Spielerfiguren (A-08). Gleiche Grundgeometrie, Varianten über Farbe, Zubehör, Symbol und Fußring.
## Nutzung: `add_child(PlayerLook.build(index, cvd_mode))` (index 0..3). Ursprung am Boden, Figur ca. 1,7 m hoch, Blick nach -Z.
## Farbe allein reicht nicht (siehe docs/STYLEGUIDE.md): Jede Figur trägt ein Symbol an Brust und Rücken, Zubehör und einen Fußring.


static func _mat(c: Color, emit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	if emit:
		m.emission_enabled = true
		m.emission = c
	return m


static func _add(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, nm := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	if nm != "":
		mi.name = nm
		mi.set_meta("part", nm)
	parent.add_child(mi)
	return mi


static func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 12
	c.rings = 4
	return c


static func _cyl(top: float, bottom: float, h: float, seg := 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


## Baut Spieler `index` (0..3). `cvd_mode`: hellere Spielerfarbe 3 (Farbenblind-Modus).
static func build(index: int, cvd_mode := false) -> Node3D:
	index = posmod(index, 4)
	var col := Palette.player_color(index, cvd_mode)
	var root := Node3D.new()
	root.name = "PlayerLook%d" % (index + 1)
	root.set_meta("symbol", Palette.PLAYER_SYMBOLS[index])
	root.set_meta("accessory", Palette.PLAYER_ACCESSORIES[index])
	var body_mat := _mat(col)
	var dark := _mat(col.darkened(0.25))
	# Körper, Beine, Arme
	_add(root, _capsule(0.4, 1.35), body_mat, Vector3(0, 0.98, 0), Vector3.ZERO, "Body")
	for sx in [-1.0, 1.0]:
		_add(root, _cyl(0.13, 0.15, 0.32), dark, Vector3(sx * 0.18, 0.16, 0), Vector3.ZERO, "Leg")
		_add(root, _capsule(0.1, 0.5), dark, Vector3(sx * 0.5, 0.95, 0), Vector3(0, 0, sx * 0.35), "Arm")
	# Gesicht: zwei leuchtende Augen, kleines Lächeln
	var eye_mat := _mat(Palette.UI_IVORY, true)
	for sx in [-1.0, 1.0]:
		var e := SphereMesh.new()
		e.radius = 0.1
		e.height = 0.2
		e.radial_segments = 8
		e.rings = 4
		_add(root, e, eye_mat, Vector3(sx * 0.16, 1.4, -0.34), Vector3.ZERO, "Eye")
	var smile := TorusMesh.new()
	smile.inner_radius = 0.07
	smile.outer_radius = 0.09
	smile.rings = 8
	smile.ring_segments = 4
	_add(root, smile, _mat(Palette.UI_IVORY.darkened(0.15)), Vector3(0, 1.22, -0.37), Vector3(PI / 2, 0, 0), "Smile").scale = Vector3(1.2, 1.0, 0.5)
	# Fußring in Spielerfarbe (Erkennung von oben/Boden)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.55
	ring.outer_radius = 0.7
	ring.rings = 16
	ring.ring_segments = 6
	var ring_mi := _add(root, ring, _mat(col.lightened(0.25), true), Vector3(0, 0.03, 0), Vector3.ZERO, "FootRing")
	ring_mi.scale = Vector3(1, 0.25, 1)
	# Symbol an Brust und Rücken
	for side in [-1.0, 1.0]:
		_symbol(root, Palette.PLAYER_SYMBOLS[index], Vector3(0, 0.95, side * 0.4), side)
	_accessory(root, index, col)
	return root


## Symbol als flache Form (Elfenbein): Kreis, Quadrat, Dreieck, Raute.
static func _symbol(root: Node3D, kind: String, pos: Vector3, side: float) -> void:
	var m := _mat(Palette.UI_IVORY)
	var face_rot := Vector3(PI / 2, 0, 0)   # Zylinder stehen in Y, flach gelegt zeigen sie nach Z
	var mi: MeshInstance3D
	match kind:
		"circle": mi = _add(root, _cyl(0.13, 0.13, 0.04, 16), m, pos, face_rot, "Symbol")
		"square": mi = _add(root, _box(Vector3(0.24, 0.24, 0.04)), m, pos, Vector3.ZERO, "Symbol")
		"triangle": mi = _add(root, _cyl(0.17, 0.17, 0.04, 3), m, pos, face_rot, "Symbol")
		_: mi = _add(root, _box(Vector3(0.22, 0.22, 0.04)), m, pos, Vector3(0, 0, PI / 4), "Symbol")
	if side > 0.0:
		mi.rotation.y = PI


static func _accessory(root: Node3D, index: int, col: Color) -> void:
	match index:
		0:   # Staubwedel mit rosa Federbüschel (Griff braun)
			var brush := Node3D.new()
			brush.name = "Accessory"
			brush.position = Vector3(0.62, 0.95, -0.3)
			brush.rotation = Vector3(-0.5, 0, 0.2)
			root.add_child(brush)
			_add(brush, _cyl(0.03, 0.03, 0.9, 6), _mat(Color(0.55, 0.35, 0.2)), Vector3(0, 0.45, 0))
			var tip := SphereMesh.new()
			tip.radius = 0.2
			tip.height = 0.4
			tip.radial_segments = 8
			tip.rings = 4
			_add(brush, tip, _mat(Color(1.0, 0.72, 0.85)), Vector3(0, 0.98, 0))
		1:   # dunkle Mütze mit Krempe
			var cap := Node3D.new()
			cap.name = "Accessory"
			root.add_child(cap)
			var dm := _mat(Color(0.15, 0.13, 0.2))
			var dome := SphereMesh.new()
			dome.radius = 0.36
			dome.height = 0.5
			dome.radial_segments = 12
			dome.rings = 4
			_add(cap, dome, dm, Vector3(0, 1.62, 0))
			_add(cap, _cyl(0.42, 0.42, 0.04, 14), dm, Vector3(0, 1.56, -0.04))
		2:   # kleiner goldener Sternanhänger am Hals
			var star := _cyl(0.13, 0.13, 0.05, 5)
			var mi := _add(root, star, _mat(Palette.STAR_GOLD, true), Vector3(0, 1.08, -0.4), Vector3(PI / 2, 0, 0), "Accessory")
			mi.scale = Vector3(1, 1, 1)
		3:   # Schal: Ring um den Hals plus hängendes Ende
			var sc := Node3D.new()
			sc.name = "Accessory"
			root.add_child(sc)
			var sm := _mat(Palette.STAR_GOLD.darkened(0.15))
			var tor := TorusMesh.new()
			tor.inner_radius = 0.33
			tor.outer_radius = 0.43
			tor.rings = 14
			tor.ring_segments = 6
			_add(sc, tor, sm, Vector3(0, 1.12, 0))
			_add(sc, _box(Vector3(0.14, 0.4, 0.05)), sm, Vector3(0.18, 0.88, -0.42), Vector3(0, 0, 0.1))


## Rollen-Hüte (M-06): sichtbar für alle, weil die Rolle repliziert wird. "" = kein Hut.
const HATS := {"allrounder": "", "putzer": "haube", "springer": "feder", "koch": "kochmuetze", "kletterer": "helm", "flitzer": "stirnband"}


## Setzt/ersetzt den Hut passend zur Rolle (oder zu einer Hut-ID aus HATS.values()).
static func update_hat(look: Node3D, role_or_hat: String) -> void:
	if look == null:
		return
	var hat_id: String = HATS.get(role_or_hat, role_or_hat)
	var old := look.get_node_or_null("Hat")
	if old != null and str(old.get_meta("hat_id", "")) == hat_id:
		return
	if old != null:
		old.free()
	if hat_id == "":
		return
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.set_meta("hat_id", hat_id)
	hat.position = Vector3(0, 1.78, 0)
	look.add_child(hat)
	var white := _mat(Color(0.96, 0.95, 0.92))
	var red := _mat(Color(0.85, 0.2, 0.25))
	var gold := _mat(Color(0.95, 0.78, 0.25), true)
	var gray := _mat(Color(0.55, 0.58, 0.65))
	match hat_id:
		"haube":
			_add(hat, _cyl(0.3, 0.42, 0.16), white, Vector3(0, 0.03, 0))
			_add(hat, _cyl(0.0, 0.3, 0.3), white, Vector3(0, 0.22, 0))
		"feder":
			_add(hat, _cyl(0.32, 0.4, 0.12), red, Vector3(0, 0.02, 0))
			_add(hat, _capsule(0.04, 0.5), gold, Vector3(0.16, 0.3, 0.05), Vector3(0, 0, -0.5))
		"kochmuetze":
			_add(hat, _cyl(0.28, 0.28, 0.2), white, Vector3(0, 0.05, 0))
			var puff := SphereMesh.new()
			puff.radius = 0.34
			puff.height = 0.5
			_add(hat, puff, white, Vector3(0, 0.3, 0))
		"helm":
			var dome := SphereMesh.new()
			dome.radius = 0.42
			dome.height = 0.84
			_add(hat, dome, gray, Vector3(0, -0.02, 0)).scale = Vector3(1, 0.7, 1)
			_add(hat, _box(Vector3(0.12, 0.1, 0.12)), gold, Vector3(0, 0.3, -0.35))
		"zylinder":
			_add(hat, _cyl(0.4, 0.4, 0.06), _mat(Color(0.12, 0.1, 0.16)), Vector3(0, -0.1, 0))
			_add(hat, _cyl(0.26, 0.26, 0.42), _mat(Color(0.12, 0.1, 0.16)), Vector3(0, 0.12, 0))
			_add(hat, _cyl(0.27, 0.27, 0.06), red, Vector3(0, 0.0, 0))
		"krone":
			_add(hat, _cyl(0.3, 0.3, 0.18), gold, Vector3(0, 0.0, 0))
			for k in 5:
				var a := TAU * k / 5.0
				_add(hat, _cyl(0.0, 0.07, 0.2, 6), gold, Vector3(cos(a) * 0.27, 0.18, sin(a) * 0.27))
		"sternmuetze":
			_add(hat, _cyl(0.0, 0.32, 0.6), _mat(Color(0.22, 0.2, 0.6)), Vector3(0, 0.25, 0))
			var st := SphereMesh.new()
			st.radius = 0.09
			st.height = 0.18
			_add(hat, st, gold, Vector3(0, 0.58, 0))
		"schleife":
			var bow := SphereMesh.new()
			bow.radius = 0.14
			bow.height = 0.28
			var pink := _mat(Color(1.0, 0.45, 0.7))
			_add(hat, bow, pink, Vector3(-0.15, 0.05, 0))
			_add(hat, bow, pink, Vector3(0.15, 0.05, 0))
			_add(hat, bow, _mat(Color(0.9, 0.3, 0.6)), Vector3(0, 0.05, 0))
		"stirnband":
			var band := TorusMesh.new()
			band.inner_radius = 0.36
			band.outer_radius = 0.44
			_add(hat, band, red, Vector3(0, -0.15, 0)).scale = Vector3(1, 1, 0.6)


## Lauf-Animation: Beine und Arme schwingen gegengleich. `phase` wächst mit der Strecke, `amount` (0..1) ist die Lauf-Intensität.
## Ruhe (amount 0) stellt die Grundhaltung wieder her. Arme behalten ihre leichte Grund-Neigung (z-Achse).
static func animate(look: Node3D, phase: float, amount: float) -> void:
	var li := 0
	var ai := 0
	for c in look.get_children():
		var part: String = c.get_meta("part", "")
		if part == "Leg":
			var sgn := 1.0 if li == 0 else -1.0
			c.rotation.x = sin(phase) * 0.8 * amount * sgn
			c.position.y = 0.16 + maxf(0.0, sin(phase + (0.0 if li == 0 else PI))) * 0.05 * amount
			li += 1
		elif part == "Arm":
			var sgn2 := -1.0 if ai == 0 else 1.0
			c.rotation.x = sin(phase) * 0.7 * amount * sgn2
			ai += 1


## Selbsttest: 4 Varianten, eindeutige Symbole und Zubehör, jeweils Körper/Augen/Arme/Beine/Fußring/2 Symbole.
static func selftest() -> bool:
	var ok := true
	var symbols := {}
	var accs := {}
	for i in 4:
		var p := build(i)
		symbols[p.get_meta("symbol")] = true
		accs[p.get_meta("accessory")] = true
		ok = ok and p.get_node_or_null("Body") != null and p.get_node_or_null("FootRing") != null and p.get_node_or_null("Accessory") != null
		var legs := 0
		var symbols_n := 0
		for c in p.get_children():
			if c.get_meta("part", "") == "Leg":
				legs += 1
			if c.get_meta("part", "") == "Symbol":
				symbols_n += 1
		ok = ok and legs == 2 and symbols_n == 2
		p.free()
	ok = ok and symbols.size() == 4 and accs.size() == 4
	print("SELFTEST PlayerLook 4 Varianten, Symbole %d, Zubehör %d -> %s" % [symbols.size(), accs.size(), "OK" if ok else "FAIL"])
	return ok
