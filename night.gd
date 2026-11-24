class_name Night
extends Node
## Nacht mit sanftem Zeitlimit: Dämmerung (0-20 %), Mitternacht (20-80 %), Morgenrot (80-100 %), dann Ende.
## Kein Game Over: Der Fortschritt bleibt, die Nacht endet einfach mit dem Sonnenaufgang.

const DEFAULT_DURATION := 600.0

var duration := DEFAULT_DURATION
var elapsed := 0.0
var running := false


func start(total_seconds: float = DEFAULT_DURATION) -> void:
	duration = maxf(1.0, total_seconds)
	elapsed = 0.0
	running = true
	GameState.start_night()


func time_left() -> float:
	return maxf(0.0, duration - elapsed)


func progress() -> float:
	return clampf(elapsed / duration, 0.0, 1.0)


## Zeit voranschreiten lassen (wird von _process aufgerufen, auch direkt testbar).
func tick(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	var p := elapsed / duration
	if p >= 1.0:
		running = false
		GameState.end_night()
	elif p >= 0.8:
		GameState.set_phase(GameState.Phase.MORGENROT)
	elif p >= 0.2:
		GameState.set_phase(GameState.Phase.MITTERNACHT)
	else:
		GameState.set_phase(GameState.Phase.DAEMMERUNG)


func _process(delta: float) -> void:
	tick(delta)
