class_name MenuBackdrop
extends Node3D
## Hauptmenü-Hintergrund (A-16): Insel vor Nachthimmel mit Werkstatt, Laternen, Ballon und drei Sternen (schmutzig, halb, golden),
## die Kamera schwebt langsam um die Insel. `reduced_motion` hält die Kamera still. Nutzung: `add_child(MenuBackdrop.new())`.
## Das Menü selbst (Buttons, Logo `assets/ui/logo.svg`) liegt als Control darüber (U-01).

@export var reduced_motion := false
@export var orbit_speed := 0.05   # rad/s
var cam: Camera3D
var _angle := -0.6


func _ready() -> void:
	add_child(NightSky.new())
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 14.0
	cm.bottom_radius = 9.0
	cm.height = 2.0
	cm.radial_segments = 48
	body.mesh = cm
	body.material_override = IslandProps.ground_material(5.0)
	body.position.y = -1.0
	body.name = "Island"
	add_child(body)
	add_child(IslandProps.decorate(13.0, 42))
	var w := Props.workshop()
	w.position = Vector3(-6, 0, -4)
	w.rotation.y = 0.5
	add_child(w)
	var sg := IslandProps.sign_post()
	sg.position = Vector3(-2.5, 0, 0.5)
	sg.rotation.y = 0.2
	add_child(sg)
	for p in [Vector3(-3.5, 0, -1.2), Vector3(4, 0, 3)]:
		var l := IslandProps.lantern()
		l.position = p
		add_child(l)
	var b := Props.balloon()
	b.position = Vector3(6, 0.2, -1)
	b.scale = Vector3.ONE * 0.8
	add_child(b)
	var clean_levels := [0.0, 0.55, 1.0]
	for i in 3:
		var s := StarLook.build(1.3)
		s.position = Vector3(-9.0 + i * 9.0, 8.0 + i * 0.6, -10.0 + i)
		s.name = "MenuStar%d" % i
		add_child(s)
		StarLook.set_clean(s, clean_levels[i])
	var fx := SkyFx.new()
	fx.reduced_motion = reduced_motion
	add_child(fx)
	cam = Camera3D.new()
	cam.fov = 55.0
	add_child(cam)
	cam.current = true
	_place_camera()


func _place_camera() -> void:
	var r := 24.0
	cam.position = Vector3(sin(_angle) * r, 9.5, cos(_angle) * r)
	cam.look_at(Vector3(0, 3.5, 0), Vector3.UP)


func _process(delta: float) -> void:
	advance(delta)


## Kamera ein Stück weiterdrehen (leichtes Hin- und Herschwingen, nie ganz um die Insel).
func advance(delta: float) -> void:
	if reduced_motion or cam == null:
		return
	_angle += orbit_speed * delta
	if _angle > 0.7:
		_angle = -0.7
	_place_camera()


## Selbsttest (Koroutine: `await MenuBackdrop.selftest(root)`): Szene baut, Kamera aktiv, bewegt sich, reduced_motion hält still.
static func selftest(root: Node) -> bool:
	var m := MenuBackdrop.new()
	root.add_child(m)
	await (Engine.get_main_loop() as SceneTree).process_frame
	var ok := m.cam != null and m.cam.current and m.get_node_or_null("Island") != null and m.get_node_or_null("MenuStar2") != null
	var p0 := m.cam.position
	m.advance(2.0)
	ok = ok and m.cam.position.distance_to(p0) > 0.5
	m.reduced_motion = true
	var p1 := m.cam.position
	m.advance(2.0)
	ok = ok and m.cam.position.is_equal_approx(p1)
	m.free()
	print("SELFTEST MenuBackdrop -> %s" % ("OK" if ok else "FAIL"))
	return ok
