class_name Star
extends Node3D
## Ein verschmutzter Stern. Schmutzflecken werden weggewischt, der Stern beginnt zu leuchten.

signal scrubbed(removed: int)
signal cleaned

@export var radius := 2.0
@export var spot_count := 140

var spots: Array[MeshInstance3D] = []
var total := 0
var progress := 0.0
var is_clean := false

var _mat: StandardMaterial3D
var _light: OmniLight3D


func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.42, 0.4, 0.4)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.85, 0.35)
	_mat.emission_energy_multiplier = 0.15
	_mat.roughness = 0.6
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat
	add_child(mi)

	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = radius
	cs.shape = sh
	body.add_child(cs)
	add_child(body)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.85, 0.45)
	_light.omni_range = 18.0
	_light.light_energy = 0.0
	add_child(_light)

	var spot_mesh := SphereMesh.new()
	spot_mesh.radius = 0.3
	spot_mesh.height = 0.6
	spot_mesh.radial_segments = 8
	spot_mesh.rings = 4
	var spot_mat := StandardMaterial3D.new()
	spot_mat.albedo_color = Color(0.16, 0.1, 0.07)
	spot_mat.roughness = 1.0
	for i in spot_count:
		var y := 1.0 - (float(i) / (spot_count - 1)) * 2.0
		var r := sqrt(maxf(0.0, 1.0 - y * y))
		var th := PI * (3.0 - sqrt(5.0)) * i
		var dir := Vector3(cos(th) * r, y, sin(th) * r)
		var up := Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT
		var s := MeshInstance3D.new()
		s.mesh = spot_mesh
		s.material_override = spot_mat
		s.basis = Basis.looking_at(dir, up) * Basis.from_scale(Vector3(1, 1, 0.35))
		s.position = dir * radius * 0.99
		add_child(s)
		spots.append(s)
	total = spots.size()
	_apply_glow()


func _process(delta: float) -> void:
	rotate_y(delta * 0.08)


## Wischt alle Flecken im Radius um einen Weltpunkt weg. Gibt die Anzahl entfernter Flecken zurück.
func wipe(world_point: Vector3, wipe_radius: float) -> int:
	if is_clean:
		return 0
	var local_p := to_local(world_point)
	var removed := 0
	for s in spots.duplicate():
		if s.position.distance_to(local_p) < wipe_radius:
			spots.erase(s)
			removed += 1
			if s.is_inside_tree() and is_inside_tree():
				var tw := create_tween()
				tw.tween_property(s, "scale", Vector3.ZERO, 0.15)
				tw.tween_callback(s.queue_free)
			else:
				s.queue_free()
	if removed > 0:
		progress = 1.0 - float(spots.size()) / float(total)
		_apply_glow()
		scrubbed.emit(removed)
		if spots.is_empty():
			is_clean = true
			cleaned.emit()
	return removed


func _apply_glow() -> void:
	_mat.albedo_color = Color(0.42, 0.4, 0.4).lerp(Color(1.0, 0.92, 0.6), progress)
	_mat.emission_energy_multiplier = lerpf(0.15, 3.0, progress)
	_light.light_energy = lerpf(0.0, 4.0, progress)
