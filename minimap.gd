class_name Minimap
extends CanvasLayer
## I-14: Minimap oben rechts (Norden = oben). Zeigt Insel, Werkstatt, Ballon, Sterne (gold = schmutzig, grün = sauber),
## Gefahren (Lava rot, Kaktus grün, Spinnen violett), Spieler (Farbe des Platzes, eigener mit Blickrichtung),
## darunter Fortschrittsbalken (geputzte Sterne) und verbleibende Zeit.

const SIZE := 190.0

var world: World
var night: Night
var players_root: Node3D
var local_player: Player
var _canvas: Control
var _bar: ProgressBar
var _time_label: Label


func _ready() -> void:
	layer = 15
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_canvas.offset_left = -SIZE - 16
	_canvas.offset_right = -16
	_canvas.offset_top = 16
	_canvas.offset_bottom = 16 + SIZE
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_map)
	add_child(_canvas)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_bar.offset_left = -SIZE - 16
	_bar.offset_right = -16
	_bar.offset_top = SIZE + 24
	_bar.offset_bottom = SIZE + 40
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)
	_time_label = Label.new()
	_time_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_time_label.offset_left = -SIZE - 16
	_time_label.offset_right = -16
	_time_label.offset_top = SIZE + 44
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_color_override("font_color", Palette.UI_IVORY)
	_time_label.add_theme_color_override("font_outline_color", Palette.UI_PANEL)
	_time_label.add_theme_constant_override("outline_size", 6)
	add_child(_time_label)


func bind(w: World, n: Night, root: Node3D) -> void:
	world = w
	night = n
	players_root = root


## Weltposition (x/z) -> Punkt in der Karte.
static func to_map(pos: Vector3, size := SIZE) -> Vector2:
	var k := size * 0.5 / (World.ISLAND_RADIUS + 2.0)
	return Vector2(size * 0.5 + pos.x * k, size * 0.5 + pos.z * k)


func _process(_d: float) -> void:
	if world == null:
		return
	var total := world.stars.size()
	_bar.max_value = maxf(total, 1)
	_bar.value = world.cleaned_count()
	if night != null:
		var t := int(ceil(night.time_left()))
		_time_label.text = "Sterne %d/%d   Zeit %d:%02d" % [world.cleaned_count(), total, t / 60, t % 60]
	_canvas.queue_redraw()


func _draw_map() -> void:
	if world == null:
		return
	var c := _canvas
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)), Color(0.04, 0.05, 0.12, 0.55))
	var k := SIZE * 0.5 / (World.ISLAND_RADIUS + 2.0)
	c.draw_circle(Vector2(SIZE, SIZE) * 0.5, World.ISLAND_RADIUS * k, Color(0.55, 0.6, 0.8, 0.55))
	for h in get_tree().get_nodes_in_group("hazards"):
		var col := Color(1.0, 0.35, 0.1)
		var r := 2.0
		match (h as Hazard).kind:
			"cactus":
				col = Color(0.3, 0.8, 0.4)
			"spider":
				col = Color(0.7, 0.4, 0.9)
				r = 3.0
			_:
				r = 3.5
		c.draw_circle(to_map(h.position), r, col)
	var ws := to_map(World.WORKSHOP_POS)   # Werkstatt: Haus-Symbol
	c.draw_rect(Rect2(ws - Vector2(5, 4), Vector2(10, 8)), Palette.UI_IVORY)
	c.draw_colored_polygon(PackedVector2Array([ws + Vector2(-7, -4), ws + Vector2(7, -4), ws + Vector2(0, -11)]), Color(0.8, 0.3, 0.35))
	if world.balloon != null:
		c.draw_circle(to_map(world.balloon.position), 5.0, Color(0.9, 0.35, 0.4))
	for s in world.stars:
		var sp := to_map(s.position)
		c.draw_circle(sp, 4.0, Color(0.4, 0.9, 0.5) if s.is_clean else Palette.STAR_GOLD)
	if players_root != null:
		for n in players_root.get_children():
			var p := n as Player
			if p == null:
				continue
			var pm := to_map(p.global_position)
			var col2 := Palette.player_color(p.slot_index())
			c.draw_circle(pm, 5.0, col2)
			if p == local_player:
				c.draw_arc(pm, 6.5, 0.0, TAU, 20, Color.WHITE, 1.5)
				var f := Vector2(-sin(p.rotation.y), -cos(p.rotation.y))
				c.draw_line(pm, pm + f * 12.0, Color.WHITE, 2.0)
