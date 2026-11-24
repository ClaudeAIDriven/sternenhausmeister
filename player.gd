class_name Player
extends CharacterBody3D
## Dritte-Person-Spieler mit Staubwedel. Halte die linke Maustaste (oder E), um zu putzen.

signal wipe_requested(point: Vector3)

const SPEED := 6.0
const JUMP_VELOCITY := 7.0
const GRAVITY := 18.0
const REACH := 9.0
const MOUSE_SENS := 0.003

var yaw := 0.0
var pitch := -0.25
var arm: Node3D
var cam: Camera3D
var brush: Node3D
var cleaning := false
var aim_point := Vector3.ZERO
var aim_valid := false


func _enter_tree() -> void:
	# Netzwerk: Der Knotenname ist die Peer-ID, dieser Peer steuert seinen Spieler.
	if str(name).is_valid_int():
		set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	add_child(cs)

	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.4
	bm.height = 1.7
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.55, 0.9)
	mat.roughness = 0.8
	body.mesh = bm
	body.material_override = mat
	body.position.y = 0.85
	add_child(body)

	var face := MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.12
	fm.height = 0.24
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(1, 0.95, 0.8)
	fmat.emission_enabled = true
	fmat.emission = Color(1, 0.95, 0.8)
	face.mesh = fm
	face.material_override = fmat
	face.position = Vector3(0.15, 1.35, -0.33)
	add_child(face)
	var face2 := face.duplicate()
	face2.position = Vector3(-0.15, 1.35, -0.33)
	add_child(face2)

	# Staubwedel: Stiel + Federbüschel
	brush = Node3D.new()
	brush.position = Vector3(0.55, 1.1, -0.5)
	add_child(brush)
	var stick := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.03
	sm.bottom_radius = 0.03
	sm.height = 1.0
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.55, 0.35, 0.2)
	stick.mesh = sm
	stick.material_override = smat
	stick.position.y = 0.5
	brush.add_child(stick)
	var tip := MeshInstance3D.new()
	var tm := SphereMesh.new()
	tm.radius = 0.2
	tm.height = 0.4
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(1.0, 0.8, 0.9)
	tip.mesh = tm
	tip.material_override = tmat
	tip.position.y = 1.05
	brush.add_child(tip)

	arm = Node3D.new()
	arm.position.y = 1.5
	add_child(arm)
	cam = Camera3D.new()
	cam.position = Vector3(0, 0.7, 5.0)
	cam.fov = 70.0
	cam.current = is_multiplayer_authority()
	arm.add_child(cam)
	arm.rotation.x = pitch

	# Position und Blickrichtung an die anderen Spieler senden
	var cfg := SceneReplicationConfig.new()
	for prop in [^":position", ^":rotation"]:
		cfg.add_property(prop)
		cfg.property_set_replication_mode(prop, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.root_path = NodePath("..")
	sync.replication_config = cfg
	add_child(sync)


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * MOUSE_SENS
		pitch = clampf(pitch - event.relative.y * MOUSE_SENS, -1.2, 0.7)
		rotation.y = yaw
		arm.rotation.x = pitch


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return   # fremde Spieler werden per Synchronisation bewegt
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	move_and_slide()
	if global_position.y < -25.0:
		global_position = Vector3(0, 2, 6)
		velocity = Vector3.ZERO

	_update_aim()
	cleaning = Input.is_action_pressed("clean") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if cleaning and aim_valid:
		wipe_requested.emit(aim_point)


func _update_aim() -> void:
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * (REACH + 5.0)
	var q := PhysicsRayQueryParameters3D.create(from, to, 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	aim_valid = false
	if not hit.is_empty():
		var p: Vector3 = hit["position"]
		if p.distance_to(global_position + Vector3(0, 1.2, 0)) <= REACH:
			aim_point = p
			aim_valid = true


func _process(_delta: float) -> void:
	# Wedel schwingt beim Putzen
	var t := Time.get_ticks_msec() / 1000.0
	if cleaning:
		brush.rotation = Vector3(-0.9 + sin(t * 18.0) * 0.5, 0, sin(t * 9.0) * 0.3)
	else:
		brush.rotation = brush.rotation.lerp(Vector3(-0.3, 0, 0.2), 0.15)
