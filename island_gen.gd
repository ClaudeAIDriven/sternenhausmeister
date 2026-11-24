class_name IslandGen
extends RefCounted
## G-31: Insel-Layout aus einem Seed. Gleicher Seed = gleiche Insel (bei allen Spielern). Verteilt Sterne (schwebend) und Orte
## (Brunnen, Obstgarten, Turm, Schrein) mit Mindestabständen auf der Insel, ohne feste Bauten (Werkstatt, Küche, Ballon, Lava,
## Startpunkt) zu überdecken. Seed 0 = klassisches Layout (keine Generierung). Reine Logik, ohne Szenen.

const STAR_COUNT := 8
const STAR_MIN_DIST := 9.0     # waagerecht zwischen Sternen
const POI_MIN_DIST := 9.0      # zwischen Orten
const POI_STAR_DIST := 4.0     # Ort zu Sternmitte waagerecht (damit man nicht unter dem Stern parkt)
const EDGE_MARGIN_STAR := 8.0  # Abstand der Sterne vom Inselrand
const EDGE_MARGIN_POI := 5.0
const STAR_Y_MIN := 5.0
const STAR_Y_MAX := 6.5        # per Sprung/Ballon erreichbar (wie das klassische Layout)
const CENTER_CLEAR := 3.0      # Startpunkt (0,0) bleibt frei

## Feste Hindernisse: [Mittelpunkt (x/z), Radius]. Passt zu world.gd (Werkstatt, Ballon, Küche, Lava).
const FIXED := [[Vector2(-8, -6), 4.5], [Vector2(9.5, -2), 3.0], [Vector2(8, -14), 3.5], [Vector2(24, -4), 4.5], [Vector2(-20, 20), 4.5]]
const POI_KINDS := ["brunnen", "obstgarten", "turm", "schrein"]


## Liefert {"seed", "stars": Array[Vector3], "pois": {kind: Vector3}}. Nur x/z der Orte sind frei, y = 0.
static func generate(seed_value: int, island_radius: float = 32.0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var stars: Array = []
	var pois := {}
	var tries := 0
	while stars.size() < STAR_COUNT and tries < 4000:
		tries += 1
		var relax := 1.0 - minf(float(tries) / 8000.0, 0.4)   # sehr spät etwas enger, damit es nie hängt
		var p := _random_point(rng, island_radius - EDGE_MARGIN_STAR)
		if p.length() < 4.0:
			continue
		var ok := true
		for s in stars:
			if Vector2(s.x, s.z).distance_to(p) < STAR_MIN_DIST * relax:
				ok = false
				break
		if ok:
			stars.append(Vector3(p.x, rng.randf_range(STAR_Y_MIN, STAR_Y_MAX), p.y))
	for kind in POI_KINDS:
		tries = 0
		while not pois.has(kind) and tries < 4000:
			tries += 1
			var relax := 1.0 - minf(float(tries) / 8000.0, 0.4)
			var p := _random_point(rng, island_radius - EDGE_MARGIN_POI)
			if p.length() < CENTER_CLEAR + 2.0 or _hits_fixed(p, 2.5):
				continue
			var ok := true
			for k in pois:
				if Vector2(pois[k].x, pois[k].z).distance_to(p) < POI_MIN_DIST * relax:
					ok = false
					break
			for s in stars:
				if Vector2(s.x, s.z).distance_to(p) < POI_STAR_DIST:
					ok = false
					break
			if ok:
				pois[kind] = Vector3(p.x, 0, p.y)
	return {"seed": seed_value, "stars": stars, "pois": pois}


static func _random_point(rng: RandomNumberGenerator, max_r: float) -> Vector2:
	var a := rng.randf() * TAU
	var r := sqrt(rng.randf()) * max_r   # gleichmäßig über die Fläche
	return Vector2(cos(a) * r, sin(a) * r)


static func _hits_fixed(p: Vector2, extra: float) -> bool:
	for f in FIXED:
		if p.distance_to(f[0]) < float(f[1]) + extra:
			return true
	return false


## Prüft ein Layout: Mindestabstände, Insel-Grenzen, feste Hindernisse, Höhe. Gibt eine Liste von Fehlern zurück (leer = ok).
static func validate(layout: Dictionary, island_radius: float = 32.0) -> Array[String]:
	var errs: Array[String] = []
	var stars: Array = layout.get("stars", [])
	var pois: Dictionary = layout.get("pois", {})
	if stars.size() != STAR_COUNT:
		errs.append("Sternzahl %d" % stars.size())
	if pois.size() != POI_KINDS.size():
		errs.append("Orte %d" % pois.size())
	for i in stars.size():
		var s: Vector3 = stars[i]
		if Vector2(s.x, s.z).length() > island_radius - 1.0:
			errs.append("Stern %d außerhalb" % i)
		if s.y < STAR_Y_MIN or s.y > STAR_Y_MAX:
			errs.append("Stern %d Höhe" % i)
		for j in range(i + 1, stars.size()):
			if Vector2(s.x, s.z).distance_to(Vector2(stars[j].x, stars[j].z)) < STAR_MIN_DIST * 0.6 - 0.001:
				errs.append("Sterne %d/%d zu nah" % [i, j])
	var keys := pois.keys()
	for a in keys.size():
		var p: Vector3 = pois[keys[a]]
		var p2 := Vector2(p.x, p.z)
		if p2.length() > island_radius - 1.0:
			errs.append("%s außerhalb" % keys[a])
		if p2.length() < CENTER_CLEAR:
			errs.append("%s am Start" % keys[a])
		if _hits_fixed(p2, 0.0):
			errs.append("%s auf festem Bau" % keys[a])
		for b in range(a + 1, keys.size()):
			var q: Vector3 = pois[keys[b]]
			if p2.distance_to(Vector2(q.x, q.z)) < POI_MIN_DIST * 0.6 - 0.001:
				errs.append("%s/%s zu nah" % [keys[a], keys[b]])
	return errs


# ---------------------------------------------------------------- Gefahren (M-04)

const LAVA_RADIUS := 3.0
const NEST_RADIUS := 3.0
const CACTUS_RADIUS := 1.2
const START_CLEAR := 6.0
const GRID := 1.0   # Rasterweite der Erreichbarkeitsprüfung (m)


## Verteilt Lava, Kakteen und Spinnennester für einen Seed. `counts` = {"lava","cactus","nests"}; `layout` = Ergebnis von generate().
## Mindestabstände: Lava ≥ 9, Nester ≥ 9, Kakteen ≥ 4 untereinander; zu Orten ≥ Radius + 3; zum Start ≥ 6; nicht auf festen Bauten.
## Danach Flood-Fill: Start, alle Orte und alle Sternmitten (am Boden) müssen erreichbar bleiben, sonst wird die letzte Gefahr entfernt.
## Gibt {"lava": [Vector3], "cactus": [...], "nests": [...]} zurück.
static func generate_hazards(seed_value: int, counts: Dictionary, layout: Dictionary, island_radius: float = 32.0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + 13
	var placed: Array = []   # [Vector2, radius, kind]
	var out := {"lava": [], "cactus": [], "nests": []}
	var plan := [["lava", int(counts.get("lava", 0)), LAVA_RADIUS, 9.0], ["nests", int(counts.get("nests", 0)), NEST_RADIUS, 9.0], ["cactus", int(counts.get("cactus", 0)), CACTUS_RADIUS, 4.0]]
	for entry in plan:
		var kind: String = entry[0]
		var want: int = entry[1]
		var r: float = entry[2]
		var gap: float = entry[3]
		var tries := 0
		while out[kind].size() < want and tries < 3000:
			tries += 1
			var p := _random_point(rng, island_radius - 3.0)
			if p.length() < START_CLEAR + r or _hits_fixed(p, r):
				continue
			var ok := true
			for k in (layout.get("pois", {}) as Dictionary):
				var q: Vector3 = layout["pois"][k]
				if p.distance_to(Vector2(q.x, q.z)) < r + 3.0:
					ok = false
					break
			if not ok:
				continue
			for o in placed:
				var need: float = gap if o[2] == kind else (r + float(o[1]) + 2.0)
				if p.distance_to(o[0]) < need:
					ok = false
					break
			if ok:
				placed.append([p, r, kind])
				out[kind].append(Vector3(p.x, 0, p.y))
	# Erreichbarkeit sichern: letzte Gefahr entfernen, bis alles erreichbar ist
	while not reachable(out, layout, island_radius):
		var removed := false
		for kind in ["cactus", "nests", "lava"]:
			if not out[kind].is_empty():
				out[kind].pop_back()
				removed = true
				break
		if not removed:
			break
	return out


## Flood-Fill auf einem Raster: erreicht der Start alle Orte und die Fläche unter jedem Stern?
static func reachable(hazards: Dictionary, layout: Dictionary, island_radius: float = 32.0) -> bool:
	var blocked: Array = []   # [Vector2, radius]
	for p in hazards.get("lava", []):
		blocked.append([Vector2(p.x, p.z), LAVA_RADIUS])
	for p in hazards.get("cactus", []):
		blocked.append([Vector2(p.x, p.z), CACTUS_RADIUS])
	for f in FIXED:
		if f[0] != Vector2(24, -4) and f[0] != Vector2(-20, 20):   # Lava aus FIXED nicht doppelt (klassische Lava zählt hier nicht)
			blocked.append([f[0], float(f[1]) * 0.8])
	var n := int(ceil(island_radius * 2.0 / GRID)) + 1
	var seen := {}
	var start := Vector2i(n / 2, n / 2)
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	var qi := 0
	while qi < queue.size():
		var c: Vector2i = queue[qi]
		qi += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			var nc: Vector2i = c + d
			if seen.has(nc) or nc.x < 0 or nc.y < 0 or nc.x >= n or nc.y >= n:
				continue
			var w := _cell_to_world(nc, n)
			if w.length() > island_radius - 1.0 or _blocked(w, blocked):
				continue
			seen[nc] = true
			queue.append(nc)
	var targets: Array = []
	for k in (layout.get("pois", {}) as Dictionary):
		var q: Vector3 = layout["pois"][k]
		targets.append(Vector2(q.x, q.z))
	for s in layout.get("stars", []):
		targets.append(Vector2(s.x, s.z))
	for t in targets:
		var tc := _world_to_cell(t, n)
		var found := false
		for dx in range(-3, 4):   # Ziel darf neben einem festen Bau liegen: ein erreichbares Rasterfeld in 3 m genügt
			for dy in range(-3, 4):
				if seen.has(tc + Vector2i(dx, dy)):
					found = true
		if not found:
			return false
	return true


static func _cell_to_world(c: Vector2i, n: int) -> Vector2:
	return Vector2(c.x - n / 2, c.y - n / 2) * GRID


static func _world_to_cell(w: Vector2, n: int) -> Vector2i:
	return Vector2i(int(round(w.x / GRID)) + n / 2, int(round(w.y / GRID)) + n / 2)


static func _blocked(w: Vector2, blocked: Array) -> bool:
	for b in blocked:
		if w.distance_to(b[0]) < float(b[1]):
			return true
	return false
