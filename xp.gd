class_name Xp
extends RefCounted
## G-26: Erfahrung. Quellen (REWARDS) geben XP, jede Stufe gibt einen Fähigkeitspunkt (Skills). Reine Logik, lokal je Spieler.

signal changed
signal leveled_up(level: int)

const MAX_LEVEL := 20
## XP je Ereignis (add_event). "spot" = ein weggeputzter Fleck.
const REWARDS := {"spot": 1, "star": 30, "constellation": 100, "enemy": 20, "cook": 15, "revive": 40}

var xp := 0          # Gesamt-XP
var level := 1
var points := 0      # ungenutzte Fähigkeitspunkte


## Gesamt-XP, die für das Erreichen von `lvl` nötig sind (Stufe 1 = 0).
static func total_for(lvl: int) -> int:
	var t := 0
	for l in range(1, lvl):
		t += need(l)
	return t


## XP von Stufe `lvl` auf `lvl + 1`.
static func need(lvl: int) -> int:
	return 40 + 20 * (lvl - 1)


func add_event(kind: String, count: int = 1) -> int:
	return add_xp(int(REWARDS.get(kind, 0)) * count)


## XP gutschreiben. Gibt die Zahl neuer Stufen zurück.
func add_xp(amount: int) -> int:
	if amount <= 0 or level >= MAX_LEVEL:
		return 0
	xp += amount
	var gained := 0
	while level < MAX_LEVEL and xp >= total_for(level + 1):
		level += 1
		points += 1
		gained += 1
		leveled_up.emit(level)
	changed.emit()
	return gained


## Fortschritt zur nächsten Stufe (0..1); auf Maximalstufe 1.
func progress() -> float:
	if level >= MAX_LEVEL:
		return 1.0
	return float(xp - total_for(level)) / float(need(level))


func spend_point() -> bool:
	if points <= 0:
		return false
	points -= 1
	changed.emit()
	return true
