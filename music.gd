class_name Music
extends Node
## Lo-Fi-Musikschleife (S-01), komplett per Code erzeugt (keine Dateien, keine Lizenzfragen, CC0/eigen).
## Nutzung (Einbau gehört nicht zu dieser Karte): `var m := Music.new(); add_child(m); m.play_music()`.
## Lautstärke: `volume` 0..1; folgt dem Autoload `Settings` (Key "music_volume"), sobald es ihn gibt (C-03).

const RATE := 22050
const BPM := 70.0
const BARS := 4
# Am7 – Fmaj7 – Cmaj7 – G6 (Wurzel, Terz, Quinte, Septime in Hz)
const CHORDS := [
	[220.0, 261.6, 329.6, 392.0],
	[174.6, 220.0, 261.6, 329.6],
	[130.8, 164.8, 196.0, 246.9],
	[196.0, 246.9, 293.7, 329.6],
]
const MELODY := [  # Pentatonik, 0 = Pause; je Takt 4 Viertel
	[659.3, 0.0, 587.3, 0.0], [523.3, 0.0, 0.0, 587.3],
	[659.3, 0.0, 783.99, 0.0], [587.3, 0.0, 0.0, 0.0],
]

var volume := 0.6:
	set(v):
		volume = clampf(v, 0.0, 1.0)
		if _player:
			_player.volume_db = linear_to_db(maxf(volume, 0.0001)) - 8.0
var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	var settings := get_node_or_null("/root/Settings")
	if settings and settings.has_method("get_value"):
		var v = settings.get_value("music_volume")
		if v != null:
			volume = float(v)
		if settings.has_signal("changed"):
			settings.changed.connect(func(key) -> void:
				if str(key) == "music_volume":
					volume = float(settings.get_value("music_volume")))
	volume = volume  # Setter anwenden


func play_music() -> void:
	if _player.stream == null:
		_player.stream = make_loop()
	_player.play()


func stop_music() -> void:
	_player.stop()


## Erzeugt die nahtlose Schleife (mono, 16 bit). Statisch, damit Tests sie ohne Baum prüfen können.
static func make_loop() -> AudioStreamWAV:
	var beat := 60.0 / BPM
	var bar := beat * 4.0
	var n := int(RATE * bar * BARS)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for b in BARS:
		var t0 := b * bar
		var chord: Array = CHORDS[b]
		# Pad: weiche Akkordtöne, die sich über den Takt sanft ein- und ausblenden
		for f in chord:
			_add_tone(buf, t0, bar, f, 0.10, 0.5 * bar, true)
		# Bass: Wurzel eine Oktave tiefer, 2 Schläge
		_add_tone(buf, t0, beat * 2.0, chord[0] * 0.5, 0.22, beat * 1.6, false)
		_add_tone(buf, t0 + beat * 2.0, beat * 2.0, chord[0] * 0.5, 0.18, beat * 1.6, false)
		# Melodie: sparsam, kurzer Zupfton
		for i in 4:
			var f: float = MELODY[b][i]
			if f > 0.0:
				_add_tone(buf, t0 + i * beat, beat * 1.5, f, 0.13, beat * 0.9, false)
		# Vinyl-Knistern
		for k in 6:
			var at := int((t0 + rng.randf() * bar) * RATE)
			if at < n:
				buf[at] += rng.randf_range(-0.03, 0.03)
	# Tiefpass (Lo-Fi-Wärme), einfach einpolig; zyklisch, damit Anfang/Ende zusammenpassen
	var lp := buf[n - 1]
	for pass_i in 2:
		for i in n:
			lp += (buf[i] - lp) * 0.25
			buf[i] = lp
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w


## Mischt einen Ton ein. `pad`: sanfte Ein-/Ausblendung über die ganze Dauer; sonst Anschlag + Abklingen.
## Wichtig für Nahtlosigkeit: Alles klingt vor dem Taktende aus (Pad blendet aus), nichts reicht über die Schleifengrenze.
static func _add_tone(buf: PackedFloat32Array, start: float, dur: float, freq: float, vol: float, decay: float, pad: bool) -> void:
	var s0 := int(start * RATE)
	var cnt := int(dur * RATE)
	for i in cnt:
		var idx := s0 + i
		if idx >= buf.size():
			break
		var t := float(i) / RATE
		var x := float(i) / cnt
		var env: float
		if pad:
			env = sin(PI * x)  # 0 -> 1 -> 0
		else:
			env = minf(1.0, t * 60.0) * exp(-t / maxf(decay * 0.35, 0.01)) * (1.0 - x * x)
		var w := sin(TAU * freq * t) + 0.25 * sin(TAU * freq * 2.0 * t)
		buf[idx] += w * env * vol


## Selbsttest: Länge stimmt, Anfang/Ende leise (nahtlos), Signal nicht leer und nicht übersteuert.
static func selftest() -> bool:
	var w := make_loop()
	var n := w.data.size() / 2
	var expect := int(RATE * (60.0 / BPM) * 4.0 * BARS)
	var first := absf(w.data.decode_s16(0)) / 32768.0
	var last := absf(w.data.decode_s16((n - 1) * 2)) / 32768.0
	var peak := 0.0
	for i in range(0, n, 7):
		peak = maxf(peak, absf(w.data.decode_s16(i * 2)) / 32768.0)
	var ok := n == expect and first < 0.02 and last < 0.02 and peak > 0.1 and peak < 0.98 and w.loop_mode == AudioStreamWAV.LOOP_FORWARD
	print("SELFTEST Music n=%d (soll %d) Rand=%.4f/%.4f Spitze=%.2f -> %s" % [n, expect, first, last, peak, "OK" if ok else "FAIL"])
	return ok
