class_name Fruit
extends Node3D
## G-22: Eine Frucht an einem Strauch/Baum. Leuchtet leicht, damit man sie nachts findet. Wächst nach REGROW Sekunden nach.
## Der Host entscheidet, wer sie bekommt (World); hier steckt nur Aussehen und Nachwachs-Zeit.

const REGROW := 90.0
const KINDS := {
	"sternbeere": {"name": "Sternbeere", "food": 15.0, "color": Color(1.0, 0.8, 0.25), "size": 0.2},
	"mondapfel": {"name": "Mondapfel", "food": 30.0, "color": Color(0.7, 0.85, 1.0), "size": 0.28},
	"wolkenpilz": {"name": "Wolkenpilz", "food": 45.0, "color": Color(0.95, 0.7, 0.95), "size": 0.3},
}

var kind := "sternbeere"
var available := true
var regrow_left := 0.0
var _body: MeshInstance3D
var _light: OmniLight3D


static func food_value(k: String) -> float:
	return float(KINDS.get(k, {}).get("food", 0.0))


static func display_name(k: String) -> String:
	return str(KINDS.get(k, {}).get("name", k))


func _ready() -> void:
	var d: Dictionary = KINDS.get(kind, KINDS["sternbeere"])
	var m := StandardMaterial3D.new()
	m.albedo_color = d["color"]
	m.emission_enabled = true
	m.emission = d["color"]
	m.emission_energy_multiplier = 1.2
	var s := SphereMesh.new()
	s.radius = float(d["size"])
	s.height = float(d["size"]) * 2.0
	s.radial_segments = 10
	s.rings = 6
	_body = MeshInstance3D.new()
	_body.mesh = s
	_body.material_override = m
	_body.position.y = 0.6
	add_child(_body)
	_light = OmniLight3D.new()
	_light.light_color = d["color"]
	_light.omni_range = 4.0
	_light.light_energy = 0.5
	_light.position.y = 0.6
	add_child(_light)
	_apply()


func set_available(on: bool) -> void:
	available = on
	regrow_left = 0.0 if on else REGROW
	_apply()


## Host: Zeit weiterlaufen lassen. Gibt true zurück, wenn die Frucht in diesem Schritt nachgewachsen ist.
func tick(delta: float) -> bool:
	if available:
		return false
	regrow_left = maxf(regrow_left - delta, 0.0)
	if regrow_left <= 0.0:
		set_available(true)
		return true
	return false


func _apply() -> void:
	if _body != null:
		_body.visible = available
		_light.visible = available
