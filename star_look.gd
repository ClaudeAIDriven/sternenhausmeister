class_name StarLook
extends RefCounted
## Stern-Basismodell mit Reinigungsübergang (A-11). Ein Mesh, ein Material, Zustand über `clean` 0..1.
## Nutzung (Einbau gehört nicht zu dieser Karte): `var s := StarLook.build(2.0); add_child(s); StarLook.set_clean(s, 0.5)`.
## Form: leicht unregelmäßige Kugel mit dezenter Sternsilhouette (5 sanfte Spitzen um die Äquatorebene).

const LEVELS: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]
const SHADER_PATH := "res://shaders/star_clean.gdshader"


## Radiusfaktor in Richtung `dir` (Einheitsvektor): 1 + sanfte Spitzen + leichte Unregelmäßigkeit.
static func radius_factor(dir: Vector3) -> float:
	var phi := atan2(dir.z, dir.x)
	var spike := pow(maxf(0.0, cos(phi * 5.0)), 2.0) * (1.0 - dir.y * dir.y)
	var wobble := 0.04 * sin(dir.x * 5.0 + dir.y * 3.0) * sin(dir.z * 4.0 + 1.0)
	return 1.0 + 0.2 * spike + wobble


static func make_mesh(radius: float) -> ArrayMesh:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 40
	sm.rings = 20
	var arrays := sm.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		var d := verts[i].normalized()
		verts[i] = d * radius * radius_factor(d)
	arrays[Mesh.ARRAY_VERTEX] = verts
	# Normalen neu berechnen (glatt, aus den verschobenen Dreiecken)
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for t in range(0, idx.size(), 3):
		var n := (verts[idx[t + 1]] - verts[idx[t]]).cross(verts[idx[t + 2]] - verts[idx[t]])
		for k in 3:
			normals[idx[t + k]] += n
	for i in normals.size():
		normals[i] = normals[i].normalized()
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func build(radius := 2.0, with_overlays := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "StarLook"
	mi.mesh = make_mesh(radius)
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("dirt_color", Palette.DIRT_GRAY)
	mat.set_shader_parameter("gold_color", Palette.STAR_GOLD)
	mat.set_shader_parameter("clean", 0.0)
	if with_overlays:
		mat.set_shader_parameter("use_overlays", true)
		mat.set_shader_parameter("dirt_soot", DirtTextures.make(DirtTextures.Kind.SOOT))
		mat.set_shader_parameter("dirt_stain", DirtTextures.make(DirtTextures.Kind.STAIN))
		mat.set_shader_parameter("dirt_patina", DirtTextures.make(DirtTextures.Kind.PATINA))
	mi.material_override = mat
	return mi


static func set_clean(star: MeshInstance3D, value: float) -> void:
	(star.material_override as ShaderMaterial).set_shader_parameter("clean", clampf(value, 0.0, 1.0))


## Selbsttest: Shader lädt, `clean` wird übernommen, Form hat Spitzen (größter/kleinster Radius), Mesh ist gültig.
static func selftest() -> bool:
	var s := build(2.0)
	set_clean(s, 0.5)
	var mat := s.material_override as ShaderMaterial
	var ok := mat.shader != null and is_equal_approx(float(mat.get_shader_parameter("clean")), 0.5)
	var aabb := s.mesh.get_aabb()
	var lo := INF
	var hi := 0.0
	for v in (s.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		lo = minf(lo, (v as Vector3).length())
		hi = maxf(hi, (v as Vector3).length())
	ok = ok and aabb.size.x > 3.8 and hi / lo > 1.15 and hi / lo < 1.4
	s.free()
	print("SELFTEST StarLook Spitzenverhältnis %.2f -> %s" % [hi / lo, "OK" if ok else "FAIL"])
	return ok
