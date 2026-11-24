extends SceneTree
## Test M-08: Trampolin gibt Sprungboost, Wunsch gibt Buff, Schwarm zeigt auf den nächsten schmutzigen Stern.
var frames := 0
var main
func _process(_d: float) -> bool:
	frames += 1
	if frames == 2:
		var menu = load("res://menu.gd")
		menu.launch = {"mode": "solo", "name": "Tester", "preset": "standard"}
		main = load("res://main.gd").new()
		root.add_child(main)
		return false
	if frames < 6:
		return false
	var ok := true
	var F = load("res://fun_items.gd")
	var p = main.player
	ok = ok and p != null and main._trampolines.size() > 0 and main.swarm != null
	var tr = main._trampolines[0]
	p.velocity = Vector3.ZERO
	ok = ok and tr.bounce(p) and p.velocity.y >= F.BOOST - 0.01
	ok = ok and not tr.bounce(p)   # Abklingzeit
	# Wunsch
	main.world.kitchen.buffs.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var stat: String = F.grant_wish(p, rng)
	ok = ok and F.WISH_STATS.has(stat) and is_equal_approx(main.world.kitchen.buff_mult(stat), 1.2)
	var w = F.WishStar.new()
	main.world.add_child(w)
	ok = ok and w.catch(p)
	# Schwarm zeigt auf den nächsten schmutzigen Stern
	for s in main.world.stars:
		s.is_clean = false
	var near = F.nearest_dirty_star(main.world.stars, p.global_position)
	ok = ok and near != null
	main.swarm.update_swarm(p.global_position, main.world.stars, 0.1)
	ok = ok and main.swarm.visible and main.swarm.target == near and main.swarm.direction_to_target(p.global_position).length() > 0.9
	for s in main.world.stars:
		s.is_clean = true
	main.swarm.update_swarm(p.global_position, main.world.stars, 0.1)
	ok = ok and not main.swarm.visible
	# Trampolin-Plätze aus Sternhöhen
	ok = ok and F.trampoline_spots([Vector3(10, 6, 0), Vector3(0, 3, 0)]).size() == 1
	print("TEST_FUN OK" if ok else "TEST_FUN FAIL")
	quit(0 if ok else 1)
	return true
