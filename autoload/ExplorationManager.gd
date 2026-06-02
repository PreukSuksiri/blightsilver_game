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
## ─── Event actions (on_enter / on_exit) ────────────────────────────────────
##   give_item   key / value  → add item to session inventory
##   remove_item key / value  → remove item from session inventory
##   set_var     key + value  → set session variable
##   give_credits value (int) → add credits to the session reward pool
##   set_flag    key + value  → set a flag carried to SaveManager on session end
##   show_message value       → emit message_posted signal (toast in UI)
##   play_sfx    value        → play the audio file at the given res:// path
##
## ─── Connection condition types ────────────────────────────────────────────
##   has_item      key        → inventory contains key
##   not_has_item  key        → inventory does NOT contain key
##   var_equals    key+value  → vars[key] == value
##   var_not_equals key+value → vars[key] != value

const EXPLORATION_PLAYER_SCENE: String = "res://scenes/exploration_player.tscn"

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

# ─────────────────────────────────────────────────────────────
# Public configuration (set before launch / start_session)
# ─────────────────────────────────────────────────────────────

## Scene to change to when the session ends.
## Defaults to the main menu.
var return_scene: String = "res://scenes/main_menu.tscn"

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

# Accumulated rewards — applied to main game when end_session(carry_rewards=true) is called.
# { "credits": int, "flags": { key: value, ... } }
var _session_rewards: Dictionary = {}
var _session_active: bool = false

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
## Equivalent to start_session() + change_scene_to_file(EXPLORATION_PLAYER_SCENE).
func launch(graph_path: String, p_return_scene: String = "res://scenes/main_menu.tscn") -> void:
	return_scene = p_return_scene
	start_session(graph_path)
	if not _session_active:
		return
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file(EXPLORATION_PLAYER_SCENE))

## Start a new exploration session by loading the graph from a JSON file.
## Clears any previous session data.
## Emits session_started after the start node is entered.
func start_session(graph_path: String) -> void:
	var graph: ExplorationGraph = ExplorationGraph.load_from_file(graph_path)
	if graph == null:
		push_error("ExplorationManager.start_session: failed to load graph at '%s'." % graph_path)
		return
	_reset_session_state()
	_current_graph = graph
	_session_rewards = {"credits": 0, "flags": {}}
	_session_active  = true
	emit_signal("session_started", graph)
	_navigate_to(graph.start_node_id, false)

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

func _reset_session_state() -> void:
	_session_active    = false
	_current_graph     = null
	_current_node_id   = ""
	_node_history.clear()
	_inventory.clear()
	_vars.clear()
	_session_rewards   = {}
	_clear_saved_session()

## Save current session state to SaveManager so it survives a game restart.
## Called automatically on every navigation, inventory, and variable change.
func _save_session_state() -> void:
	if not _session_active or _current_graph == null:
		return
	SaveManager.exploration_session = {
		"active":          true,
		"graph_path":      _current_graph._source_path,
		"current_node_id": _current_node_id,
		"history":         _node_history.duplicate(),
		"inventory":       _inventory.duplicate(),
		"vars":            _vars.duplicate(),
		"rewards":         _session_rewards.duplicate(true),
		"return_scene":    return_scene,
	}
	SaveManager.save_data()

## Clear any stored mid-session data from SaveManager.
func _clear_saved_session() -> void:
	if SaveManager.exploration_session.get("active", false):
		SaveManager.exploration_session = {}
		SaveManager.save_data()

## Restore a previously saved session. Returns true on success.
## Called by ExplorationPlayer when it detects a saved session in SaveManager.
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
	graph._source_path = graph_path
	_current_graph    = graph
	_session_rewards  = sd.get("rewards", {"credits": 0, "flags": {}}).duplicate(true) as Dictionary
	_session_active   = true
	var hist: Variant = sd.get("history", [])
	_node_history     = hist as Array[String] if hist is Array else []
	var inv: Variant  = sd.get("inventory", [])
	_inventory        = inv as Array if inv is Array else []
	var vs: Variant   = sd.get("vars", {})
	_vars             = vs as Dictionary if vs is Dictionary else {}
	return_scene      = str(sd.get("return_scene", "res://scenes/main_menu.tscn"))
	_current_node_id  = str(sd.get("current_node_id", graph.start_node_id))
	emit_signal("session_started", graph)
	var node: ExplorationNode = graph.get_node_by_id(_current_node_id)
	if node != null:
		emit_signal("node_entered", node)
	return true

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
			_process_events(old_node.on_exit_events)
			emit_signal("node_exited", old_node)

	# Update history
	if push_current_to_history and not _current_node_id.is_empty():
		_node_history.append(_current_node_id)
	_current_node_id = node_id
	_node_history.append(node_id)

	# Fire on_enter events for the new node
	_process_events(target.on_enter_events)
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
	for cond: Variant in (conditions as Array):
		if not cond is Dictionary:
			continue
		var cd: Dictionary = cond as Dictionary
		var ctype: String  = str(cd.get("type",  ""))
		var key: String    = str(cd.get("key",   ""))
		var val: String    = str(cd.get("value", ""))
		match ctype:
			"has_item":
				if not has_item(key):
					return false
			"not_has_item":
				if has_item(key):
					return false
			"var_equals":
				if get_var(key) != val:
					return false
			"var_not_equals":
				if get_var(key) == val:
					return false
	return true

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
	emit_signal("inventory_changed", _inventory.duplicate())
	_save_session_state()

## Remove one instance of an item from the session inventory.
func remove_item(item: String) -> void:
	if _inventory.has(item):
		_inventory.erase(item)
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
	_vars[key] = value
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
				var amount: int = int(value) if value.is_valid_int() else (int(key) if key.is_valid_int() else 0)
				if amount > 0:
					var cur: int = int(_session_rewards.get("credits", 0))
					_session_rewards["credits"] = cur + amount
					emit_signal("message_posted", "Found %d credits!" % amount)

			"set_flag":
				var flags: Variant = _session_rewards.get("flags", {})
				if flags is Dictionary:
					(flags as Dictionary)[key] = value
					_session_rewards["flags"] = flags

			"show_message":
				emit_signal("message_posted", value)

			"play_sfx":
				_play_sfx(value)

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
