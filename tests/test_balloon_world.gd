extends SceneTree
## Test I-06: Ballon steht in der Welt, steigt mit einem Spieler an Bord (Physik), sinkt ohne.
var frames := 0
var w
var p
var start_y := 0.0

func _initialize() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "jump", "clean"]:
		InputMap.add_action(a)

func _physics_process(_d: float) -> bool:
	frames += 1
	if frames == 2:
		w = load("res://world.gd").new()
		root.add_child(w)
		var floor_body := StaticBody3D.new()
		root.add_child(floor_body)
		start_y = w.balloon.position.y
		p = load("res://player.gd").new()
		p.name = "1"
		root.add_child(p)
		p.global_position = w.balloon.global_position + Vector3(0, 0.9, 0)
	if frames == 140:   # ~2,3 s
		var ok: bool = w.balloon != null and w.balloon.riders >= 1 and w.balloon.position.y > start_y + 3.0
		ok = ok and p.global_position.y > w.balloon.position.y   # Spieler fährt oben auf der Plattform mit
		print("TEST_BALLOON_WORLD OK" if ok else "TEST_BALLOON_WORLD FAIL riders=%d y=%.2f spieler=%.2f" % [w.balloon.riders, w.balloon.position.y, p.global_position.y])
		quit(0 if ok else 1)
	return false
