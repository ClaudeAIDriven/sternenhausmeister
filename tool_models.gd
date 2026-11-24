class_name ToolModels
extends RefCounted
## 3D-Modelle der vier Werkzeuge (A-09), an der Silhouette unterscheidbar:
##  duster = schlanker Stiel + runder Federbüschel · vacuum = runder Körper + breite Düse mit Leuchtring
##  cloth = großes flaches Tuch mit Falten · polish = Scheibe auf kurzem dickem Griff mit goldenem Zentrum.
## Nutzung: `var t := ToolModels.build("vacuum")` (Ursprung am Griff, Werkzeug zeigt nach +Y, ca. 1 m). Eigener Anker "EffectPoint"
## am Wirkpunkt (Staub nach außen / Einsaugen / Glanzring). Zuordnung zu `CleanTool.Kind` siehe `kind_of`.

const KINDS: Array[String] = ["duster", "vacuum", "cloth", "polish"]


static func _mat(c: Color, emit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if emit:
		m.emission_enabled = true
		m.emission = c
	return m


static func _add(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _cyl(top: float, bottom: float, h: float, seg := 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func _sphere(r: float, seg := 10) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = seg / 2
	return s


static func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


static func _anchor(root: Node3D, pos: Vector3) -> void:
	var a := Node3D.new()
	a.name = "EffectPoint"
	a.position = pos
	root.add_child(a)


static func build(kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Tool_" + kind
	root.set_meta("kind", kind)
	var wood := _mat(Color(0.55, 0.35, 0.2))
	match kind:
		"duster":
			_add(root, _cyl(0.03, 0.035, 0.95, 8), wood, Vector3(0, 0.475, 0))
			_add(root, _sphere(0.21), _mat(Color(1.0, 0.72, 0.85)), Vector3(0, 1.05, 0))
			for i in 6:   # abstehende Federn
				var a := i * TAU / 6.0
				var f := _add(root, _cyl(0.0, 0.06, 0.3, 5), _mat(Color(1.0, 0.82, 0.9)), Vector3(cos(a) * 0.2, 1.12, sin(a) * 0.2), Vector3(sin(a) * 0.9, 0, -cos(a) * 0.9))
				f.scale = Vector3(1, 1, 0.6)
			_anchor(root, Vector3(0, 1.2, 0))
		"vacuum":
			var teal := _mat(Palette.player_color(3).lightened(0.35))
			_add(root, _cyl(0.04, 0.045, 0.5, 8), wood, Vector3(0, 0.25, 0))
			_add(root, _sphere(0.27, 12), teal, Vector3(0, 0.62, 0))
			_add(root, _cyl(0.4, 0.13, 0.28, 12), teal.duplicate(), Vector3(0, 0.95, 0))   # breite Düse nach oben aufgeweitet
			var ring := TorusMesh.new()
			ring.inner_radius = 0.33
			ring.outer_radius = 0.4
			ring.rings = 16
			ring.ring_segments = 6
			_add(root, ring, _mat(Palette.STAR_GOLD, true), Vector3(0, 1.1, 0)).scale = Vector3(1, 0.5, 1)
			_anchor(root, Vector3(0, 1.1, 0))
		"cloth":
			var pastel := Color(0.72, 0.9, 0.85)
			_add(root, _cyl(0.04, 0.04, 0.5, 8), wood, Vector3(0, 0.25, 0))
			# großes, leicht überdimensioniertes Tuch: hängt senkrecht vom Griff herab, mit Falten (versetzte, gewellte Bahnen)
			for i in 5:
				var x := -0.4 + i * 0.2
				var bahn := _add(root, _box(Vector3(0.2, 0.62 - 0.06 * (i % 2), 0.05)), _mat(pastel.lightened(0.1 * (i % 2)).darkened(0.06 * ((i + 1) % 2))), Vector3(x, 0.8 - 0.03 * (i % 2), 0.05 * sin(i * 1.7)), Vector3(0, 0.25 * sin(i * 1.7), 0))
				bahn.scale = Vector3(1, 1, 1)
			_anchor(root, Vector3(0, 0.6, 0.1))
		"polish":
			_add(root, _cyl(0.06, 0.07, 0.55, 8), wood.duplicate(), Vector3(0, 0.275, 0))
			_add(root, _cyl(0.4, 0.4, 0.1, 18), _mat(Color(0.82, 0.78, 0.9)), Vector3(0, 0.6, 0))
			_add(root, _cyl(0.17, 0.17, 0.12, 14), _mat(Palette.STAR_GOLD, true), Vector3(0, 0.62, 0))   # goldenes Zentrum
			var rim := TorusMesh.new()
			rim.inner_radius = 0.37
			rim.outer_radius = 0.43
			rim.rings = 18
			rim.ring_segments = 5
			_add(root, rim, _mat(Palette.STAR_GOLD.darkened(0.3)), Vector3(0, 0.6, 0)).scale = Vector3(1, 0.4, 1)
			_anchor(root, Vector3(0, 0.7, 0))
		_:
			push_warning("ToolModels: unbekanntes Werkzeug " + kind)
	return root


## Zuordnung zu `CleanTool.Kind`: Wedel = ANY (Altverhalten), Sauger = VACUUM (Ruß), Tuch = CLOTH (Flecken), Polierpad = POLISH (Patina).
static func kind_of(name: String) -> int:
	match name:
		"vacuum": return CleanTool.Kind.VACUUM
		"cloth": return CleanTool.Kind.CLOTH
		"polish": return CleanTool.Kind.POLISH
		_: return CleanTool.Kind.ANY


## Färbt ein Modell komplett schwarz und unbeleuchtet (zum Prüfen der Silhouette).
static func silhouette(node: Node) -> void:
	for c in node.get_children():
		if c is MeshInstance3D:
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color.BLACK
			(c as MeshInstance3D).material_override = m
		silhouette(c)


## Größe (AABB über alle Meshes) in der XY-Ebene, für den Selbsttest.
static func _extent(node: Node3D) -> Vector2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in node.get_children():
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var b := mi.get_aabb()
			for corner in 8:
				var p := mi.transform * Vector3(b.position.x + (corner & 1) * b.size.x, b.position.y + ((corner >> 1) & 1) * b.size.y, b.position.z + ((corner >> 2) & 1) * b.size.z)
				lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
				hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	return hi - lo


## Selbsttest: jedes Werkzeug hat Meshes und Wirkpunkt; Breite/Höhe-Verhältnisse sind paarweise verschieden (Silhouetten).
static func selftest() -> bool:
	var ok := true
	var ratios: Array[float] = []
	var kinds := {}
	for k in KINDS:
		var t := build(k)
		var meshes := 0
		for c in t.get_children():
			if c is MeshInstance3D:
				meshes += 1
		ok = ok and meshes >= 3 and t.get_node_or_null("EffectPoint") != null
		var e := _extent(t)
		ratios.append(e.x / e.y)
		kinds[kind_of(k)] = true
		t.free()
	for i in ratios.size():
		for j in range(i + 1, ratios.size()):
			ok = ok and absf(ratios[i] - ratios[j]) > 0.1
	ok = ok and kinds.size() == 4
	print("SELFTEST ToolModels Breite/Höhe %s -> %s" % [str(ratios.map(func(r): return snappedf(r, 0.01))), "OK" if ok else "FAIL"])
	return ok
