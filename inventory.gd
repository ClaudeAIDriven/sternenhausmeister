class_name Inventory
extends RefCounted
## G-22: Zwölf Plätze für Früchte (nur lokal beim Spieler). Q isst die vorderste Frucht und füllt die Sättigung (Food, G-21).

signal changed

const SLOTS := 12   # mehr Essen sammeln: 12 statt 6 Plätze

var items: Array[String] = []
var extra_slots := 0   # M-01: Fähigkeit "bag_slots"


func is_full() -> bool:
	return items.size() >= SLOTS + extra_slots


func add(kind: String) -> bool:
	if is_full() or not Fruit.KINDS.has(kind):
		return false
	items.append(kind)
	changed.emit()
	return true


## Isst die Frucht auf Platz `slot` (Standard: vorderste). Gibt die gegessene Sorte zurück, "" wenn nichts da war.
func eat(food: Food, slot: int = 0) -> String:
	if slot < 0 or slot >= items.size() or food == null:
		return ""
	var kind := items[slot]
	items.remove_at(slot)
	food.feed(Fruit.food_value(kind))
	changed.emit()
	return kind
