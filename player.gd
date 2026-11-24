class_name Player
extends CharacterBody3D
## Dritte-Person-Spieler mit Staubwedel. Halte die linke Maustaste (oder E), um zu putzen.

signal wipe_requested(point: Vector3)
signal health_changed(value: float)
signal died
signal ping_received(sender: int, point: Vector3)   # G-33
signal revived(by_teammate: bool)   # G-20
signal helped_up(target: Player)    # M-14: ich habe jemanden wiederbelebt
signal hit_landed(target: Player)

const SPEED := 6.0
const JUMP_VELOCITY := 7.0
const GRAVITY := 18.0
const REACH := 9.0
const MOUSE_SENS := 0.003
## I-12: Gesundheit. Sie regeneriert erst nach REGEN_DELAY Sekunden ohne Schaden und dann nur langsam.
const MAX_HEALTH := 100.0
const REGEN_DELAY := 6.0
const REGEN_RATE := 1.0         # Punkte pro Sekunde
const SAFE_FALL := 5.0          # Fallhöhe in m ohne Schaden
const FALL_DAMAGE := 7.0        # Schaden je weiterem Meter
const HIT_DAMAGE := 12.0        # Schlag eines anderen Spielers
const ATTACK_RANGE := 2.4
const ATTACK_COOLDOWN := 0.7
const RESPAWN_INVULN := 2.0
const SPAWN_POINT := Vector3(0, 2, 6)
## G-20: Bei 0 Leben fällt der Spieler um, verliert 10 % Sternenstaub und wartet RESPAWN_TIME Sekunden. Ein Mitspieler
## beendet das sofort, wenn er REVIVE_TIME Sekunden F hält (Reichweite REVIVE_RANGE). Wiederbelebte starten mit halber Gesundheit.
const DEATH_DUST_LOSS := 0.10
const RESPAWN_TIME := 60.0
const REVIVE_TIME := 3.0
const REVIVE_RANGE := 2.5
const REVIVE_HEALTH := 0.5

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
var nameplate: Label3D
var _shop: Node
var _ping_cd := 0.0
const PING_COOLDOWN := 1.0
var brawl := false   # G-32: Rauflust (nur der Wert des Hosts zählt, wird repliziert); Standard friedlich
var _shown_tool := "wedel"   # G-25: welches Utensil gerade als Modell in der Hand ist
var health := MAX_HEALTH
var food := Food.new()         # G-21: Sättigung, nur lokal
var xp := Xp.new()             # M-01: Erfahrung, nur lokal
var skills: Skills             # M-01: Fähigkeiten (aus data/skills.json), nur lokal
var kitchen: Kitchen           # M-01: Küchen-Buffs (main setzt es aus der Welt)
var _air_jumps_left := 0
var _hat_role := ""
var hat_override := ""   # M-09: selbst gewählter Hut; M-13: wird repliziert, alle sehen ihn
var _hat_shown := "-"
var downed := false            # G-20: am Boden, wird mit repliziert
var respawn_left := 0.0
var revive_target: Player      # wen ich gerade wiederbelebe (für die Anzeige)
var revive_progress := 0.0     # 0..1
var last_dust_lost := 0
var _revive_held := 0.0
var role := Roles.DEFAULT_ID      # I-13, wird mit repliziert
var _jump_cd := 0.0
var _impulse := Vector3.ZERO
var _since_damage := 0.0
var _invuln := 0.0
var _attack_cd := 0.0
var _airborne := false
var _peak_y := 0.0
var _on_balloon: Balloon
var _last_pos := Vector3.ZERO
var _anim_speed := 0.0
var _phase := 0.0


func _enter_tree() -> void:
	# Netzwerk: Der Knotenname ist die Peer-ID, dieser Peer steuert seinen Spieler.
	if str(name).is_valid_int():
		set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	add_to_group("players")
	skills = Skills.new(xp, role)
	skills.load_data()
	if is_multiplayer_authority():
		role = str(Settings.get_value("role"))
		if Roles.can(role, "climb"):
			floor_max_angle = deg_to_rad(70.0)   # G-24: steile Flächen hinauflaufen
		brawl = bool(Menu.launch.get("brawl", false))
	_last_pos = global_position
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
	for prop in [^":position", ^":rotation", ^":health", ^":role", ^":downed"]:
		cfg.add_property(prop)
		cfg.property_set_replication_mode(prop, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	cfg.add_property(^":hat_override")   # M-13
	cfg.property_set_replication_mode(^":hat_override", SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	cfg.add_property(^":brawl")   # G-32
	cfg.property_set_replication_mode(^":brawl", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.root_path = NodePath("..")
	sync.replication_config = cfg
	add_child(sync)


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if aim_valid:
			send_ping(aim_point)   # G-33: Mittlere Maustaste = Ping
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_G and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		place_ladder()   # G-24: Kletterer stellt eine Leiter auf
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
	if downed:
		_physics_downed(delta)
		return
	update_revive(delta, Input.is_physical_key_pressed(KEY_F) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := stat("speed", SPEED) * Roles.factor(role, "speed") * food.speed_factor() * mod("speed")
	_jump_cd = maxf(_jump_cd - delta, 0.0)
	if _on_balloon != null and is_instance_valid(_on_balloon) and _on_balloon.is_aloft():
		# Ballon lenken (I-11): Auf der Plattform in der Luft steuert WASD den Ballon statt den Spieler.
		_on_balloon.request_steer(dir)   # M-12: online geht die Lenkung an den Host
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	velocity.x += _impulse.x
	velocity.z += _impulse.z
	_impulse = Vector3(_impulse.x, 0, _impulse.z).lerp(Vector3.ZERO, clampf(delta * 6.0, 0.0, 1.0))
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		if _air_jumps_left > 0 and Input.is_action_just_pressed("jump"):   # M-01: Doppelsprung (Fähigkeit)
			_air_jumps_left -= 1
			velocity.y = JUMP_VELOCITY * Roles.factor(role, "jump") * mod("jump")
			_peak_y = global_position.y
	elif Input.is_action_just_pressed("jump") and _jump_cd <= 0.0:
		velocity.y = JUMP_VELOCITY * Roles.factor(role, "jump") * mod("jump")
		food.on_jump()
		_jump_cd = Roles.factor(role, "jump_cd") * mod("jump_cd")
		_air_jumps_left = int(skills.add("double_jump")) if skills != null else 0
	_apply_climb(Input.get_vector("move_left", "move_right", "move_forward", "move_back"))
	move_and_slide()
	_track_floor()
	_track_fall(delta)
	if global_position.y < -25.0:
		_airborne = false
		global_position = SPAWN_POINT
		velocity = Vector3.ZERO
	food.tick(delta * Roles.factor(role, "hunger") * mod("hunger"), Vector2(velocity.x, velocity.z).length() > 0.5, cleaning)
	_tick_health(delta)
	if InputMap.has_action("attack") and Input.is_action_just_pressed("attack") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		try_attack()

	_update_aim()
	cleaning = Input.is_action_pressed("clean") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if cleaning and aim_valid:
		wipe_requested.emit(aim_point)


func _update_aim() -> void:
	var from := cam.global_position
	var reach := stat("reach", REACH) * mod("reach") + (skills.add("reach") if skills != null else 0.0)
	var to := from - cam.global_transform.basis.z * (reach + 5.0)
	var q := PhysicsRayQueryParameters3D.create(from, to, 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	aim_valid = false
	if not hit.is_empty():
		var p: Vector3 = hit["position"]
		if p.distance_to(global_position + Vector3(0, 1.2, 0)) <= reach:
			aim_point = p
			aim_valid = true


func _process(delta: float) -> void:
	# Lauf-Animation (I-11): aus der tatsächlichen Bewegung abgeleitet, damit sie auch bei fremden Spielern passt
	if delta > 0.0 and is_inside_tree():
		var moved := global_position - _last_pos
		moved.y = 0.0
		var sp := minf(moved.length() / delta, SPEED * 1.6)
		_anim_speed = lerpf(_anim_speed, sp, clampf(delta * 12.0, 0.0, 1.0))
		_last_pos = global_position
		_phase += _anim_speed * delta * 1.7
		if look != null:
			PlayerLook.animate(look, _phase, clampf(_anim_speed / SPEED, 0.0, 1.0))
	if look != null:   # G-20: Gefallene liegen auf der Seite
		look.rotation.z = lerpf(look.rotation.z, PI * 0.5 if downed else 0.0, clampf(delta * 8.0, 0.0, 1.0))
	_refresh_tool()
	if look != null and (role != _hat_role or hat_override != _hat_shown):   # M-06/M-13: Hut folgt Rolle und gewähltem Hut (beides repliziert)
		_hat_role = role
		if hat_override.length() > 24:
			hat_override = ""   # Schutz gegen unsinnige Werte aus dem Netz
		_hat_shown = hat_override
		PlayerLook.update_hat(look, hat_override if hat_override != "" else role)
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


## Name aus der Spielerliste; offline bzw. unbekannt: Spielername aus den Einstellungen.
func display_name() -> String:
	var info: Dictionary = NetworkManager.players.get(str(name).to_int(), {})
	var n := str(info.get("name", ""))
	return n if n != "" else str(Settings.get_value("player_name"))


## Namensschild (A-02): immer sichtbar über dem Kopf, in der Farbe des Platzes, mit dunklem Rand für Lesbarkeit.
func _refresh_nameplate(idx: int) -> void:
	if nameplate == null:
		nameplate = Label3D.new()
		nameplate.name = "Nameplate"
		nameplate.position = Vector3(0, 2.5, 0)
		nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nameplate.no_depth_test = true
		nameplate.fixed_size = false
		nameplate.pixel_size = 0.008
		nameplate.font_size = 48
		nameplate.outline_size = 14
		nameplate.outline_modulate = Color(0.04, 0.05, 0.12)
		add_child(nameplate)
	nameplate.text = display_name()
	nameplate.modulate = Palette.player_color(idx).lightened(0.35)
	# Eigene Figur: Schild verbergen (sonst steht es im Bild der eigenen Kamera)
	nameplate.visible = not (is_multiplayer_authority() and NetworkManager.is_online())


func _refresh_look() -> void:
	var idx := slot_index()
	_refresh_nameplate(idx)
	if idx == look_index and look != null:
		return
	look_index = idx
	if look != null:
		look.queue_free()
	look = PlayerLook.build(idx)
	look.name = "Look"
	add_child(look)
	PlayerLook.update_hat(look, role)


# ---------------------------------------------------------------- Gesundheit (I-12)

func _track_floor() -> void:
	_on_balloon = null
	if not is_on_floor():
		return
	for i in get_slide_collision_count():
		var c := get_slide_collision(i).get_collider()
		if c is Balloon:
			_on_balloon = c
			return


## Fallschaden: höchster Punkt in der Luft minus Landehöhe, erst ab SAFE_FALL Metern.
func _track_fall(_delta: float) -> void:
	if is_on_floor():
		if _airborne:
			_airborne = false
			var drop := _peak_y - global_position.y
			if drop > SAFE_FALL:
				damage((drop - SAFE_FALL) * FALL_DAMAGE * mod("fall_damage"))
	else:
		if not _airborne:
			_airborne = true
			_peak_y = global_position.y
		_peak_y = maxf(_peak_y, global_position.y)


func _tick_health(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_since_damage += delta
	if health < MAX_HEALTH and _since_damage >= REGEN_DELAY:
		health = minf(health + REGEN_RATE * delta * food.regen_factor() * mod("regen"), MAX_HEALTH)
		health_changed.emit(health)


## Schaden (nur beim Besitzer-Peer wirksam). Bei 0: kurz benommen, zurück zur Startlaterne mit voller Gesundheit.
func damage(amount: float) -> void:
	if amount <= 0.0 or _invuln > 0.0 or downed or not is_multiplayer_authority():
		return
	health = maxf(health - amount, 0.0)
	_since_damage = 0.0
	health_changed.emit(health)
	if health <= 0.0:
		_go_down()


## G-20: Umfallen. 10 % des Sternenstaubs gehen verloren, dann läuft der Respawn-Zähler.
func _go_down() -> void:
	downed = true
	cleaning = false
	respawn_left = RESPAWN_TIME
	revive_target = null
	revive_progress = 0.0
	_revive_held = 0.0
	velocity = Vector3.ZERO
	_impulse = Vector3.ZERO
	_airborne = false
	last_dust_lost = GameState.lose_dust_fraction(DEATH_DUST_LOSS)
	died.emit()


## Am Boden: Zähler läuft, bei 0 Rückkehr zur Startlaterne mit voller Gesundheit.
func _physics_downed(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()
	tick_downed(delta)
	_follow_spectated()


func tick_downed(delta: float) -> void:
	if not downed:
		return
	respawn_left = maxf(respawn_left - delta, 0.0)
	if respawn_left <= 0.0:
		get_up(false)


## Aufstehen. Mitspieler-Hilfe: sofort, an Ort und Stelle, halbe Gesundheit. Zeitablauf: volle Gesundheit an der Startlaterne.
func get_up(by_teammate: bool) -> void:
	if not downed:
		return
	downed = false
	respawn_left = 0.0
	_invuln = RESPAWN_INVULN
	_since_damage = 0.0
	if by_teammate:
		health = MAX_HEALTH * REVIVE_HEALTH
	else:
		health = MAX_HEALTH
		global_position = SPAWN_POINT
	velocity = Vector3.ZERO
	_airborne = false
	if arm != null:
		arm.top_level = false
		arm.position = Vector3(0, 1.5, 0)
		arm.rotation = Vector3(pitch, 0, 0)
	health_changed.emit(health)
	revived.emit(by_teammate)


## Mitspieler halten F neben einem Gefallenen. Sammelt Haltezeit; nach REVIVE_TIME wird er sofort wiederbelebt.
## `held` = F gerade gedrückt. Gibt true zurück, wenn in diesem Schritt jemand aufgeholfen wurde.
func update_revive(delta: float, held: bool) -> bool:
	var target: Player = null
	if held:
		var best := REVIVE_RANGE
		for n in get_tree().get_nodes_in_group("players"):
			var o := n as Player
			if o == null or o == self or not o.downed:
				continue
			var d := o.global_position.distance_to(global_position)
			if d < best:
				best = d
				target = o
	if target == null or target != revive_target:
		_revive_held = 0.0
	revive_target = target
	if target == null:
		revive_progress = 0.0
		return false
	_revive_held += delta
	revive_progress = clampf(_revive_held / REVIVE_TIME, 0.0, 1.0)
	if _revive_held >= REVIVE_TIME:
		_revive_held = 0.0
		revive_progress = 0.0
		revive_target = null
		xp.add_event("revive")   # M-11: XP fürs Wiederbeleben
		helped_up.emit(target)
		if target.is_multiplayer_authority():
			target.get_up(true)
		else:
			target.rpc_revive.rpc_id(target.get_multiplayer_authority())
		return true
	return false


@rpc("any_peer", "call_remote", "reliable")
func rpc_revive() -> void:
	if is_multiplayer_authority():
		get_up(true)


## Zuschauer-Kamera: Der Gefallene schaut einem noch stehenden Mitspieler über die Schulter (wenn es einen gibt).
func _follow_spectated() -> void:
	if arm == null or cam == null or not cam.current:
		return
	var tgt: Player = null
	for n in get_tree().get_nodes_in_group("players"):
		var o := n as Player
		if o != null and o != self and not o.downed:
			tgt = o
			break
	if tgt == null:
		arm.top_level = false
		arm.position = Vector3(0, 1.5, 0)
		return
	arm.top_level = true
	arm.global_position = tgt.global_position + Vector3(0, 1.5, 0)
	arm.global_rotation = Vector3(-0.25, tgt.rotation.y, 0)


## Schlag auf den nächsten anderen Spieler vor dir (Reichweite ATTACK_RANGE, Abklingzeit ATTACK_COOLDOWN).
func try_attack() -> bool:
	if _attack_cd > 0.0:
		return false
	_attack_cd = ATTACK_COOLDOWN
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var best: Player = null
	var best_d := ATTACK_RANGE
	for n in get_tree().get_nodes_in_group("players"):
		var o := n as Player
		if o == null or o == self:
			continue
		var d := o.global_position - global_position
		d.y = 0.0
		if d.length() < best_d and (d.length() < 0.8 or d.normalized().dot(fwd) > 0.3):
			best = o
			best_d = d.length()
	if best == null:
		return false
	var push := fwd * 7.0 + Vector3(0, 3.0, 0)
	if best.is_multiplayer_authority():
		best.take_hit(HIT_DAMAGE, push)   # lokal (Solo/Test)
	else:
		best.take_hit.rpc_id(best.get_multiplayer_authority(), HIT_DAMAGE, push)
	hit_landed.emit(best)
	return true


@rpc("any_peer", "call_local", "reliable")
func take_hit(amount: float, push: Vector3) -> void:
	if not is_multiplayer_authority():
		return
	knock(push)
	if room_brawl():   # G-32: friedlich = nur wegstoßen
		damage(amount)


## Rauflust des Raums: Wert des Host-Spielers (Knoten "1"), ohne Host (Solo/Test) der eigene.
func room_brawl() -> bool:
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("players"):
			var o := n as Player
			if o != null and str(o.name) == "1":
				return o.brawl
	return brawl


## Rückstoß: horizontaler Anteil klingt über ~0,3 s ab, vertikaler Anteil wirkt sofort als Sprung.
func knock(v: Vector3) -> void:
	_impulse = Vector3(v.x, 0, v.z)
	if v.y > 0.0:
		velocity.y = maxf(velocity.y, v.y)


## M-01: Gesamtfaktor eines Stats aus Fähigkeiten, Küchen-Buff und Schrein (1.0 = keine Wirkung).
func mod(stat_name: String) -> float:
	var m := 1.0
	if skills != null:
		skills.role = role
		m *= skills.mult(stat_name)
	if kitchen != null and is_instance_valid(kitchen):
		m *= kitchen.buff_mult(stat_name)
	m *= Poi.buff_mult(stat_name)
	return m


## Wischradius-Faktor der Rolle (main.gd multipliziert damit den Shop-Radius).
func wipe_factor() -> float:
	return Roles.factor(role, "wipe") * food.clean_factor() * mod("wipe")


## G-25: Ausgerüstetes Utensil aus der Werkstatt (leer = Wedel ohne Shop).
func utensil() -> Dictionary:
	stat("speed", SPEED)   # sucht den Shop, falls noch nicht gefunden
	if _shop != null and is_instance_valid(_shop) and _shop.has_method("equipped_utensil"):
		return _shop.equipped_utensil()
	return {}


## Werkzeugart (CleanTool.Kind) des Utensils in der Hand. main.gd reicht sie an World.wipe_at weiter.
func tool_kind() -> int:
	return CleanTool.kind_from_name(str(utensil().get("tool_kind", "ANY")))


## Wischtempo-Faktor (Utensil-Upgrades "Tempo"), 1.0 = Grundwert.
func wipe_rate() -> float:
	return stat("wipe_rate", 1.0) * mod("wipe_rate")


## Modell in der Hand an das Utensil anpassen (nur wenn es sich geändert hat).
func _refresh_tool() -> void:
	var ut := utensil()
	var id := str(ut.get("id", "wedel"))
	if id == _shown_tool or brush == null:
		return
	_shown_tool = id
	for c in brush.get_children():
		c.queue_free()
	var m := ToolModels.build(str(ut.get("model", "duster")))
	m.scale = Vector3.ONE * float(ut.get("scale", 1.0))
	brush.add_child(m)


## G-33: Ping an einen Weltpunkt, sichtbar auf der Minimap aller Spieler (Abklingzeit PING_COOLDOWN). false = zu früh oder ungültig.
func send_ping(point: Vector3) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now < _ping_cd or not point.is_finite():
		return false
	_ping_cd = now + PING_COOLDOWN
	rpc_ping.rpc(point)
	return true


@rpc("any_peer", "call_local", "reliable")
func rpc_ping(point: Vector3) -> void:
	if not point.is_finite() or point.length() > 200.0:
		return
	var sender := multiplayer.get_remote_sender_id()
	ping_received.emit(sender if sender != 0 else str(name).to_int(), point)


# ---------------------------------------------------------------- Kletterer (G-24)

const CLIMB_SPEED := 3.5
const LADDER_COOLDOWN := 20.0
var _ladder_cd := 0.0


## Leiter hoch (alle Rollen, vorwärts laufen) und Wände hoch (nur Kletterer). Wird vor move_and_slide aufgerufen.
func _apply_climb(input: Vector2) -> void:
	if input.y >= -0.1:
		return
	if Ladder.find_for(get_tree(), global_position) != null:
		velocity.y = Ladder.CLIMB_SPEED
		_airborne = false
		_peak_y = global_position.y   # an der Leiter kein Fallschaden
		return
	if Roles.can(role, "climb") and is_on_wall():
		velocity.y = maxf(velocity.y, CLIMB_SPEED * Roles.factor(role, "climb") * mod("climb"))   # M-11: Fähigkeit "Fester Griff"
		_peak_y = global_position.y


## Kletterer: Leiter vor sich aufstellen (8 s, Abklingzeit 20 s). false = keine Rolle/zu früh.
func place_ladder() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if not Roles.can(role, "ladder") or now < _ladder_cd or downed:
		return false
	_ladder_cd = now + LADDER_COOLDOWN * mod("ladder_cd")
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	var pos := global_position + fwd.normalized() * 1.2
	rpc_place_ladder.rpc(pos, rotation.y, ladder_lifetime())
	return true


## M-11: Standzeit der Leiter mit Fähigkeit "Lange Leiter" (+2 s je Stufe).
func ladder_lifetime() -> float:
	return Ladder.LIFETIME + (skills.add("ladder_time") if skills != null else 0.0)


@rpc("any_peer", "call_local", "reliable")
func rpc_place_ladder(pos: Vector3, yaw: float, life: float = Ladder.LIFETIME) -> void:
	if not pos.is_finite() or pos.length() > 200.0:
		return
	var l := Ladder.new()
	l.left = clampf(life, 1.0, 60.0)
	l.position = pos
	l.rotation.y = yaw
	var scene := get_tree().current_scene
	(scene if scene != null else get_tree().root).add_child(l)
