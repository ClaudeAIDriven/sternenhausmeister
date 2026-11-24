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
var look: Node3D
var look_index := -1
var _shop: Node


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

	# Figur (A-08) und Werkzeug (A-09); Farbe/Symbol hängen vom Platz in der Spielerliste ab
	brush = Node3D.new()
	brush.position = Vector3(0.55, 1.1, -0.5)
	add_child(brush)
	brush.add_child(ToolModels.build("duster"))
	_refresh_look()
	NetworkManager.players_changed.connect(_refresh_look)

	arm = Node3D.new()
	arm.position.y = 1.5
	add_child(arm)
	cam = Camera3D.new()
	cam.position = Vector3(0, 0.7, 5.0)
	cam.fov = float(Settings.get_value("fov"))
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
		var sens := float(Settings.get_value("mouse_sens"))
		yaw -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens, -1.2, 0.7)
		rotation.y = yaw
		arm.rotation.x = pitch


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return   # fremde Spieler werden per Synchronisation bewegt
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := stat("speed", SPEED)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
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
	var reach := stat("reach", REACH)
	var to := from - cam.global_transform.basis.z * (reach + 5.0)
	var q := PhysicsRayQueryParameters3D.create(from, to, 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	aim_valid = false
	if not hit.is_empty():
		var p: Vector3 = hit["position"]
		if p.distance_to(global_position + Vector3(0, 1.2, 0)) <= reach:
			aim_point = p
			aim_valid = true


func _process(_delta: float) -> void:
	# Wedel schwingt beim Putzen
	var t := Time.get_ticks_msec() / 1000.0
	if cleaning:
		brush.rotation = Vector3(-0.9 + sin(t * 18.0) * 0.5, 0, sin(t * 9.0) * 0.3)
	else:
		brush.rotation = brush.rotation.lerp(Vector3(-0.3, 0, 0.2), 0.15)


## Wert aus dem Shop (G-05), falls ein Shop im Spiel hängt, sonst der Standardwert.
func stat(key: String, fallback: float) -> float:
	if _shop == null or not is_instance_valid(_shop):
		_shop = get_tree().root.find_child("Shop", true, false) if is_inside_tree() else null
	if _shop != null and _shop.has_method("value"):
		var v: float = _shop.value(key)
		if v > 0.0:
			return v
	return fallback


## Platz in der Spielerliste (0..3): Host zuerst, danach nach Peer-ID. Offline 0.
func slot_index() -> int:
	var ids := NetworkManager.players.keys()
	ids.sort()
	var i := ids.find(str(name).to_int())
	return clampi(i, 0, 3) if i >= 0 else 0


func _refresh_look() -> void:
	var idx := slot_index()
	if idx == look_index and look != null:
		return
	look_index = idx
	if look != null:
		look.queue_free()
	look = PlayerLook.build(idx)
	look.name = "Look"
	add_child(look)
