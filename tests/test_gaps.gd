extends SceneTree
## Test M-11: Fähigkeiten "Fester Griff" (climb) und "Lange Leiter" (ladder_time) wirken, Wiederbeleben gibt XP,
## GameState.stars_cleaned zählt einen Stern pro Nacht nur einmal.
var frames := 0

func _initialize() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "jump", "clean", "attack"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

func _process(_d: float) -> bool:
	frames += 1
	if frames != 3:
		return false
	var ok := true
	var gs = root.get_node("GameState")
	var P = load("res://player.gd")
	var p = P.new()
	p.name = "1"
	root.add_child(p)
	p.role = "kletterer"
	p.skills.role = "kletterer"
	var base_life: float = p.ladder_lifetime()
	var base_climb: float = p.mod("climb")
	p.skills.levels["kletterer_leiter"] = 2
	p.skills.levels["kletterer_griff"] = 1
	ok = ok and is_equal_approx(p.ladder_lifetime(), base_life + 4.0)
	ok = ok and p.mod("climb") > base_climb * 1.15
	# Leiter übernimmt die Standzeit
	p.rpc_place_ladder(Vector3(0, 0, 3), 0.0, p.ladder_lifetime())
	var lad = root.get_tree().get_nodes_in_group("ladders")
	ok = ok and lad.size() == 1 and is_equal_approx(lad[0].left, base_life + 4.0)
	# Wiederbeleben gibt XP
	var q = P.new()
	q.name = "2"
	root.add_child(q)
	q.global_position = p.global_position + Vector3(1, 0, 0)
	q.set_multiplayer_authority(1)
	q.downed = true
	var xp_before: int = p.xp.xp
	var done := false
	for i in 400:
		if p.update_revive(0.02, true):
			done = true
			break
	ok = ok and done and p.xp.xp - xp_before == 40
	# Stern zählt pro Nacht nur einmal
	gs.start_night()
	var star := Node.new()
	root.add_child(star)
	gs.report_star_cleaned(star)
	gs.report_star_cleaned(star)
	var other := Node.new()
	root.add_child(other)
	gs.report_star_cleaned(other)
	ok = ok and gs.stars_cleaned == 2
	gs.start_night()
	ok = ok and gs.stars_cleaned == 0
	gs.report_star_cleaned(star)
	ok = ok and gs.stars_cleaned == 1
	print("TEST_GAPS OK" if ok else "TEST_GAPS FAIL life=%.1f climb=%.2f xp=%d stars=%d" % [p.ladder_lifetime(), p.mod("climb"), p.xp.xp - xp_before, gs.stars_cleaned])
	quit(0 if ok else 1)
	return false
