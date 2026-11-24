class_name Food
extends RefCounted
## G-21: Sättigungsleiste. Sinkt langsam mit Laufen, Springen und Putzen. Satt (> 60 %): Regeneration x2, Putzen +10 %.
## Leer: keine Regeneration, Tempo -20 %. Hunger tötet nie und macht nur langsamer (Hunger ist ein Vorteil, kein Zwang).

signal changed(value: float)

const MAX := 100.0
const SATED_ABOVE := 0.6           # Anteil von MAX
const DRAIN_IDLE := 0.03           # je Sekunde, immer
const DRAIN_MOVE := 0.10           # je Sekunde beim Laufen
const DRAIN_CLEAN := 0.10          # je Sekunde beim Putzen
const DRAIN_JUMP := 0.5            # je Sprung
const REGEN_SATED := 2.0
const CLEAN_SATED := 1.1
const SPEED_EMPTY := 0.8

var capacity := MAX        # G-24: Koch hat mehr (Rolle), Maximum der Leiste
var drain_mult := 1.0      # G-24: Kletterer verbraucht mehr
var value := MAX


## G-24: Rolle anwenden (Leistengröße, Verbrauch). Hält den Füllstand-Anteil.
func apply_role(role_id: String) -> void:
	var frac := fraction()
	capacity = MAX * Roles.factor(role_id, "food_max")
	drain_mult = Roles.factor(role_id, "food_drain")
	value = clampf(frac * capacity, 0.0, capacity)
	changed.emit(value)


func fraction() -> float:
	return value / capacity


func is_sated() -> bool:
	return fraction() > SATED_ABOVE


func is_empty() -> bool:
	return value <= 0.0


## Ein Zeitschritt: `moving` = läuft, `cleaning` = putzt gerade.
func tick(delta: float, moving: bool, cleaning: bool) -> void:
	var d := DRAIN_IDLE
	if moving:
		d += DRAIN_MOVE
	if cleaning:
		d += DRAIN_CLEAN
	_apply(value - d * drain_mult * delta)


func on_jump() -> void:
	_apply(value - DRAIN_JUMP * drain_mult)


## Essen (G-22): füllt die Leiste auf.
func feed(amount: float) -> void:
	_apply(value + amount)


func regen_factor() -> float:
	if is_empty():
		return 0.0
	return REGEN_SATED if is_sated() else 1.0


func clean_factor() -> float:
	return CLEAN_SATED if is_sated() else 1.0


func speed_factor() -> float:
	return SPEED_EMPTY if is_empty() else 1.0


func _apply(v: float) -> void:
	var nv := clampf(v, 0.0, capacity)
	if not is_equal_approx(nv, value):
		value = nv
		changed.emit(value)
