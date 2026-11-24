class_name Constellation
extends RefCounted
## Rätsel-Logik eines Sternbilds (G-03): Die Sterne müssen in der Reihenfolge `order` geputzt werden.
## Reine Logik ohne Knoten; nur der Host verwaltet sie. Wer sie benutzt: meldet jeden geputzten Stern per
## `report_cleaned(id)`. Bei falscher Reihenfolge sagt `wrong`, welche Sterne wieder verschmutzen sollen
## und welcher Stern als Nächstes dran ist (Hinweis). Bei Erfolg `solved(bonus)` mit Bonus-Staub.

signal progressed(done: int, total: int)
## redirty: Sterne, die wieder schmutzig werden (bisher richtig geputzte plus der falsche); hint_id: richtiger nächster Stern
signal wrong(star_id: int, hint_id: int, redirty: Array)
signal solved(bonus: int)

const BONUS_PER_STAR := 5

var id := ""
var title := ""
var order: Array[int] = []
var positions := {}   # Stern-ID -> Vector2
var done := 0          # richtig geputzte Sterne in Folge
var is_solved := false
var mistakes := 0


## Baut aus Sternbild-Daten (siehe ConstellationLoader). Gibt null zurück, wenn die Daten ungültig sind.
static func from_data(d: Dictionary) -> Constellation:
	if ConstellationLoader.validate(d) != "":
		return null
	var c := Constellation.new()
	c.id = str(d["id"])
	c.title = str(d["name"])
	for o in d["order"]:
		c.order.append(int(o))
	for s in d["stars"]:
		c.positions[int(s["id"])] = Vector2(float(s["pos"][0]), float(s["pos"][1]))
	return c


func total() -> int:
	return order.size()


## ID des Sterns, der als Nächstes geputzt werden muss (-1 wenn gelöst). Das ist auch der Hinweis.
func hint() -> int:
	return -1 if is_solved else order[done]


func bonus() -> int:
	return BONUS_PER_STAR * order.size()


## Meldet, dass der Stern `star_id` fertig geputzt ist. Gibt zurück: "ok", "solved", "wrong" oder "ignored"
## (unbekannter Stern oder schon gelöst).
func report_cleaned(star_id: int) -> String:
	if is_solved or not positions.has(star_id):
		return "ignored"
	if star_id == order[done]:
		done += 1
		if done == order.size():
			is_solved = true
			progressed.emit(done, order.size())
			solved.emit(bonus())
			return "solved"
		progressed.emit(done, order.size())
		return "ok"
	# falsch: Hinweis geben, alles bisherige zurücksetzen
	var redirty: Array = order.slice(0, done)
	redirty.append(star_id)
	var expected := order[done]
	mistakes += 1
	done = 0
	progressed.emit(0, order.size())
	wrong.emit(star_id, expected, redirty)
	return "wrong"


## Tonfolge des Sternbilds (S-02): Tonhöhen der Sterne in Lösungsreihenfolge, siehe Sfx.star_freq.
func melody_freqs() -> Array[float]:
	return Sfx.melody_freqs(order)


## Kurze Melodie zum Abspielen, wenn das Sternbild gelöst ist (z. B. bei `solved`).
func melody_stream() -> AudioStreamWAV:
	return Sfx.make_melody(melody_freqs())


func reset() -> void:
	done = 0
	is_solved = false
	progressed.emit(0, order.size())
