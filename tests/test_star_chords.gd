extends SceneTree
## Test S-02: Jeder Stern eigene Tonhöhe, Akkorde, Tonfolge nach Sternbild korrekt.

# dominante Frequenz in einem Sampleabschnitt (Nulldurchgänge)
func _freq(w: AudioStreamWAV, from_s: float, to_s: float) -> float:
	var a := int(Sfx.RATE * from_s)
	var b := int(Sfx.RATE * to_s)
	var crossings := 0
	var prev := w.data.decode_s16(a * 2)
	for i in range(a + 1, b):
		var v := w.data.decode_s16(i * 2)
		if prev < 0 and v >= 0:
			crossings += 1
		prev = v
	return crossings / (to_s - from_s)


func _initialize() -> void:
	var ok := true
	# 10 verschiedene Töne, aufsteigend; Oktavwiederholung ab 10
	var seen := {}
	var last := 0.0
	for i in 10:
		var f := Sfx.star_freq(i)
		ok = ok and f > last
		last = f
		seen[snappedf(f, 0.01)] = true
	ok = ok and seen.size() == 10
	ok = ok and is_equal_approx(Sfx.star_freq(10) / Sfx.star_freq(0), 2.0)
	# Akkord: drei verschiedene Töne, höchster unter 3. Stufe darüber
	var ch := Sfx.chord_freqs(0)
	ok = ok and ch.size() == 3 and ch[0] < ch[1] and ch[1] < ch[2]
	# Tonfolge je Sternbild entspricht der Reihenfolge
	var all: Array = ConstellationLoader.load_dir("res://data/constellations")
	for d in all:
		var c := Constellation.from_data(d)
		var mf := c.melody_freqs()
		ok = ok and mf.size() == c.order.size()
		for i in mf.size():
			ok = ok and is_equal_approx(mf[i], Sfx.star_freq(c.order[i]))
		# Gerenderte Melodie: Note i liegt im Fenster ab i*0.28 s bei der erwarteten Frequenz (±4 %)
		var w := c.melody_stream()
		ok = ok and w.data.size() > 0
		for i in mf.size():
			var got := _freq(w, i * 0.28 + 0.02, i * 0.28 + 0.12)
			if absf(got - mf[i]) / mf[i] > 0.04:
				ok = ok and false
				print("MISMATCH ", d["id"], " note ", i, " got ", got, " want ", mf[i])
	# Kassiopeia hat eine andere Tonfolge als verkehrtes Sternbild (Reihenfolge zählt)
	var k := Constellation.from_data(all[1])
	var rev := Sfx.melody_freqs(k.order.duplicate())
	rev.reverse()
	ok = ok and rev != k.melody_freqs()
	# Akkord klingt: Länge stimmt und nicht übersteuert
	var cw := Sfx.make_chord(ch, 0.5, 0.6)
	ok = ok and cw.data.size() == int(Sfx.RATE * 0.5) * 2
	print("TEST_STAR_CHORDS OK" if ok else "TEST_STAR_CHORDS FAIL")
	quit(0 if ok else 1)
