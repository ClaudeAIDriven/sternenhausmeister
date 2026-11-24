class_name CleanTool
extends RefCounted
## Putzwerkzeuge und Schmutztypen (G-06). Richtiges Werkzeug wirkt voll, falsches nur schwach.

enum Dirt { SOOT, STAIN, PATINA }  # Ruß, Flecken, Patina
enum Kind { ANY, VACUUM, CLOTH, POLISH }  # ANY = Altverhalten (alles voll wirksam)

const WRONG_FACTOR := 0.34  # falsches Werkzeug: gut ein Drittel der Wirkung
const DIRT_COLORS := {
	Dirt.SOOT: Color(0.08, 0.07, 0.07),
	Dirt.STAIN: Color(0.30, 0.18, 0.08),
	Dirt.PATINA: Color(0.10, 0.28, 0.24),
}
const MATCH := {Kind.VACUUM: Dirt.SOOT, Kind.CLOTH: Dirt.STAIN, Kind.POLISH: Dirt.PATINA}


## G-25: Werkzeugart aus dem Namen in den Utensil-Daten ("ANY", "VACUUM", "CLOTH", "POLISH"); unbekannt = ANY.
static func kind_from_name(n: String) -> int:
	return int(Kind.get(n, Kind.ANY))


## Wirkung (0..1) eines Werkzeugs auf einen Schmutztyp.
static func efficiency(kind: int, dirt: int) -> float:
	if kind == Kind.ANY or MATCH.get(kind, -1) == dirt:
		return 1.0
	return WRONG_FACTOR


## Selbsttest: richtiges Werkzeug braucht weniger Wischzüge als falsches. Gibt true bei Erfolg.
## Koroutine: mit `await CleanTool.selftest(root)` aufrufen (braucht laufenden Baum, damit Star._ready läuft).
static func selftest(root: Node) -> bool:
	await (Engine.get_main_loop() as SceneTree).process_frame
	var counts := {}
	for kind in [Kind.VACUUM, Kind.CLOTH, Kind.POLISH]:
		var star := Star.new()
		root.add_child(star)
		await (Engine.get_main_loop() as SceneTree).process_frame
		var strokes := 0
		var only: int = MATCH[kind]
		# Nur Flecken des passenden Typs zählen: alle anderen sofort entfernen (ANY).
		for s in star.spots.duplicate():
			if s.get_meta("dirt") != only:
				star.wipe(star.to_global(s.position), 0.01, Kind.ANY)
		var right_n := star.spots.size()
		while strokes < 50 and star.spots.size() > 0:
			strokes += 1
			star.wipe(star.global_position, 100.0, kind)
		counts[kind] = [strokes, right_n]
		star.free()
	var ok := true
	for kind in counts:
		ok = ok and counts[kind][0] == 1
	# Falsches Werkzeug auf Ruß (Tuch auf Ruß): braucht mehrere Züge.
	var star2 := Star.new()
	root.add_child(star2)
	await (Engine.get_main_loop() as SceneTree).process_frame
	for s in star2.spots.duplicate():
		if s.get_meta("dirt") != Dirt.SOOT:
			star2.wipe(star2.to_global(s.position), 0.01, Kind.ANY)
	var wrong := 0
	while wrong < 50 and star2.spots.size() > 0:
		wrong += 1
		star2.wipe(star2.global_position, 100.0, Kind.CLOTH)
	star2.free()
	ok = ok and wrong > 1
	print("SELFTEST G-06 right_strokes=1 wrong_strokes=%d ok=%s" % [wrong, str(ok)])
	return ok
