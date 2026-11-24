extends Node
## Autoload "Settings": Einstellungen in user://settings.cfg speichern und laden.

signal changed(key: String)

const DEFAULTS := {
	"volume_master": 1.0,
	"volume_music": 0.8,
	"volume_sfx": 1.0,
	"mouse_sens": 0.003,
	"fov": 70.0,
	"ui_scale": 1.0,
	"player_name": "Spieler",
	# C-04: eigene Tastenbelegung, {Aktion: {"kb": Ereignis-Dict, "pad": Ereignis-Dict}}.
	# Leer = Standardbelegung (siehe input_setup.gd).
	"bindings": {},
}

var config_path := "user://settings.cfg"
var _values: Dictionary = DEFAULTS.duplicate(true)


func _ready() -> void:
	load_settings()


func get_value(key: String) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant, save_now := true) -> void:
	if not DEFAULTS.has(key):
		push_warning("Unbekannte Einstellung: " + key)
		return
	if _values.get(key) == value:
		return
	_values[key] = value
	changed.emit(key)
	if save_now:
		save_settings()


func save_settings() -> Error:
	var cf := ConfigFile.new()
	for k in _values:
		cf.set_value("settings", k, _values[k])
	return cf.save(config_path)


func load_settings() -> Error:
	_values = DEFAULTS.duplicate(true)
	var cf := ConfigFile.new()
	var err := cf.load(config_path)
	if err != OK:
		return err
	for k in DEFAULTS:
		if cf.has_section_key("settings", k):
			_values[k] = cf.get_value("settings", k)
	return OK


func reset_to_defaults() -> void:
	_values = DEFAULTS.duplicate(true)
	save_settings()
	for k in DEFAULTS:
		changed.emit(k)
