class_name UiIcons
extends RefCounted
## Prozedurale UI-Icons (A-15), gezeichnet aus Polygonen mit Supersampling (4x), weiche Kanten, transparenter Hintergrund.
## Nutzung: `UiIcons.texture("stardust", 64)` -> ImageTexture. Namen siehe `NAMES`. Symbole der Spieler: `UiIcons.symbol("circle", Palette.player_color(0), 64)`.

const NAMES: Array[String] = ["stardust", "star", "time", "dusk", "midnight", "dawn", "duster", "vacuum", "cloth", "polish"]
const SS := 4   # Supersampling-Faktor

const GOLD := Palette.STAR_GOLD
const IVORY := Palette.UI_IVORY


static func _fill(img: Image, pts: PackedVector2Array, c: Color, replace := false) -> void:
	# Scanline-Füllung (even-odd). Koordinaten in Pixeln des (übergroßen) Bildes.
	var h := img.get_height()
	var w := img.get_width()
	var n := pts.size()
	var min_y := INF
	var max_y := -INF
	for p in pts:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	for y in range(maxi(0, int(floor(min_y))), mini(h, int(ceil(max_y)) + 1)):
		var yy := y + 0.5
		var xs: Array[float] = []
		for i in n:
			var a := pts[i]
			var b := pts[(i + 1) % n]
			if (a.y <= yy and b.y > yy) or (b.y <= yy and a.y > yy):
				xs.append(a.x + (yy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		for k in range(0, xs.size() - 1, 2):
			for x in range(maxi(0, int(round(xs[k]))), mini(w, int(round(xs[k + 1])))):
				if replace:
					img.set_pixel(x, y, c)
				else:
					img.set_pixel(x, y, _over(img.get_pixel(x, y), c))


static func _over(dst: Color, src: Color) -> Color:
	var a := src.a + dst.a * (1.0 - src.a)
	if a <= 0.0:
		return Color(0, 0, 0, 0)
	return Color((src.r * src.a + dst.r * dst.a * (1.0 - src.a)) / a, (src.g * src.a + dst.g * dst.a * (1.0 - src.a)) / a, (src.b * src.a + dst.b * dst.a * (1.0 - src.a)) / a, a)


static func _s(img: Image, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var size := float(img.get_width())
	for p in pts:
		out.append(Vector2(p[0], p[1]) * size)
	return out


static func _circle(img: Image, cx: float, cy: float, r: float, c: Color, replace := false, seg := 28) -> void:
	var pts := []
	for i in seg:
		var a := TAU * i / seg
		pts.append([cx + cos(a) * r, cy + sin(a) * r])
	_fill(img, _s(img, pts), c, replace)


static func _rect(img: Image, x: float, y: float, w: float, h: float, c: Color) -> void:
	_fill(img, _s(img, [[x, y], [x + w, y], [x + w, y + h], [x, y + h]]), c)


static func _poly(img: Image, pts: Array, c: Color) -> void:
	_fill(img, _s(img, pts), c)


static func _star_pts(cx: float, cy: float, ro: float, ri: float) -> Array:
	var pts := []
	for i in 10:
		var a := -PI / 2.0 + TAU * i / 10.0
		var r := ro if i % 2 == 0 else ri
		pts.append([cx + cos(a) * r, cy + sin(a) * r])
	return pts


static func image(name: String, size := 64) -> Image:
	var img := Image.create(size * SS, size * SS, false, Image.FORMAT_RGBA8)
	match name:
		"stardust":   # goldener Kristall mit drei Facetten und Schweif
			_poly(img, [[0.2, 0.74], [0.02, 0.98], [0.32, 0.84]], GOLD.darkened(0.15))
			_poly(img, [[0.5, 0.1], [0.78, 0.38], [0.62, 0.82], [0.38, 0.82], [0.22, 0.38]], GOLD.darkened(0.35))
			_poly(img, [[0.5, 0.1], [0.22, 0.38], [0.5, 0.5]], GOLD.lightened(0.45))
			_poly(img, [[0.5, 0.1], [0.78, 0.38], [0.5, 0.5]], GOLD)
			_poly(img, [[0.22, 0.38], [0.38, 0.82], [0.62, 0.82], [0.78, 0.38], [0.5, 0.5]], GOLD.darkened(0.12))
		"star":
			_poly(img, _star_pts(0.5, 0.54, 0.46, 0.2), GOLD.darkened(0.2))
			_poly(img, _star_pts(0.5, 0.54, 0.36, 0.15), GOLD)
		"time":   # Uhr mit Zeigern
			_circle(img, 0.5, 0.5, 0.44, IVORY)
			_circle(img, 0.5, 0.5, 0.35, Palette.UI_PANEL, true)
			_rect(img, 0.47, 0.2, 0.06, 0.33, IVORY)
			_rect(img, 0.47, 0.47, 0.25, 0.06, GOLD)
		"dusk":   # Sonne halb untergegangen + Horizont + kleiner Stern
			var sun := []
			for i in 15:
				var a := PI + PI * i / 14.0
				sun.append([0.5 + cos(a) * 0.3, 0.68 + sin(a) * 0.3])
			_poly(img, sun, Color(1.0, 0.62, 0.35))
			_rect(img, 0.08, 0.68, 0.84, 0.06, Palette.SKY_DUSK.lightened(0.5))
			_poly(img, _star_pts(0.78, 0.2, 0.1, 0.045), GOLD)
		"midnight":   # Mondsichel + Stern
			_circle(img, 0.46, 0.52, 0.36, IVORY)
			_circle(img, 0.6, 0.44, 0.31, Color(0, 0, 0, 0), true)
			_poly(img, _star_pts(0.78, 0.26, 0.11, 0.05), GOLD)
		"dawn":   # Aufgehende Sonne mit Strahlenfächer
			var sun2 := []
			for i in 15:
				var a2 := PI + PI * i / 14.0
				sun2.append([0.5 + cos(a2) * 0.22, 0.7 + sin(a2) * 0.22])
			_poly(img, sun2, Palette.SKY_DAWN.lightened(0.3))
			for i in 5:
				var a3 := PI + PI * (i + 0.5) / 5.0
				_poly(img, [[0.5 + cos(a3 - 0.1) * 0.3, 0.7 + sin(a3 - 0.1) * 0.3], [0.5 + cos(a3 + 0.1) * 0.3, 0.7 + sin(a3 + 0.1) * 0.3], [0.5 + cos(a3) * 0.46, 0.7 + sin(a3) * 0.46]], Palette.SKY_DAWN.lightened(0.45))
			_rect(img, 0.08, 0.7, 0.84, 0.06, Palette.SKY_DAWN.lightened(0.45))
		"duster":   # Stiel + Federbüschel
			_poly(img, [[0.46, 0.4], [0.54, 0.4], [0.58, 0.96], [0.42, 0.96]], Color(0.65, 0.42, 0.25))
			_circle(img, 0.5, 0.27, 0.21, Color(1.0, 0.72, 0.85))
			_poly(img, [[0.22, 0.2], [0.06, 0.1], [0.3, 0.34]], Color(1.0, 0.82, 0.9))
			_poly(img, [[0.78, 0.2], [0.94, 0.1], [0.7, 0.34]], Color(1.0, 0.82, 0.9))
		"vacuum":   # Kugel + breite Düse mit Leuchtring
			_circle(img, 0.5, 0.7, 0.26, Palette.player_color(3).lightened(0.35))
			_poly(img, [[0.08, 0.14], [0.92, 0.14], [0.62, 0.46], [0.38, 0.46]], Palette.player_color(3).lightened(0.1))
			_rect(img, 0.08, 0.1, 0.84, 0.07, GOLD)
		"cloth":   # hängendes Tuch mit Falten
			_rect(img, 0.1, 0.14, 0.8, 0.7, Color(0.72, 0.9, 0.85))
			for i in 3:
				_rect(img, 0.28 + i * 0.22, 0.14, 0.06, 0.7, Color(0.5, 0.74, 0.7))
			_rect(img, 0.44, 0.84, 0.12, 0.14, Color(0.65, 0.42, 0.25))
		"polish":   # Scheibe auf Griff mit goldenem Zentrum
			_rect(img, 0.44, 0.5, 0.12, 0.46, Color(0.65, 0.42, 0.25))
			_circle(img, 0.5, 0.34, 0.4, Color(0.82, 0.78, 0.9))
			_circle(img, 0.5, 0.34, 0.18, GOLD)
	return _finish(img, size)


static func _finish(img: Image, size: int) -> Image:
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return img


## Spielersymbol (Kreis, Quadrat, Dreieck, Raute) gefüllt in `color`.
static func symbol_image(kind: String, color: Color, size := 64) -> Image:
	var img := Image.create(size * SS, size * SS, false, Image.FORMAT_RGBA8)
	match kind:
		"circle": _circle(img, 0.5, 0.5, 0.4, color)
		"square": _rect(img, 0.12, 0.12, 0.76, 0.76, color)
		"triangle": _poly(img, [[0.5, 0.08], [0.94, 0.88], [0.06, 0.88]], color)
		_: _poly(img, [[0.5, 0.04], [0.96, 0.5], [0.5, 0.96], [0.04, 0.5]], color)
	return _finish(img, size)


static func texture(name: String, size := 64) -> ImageTexture:
	return ImageTexture.create_from_image(image(name, size))


static func symbol(kind: String, color: Color, size := 64) -> ImageTexture:
	return ImageTexture.create_from_image(symbol_image(kind, color, size))


## Selbsttest: alle Icons sind nicht leer, nicht komplett gefüllt (bei 32 und 128 px), und paarweise verschieden (Pixelabweichung).
static func selftest() -> bool:
	var ok := true
	var shapes := {}
	for nm in NAMES:
		for sz: int in [32, 128]:
			var img := image(nm, sz)
			var on := 0
			for y in sz:
				for x in sz:
					if img.get_pixel(x, y).a > 0.5:
						on += 1
			var f: float = float(on) / float(sz * sz)
			ok = ok and f > 0.1 and f < 0.9
			if sz == 32:
				shapes[nm] = img
	var names := NAMES
	for i in names.size():
		for j in range(i + 1, names.size()):
			var diff := 0
			for y in 32:
				for x in 32:
					if absf(shapes[names[i]].get_pixel(x, y).a - shapes[names[j]].get_pixel(x, y).a) > 0.5:
						diff += 1
			ok = ok and diff > 60
	for k in ["circle", "square", "triangle", "diamond"]:
		ok = ok and symbol_image(k, Color.WHITE, 32).get_pixel(16, 17).a > 0.5
	print("SELFTEST UiIcons %d Icons -> %s" % [NAMES.size(), "OK" if ok else "FAIL"])
	return ok
