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
##   Reserved key (not seeded as a session var):
##     "force_fresh"  bool   If true, always start a fresh session — the
##                           auto-resume check is skipped even when a saved
##                           session exists for the same graph.
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
##   give_credits value (int) → grant shop credits immediately (value = amount;
##                              key used as amount if value is empty)
##   give_booster_pack value  → send pack to mailbox (value = pack name or id;
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

## Emitted when a reward is sent to the player's mailbox (booster pack, credits, etc.).
## info keys: image_path (String), display_name (String), type ("credits"|"booster_pack")
signal mailbox_reward_granted(info: Dictionary)

## Emitted when an end_exploration effect fires (item, spot, node event, or VN beat).
## ExplorationPlayer connects to this and performs the scene transition.
signal end_exploration_requested

## Emitted when an end_exploration_vn effect fires.
## vn_path — res:// path to the VN JSON to play before returning to return_scene.
signal end_exploration_vn_requested(vn_path: String)

# ─────────────────────────────────────────────────────────────
# Public configuration (set before launch / start_session)
# ─────────────────────────────────────────────────────────────

## Scene to change to when the session ends.
## Defaults to the main menu.
var return_scene: String = "res://scenes/main_menu.tscn"

## Parameters forwarded to the next fresh session.
## All keys except "force_fresh" are seeded as session variables.
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
var _talked_characters: Dictionary = {}  # "node_id:char_index" → true; characters removed from room after talk

# Accumulated rewards — applied to main game when end_session(carry_rewards=true) is called.
# { "credits": int, "flags": { key: value, ... } }
var _session_rewards: Dictionary = {}
var _session_active: bool = false
var _source_vn_scene: String = ""
## BGM snapshot from save file; consumed once when ExplorationPlayer refreshes the node.
var _pending_restored_bgm: Dictionary = {}

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
		if saved.get("active", false) and str(saved.get("graph_path", "")) == graph_path:
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
		if k in ["force_fresh", "keep_vn_bgm"]:
			continue
		_vars[k] = str(launch_params.get(k, ""))
	emit_signal("session_started", graph)
	_navigate_to(graph.resolve_start_node_id(_vars), false)
	_save_session_state(true)

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
## Emits session_ended with a copy of the rewards Dictionary.
func end_session(carry_rewards: bool = true) -> void:
	if not _session_active:
		return
	var rewards: Dictionary = _session_rewards.duplicate(true) if carry_rewards else {}
	if carry_rewards:
		_apply_rewards(rewards)
	_reset_session_state()
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
	_talked_characters.clear()
	_session_rewards   = {}
	_source_vn_scene   = ""
	_pending_restored_bgm = {}

func _reset_session_state() -> void:
	_clear_session_memory()
	_clear_saved_session()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _session_active:
			_save_session_state(true)
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		if _session_active:
			_save_session_state(true)

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

## Mark a character (node_id + index in node.characters) as talked when remove_after_talk is set.
func mark_char_talked(node_id: String, char_index: int) -> void:
	_talked_characters[node_id + ":" + str(char_index)] = true
	_save_session_state()

## Returns true if the character was already talked to this session (remove_after_talk).
func is_char_talked(node_id: String, char_index: int) -> bool:
	return _talked_characters.has(node_id + ":" + str(char_index))

## Save current session state to SaveManager so it survives a game restart.
## Called automatically on state changes when auto-save is enabled.
## Pass force=true for manual Save and Exit or when re-enabling auto-save.
func _save_session_state(force: bool = false) -> void:
	if not _session_active or _current_graph == null:
		return
	if not force and not SaveManager.exploration_auto_save:
		return
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
		"bgm_path":          BGMManager.get_current_path(),
		"bgm_context":       BGMManager.get_current_context(),
		"bgm_position":      BGMManager.get_playback_position(),
		"bgm_loop_from_sec": BGMManager.get_loop_restart_sec(),
	}
	SaveManager.save_data()

## Write the current session snapshot immediately (used by Save and Exit).
func save_session_now() -> void:
	_save_session_state(true)

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


func _queue_restored_bgm_from_save(sd: Dictionary) -> void:
	var path: String = str(sd.get("bgm_path", "")).strip_edges()
	if path.is_empty():
		_pending_restored_bgm = {}
		return
	_pending_restored_bgm = {
		"path": path,
		"context": str(sd.get("bgm_context", BGMManager.CONTEXT_VN)).strip_edges(),
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
	_navigate_to(node_id, true)

## Move to the previous node in navigation history.
## Returns true on success, false if already at the origin.
func go_back() -> bool:
	if _node_history.size() < 2:
		return false
	_node_history.pop_back()           # remove current node
	var prev_id: String = _node_history.pop_back()  # remove previous (re-pushed by _navigate_to)
	_navigate_to(prev_id, false)
	return true

## Returns true if there is a previous node to go back to.
func can_go_back() -> bool:
	return _node_history.size() >= 2

func _navigate_to(node_id: String, push_current_to_history: bool) -> void:
	if _current_graph == null:
		return
	var target: ExplorationNode = _current_graph.get_node_by_id(node_id)
	if target == null:
		push_error("ExplorationManager: node '%s' not found in graph '%s'." % [
			node_id, _current_graph.graph_id])
		return

	# Fire on_exit events for the node we are leaving
	if not _current_node_id.is_empty():
		var old_node: ExplorationNode = _current_graph.get_node_by_id(_current_node_id)
		if old_node != null:
			_process_events(old_node.resolve_on_exit_events(_vars))
			emit_signal("node_exited", old_node)

	# Update history
	if push_current_to_history and not _current_node_id.is_empty():
		_node_history.append(_current_node_id)
	_current_node_id = node_id
	_node_history.append(node_id)

	# Fire on_enter events for the new node
	_process_events(target.resolve_on_enter_events(_vars))
	emit_signal("node_entered", target)
	_save_session_state()

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

## Public single-event dispatcher — called by VNPlayer for exploration_actions beats.
## Accepts the same action/key/value format as on_enter/on_exit events.
func dispatch_event(action: String, key: String, value: String) -> void:
	_process_events([{"action": action, "key": key, "value": value}])

## Get a session variable value, or default_val if not set.
func get_var(key: String, default_val: String = "") -> String:
	return str(_vars.get(key, default_val))

## Returns true if the session variable is set (regardless of value).
func has_var(key: String) -> bool:
	return _vars.has(key)

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
					_grant_credits(amount)

			"give_booster_pack":
				var pack_ref: String = value if not value.is_empty() else key
				var subject_override: String = key if not value.is_empty() else ""
				_grant_booster_pack_mail(pack_ref, subject_override)

			"set_flag":
				var flags: Variant = _session_rewards.get("flags", {})
				if flags is Dictionary:
					(flags as Dictionary)[key] = value
					_session_rewards["flags"] = flags

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

## Grant shop credits immediately (Collection wallet used by the Shop).
func _grant_credits(amount: int) -> void:
	if amount <= 0 or amount >= 1_000_000:
		push_warning("ExplorationManager: invalid credit amount %d." % amount)
		return
	Collection.add_credits(amount)
	emit_signal("mailbox_reward_granted", {
		"type":         "credits",
		"image_path":   "res://assets/textures/ui/decorations/ui_coin_front.png",
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
	# Configure a standard VS_AI battle using the EXPLORATION game mode.
	# The AI controls player 1; the human plays as player 0.
	GameState.apply_battle_audio_config({
		"battle_bgm": node.battle_bgm,
		"setup_bgm": node.setup_bgm,
		"almost_win_bgm": node.almost_win_bgm,
		"battle_bgm_volume": node.battle_bgm_volume,
	}, "")
	GameState.new_game(GameState.GameMode.EXPLORATION)
	SaveManager.save_data()
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))

## Called by GameBoard._on_game_over() when game_mode == EXPLORATION.
## Stores the result so ExplorationPlayer can read it when it reloads.
func complete_battle_node(won: bool) -> void:
	pending_battle_result = {"won": won, "node_id": _current_node_id}

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
		"Return scene   : %s" % return_scene,
	]
	return "\n".join(lines)
