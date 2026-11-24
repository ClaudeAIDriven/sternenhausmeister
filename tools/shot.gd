extends SceneTree
## Screenshot-Helfer (nur mit echtem Renderer, z. B. xvfb + llvmpipe): lädt das Spiel, wartet, speichert user://shot.png und /tmp/shot.png.
var frames := 0
var main
func _process(_d: float) -> bool:
	frames += 1
	if frames == 2:
		var menu = load("res://menu.gd")
		menu.launch = {"mode": "solo", "name": "Foto", "preset": "standard", "map": OS.get_environment("SHOT_MAP") if OS.get_environment("SHOT_MAP") != "" else "mondwiese"}
		main = load("res://main.gd").new()
		root.add_child(main)
	if frames == 40 and OS.get_environment("SHOT_CAM") != "":
		var cam := Camera3D.new()
		root.add_child(cam)
		var what := OS.get_environment("SHOT_CAM")   # star | spider | bunny | cloud | player
		var target: Node3D = main.world.stars[0]
		if what in ["spider", "bunny", "cloud"]:
			for e in main.world.enemies:
				if (what == "spider" and e.kind == "spinne") or (what == "bunny" and e.kind == "wollmaus") or (what == "cloud" and e.kind == "russwolke"):
					target = e
					break
		if what == "player":
			target = main.player
		var d := 7.0 if what in ["star", "cloud"] else 3.0
		cam.global_position = target.global_position + Vector3(0, 1.5, d)
		cam.look_at(target.global_position, Vector3.UP)
		cam.current = true
	if frames == 90:
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("/tmp/shot.png")
		print("SHOT ", img.get_size())
		quit(0)
		return true
	return false
