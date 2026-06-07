extends Node
# Autoload: TutorialBattleManager
# Manages tutorial duel state: mission lifecycle, overlay control, action reporting.

signal mission_started(instruction: String)
signal mission_complete
signal all_turn_missions_done
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
var _mission_list: Array = []
var _mission_idx: int = 0
var _mission_step: int = 0  # 0 = step one, 1 = step two (attack/bluff/union/use_tech)
var _session_id: int = 0    # incremented whenever missions are reset; used to cancel stale awaits

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

## Called by GameBoard._ready() when the battle starts.
func on_board_ready(board: Node) -> void:
	if not is_prepared:
		return
	_game_board = board
	is_active = true
	is_prepared = false
	_player_turn_count = 0
	_mission_list = []
	_mission_idx = 0
	_mission_step = 0
	_session_id += 1

	var ov_script = load("res://scripts/TutorialMissionOverlay.gd")
	_overlay = ov_script.new()
	_overlay.name = "TutorialMissionOverlay"
	board.add_child(_overlay)

## Cleanly shuts down the tutorial layer.
func stop() -> void:
	is_active = false
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
	stop()
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

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
		var center0 := _get_step_center(m, 0)

		if center0 == Vector2.ZERO:
			# Mission target not found / impossible → skip silently
			_mission_idx += 1
			continue

		# Activate step 0
		_mission_step = 0
		var radius := _undim_radius()
		var instruction: String = m.get("instruction", "")
		if _overlay != null and is_instance_valid(_overlay):
			_overlay.show_mission(center0, radius, instruction)
		mission_started.emit(instruction)

		if _is_two_step(m):
			# Wait for player to complete step 0 (e.g., tap the card)
			await _step_ready_sig
			if _session_id != sid:
				return

			# Full dim while sub-menu / modal loads
			if _overlay != null and is_instance_valid(_overlay):
				_overlay.show_checking()
			await get_tree().create_timer(0.2).timeout
			if _session_id != sid:
				return

			# Check step 1 target
			var center1 := _get_step_center(m, 1)
			if center1 == Vector2.ZERO:
				# Second step impossible; skip this mission
				_mission_idx += 1
				_mission_step = 0
				if _overlay != null and is_instance_valid(_overlay):
					_overlay.hide_overlay()
				continue

			# Activate step 1
			_mission_step = 1
			if _overlay != null and is_instance_valid(_overlay):
				_overlay.show_mission(center1, radius, instruction)

			await _mission_satisfied_sig
			if _session_id != sid:
				return
		else:
			# Single-step mission: wait directly for satisfaction
			await _mission_satisfied_sig
			if _session_id != sid:
				return

		# Mission complete
		_mission_idx += 1
		_mission_step = 0
		if _overlay != null and is_instance_valid(_overlay):
			_overlay.hide_overlay()
		mission_complete.emit()
		await get_tree().create_timer(0.1).timeout

	# All missions for this turn are done
	all_turn_missions_done.emit()
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.hide_overlay()

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

func _handle_attack(act: String, p: Dictionary, m: Dictionary) -> void:
	var target: String = m.get("card_name", "")
	match _mission_step:
		0:
			if act == "card_tap" and p.get("card_name", "") == target and p.get("player", -1) == 0:
				_step_ready_sig.emit()
		1:
			if act == "attack_icon_tap" and p.get("card_name", "") == target:
				_mission_satisfied_sig.emit()

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
	match _mission_step:
		0:
			if act == "union_hud_tap":
				_step_ready_sig.emit()
		1:
			if act == "union_selected":
				var req: String = m.get("union_name", "")
				if req.is_empty() or p.get("union_name", "") == req:
					_mission_satisfied_sig.emit()

func _handle_use_tech(act: String, p: Dictionary, m: Dictionary) -> void:
	var tech: String = m.get("tech_name", "")
	match _mission_step:
		0:
			if act == "tech_chip_tap" and p.get("player", -1) == 0:
				_step_ready_sig.emit()
		1:
			if act == "tech_use_tap":
				if tech.is_empty() or p.get("tech_name", "") == tech:
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

func _undim_radius() -> float:
	return 64.0  # 200% of a typical ~32px OS cursor
