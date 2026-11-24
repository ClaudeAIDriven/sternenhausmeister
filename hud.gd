class_name Hud
extends CanvasLayer
## Einfache Anzeige: Fortschritt, Steuerungshinweis, Fadenkreuz. (Wird später durch U-02 ersetzt.)

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(20, 16)
	_label.add_theme_font_size_override("font_size", 22)
	add_child(_label)
	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 28)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-8, -18)
	add_child(cross)


func show_status(cleaned: int, total: int, extra: String = "") -> void:
	var lines := "Sterne geputzt: %d / %d\n" % [cleaned, total]
	lines += "WASD laufen · Leertaste springen · Maus zielen\n"
	lines += "Linke Maustaste / E: putzen · Klick: Maus einfangen · Esc: loslassen"
	if extra != "":
		lines += "\n\n" + extra
	_label.text = lines
