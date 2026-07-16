extends Node
## ExplorationManager — autoload that owns all Exploration session state.
##
## An Exploration session is a temporary, self-contained run through an
## ExplorationGraph. Session data (inventory, variables, rewards) is discarded
## when end_session() is called, unless carry_rewards is true.
##
## ─── Quick-start ───────────────────────────────────────────────────────────
##
##   # 1. Optionally set a return scene (default is main_menu.tscn):
##   ExplorationManager.return_scene = "res://scenes/main_menu.tscn"
##
##   # 2. Start the session — this changes the scene to exploration_player.tscn:
##   ExplorationManager.launch("res://exploration/graphs/my_graph.json")
##
##   # — or — start a session without changing scene (manual UI):
##   ExplorationManager.start_session("res://exploration/graphs/my_graph.json")
##
##   # 3. The player navigates; the ExplorationPlayer UI handles most events.
##
##   # 4. The session ends automatically when the player reaches an EXIT node
##   #    and confirms. You can also call end_session() directly.
##
## ─── Launch parameters ─────────────────────────────────────────────────────
##
##   Pass any Dictionary as the third argument to launch(). All keys are
##   seeded as session variables at the start of a fresh session, so your
##   graph node conditions can read them with var_equals / var_not_equals /
##   var_greater / var_less / get_var().
##
##   Reserved keys (not seeded as session vars):
##     "force_fresh"  bool   Skip auto-resume; always start fresh
##     "keep_vn_bgm"  bool   Keep VN music through exploration launch
##     "initial_inventory"  Array  Item ids for this launch (overrides graph default)
##
##   Common launch params (seeded as session vars):
##     "flashlight"   "1"/"0"  Handheld flashlight cone in ExplorationPlayer
##
##   Examples:
##     # Pass act + chapter; gate with force_fresh when starting a new run
##     ExplorationManager.launch(path, return_scene, {
##         "act": "2", "chapter": "3", "force_fresh": true
##     })
##
##     # Resume saved progress, no extra params
##     ExplorationManager.launch(path, return_scene)
##
## ─── Event actions (on_enter / on_exit) ────────────────────────────────────
##   give_item   key / value  → add item to session inventory
##   remove_item key / value  → remove item from session inventory
##   set_var     key + value  → set session variable
##   give_credits value (int) → send credits to mailbox (value = amount;
##                              key = amount if value empty, or optional mail subject if value is amount)
##   give_booster_pack value  → send pack to mailbox (value = pack name or id;
##                              key = optional mail subject override)
##   give_union_scroll value  → send scroll(s) to mailbox (value = count, default 1;
##                              key = optional mail subject override)
##   set_flag    key + value  → set a flag carried to SaveManager on session end
##   show_message value       → emit message_posted signal (toast in UI)
##   play_sfx    value        → play the audio file at the given res:// path
##
## ─── Connection condition types ────────────────────────────────────────────
##   has_item      key        → inventory contains key
##   not_has_item  key        → inventory does NOT contain key
##   var_equals    key+value  → vars[key] == value
##   var_not_equals key+value → vars[key] != value
##   var_greater   key+value  → vars[key] > value (numeric)
##   var_less      key+value  → vars[key] < value (numeric)
##   at_node       key/value  → current node id matches

const EXPLORATION_PLAYER_SCENE: String = "res://scenes/exploration_player.tscn"

static func normalize_graph_path(path: String) -> String:
	var s: String = path.strip_edges()
	if s.is_empty():
		return ""
	if not s.begins_with("res://"):
		s = "res://%s" % s.trim_prefix("/")
	return s

# ─────────────────────────────────────────────────────────────
# Signals
# ─────────────────────────────────────────────────────────────

## Emitted when a session successfully begins (after the start node is entered).
signal session_started(graph: ExplorationGraph)

## Emitted when a session ends. rewards contains credits/flags applied to main game.
signal session_ended(rewards: Dictionary)

## Emitted each time the player moves to a new node (after on_enter events fire).
signal node_entered(node: ExplorationNode)

## Emitted when the player leaves a node (after on_exit events fire).
signal node_exited(node: ExplorationNode)

## Emitted when the session inventory changes.
signal inventory_changed(items: Array)

## Emitted when a session variable is set.
signal var_changed(key: String, value: String)

## Emitted by events with action="show_message". UI displays this as a toast.
signal message_posted(text: String)

## Emitted when an item is added to the session inventory. UI shows the item-obtained overlay.
signal item_obtained(item_id: String)

## Emitted when ExplorationPlayer finishes the item-obtained overlay queue.
signal item_obtained_overlay_idle

## Emitted when a reward is sent to the player's mailbox (booster pack, credits, etc.).
## info keys: image_path (String), display_name (String), type ("credits"|"booster_pack")
signal mailbox_reward_granted(info: Dictionary)

## Emitted when an end_exploration effect fires (item, spot, node event, or VN beat).
## ExplorationPlayer connects to this and performs the scene transition.
signal end_exploration_requested

## Emitted when an end_exploration_vn effect fires.
## vn_path — res:// path to the VN JSON to play before returning to return_scene.
signal end_exploration_vn_requested(vn_path: String)

## Emitted after exploration session data is written to disk.
signal session_saved

# ─────────────────────────────────────────────────────────────
# Public configuration (set before launch / start_session)
# ─────────────────────────────────────────────────────────────

## Scene to change to when the session ends.
## Defaults to the main menu.
var return_scene: String = "res://scenes/main_menu.tscn"

## Parameters forwarded to the next fresh session.
## All keys except reserved entries are seeded as session variables.
## Values may be plain strings or {"random": [min, max]} for inclusive int rolls.
## Can be set here directly or passed as the third arg to launch().
var launch_params: Dictionary = {}
## When true, exploration does not replace BGM (keeps track from launching VN).
## When true, VNPlayer skipped stopping BGM at the exploration handoff.
## Cleared as soon as ExplorationPlayer loads — it does not block node music.
var keep_vn_bgm: bool = false

## VN JSON path to play as an overlay after the session ends, before return_scene.
## Set by VNPlayer when a beat launches exploration with exploration_on_return.
var pending_return_vn: String = ""

## Gallery / VN chapter that launched this session — stored in the save snapshot.
var launch_source_vn: String = ""

## Written by complete_battle_node(); read by ExplorationPlayer on reload.
## Format: { "won": bool, "node_id": String }
var pending_battle_result: Dictionary = {}

## Spot action chain interrupted by a VN start_battle handoff.
## Format: { "node_id": String, "actions": Array, "from_index": int }
var _pending_spot_action_resume: Dictionary = {}

# ─────────────────────────────────────────────────────────────
# Internal session state
# ─────────────────────────────────────────────────────────────

var _current_graph: ExplorationGraph = null
var _current_node_id: String = ""
var _node_history: Array[String] = []
var _inventory: Array[String] = []
var _vars: Dictionary = {}
var _played_vn_scenes: Dictionary = {}   # path → true; tracks once-only VN scenes played this session
var _interacted_spots: Dictionary = {}   # "node_id:spot_index" → true; one-time spots already used
var _spots_in_progress: Dictionary = {}  # "node_id:spot_index" → true; hide-after spots mid-action (not saved)
var _talked_characters: Dictionary = {}  # "node_id:char_index" → true; characters removed from room after talk
var _pending_spot_on_complete: Callable = Callable()
var _pending_spot_interaction: Dictionary = {}  # { node_id, spot_index, hide_after } while a spot queue runs
var _pending_play_once_paths: Array = []  # VN paths to mark played when the current spot queue finishes
var _exploration_checkpoint_pending: bool = false

# Accumulated rewards — applied to main game when end_session(carry_rewards=true) is called.
# { "credits": int, "flags": { key: value, ... } }
var _session_rewards: Dictionary = {}
var _session_active: bool = false
var _source_vn_scene: String = ""
## BGM snapshot from save file; consumed once when ExplorationPlayer refreshes the node.
var _pending_restored_bgm: Dictionary = {}
## BGM snapshot taken before an exploration VN; survives VN→battle handoff for post-battle resume.
var _vn_resume_bgm: Dictionary = {}
## True while ExplorationPlayer is showing (or queued) item-obtained overlays.
var _item_obtained_overlay_busy: bool = false

# ─────────────────────────────────────────────────────────────
# Read-only properties
# ─────────────────────────────────────────────────────────────

## True while a session is running.
var is_session_active: bool:
	get: return _session_active

## The graph loaded for the current session, or null.
var current_graph: ExplorationGraph:
	get: return _current_graph

## The node the player is currently at, or null.
var current_node: ExplorationNode:
	get:
		if _current_graph == null or _current_node_id.is_empty():
			return null
		return _current_graph.get_node_by_id(_current_node_id)

## The ID of the node the player is currently at.
var current_node_id: String:
	get: return _current_node_id

## Campaign / gallery VN that launched this exploration (empty if none).
func get_source_vn_scene() -> String:
	return _source_vn_scene

# ─────────────────────────────────────────────────────────────
# Session Control — Public API
# ─────────────────────────────────────────────────────────────

## Convenience: start a session AND change the scene to ExplorationPlayer.
## Pass {"force_fresh": true} as params to always start fresh and skip
## auto-resume, even if a saved session exists for the same graph.
func launch(graph_path: String, p_return_scene: String = "res://scenes/main_menu.tscn", params: Dictionary = {}) -> void:
	return_scene = p_return_scene
	if not params.is_empty():
		launch_params.merge(params, true)
	# Drop reserved keys not supplied by this launch — merge is cumulative and stale
	# values (e.g. keep_vn_bgm from a prior VN handoff) would otherwise block node music.
	for reserved_key: String in ["keep_vn_bgm", "force_fresh"]:
		if not params.has(reserved_key):
			launch_params.erase(reserved_key)

	keep_vn_bgm = bool(launch_params.get("keep_vn_bgm", false))
	var force_fresh: bool = bool(launch_params.get("force_fresh", false))

	# Resume saved session for the same graph (unless force_fresh is set)
	if not force_fresh:
		var saved: Dictionary = SaveManager.exploration_session
		if saved.get("active", false) \
				and normalize_graph_path(str(saved.get("graph_path", ""))) \
				== normalize_graph_path(graph_path):
			if restore_saved_session():
				CheckerTransition.fade_out_to_battle(func() -> void:
					get_tree().change_scene_to_file(EXPLORATION_PLAYER_SCENE))
				return

	# No matching saved session, or force_fresh — start fresh
	var preserved_source_vn: String = launch_source_vn.strip_edges()
	launch_source_vn = ""
	start_session(graph_path, preserved_source_vn)
	if not _session_active:
		return
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file(EXPLORATION_PLAYER_SCENE))

## Resolve an exploration launch param to the string stored in session vars.
## Supports fixed values and {"random": [min, max]} inclusive integer ranges.
static func resolve_launch_param_value(value: Variant) -> String:
	if value is Dictionary:
		var spec: Dictionary = value as Dictionary
		if spec.has("random"):
			var range_spec: Variant = spec["random"]
			var lo: int = 0
			var hi: int = 0
			if range_spec is Array and (range_spec as Array).size() >= 2:
				lo = int((range_spec as Array)[0])
				hi = int((range_spec as Array)[1])
			elif range_spec is Dictionary:
				lo = int((range_spec as Dictionary).get("min", 0))
				hi = int((range_spec as Dictionary).get("max", 0))
			if lo > hi:
				var swap: int = lo
				lo = hi
				hi = swap
			return str(randi_range(lo, hi))
	return str(value)


## Start a new exploration session by loading the graph from a JSON file.
## Clears any previous session data. Non-reserved keys from launch_params
## are seeded into session vars so graph conditions can read them immediately.
## Emits session_started after the start node is entered.
func start_session(graph_path: String, source_vn_scene: String = "") -> void:
	var graph: ExplorationGraph = ExplorationGraph.load_from_file(graph_path)
	if graph == null:
		push_error("ExplorationManager.start_session: failed to load graph at '%s'." % graph_path)
		return
	var preserve_keep_bgm: bool = bool(launch_params.get("keep_vn_bgm", false))
	_clear_session_memory()
	keep_vn_bgm = preserve_keep_bgm
	_source_vn_scene = source_vn_scene.strip_edges()
	_current_graph   = graph
	_session_rewards = {"credits": 0, "flags": {}}
	_session_active  = true
	for k: String in launch_params:
		if k in ["force_fresh", "keep_vn_bgm", "initial_inventory"]:
			continue
		_vars[k] = resolve_launch_param_value(launch_params.get(k))
	_seed_initial_inventory(graph.initial_inventory, launch_params.get("initial_inventory", null))
	emit_signal("session_started", graph)
	_navigate_to(graph.resolve_start_node_id(_vars), false)
	_save_session_state(true)
	var note_ch: String = DetectiveNoteManager.resolve_active_chapter(_source_vn_scene)
	if not note_ch.is_empty():
		DetectiveNoteManager.apply_start_clues(note_ch)

## Restart the current session from the start node, resetting all progress.
## return_scene is preserved. Emits session_started then node_entered for the start node.
func restart_stage() -> void:
	if not _session_active or _current_graph == null:
		return
	var path: String = _current_graph._source_path
	var rs: String   = return_scene
	var src: String  = _source_vn_scene
	start_session(path, src)
	return_scene = rs

## End the current session.
## If carry_rewards is true, accumulated credits and flags are applied to the main game.
## When clear_saved is false, the on-disk exploration snapshot is kept (chapter arc handoff).
## Emits session_ended with a copy of the rewards Dictionary.
func end_session(carry_rewards: bool = true, clear_saved: bool = true) -> void:
	if not _session_active:
		return
	if not clear_saved:
		_save_session_state(true)
	var rewards: Dictionary = _session_rewards.duplicate(true) if carry_rewards else {}
	if carry_rewards:
		_apply_rewards(rewards)
	_clear_session_memory()
	if clear_saved:
		_clear_saved_session()
	emit_signal("session_ended", rewards)

func _clear_session_memory() -> void:
	keep_vn_bgm        = false
	_session_active    = false
	_current_graph     = null
	_current_node_id   = ""
	_node_history.clear()
	_inventory.clear()
	_vars.clear()
	_played_vn_scenes.clear()
	_interacted_spots.clear()
	_spots_in_progress.clear()
	_talked_characters.clear()
	_pending_spot_on_complete = Callable()
	_pending_spot_interaction = {}
	_pending_play_once_paths.clear()
	_session_rewards   = {}
	_source_vn_scene   = ""
	_pending_restored_bgm = {}
	_vn_resume_bgm = {}
	_item_obtained_overlay_busy = false
	_pending_spot_action_resume = {}
	pending_battle_result = {}
	_exploration_checkpoint_pending = false

func _reset_session_state() -> void:
	_clear_session_memory()
	_clear_saved_session()

## End live session but keep the saved exploration snapshot (chapter return VN handoff).
func detach_session_keep_save(carry_rewards: bool = true) -> void:
	end_session(carry_rewards, false)

## Mark a VN scene path as having been played this session.
func mark_vn_played(path: String) -> void:
	if path.is_empty():
		return
	_played_vn_scenes[path] = true
	_save_session_state()

## Returns true if the given VN scene path has already been played this session.
func is_vn_played(path: String) -> bool:
	return _played_vn_scenes.has(path)

## Mark a one-time investigable spot (identified by node_id + index) as interacted.
func mark_spot_interacted(node_id: String, spot_index: int) -> void:
	_interacted_spots[node_id + ":" + str(spot_index)] = true
	_save_session_state()

## Returns true if the given spot has already been interacted with this session.
func is_spot_interacted(node_id: String, spot_index: int) -> bool:
	return _interacted_spots.has(node_id + ":" + str(spot_index))

## Track a hide-after spot while its action queue is running (not persisted).
func begin_spot_interaction(node_id: String, spot_index: int) -> void:
	if node_id.is_empty() or spot_index < 0:
		return
	_spots_in_progress[node_id + ":" + str(spot_index)] = true

func end_spot_interaction(node_id: String, spot_index: int) -> void:
	_spots_in_progress.erase(node_id + ":" + str(spot_index))

func is_spot_in_progress(node_id: String, spot_index: int) -> bool:
	return _spots_in_progress.has(node_id + ":" + str(spot_index))

func set_pending_spot_on_complete(cb: Callable) -> void:
	_pending_spot_on_complete = cb

func take_pending_spot_on_complete() -> Callable:
	var cb: Callable = _pending_spot_on_complete
	_pending_spot_on_complete = Callable()
	return cb

func clear_pending_spot_on_complete() -> void:
	_pending_spot_on_complete = Callable()

func set_pending_spot_interaction(node_id: String, spot_index: int, hide_after: bool) -> void:
	_pending_spot_interaction = {
		"node_id":    node_id,
		"spot_index": spot_index,
		"hide_after": hide_after,
	}

func take_pending_spot_interaction() -> Dictionary:
	var out: Dictionary = _pending_spot_interaction.duplicate()
	_pending_spot_interaction = {}
	return out

func clear_pending_spot_interaction() -> void:
	_pending_spot_interaction = {}

func reset_pending_play_once_paths() -> void:
	_pending_play_once_paths.clear()

func append_pending_play_once_path(path: String) -> void:
	var p: String = path.strip_edges()
	if p.is_empty():
		return
	_pending_play_once_paths.append(p)

func commit_pending_play_once_paths() -> void:
	for path_var: Variant in _pending_play_once_paths:
		mark_vn_played(str(path_var))
	_pending_play_once_paths.clear()

## Mark a character (node_id + index in node.characters) as talked when remove_after_talk is set.
func mark_char_talked(node_id: String, char_index: int) -> void:
	_talked_characters[node_id + ":" + str(char_index)] = true
	_save_session_state()

## Returns true if the character was already talked to this session (remove_after_talk).
func is_char_talked(node_id: String, char_index: int) -> bool:
	return _talked_characters.has(node_id + ":" + str(char_index))

## True when a BGM path/context belongs to battle flow (not exploration ambient).
func is_battle_bgm_snapshot(path: String, context: String = "") -> bool:
	var ctx: String = context.strip_edges()
	if ctx in [
		BGMManager.CONTEXT_BATTLE,
		BGMManager.CONTEXT_PLACEMENT,
		BGMManager.CONTEXT_BOSS,
		BGMManager.CONTEXT_ALMOST_WIN,
	]:
		return true
	path = path.strip_edges()
	if path.is_empty():
		return false
	var file_name: String = path.get_file().to_lower()
	for prefix: String in ["bgm_battle_", "bgm_boss_", "bgm_placement_", "bgm_almost_win_"]:
		if file_name.begins_with(prefix):
			return true
	for battle_ctx: String in [
		BGMManager.CONTEXT_BATTLE,
		BGMManager.CONTEXT_PLACEMENT,
		BGMManager.CONTEXT_BOSS,
		BGMManager.CONTEXT_ALMOST_WIN,
	]:
		var default_path: String = BGMManager.get_default_path(battle_ctx).strip_edges()
		if not default_path.is_empty() and path == default_path:
			return true
	var battle_path: String = GameState.battle_bgm_path.strip_edges()
	if not battle_path.is_empty() and path == battle_path:
		return true
	var setup_path: String = GameState.battle_setup_bgm_path.strip_edges()
	if not setup_path.is_empty() and path == setup_path:
		return true
	var almost_path: String = GameState.get_almost_win_bgm_path().strip_edges()
	return not almost_path.is_empty() and path == almost_path


func _is_exploration_player_scene_active() -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return false
	return tree.current_scene.scene_file_path == EXPLORATION_PLAYER_SCENE


func _is_exploration_ambient_bgm(path: String, context: String) -> bool:
	path = path.strip_edges()
	context = context.strip_edges()
	if path.is_empty():
		return false
	if is_battle_bgm_snapshot(path, context):
		return false
	if context == BGMManager.CONTEXT_MAIN_MENU:
		return false
	return true


func _bgm_snapshot_from_saved_session(sd: Dictionary) -> Dictionary:
	return {
		"bgm_path": str(sd.get("bgm_path", "")).strip_edges(),
		"bgm_context": str(sd.get("bgm_context", BGMManager.CONTEXT_VN)).strip_edges(),
		"bgm_position": float(sd.get("bgm_position", 0.0)),
		"bgm_loop_from_sec": float(sd.get("bgm_loop_from_sec", -1.0)),
	}


func _empty_bgm_snapshot() -> Dictionary:
	return {
		"bgm_path": "",
		"bgm_context": "",
		"bgm_position": 0.0,
		"bgm_loop_from_sec": -1.0,
	}


func _resolve_persisted_bgm_snapshot() -> Dictionary:
	var prev: Dictionary = SaveManager.exploration_session
	if not prev.get("active", false):
		return _empty_bgm_snapshot()
	var preserved: Dictionary = _bgm_snapshot_from_saved_session(prev)
	var preserved_path: String = str(preserved.get("bgm_path", "")).strip_edges()
	var preserved_context: String = str(preserved.get("bgm_context", BGMManager.CONTEXT_VN)).strip_edges()
	if preserved_path.is_empty() or is_battle_bgm_snapshot(preserved_path, preserved_context):
		return _empty_bgm_snapshot()
	return preserved


func _session_bgm_snapshot() -> Dictionary:
	var path: String = BGMManager.get_current_path().strip_edges()
	var context: String = BGMManager.get_current_context().strip_edges()
	var position: float = BGMManager.get_playback_position()
	var loop_from_sec: float = BGMManager.get_loop_restart_sec()

	if is_battle_bgm_snapshot(path, context):
		if not _vn_resume_bgm.is_empty():
			path = str(_vn_resume_bgm.get("path", "")).strip_edges()
			context = str(_vn_resume_bgm.get("context", BGMManager.CONTEXT_VN)).strip_edges()
			position = float(_vn_resume_bgm.get("position", 0.0))
			loop_from_sec = float(_vn_resume_bgm.get("loop_from_sec", -1.0))
		else:
			return _resolve_persisted_bgm_snapshot()

	# After Save and Exit the live session stays active while the title menu plays its
	# own BGM — never overwrite the exploration snapshot with that audio.
	if not _is_exploration_player_scene_active() or not _is_exploration_ambient_bgm(path, context):
		return _resolve_persisted_bgm_snapshot()

	if is_battle_bgm_snapshot(path, context):
		return _empty_bgm_snapshot()

	return {
		"bgm_path": path,
		"bgm_context": context,
		"bgm_position": position,
		"bgm_loop_from_sec": loop_from_sec,
	}


## Save current session state to SaveManager so it survives a game restart.
## Called automatically on state changes when auto-save is enabled.
## Pass force=true for manual Save and Exit or when re-enabling auto-save.
func _save_session_state(force: bool = false) -> void:
	if not _session_active or _current_graph == null:
		return
	if not force and not SaveManager.exploration_auto_save:
		return
	var bgm: Dictionary = _session_bgm_snapshot()
	SaveManager.exploration_session = {
		"active":            true,
		"graph_path":        normalize_graph_path(_current_graph._source_path),
		"current_node_id":   _current_node_id,
		"history":           _node_history.duplicate(),
		"inventory":         _inventory.duplicate(),
		"vars":              _vars.duplicate(),
		"played_vn_scenes":  _played_vn_scenes.keys(),
		"interacted_spots":  _interacted_spots.keys(),
		"talked_characters": _talked_characters.keys(),
		"rewards":           _session_rewards.duplicate(true),
		"return_scene":      return_scene,
		"pending_return_vn": pending_return_vn,
		"source_vn_scene":   _source_vn_scene,
		"bgm_path":          bgm["bgm_path"],
		"bgm_context":       bgm["bgm_context"],
		"bgm_position":      bgm["bgm_position"],
		"bgm_loop_from_sec": bgm["bgm_loop_from_sec"],
	}
	SaveManager.save_data()
	emit_signal("session_saved")

## Write the current session snapshot immediately (used by Save and Exit).
func save_session_now() -> void:
	_save_session_state(true)

func mark_exploration_checkpoint_pending() -> void:
	_exploration_checkpoint_pending = true

func finalize_exploration_checkpoint() -> void:
	if not _session_active:
		return
	if not SaveManager.exploration_auto_save:
		return
	_save_session_state()

func clear_exploration_checkpoint_pending() -> void:
	_exploration_checkpoint_pending = false

func finalize_exploration_checkpoint_if_pending() -> void:
	if not _exploration_checkpoint_pending:
		return
	finalize_exploration_checkpoint()
	clear_exploration_checkpoint_pending()

## True when a resumable mid-session snapshot exists, optionally for a specific graph.
func has_saved_session(graph_path: String = "") -> bool:
	var sd: Dictionary = SaveManager.exploration_session
	if not sd.get("active", false):
		return false
	if graph_path.is_empty():
		return true
	return normalize_graph_path(str(sd.get("graph_path", ""))) \
		== normalize_graph_path(graph_path)

## Drop a mid-session snapshot when a gallery chapter is marked complete.
func clear_saved_session_for_chapter(chapter_vn_path: String, card: Dictionary = {}) -> void:
	var chapter: String = chapter_vn_path.strip_edges()
	if chapter.is_empty():
		return
	if not SaveManager.exploration_session.get("active", false):
		return
	var graph_path: String = str(SaveManager.exploration_session.get("graph_path", "")).strip_edges()
	if not card.is_empty():
		var from_card: String = resolve_chapter_exploration_graph(card, chapter)
		if not from_card.is_empty():
			graph_path = from_card
	elif graph_path.is_empty():
		graph_path = str(find_exploration_call_in_vn(chapter).get("graph_path", "")).strip_edges()
	if not has_saved_session_for_chapter(chapter, graph_path, card):
		return
	_clear_saved_session()

## Discard the stored mid-session snapshot without ending the live session.
func clear_saved_session() -> void:
	_clear_saved_session()

## Scan a VN JSON for the first exploration_call beat (used by campaign chapter picker).
func find_exploration_call_in_vn(vn_path: String) -> Dictionary:
	var path: String = vn_path.strip_edges()
	if path.is_empty() or not ResourceLoader.exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Array:
		return {}
	for beat: Variant in parsed:
		if not beat is Dictionary:
			continue
		var b: Dictionary = beat as Dictionary
		var graph_path: String = str(b.get("exploration_call", "")).strip_edges()
		if graph_path.is_empty():
			continue
		return {
			"graph_path": graph_path,
			"on_return": str(b.get("exploration_on_return", "")).strip_edges(),
		}
	return {}

## Resolve the exploration graph for a campaign gallery chapter card.
func resolve_chapter_exploration_graph(card: Dictionary, vn_path: String) -> String:
	var from_card: String = str(card.get("exploration_graph", "")).strip_edges()
	if not from_card.is_empty():
		return from_card
	return str(find_exploration_call_in_vn(vn_path).get("graph_path", "")).strip_edges()

## Match a gallery chapter to a saved exploration snapshot.
func has_saved_session_for_chapter(
		chapter_vn_path: String,
		graph_path: String,
		card: Dictionary = {}) -> bool:
	if not has_saved_session(graph_path):
		return false
	var chapter: String = chapter_vn_path.strip_edges()
	if chapter.is_empty():
		return false

	var sd: Dictionary = SaveManager.exploration_session
	var saved_vn: String = str(sd.get("source_vn_scene", "")).strip_edges()
	if not saved_vn.is_empty() and saved_vn == chapter:
		return true

	var var_key: String = str(card.get("exploration_save_var", "")).strip_edges()
	var var_val: String = str(card.get("exploration_save_value", "")).strip_edges()
	if not var_key.is_empty() and not var_val.is_empty():
		var sd_vars: Variant = sd.get("vars", {})
		if sd_vars is Dictionary and str((sd_vars as Dictionary).get(var_key, "")) == var_val:
			return true

	if saved_vn.is_empty():
		return var_key.is_empty()

	return false

## Restore saved progress and open the exploration player (campaign gallery continue).
func resume_saved_exploration(graph_path: String, fallback_return_scene: String = "res://scenes/main_menu.tscn") -> void:
	launch(graph_path, fallback_return_scene, {})

## Clear any stored mid-session data from SaveManager.
func _clear_saved_session() -> void:
	if SaveManager.exploration_session.get("active", false):
		SaveManager.exploration_session = {}
		SaveManager.save_data()

## Restore a previously saved session. Returns true on success.
func restore_saved_session() -> bool:
	var sd: Dictionary = SaveManager.exploration_session
	if not sd.get("active", false):
		return false
	var graph_path: String = str(sd.get("graph_path", ""))
	if graph_path.is_empty():
		return false
	var graph: ExplorationGraph = ExplorationGraph.load_from_file(graph_path)
	if graph == null:
		return false
	graph._source_path = normalize_graph_path(graph_path)
	_current_graph    = graph
	_session_rewards  = sd.get("rewards", {"credits": 0, "flags": {}}).duplicate(true) as Dictionary
	_session_active   = true
	var hist: Variant = sd.get("history", [])
	_node_history = []
	if hist is Array:
		_node_history.assign(hist)
	var inv: Variant  = sd.get("inventory", [])
	_inventory = []
	if inv is Array:
		_inventory.assign(inv)
	var vs: Variant   = sd.get("vars", {})
	_vars             = vs as Dictionary if vs is Dictionary else {}
	_played_vn_scenes.clear()
	var pvn: Variant  = sd.get("played_vn_scenes", [])
	if pvn is Array:
		for p: Variant in (pvn as Array):
			_played_vn_scenes[str(p)] = true
	_interacted_spots.clear()
	var isp: Variant  = sd.get("interacted_spots", [])
	if isp is Array:
		for s: Variant in (isp as Array):
			_interacted_spots[str(s)] = true
	_talked_characters.clear()
	var tc: Variant = sd.get("talked_characters", [])
	if tc is Array:
		for c: Variant in (tc as Array):
			_talked_characters[str(c)] = true
	return_scene      = str(sd.get("return_scene", "res://scenes/main_menu.tscn"))
	pending_return_vn = str(sd.get("pending_return_vn", ""))
	_source_vn_scene  = str(sd.get("source_vn_scene", ""))
	_current_node_id  = str(sd.get("current_node_id", graph.start_node_id))
	_queue_restored_bgm_from_save(sd)
	emit_signal("session_started", graph)
	var node: ExplorationNode = graph.get_node_by_id(_current_node_id)
	if node != null:
		emit_signal("node_entered", node)
	return true


## Pop the BGM snapshot queued by restore_saved_session (single use).
func take_pending_restored_bgm() -> Dictionary:
	var out: Dictionary = _pending_restored_bgm.duplicate()
	_pending_restored_bgm = {}
	return out


func is_item_obtained_overlay_busy() -> bool:
	return _item_obtained_overlay_busy


func mark_item_obtained_overlay_busy() -> void:
	_item_obtained_overlay_busy = true


func mark_item_obtained_overlay_idle() -> void:
	if not _item_obtained_overlay_busy:
		return
	_item_obtained_overlay_busy = false
	emit_signal("item_obtained_overlay_idle")


## Capture ambient exploration BGM before an overlay VN (single-use resume after battle handoff).
func snapshot_bgm_before_vn() -> void:
	if not _session_active:
		return
	var path: String = BGMManager.get_current_path().strip_edges()
	var context: String = BGMManager.get_current_context().strip_edges()
	if is_battle_bgm_snapshot(path, context):
		return
	if path.is_empty():
		return
	_vn_resume_bgm = {
		"path": path,
		"context": BGMManager.get_current_context(),
		"position": BGMManager.get_playback_position(),
		"loop_from_sec": BGMManager.get_loop_restart_sec(),
	}


## Pop the VN pre-battle BGM snapshot (single use).
func take_vn_resume_bgm() -> Dictionary:
	var out: Dictionary = _vn_resume_bgm.duplicate()
	_vn_resume_bgm = {}
	return out


## Drop a pending VN resume snapshot (normal VN finish or loss-not-returning-to-exploration).
func clear_vn_resume_bgm() -> void:
	_vn_resume_bgm = {}


func _queue_restored_bgm_from_save(sd: Dictionary) -> void:
	var path: String = str(sd.get("bgm_path", "")).strip_edges()
	var context: String = str(sd.get("bgm_context", BGMManager.CONTEXT_VN)).strip_edges()
	if path.is_empty() or is_battle_bgm_snapshot(path, context):
		_pending_restored_bgm = {}
		return
	_pending_restored_bgm = {
		"path": path,
		"context": context,
		"position": float(sd.get("bgm_position", 0.0)),
		"loop_from_sec": float(sd.get("bgm_loop_from_sec", -1.0)),
	}

func _apply_rewards(rewards: Dictionary) -> void:
	var credits: int = int(rewards.get("credits", 0))
	if credits > 0 and credits < 1_000_000:   # sanity-clamp
		Collection.add_credits(credits)

	var flags: Variant = rewards.get("flags", {})
	if flags is Dictionary and not (flags as Dictionary).is_empty():
		for key: Variant in (flags as Dictionary).keys():
			SaveManager.exploration_flags[str(key)] = str((flags as Dictionary)[key])
		SaveManager.save_data()

# ─────────────────────────────────────────────────────────────
# Navigation — Public API
# ─────────────────────────────────────────────────────────────

## Move to the node with the given id.
## Fires on_exit for the current node then on_enter for the target.
## Emits node_entered after arriving.
func navigate_to(node_id: String) -> void:
	if not _session_active:
		push_warning("ExplorationManager.navigate_to() called outside of an active session.")
		return
	_navigate_to(node_id, true, true, true)


## Apply navigation state only (on_exit / history / on_enter). No visuals or save.
func apply_navigate_to(node_id: String) -> bool:
	if not _session_active:
		push_warning("ExplorationManager.apply_navigate_to() called outside of an active session.")
		return false
	return _navigate_to(node_id, true, false, false)


## Apply go-back state only. No visuals or save.
func apply_go_back() -> bool:
	if _node_history.size() < 2:
		return false
	_node_history.pop_back()
	var prev_id: String = _node_history.pop_back()
	return _navigate_to(prev_id, false, false, false)


## Refresh ExplorationPlayer after apply_navigate_to / apply_go_back.
func commit_navigation_visuals() -> void:
	if _current_graph == null or _current_node_id.is_empty():
		return
	var node: ExplorationNode = _current_graph.get_node_by_id(_current_node_id)
	if node != null:
		emit_signal("node_entered", node)


## Persist session after navigation state is applied, before the fade transition.
func save_navigation_checkpoint() -> void:
	_save_session_state()


## Move to the previous node in navigation history.
## Returns true on success, false if already at the origin.
func go_back() -> bool:
	if _node_history.size() < 2:
		return false
	_node_history.pop_back()
	var prev_id: String = _node_history.pop_back()
	if not _navigate_to(prev_id, false, true, true):
		return false
	return true

## Returns true if there is a previous node to go back to.
func can_go_back() -> bool:
	return _node_history.size() >= 2

func _navigate_to(node_id: String, push_current_to_history: bool,
		emit_entered: bool = true, save_after: bool = true) -> bool:
	if _current_graph == null:
		return false
	var target: ExplorationNode = _current_graph.get_node_by_id(node_id)
	if target == null:
		push_error("ExplorationManager: node '%s' not found in graph '%s'." % [
			node_id, _current_graph.graph_id])
		return false

	# Fire on_exit events for the node we are leaving
	if not _current_node_id.is_empty():
		var old_node: ExplorationNode = _current_graph.get_node_by_id(_current_node_id)
		if old_node != null:
			_process_events(old_node.resolve_on_exit_events(_vars))
			emit_signal("node_exited", old_node)

	# Update history
	if push_current_to_history and not _current_node_id.is_empty():
		_node_history.append(_current_node_id)
		GlobalStatManager.on_exploration_navigate()
	_current_node_id = node_id
	_node_history.append(node_id)

	# Fire on_enter events for the new node
	_process_events(target.resolve_on_enter_events(_vars))
	if emit_entered:
		emit_signal("node_entered", target)
	if save_after:
		_save_session_state()
	return true

# ─────────────────────────────────────────────────────────────
# Connection / Choice Availability — Public API
# ─────────────────────────────────────────────────────────────

## Returns true if all conditions on a connection Dictionary are currently satisfied.
func is_connection_unlocked(conn: Dictionary) -> bool:
	var conditions: Variant = conn.get("conditions", [])
	if not conditions is Array:
		return true
	return ExplorationConditions.evaluate_all(conditions as Array)

## True when the connection dict has at least one condition entry.
func connection_has_conditions(conn: Dictionary) -> bool:
	var conditions: Variant = conn.get("conditions", [])
	return conditions is Array and not (conditions as Array).is_empty()

## locked_mode when conditions fail: "hide" (default) or "disable".
func get_connection_locked_mode(conn: Dictionary) -> String:
	var mode: String = str(conn.get("locked_mode", "hide")).strip_edges().to_lower()
	return mode if mode == "disable" else "hide"

## Whether a connection should appear in the compass radial menu.
func connection_should_show(conn: Dictionary) -> bool:
	if is_connection_unlocked(conn):
		return true
	if not connection_has_conditions(conn):
		return false
	return get_connection_locked_mode(conn) == "disable"

## Returns the locked-hint string if the connection is locked, or "" if it is open.
func get_connection_lock_hint(conn: Dictionary) -> String:
	if is_connection_unlocked(conn):
		return ""
	var hint: String = str(conn.get("locked_hint", ""))
	return hint if not hint.is_empty() else "Locked"

# ─────────────────────────────────────────────────────────────
# Inventory — Public API
# ─────────────────────────────────────────────────────────────

func _seed_initial_inventory(graph_items: Array, launch_items: Variant) -> void:
	var seed: Array[String] = []
	if launch_items is Array and not (launch_items as Array).is_empty():
		for item_var: Variant in (launch_items as Array):
			var item_id: String = str(item_var).strip_edges()
			if not item_id.is_empty():
				seed.append(item_id)
	else:
		for item_var: Variant in graph_items:
			var item_id: String = str(item_var).strip_edges()
			if not item_id.is_empty():
				seed.append(item_id)
	if seed.is_empty():
		return
	for item_id: String in seed:
		_inventory.append(item_id)
	print("[Exploration] initial_inventory: %s (node: %s)" % [str(_inventory), current_node_id])
	emit_signal("inventory_changed", _inventory.duplicate())

## Add one instance of an item to the session inventory.
func add_item(item: String) -> void:
	if item.is_empty():
		return
	_inventory.append(item)
	print("[Exploration] item_obtained: %s  (inventory count: %d, node: %s)" % [
		item, _inventory.size(), current_node_id])
	emit_signal("inventory_changed", _inventory.duplicate())
	emit_signal("item_obtained", item)
	_save_session_state()

## Remove one instance of an item from the session inventory.
func remove_item(item: String) -> void:
	if _inventory.has(item):
		_inventory.erase(item)
		print("[Exploration] item_removed: %s  (inventory count: %d, node: %s)" % [
			item, _inventory.size(), current_node_id])
		emit_signal("inventory_changed", _inventory.duplicate())
		_save_session_state()

## Returns true if the item is currently in the session inventory.
func has_item(item: String) -> bool:
	return item in _inventory

## Returns a copy of the current session inventory.
func get_inventory() -> Array:
	return _inventory.duplicate()

# ─────────────────────────────────────────────────────────────
# Variables — Public API
# ─────────────────────────────────────────────────────────────

## Set a session variable.
func set_var(key: String, value: String) -> void:
	var had_key: bool = _vars.has(key)
	var prev: String = str(_vars.get(key, "")) if had_key else "(unset)"
	_vars[key] = value
	print("[Exploration] var_changed: %s = \"%s\" (was: %s, node: %s)" % [
		key, value, prev, current_node_id])
	emit_signal("var_changed", key, value)
	_save_session_state()


## Remove a session variable (no-op if unset). Does not persist by itself.
func clear_var(key: String) -> void:
	var clean: String = key.strip_edges()
	if clean.is_empty() or not _vars.has(clean):
		return
	_vars.erase(clean)
	emit_signal("var_changed", clean, "")


## Set a persistent exploration flag (SaveManager.exploration_flags + session rewards).
func set_exploration_flag(key: String, value: String) -> void:
	var flag_key: String = key.strip_edges()
	if flag_key.is_empty():
		return
	SaveManager.exploration_flags[flag_key] = value
	var flags: Variant = _session_rewards.get("flags", {})
	if not flags is Dictionary:
		flags = {}
	(flags as Dictionary)[flag_key] = value
	_session_rewards["flags"] = flags
	SaveManager.save_data()
	print("[Exploration] flag_set: %s = \"%s\" (node: %s)" % [flag_key, value, current_node_id])

## Public single-event dispatcher — called by VNPlayer for exploration_actions beats.
## Accepts the same action/key/value format as on_enter/on_exit events.
func dispatch_event(action: String, key: String, value: String) -> void:
	_process_events([{"action": action, "key": key, "value": value}])

## Get a session variable value, or default_val if not set.
## Falls back to SaveManager.exploration_flags so detective-note /
## set_flag values still work in VN when a session var was never set.
func get_var(key: String, default_val: String = "") -> String:
	var clean: String = key.strip_edges().trim_prefix("#").trim_suffix("#")
	if clean.is_empty():
		return default_val
	if _vars.has(clean):
		return str(_vars[clean])
	if SaveManager.exploration_flags.has(clean):
		return str(SaveManager.exploration_flags[clean])
	return default_val

## True when the session has the var key, or a persistent exploration flag exists.
func has_var(key: String) -> bool:
	var clean: String = key.strip_edges().trim_prefix("#").trim_suffix("#")
	if clean.is_empty():
		return false
	return _vars.has(clean) or SaveManager.exploration_flags.has(clean)


## Replace placeholders with current session var values.
## Forms:
##   #var_name#
##   #var_name%translate?From=To&Other=Alt#
##   #var_name%clue_name=true#          — clue id → Detective Note display Name
##   #var_name%allcapitalize=true#
##   #var_name%firstcapitalize=true#
##   #var_name%decapitalize=true#
## Modifiers can be chained, applied left→right:
##   #var_name%clue_name=true%firstcapitalize=true#
## Missing keys become empty string. Unmatched hashes are left as-is.
func substitute_text_vars(text: String, locale: String = "en") -> String:
	if text.is_empty() or text.find("#") < 0:
		return text
	var re := RegEx.new()
	# Group 1 = var name; group 2 = optional %mod... chain (includes leading %)
	if re.compile("#([A-Za-z_][A-Za-z0-9_]*)((?:%(?:translate\\?[^#%]*|(?:allcapitalize|firstcapitalize|decapitalize|clue_name)=[^#%]*))*)#") != OK:
		return text
	var matches: Array[RegExMatch] = re.search_all(text)
	if matches.is_empty():
		return text
	var result: String = ""
	var last_end: int = 0
	for m: RegExMatch in matches:
		result += text.substr(last_end, m.get_start() - last_end)
		result += _resolve_var_placeholder(m.get_string(1), m.get_string(2), locale)
		last_end = m.get_end()
	result += text.substr(last_end)
	return result


func _resolve_var_placeholder(var_key: String, mods_raw: String, locale: String = "en") -> String:
	var value: String = get_var(var_key, "")
	if mods_raw.is_empty():
		return value
	for mod: String in mods_raw.split("%", false):
		if mod.is_empty():
			continue
		if mod.begins_with("translate?"):
			value = _apply_var_translate(value, mod.substr("translate?".length()))
			continue
		var eq: int = mod.find("=")
		if eq < 0:
			continue
		var name: String = mod.substr(0, eq).strip_edges().to_lower()
		var flag: String = mod.substr(eq + 1).strip_edges().to_lower()
		if not _is_truthy_flag(flag):
			continue
		match name:
			"allcapitalize":
				value = value.to_upper()
			"firstcapitalize":
				value = _capitalize_first(value)
			"decapitalize":
				value = value.to_lower()
			"clue_name":
				value = _resolve_clue_display_name(value, locale)
	return value


func _resolve_clue_display_name(clue_id: String, locale: String) -> String:
	var cid: String = clue_id.strip_edges()
	if cid.is_empty():
		return ""
	var clue: Dictionary = DetectiveNoteVault.get_clue(cid)
	if clue.is_empty():
		return cid
	var display: String = DetectiveNoteVault.clue_display_name(clue, locale)
	return display if not display.is_empty() else cid


func _is_truthy_flag(flag: String) -> bool:
	return flag == "true" or flag == "1" or flag == "yes" or flag == "on"


func _capitalize_first(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0, 1).to_upper() + s.substr(1)


## Apply From=To&Other=Alt mapping to a raw var value.
## Optional `*` maps any unmatched value: `Nex=I&*=they`
func _apply_var_translate(raw: String, query: String) -> String:
	var default_val: String = raw
	for pair: String in query.split("&", false):
		var eq: int = pair.find("=")
		if eq < 0:
			continue
		var from_s: String = pair.substr(0, eq)
		var to_s: String = pair.substr(eq + 1)
		if from_s == "*":
			default_val = to_s
			continue
		if from_s == raw:
			return to_s
	return default_val


## True when session var flashlight is enabled ("1", "true", etc.).
func is_flashlight_enabled() -> bool:
	if not _session_active:
		return false
	var v: String = str(_vars.get("flashlight", "")).strip_edges().to_lower()
	return v == "1" or v == "true" or v == "yes" or v == "on"

## Returns a copy of all current session variables.
func get_all_vars() -> Dictionary:
	return _vars.duplicate()

# ─────────────────────────────────────────────────────────────
# Event Processing
# ─────────────────────────────────────────────────────────────

## Public wrapper — lets external scripts fire a list of event dicts.
func process_events(events: Array) -> void:
	_process_events(events)

func _process_events(events: Array) -> void:
	for ev: Variant in events:
		if not ev is Dictionary:
			continue
		var d: Dictionary  = ev as Dictionary
		var action: String = str(d.get("action", ""))
		var key: String    = str(d.get("key",    ""))
		var value: String  = str(d.get("value",  ""))

		match action:
			"give_item":
				add_item(key if not key.is_empty() else value)

			"remove_item":
				remove_item(key if not key.is_empty() else value)

			"set_var":
				set_var(key, value)

			"give_credits":
				var amount: int = _parse_credit_amount(key, value)
				if amount > 0:
					var credit_subject: String = ""
					if not value.is_empty() and value.is_valid_int() \
							and not key.is_empty() and not key.is_valid_int():
						credit_subject = key
					_grant_credits(amount, credit_subject)

			"give_booster_pack":
				var pack_ref: String = value if not value.is_empty() else key
				var subject_override: String = key if not value.is_empty() else ""
				_grant_booster_pack_mail(pack_ref, subject_override)

			"give_union_scroll":
				var scroll_amount: int = _parse_credit_amount(key, value)
				if scroll_amount <= 0:
					scroll_amount = 1
				var scroll_subject: String = ""
				if not key.is_empty() and not key.is_valid_int():
					scroll_subject = key
				_grant_union_scroll_mail(scroll_amount, scroll_subject)

			"set_flag":
				set_exploration_flag(key, value)

			"note_add_clue":
				var clue_ch: String = _note_chapter(value)
				if clue_ch.is_empty():
					push_warning("ExplorationManager: note_add_clue '%s' — no note chapter for this context." % key)
				else:
					DetectiveNoteManager.add_clue(clue_ch, key)

			"note_unlock_topic":
				var topic_ch: String = _note_chapter(value)
				if topic_ch.is_empty():
					push_warning("ExplorationManager: note_unlock_topic '%s' — no note chapter for this context." % key)
				else:
					DetectiveNoteManager.unlock_topic(topic_ch, key)

			"note_upgrade_topic":
				var up_ch: String = _note_chapter("")
				if up_ch.is_empty():
					push_warning("ExplorationManager: note_upgrade_topic '%s' — no note chapter for this context." % key)
				else:
					var lvl: int = int(value) if value.is_valid_int() else 0
					if lvl <= 0:
						lvl = DetectiveNoteManager.get_topic_level(up_ch, key) + 1
					DetectiveNoteManager.upgrade_topic(up_ch, key, lvl)

			"show_message":
				emit_signal("message_posted", value)

			"play_sfx":
				_play_sfx(value)

			"end_exploration":
				end_session(true)
				emit_signal("end_exploration_requested")

			"end_exploration_vn":
				var vn_path: String = value if not value.is_empty() else key
				end_session(true)
				emit_signal("end_exploration_vn_requested", vn_path)

## Chapter for note_* actions: explicit chapter id when given (and known),
## otherwise the chapter mapped to the active exploration graph / VN scene.
func _note_chapter(explicit: String) -> String:
	var ch: String = explicit.strip_edges()
	if not ch.is_empty() and not DetectiveNoteVault.get_chapter(ch).is_empty():
		return ch
	return DetectiveNoteManager.resolve_active_chapter()

## Send exploration credits to the player's mailbox (claimable from Inventory).
func _grant_credits(amount: int, subject_override: String = "") -> void:
	if amount <= 0 or amount >= 1_000_000:
		push_warning("ExplorationManager: invalid credit amount %d." % amount)
		return
	var subject: String = subject_override if not subject_override.is_empty() \
		else "Exploration Reward — %d Credits" % amount
	MailboxManager.send_mail(
		"Exploration",
		subject,
		"You earned %d Credits during exploration. Claim them from your Inventory." % amount,
		{"type": "credits", "amount": amount})
	emit_signal("mailbox_reward_granted", {
		"type":         "credits",
		"image_path":   "res://assets/textures/ui/decorations/ui_icon_credit.png",
		"display_name": "Received %d Credits" % amount,
	})
	# Toast is intentionally omitted — the mailbox reward overlay is the visual feedback.

func _parse_credit_amount(key: String, value: String) -> int:
	if value.is_valid_int():
		return int(value)
	if key.is_valid_int():
		return int(key)
	return 0

## Send a booster pack to the player's mailbox (claimable from Inventory).
## pack_ref — pack display name or id (resolved via ShopManager.get_pack_by_name).
## subject_override — optional custom mail subject; auto-generated when empty.
func _grant_booster_pack_mail(pack_ref: String, subject_override: String = "") -> void:
	if pack_ref.is_empty():
		push_warning("ExplorationManager: give_booster_pack missing pack name/id.")
		return
	var pack: Dictionary = ShopManager.get_pack_by_name(pack_ref)
	if pack.is_empty():
		push_warning("ExplorationManager: unknown booster pack '%s'." % pack_ref)
		emit_signal("message_posted", "Unknown booster pack reward.")
		return
	var pack_name: String = str(pack.get("name", pack_ref))
	var subject: String = subject_override if not subject_override.is_empty() \
		else "Exploration Reward — %s" % pack_name
	MailboxManager.send_mail(
		"Exploration",
		subject,
		"You earned a booster pack during exploration: %s. Claim it from your Inventory." % pack_name,
		{"type": "booster_pack", "pack_name": pack_name})
	var pack_image: String = str(pack.get("pack_image", ""))
	emit_signal("mailbox_reward_granted", {
		"type":         "booster_pack",
		"image_path":   pack_image,
		"display_name": pack_name,
	})
	# Toast is intentionally omitted — the mailbox reward overlay is the visual feedback.

func _grant_union_scroll_mail(count: int, subject_override: String = "") -> void:
	if count <= 0:
		push_warning("ExplorationManager: give_union_scroll count must be positive.")
		return
	UnionScrollManager.grant_union_scroll_mail(count, subject_override, "Exploration")
	emit_signal("mailbox_reward_granted", {
		"type":         "union_scroll",
		"image_path":   UnionScrollManager.SCROLL_IMAGE,
		"display_name": "Union Scroll ×%d" % count,
	})

func _play_sfx(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: Variant = load(path)
	if not stream is AudioStream:
		return
	var asp := AudioStreamPlayer.new()
	asp.stream = stream as AudioStream
	asp.bus    = &"SFX"
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)

# ─────────────────────────────────────────────────────────────
# Battle Integration
# ─────────────────────────────────────────────────────────────

## Called by ExplorationPlayer when the player confirms a battle at a BATTLE node.
## Sets up a VS-AI-style grid duel then changes scene to game_board.tscn.
## GameBoard._on_game_over() will call complete_battle_node() with the result.
func start_battle_for_node(node: ExplorationNode) -> void:
	if not _session_active:
		push_warning("ExplorationManager.start_battle_for_node: no active session.")
		return
	pending_battle_result = {}
	snapshot_bgm_before_vn()
	save_session_now()
	# Configure a standard VS_AI battle using the EXPLORATION game mode.
	# The AI controls player 1; the human plays as player 0.
	GameState.apply_battle_audio_config({
		"battle_bgm": node.battle_bgm,
		"setup_bgm": node.setup_bgm,
		"almost_win_bgm": node.almost_win_bgm,
		"battle_bgm_volume": node.battle_bgm_volume,
	})
	var vault_cfg: Dictionary = AIDeckVault.resolve_vault_from_dict({
		"ai_deck_vault": node.ai_deck_vault,
		"ai_deck_vault_formation": node.ai_deck_vault_formation,
	})
	if bool(vault_cfg.get("ok", false)):
		GameState._vn_battle_pending = true
		AIDeckVault.apply_enemy_battle_config(vault_cfg)
		GameState.analytics_battle_id = str(vault_cfg.get("entry_id", "")).strip_edges()
	else:
		GameState.analytics_battle_id = ""
		GameState.campaign_enemy_config = {}
		GameState.battle_ai_deck = null
		GameState.battle_ai_forced_cells.clear()
		GameState.battle_ai_forced_tech.clear()
		GameState.battle_ai_featured_union = ""
	GameState.new_game(GameState.GameMode.EXPLORATION)
	GameState.quick_duel_protagonist_id = "nex"
	if _current_graph != null:
		GameState.analytics_graph_path = str(_current_graph._source_path)
	GlobalStatManager.on_duel_started({"is_quick_duel": false, "is_tutorial": false})
	SaveManager.save_data()
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))

## Called by GameBoard._on_game_over() when game_mode == EXPLORATION.
## Stores the result so ExplorationPlayer can read it when it reloads.
func complete_battle_node(won: bool) -> void:
	pending_battle_result = {"won": won, "node_id": _current_node_id}

## Clear battle handoff state after a duel loss without applying loss progress vars.
func clear_duel_loss_handoff() -> void:
	pending_battle_result = {}
	clear_spot_action_resume()
	clear_pending_spot_on_complete()
	reset_pending_play_once_paths()
	var pending_spot: Dictionary = take_pending_spot_interaction()
	if not pending_spot.is_empty():
		var node_id: String = str(pending_spot.get("node_id", ""))
		var spot_index: int = int(pending_spot.get("spot_index", -1))
		end_spot_interaction(node_id, spot_index)

## Restore the on-disk exploration snapshot after losing a story/exploration duel.
func resume_from_last_save_after_duel_loss() -> bool:
	clear_duel_loss_handoff()
	if not has_saved_session():
		return false
	return restore_saved_session()

## Return to title after a duel loss while keeping saved chapter progress intact.
func quit_to_title_after_duel_loss() -> void:
	clear_duel_loss_handoff()
	if not _session_active:
		return
	if not has_saved_session():
		save_session_now()
	_clear_session_memory()

# ─────────────────────────────────────────────────────────────
# Spot action resume (VN start_battle handoff)
# ─────────────────────────────────────────────────────────────

## Stage remaining spot actions before a play_vn that may hand off to battle.
## Cleared when the VN finishes normally or after a post-battle resume attempt.
func stage_spot_action_resume(
		node_id: String,
		actions: Array,
		from_index: int,
		resume_tag: String = "",
		meta: Dictionary = {}) -> void:
	if node_id.is_empty() or from_index >= actions.size():
		return
	_pending_spot_action_resume = {
		"node_id":    node_id,
		"actions":    actions.duplicate(true),
		"from_index": from_index,
		"resume_tag": resume_tag,
		"meta":       meta.duplicate(),
	}

func clear_spot_action_resume() -> void:
	_pending_spot_action_resume = {}

## Pop staged spot actions after returning from battle. Runs only on a win for the
## same node that staged them; loss or node mismatch discards the pending chain.
func take_spot_action_resume_for_battle(won: bool, node_id: String) -> Dictionary:
	if _pending_spot_action_resume.is_empty():
		return {}
	var staged_node: String = str(_pending_spot_action_resume.get("node_id", ""))
	var out: Dictionary = _pending_spot_action_resume.duplicate(true)
	clear_spot_action_resume()
	if not won or staged_node != node_id:
		clear_pending_spot_on_complete()
		reset_pending_play_once_paths()
		return {}
	return out

# ─────────────────────────────────────────────────────────────
# Debug
# ─────────────────────────────────────────────────────────────

## Returns a multi-line snapshot of the current session state.
## Call from AdminConsole or via F3 in ExplorationPlayer.
func debug_dump() -> String:
	var lines: Array[String] = [
		"=== ExplorationManager Debug ===",
		"Session active : %s" % str(_session_active),
		"Graph          : %s" % (str(_current_graph.graph_id) if _current_graph != null else "none"),
		"Current node   : '%s'" % _current_node_id,
		"History (%d)   : %s" % [_node_history.size(), str(_node_history)],
		"Inventory (%d) : %s" % [_inventory.size(), str(_inventory)],
		"Variables (%d) : %s" % [_vars.size(), str(_vars)],
		"Rewards        : %s" % str(_session_rewards),
		"Pending battle : %s" % str(pending_battle_result),
		"Spot resume    : %s" % str(_pending_spot_action_resume),
		"Return scene   : %s" % return_scene,
	]
	return "\n".join(lines)
