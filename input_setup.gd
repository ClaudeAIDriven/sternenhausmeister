class_name InputSetup
extends RefCounted
## C-04: InputMap aus den Einstellungen aufbauen (Tastatur, Maus, Gamepad) und Umbelegen.
## Aufruf: InputSetup.apply() beim Start (ersetzt main.gd::_setup_input) und
## InputSetup.rebind(aktion, ereignis) aus dem Umbelegen-Dialog.
## Pro Aktion gibt es zwei Plätze: "kb" (Taste oder Maustaste) und "pad" (Gamepad-Knopf oder -Achse).
## Gespeichert wird nur, was vom Standard abweicht (Settings-Schlüssel "bindings").

const ACTIONS := ["move_forward", "move_back", "move_left", "move_right", "jump", "clean", "attack"]
const SLOTS := ["kb", "pad"]


## Standardbelegung: {Aktion: {"kb": Dict, "pad": Dict}} (Ereignisse als Dictionary).
static func defaults() -> Dictionary:
	return {
		"move_forward": {"kb": _key(KEY_W), "pad": _axis(JOY_AXIS_LEFT_Y, -1.0)},
		"move_back": {"kb": _key(KEY_S), "pad": _axis(JOY_AXIS_LEFT_Y, 1.0)},
		"move_left": {"kb": _key(KEY_A), "pad": _axis(JOY_AXIS_LEFT_X, -1.0)},
		"move_right": {"kb": _key(KEY_D), "pad": _axis(JOY_AXIS_LEFT_X, 1.0)},
		"jump": {"kb": _key(KEY_SPACE), "pad": _btn(JOY_BUTTON_A)},
		"clean": {"kb": _mouse(MOUSE_BUTTON_LEFT), "pad": _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)},
		"attack": {"kb": _mouse(MOUSE_BUTTON_RIGHT), "pad": _btn(JOY_BUTTON_X)},
	}


## Baut die InputMap neu: Standard, darüber die gespeicherten Abweichungen.
static func apply(settings: Node = null) -> void:
	var overrides := _overrides(settings)
	var defs := defaults()
	for action in ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action, 0.5)
		for slot in SLOTS:
			var d: Dictionary = overrides.get(action, {}).get(slot, defs[action][slot])
			var e := dict_to_event(d)
			if e != null:
				InputMap.action_add_event(action, e)
	# Wie bisher: E als zweite Taste zum Putzen, solange 'kb' nicht umbelegt wurde.
	if not overrides.get("clean", {}).has("kb"):
		InputMap.action_add_event("clean", dict_to_event(_key(KEY_E)))


## Belegt eine Aktion neu. Der Platz (kb/pad) ergibt sich aus dem Ereignis.
## Rückgabe: OK, ERR_INVALID_PARAMETER (unbekannte Aktion/ungeeignetes Ereignis, Esc ist gesperrt),
## ERR_ALREADY_EXISTS (Ereignis gehört schon zu einer anderen Aktion; nichts wird geändert).
static func rebind(action: String, event: InputEvent, settings: Node = null) -> Error:
	if not ACTIONS.has(action):
		return ERR_INVALID_PARAMETER
	var slot := slot_of(event)
	if slot == "":
		return ERR_INVALID_PARAMETER
	if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		return ERR_INVALID_PARAMETER
	var d := event_to_dict(event)
	if d.is_empty():
		return ERR_INVALID_PARAMETER
	var cur := effective(settings)
	for other in ACTIONS:
		if other != action and _same(cur[other][slot], d):
			return ERR_ALREADY_EXISTS
	var s := _settings(settings)
	if s == null:
		return ERR_UNAVAILABLE
	var ov := _overrides(settings)
	var entry: Dictionary = ov.get(action, {}).duplicate()
	entry[slot] = d
	ov[action] = entry
	s.set_value("bindings", ov)
	apply(settings)
	return OK


## Setzt eine Aktion (beide Plätze) auf den Standard zurück.
static func reset_action(action: String, settings: Node = null) -> void:
	var s := _settings(settings)
	if s == null:
		return
	var ov := _overrides(settings)
	ov.erase(action)
	s.set_value("bindings", ov)
	apply(settings)


## Gültige Belegung je Aktion (Standard + Abweichungen).
static func effective(settings: Node = null) -> Dictionary:
	var out := defaults()
	var ov := _overrides(settings)
	for action in ov:
		if out.has(action):
			for slot in ov[action]:
				if SLOTS.has(slot):
					out[action][slot] = ov[action][slot]
	return out


## Anzeigetext für den Dialog, z. B. "E", "Linke Maustaste", "Gamepad A".
static func event_text(d: Dictionary) -> String:
	var e := dict_to_event(d)
	if e == null:
		return "–"
	if e is InputEventKey:
		return OS.get_keycode_string((e as InputEventKey).physical_keycode)
	if e is InputEventMouseButton:
		return "Maustaste %d" % (e as InputEventMouseButton).button_index
	if e is InputEventJoypadButton:
		return "Gamepad Knopf %d" % (e as InputEventJoypadButton).button_index
	var m := e as InputEventJoypadMotion
	return "Gamepad Achse %d%s" % [m.axis, "+" if m.axis_value > 0.0 else "-"]


static func slot_of(e: InputEvent) -> String:
	if e is InputEventKey or e is InputEventMouseButton:
		return "kb"
	if e is InputEventJoypadButton or e is InputEventJoypadMotion:
		return "pad"
	return ""


static func event_to_dict(e: InputEvent) -> Dictionary:
	if e is InputEventKey:
		var k := e as InputEventKey
		var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
		return _key(code) if code != KEY_NONE else {}
	if e is InputEventMouseButton:
		return _mouse((e as InputEventMouseButton).button_index)
	if e is InputEventJoypadButton:
		return _btn((e as InputEventJoypadButton).button_index)
	if e is InputEventJoypadMotion:
		var m := e as InputEventJoypadMotion
		return _axis(m.axis, signf(m.axis_value))
	return {}


static func dict_to_event(d: Dictionary) -> InputEvent:
	match d.get("t", ""):
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = int(d.get("c", 0)) as Key
			return k
		"mouse":
			var m := InputEventMouseButton.new()
			m.button_index = int(d.get("b", 0)) as MouseButton
			return m
		"jbtn":
			var b := InputEventJoypadButton.new()
			b.button_index = int(d.get("b", 0)) as JoyButton
			return b
		"jaxis":
			var a := InputEventJoypadMotion.new()
			a.axis = int(d.get("a", 0)) as JoyAxis
			a.axis_value = float(d.get("v", 1.0))
			return a
	return null


static func _key(code: int) -> Dictionary:
	return {"t": "key", "c": code}

static func _mouse(button: int) -> Dictionary:
	return {"t": "mouse", "b": button}

static func _btn(button: int) -> Dictionary:
	return {"t": "jbtn", "b": button}

static func _axis(axis: int, value: float) -> Dictionary:
	return {"t": "jaxis", "a": axis, "v": value}


static func _same(a: Dictionary, b: Dictionary) -> bool:
	return a.get("t") == b.get("t") and a.get("c") == b.get("c") and a.get("b") == b.get("b") \
		and a.get("a") == b.get("a") and is_equal_approx(float(a.get("v", 0.0)), float(b.get("v", 0.0)))


static func _settings(settings: Node) -> Node:
	if settings != null:
		return settings
	var loop := Engine.get_main_loop()
	return (loop as SceneTree).root.get_node_or_null("Settings") if loop is SceneTree else null


## Kopie der gespeicherten Abweichungen (Werte aus ConfigFile können Fremdtypen sein: prüfen).
static func _overrides(settings: Node) -> Dictionary:
	var s := _settings(settings)
	var out := {}
	if s == null:
		return out
	var raw: Variant = s.get_value("bindings")
	if not (raw is Dictionary):
		return out
	for action in raw:
		if raw[action] is Dictionary:
			var entry := {}
			for slot in raw[action]:
				if SLOTS.has(slot) and raw[action][slot] is Dictionary:
					entry[slot] = (raw[action][slot] as Dictionary).duplicate()
			if not entry.is_empty():
				out[action] = entry
	return out
