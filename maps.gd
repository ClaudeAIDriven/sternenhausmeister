class_name Maps
extends RefCounted
## M-03: Karten (Inselprofile). Jede Karte legt fest, wie viele Gefahren und Gegner es gibt und wie der Boden getönt ist.
## Die Positionen kommen aus festen Kandidatenlisten (M-04 ersetzt sie durch Seed-Verteilung). Reine Daten, keine Szenen.

const DEFAULT_ID := "mondwiese"

const LAVA_CANDIDATES := [Vector3(24, 0, -4), Vector3(-20, 0, 20), Vector3(-24, 0, -14), Vector3(14, 0, 22), Vector3(-10, 0, 27), Vector3(27, 0, 12), Vector3(0, 0, -27), Vector3(-27, 0, 2)]
const CACTUS_CANDIDATES := [Vector3(12, 0, 12), Vector3(-3, 0, -25), Vector3(20, 0, -18), Vector3(-25, 0, 6), Vector3(4, 0, 25), Vector3(-14, 0, -2),
	Vector3(-18, 0, -18), Vector3(15, 0, -26), Vector3(26, 0, 2), Vector3(-8, 0, 21), Vector3(22, 0, 20), Vector3(-26, 0, -4)]
const NEST_CANDIDATES := [Vector3(-9, 0, 17), Vector3(14, 0, -21), Vector3(-23, 0, -9), Vector3(5, 0, 20), Vector3(-15, 0, -22), Vector3(25, 0, 8)]

const ALL := {
	"mondwiese": {"name": "Mondwiese", "desc": "Die klassische Insel: wenig Gefahr, viel Sternenglanz.",
		"lava": 2, "cactus": 6, "nests": 3, "bunny_mult": 1.0, "spider_mult": 1.0, "ground": Color(1, 1, 1)},
	"lavafelder": {"name": "Lavafelder", "desc": "Glühender Boden. Wer springt, bleibt heil.",
		"lava": 8, "cactus": 2, "nests": 2, "bunny_mult": 0.5, "spider_mult": 0.5, "ground": Color(1.0, 0.62, 0.5)},
	"kaktuswueste": {"name": "Kaktuswüste", "desc": "Sand, Sonne, Stacheln überall.",
		"lava": 1, "cactus": 12, "nests": 2, "bunny_mult": 1.0, "spider_mult": 0.5, "ground": Color(1.0, 0.9, 0.62)},
	"spinnenhoehle": {"name": "Spinnenhöhle", "desc": "Dunkel, klebrig, voller Beine. Nimm den Staubsauger mit!",
		"lava": 2, "cactus": 2, "nests": 6, "bunny_mult": 0.5, "spider_mult": 2.5, "ground": Color(0.62, 0.58, 0.9)},
}


static func ids() -> Array:
	var out := ALL.keys()
	out.erase(DEFAULT_ID)
	out.push_front(DEFAULT_ID)
	return out


static func profile(id: String) -> Dictionary:
	return ALL.get(id, ALL[DEFAULT_ID])


static func valid(id: String) -> bool:
	return ALL.has(id)


## Die ersten n Kandidaten (n wird auf die Listenlänge begrenzt).
static func pick(candidates: Array, n: int) -> Array:
	return candidates.slice(0, clampi(n, 0, candidates.size()))
