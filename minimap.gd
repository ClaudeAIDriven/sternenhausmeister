class_name Minimap
extends CanvasLayer
## I-14: Minimap oben rechts (Norden = oben). Zeigt Insel, Werkstatt, Ballon, Sterne (gold = schmutzig, grün = sauber),
## Gefahren (Lava rot, Kaktus grün, Spinnen violett), Spieler (Farbe des Platzes, eigener mit Blickrichtung),
## darunter Fortschrittsbalken (geputzte Sterne) und verbleibende Zeit.

const SIZE := 190.0
const PING_SECONDS := 8.0   # G-33

var pings: Array = []   # {"pos": Vector3, "left": float, "slot": int, "owner": String}
var _overlay: Control   # Randpfeile über dem ganzen Bildschirm

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
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_ping_arrows)
	add_child(_overlay)


func bind(w: World, n: Night, root: Node3D) -> void:
	world = w
	night = n
	players_root = root


## Weltposition (x/z) -> Punkt in der Karte.
static func to_map(pos: Vector3, size := SIZE) -> Vector2:
	var k := size * 0.5 / (World.ISLAND_RADIUS + 2.0)
	return Vector2(size * 0.5 + pos.x * k, size * 0.5 + pos.z * k)


func _process(delta: float) -> void:
	_connect_players()
	tick_pings(delta)
	_overlay.queue_redraw()
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
	for poi in get_tree().get_nodes_in_group("pois"):   # G-30: Orte mit Symbol
		_draw_poi(c, poi as Poi)
	if Poi.tower_active:   # Aussichtsturm: Gegner sichtbar
		for e in get_tree().get_nodes_in_group("enemies"):
			c.draw_circle(to_map((e as Node3D).global_position), 3.0, Color(0.9, 0.2, 0.7))
	var ws := to_map(World.WORKSHOP_POS)   # Werkstatt: Haus-Symbol
	c.draw_rect(Rect2(ws - Vector2(5, 4), Vector2(10, 8)), Palette.UI_IVORY)
	c.draw_colored_polygon(PackedVector2Array([ws + Vector2(-7, -4), ws + Vector2(7, -4), ws + Vector2(0, -11)]), Color(0.8, 0.3, 0.35))
	if world.balloon != null:
		c.draw_circle(to_map(world.balloon.position), 5.0, Color(0.9, 0.35, 0.4))
	for s in world.stars:
		var sp := to_map(s.position)
		c.draw_circle(sp, 4.0, Color(0.4, 0.9, 0.5) if s.is_clean else Palette.STAR_GOLD)
	for pg in pings:   # G-33: pulsierender Ring in der Farbe des Absenders
		var pm2 := to_map(pg["pos"])
		var pulse := fmod(Time.get_ticks_msec() / 1000.0, 1.0)
		var pc := Palette.player_color(int(pg["slot"]))
		c.draw_arc(pm2, 4.0 + pulse * 8.0, 0.0, TAU, 20, Color(pc.r, pc.g, pc.b, 1.0 - pulse), 2.0)
		c.draw_circle(pm2, 3.0, pc)
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


# ---------------------------------------------------------------- Pings (G-33)

## Hört auf alle Spieler (auch später beigetretene): jeder Ping kommt per RPC bei jedem Spieler-Knoten an.
func _connect_players() -> void:
	if players_root == null:
		return
	for n in players_root.get_children():
		var p := n as Player
		if p != null and not p.has_meta("ping_hooked"):
			p.set_meta("ping_hooked", true)
			p.ping_received.connect(func(_sender: int, pt: Vector3): add_ping(pt, p))


## Ping setzen. Pro Spieler gibt es nur einen aktiven Ping (der neue ersetzt den alten).
func add_ping(pos: Vector3, from: Player = null) -> void:
	var owner_name := str(from.name) if from != null else ""
	for i in range(pings.size() - 1, -1, -1):
		if pings[i]["owner"] == owner_name and owner_name != "":
			pings.remove_at(i)
	pings.append({"pos": pos, "left": PING_SECONDS, "slot": from.slot_index() if from != null else 0, "owner": owner_name})


func tick_pings(delta: float) -> void:
	for i in range(pings.size() - 1, -1, -1):
		pings[i]["left"] = float(pings[i]["left"]) - delta
		if float(pings[i]["left"]) <= 0.0:
			pings.remove_at(i)


## Punkt am Bildschirmrand in Richtung `screen_pos` (vom Mittelpunkt aus), mit Abstand `margin`.
static func edge_point(screen_pos: Vector2, size: Vector2, margin: float = 36.0) -> Vector2:
	var center := size * 0.5
	var d := screen_pos - center
	if d.length() < 0.001:
		return center
	var half := center - Vector2(margin, margin)
	var s := minf(half.x / maxf(absf(d.x), 0.001), half.y / maxf(absf(d.y), 0.001))
	return center + d * s


## Randpfeil nötig? Ja, wenn der Punkt hinter der Kamera oder außerhalb des Bildschirms liegt.
func _draw_ping_arrows() -> void:
	if pings.is_empty() or local_player == null or not is_instance_valid(local_player) or local_player.cam == null:
		return
	var cam := local_player.cam
	var size := get_viewport().get_visible_rect().size
	for pg in pings:
		var wp: Vector3 = pg["pos"] + Vector3(0, 1.0, 0)
		var col := Palette.player_color(int(pg["slot"]))
		var behind := cam.is_position_behind(wp)
		var sp := cam.unproject_position(wp)
		var inside := not behind and Rect2(Vector2.ZERO, size).grow(-24.0).has_point(sp)
		if inside:
			_overlay.draw_arc(sp, 14.0, 0.0, TAU, 24, col, 3.0)
			_overlay.draw_circle(sp, 4.0, col)
			continue
		if behind:
			sp = size * 0.5 + (size * 0.5 - sp)   # hinter dem Rücken: Richtung spiegeln
		var ep := edge_point(sp, size)
		var dir := (ep - size * 0.5).normalized()
		var perp := Vector2(-dir.y, dir.x)
		_overlay.draw_colored_polygon(PackedVector2Array([ep + dir * 16.0, ep - dir * 8.0 + perp * 10.0, ep - dir * 8.0 - perp * 10.0]), col)


func _draw_poi(c: Control, poi: Poi) -> void:
	if poi == null:
		return
	var p := to_map(poi.global_position)
	var col := poi.map_color()
	match poi.map_shape():
		"square":
			c.draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), col)
		"triangle":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 4), p + Vector2(-5, 4)]), col)
		"diamond":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 0), p + Vector2(0, 6), p + Vector2(-5, 0)]), col)
		_:
			c.draw_circle(p, 4.5, col)
