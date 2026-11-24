class_name HealthUI
extends CanvasLayer
## I-12: Lebensleiste unten Mitte. Rot blinkt kurz bei Schaden; Meldung nach dem Zusammenbruch.

var bar: ProgressBar
var msg: Label
var _flash: ColorRect
var _player: Player
var _msg_left := 0.0
var _last := Player.MAX_HEALTH


func _ready() -> void:
	layer = 20
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.9, 0.1, 0.1, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	bar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = Player.MAX_HEALTH
	bar.value = Player.MAX_HEALTH
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(260, 18)
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.offset_top = -40
	bar.offset_bottom = -20
	bar.offset_left = -130
	bar.offset_right = 130
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.2, 0.3)
	fill.set_corner_radius_all(6)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.06, 0.14, 0.75)
	back.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	msg = Label.new()
	msg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	msg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	msg.offset_top = -80
	msg.add_theme_color_override("font_color", Palette.UI_IVORY)
	msg.add_theme_color_override("font_outline_color", Palette.UI_PANEL)
	msg.add_theme_constant_override("outline_size", 6)
	add_child(msg)


func bind(p: Player) -> void:
	_player = p
	p.health_changed.connect(_on_health)
	p.died.connect(func():
		msg.text = "Benommen! Zurück bei der Laterne."
		_msg_left = 3.0)
	_on_health(p.health)


func _on_health(v: float) -> void:
	if bar == null:
		return
	if v < _last - 0.5:
		_flash.color.a = 0.35
	_last = v
	bar.value = v


func _process(delta: float) -> void:
	_flash.color.a = maxf(_flash.color.a - delta * 0.8, 0.0)
	if _msg_left > 0.0:
		_msg_left -= delta
		if _msg_left <= 0.0:
			msg.text = ""
	if _player != null and is_instance_valid(_player):
		bar.value = _player.health
