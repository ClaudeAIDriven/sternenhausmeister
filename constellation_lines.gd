class_name ConstellationLines
extends Node3D
## Sternbild-Linien (A-13): dünne goldene, leicht "handgezeichnete" Linien mit runden Enden, leuchtende Knotenpunkte,
## sanftes Pulsieren und ein Funkel-Burst bei Fertigstellung. Nur ein Linienmaterial und ein Knotenmaterial (wenige Draw Calls).
## Nutzung (Einbau gehört nicht zu dieser Karte):
##   var c := ConstellationLines.new(); add_child(c); c.build(punkte)   # Weltpositionen der Sterne, Kette p0-p1-p2-...
##   c.set_progress(0.5)   # zeigt die Hälfte der Segmente, c.finish() = alles + Burst

signal finished

@export var reduced_motion := false   # true = kein Pulsieren
@export var line_radius := 0.045
@export var node_radius := 0.13

var points: Array[Vector3] = []
var edges: Array[Vector2i] = []
var segment_count := 0
var node_count := 0
var _line_mat: StandardMaterial3D
var _node_mat: StandardMaterial3D
var _segments: Array[Node3D] = []   # je Kante ein Node3D mit mehreren Capsule-Teilstücken
var _nodes: Array[MeshInstance3D] = []
var _progress := 0.0
var _t := 0.0


func _make_mats() -> void:
	_line_mat = StandardMaterial3D.new()
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_mat.albedo_color = Palette.STAR_GOLD
	_node_mat = StandardMaterial3D.new()
	_node_mat.albedo_color = Palette.STAR_GOLD
	_node_mat.emission_enabled = true
	_node_mat.emission = Palette.STAR_GOLD
	_node_mat.emission_energy_multiplier = 0.8


## `pts`: Weltpositionen. `edge_list` leer = einfache Kette p0-p1-...-p(n-1) (n-1 Segmente).
func build(pts: Array[Vector3], edge_list: Array[Vector2i] = [], seed_value := 11) -> void:
	for c in get_children():
		c.queue_free()
	_segments.clear()
	_nodes.clear()
	points = pts.duplicate()
	edges = edge_list.duplicate()
	if edges.is_empty():
		for i in points.size() - 1:
			edges.append(Vector2i(i, i + 1))
	_make_mats()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for e in edges:
		var seg := Node3D.new()
		seg.name = "Segment"
		add_child(seg)
		_segments.append(seg)
		_draw_segment(seg, points[e.x], points[e.y], rng)
	for p in points:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = node_radius
		sm.height = node_radius * 2.0
		sm.radial_segments = 8
		sm.rings = 4
		mi.mesh = sm
		mi.material_override = _node_mat
		mi.position = p
		mi.name = "Node"
		add_child(mi)
		_nodes.append(mi)
	segment_count = _segments.size()
	node_count = _nodes.size()
	set_progress(1.0)


## Linie aus 3 Capsule-Teilen mit kleinem Versatz quer zur Richtung, damit sie von Hand gezogen wirkt, nicht wie ein Kabel.
func _draw_segment(seg: Node3D, a: Vector3, b: Vector3, rng: RandomNumberGenerator) -> void:
	var dir := (b - a)
	var length := dir.length()
	if length < 0.001:
		return
	var up := Vector3.UP if absf(dir.normalized().y) < 0.95 else Vector3.RIGHT
	var side := dir.normalized().cross(up).normalized()
	var parts := 3
	var wobble := length * 0.025
	var pts: Array[Vector3] = [a]
	for i in range(1, parts):
		pts.append(a.lerp(b, float(i) / parts) + side * rng.randf_range(-wobble, wobble))
	pts.append(b)
	for i in pts.size() - 1:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var d := p1 - p0
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()   # runde Enden
		cap.radius = line_radius
		cap.height = d.length() + line_radius * 2.0
		cap.radial_segments = 6
		cap.rings = 2
		mi.mesh = cap
		mi.material_override = _line_mat
		var y := d.normalized()
		var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT).normalized()
		var z := x.cross(y).normalized()
		mi.transform = Transform3D(Basis(x, y, z), (p0 + p1) * 0.5)
		seg.add_child(mi)


## 0..1: wie viele Segmente (und deren Knoten) sichtbar sind.
func set_progress(p: float) -> void:
	_progress = clampf(p, 0.0, 1.0)
	var n := int(round(_progress * segment_count))
	for i in _segments.size():
		_segments[i].visible = i < n
	for i in _nodes.size():
		_nodes[i].visible = i <= n


func progress() -> float:
	return _progress


func visible_segments() -> int:
	var n := 0
	for s in _segments:
		if s.visible:
			n += 1
	return n


## Fertigstellung: alles zeigen, kurzer Funkel-Burst in der Mitte (Effects aus A-05).
func finish() -> void:
	set_progress(1.0)
	if is_inside_tree() and points.size() > 0:
		var c := Vector3.ZERO
		for p in points:
			c += p
		Effects.sparkle_burst(self, c / points.size(), 0.0)
	finished.emit()


func _process(delta: float) -> void:
	_t += delta
	pulse(_t)


## Dezentes Pulsieren der Knoten (Leuchtstärke 0,6 .. 1,0). Mit `reduced_motion` bleibt es konstant.
func pulse(t: float) -> void:
	if _node_mat == null:
		return
	_node_mat.emission_energy_multiplier = 0.8 if reduced_motion else 0.8 + 0.2 * sin(t * 2.2)


## Selbsttest: n Punkte -> n-1 Segmente und n Knoten, Fortschritt blendet Segmente aus, Pulsieren ändert sich, reduced_motion nicht.
static func selftest() -> bool:
	var c := ConstellationLines.new()
	var pts: Array[Vector3] = [Vector3(0, 0, 0), Vector3(2, 1, 0), Vector3(4, 0.5, 0), Vector3(5, 2.5, 0), Vector3(3, 3.5, 0)]
	c.build(pts)
	var ok := c.segment_count == 4 and c.node_count == 5 and c.visible_segments() == 4
	c.set_progress(0.5)
	ok = ok and c.visible_segments() == 2
	c.set_progress(1.0)
	c.pulse(0.0)
	var e0 := c._node_mat.emission_energy_multiplier
	c.pulse(0.7)
	var e1 := c._node_mat.emission_energy_multiplier
	ok = ok and not is_equal_approx(e0, e1)
	c.reduced_motion = true
	c.pulse(0.0)
	var r0 := c._node_mat.emission_energy_multiplier
	c.pulse(0.7)
	ok = ok and is_equal_approx(r0, c._node_mat.emission_energy_multiplier)
	c.free()
	print("SELFTEST ConstellationLines 5 Punkte, 4 Segmente, Puls %.2f/%.2f -> %s" % [e0, e1, "OK" if ok else "FAIL"])
	return ok
