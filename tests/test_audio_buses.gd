extends SceneTree
## Test S-03: getrennte Busse, Lautstärke je Bus aus den Einstellungen, UI-Klicks, nahtloser Ambient-Loop.

var frames := 0

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var ok := true
	var st = root.get_node("Settings")
	st.config_path = "user://settings_test_audio.cfg"
	st.reset_to_defaults()
	Sfx.setup_buses()
	Sfx.setup_buses()   # zweimal: keine doppelten Busse
	var idxs := {}
	for b in Sfx.BUSES:
		var i := AudioServer.get_bus_index(b)
		ok = ok and i > 0
		idxs[i] = true
		ok = ok and AudioServer.get_bus_send(i) == &"Master"
	ok = ok and idxs.size() == 4 and AudioServer.bus_count == 5
	# Lautstärken unabhängig
	st.set_value("volume_sfx", 0.5)
	st.set_value("volume_music", 0.2)
	st.set_value("volume_master", 1.0)
	Sfx.apply_settings(st)
	ok = ok and absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(Sfx.BUS_UI)) - linear_to_db(0.5)) < 0.01
	ok = ok and absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(Sfx.BUS_MUSIC)) - linear_to_db(0.2)) < 0.01
	st.set_value("volume_sfx", 0.0)
	Sfx.apply_settings(st)
	ok = ok and AudioServer.is_bus_mute(AudioServer.get_bus_index(Sfx.BUS_AMBIENT)) and not AudioServer.is_bus_mute(AudioServer.get_bus_index(Sfx.BUS_MUSIC))
	# Klicks: nicht leer, kurz, nicht übersteuert
	for w in [Sfx.make_click(), Sfx.make_hover(), Sfx.make_confirm()]:
		ok = ok and w.data.size() > 100 and w.data.size() < Sfx.RATE * 2
	# Ambient: Schleife gesetzt, Naht ohne Sprung, Pegel plausibel
	var amb := Sfx.make_night_ambient(8.0)
	var n := amb.data.size() / 2
	ok = ok and amb.loop_mode == AudioStreamWAV.LOOP_FORWARD and amb.loop_end == n
	var seam := absi(amb.data.decode_s16((n - 1) * 2) - amb.data.decode_s16(0))
	var peak := 0
	var typical := 0.0
	for i in range(0, n, 7):
		var v := absi(amb.data.decode_s16(i * 2))
		peak = maxi(peak, v)
		typical += v
	typical /= float(n / 7)
	ok = ok and seam < 1500 and peak > 500 and peak < 32000 and typical > 100
	print("AUDIO seam=", seam, " peak=", peak, " mean=", typical)
	# Knoten: Sfx-Instanz hängt Spieler an SFX-Bus, Ambient an Ambient-Bus
	var sfx := Sfx.new()
	root.add_child(sfx)
	ok = ok and sfx.players[0].bus == Sfx.BUS_SFX
	sfx.start_ambient()
	ok = ok and sfx.ambient_player.bus == Sfx.BUS_AMBIENT
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings_test_audio.cfg"))
	print("TEST_AUDIO_BUSES OK" if ok else "TEST_AUDIO_BUSES FAIL")
	quit(0 if ok else 1)
	return true
