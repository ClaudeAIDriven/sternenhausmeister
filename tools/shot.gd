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
	if frames == 90:
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("/tmp/shot.png")
		print("SHOT ", img.get_size())
		quit(0)
		return true
	return false
