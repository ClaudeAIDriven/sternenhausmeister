extends SceneTree
## Test M-13: Erfolge/Tagebuch-Text fürs Pausenmenü; gewählter Hut ist Teil der Replikation und wird bei jeder Änderung (auch von außen, also aus dem Netz) angezeigt.
var frames := 0
var p

func _initialize() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "jump", "clean", "attack"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

func _process(_d: float) -> bool:
	frames += 1
	if frames == 2:
		p = load("res://player.gd").new()
		p.name = "1"
		root.add_child(p)
	elif frames == 4:
		var sync = p.get_node("Sync")
		var ok: bool = sync.replication_config.has_property(^":hat_override")
		p.hat_override = "kochmuetze"   # wie vom Synchronizer gesetzt
		p._process(0.016)
		var hat = p.look.get_node_or_null("Hat")
		ok = ok and hat != null and str(hat.get_meta("hat_id", "")) == "kochmuetze"
		p.hat_override = ""
		p._process(0.016)
		hat = p.look.get_node_or_null("Hat")
		var role_hat: String = load("res://player_look.gd").HATS.get(p.role, "")
		ok = ok and (hat == null if role_hat == "" else str(hat.get_meta("hat_id", "")) == role_hat)
		p.hat_override = "x".repeat(40)   # unsinniger Netzwert
		p._process(0.016)
		ok = ok and p.hat_override == ""
		var A = load("res://achievements.gd")
		var ach = A.new()
		ach.path = "user://test_journal.json"
		ach.count("spot", 12)
		ach.record_night(1, 3, 40, 12)
		var jt: String = ach.journal_text()
		ok = ok and "✓ Erste Schritte" in jt and "[12/500]" in jt and "Nacht 1: 3 Sterne" in jt and "Tagebuch" in jt
		var pz = load("res://pause.gd").new()
		pz.achievements = ach
		root.add_child(pz)
		pz.toggle_journal()
		ok = ok and pz.journal_label.visible and "Erste Schritte" in pz.journal_label.text
		pz.toggle_journal()
		ok = ok and not pz.journal_label.visible
		print("TEST_HAT_SYNC OK" if ok else "TEST_HAT_SYNC FAIL")
		quit(0 if ok else 1)
	return false
