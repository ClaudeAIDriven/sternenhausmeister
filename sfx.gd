class_name Sfx
extends Node
## Kleiner Sound-Helfer: erzeugt Töne per Code (keine Audiodateien nötig).

const RATE := 22050

var players: Array[AudioStreamPlayer] = []
var idx := 0


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)


static func make_tone(freq: float, dur: float, vol: float = 0.5, noise: float = 0.0) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var env := minf(1.0, t * 80.0) * pow(1.0 - float(i) / n, 2.0)
		var s := sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.0 * t) * 0.2
		if noise > 0.0:
			s = s * (1.0 - noise) + (randf() * 2.0 - 1.0) * noise
		var v := int(clampf(s * env * vol, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


func play(stream: AudioStream, pitch: float = 1.0, db: float = 0.0) -> void:
	var p := players[idx]
	idx = (idx + 1) % players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = db
	p.play()


# --- S-02: Sternakkorde und Sternbild-Melodien -------------------------------------------------

## Tonleiter für Sternhöhen: C-Dur-Pentatonik, Halbtöne über dem Grundton C4. Zwei Oktaven = 10 verschiedene Töne.
const STAR_SCALE := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21]
const ROOT_FREQ := 261.63


## Eigene Tonhöhe je Stern-ID (Hz). IDs 0..9 klingen alle verschieden; ab 10 wiederholt sich die Reihe eine Oktave höher.
static func star_freq(star_id: int) -> float:
	var n := STAR_SCALE.size()
	var i := posmod(star_id, n)
	var octave := floori(float(star_id) / n) if star_id >= 0 else 0
	return ROOT_FREQ * pow(2.0, (STAR_SCALE[i] + 12.0 * octave) / 12.0)


## Akkord auf einem Stern: Grundton, die übernächste und die überübernächste Stufe der Sterntonleiter (Terz/Quinte-artig).
static func chord_freqs(star_id: int) -> Array[float]:
	return [star_freq(star_id), star_freq(star_id + 2), star_freq(star_id + 4)]


## Tonfolge eines Sternbilds: die Töne seiner Sterne in der Reihenfolge `order`.
static func melody_freqs(order: Array) -> Array[float]:
	var out: Array[float] = []
	for id in order:
		out.append(star_freq(int(id)))
	return out


## Mehrere Töne gleichzeitig (Akkord), Lautstärke wird durch die Tonzahl geteilt, damit nichts übersteuert.
static func make_chord(freqs: Array, dur: float, vol: float = 0.5) -> AudioStreamWAV:
	return _render(freqs, [], dur, dur, vol, true)


## Töne nacheinander im Abstand `step` Sekunden (Melodie); jeder Ton klingt `note_dur` Sekunden aus.
static func make_melody(freqs: Array, step: float = 0.28, note_dur: float = 0.7, vol: float = 0.4) -> AudioStreamWAV:
	var starts: Array = []
	for i in freqs.size():
		starts.append(step * i)
	var total := step * maxf(0.0, freqs.size() - 1.0) + note_dur
	return _render(freqs, starts, total, note_dur, vol, false)


static func _render(freqs: Array, starts: Array, total: float, note_dur: float, vol: float, together: bool) -> AudioStreamWAV:
	var n := int(RATE * total)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var per := vol / (float(freqs.size()) if together else 1.0)
	for k in freqs.size():
		var f: float = freqs[k]
		var off := 0 if together else int(RATE * float(starts[k]))
		var len := int(RATE * note_dur)
		for i in len:
			if off + i >= n:
				break
			var t := float(i) / RATE
			var env := minf(1.0, t * 80.0) * pow(1.0 - float(i) / len, 2.0)
			buf[off + i] += (sin(TAU * f * t) * 0.7 + sin(TAU * f * 2.0 * t) * 0.2) * env * per
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
