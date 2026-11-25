class_name Maps
extends RefCounted
## M-03: Karten (Inselprofile). Jede Karte legt fest, wie viele Gefahren und Gegner es gibt und wie der Boden getönt ist.
## Die Positionen kommen aus festen Kandidatenlisten (M-04 ersetzt sie durch Seed-Verteilung). Reine Daten, keine Szenen.

const DEFAULT_ID := "mondwiese"

const LAVA_CANDIDATES := [Vector3(48, 0, -8), Vector3(-40, 0, 40), Vector3(-48, 0, -28), Vector3(28, 0, 44), Vector3(-20, 0, 54), Vector3(54, 0, 24), Vector3(0, 0, -54), Vector3(-54, 0, 4)]
const CACTUS_CANDIDATES := [Vector3(24, 0, 24), Vector3(-6, 0, -50), Vector3(40, 0, -36), Vector3(-50, 0, 12), Vector3(8, 0, 50), Vector3(-28, 0, -4),
	Vector3(-36, 0, -36), Vector3(30, 0, -52), Vector3(52, 0, 4), Vector3(-16, 0, 42), Vector3(44, 0, 40), Vector3(-52, 0, -8)]
const NEST_CANDIDATES := [Vector3(-18, 0, 34), Vector3(28, 0, -42), Vector3(-46, 0, -18), Vector3(10, 0, 40), Vector3(-30, 0, -44), Vector3(50, 0, 16)]

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
