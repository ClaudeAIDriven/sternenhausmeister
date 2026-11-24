class_name Roles
extends RefCounted
## I-13: Rollen mit Stärken und Schwächen. Werte sind Faktoren auf die Grundwerte; der Spieler wählt die Rolle im Menü.
##  G-24: hunger (Faktor auf den Sättigungsverbrauch), recipe_food/buff_time (Faktor auf Gerichte, wirkt in der Küche), climb (0/1: klettert an Wänden),
##  ladder (0/1: kann eine Leiter aufstellen). Koch: 50 % mehr Leiste = Verbrauch /1,5.
##  speed: Lauftempo, jump: Sprungkraft, jump_cd: Sprung-Abklingzeit (s), wipe: Wischradius, fears_spiders: meidet Spinnennester.

const DEFAULT_ID := "allrounder"

const ALL := {
	"allrounder": {"name": "Allrounder", "speed": 1.0, "jump": 1.0, "jump_cd": 0.0, "wipe": 1.0, "fears_spiders": false,
		"desc": "Keine Stärken, keine Schwächen."},
	"springer": {"name": "Hüpfer", "speed": 1.0, "jump": 1.6, "jump_cd": 2.5, "wipe": 1.0, "fears_spiders": false,
		"desc": "Springt viel höher (erreicht tiefe Sterne ohne Ballon), muss danach 2,5 s warten."},
	"putzer": {"name": "Gründlicher Putzer", "speed": 0.9, "jump": 1.0, "jump_cd": 0.0, "wipe": 1.5, "fears_spiders": true,
		"desc": "Wischt 50 % breiter, hat aber Angst vor Spinnen und läuft nicht in ihre Nähe."},
	"koch": {"name": "Koch", "speed": 1.0, "jump": 1.0, "jump_cd": 0.0, "wipe": 1.0, "fears_spiders": false, "hunger": 0.667, "recipe_food": 1.5, "buff_time": 1.5,
		"desc": "Hält 50 % länger satt, seine Gerichte füllen 50 % mehr und wirken länger – für das ganze Team."},
	"kletterer": {"name": "Kletterer", "speed": 1.0, "jump": 1.0, "jump_cd": 0.0, "wipe": 1.0, "fears_spiders": false, "hunger": 1.5, "climb": 1.0, "ladder": 1.0,
		"desc": "Klettert steile Wände hoch und stellt mit G eine Leiter auf (8 s), die alle nutzen. Braucht 50 % mehr Essen."},
	"flitzer": {"name": "Flitzer", "speed": 1.5, "jump": 1.0, "jump_cd": 0.0, "wipe": 0.6, "fears_spiders": false,
		"desc": "Sehr schnell, putzt aber nur 60 % so breit (schlampig)."},
}


static func ids() -> Array:
	return ["allrounder", "springer", "putzer", "flitzer", "koch", "kletterer"]


static func data(id: String) -> Dictionary:
	return ALL.get(id, ALL[DEFAULT_ID])


static func factor(id: String, key: String) -> float:
	return float(data(id).get(key, 1.0))


## Hat die Rolle die Fähigkeit `key` (Faktor > 0)? z. B. "climb", "ladder".
static func can(id: String, key: String) -> bool:
	return float(data(id).get(key, 0.0)) > 0.0


static func fears_spiders(id: String) -> bool:
	return bool(data(id).get("fears_spiders", false))
