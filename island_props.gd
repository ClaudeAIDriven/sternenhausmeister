class_name IslandProps
extends RefCounted
## Insel-Dekoration (A-12): kachelbare Bodentextur, Gras-Büschel, Steine, Büsche, Laterne, Werkstatt-Schild.
## Gras und Steine kommen als MultiMesh (je 1 Draw Call). Nutzung (Einbau gehört nicht zu dieser Karte):
##   var deco := IslandProps.decorate(13.0, 42)   # Node3D mit Gras, Steinen, Büschen (Insel-Mitte = Ursprung, Oberseite y=0)
##   add_child(deco)
##   var lamp := IslandProps.lantern(); lamp.position = Vector3(5, 0, 6); add_child(lamp)

const TEX_SIZE := 256


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	return m


# --- Bodentextur: kachelbar (periodisches Wertrauschen, Perioden teilen 256), handgemalt-flächig ---
static func _h(x: int, y: int, period: int, s: int) -> float:
	return float(hash(Vector3i(posmod(x, period), posmod(y, period), s)) % 10000) / 10000.0


static func _pnoise(u: float, v: float, period: int, s: int) -> float:
	var x := u * period
	var y := v * period
	var xi := int(floor(x))
	var yi := int(floor(y))
	var fx := x - xi
	var fy := y - yi
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(_h(xi, yi, period, s), _h(xi + 1, yi, period, s), fx), lerpf(_h(xi, yi + 1, period, s), _h(xi + 1, yi + 1, period, s), fx), fy)


static func ground_image(seed_value := 3) -> Image:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var base := Palette.ISLAND
	var grass := Palette.player_color(3).lerp(Palette.ISLAND, 0.55).lightened(0.05)   # sanftes Blaugrün für Grasflächen
	for y in TEX_SIZE:
		for x in TEX_SIZE:
			var u := float(x) / TEX_SIZE
			var v := float(y) / TEX_SIZE
			var n := _pnoise(u, v, 4, seed_value) * 0.6 + _pnoise(u, v, 8, seed_value + 1) * 0.3 + _pnoise(u, v, 16, seed_value + 2) * 0.1
			var c := base.lerp(grass, smoothstep(0.5, 0.62, n))              # flächige Grasinseln mit weicher, handgemalter Kante
			c = c.lightened(0.12 * (_pnoise(u, v, 32, seed_value + 3) - 0.5))   # leichte Pinselstruktur
			img.set_pixel(x, y, c)
	return img


static func ground_texture(seed_value := 3) -> ImageTexture:
	return ImageTexture.create_from_image(ground_image(seed_value))


## Bodenmaterial mit kachelnder Textur. `tiles`: Wiederholungen über die Insel (UV-Skala).
static func ground_material(tiles := 6.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = ground_texture()
	m.uv1_scale = Vector3(tiles, tiles, 1)
	m.texture_repeat = true
	m.roughness = 0.95
	return m


# --- Einzelteile ---
static func grass_tuft_mesh() -> ArrayMesh:
	# drei gekreuzte, spitze Halme als ein Mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var a := i * PI / 3.0
		var dx := cos(a) * 0.09
		var dz := sin(a) * 0.09
		var lean := Vector3(sin(a * 2.0) * 0.05, 0, cos(a * 2.0) * 0.05)
		for v in [Vector3(-dx, 0, -dz), Vector3(dx, 0, dz), Vector3(0, 0.38, 0) + lean]:
			st.add_vertex(v)
		for v in [Vector3(dx, 0, dz), Vector3(-dx, 0, -dz), Vector3(0, 0.38, 0) + lean]:   # Rückseite
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


static func rock_mesh() -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 0.7
	s.radial_segments = 6
	s.rings = 3
	return s


static func bush_mesh() -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 0.8
	s.radial_segments = 8
	s.rings = 4
	return s


static func _multimesh(parent: Node3D, mesh: Mesh, mat: Material, transforms: Array[Transform3D], nm: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.material_override = mat
	parent.add_child(mmi)


## Streut Gras, Steine und Büsche auf die Inselfläche (Radius `radius`, Ring zwischen Rand und Mitte, Mitte bleibt frei).
static func decorate(radius := 13.0, seed_value := 42, grass_n := 160, rock_n := 24, bush_n := 9) -> Node3D:
	var root := Node3D.new()
	root.name = "IslandDeco"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var spot := func(rmin: float, rmax: float) -> Vector3:
		var a := rng.randf() * TAU
		var r := rng.randf_range(rmin, rmax)
		return Vector3(cos(a) * r, 0.0, sin(a) * r)
	var gt: Array[Transform3D] = []
	for i in grass_n:
		var p: Vector3 = spot.call(3.0, radius - 0.6)
		gt.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.7, 1.5)), p))
	_multimesh(root, grass_tuft_mesh(), _mat(Palette.player_color(3).lerp(Palette.ISLAND, 0.25)), gt, "Grass")
	var rt: Array[Transform3D] = []
	for i in rock_n:
		var p: Vector3 = spot.call(4.0, radius - 0.4)
		var sc := rng.randf_range(0.25, 0.9)
		rt.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc * rng.randf_range(0.8, 1.3), sc * 0.7, sc)), p + Vector3(0, sc * 0.2, 0)))
	_multimesh(root, rock_mesh(), _mat(Palette.ISLAND.darkened(0.25)), rt, "Rocks")
	var bt: Array[Transform3D] = []
	for i in bush_n:
		var p: Vector3 = spot.call(6.0, radius - 1.0)
		var sc := rng.randf_range(0.8, 1.5)
		bt.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), p + Vector3(0, 0.3 * sc, 0)))
	_multimesh(root, bush_mesh(), _mat(Palette.player_color(3).lerp(Palette.ISLAND, 0.35).darkened(0.1)), bt, "Bushes")
	return root


## Laterne: Pfosten, leuchtende Lampe, optional ein kleines Licht (Lichter sparsam setzen, Compatibility!).
static func lantern(with_light := true) -> Node3D:
	var n := Node3D.new()
	n.name = "Lantern"
	var wood := _mat(Color(0.35, 0.27, 0.22))
	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.05
	pm.bottom_radius = 0.07
	pm.height = 1.6
	pm.radial_segments = 6
	post.mesh = pm
	post.material_override = wood
	post.position.y = 0.8
	n.add_child(post)
	var lamp := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.3, 0.38, 0.3)
	lamp.mesh = lm
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Palette.STAR_GOLD
	glow.emission_enabled = true
	glow.emission = Palette.STAR_GOLD
	glow.emission_energy_multiplier = 1.2
	lamp.material_override = glow
	lamp.position.y = 1.78
	n.add_child(lamp)
	var cap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.28
	cm.height = 0.2
	cm.radial_segments = 4
	cap.mesh = cm
	cap.material_override = wood
	cap.position.y = 2.07
	n.add_child(cap)
	if with_light:
		var l := OmniLight3D.new()
		l.light_color = Palette.STAR_GOLD
		l.light_energy = 0.7
		l.omni_range = 5.0
		l.position.y = 1.78
		n.add_child(l)
	return n


## Werkstatt-Schild: Brett an einem Pfosten mit Text (Standard "Werkstatt").
static func sign_post(text := "Werkstatt") -> Node3D:
	var n := Node3D.new()
	n.name = "SignPost"
	var wood := _mat(Color(0.5, 0.36, 0.22))
	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.06
	pm.bottom_radius = 0.08
	pm.height = 1.3
	pm.radial_segments = 6
	post.mesh = pm
	post.material_override = wood
	post.position.y = 0.65
	n.add_child(post)
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.3, 0.45, 0.08)
	board.mesh = bm
	board.material_override = _mat(Color(0.62, 0.45, 0.28))
	board.position.y = 1.2
	n.add_child(board)
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 48
	lab.pixel_size = 0.0045
	lab.modulate = Palette.UI_IVORY
	lab.outline_size = 8
	lab.outline_modulate = Color(0.2, 0.13, 0.08)
	lab.position = Vector3(0, 1.2, 0.05)
	lab.name = "Text"
	n.add_child(lab)
	return n


## Selbsttest: Bodentextur kachelbar (Randpixel-Test), Deko enthält Gras/Steine/Büsche als MultiMesh, Laterne leuchtet.
static func selftest() -> bool:
	var img := ground_image()
	# Randpixel-Test: Sprung über die Naht (Spalte 255 -> 0, Zeile 255 -> 0) darf nicht größer sein als typische Nachbarsprünge im Inneren.
	var seam := 0.0
	var inner := 0.0
	for i in TEX_SIZE:
		seam += absf(img.get_pixel(TEX_SIZE - 1, i).get_luminance() - img.get_pixel(0, i).get_luminance())
		seam += absf(img.get_pixel(i, TEX_SIZE - 1).get_luminance() - img.get_pixel(i, 0).get_luminance())
		inner += absf(img.get_pixel(127, i).get_luminance() - img.get_pixel(128, i).get_luminance())
		inner += absf(img.get_pixel(i, 127).get_luminance() - img.get_pixel(i, 128).get_luminance())
	var ok := seam <= inner * 1.5 + 0.5
	var d := decorate()
	var counts := {}
	for c in d.get_children():
		counts[c.name] = (c as MultiMeshInstance3D).multimesh.instance_count
	ok = ok and counts.get("Grass", 0) > 100 and counts.get("Rocks", 0) > 10 and counts.get("Bushes", 0) > 3
	var l := lantern()
	ok = ok and l.get_child_count() == 4 and sign_post().get_node("Text") != null
	d.free()
	l.free()
	print("SELFTEST IslandProps Naht %.1f vs innen %.1f, %s -> %s" % [seam, inner, str(counts), "OK" if ok else "FAIL"])
	return ok
