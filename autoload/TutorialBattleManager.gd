extends Node
# Autoload: TutorialBattleManager
# Manages tutorial duel state: mission lifecycle, overlay control, action reporting.

const DeckData = preload("res://resources/DeckData.gd")
const CONFIG_DIR := "res://data/tutorial_battles/"
const MISSION_PLAYER_TIMEOUT_SEC := 20.0

signal mission_started(instruction: String)
signal mission_complete
signal all_turn_missions_done
signal all_tutorial_missions_done
signal tutorial_complete

# ── Public state ──────────────────────────────────────────────
var is_prepared: bool = false   # config loaded, waiting for GameBoard
var is_active: bool = false     # GameBoard is live and tutorial is running
var config: Dictionary = {}

# ── Internal references ───────────────────────────────────────
var _game_board: Node = null
var _overlay: Node = null

# ── Turn / mission state ──────────────────────────────────────
var _player_turn_count: int = 0
var _last_tutorial_game_turn: int = -1  # skip mid-turn MODE_SELECT re-entries after attacks
var _mission_list: Array = []
var _mission_idx: int = 0
var _mission_step: int = 0  # 0 = step one, 1 = step two (attack/bluff/union/use_tech)
var _session_id: int = 0    # incremented whenever missions are reset; used to cancel stale awaits
var _pending_effect_resolve: bool = false
var _await_abort_reason: String = ""  # "", "timeout", "unavailable", "cancelled"
var _all_missions_complete: bool = false

# Internal signals used to communicate between report_action() and _run_missions()
signal _step_ready_sig
signal _mission_satisfied_sig

# ─────────────────────────────────────────────────────────────
# Launch API
# ─────────────────────────────────────────────────────────────

## Call from TutorialBattleBuilder before transitioning to game_board.tscn.
func prepare(cfg: Dictionary) -> void:
	config = cfg.duplicate(true)
	is_prepared = true
	is_active = false

## Load a tutorial config JSON from disk. Returns {} on failure.
func load_config_file(path: String) -> Dictionary:
	var trimmed: String = path.strip_edges()
	if trimmed.is_empty() or not FileAccess.file_exists(trimmed):
		return {}
	var fa := FileAccess.open(trimmed, FileAccess.READ)
	if fa == null:
		return {}
	var parsed: Variant = JSON.parse_string(fa.get_as_text())
	fa.close()
	return parsed as Dictionary if parsed is Dictionary else {}

## Load config from path, then configure battle. Returns "" on success.
func configure_battle_from_path(path: String, run_tutorial_missions: bool = true) -> String:
	var cfg := load_config_file(path)
	if cfg.is_empty():
		return "Could not load tutorial config: " + path.strip_edges()
	var err: String = _configure_battle_state_from_config(cfg)
	if not err.is_empty():
		return err
	if run_tutorial_missions:
		prepare(cfg)
	return ""

## Configure GameState + tutorial layer from a config dict. Returns "" on success.
func configure_battle_from_config(cfg: Dictionary) -> String:
	if cfg.is_empty():
		return "Tutorial config is empty."
	var err: String = _configure_battle_state_from_config(cfg)
	if not err.is_empty():
		return err
	prepare(cfg)
	return ""

func _configure_battle_state_from_config(cfg: Dictionary) -> String:
	if cfg.is_empty():
		return "Tutorial config is empty."

	var player_deck_dict: Dictionary = cfg.get("player_deck", {})
	var ai_deck_dict: Dictionary = cfg.get("ai_deck", {})

	var p_deck := DeckData.new()
	p_deck.deck_name = "Tutorial Player"
	p_deck.characters = (player_deck_dict.get("characters", []) as Array).duplicate()
	p_deck.traps = (player_deck_dict.get("traps", []) as Array).duplicate()
	p_deck.techs = (player_deck_dict.get("techs", []) as Array).duplicate()

	var ai_deck := DeckData.new()
	ai_deck.deck_name = "Tutorial AI"
	ai_deck.characters = (ai_deck_dict.get("characters", []) as Array).duplicate()
	ai_deck.traps = (ai_deck_dict.get("traps", []) as Array).duplicate()
	ai_deck.techs = (ai_deck_dict.get("techs", []) as Array).duplicate()

	if not p_deck.is_valid():
		return "Player deck invalid:\n" + p_deck.validation_message()
	if not ai_deck.is_valid():
		return "AI deck invalid:\n" + ai_deck.validation_message()

	GameState.game_mode = GameState.GameMode.VS_AI
	GameState._vn_battle_pending = true
	GameState.battle_player_deck = p_deck
	GameState.battle_player_forced_cells = (cfg.get("player_formation", []) as Array).duplicate(true)
	GameState.battle_ai_deck = ai_deck
	GameState.battle_ai_forced_cells = (cfg.get("ai_formation", []) as Array).duplicate(true)
	GameState.battle_ai_forced_tech = ai_deck.techs.duplicate()
	_apply_portraits_from_config(cfg)
	var p1n: String = str(cfg.get("player1_name", "")).strip_edges()
	var p2n: String = str(cfg.get("player2_name", "")).strip_edges()
	if not p1n.is_empty() or not p2n.is_empty():
		GameState.campaign_player_names = [p1n, p2n]
	return ""

func _apply_portraits_from_config(cfg: Dictionary) -> void:
	var p1_port: String = str(cfg.get("portrait_p1", "")).strip_edges()
	if not p1_port.is_empty():
		GameState.player_portraits[0] = p1_port
	var p2_port: String = str(cfg.get("portrait_p2", "")).strip_edges()
	if not p2_port.is_empty():
		GameState.player_portraits[1] = p2_port

## Tutorial duels always start with Player 2 (index 1, tails). -1 = not forced.
func get_forced_first_player() -> int:
	if is_prepared or is_active:
		return 1
	return -1

## Hide union HUD on the human player's first tutorial turn only.
func should_hide_union_suggest() -> bool:
	return is_active and _player_turn_count == 1

func is_mission_in_progress() -> bool:
	return is_active and _mission_idx < _mission_list.size()

func get_current_mission_type() -> String:
	if not is_mission_in_progress():
		return ""
	return str(_mission_list[_mission_idx].get("type", ""))

## Hide ENEMY VIEW / YOUR VIEW buttons for the whole tutorial (do not alter card peek state).
func should_hide_reveal_view_btn() -> bool:
	return is_active

## Block double-tap info on any grid card while a turn mission is active.
func should_block_card_detail() -> bool:
	return is_mission_in_progress()

func should_allow_end_turn_btn() -> bool:
	if not is_mission_in_progress():
		return true
	return get_current_mission_type() == "end_turn"

## Hide the options button until every configured tutorial mission is finished.
func should_hide_options_btn() -> bool:
	if not is_active:
		return false
	if _all_missions_complete:
		return false
	return get_current_mission_type() != "options"

func should_allow_options_btn() -> bool:
	return not should_hide_options_btn()

## Called by GameBoard._ready() when the battle starts.
func on_board_ready(board: Node) -> void:
	if not is_prepared:
		return
	_game_board = board
	is_active = true
	is_prepared = false
	_player_turn_count = 0
	_last_tutorial_game_turn = -1
	_mission_list = []
	_mission_idx = 0
	_mission_step = 0
	_session_id += 1
	_all_missions_complete = false

	var ov_script = load("res://scripts/TutorialMissionOverlay.gd")
	_overlay = ov_script.new()
	_overlay.name = "TutorialMissionOverlay"
	board.add_child(_overlay)

func _get_max_configured_turn() -> int:
	var turns: Dictionary = config.get("turns", {})
	var max_turn: int = 0
	for k: Variant in turns.keys():
		max_turn = maxi(max_turn, int(k))
	return max_turn

func _try_mark_all_missions_complete() -> void:
	if _all_missions_complete:
		return
	var max_turn: int = _get_max_configured_turn()
	if max_turn <= 0:
		return
	if _player_turn_count < max_turn:
		return
	_all_missions_complete = true
	all_tutorial_missions_done.emit()

## Cleanly shuts down the tutorial layer.
func stop() -> void:
	is_active = false
	is_prepared = false
	config = {}
	_all_missions_complete = false
	_pending_effect_resolve = false
	_last_tutorial_game_turn = -1
	_session_id += 1
	# Unblock any coroutine that is awaiting a signal so it can exit cleanly.
	_step_ready_sig.emit()
	_mission_satisfied_sig.emit()
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	_game_board = null

# ─────────────────────────────────────────────────────────────
# Turn Lifecycle
# ─────────────────────────────────────────────────────────────

## Called by GameBoard when the human player's turn begins (MODE_SELECT phase).
func on_player_turn_started() -> void:
	if not is_active:
		return
	# GameBoard re-enters MODE_SELECT after every attack; only load missions once per turn.
	if GameState.turn_number == _last_tutorial_game_turn:
		return
	_last_tutorial_game_turn = GameState.turn_number
	_player_turn_count += 1

	var turns: Dictionary = config.get("turns", {})

	# Check if all configured turns are exhausted
	var max_configured_turn := 0
	for k in turns.keys():
		max_configured_turn = maxi(max_configured_turn, int(k))

	if max_configured_turn > 0 and _player_turn_count > max_configured_turn:
		var on_complete: String = config.get("on_complete", "end_immediately")
		if on_complete == "end_immediately":
			await get_tree().process_frame
			_end_tutorial_battle()
		return

	var key := str(_player_turn_count)
	_mission_list = turns.get(key, []).duplicate(true)
	_mission_idx = 0
	_mission_step = 0
	_session_id += 1
	var sid := _session_id
	_run_missions(sid)

func _end_tutorial_battle() -> void:
	tutorial_complete.emit()
	SaveManager.mark_attack_tutorial_complete()
	var vn_win: String = GameState.vn_on_win.strip_edges()
	GameState.vn_on_win = ""
	GameState.vn_on_lose = ""
	stop()
	var return_scene: String = ""
	if GameState.quick_duel_launch:
		GameState.quick_duel_launch = false
		GameState.quick_duel_reroll_previews = true
		return_scene = GameState.post_battle_return_scene.strip_edges()
		if return_scene.is_empty():
			return_scene = "res://scenes/main_menu.tscn"
			GameState.open_quick_duel_overlay_on_menu = true
		GameState.post_battle_return_scene = ""
	if return_scene != "":
		CheckerTransition.fade_out_to_scene(return_scene)
		return
	if vn_win != "" and vn_win != "game_over":
		VNPlayer.launch_overlay(vn_win, func() -> void:
			MainMenuReturnLoader.return_to_main_menu())
		return
	CheckerTransition.fade_out_to_scene("res://scenes/main_menu.tscn")

# ─────────────────────────────────────────────────────────────
# Async Mission Runner
# ─────────────────────────────────────────────────────────────

func _run_missions(sid: int) -> void:
	while _mission_idx < _mission_list.size():
		if _session_id != sid:
			return

		# Brief pause to let the board settle before checking
		if _overlay != null and is_instance_valid(_overlay):
			_overlay.show_checking()
		await get_tree().create_timer(0.35).timeout
		if _session_id != sid:
			return

		var m: Dictionary = _mission_list[_mission_idx]
		var mtype: String = m.get("type", "")

		if mtype == "show_message":
			_mission_step = 0
			_pending_effect_resolve = false
			var msg_text: String = str(m.get("message", m.get("instruction", ""))).strip_edges()
			if msg_text.is_empty():
				_mission_idx += 1
				continue
			if _overlay != null and is_instance_valid(_overlay):
				_overlay.show_message(msg_text)
			mission_started.emit(msg_text)
			if not await _await_mission_player_action(_mission_satisfied_sig, sid):
				_handle_mission_await_failed(sid)
				if _session_id != sid:
					return
				continue
			_mission_idx += 1
			if _overlay != null and is_instance_valid(_overlay):
				_overlay.hide_overlay()
			mission_complete.emit()
			continue

		if mtype == "wait":
			_mission_step = 0
			_pending_effect_resolve = false
			var wait_sec: float = _mission_wait_seconds(m)
			if _overlay != null and is_instance_valid(_overlay):
				_overlay.show_wait()
			mission_started.emit("")
			await get_tree().create_timer(wait_sec).timeout
			if _session_id != sid:
				return
			if _overlay != null and is_instance_valid(_overlay):
				_overlay.hide_wait()
			_mission_idx += 1
			mission_complete.emit()
			continue

		var center0 := _get_step_center(m, 0)

		if center0 == Vector2.ZERO or not _mission_target_available(m):
			# Mission target not found / impossible → skip silently
			_mission_idx += 1
			continue

		# Activate step 0
		_mission_step = 0
		_pending_effect_resolve = false
		var radius := _undim_radius(m, _mission_step)
		var instruction: String = m.get("instruction", "")
		if _overlay != null and is_instance_valid(_overlay):
			_overlay.show_mission(center0, radius, instruction)
		mission_started.emit(instruction)

		if _is_two_step(m):
			# Wait for player to complete step 0 (e.g., tap the card)
			if not await _await_mission_player_action(_step_ready_sig, sid):
				_handle_mission_await_failed(sid)
				if _session_id != sid:
					return
				continue

			# Full dim while sub-menu / modal loads
			if _overlay != null and is_instance_valid(_overlay):
				_overlay.show_checking()
			await get_tree().create_timer(0.2).timeout
			if _session_id != sid:
				return

			# Check step 1 target
			var center1 := _get_step_center(m, 1)
			if center1 == Vector2.ZERO or not _mission_target_available(m):
				# Second step impossible; skip this mission
				_mission_idx += 1
				_mission_step = 0
				if _overlay != null and is_instance_valid(_overlay):
					_overlay.hide_overlay()
				continue

			# Activate step 1
			_mission_step = 1
			if _overlay != null and is_instance_valid(_overlay):
				_overlay.show_mission(center1, _undim_radius(m, _mission_step), instruction)

			if not await _await_mission_player_action(_mission_satisfied_sig, sid):
				_handle_mission_await_failed(sid)
				if _session_id != sid:
					return
				continue
		else:
			# Single-step mission: wait directly for satisfaction
			if not await _await_mission_player_action(_mission_satisfied_sig, sid):
				_handle_mission_await_failed(sid)
				if _session_id != sid:
					return
				continue

		# Mission complete
		_mission_idx += 1
		_mission_step = 0
		if _overlay != null and is_instance_valid(_overlay):
			_overlay.hide_overlay()
		mission_complete.emit()

	# All missions for this turn are done
	all_turn_missions_done.emit()
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.hide_overlay()
	_try_mark_all_missions_complete()

# ─────────────────────────────────────────────────────────────
# Action Reporting  (called by GameBoard hooks)
# ─────────────────────────────────────────────────────────────

func report_action(action_type: String, params: Dictionary) -> void:
	if not is_active or _mission_idx >= _mission_list.size():
		return
	var m: Dictionary = _mission_list[_mission_idx]

	match m.get("type", ""):
		"attack":
			_handle_attack(action_type, params, m)
		"bluff":
			_handle_bluff(action_type, params, m)
		"union_summon":
			_handle_union(action_type, params, m)
		"use_tech":
			_handle_use_tech(action_type, params, m)
		"end_turn":
			if action_type == "end_turn_tap":
				_mission_satisfied_sig.emit()
		"options":
			if action_type == "options_tap":
				_mission_satisfied_sig.emit()
		"tap_void_stack":
			if action_type == "void_stack_tap":
				var req_p := 0 if m.get("side", "player") == "player" else 1
				if params.get("player", -1) == req_p:
					_mission_satisfied_sig.emit()
		"tap_tech":
			if action_type == "tech_chip_tap" and params.get("player", -1) == 0:
				_mission_satisfied_sig.emit()
		"tap_card":
			if action_type == "card_tap":
				var req_name: String = m.get("card_name", "")
				if not req_name.is_empty() and params.get("card_name", "") != req_name:
					return
				var req_p := 0 if m.get("side", "player") == "player" else 1
				if params.get("player", -1) == req_p:
					_mission_satisfied_sig.emit()
		"tap_cell":
			if action_type == "cell_tap":
				var req_p := 0 if m.get("side", "player") == "player" else 1
				if params.get("row", -1) == m.get("row", -1) \
						and params.get("col", -1) == m.get("col", -1) \
						and params.get("player", -1) == req_p:
					_mission_satisfied_sig.emit()
		"show_message":
			if action_type == "message_ok":
				_mission_satisfied_sig.emit()

func _handle_attack(act: String, p: Dictionary, m: Dictionary) -> void:
	var target: String = m.get("card_name", "")
	match _mission_step:
		0:
			if act == "card_tap" and p.get("card_name", "") == target and p.get("player", -1) == 0:
				_step_ready_sig.emit()
		1:
			if act == "attack_icon_tap" and p.get("card_name", "") == target:
				_pending_effect_resolve = true
				if _overlay != null and is_instance_valid(_overlay):
					_overlay.show_checking()
			elif act == "attack_completed" and _pending_effect_resolve \
					and p.get("card_name", "") == target and p.get("player", -1) == 0:
				_pending_effect_resolve = false
				_mission_satisfied_sig.emit()
			elif act == "attack_aborted":
				_pending_effect_resolve = false

func _handle_bluff(act: String, p: Dictionary, m: Dictionary) -> void:
	var target: String = m.get("card_name", "")
	match _mission_step:
		0:
			if act == "card_tap" and p.get("card_name", "") == target and p.get("player", -1) == 0:
				_step_ready_sig.emit()
		1:
			if act == "bluff_icon_tap" and p.get("card_name", "") == target:
				_mission_satisfied_sig.emit()

func _handle_union(act: String, p: Dictionary, m: Dictionary) -> void:
	var req: String = m.get("union_name", "")
	match _mission_step:
		0:
			if act == "union_hud_tap":
				_step_ready_sig.emit()
		1:
			if act == "union_selected" and p.get("player", -1) == 0:
				if req.is_empty() or p.get("union_name", "") == req:
					_pending_effect_resolve = true
					if _overlay != null and is_instance_valid(_overlay):
						_overlay.show_checking()
			elif act == "union_resolved" and _pending_effect_resolve and p.get("player", -1) == 0:
				if req.is_empty() or p.get("union_name", "") == req:
					_pending_effect_resolve = false
					_mission_satisfied_sig.emit()

func _handle_use_tech(act: String, p: Dictionary, m: Dictionary) -> void:
	var tech: String = m.get("tech_name", "")
	match _mission_step:
		0:
			if act == "tech_chip_tap" and p.get("player", -1) == 0:
				_step_ready_sig.emit()
		1:
			if act == "tech_played" and p.get("player", -1) == 0:
				var played: String = p.get("tech_name", "")
				if tech.is_empty() or played == tech:
					_pending_effect_resolve = true
					if _overlay != null and is_instance_valid(_overlay):
						_overlay.show_checking()
			elif act == "tech_resolved" and _pending_effect_resolve and p.get("player", -1) == 0:
				_pending_effect_resolve = false
				_mission_satisfied_sig.emit()

# ─────────────────────────────────────────────────────────────
# Position Helpers
# ─────────────────────────────────────────────────────────────

func _get_step_center(m: Dictionary, step: int) -> Vector2:
	if _game_board == null or not is_instance_valid(_game_board):
		return Vector2.ZERO
	var mtype: String = m.get("type", "")

	if step == 0:
		match mtype:
			"attack", "bluff":
				return _game_board.get_card_center(0, m.get("card_name", ""))
			"tap_card":
				var p := 0 if m.get("side", "player") == "player" else 1
				return _game_board.get_card_center(p, m.get("card_name", ""))
			"union_summon":
				return _game_board.get_union_btn_center()
			"use_tech", "tap_tech":
				return _game_board.get_tech_chip_center(0)
			"end_turn":
				return _game_board.get_end_turn_btn_center()
			"options":
				return _game_board.get_options_btn_center()
			"tap_void_stack":
				var p := 0 if m.get("side", "player") == "player" else 1
				return _game_board.get_void_stack_center(p)
			"tap_cell":
				var p := 0 if m.get("side", "player") == "player" else 1
				return _game_board.get_cell_center(p, m.get("row", 0), m.get("col", 0))
	elif step == 1:
		match mtype:
			"attack":
				return _game_board.get_context_btn_center("attack")
			"bluff":
				return _game_board.get_context_btn_center("bluff")
			"union_summon":
				return _game_board.get_union_modal_btn_center(m.get("union_name", ""))
			"use_tech":
				return _game_board.get_tech_use_btn_center(m.get("tech_name", ""))
	return Vector2.ZERO

func _is_two_step(m: Dictionary) -> bool:
	return m.get("type", "") in ["attack", "bluff", "union_summon", "use_tech"]

func _undim_radius(m: Dictionary, step: int) -> float:
	var mtype: String = m.get("type", "")
	match mtype:
		"use_tech", "tap_tech":
			# Tech chip (~76×96) and hand USE button are smaller than grid cells.
			return 38.0 if step == 0 else 44.0
	return 64.0  # 200% of a typical ~32px OS cursor

func _mission_wait_seconds(m: Dictionary) -> float:
	var raw: Variant = m.get("seconds", m.get("duration", 1.0))
	var secs: float = float(raw) if str(raw).is_valid_float() else 1.0
	return maxf(0.1, secs)

# ─────────────────────────────────────────────────────────────
# Player timeout / unavailable target
# ─────────────────────────────────────────────────────────────

func _mission_target_available(m: Dictionary) -> bool:
	var card_name: String = str(m.get("card_name", "")).strip_edges()
	if card_name.is_empty():
		return true
	var mtype: String = m.get("type", "")
	match mtype:
		"attack", "bluff":
			return _player_has_character(0, card_name)
		"tap_card":
			var player_idx: int = 0 if m.get("side", "player") == "player" else 1
			return _player_has_character(player_idx, card_name)
		_:
			return true

func _player_has_character(player_idx: int, card_name: String) -> bool:
	for r: int in range(GameState.GRID_SIZE):
		for c: int in range(GameState.GRID_SIZE):
			var card: GameState.CardInstance = GameState.get_card(player_idx, r, c)
			if card.card_type == "character" \
					and card.card_name == card_name \
					and not card.was_destroyed:
				return true
	return false

func _await_mission_player_action(wait_signal: Signal, sid: int) -> bool:
	_await_abort_reason = ""
	var state := {"fired": false}
	wait_signal.connect(func(): state.fired = true, CONNECT_ONE_SHOT)
	var timer := get_tree().create_timer(MISSION_PLAYER_TIMEOUT_SEC)
	while not state.fired and timer.time_left > 0.0:
		if _session_id != sid:
			_await_abort_reason = "cancelled"
			return false
		if _mission_idx < _mission_list.size() \
				and not _mission_target_available(_mission_list[_mission_idx]):
			_await_abort_reason = "unavailable"
			return false
		await get_tree().process_frame
	if not state.fired:
		_await_abort_reason = "timeout"
	return state.fired and _session_id == sid

func _handle_mission_await_failed(sid: int) -> void:
	match _await_abort_reason:
		"unavailable":
			_skip_mission_on_unavailable(sid)
		"timeout":
			_skip_mission_on_timeout(sid)
		_:
			pass

func _skip_current_mission(sid: int, message: String) -> void:
	if _session_id != sid:
		return
	_pending_effect_resolve = false
	_mission_step = 0
	_mission_idx += 1
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.hide_overlay()
	GameState.post_message(message)
	mission_complete.emit()

func _skip_mission_on_timeout(sid: int) -> void:
	_skip_current_mission(sid, "Tutorial step skipped — took too long.")

func _skip_mission_on_unavailable(sid: int) -> void:
	_skip_current_mission(sid, "Tutorial step skipped — assigned unit is no longer available.")

# ─────────────────────────────────────────────────────────────
# Card context menu restrictions
# ─────────────────────────────────────────────────────────────

## Whether the card context strip may open for this cell during the active mission.
func should_open_card_context(player: int, card_name: String) -> bool:
	if not is_active or _mission_idx >= _mission_list.size():
		return true
	var m: Dictionary = _mission_list[_mission_idx]
	var mtype: String = m.get("type", "")
	var req_p := 0 if m.get("side", "player") == "player" else 1
	match mtype:
		"attack", "bluff":
			return player == 0 and card_name == m.get("card_name", "")
		"tap_card":
			var req_name: String = m.get("card_name", "")
			if not req_name.is_empty():
				return player == req_p and card_name == req_name
			return player == req_p
		_:
			return false

## Empty array = no filter. Otherwise only listed actions appear (attack/info/bluff/union).
func get_card_context_allowlist(card_name: String) -> Array:
	if not is_active or _mission_idx >= _mission_list.size():
		return []
	var m: Dictionary = _mission_list[_mission_idx]
	if card_name != m.get("card_name", ""):
		return []
	match m.get("type", ""):
		"attack":
			return ["attack"]
		"bluff":
			return ["bluff"]
	return []
