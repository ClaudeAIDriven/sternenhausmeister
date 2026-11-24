class_name Roles
extends RefCounted
## I-13: Rollen mit Stärken und Schwächen. Werte sind Faktoren auf die Grundwerte; der Spieler wählt die Rolle im Menü.
##  speed: Lauftempo, jump: Sprungkraft, jump_cd: Sprung-Abklingzeit (s), wipe: Wischradius, fears_spiders: meidet Spinnennester.

const DEFAULT_ID := "allrounder"

const ALL := {
	"allrounder": {"name": "Allrounder", "speed": 1.0, "jump": 1.0, "jump_cd": 0.0, "wipe": 1.0, "fears_spiders": false,
		"desc": "Keine Stärken, keine Schwächen."},
	"springer": {"name": "Hüpfer", "speed": 1.0, "jump": 1.6, "jump_cd": 2.5, "wipe": 1.0, "fears_spiders": false,
		"desc": "Springt viel höher (erreicht tiefe Sterne ohne Ballon), muss danach 2,5 s warten."},
	"putzer": {"name": "Gründlicher Putzer", "speed": 0.9, "jump": 1.0, "jump_cd": 0.0, "wipe": 1.5, "fears_spiders": true,
		"desc": "Wischt 50 % breiter, hat aber Angst vor Spinnen und läuft nicht in ihre Nähe."},
	"flitzer": {"name": "Flitzer", "speed": 1.5, "jump": 1.0, "jump_cd": 0.0, "wipe": 0.6, "fears_spiders": false,
		"desc": "Sehr schnell, putzt aber nur 60 % so breit (schlampig)."},
	# G-24. Team-Nutzen: Koch füttert alle (Rezepte füllen mehr, Buffs halten länger); Kletterer baut eine Leiter für alle.
	"koch": {"name": "Koch", "speed": 1.0, "jump": 1.0, "jump_cd": 0.0, "wipe": 1.0, "fears_spiders": false,
		"food_max": 1.5, "recipe_food": 1.5, "buff_time": 1.5,
		"desc": "Große Sättigungsleiste (+50 %), Rezepte füllen 50 % mehr, Buffs halten 50 % länger."},
	"kletterer": {"name": "Kletterer", "speed": 1.0, "jump": 1.0, "jump_cd": 0.0, "wipe": 1.0, "fears_spiders": false,
		"climb": 1.0, "ladder": 1.0, "food_drain": 1.5,
		"desc": "Klettert steile Flächen hoch und stellt eine Leiter (8 s) für alle auf, braucht aber 50 % mehr Essen."},
}

## Standardwerte der G-24-Schlüssel (andere Rollen haben sie nicht).
const DEFAULTS := {"food_max": 1.0, "recipe_food": 1.0, "buff_time": 1.0, "food_drain": 1.0, "climb": 0.0, "ladder": 0.0}


static func ids() -> Array:
	return ["allrounder", "springer", "putzer", "flitzer", "koch", "kletterer"]


static func data(id: String) -> Dictionary:
	return ALL.get(id, ALL[DEFAULT_ID])


static func factor(id: String, key: String) -> float:
	return float(data(id).get(key, DEFAULTS.get(key, 1.0)))


static func can_climb(id: String) -> bool:
	return factor(id, "climb") > 0.0


static func can_ladder(id: String) -> bool:
	return factor(id, "ladder") > 0.0


static func fears_spiders(id: String) -> bool:
	return bool(data(id).get("fears_spiders", false))
