class_name Ladder
extends Node3D
## G-24: Leiter des Kletterers. Steht LIFETIME Sekunden, danach verschwindet sie. Alle Spieler dürfen sie benutzen:
## `can_use(pos)` = Spieler steht nah genug an der Leiter. Der Player steigt dann mit CLIMB_SPEED nach oben.
## Die Leiter ist lokal (nicht über das Netzwerk repliziert).

const LIFETIME := 8.0
const HEIGHT := 5.0
const REACH := 1.0          # waagrechter Abstand, in dem man sie nutzt
const CLIMB_SPEED := 4.0

var left := LIFETIME


func _init() -> void:
	name = "Ladder"
	add_to_group("ladders")


func tick(delta: float) -> bool:
	left -= delta
	if left <= 0.0:
		queue_free()
		return false
	return true


func can_use(pos: Vector3) -> bool:
	if left <= 0.0:
		return false
	var d := Vector2(pos.x - global_position.x, pos.z - global_position.z).length()
	return d <= REACH and pos.y >= global_position.y - 0.5 and pos.y <= global_position.y + HEIGHT


## Nächste benutzbare Leiter aus der Gruppe, sonst null.
static func find_usable(tree: SceneTree, pos: Vector3) -> Ladder:
	for l in tree.get_nodes_in_group("ladders"):
		if l is Ladder and l.can_use(pos):
			return l
	return null


func _process(delta: float) -> void:
	tick(delta)


func _ready() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.55, 0.38, 0.2)
	for x in [-0.3, 0.3]:
		var rail := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, HEIGHT, 0.08)
		rail.mesh = bm
		rail.material_override = wood
		rail.position = Vector3(x, HEIGHT * 0.5, 0)
		add_child(rail)
	for i in 10:
		var rung := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.6, 0.06, 0.06)
		rung.mesh = rm
		rung.material_override = wood
		rung.position = Vector3(0, 0.3 + i * 0.48, 0)
		add_child(rung)
