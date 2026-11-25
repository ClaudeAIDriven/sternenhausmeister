class_name SpiderEnemy
extends Enemy
## G-28: Spinne. Bewacht ihr Nest an einem Stern, beißt Spieler in BITE_RANGE alle BITE_INTERVAL Sekunden (BITE_DAMAGE) und lässt
## sich nur mit dem Staubsauger (CleanTool.Kind.VACUUM) entfernen; andere Werkzeuge prallen ab.

const BITE_DAMAGE := 8.0
const BITE_RANGE := 3.0
const BITE_INTERVAL := 2.0

var _bite_cd := 0.0
var _legs: Array[MeshInstance3D] = []
var _t := 0.0
var _wander := Vector3.ZERO
var _wander_t := 0.0
const CHASE_RANGE := 10.0
const CRAWL_SPEED := 0.45   # rad/s auf der Sternkugel


func _init() -> void:
	kind = "spinne"
	name = "Spinne"


func can_remove(tool: int) -> bool:
	return tool == CleanTool.Kind.VACUUM


func _ready() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.1, 0.14)
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.3
	sm.height = 0.5
	body.mesh = sm
	body.material_override = dark
	add_child(body)
	for i in 8:
		var leg := MeshInstance3D.new()
		var lm := CapsuleMesh.new()
		lm.radius = 0.03
		lm.height = 0.9
		leg.mesh = lm
		leg.material_override = dark
		var a := TAU * i / 8.0
		leg.position = Vector3(cos(a) * 0.45, 0.0, sin(a) * 0.45)
		leg.rotation = Vector3(sin(a) * 1.0, 0, -cos(a) * 1.0)
		add_child(leg)
		_legs.append(leg)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.2, 0.15)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.2, 0.15)
	for sx in [-0.1, 0.1]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.06
		em.height = 0.12
		eye.mesh = em
		eye.material_override = eye_mat
		eye.position = Vector3(sx, 0.1, 0.25)
		add_child(eye)


func act(delta: float, world) -> void:
	_bite_cd = maxf(_bite_cd - delta, 0.0)
	_crawl(delta, world)
	if world.zen or _bite_cd > 0.0:
		return
	for n in world.get_tree().get_nodes_in_group("players"):
		var p := n as Player
		if p == null or p.downed:
			continue
		if p.global_position.distance_to(global_position) <= BITE_RANGE:
			_bite_cd = BITE_INTERVAL
			world.bite_player(int(str(p.name)), BITE_DAMAGE)
			return


func _process(delta: float) -> void:   # M-06: Beine zucken, vor dem Biss schneller
	_t += delta
	var speed := 5.0 if _bite_cd > BITE_INTERVAL - 0.5 else 2.0
	for i in _legs.size():
		var a := TAU * i / 8.0
		_legs[i].rotation = Vector3(sin(a) * 1.0 + sin(_t * speed + i) * 0.18, 0, -cos(a) * 1.0)


## Bugfix: Spinnen krabbeln über den Stern, jagen Spieler in CHASE_RANGE und laufen sonst ziellos umher.
func _crawl(delta: float, world) -> void:
	if star == null:
		return
	var best: Node3D = null
	var best_d := CHASE_RANGE
	if not world.zen:
		for n in world.get_tree().get_nodes_in_group("players"):
			var p := n as Player
			if p == null or p.downed:
				continue
			var d := p.global_position.distance_to(global_position)
			if d < best_d:
				best_d = d
				best = p
	var goal := Vector3.ZERO
	if best != null:
		goal = star.to_local(best.global_position).normalized()
	else:
		_wander_t -= delta
		if _wander_t <= 0.0 or _wander == Vector3.ZERO:
			_wander_t = randf_range(2.0, 5.0)
			_wander = Vector3(randf_range(-1, 1), randf_range(-0.2, 1), randf_range(-1, 1)).normalized()
		goal = _wander
	if goal == Vector3.ZERO or goal.is_equal_approx(dir):
		return
	var axis := dir.cross(goal)
	if axis.length() < 0.001:
		return
	var ang := minf(dir.angle_to(goal), CRAWL_SPEED * delta)
	rotate_dir(axis, ang)
	target_dir = dir
