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
