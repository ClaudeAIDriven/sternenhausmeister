extends Node
## Autoload "GameState": zentraler Spielzustand. Nur der Host ändert ihn später (siehe N-03), Clients bekommen Kopien.

signal night_started
signal night_ended
signal phase_changed(phase: int)
signal star_cleaned(star: Node)
signal dust_changed(amount: int)
signal player_count_changed(count: int)

enum Phase { DAEMMERUNG, MITTERNACHT, MORGENROT, ENDE }

var player_count := 1:
	set(v):
		v = maxi(1, v)
		if v != player_count:
			player_count = v
			player_count_changed.emit(v)
var night_state: Phase = Phase.ENDE
var dust := 0
var stars_cleaned := 0
var night_running := false


func start_night() -> void:
	stars_cleaned = 0
	night_running = true
	set_phase(Phase.DAEMMERUNG)
	night_started.emit()


func end_night() -> void:
	night_running = false
	set_phase(Phase.ENDE)
	night_ended.emit()


func set_phase(p: Phase) -> void:
	if p != night_state:
		night_state = p
		phase_changed.emit(p)


func report_star_cleaned(star: Node) -> void:
	stars_cleaned += 1
	star_cleaned.emit(star)


func add_dust(amount: int) -> void:
	dust = maxi(0, dust + amount)
	dust_changed.emit(dust)


func spend_dust(amount: int) -> bool:
	if amount > dust:
		return false
	add_dust(-amount)
	return true


## G-20: Zieht `fraction` (0..1) des Sternenstaubs ab (abgerundet). Gibt den Verlust zurück.
func lose_dust_fraction(fraction: float) -> int:
	if dust <= 0:
		return 0
	var lost := clampi(int(floor(dust * fraction)), 0, dust)
	if lost <= 0:
		return 0
	add_dust(-lost)
	return lost
