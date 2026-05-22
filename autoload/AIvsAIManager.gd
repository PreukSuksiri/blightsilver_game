extends Node
## AIvsAIManager — autoload that persists config and battle log across scene changes
## for the AI vs AI debug mode.

signal log_written(line: String)

const DeckData = preload("res://resources/DeckData.gd")

# ── Config (set by AIvsAIConfig before launching the game board) ──────────────
var deck0: Variant = null                 # player 0's deck (DeckData or null)
var deck1: Variant = null                 # player 1's deck (DeckData or null)
var forced_cells_0: Array = []            # Array[Dictionary{card_name, row, col}]
var forced_cells_1: Array = []            # Array[Dictionary{card_name, row, col}]

# ── Log state ─────────────────────────────────────────────────────────────────
var _log_lines: Array[String] = []
var _file: FileAccess = null
var _match_start_msec: int = 0
var _file_path: String = ""
var _active: bool = false                 # true while a match is in progress
var _prev_crystals: Array[int] = [0, 0]  # snapshot for delta computation

# ── Internal: connections to game signals ─────────────────────────────────────
var _board_ref: Node = null
var _tm_ref: Node = null                  # TurnManager
var _ai0_ref: Node = null                 # AIPlayer for player 0 (AI_VS_AI only)
var _ai1_ref: Node = null                 # AIPlayer for player 1

# ─────────────────────────────────────────────────────────────────────────────
func configure(d0: Variant, fc0: Array, d1: Variant, fc1: Array) -> void:
	deck0 = d0
	deck1 = d1
	forced_cells_0 = fc0.duplicate(true)
	forced_cells_1 = fc1.duplicate(true)

func get_log_text() -> String:
	return "\n".join(PackedStringArray(_log_lines))

func is_active() -> bool:
	return _active

# Called by GameBoard._ready() in AI_VS_AI mode after turn_manager is created.
func start_logging(board: Node) -> void:
	_board_ref = board
	_tm_ref    = board.turn_manager
	_active    = true
	_match_start_msec = Time.get_ticks_msec()

	# Open log file
	_ensure_log_dir()
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	_file_path = "res://logs/ai_vs_ai_%04d-%02d-%02d_%02d-%02d-%02d.txt" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"], dt["second"]
	]
	_file = FileAccess.open(_file_path, FileAccess.WRITE)

	# Write header
	var d0_name: String = deck0.deck_name if deck0 != null else "(random pool)"
	var d1_name: String = deck1.deck_name if deck1 != null else "(random pool)"
	var fc0_str: String = _format_forced(forced_cells_0)
	var fc1_str: String = _format_forced(forced_cells_1)
	_raw("=== AI vs AI Match ===")
	_raw("Started:  %04d-%02d-%02d %02d:%02d:%02d" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"], dt["second"]])
	_raw("AI-0 Deck:    " + d0_name)
	_raw("AI-1 Deck:    " + d1_name)
	_raw("AI-0 Forced:  " + fc0_str)
	_raw("AI-1 Forced:  " + fc1_str)
	_raw("===")
	_raw("")

	# Initialise crystal snapshot for delta tracking
	_prev_crystals[0] = GameState.crystals[0]
	_prev_crystals[1] = GameState.crystals[1]

	# Log initial grid state (setup happened before this call, so we scan retroactively)
	_log_initial_grid()

	# Connect signals
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.game_over.connect(_on_game_over_signal)
	GameState.card_placed.connect(_on_card_placed)
	GameState.card_destroyed.connect(_on_card_destroyed)
	GameState.card_revealed.connect(_on_card_revealed)
	GameState.crystals_changed.connect(_on_crystals_changed)
	GameState.turn_changed.connect(_on_turn_changed)
	_tm_ref.attack_completed.connect(_on_attack_completed)
	_tm_ref.tech_played.connect(_on_tech_played)
	_tm_ref.turn_ended.connect(_on_turn_ended)
	_tm_ref.coin_flip_visual_requested.connect(_on_coin_flip)
	_tm_ref.awaiting_trap_choice.connect(_on_choice_prompt)
	_tm_ref.awaiting_defender_choice.connect(_on_defender_choice_prompt)
	_tm_ref.awaiting_target_selection.connect(_on_target_prompt)

	# AI player signals (decisions made before execution)
	_ai0_ref = _board_ref.ai_player_0
	_ai1_ref = _board_ref.ai_player
	if _ai0_ref != null:
		_ai0_ref.ai_attack_chosen.connect(_on_ai0_attack_chosen)
		_ai0_ref.ai_target_chosen.connect(_on_ai0_target_chosen)
		_ai0_ref.ai_trap_choice.connect(_on_ai0_trap_choice)
	if _ai1_ref != null:
		_ai1_ref.ai_attack_chosen.connect(_on_ai1_attack_chosen)
		_ai1_ref.ai_target_chosen.connect(_on_ai1_target_chosen)
		_ai1_ref.ai_trap_choice.connect(_on_ai1_trap_choice)

func on_game_over(winner: int) -> void:
	# Called by GameBoard._on_game_over() in AI_VS_AI mode
	var result_str: String
	match winner:
		-1: result_str = "Tie"
		0:  result_str = "AI Player 0 wins"
		1:  result_str = "AI Player 1 wins"
		_:  result_str = "Unknown"
	_raw("")
	_raw("=== GAME OVER ===")
	log_event(result_str)
	var c0: int = GameState.crystals[0]
	var c1: int = GameState.crystals[1]
	log_event("Final crystals — P0: %d  P1: %d  |  Turns: %d" % [c0, c1, GameState.turn_number])
	log_event("Log saved to: " + _file_path)
	_cleanup()
	# Return to config scene
	get_tree().change_scene_to_file("res://scenes/ai_vs_ai_config.tscn")

func log_event(msg: String) -> void:
	var elapsed_ms: int = Time.get_ticks_msec() - _match_start_msec
	var s: int   = elapsed_ms / 1000
	var ms: int  = elapsed_ms % 1000
	var min_: int = s / 60
	s = s % 60
	var line: String = "[%02d:%02d.%03d] %s" % [min_, s, ms, msg]
	_log_lines.append(line)
	if _file != null:
		_file.store_line(line)
	emit_signal("log_written", line)

# ── Private helpers ───────────────────────────────────────────────────────────
func _raw(text: String) -> void:
	_log_lines.append(text)
	if _file != null:
		_file.store_line(text)

func _ensure_log_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://logs"))

func _format_forced(fc: Array) -> String:
	if fc.is_empty():
		return "none"
	var parts: Array[String] = []
	for d: Variant in fc:
		if d is Dictionary:
			parts.append("(%d,%d) %s" % [int(d.get("row", 0)), int(d.get("col", 0)), str(d.get("card_name", "?"))])
	return ", ".join(PackedStringArray(parts))

func _cleanup() -> void:
	_active = false
	if _file != null:
		_file.close()
		_file = null
	_disconnect_all()

func _disconnect_all() -> void:
	if GameState.phase_changed.is_connected(_on_phase_changed):
		GameState.phase_changed.disconnect(_on_phase_changed)
	if GameState.game_over.is_connected(_on_game_over_signal):
		GameState.game_over.disconnect(_on_game_over_signal)
	if GameState.card_placed.is_connected(_on_card_placed):
		GameState.card_placed.disconnect(_on_card_placed)
	if GameState.card_destroyed.is_connected(_on_card_destroyed):
		GameState.card_destroyed.disconnect(_on_card_destroyed)
	if GameState.card_revealed.is_connected(_on_card_revealed):
		GameState.card_revealed.disconnect(_on_card_revealed)
	if GameState.crystals_changed.is_connected(_on_crystals_changed):
		GameState.crystals_changed.disconnect(_on_crystals_changed)
	if GameState.turn_changed.is_connected(_on_turn_changed):
		GameState.turn_changed.disconnect(_on_turn_changed)
	if _tm_ref != null:
		if _tm_ref.attack_completed.is_connected(_on_attack_completed):
			_tm_ref.attack_completed.disconnect(_on_attack_completed)
		if _tm_ref.tech_played.is_connected(_on_tech_played):
			_tm_ref.tech_played.disconnect(_on_tech_played)
		if _tm_ref.turn_ended.is_connected(_on_turn_ended):
			_tm_ref.turn_ended.disconnect(_on_turn_ended)
		if _tm_ref.coin_flip_visual_requested.is_connected(_on_coin_flip):
			_tm_ref.coin_flip_visual_requested.disconnect(_on_coin_flip)
		if _tm_ref.awaiting_trap_choice.is_connected(_on_choice_prompt):
			_tm_ref.awaiting_trap_choice.disconnect(_on_choice_prompt)
		if _tm_ref.awaiting_defender_choice.is_connected(_on_defender_choice_prompt):
			_tm_ref.awaiting_defender_choice.disconnect(_on_defender_choice_prompt)
		if _tm_ref.awaiting_target_selection.is_connected(_on_target_prompt):
			_tm_ref.awaiting_target_selection.disconnect(_on_target_prompt)
	if _ai0_ref != null:
		if _ai0_ref.ai_attack_chosen.is_connected(_on_ai0_attack_chosen):
			_ai0_ref.ai_attack_chosen.disconnect(_on_ai0_attack_chosen)
		if _ai0_ref.ai_target_chosen.is_connected(_on_ai0_target_chosen):
			_ai0_ref.ai_target_chosen.disconnect(_on_ai0_target_chosen)
		if _ai0_ref.ai_trap_choice.is_connected(_on_ai0_trap_choice):
			_ai0_ref.ai_trap_choice.disconnect(_on_ai0_trap_choice)
	if _ai1_ref != null:
		if _ai1_ref.ai_attack_chosen.is_connected(_on_ai1_attack_chosen):
			_ai1_ref.ai_attack_chosen.disconnect(_on_ai1_attack_chosen)
		if _ai1_ref.ai_target_chosen.is_connected(_on_ai1_target_chosen):
			_ai1_ref.ai_target_chosen.disconnect(_on_ai1_target_chosen)
		if _ai1_ref.ai_trap_choice.is_connected(_on_ai1_trap_choice):
			_ai1_ref.ai_trap_choice.disconnect(_on_ai1_trap_choice)
	_tm_ref = null
	_ai0_ref = null
	_ai1_ref = null
	_board_ref = null

# ── Signal handlers ───────────────────────────────────────────────────────────

## Turn header — fires exactly once per turn when current_player changes.
func _on_turn_changed(player: int) -> void:
	var c0: int = GameState.crystals[0]
	var c1: int = GameState.crystals[1]
	_raw("")
	_raw("--- Turn %d  |  Player %d  |  Crystals P0=%d P1=%d ---" % [
		GameState.turn_number, player, c0, c1])
	_log_board_snapshot()
	# Re-sync crystal snapshot so the first delta of the turn is relative to turn start
	_prev_crystals[0] = c0
	_prev_crystals[1] = c1

func _log_initial_grid() -> void:
	_raw("")
	_raw("--- Initial Setup (server-side view) ---")
	# Log AI personalities so behavior is interpretable during audit
	if _ai0_ref != null:
		_raw("AI-0 Personality:  DEF=%s  OFF=%s  SOC=%s" % [
			_ai0_ref.personality_defensive,
			_ai0_ref.personality_offensive,
			_ai0_ref.personality_social])
	if _ai1_ref != null:
		_raw("AI-1 Personality:  DEF=%s  OFF=%s  SOC=%s" % [
			_ai1_ref.personality_defensive,
			_ai1_ref.personality_offensive,
			_ai1_ref.personality_social])
	# Log tech hands
	for p: int in [0, 1]:
		var hand: Array = GameState.tech_hands[p]
		if hand.is_empty():
			_raw("P%d Tech hand: (none)" % p)
		else:
			_raw("P%d Tech hand: %s" % [p, ", ".join(PackedStringArray(hand))])
	for p: int in [0, 1]:
		var lines: Array[String] = []
		for r: int in range(GameState.GRID_SIZE):
			var cells: Array[String] = []
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if card.card_type == "dead_end":
					cells.append("[  — ]")
				else:
					var label: String = card.card_name.left(4) if not card.card_name.is_empty() else "???"
					var type_tag: String = "C" if card.card_type == "character" else "T"
					cells.append("[%s:%-4s]" % [type_tag, label])
			lines.append("  " + "".join(PackedStringArray(cells)))
		_raw("P%d: %s" % [p, lines[0]])
		for i: int in range(1, lines.size()):
			_raw("    " + lines[i])
	_raw("")

func _log_board_snapshot() -> void:
	for p: int in [0, 1]:
		var lines: Array[String] = []
		for r: int in range(GameState.GRID_SIZE):
			var cells: Array[String] = []
			for c: int in range(GameState.GRID_SIZE):
				var card: GameState.CardInstance = GameState.get_card(p, r, c)
				if card.card_type == "dead_end":
					cells.append("[  — ]")
				elif card.face_up:
					cells.append("[%-4s]" % card.card_name.left(4))
				else:
					cells.append("[  ? ]")
			lines.append("  " + "".join(PackedStringArray(cells)))
		_raw("P%d: %s" % [p, lines[0]])
		for i: int in range(1, lines.size()):
			_raw("    " + lines[i])

## Crystal delta — fires on every lose_crystals / gain_crystals call.
func _on_crystals_changed(player: int, new_amount: int, reason: String = "") -> void:
	var delta: int = new_amount - _prev_crystals[player]
	if delta == 0:
		_prev_crystals[player] = new_amount
		return
	var sign: String = "+" if delta >= 0 else ""
	var reason_tag: String = "  [%s]" % reason if not reason.is_empty() else ""
	log_event("Crystals: P%d %d → %d (%s%d)%s" % [
		player, _prev_crystals[player], new_amount, sign, delta, reason_tag])
	_prev_crystals[player] = new_amount

func _on_phase_changed(_phase: GameState.Phase) -> void:
	pass  # Turn header is now handled by _on_turn_changed; nothing else needs logging here.

func _on_attack_completed(attacker_pos: Vector2i, target_pos: Vector2i,
		result: BattleResolver.BattleResult) -> void:
	var atk_player: int = GameState.current_player
	var def_player: int = GameState.get_opponent(atk_player)

	# Trap encounter — log trap name instead of misleading ATK=0 DEF=0 TIE
	if result.special_trigger == "trap_effect":
		var trap: Variant = result.special_params.get("trap_data", null)
		var tname: String = trap.card_name if trap != null else "?"
		log_event("Trap: \"%s\" triggered  P%d(%d,%d)→P%d(%d,%d)" % [
			tname,
			atk_player, attacker_pos.x, attacker_pos.y,
			def_player, target_pos.x, target_pos.y])
		return

	var atk_card: GameState.CardInstance = GameState.get_card(atk_player, attacker_pos.x, attacker_pos.y)
	var def_card: GameState.CardInstance = GameState.get_card(def_player, target_pos.x, target_pos.y)
	# Card name may be empty if the card was destroyed during battle (slot became dead_end).
	# Use the result flags to produce a meaningful fallback.
	var a_name: String
	if atk_card != null and not atk_card.card_name.is_empty():
		a_name = atk_card.card_name
	elif result.attacker_destroyed:
		a_name = "(self-destroyed)"
	else:
		a_name = "?"
	var d_name: String
	if def_card != null and not def_card.card_name.is_empty():
		d_name = def_card.card_name
	elif result.defender_destroyed:
		d_name = "(destroyed)"
	else:
		d_name = "(dead-end)"
	var outcome: String
	if result.defender_destroyed and not result.attacker_destroyed:
		outcome = "WIN"
	elif result.attacker_destroyed and not result.defender_destroyed:
		outcome = "LOSE"
	else:
		outcome = "TIE"
	log_event("Attack P%d(%d,%d)\"%s\" → P%d(%d,%d)\"%s\"  Dice=%d  ATK=%d vs DEF=%d  → %s" % [
		atk_player, attacker_pos.x, attacker_pos.y, a_name,
		def_player, target_pos.x, target_pos.y, d_name,
		GameState.dice_result,
		result.attacker_atk_used,
		result.defender_def_used,
		outcome
	])

func _on_tech_played(player_index: int, tech_name: String) -> void:
	log_event("Tech played  P%d: \"%s\"" % [player_index, tech_name])

func _on_turn_ended(player_index: int) -> void:
	log_event("Turn ended  P%d  |  Crystals P0=%d P1=%d" % [
		player_index, GameState.crystals[0], GameState.crystals[1]])

func _on_card_destroyed(player_index: int, row: int, col: int) -> void:
	log_event("Card destroyed  P%d (%d,%d)" % [player_index, row, col])

func _on_coin_flip(results: Array) -> void:
	var strs: Array[String] = []
	for r: Variant in results:
		strs.append("Heads" if r else "Tails")
	log_event("Coin flip: " + ", ".join(PackedStringArray(strs)))

func _on_game_over_signal(_winner: int) -> void:
	# GameBoard handles this directly via on_game_over(); do nothing here
	pass

func _on_card_placed(player: int, row: int, col: int) -> void:
	var card: GameState.CardInstance = GameState.get_card(player, row, col)
	log_event("Placed: P%d (%d,%d) \"%s\" [%s]" % [player, row, col, card.card_name, card.card_type])

func _on_card_revealed(player: int, row: int, col: int) -> void:
	var card: GameState.CardInstance = GameState.get_card(player, row, col)
	if card.card_name.is_empty():
		return  # dead-end or blank slot — not a real reveal
	log_event("Revealed: P%d (%d,%d) \"%s\"" % [player, row, col, card.card_name])

# ── Prompt / choice logging ───────────────────────────────────────────────────

func _on_choice_prompt(prompt: String, choices: Array) -> void:
	var opts: String = " / ".join(PackedStringArray(choices.map(func(s: Variant) -> String: return str(s))))
	log_event("Prompt: \"%s\"  [%s]" % [prompt, opts])

func _on_defender_choice_prompt(prompt: String, choices: Array) -> void:
	var opts: String = " / ".join(PackedStringArray(choices.map(func(s: Variant) -> String: return str(s))))
	log_event("Defender prompt: \"%s\"  [%s]" % [prompt, opts])

func _on_target_prompt(prompt: String, filter: String) -> void:
	log_event("Target prompt: \"%s\"  filter=%s" % [prompt, filter])

# ── AI decision logging ───────────────────────────────────────────────────────

func _on_ai0_attack_chosen(attacker: Vector2i, target: Vector2i) -> void:
	var a_card: GameState.CardInstance = GameState.get_card(0, attacker.x, attacker.y)
	var t_card: GameState.CardInstance = GameState.get_card(1, target.x, target.y)
	var t_info: String = "\"%s\" [DEF=%d]" % [t_card.card_name, t_card.get_effective_def()] \
		if t_card.card_type != "dead_end" else "\"(dead-end)\""
	log_event("AI0 attack decision: (%d,%d)\"%s\" [ATK=%d] → (%d,%d) %s" % [
		attacker.x, attacker.y, a_card.card_name, a_card.get_effective_atk(),
		target.x, target.y, t_info])

func _on_ai1_attack_chosen(attacker: Vector2i, target: Vector2i) -> void:
	var a_card: GameState.CardInstance = GameState.get_card(1, attacker.x, attacker.y)
	var t_card: GameState.CardInstance = GameState.get_card(0, target.x, target.y)
	var t_info: String = "\"%s\" [DEF=%d]" % [t_card.card_name, t_card.get_effective_def()] \
		if t_card.card_type != "dead_end" else "\"(dead-end)\""
	log_event("AI1 attack decision: (%d,%d)\"%s\" [ATK=%d] → (%d,%d) %s" % [
		attacker.x, attacker.y, a_card.card_name, a_card.get_effective_atk(),
		target.x, target.y, t_info])

func _on_ai0_target_chosen(pos: Vector2i) -> void:
	log_event("AI0 target chosen: (%d,%d)" % [pos.x, pos.y])

func _on_ai1_target_chosen(pos: Vector2i) -> void:
	log_event("AI1 target chosen: (%d,%d)" % [pos.x, pos.y])

func _on_ai0_trap_choice(choice_index: int) -> void:
	log_event("AI0 choice: %d" % choice_index)

func _on_ai1_trap_choice(choice_index: int) -> void:
	log_event("AI1 choice: %d" % choice_index)
