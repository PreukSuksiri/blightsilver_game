extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var msgs: PackedStringArray = PackedStringArray()
	var db: Node = root.get_node_or_null("OmenDatabase")
	var em: Node = root.get_node_or_null("ExplorationManager")
	var gs: Node = root.get_node_or_null("GameState")
	var applier = load("res://scripts/OmenBattleApplier.gd")

	var all: Array = db.call("get_all_omens")
	msgs.append("catalog=%d" % all.size())
	var impl := 0
	for o in all:
		if bool(o.get("implemented", false)):
			impl += 1
	msgs.append("implemented=%d" % impl)

	# Anoint eligibility
	var deck := [
		{"name": "Dummy", "type": "unit", "affinity": "NATURE", "cost": 2, "atk": 10, "def": 10, "ability_none": false},
		{"name": "TrapA", "type": "trap", "affinity": "", "cost": 1, "atk": 0, "def": 0, "ability_none": false},
	]
	var anoint_ids: Array = []
	for o in all:
		if db.call("is_anoint", o) and bool(o.get("implemented", false)):
			anoint_ids.append(str(o.get("id")))
			if anoint_ids.size() >= 5:
				break
	msgs.append("sample anoint ids=%s" % str(anoint_ids))

	em.call("add_omen", "rune_berkano", "")
	em.call("add_omen", "rune_uruz", "")
	applier.prepare_from_exploration()
	applier.apply_pre_battle_crystal_and_flags()
	# Setup place berkano
	gs.call("new_game", gs.get("GameMode").VS_AI if false else 0)
	# new_game may clear omens — re-prepare
	applier.prepare_from_exploration()
	applier.apply_setup_runes()
	var setup_count := 0
	for r in range(4):
		for c in range(4):
			if str(applier.get_cell_rune(0, r, c)) != "":
				setup_count += 1
	msgs.append("setup runes placed=%d" % setup_count)
	if setup_count < 1:
		ok = false

	# Place a character then begin-game runes
	# Use GameState place if available
	if gs.has_method("place_character"):
		gs.call("place_character", 0, 0, 0, "Dummy")
	applier.apply_begin_game(null)
	var begin_count := 0
	for r in range(4):
		for c in range(4):
			var rid: String = str(applier.get_cell_rune(0, r, c))
			if rid != "":
				begin_count += 1
	msgs.append("total runes after begin=%d" % begin_count)

	# Options/list helpers
	var list_panel = load("res://scripts/OmenListPanel.gd")
	var host := Control.new()
	root.add_child(host)
	var box := VBoxContainer.new()
	host.add_child(box)
	list_panel.build_list(box, em.call("get_active_omens"))
	msgs.append("list children=%d" % box.get_child_count())

	# QuickDuel clear pattern
	applier.clear()
	if (gs.get("active_omens") as Array).size() != 0:
		ok = false
		msgs.append("clear failed")
	if (em.call("get_held_omen_ids") as Array).is_empty():
		ok = false
		msgs.append("exploration cleared by battle clear")
	else:
		msgs.append("exploration persisted")

	print("OMEN_SMOKE " + ("PASS" if ok else "FAIL"))
	for m in msgs:
		print("  - ", m)
	quit(0 if ok else 1)
