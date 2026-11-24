class_name Hazard
extends Area3D
## Umgebungsgefahr (I-12): Lava (Schaden pro Sekunde, solange man darin steht) und Kaktus (Stich mit Rückstoß, mit Abklingzeit).
## Nur der Peer, dem der Spieler gehört, wendet den Schaden an (jeder Spieler verwaltet seine eigene Gesundheit).

const LAVA_DPS := 28.0
const CACTUS_DAMAGE := 14.0
const CACTUS_COOLDOWN := 1.0

@export var kind := "lava"      # "lava" | "cactus" | "spider" (Spinnennest: schreckt Spieler mit Spinnenangst zurück)
@export var radius := 3.0
var _cool := {}                 # Spieler-Instanz-ID -> Restzeit der Abklingzeit


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var cs := CollisionShape3D.new()
	if kind == "spider":
		var sp := CylinderShape3D.new()
		sp.radius = radius
		sp.height = 2.0
		cs.shape = sp
		cs.position.y = 1.0
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.12, 0.1, 0.14)
		var body_m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.45
		sm.height = 0.8
		body_m.mesh = sm
		body_m.material_override = dark
		body_m.position.y = 0.7
		add_child(body_m)
		for i in 8:   # acht Beine
			var leg := MeshInstance3D.new()
			var lm := CapsuleMesh.new()
			lm.radius = 0.04
			lm.height = 1.3
			leg.mesh = lm
			leg.material_override = dark
			var ang := TAU * i / 8.0
			leg.position = Vector3(cos(ang) * 0.7, 0.45, sin(ang) * 0.7)
			leg.rotation = Vector3(sin(ang) * 0.9, 0, -cos(ang) * 0.9)
			add_child(leg)
		var web := MeshInstance3D.new()   # Netz als flacher heller Ring am Boden
		var wm := CylinderMesh.new()
		wm.top_radius = radius
		wm.bottom_radius = radius
		wm.height = 0.02
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.85, 0.85, 0.9, 0.35)
		wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		web.mesh = wm
		web.material_override = wmat
		web.position.y = 0.02
		add_child(web)
	elif kind == "lava":
		var sh := CylinderShape3D.new()
		sh.radius = radius
		sh.height = 1.0
		cs.shape = sh
		cs.position.y = 0.4
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = radius
		cm.bottom_radius = radius
		cm.height = 0.06
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.25, 0.05)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.4, 0.1)
		mat.emission_energy_multiplier = 1.6
		mi.mesh = cm
		mi.material_override = mat
		mi.position.y = 0.03
		add_child(mi)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.45, 0.15)
		light.omni_range = radius * 2.5
		light.position.y = 1.0
		add_child(light)
	else:
		var sh2 := CylinderShape3D.new()
		sh2.radius = 0.95   # etwas größer als der Stamm: Stich bei Berührung
		sh2.height = 2.2
		cs.shape = sh2
		cs.position.y = 1.1
		var green := StandardMaterial3D.new()
		green.albedo_color = Color(0.25, 0.6, 0.3)
		var trunk := MeshInstance3D.new()
		var tm := CapsuleMesh.new()
		tm.radius = 0.35
		tm.height = 2.2
		trunk.mesh = tm
		trunk.material_override = green
		trunk.position.y = 1.1
		add_child(trunk)
		for sx in [-1.0, 1.0]:
			var arm := MeshInstance3D.new()
			var am := CapsuleMesh.new()
			am.radius = 0.2
			am.height = 1.0
			arm.mesh = am
			arm.material_override = green
			arm.position = Vector3(sx * 0.55, 1.3 + (0.2 if sx > 0 else 0.0), 0)
			add_child(arm)
		# Sichtbare feste Wand, damit man den Kaktus nicht durchläuft
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var bs := CollisionShape3D.new()
		var bsh := CylinderShape3D.new()
		bsh.radius = 0.45
		bsh.height = 2.2
		bs.shape = bsh
		bs.position.y = 1.1
		body.add_child(bs)
		add_child(body)
	add_child(cs)


func _physics_process(delta: float) -> void:
	for k in _cool.keys():
		_cool[k] = float(_cool[k]) - delta
		if _cool[k] <= 0.0:
			_cool.erase(k)
	for b in get_overlapping_bodies():
		if b is Player:
			apply_to(b, delta)


## Wendet den Schaden dieser Gefahr auf einen Spieler an (nur beim Besitzer-Peer wirksam). Getrennt, damit Tests ohne Physik laufen.
func apply_to(p: Player, delta: float) -> void:
	if not p.is_multiplayer_authority():
		return
	if kind == "spider":
		if Roles.fears_spiders(p.role):
			var back := p.global_position - global_position
			back.y = 0.0
			p.knock(back.normalized() * 10.0)   # Angst: weicht aus, kann nicht hinein
		return
	if kind == "lava":
		p.damage(LAVA_DPS * delta)
		p.velocity.y = maxf(p.velocity.y, 3.0)   # Lava stößt leicht nach oben
	else:
		var id := p.get_instance_id()
		if _cool.has(id):
			return
		_cool[id] = CACTUS_COOLDOWN
		var away := p.global_position - global_position
		away.y = 0.0
		p.damage(CACTUS_DAMAGE)
		p.knock(away.normalized() * 9.0 + Vector3(0, 3.0, 0))
