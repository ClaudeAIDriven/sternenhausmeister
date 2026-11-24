class_name Food
extends RefCounted
## G-21: Sättigung als zweite Leiste. Sie sinkt nur durch Tätigkeit (Laufen, Springen, Putzen), nie im Stillstand,
## und ist ein Vorteil statt eines Zwangs (Valheim): satt = schneller heilen und gründlicher putzen,
## leer = keine Regeneration und langsamer, aber niemals Schaden oder Tod.
## Auffüllen über eat() (Früchte kommen mit G-22).

const MAX := 100.0
const WELL_FED := 0.6           # ab diesem Anteil gilt man als satt
const WALK_DRAIN := 0.12        # pro Sekunde bei voller Laufgeschwindigkeit (eine Nacht = 600 s)
const CLEAN_DRAIN := 0.10       # pro Sekunde Putzen
const JUMP_COST := 0.6          # je Sprung
const FED_REGEN := 2.0          # Regenerations-Faktor, wenn satt
const FED_WIPE := 1.1           # Putzradius-Faktor, wenn satt
const EMPTY_SPEED := 0.8        # Tempo-Faktor bei leerer Leiste

signal changed(value: float)

var value := MAX


## move_ratio: 0..1 Anteil der vollen Laufgeschwindigkeit in diesem Schritt.
func tick(delta: float, move_ratio: float, cleaning: bool) -> void:
	var drain := WALK_DRAIN * clampf(move_ratio, 0.0, 1.0)
	if cleaning:
		drain += CLEAN_DRAIN
	_apply(value - drain * delta)


func jumped() -> void:
	_apply(value - JUMP_COST)


func eat(amount: float) -> void:
	_apply(value + amount)


func ratio() -> float:
	return value / MAX


func is_fed() -> bool:
	return ratio() > WELL_FED


func is_empty() -> bool:
	return value <= 0.0


func regen_factor() -> float:
	if is_empty():
		return 0.0
	return FED_REGEN if is_fed() else 1.0


func wipe_factor() -> float:
	return FED_WIPE if is_fed() else 1.0


func speed_factor() -> float:
	return EMPTY_SPEED if is_empty() else 1.0


func _apply(v: float) -> void:
	var nv := clampf(v, 0.0, MAX)
	if not is_equal_approx(nv, value):
		value = nv
		changed.emit(value)
