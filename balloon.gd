class_name Balloon
extends AnimatableBody3D
## Ballon-Plattform (G-10): steigt, solange mindestens ein Spieler an Bord ist, bis zur Zielhöhe
## und sinkt sanft zurück, wenn leer. Mehrere Spieler können gleichzeitig mitfahren (Koop).
## Einbau (nicht Teil dieser Karte): `var b := Balloon.new(); b.position = ...; add_child(b)`.
## Als AnimatableBody3D nimmt er CharacterBody3D-Spieler auf der Plattform mit.

signal reached_top
signal returned

const RISE_SPEED := 2.5   # m/s aufwärts
const FALL_SPEED := 1.5   # m/s abwärts, wenn leer
const BOARD_SIZE := Vector3(3.0, 0.3, 3.0)

@export var top_height := 14.0   # Höhe der Plattform über dem Start (Sterne in 12 m sind so erreichbar)
var base_y := 0.0
var riders := 0
var at_top := false
var _area: Area3D


func _ready() -> void:
	base_y = position.y
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = BOARD_SIZE
	cs.shape = box
	add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = BOARD_SIZE
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.55, 0.3)
	mi.mesh = bm
	mi.material_override = mat
	add_child(mi)
	# Ballonhülle (nur Optik) über der Plattform
	var env := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.0
	sm.height = 4.0
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color(0.9, 0.35, 0.4)
	env.mesh = sm
	env.material_override = emat
	env.position.y = 5.0
	add_child(env)
	# Zone knapp über der Plattform zählt Mitfahrer
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = 1
	var acs := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(BOARD_SIZE.x, 1.5, BOARD_SIZE.z)
	acs.shape = abox
	acs.position.y = 1.0
	_area.add_child(acs)
	add_child(_area)
	_area.body_entered.connect(func(b: Node3D) -> void: if b is Player: riders += 1)
	_area.body_exited.connect(func(b: Node3D) -> void: if b is Player: riders = maxi(riders - 1, 0))


func _physics_process(delta: float) -> void:
	position.y = next_height(position.y, riders, delta)
	_check_events()


## Reine Logik (testbar ohne Physik): neue Höhe nach `delta` Sekunden.
func next_height(y: float, rider_count: int, delta: float) -> float:
	if rider_count > 0:
		return minf(y + RISE_SPEED * delta, base_y + top_height)
	return maxf(y - FALL_SPEED * delta, base_y)


func _check_events() -> void:
	var top := position.y >= base_y + top_height - 0.001
	if top and not at_top:
		reached_top.emit()
	if not top and at_top and position.y <= base_y + 0.001:
		returned.emit()
	if top != at_top and (top or position.y <= base_y + 0.001):
		at_top = top


## Selbsttest: Mit Mitfahrer erreicht die Plattform die Höhe von 12 m, ohne Mitfahrer sinkt sie zurück.
## Reine Rechnung, keine Physik. Aufruf: `Balloon.selftest()`.
static func selftest() -> bool:
	var b := Balloon.new()
	b.base_y = 0.0
	var y := 0.0
	var t := 0.0
	var reached_12 := -1.0
	while t < 30.0:
		y = b.next_height(y, 1, 1.0 / 60.0)
		t += 1.0 / 60.0
		if reached_12 < 0.0 and y >= 12.0:
			reached_12 = t
	var capped := is_equal_approx(y, b.top_height)
	var down := y
	for i in 3600:
		down = b.next_height(down, 0, 1.0 / 60.0)
	var ok := reached_12 > 0.0 and reached_12 < 10.0 and capped and is_zero_approx(down)
	b.free()
	print("SELFTEST Balloon 12m nach %.1fs, oben=%s, unten=%s -> %s" % [reached_12, capped, is_zero_approx(down), "OK" if ok else "FAIL"])
	return ok
