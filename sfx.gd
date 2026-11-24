class_name Sfx
extends Node
## Kleiner Sound-Helfer: erzeugt Töne per Code (keine Audiodateien nötig).

const RATE := 22050

## Getrennte Lautstärke-Busse (S-03): SFX (Putzen, Chimes), UI (Klicks), Ambient (Wind/Nacht), Music (Musik). Alle laufen über Master.
const BUS_SFX := "SFX"
const BUS_UI := "UI"
const BUS_AMBIENT := "Ambient"
const BUS_MUSIC := "Music"
const BUSES := [BUS_SFX, BUS_UI, BUS_AMBIENT, BUS_MUSIC]

var players: Array[AudioStreamPlayer] = []
var idx := 0


func _ready() -> void:
	setup_buses()
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
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


# --- S-03: UI- und Ambient-Sounds, Lautstärke-Busse --------------------------------------------

var ambient_player: AudioStreamPlayer


## Legt die Busse an, falls es sie noch nicht gibt (mehrfach aufrufbar).
static func setup_buses() -> void:
	for b in BUSES:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")


## Lautstärke 0..1 (linear) eines Busses setzen; 0 schaltet stumm.
static func set_bus_volume(bus: String, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(i, linear <= 0.0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))


## Setzt die Bus-Lautstärken aus den Einstellungen: volume_master -> Master, volume_music -> Music,
## volume_sfx -> SFX, UI und Ambient (eigener Regler für UI/Ambient gibt es noch nicht).
static func apply_settings(settings: Node = null) -> void:
	setup_buses()
	if settings == null:
		var loop := Engine.get_main_loop()
		if loop is SceneTree:
			settings = (loop as SceneTree).root.get_node_or_null("Settings")
	if settings == null:
		return
	set_bus_volume("Master", float(settings.get_value("volume_master")))
	set_bus_volume(BUS_MUSIC, float(settings.get_value("volume_music")))
	var sfx_v := float(settings.get_value("volume_sfx"))
	for b in [BUS_SFX, BUS_UI, BUS_AMBIENT]:
		set_bus_volume(b, sfx_v)


## Kurzer, weicher Klick für Knöpfe.
static func make_click() -> AudioStreamWAV:
	return make_tone(1250.0, 0.04, 0.35, 0.15)


## Noch leiserer Ton beim Überfahren eines Knopfes.
static func make_hover() -> AudioStreamWAV:
	return make_tone(880.0, 0.03, 0.2)


## Bestätigung (Menü "Start", Kauf): etwas längerer, hellerer Ton als der Klick.
static func make_confirm() -> AudioStreamWAV:
	return make_tone(784.0, 0.22, 0.4)


## Nahtlos wiederholbarer Nachtwind mit leisen Grillen. `dur` Sekunden, Schleife eingestellt.
static func make_night_ambient(dur: float = 8.0) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var fade := int(RATE * 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var lp := 0.0
	for i in n + fade:
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.04   # Tiefpass: Rauschen -> Wind
		raw[i] = lp
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		buf[i] = raw[i]
	for i in fade:   # Naht: Ende geht weich in den Anfang über
		var a := float(i) / fade
		buf[i] = raw[i] * a + raw[n + i] * (1.0 - a)
	var gust_cycles := maxi(1, int(dur / 4.0))
	for i in n:
		var gust := 0.6 + 0.4 * sin(TAU * gust_cycles * float(i) / n)   # Böen: ganze Perioden = nahtlos
		buf[i] *= gust * 5.0
	# Grillen: kurze 4,2-kHz-Zirpgruppen, vollständig innerhalb der Schleife
	for c in int(dur / 1.3):
		var start := int(RATE * (0.3 + c * 1.3 + rng.randf() * 0.3))
		for chirp in 3:
			var cs := start + int(RATE * 0.07) * chirp
			for i in int(RATE * 0.035):
				if cs + i < n:
					buf[cs + i] += sin(TAU * 4200.0 * float(i) / RATE) * 0.04 * sin(PI * float(i) / (RATE * 0.035))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(buf[i] * 0.45, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w


## Klick/UI-Ton über den UI-Bus.
func play_ui(stream: AudioStream, db: float = -4.0) -> void:
	var p := AudioStreamPlayer.new()
	p.bus = BUS_UI
	p.stream = stream
	p.volume_db = db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## Startet den Nacht-Ambient-Loop über den Ambient-Bus (nur einmal).
func start_ambient(db: float = -10.0) -> void:
	if ambient_player != null:
		return
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = BUS_AMBIENT
	ambient_player.stream = make_night_ambient()
	ambient_player.volume_db = db
	add_child(ambient_player)
	ambient_player.play()


func stop_ambient() -> void:
	if ambient_player != null:
		ambient_player.queue_free()
		ambient_player = null
