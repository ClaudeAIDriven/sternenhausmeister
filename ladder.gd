class_name Ladder
extends Node3D
## G-24: Leiter des Kletterers. Steht LIFETIME Sekunden und kann von allen Spielern hochgeklettert werden (vorwärts laufen).
## Wird bei allen Spielern lokal erzeugt (RPC am Spieler), keine eigene Synchronisation nötig.

const LIFETIME := 8.0
const HEIGHT := 7.0
const REACH := 0.9          # waagerechter Abstand, in dem man klettern kann
const CLIMB_SPEED := 4.0

var left := LIFETIME


func _ready() -> void:
	add_to_group("ladders")
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.55, 0.38, 0.2)
	for sx in [-0.35, 0.35]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.08, HEIGHT, 0.08)
		rail.mesh = rm
		rail.material_override = wood
		rail.position = Vector3(sx, HEIGHT * 0.5, 0)
		add_child(rail)
	for i in int(HEIGHT / 0.5):
		var rung := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.7, 0.06, 0.06)
		rung.mesh = gm
		rung.material_override = wood
		rung.position = Vector3(0, 0.4 + i * 0.5, 0)
		add_child(rung)


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	left -= delta
	if left <= 0.0 and is_inside_tree():
		queue_free()


## Kann ein Spieler an `pos` (Weltposition der Füße) diese Leiter benutzen?
func can_climb(pos: Vector3) -> bool:
	if left <= 0.0:
		return false
	var d := Vector2(pos.x - global_position.x, pos.z - global_position.z).length()
	return d <= REACH and pos.y >= global_position.y - 0.5 and pos.y <= global_position.y + HEIGHT


## Erste benutzbare Leiter im Baum (oder null).
static func find_for(tree: SceneTree, pos: Vector3) -> Ladder:
	for n in tree.get_nodes_in_group("ladders"):
		var l := n as Ladder
		if l != null and l.can_climb(pos):
			return l
	return null
