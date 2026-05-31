extends Node
## AIvsAIManager — autoload that persists config and battle log across scene changes
## for the AI vs AI debug mode.

signal log_written(line: String)

const DeckData = preload("res://resources/DeckData.gd")
const MAX_BATCH_ITERATIONS: int = 20

# ── Config (set by AIvsAIConfig before launching the game board) ──────────────
var deck0: Variant = null                 # player 0's deck (DeckData or null)
var deck1: Variant = null                 # player 1's deck (DeckData or null)
var forced_cells_0: Array = []            # Array[Dictionary{card_name, row, col}]
var forced_cells_1: Array = []            # Array[Dictionary{card_name, row, col}]
var forced_tech_0: Array = []             # Array[String] — up to 3 tech names (empty = random fill)
var forced_tech_1: Array = []             # Array[String]

# ── Batch run (auto-iterate AI vs AI) ─────────────────────────────────────────
var batch_total: int = 1
var batch_completed: int = 0
var batch_running: bool = false
var _batch_summary_lines: Array[String] = []

# ── Log state ─────────────────────────────────────────────────────────────────
var _log_lines: Array[String] = []
var _file: FileAccess = null
var _match_start_msec: int = 0
var _file_path: String = ""
var _active: bool = false                 # true while a match is in progress
var _prev_crystals: Array[int] = [0, 0]  # snapshot for delta computation
var _logged_destroy_slots: Dictionary = {}  # "p:r:c" keys — avoids duplicate destroy lines
var _pending_game_over_winner: int = -999  # deferred until attack log flushes

# ── Internal: connections to game signals ─────────────────────────────────────
var _board_ref: Node = null
var _tm_ref: Node = null                  # TurnManager
var _ai0_ref: Node = null                 # AIPlayer for player 0 (AI_VS_AI only)
var _ai1_ref: Node = null                 # AIPlayer for player 1

# ─────────────────────────────────────────────────────────────────────────────
func configure(d0: Variant, fc0: Array, d1: Variant, fc1: Array,
		ft0: Array = [], ft1: Array = []) -> void:
	deck0 = d0
	deck1 = d1
	forced_cells_0 = fc0.duplicate(true)
	forced_cells_1 = fc1.duplicate(true)
	forced_tech_0 = ft0.duplicate(true)
	forced_tech_1 = ft1.duplicate(true)


func start_batch(iterations: int) -> void:
	batch_total = clampi(iterations, 1, MAX_BATCH_ITERATIONS)
	batch_completed = 0
	batch_running = batch_total > 1
	_batch_summary_lines.clear()
	if batch_total > 1:
		_log_lines.clear()


func get_batch_progress_text() -> String:
	if batch_total <= 1:
		return ""
	return "Batch %d / %d" % [mini(batch_completed + 1, batch_total), batch_total]


func launch_battle() -> void:
	GameState.game_mode                  = GameState.GameMode.AI_VS_AI
	GameState.battle_player_forced_cells = forced_cells_0.duplicate(true)
	GameState.battle_ai_forced_cells     = forced_cells_1.duplicate(true)
	GameState.battle_player_deck         = deck0
	GameState.battle_ai_deck             = deck1
	get_tree().change_scene_to_file("res://scenes/game_board.tscn")

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
	_logged_destroy_slots.clear()
	_pending_game_over_winner = -999

	if batch_running and batch_completed > 0:
		_log_lines.clear()

	# Open log file
	_ensure_log_dir()
	var mode_tag: String = "card_e2e" if CardE2ERunner.is_active() else "ai_vs_ai"
	var log_info: Dictionary = SessionLogNaming.begin_battle_log(mode_tag)
	_file_path = log_info["path"]
	_file = FileAccess.open(_file_path, FileAccess.WRITE)

	# Write header
	var d0_name: String = deck0.deck_name if deck0 != null else "(random pool)"
	var d1_name: String = deck1.deck_name if deck1 != null else "(random pool)"
	var fc0_str: String = _format_forced(forced_cells_0)
	var fc1_str: String = _format_forced(forced_cells_1)
	var ft0_str: String = _format_forced_tech(forced_tech_0)
	var ft1_str: String = _format_forced_tech(forced_tech_1)
	_raw("=== %s ===" % log_info["battle_display_name"])
	_raw("Battle started: %s" % log_info["battle_started_at"])
	_raw("%s (started %s)" % [log_info["session_display_name"], log_info["session_started_at"]])
	if CardE2ERunner.is_active():
		for line: String in CardE2ERunner.build_scenario_log_header():
			_raw(line)
		_raw("")
	_raw("=== AI vs AI Match ===")
	if batch_total > 1:
		_raw("Batch iteration: %d / %d" % [batch_completed + 1, batch_total])
	_raw("AI-0 Deck:    " + d0_name)
	_raw("AI-1 Deck:    " + d1_name)
	_raw("AI-0 Forced:  " + fc0_str)
	_raw("AI-1 Forced:  " + fc1_str)
	_raw("AI-0 Tech:    " + ft0_str)
	_raw("AI-1 Tech:    " + ft1_str)
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
	GameState.message_posted.connect(_on_message_posted)
	GameState.dice_rolled.connect(_on_dice_rolled)
	GameState.card_atk_changed.connect(_on_card_atk_changed)
	GameState.card_def_changed.connect(_on_card_def_changed)
	GameState.card_flag_added.connect(_on_card_flag_added)
	GameState.card_flag_removed.connect(_on_card_flag_removed)
	GameState.union_summoned.connect(_on_union_summoned)
	_tm_ref.attack_completed.connect(_on_attack_completed)
	_tm_ref.tech_played.connect(_on_tech_played)
	_tm_ref.turn_ended.connect(_on_turn_ended)
	_tm_ref.coin_flip_visual_requested.connect(_on_coin_flip)
	_tm_ref.awaiting_trap_choice.connect(_on_choice_prompt)
	_tm_ref.awaiting_defender_choice.connect(_on_defender_choice_prompt)
	_tm_ref.awaiting_target_selection.connect(_on_target_prompt)
	_tm_ref.ability_choice_resolved.connect(_on_ability_choice_resolved)
	_tm_ref.mode_selected.connect(_on_mode_selected)
	_tm_ref.attack_aborted.connect(_on_attack_aborted)
	_tm_ref.tech_resolved.connect(_on_tech_resolved)
	_tm_ref.ability_selection_done.connect(_on_ability_selection_done)
	_tm_ref.attack_phase_started.connect(_on_attack_phase_started)

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
	# Defer so TurnManager can emit attack_completed / card_destroyed for the killing blow.
	_pending_game_over_winner = winner
	call_deferred("_finish_game_over_log")

func _finish_game_over_log() -> void:
	if _pending_game_over_winner == -999:
		return
	var winner: int = _pending_game_over_winner
	_pending_game_over_winner = -999
	_write_game_over_log(winner)

func _write_game_over_log(winner: int) -> void:
	var result_str: String
	match winner:
		-1: result_str = "Tie"
		0:  result_str = "AI Player 0 wins"
		1:  result_str = "AI Player 1 wins"
		_:  result_str = "Unknown"
	_raw("")
	_raw("=== GAME OVER ===")
	log_event(result_str)
	if GameState.game_over_reason != "":
		log_event("Reason: %s" % GameState.game_over_reason)
	var c0: int = GameState.crystals[0]
	var c1: int = GameState.crystals[1]
	log_event("Final crystals — P0: %d  P1: %d  |  Turns: %d" % [c0, c1, GameState.turn_number])
	log_event("Log saved to: " + _file_path)

	batch_completed += 1
	if batch_total > 1:
		_batch_summary_lines.append("Battle %d/%d: %s  |  P0=%d P1=%d  |  %d turns" % [
			batch_completed, batch_total, result_str, c0, c1, GameState.turn_number])

	_cleanup()

	if CardE2ERunner.is_active():
		CardE2ERunner.on_battle_finished(_file_path, PackedStringArray(_log_lines))
		return

	if batch_running and batch_completed < batch_total:
		# Chain next battle without returning to config.
		call_deferred("launch_battle")
		return

	batch_running = false
	if batch_total > 1 and not _batch_summary_lines.is_empty():
		_write_batch_summary_file()
		var summary_header: PackedStringArray = PackedStringArray([
			"",
			"=== BATCH COMPLETE (%d battles) ===" % batch_completed,
		])
		summary_header.append_array(_batch_summary_lines)
		summary_header.append("===")
		summary_header.append("")
		for line: String in summary_header:
			_log_lines.append(line)

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


func _write_batch_summary_file() -> void:
	var path: String = "%s/batch_summary.txt" % SessionLogNaming.session_folder_path
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_line("=== AI vs AI Batch (%d battles) ===" % batch_completed)
	file.store_line("Completed: %s" % SessionLogNaming.session_started_at)
	for line: String in _batch_summary_lines:
		file.store_line(line)
	file.close()

func _format_forced(fc: Array) -> String:
	if fc.is_empty():
		return "none"
	var parts: Array[String] = []
	for d: Variant in fc:
		if d is Dictionary:
			parts.append("(%d,%d) %s" % [int(d.get("row", 0)), int(d.get("col", 0)), str(d.get("card_name", "?"))])
	return ", ".join(PackedStringArray(parts))

func _format_forced_tech(ft: Array) -> String:
	if ft.is_empty():
		return "random"
	var names: Array[String] = []
	for t: Variant in ft:
		var n: String = str(t).strip_edges()
		if not n.is_empty():
			names.append(n)
	if names.is_empty():
		return "random"
	return ", ".join(PackedStringArray(names))

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
	if GameState.message_posted.is_connected(_on_message_posted):
		GameState.message_posted.disconnect(_on_message_posted)
	if GameState.dice_rolled.is_connected(_on_dice_rolled):
		GameState.dice_rolled.disconnect(_on_dice_rolled)
	if GameState.card_atk_changed.is_connected(_on_card_atk_changed):
		GameState.card_atk_changed.disconnect(_on_card_atk_changed)
	if GameState.card_def_changed.is_connected(_on_card_def_changed):
		GameState.card_def_changed.disconnect(_on_card_def_changed)
	if GameState.card_flag_added.is_connected(_on_card_flag_added):
		GameState.card_flag_added.disconnect(_on_card_flag_added)
	if GameState.card_flag_removed.is_connected(_on_card_flag_removed):
		GameState.card_flag_removed.disconnect(_on_card_flag_removed)
	if GameState.union_summoned.is_connected(_on_union_summoned):
		GameState.union_summoned.disconnect(_on_union_summoned)
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
		if _tm_ref.ability_choice_resolved.is_connected(_on_ability_choice_resolved):
			_tm_ref.ability_choice_resolved.disconnect(_on_ability_choice_resolved)
		if _tm_ref.mode_selected.is_connected(_on_mode_selected):
			_tm_ref.mode_selected.disconnect(_on_mode_selected)
		if _tm_ref.attack_aborted.is_connected(_on_attack_aborted):
			_tm_ref.attack_aborted.disconnect(_on_attack_aborted)
		if _tm_ref.tech_resolved.is_connected(_on_tech_resolved):
			_tm_ref.tech_resolved.disconnect(_on_tech_resolved)
		if _tm_ref.ability_selection_done.is_connected(_on_ability_selection_done):
			_tm_ref.ability_selection_done.disconnect(_on_ability_selection_done)
		if _tm_ref.attack_phase_started.is_connected(_on_attack_phase_started):
			_tm_ref.attack_phase_started.disconnect(_on_attack_phase_started)
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

func _destroy_slot_key(player_index: int, row: int, col: int) -> String:
	return "%d:%d:%d" % [player_index, row, col]


func _log_card_destroyed_if_needed(player_index: int, row: int, col: int, card_label: String) -> void:
	if card_label.is_empty():
		return
	var key: String = _destroy_slot_key(player_index, row, col)
	if _logged_destroy_slots.has(key):
		return
	_logged_destroy_slots[key] = true
	log_event("Card destroyed  P%d (%d,%d) %s" % [player_index, row, col, card_label])


func _log_attack_resolution(attacker_pos: Vector2i, target_pos: Vector2i,
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
		# attacker_destroyed is NOT set by BattleResolver for traps — check effect_type directly
		var _destroys_attacker: bool = false
		if trap is TrapData:
			var td: TrapData = trap as TrapData
			_destroys_attacker = td.effect_type in [
				TrapData.TrapEffectType.DESTROY_ATTACKER,
				TrapData.TrapEffectType.DESTROY_ATTACKER_CHOICE_DESTROY,
				TrapData.TrapEffectType.DESTROY_ATTACKER_DEFENDER_PAYS,
			]
		if _destroys_attacker:
			log_event("Anim: 3E  △ P%d(%d,%d)" % [atk_player, attacker_pos.x, attacker_pos.y])
		else:
			log_event("Anim: 3D  (attacker survives)")
		return

	# Use names captured in BattleResult before destruction — reading from GameState here would
	# see a dead_end slot for any card that was destroyed during battle resolution.
	var a_name: String = BattleLogFormat.attack_side_label(result, true)
	var d_name: String = BattleLogFormat.attack_side_label(result, false)
	# Dead-end attack: defender had no card — log as DEAD_END
	if result.defender_name.is_empty() and not result.defender_destroyed:
		log_event("Attack P%d(%d,%d)%s → P%d(%d,%d)(empty)  Dice=%d  → DEAD_END" % [
			atk_player, attacker_pos.x, attacker_pos.y, a_name,
			def_player, target_pos.x, target_pos.y,
			GameState.dice_result])
		log_event("Anim: 3F  (blank slot)")
		return
	var outcome: String
	if result.defender_destroyed and not result.attacker_destroyed:
		outcome = "WIN"
	elif result.attacker_destroyed and not result.defender_destroyed:
		outcome = "LOSE"
	else:
		outcome = "TIE"
	log_event("Attack P%d(%d,%d)%s → P%d(%d,%d)%s  Dice=%d  ATK=%d vs DEF=%d  → %s" % [
		atk_player, attacker_pos.x, attacker_pos.y, a_name,
		def_player, target_pos.x, target_pos.y, d_name,
		GameState.dice_result,
		result.attacker_atk_used,
		result.defender_def_used,
		outcome
	])
	for overlay_line: String in BattleResolver.reckoning_overlay_log_lines(
			atk_player, def_player, result):
		log_event(overlay_line)
	# Animation scenario line — lets you audit which overlay animation fired
	var anim_line: String
	if result.attacker_destroyed and result.defender_destroyed:
		anim_line = "3C  △ P%d(%d,%d) + △ P%d(%d,%d)" % [
			atk_player, attacker_pos.x, attacker_pos.y,
			def_player, target_pos.x, target_pos.y]
	elif result.defender_destroyed:
		anim_line = "3A  △ P%d(%d,%d)" % [def_player, target_pos.x, target_pos.y]
	elif result.attacker_destroyed:
		anim_line = "3B  △ P%d(%d,%d)" % [atk_player, attacker_pos.x, attacker_pos.y]
	elif result.defender_name.is_empty():
		anim_line = "3F  (blank slot)"
	else:
		anim_line = "exchange  (no destruction)"
	log_event("Anim: " + anim_line)

	if result.attacker_destroyed:
		_log_card_destroyed_if_needed(
			atk_player, attacker_pos.x, attacker_pos.y, a_name)
	if result.defender_destroyed:
		_log_card_destroyed_if_needed(
			def_player, target_pos.x, target_pos.y, d_name)


func _on_attack_completed(attacker_pos: Vector2i, target_pos: Vector2i,
		result: BattleResolver.BattleResult) -> void:
	_log_attack_resolution(attacker_pos, target_pos, result)

func _on_tech_played(player_index: int, tech_name: String) -> void:
	log_event("Tech played  P%d: \"%s\"" % [player_index, tech_name])

func _on_turn_ended(player_index: int) -> void:
	log_event("Turn ended  P%d  |  Crystals P0=%d P1=%d" % [
		player_index, GameState.crystals[0], GameState.crystals[1]])

func _on_card_destroyed(player_index: int, row: int, col: int) -> void:
	# During battle, attack_completed logs destroys in order after the attack line.
	if GameState.current_phase == GameState.Phase.BATTLE:
		return
	# Signal fires before place_dead_end() clears the slot, so card name is still readable.
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	if card == null or card.card_type == "dead_end" or card.card_name.is_empty():
		log_event("Dead-end placed  P%d (%d,%d)" % [player_index, row, col])
	else:
		var key: String = _destroy_slot_key(player_index, row, col)
		if _logged_destroy_slots.has(key):
			return
		_logged_destroy_slots[key] = true
		log_event("Card destroyed  P%d (%d,%d) %s" % [
			player_index, row, col, BattleLogFormat.format_card(card)])

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
	log_event("Placed: P%d (%d,%d) %s [%s]" % [
		player, row, col, BattleLogFormat.format_card(card), card.card_type])

func _on_card_revealed(player: int, row: int, col: int) -> void:
	var card: GameState.CardInstance = GameState.get_card(player, row, col)
	if card.card_name.is_empty():
		if card.card_type == "dead_end":
			log_event("Revealed: P%d (%d,%d) (blank slot)" % [player, row, col])
		return
	log_event("Revealed: P%d (%d,%d) %s" % [player, row, col, BattleLogFormat.format_card(card)])

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
	if GameState.current_player != 0:
		return
	var a_card: GameState.CardInstance = GameState.get_card(0, attacker.x, attacker.y)
	if a_card.card_type != "character":
		return
	var t_card: GameState.CardInstance = GameState.get_card(1, target.x, target.y)
	var t_info: String = BattleLogFormat.format_card(t_card) \
		if t_card.card_type != "dead_end" else "(dead-end)"
	log_event("AI0 attack decision: (%d,%d)%s → (%d,%d) %s" % [
		attacker.x, attacker.y, BattleLogFormat.format_unit(a_card),
		target.x, target.y, t_info])

func _on_ai1_attack_chosen(attacker: Vector2i, target: Vector2i) -> void:
	if GameState.current_player != 1:
		return
	var a_card: GameState.CardInstance = GameState.get_card(1, attacker.x, attacker.y)
	if a_card.card_type != "character":
		return
	var t_card: GameState.CardInstance = GameState.get_card(0, target.x, target.y)
	var t_info: String = BattleLogFormat.format_card(t_card) \
		if t_card.card_type != "dead_end" else "(dead-end)"
	log_event("AI1 attack decision: (%d,%d)%s → (%d,%d) %s" % [
		attacker.x, attacker.y, BattleLogFormat.format_unit(a_card),
		target.x, target.y, t_info])

func _on_ai0_target_chosen(pos: Vector2i) -> void:
	log_event("AI0 target chosen: (%d,%d)" % [pos.x, pos.y])

func _on_ai1_target_chosen(pos: Vector2i) -> void:
	log_event("AI1 target chosen: (%d,%d)" % [pos.x, pos.y])

func _on_ai0_trap_choice(choice_index: int) -> void:
	log_event("AI0 choice: %d" % choice_index)

func _on_ai1_trap_choice(choice_index: int) -> void:
	log_event("AI1 choice: %d" % choice_index)

# ── Additional signal handlers ────────────────────────────────────────────────

## All post_message() calls — ability outcomes, tech effects, trap descriptions, etc.
## Redundant messages already captured by structured log entries are suppressed.
func _on_message_posted(text: String) -> void:
	# Suppress: turn banner (captured by turn header)
	if text.contains("'s turn — play a Tech"):
		return
	# Suppress: "Player X plays [tech]!" (captured by tech_played)
	if text.begins_with("Player ") and text.contains(" plays ") and text.ends_with("!"):
		return
	# Suppress: "Player X ends their turn." (captured by turn_ended)
	if text.begins_with("Player ") and text.contains("ends their turn"):
		return
	# Suppress: "X ATK N vs Y DEF N" battle comparison (captured by attack log)
	if text.contains(" ATK ") and text.contains(" vs ") and text.contains(" DEF "):
		return
	# Suppress: "X defends successfully!" (captured by attack log outcome)
	if text.ends_with(" defends successfully!"):
		return
	log_event("MSG: %s" % text)

## Dice roll result (fired by GameState after every roll).
func _on_dice_rolled(result: int) -> void:
	log_event("Dice rolled: %d" % result)

## ATK stat changed on a card (buff/debuff, ability effect, etc.).
func _on_card_atk_changed(player_index: int, row: int, col: int, old_val: int, new_val: int) -> void:
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	log_event("ATK changed P%d(%d,%d)%s: %d → %d" % [
		player_index, row, col, BattleLogFormat.format_card(card), old_val, new_val])

## DEF stat changed on a card.
func _on_card_def_changed(player_index: int, row: int, col: int, old_val: int, new_val: int) -> void:
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	log_event("DEF changed P%d(%d,%d)%s: %d → %d" % [
		player_index, row, col, BattleLogFormat.format_card(card), old_val, new_val])

## Yes/No ability choice resolved (Armored Dino, etc.).
func _on_ability_choice_resolved(choice_index: int) -> void:
	var label: String = "Yes" if choice_index == 0 else "No"
	log_event("Ability choice resolved: %d (%s)" % [choice_index, label])

## Attack was aborted (invalid target, already attacked, berserk block, etc.).
## The reason is captured by the MSG: line posted by post_message() just before the signal fires.
func _on_attack_aborted() -> void:
	log_event("Attack aborted")

## Tech effect fully resolved (async techs like Spy, Great Diplomacy, etc. complete here).
func _on_tech_resolved(player_index: int) -> void:
	log_event("Tech resolved  P%d" % player_index)

func _on_ability_selection_done() -> void:
	log_event("Ability target resolved  P%d" % GameState.current_player)

## Card flag added (mutagen, venom, berserk, etc.).
func _on_card_flag_added(player_index: int, row: int, col: int, flag: String) -> void:
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	log_event("Flag+ P%d(%d,%d)%s: %s" % [
		player_index, row, col, BattleLogFormat.format_card(card), flag])

## Card flag removed.
func _on_card_flag_removed(player_index: int, row: int, col: int, flag: String) -> void:
	var card: GameState.CardInstance = GameState.get_card(player_index, row, col)
	log_event("Flag- P%d(%d,%d)%s: %s" % [
		player_index, row, col, BattleLogFormat.format_card(card), flag])

## Union summoned — fires before crystal cost is paid.
func _on_union_summoned(player: int, union_label: String, material_labels: Array) -> void:
	log_event("Union summoned P%d: %s from %s" % [
		player, union_label, ", ".join(PackedStringArray(material_labels))])

## Attack phase started — shows how many attacks this player has this turn.
func _on_attack_phase_started(player_index: int, max_attacks: int) -> void:
	log_event("Attack phase P%d: %d attack(s) available" % [player_index, max_attacks])

## Turn mode selected (ATTACK / TECH / NONE).
func _on_mode_selected(player_index: int, mode: GameState.TurnMode) -> void:
	var mode_name: String
	match mode:
		GameState.TurnMode.ATTACK: mode_name = "ATTACK"
		GameState.TurnMode.TECH:   mode_name = "TECH"
		GameState.TurnMode.NONE:   mode_name = "NONE"
		_:                         mode_name = str(mode)
	log_event("Mode selected P%d: %s" % [player_index, mode_name])
