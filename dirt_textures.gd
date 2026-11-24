class_name DirtTextures
extends RefCounted
## Prozedurale Schmutz-Overlays (A-10), 256x256, RGBA (Alpha = Deckkraft), mit festem Seed reproduzierbar.
## Die drei Typen unterscheiden sich in der FORM, nicht nur in der Farbe (Barrierefreiheit):
##   SOOT (Ruß)     = runde, ausgefranste Flecken · STAIN (Flecken) = Ringe und Tropfen · PATINA = kantige, verzweigte Risse.
## Nutzung: `DirtTextures.make(DirtTextures.Kind.SOOT)` -> ImageTexture; `make_mask()` -> RGB = Abdeckung je Typ, A = beliebiger Schmutz.

enum Kind { SOOT, STAIN, PATINA }
const SIZE := 256


static func _color(kind: int) -> Color:
	match kind:
		Kind.SOOT: return Palette.DIRT_SOOT
		Kind.STAIN: return Palette.DIRT_STAIN.darkened(0.4)   # dunkler als Hintergrund-Grau, sonst zu kontrastarm
		_: return Palette.DIRT_PATINA.darkened(0.25)


## Deckkraft-Bild (L8-artig als Float-Array pro Pixel), Werte 0..1.
static func coverage(kind: int, seed_value := 7) -> PackedFloat32Array:
	var cov := PackedFloat32Array()
	cov.resize(SIZE * SIZE)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + kind * 101
	match kind:
		Kind.SOOT: _soot(cov, rng)
		Kind.STAIN: _stain(cov, rng)
		_: _patina(cov, rng)
	return cov


static func _put(cov: PackedFloat32Array, x: int, y: int, v: float) -> void:
	if x >= 0 and y >= 0 and x < SIZE and y < SIZE:
		var i := y * SIZE + x
		cov[i] = maxf(cov[i], v)


## Ruß: runde Flecken mit unruhigem Rand (Winkel-Rauschen aus Sinus-Summen), weich ausfransend.
static func _soot(cov: PackedFloat32Array, rng: RandomNumberGenerator) -> void:
	for n in 14:
		var c := Vector2(rng.randf_range(10, SIZE - 10), rng.randf_range(10, SIZE - 10))
		var r := rng.randf_range(12.0, 34.0)
		var ph := [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
		var x0 := int(c.x - r * 1.6)
		var y0 := int(c.y - r * 1.6)
		for y in range(y0, int(c.y + r * 1.6)):
			for x in range(x0, int(c.x + r * 1.6)):
				var d := Vector2(x, y) - c
				var a := d.angle()
				var edge := r * (1.0 + 0.16 * sin(a * 3.0 + ph[0]) + 0.10 * sin(a * 7.0 + ph[1]) + 0.06 * sin(a * 13.0 + ph[2]))
				var t := d.length() / edge
				if t < 1.0:
					_put(cov, x, y, clampf((1.0 - t) * 3.0, 0.0, 1.0) * 0.95)
	# feine Rußkörnchen drumherum
	for n in 120:
		var p := Vector2(rng.randf_range(0, SIZE), rng.randf_range(0, SIZE))
		_put(cov, int(p.x), int(p.y), 0.8)
		_put(cov, int(p.x) + 1, int(p.y), 0.5)


## Flecken: Ringe (mit kleinen Lücken) und Tropfen (Kreis + Schweif).
static func _stain(cov: PackedFloat32Array, rng: RandomNumberGenerator) -> void:
	for n in 8:
		var c := Vector2(rng.randf_range(30, SIZE - 30), rng.randf_range(30, SIZE - 30))
		var r := rng.randf_range(16.0, 40.0)
		var w := rng.randf_range(6.0, 10.0)
		var gap_a := rng.randf() * TAU
		for y in range(int(c.y - r - w - 2), int(c.y + r + w + 2)):
			for x in range(int(c.x - r - w - 2), int(c.x + r + w + 2)):
				var d := Vector2(x, y) - c
				var dist := absf(d.length() - r)
				if dist < w * 0.5 and absf(angle_difference(d.angle(), gap_a)) > 0.35:
					_put(cov, x, y, clampf((w * 0.5 - dist) * 1.2, 0.0, 1.0))
	for n in 12:   # Tropfen: Kreis oben, Spitze nach unten
		var c := Vector2(rng.randf_range(10, SIZE - 10), rng.randf_range(10, SIZE - 22))
		var r := rng.randf_range(4.0, 9.0)
		for y in range(int(c.y - r), int(c.y + r * 3.0)):
			for x in range(int(c.x - r), int(c.x + r) + 1):
				var d := Vector2(x, y) - c
				var inside := d.length() < r
				var tail := d.y > 0.0 and absf(d.x) < r * (1.0 - d.y / (r * 3.0)) * 0.9
				if inside or tail:
					_put(cov, x, y, 0.9)


## Patina: verzweigte Risse, nur Richtungen in 45°-Schritten (kantig), dazu kleine eckige Splitter.
static func _patina(cov: PackedFloat32Array, rng: RandomNumberGenerator) -> void:
	var dirs := [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)]
	var heads: Array = []
	for n in 6:
		heads.append([Vector2(rng.randf_range(20, SIZE - 20), rng.randf_range(20, SIZE - 20)), rng.randi() % 8, 22])
	while not heads.is_empty():
		var h: Array = heads.pop_back()
		var p: Vector2 = h[0]
		var dir: int = h[1]
		var life: int = h[2]
		while life > 0:
			var seg := rng.randi_range(5, 11)
			var v: Vector2 = dirs[dir].normalized()
			for s in seg:
				p += v
				for oy in 3:
					for ox in 3:
						_put(cov, int(p.x) + ox - 1, int(p.y) + oy - 1, 0.95)
			life -= 1
			dir = (dir + (1 if rng.randf() < 0.5 else 7)) % 8   # knickt um 45°
			if rng.randf() < 0.28 and heads.size() < 40:
				heads.append([p, (dir + (3 if rng.randf() < 0.5 else 5)) % 8, life / 2])
			if p.x < 0 or p.y < 0 or p.x >= SIZE or p.y >= SIZE:
				break
	for n in 14:   # eckige Splitter (gedrehte Quadrate)
		var c := Vector2(rng.randf_range(8, SIZE - 8), rng.randf_range(8, SIZE - 8))
		var r := rng.randf_range(3.0, 7.0)
		var ang := rng.randf() * PI
		for y in range(int(c.y - r * 1.5), int(c.y + r * 1.5)):
			for x in range(int(c.x - r * 1.5), int(c.x + r * 1.5)):
				var d := (Vector2(x, y) - c).rotated(-ang)
				if absf(d.x) < r and absf(d.y) < r * 0.5:
					_put(cov, x, y, 0.9)


static func make_image(kind: int, seed_value := 7) -> Image:
	var cov := coverage(kind, seed_value)
	var col := _color(kind)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var a := cov[y * SIZE + x]
			if a > 0.0:
				var shade := 1.0 - 0.12 * float(hash(Vector2i(x / 3, y / 3)) % 100) / 100.0   # leichte, weiche Körnung
				img.set_pixel(x, y, Color(col.r * shade, col.g * shade, col.b * shade, a))
	return img


static func make(kind: int, seed_value := 7) -> ImageTexture:
	return ImageTexture.create_from_image(make_image(kind, seed_value))


## Schmutzmaske: R = Ruß, G = Flecken, B = Patina, A = größte Deckkraft (beliebiger Schmutz). Für Shader mit Kanalsteuerung.
static func make_mask(seed_value := 7) -> ImageTexture:
	var c0 := coverage(Kind.SOOT, seed_value)
	var c1 := coverage(Kind.STAIN, seed_value)
	var c2 := coverage(Kind.PATINA, seed_value)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			img.set_pixel(x, y, Color(c0[i], c1[i], c2[i], maxf(c0[i], maxf(c1[i], c2[i]))))
	return ImageTexture.create_from_image(img)


## Anteil der Randpixel (Deckkraft-Sprung zu einem Nachbarn) an der Fläche: hoch bei Linien und Ringen, niedrig bei Blobs.
static func _edge_ratio(cov: PackedFloat32Array) -> float:
	var edge := 0
	var area := 0
	for y in range(1, SIZE - 1):
		for x in range(1, SIZE - 1):
			var on := cov[y * SIZE + x] > 0.5
			if on:
				area += 1
				if cov[y * SIZE + x + 1] <= 0.5 or cov[y * SIZE + x - 1] <= 0.5 or cov[(y + 1) * SIZE + x] <= 0.5 or cov[(y - 1) * SIZE + x] <= 0.5:
					edge += 1
	return float(edge) / maxf(float(area), 1.0)


## Selbsttest: 256x256, plausible Deckung (3-45 %), Formen unterscheiden sich (Randanteil Ruß < Flecken < Patina), Reproduzierbarkeit.
static func selftest() -> bool:
	var ok := true
	var ratios := []
	var cover := []
	for k in [Kind.SOOT, Kind.STAIN, Kind.PATINA]:
		var cov := coverage(k)
		var on := 0
		for v in cov:
			if v > 0.5:
				on += 1
		cover.append(snappedf(float(on) / cov.size(), 0.01))
		ratios.append(snappedf(_edge_ratio(cov), 0.01))
		ok = ok and on > cov.size() * 0.03 and on < cov.size() * 0.45
		ok = ok and coverage(k) == cov
	ok = ok and make_image(Kind.SOOT).get_width() == SIZE and ratios[0] < ratios[1] and ratios[1] < ratios[2]
	print("SELFTEST DirtTextures Deckung %s Randanteil %s -> %s" % [str(cover), str(ratios), "OK" if ok else "FAIL"])
	return ok
