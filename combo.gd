class_name Combo
extends RefCounted
## Kombo beim Putzen (G-12): Wer ohne längere Pause wischt, baut eine Serie auf. Jede Stufe gibt +10 % Staub (bis +50 %)
## und lässt den Putzton etwas höher klingen. Pause länger als WINDOW Sekunden setzt die Serie zurück, ohne Strafe.
## Reine Logik ohne Szene; die Zeit wird von außen übergeben (testbar). Nutzung: `var bonus := combo.hit(now, spots)`.

const WINDOW := 1.5            # Sekunden ohne Putzen, bis die Serie endet
const SPOTS_PER_LEVEL := 12    # so viele entfernte Flecken in Folge für eine Stufe
const MAX_LEVEL := 5
const BONUS_PER_LEVEL := 0.10
const PITCH_PER_LEVEL := 0.06

signal level_changed(level: int)

var level := 0
var streak := 0
var _last := -1000.0
var _carry := 0.0


func multiplier() -> float:
	return 1.0 + BONUS_PER_LEVEL * level


func pitch() -> float:
	return 1.0 + PITCH_PER_LEVEL * level


## Meldet entfernte Flecken zur Zeit `now` (Sekunden). Gibt den Staub zurück (Basis * Bonus, Reste werden übertragen).
func hit(now: float, spots: int, base_per_spot: float = 1.0) -> int:
	if spots <= 0:
		return 0
	if now - _last > WINDOW:
		reset()
	_last = now
	streak += spots
	var new_level := mini(MAX_LEVEL, streak / SPOTS_PER_LEVEL)
	if new_level != level:
		level = new_level
		level_changed.emit(level)
	_carry += spots * base_per_spot * multiplier()
	var whole := int(_carry)
	_carry -= whole
	return whole


## Setzt die Serie zurück (Pause, Nachtende). Der Restbetrag bleibt erhalten, damit nichts verloren geht.
func reset() -> void:
	streak = 0
	if level != 0:
		level = 0
		level_changed.emit(0)


## Falls die Pause zu lang war, die Serie beenden (für die Anzeige, ohne dass gewischt wird).
func tick(now: float) -> void:
	if level > 0 and now - _last > WINDOW:
		reset()
