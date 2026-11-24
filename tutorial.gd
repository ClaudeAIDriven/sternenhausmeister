class_name Tutorial
extends Node
## Anfängerhilfe (U-06): Beim ersten Spiel führen kurze Hinweise durch die ersten Minuten: Putzen, ganzen Stern säubern,
## Werkstatt, Sternbild-Reihenfolge. Der nächste Stern des Sternbilds pulsiert zu Beginn. Danach merkt sich Settings
## `tutorial_done`, und die Hilfe bleibt aus. Nutzung: `var t := Tutorial.new(); add_child(t); t.bind(world, hud)`.
## Die Schritte laufen von selbst weiter, sobald die passende Handlung passiert ist (Signale der Welt).

enum Step { START, FIRST_WIPE, FIRST_STAR, PUZZLE, DONE }

const TEXTS := {
	Step.START: "Willkommen auf der Wolkeninsel! Geh nah an einen schmutzigen Stern und halte die linke Maustaste (oder E) zum Putzen.",
	Step.FIRST_WIPE: "Schön! Putz den ganzen Stern sauber. Mit der Taste B öffnest du die Werkstatt: Dort kaufst du Upgrades mit Sternenstaub.",
	Step.FIRST_STAR: "Der erste Stern glänzt! Die Sterne bilden ein Sternbild. Putz sie in der richtigen Reihenfolge, der pulsierende Stern ist als Nächstes dran.",
	Step.PUZZLE: "",
}

var step: int = Step.START
var active := false
var _world: World
var _hud: Hud


func bind(world: World, hud: Hud) -> void:
	_world = world
	_hud = hud
	if bool(Settings.get_value("tutorial_done")):
		step = Step.DONE
		return
	active = true
	world.star_scrubbed.connect(_on_scrubbed)
	world.star_cleaned.connect(_on_cleaned)
	world.puzzle_solved.connect(func(_b): finish())
	_enter(Step.START)
	_pulse_first_puzzle_star()


func _enter(s: int) -> void:
	step = s
	if TEXTS.get(s, "") != "":
		_hud.show_puzzle_message(TEXTS[s], 14.0)


## Lässt den ersten Stern des Sternbilds pulsieren (nur solange noch nichts geputzt wurde).
func _pulse_first_puzzle_star() -> void:
	if _world.puzzle == null:
		return
	var idx: int = _world.puzzle.hint()
	if idx >= 0 and idx < _world.stars.size():
		_world.stars[idx].set_hint(true)


func _on_scrubbed(_star: Star, _removed: int) -> void:
	if active and step == Step.START:
		_enter(Step.FIRST_WIPE)


func _on_cleaned(_star: Star) -> void:
	if not active:
		return
	if step == Step.START or step == Step.FIRST_WIPE:
		_enter(Step.FIRST_STAR)
		step = Step.PUZZLE   # ab jetzt zeigt die Welt selbst den nächsten Stern (hint_mode); Text bleibt stehen
		Settings.set_value("tutorial_done", true)


func finish() -> void:
	active = false
	step = Step.DONE
	Settings.set_value("tutorial_done", true)
