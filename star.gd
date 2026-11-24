class_name Star
extends Node3D
## Ein verschmutzter Stern. Schmutzflecken werden weggewischt, der Stern beginnt zu leuchten.

signal scrubbed(removed: int)
signal cleaned
signal reset_done
signal redirtied(restored: int)   # G-15: Sternschnuppe hat einzelne Flecken zurückgebracht

@export var radius := 2.0
@export var spot_count := 140

var spots: Array[MeshInstance3D] = []
var total := 0
var progress := 0.0
var is_clean := false
var last_removed: Array[int] = []   # Fleck-IDs, die der letzte wipe() entfernt hat (für Netzwerk-Replikation)
var removed_ids: Array[int] = []    # alle entfernten Fleck-IDs (Zustand für Nachzügler)

var _by_id := {}
var _spot_mesh: SphereMesh
var _spot_mats := {}

var _look: MeshInstance3D
var _light: OmniLight3D
var _hint := false


func _ready() -> void:
	_look = StarLook.build(radius)   # A-11: Sternform, Schmutz-Overlays, Putzübergang per Shader
	# Gold etwas gedämpft, sonst überstrahlt der Umgebungs-Glow (sky.gd) den sauberen Stern zu einer gelben Fläche
	var lm := _look.material_override as ShaderMaterial
	lm.set_shader_parameter("gold_color", Palette.STAR_GOLD.darkened(0.35))
	lm.set_shader_parameter("rim_color", Palette.STAR_GOLD.darkened(0.25))
	add_child(_look)

	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = radius * 1.1
	cs.shape = sh
	body.add_child(cs)
	add_child(body)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.85, 0.45)
	_light.omni_range = 18.0
	_light.light_energy = 0.0
	add_child(_light)

	_build_spots()


## Baut alle Schmutzflecken (neu) auf. Fleck-IDs sind bei allen Spielern gleich (Reihenfolge der Fibonacci-Kugel).
func _build_spots() -> void:
	_spot_mesh = SphereMesh.new()
	_spot_mesh.radius = 0.3
	_spot_mesh.height = 0.6
	_spot_mesh.radial_segments = 8
	_spot_mesh.rings = 4
	_spot_mats = {}
	for d in CleanTool.DIRT_COLORS:
		var m := StandardMaterial3D.new()
		m.albedo_color = CleanTool.DIRT_COLORS[d]
		m.roughness = 1.0
		_spot_mats[d] = m
	for i in spot_count:
		spots.append(_make_spot(i))
	total = spots.size()
	_apply_glow()


## Erzeugt den Fleck mit der ID i (Fibonacci-Kugel, bei allen Spielern gleich) und hängt ihn an den Stern.
func _make_spot(i: int) -> MeshInstance3D:
	var y := 1.0 - (float(i) / (spot_count - 1)) * 2.0
	var r := sqrt(maxf(0.0, 1.0 - y * y))
	var th := PI * (3.0 - sqrt(5.0)) * i
	var dir := Vector3(cos(th) * r, y, sin(th) * r)
	var up := Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT
	var s := MeshInstance3D.new()
	s.mesh = _spot_mesh
	var dirt: int = i % 3
	s.material_override = _spot_mats[dirt]
	s.set_meta("dirt", dirt)
	s.set_meta("hp", 1.0)
	s.set_meta("id", i)
	_by_id[i] = s
	s.basis = Basis.looking_at(dir, up) * Basis.from_scale(Vector3(1, 1, 0.35))
	s.position = dir * radius * StarLook.radius_factor(dir) * 0.99   # sitzt auf der Sternoberfläche (mit Spitzen)
	add_child(s)
	return s


func _process(delta: float) -> void:
	rotate_y(delta * 0.08)


## Wischt alle Flecken im Radius um einen Weltpunkt weg. Gibt die Anzahl entfernter Flecken zurück.
## tool: CleanTool.Kind; ANY (Standard) wirkt auf alles voll. Falsches Werkzeug entfernt Flecken nur nach mehreren Zügen.
## Die entfernten Fleck-IDs stehen danach in `last_removed` (für die Replikation durch World).
func wipe(world_point: Vector3, wipe_radius: float, tool: int = CleanTool.Kind.ANY) -> int:
	last_removed = []
	if is_clean:
		return 0
	var local_p := to_local(world_point)
	var removed := 0
	for s in spots.duplicate():
		if s.position.distance_to(local_p) < wipe_radius:
			var hp: float = s.get_meta("hp") - CleanTool.efficiency(tool, s.get_meta("dirt"))
			s.set_meta("hp", hp)
			if hp > 0.001:
				continue
			last_removed.append(s.get_meta("id"))
			_remove_spot(s)
			removed += 1
	_finish_removal(removed)
	return removed


## Entfernt Flecken anhand ihrer IDs (Client-Seite: der Host hat entschieden). Unbekannte/bereits entfernte IDs werden ignoriert.
func apply_removed(ids: Array) -> int:
	var removed := 0
	for id in ids:
		var s: MeshInstance3D = _by_id.get(int(id))
		if s != null and spots.has(s):
			_remove_spot(s)
			removed += 1
	_finish_removal(removed)
	return removed


func _remove_spot(s: MeshInstance3D) -> void:
	spots.erase(s)
	removed_ids.append(s.get_meta("id"))
	if s.is_inside_tree() and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(s, "scale", Vector3.ZERO, 0.15)
		tw.tween_callback(s.queue_free)
	else:
		s.queue_free()


func _finish_removal(removed: int) -> void:
	if removed > 0:
		progress = 1.0 - float(spots.size()) / float(total)
		_apply_glow()
		scrubbed.emit(removed)
		if spots.is_empty() and not is_clean:
			is_clean = true
			cleaned.emit()


func _apply_glow() -> void:
	StarLook.set_clean(_look, progress)
	_light.light_energy = maxf(lerpf(0.0, 1.2, progress), 1.6 if _hint else 0.0)


## Stern wieder komplett verschmutzen (falsche Sternbild-Reihenfolge). Wird bei allen Spielern ausgeführt.
func reset() -> void:
	for sp in spots:
		sp.queue_free()
	spots.clear()
	_by_id.clear()
	removed_ids.clear()
	last_removed = []
	is_clean = false
	progress = 0.0
	_build_spots()
	reset_done.emit()


## Hinweis: Der Stern leuchtet sanft, solange er der nächste richtige ist.
func set_hint(on: bool) -> void:
	_hint = on
	_apply_glow()


## G-15 (Host): Bringt `count` zufällige bereits entfernte Flecken zurück (Sternschnuppe). Gibt die Fleck-IDs zurück
## (leer, wenn nichts zu verschmutzen war). Clients wenden dieselben IDs mit `apply_restored` an.
func redirty(count: int, rng: RandomNumberGenerator = null) -> Array[int]:
	var pool: Array[int] = removed_ids.duplicate()
	var picked: Array[int] = []
	while picked.size() < count and not pool.is_empty():
		var k := (rng.randi() if rng != null else randi()) % pool.size()
		picked.append(pool[k])
		pool.remove_at(k)
	apply_restored(picked)
	return picked


## Bringt Flecken anhand ihrer IDs zurück (Client-Seite). Unbekannte oder noch vorhandene IDs werden ignoriert.
func apply_restored(ids: Array) -> int:
	var restored := 0
	for id in ids:
		var i := int(id)
		if i < 0 or i >= spot_count or not removed_ids.has(i):
			continue
		removed_ids.erase(i)
		spots.append(_make_spot(i))
		restored += 1
	if restored > 0:
		is_clean = false
		progress = 1.0 - float(spots.size()) / float(total)
		_apply_glow()
		redirtied.emit(restored)
	return restored
