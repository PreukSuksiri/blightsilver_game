extends Node
# DailyDungeonManager — autoload that owns all Daily Dungeon state.
#
# Responsibilities:
#   • Load dungeon layout files from res://daily_dungeon/layouts/
#   • Check and apply the daily reset (advance playlist, roll modifiers)
#   • Track per-node progress (first clear vs revisit)
#   • Provide API used by DailyDungeonMap, Builder, Activator, GameBoard

# ─────────────────────────────────────────────────────────────
# Modifier catalogue  (loaded from data/dungeon_modifiers.json)
# ─────────────────────────────────────────────────────────────

const MODIFIER_CATALOG_PATH: String = "res://data/dungeon_modifiers.json"

## Array of Dictionaries, each: { key, label, description, positive, implemented }
var _modifier_catalog: Array = []

## Fast lookup: key → catalog entry
var _modifier_by_key: Dictionary = {}

func _load_modifier_catalog() -> void:
	if not FileAccess.file_exists(MODIFIER_CATALOG_PATH):
		push_error("DailyDungeonManager: modifier catalog not found at %s" % MODIFIER_CATALOG_PATH)
		return
	var file := FileAccess.open(MODIFIER_CATALOG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		push_error("DailyDungeonManager: modifier catalog is not a JSON array")
		return
	_modifier_catalog = parsed
	_modifier_by_key.clear()
	for entry: Variant in _modifier_catalog:
		if entry is Dictionary:
			var k: String = str(entry.get("key", ""))
			if k != "":
				_modifier_by_key[k] = entry

## All modifier keys (from catalog).
func get_all_modifier_keys() -> Array:
	var keys: Array = []
	for entry: Variant in _modifier_catalog:
		if entry is Dictionary:
			keys.append(str(entry.get("key", "")))
	return keys

## Human-readable label for a modifier key.
func get_modifier_label(key: String) -> String:
	var entry: Variant = _modifier_by_key.get(key, null)
	if entry is Dictionary:
		return str(entry.get("label", key))
	return key

## Description text for a modifier key.
func get_modifier_desc(key: String) -> String:
	var entry: Variant = _modifier_by_key.get(key, null)
	if entry is Dictionary:
		return str(entry.get("description", ""))
	return ""

## True = positive (green), False = negative (red). no_effect is treated as positive/neutral.
func is_modifier_positive(key: String) -> bool:
	if key.strip_edges() == WHEEL_NO_EFFECT:
		return true
	var entry: Variant = _modifier_by_key.get(key, null)
	if entry is Dictionary:
		return bool(entry.get("positive", true))
	return true

## True if the modifier has engine implementation.
func is_modifier_implemented(key: String) -> bool:
	var entry: Variant = _modifier_by_key.get(key, null)
	if entry is Dictionary:
		return bool(entry.get("implemented", false))
	return false

## Full catalog array (for Builder/Editor UI).
func get_modifier_catalog() -> Array:
	return _modifier_catalog.duplicate()

# ─────────────────────────────────────────────────────────────
# Rewards
# ─────────────────────────────────────────────────────────────

const REWARD_NORMAL_FIRST:   int = 50
const REWARD_NORMAL_REVISIT: int = 5
const REWARD_BOSS_FIRST:     int = 200
const REWARD_BOSS_REVISIT:   int = 20

# ─────────────────────────────────────────────────────────────
# State (persisted via SaveManager)
# ─────────────────────────────────────────────────────────────

## Ordered list of playlist entries. Each entry is a Dictionary:
##   { "dungeon_id": String, "modifiers": Array[String] }
var playlist: Array = []

## Which slot is the current (today's) dungeon.
var playlist_index: int = 0

## Date string of the last midnight reset ("YYYY-MM-DD").
var last_reset_date: String = ""

## Active modifiers for today (derived from playlist[playlist_index].modifiers).
var active_modifiers: Array = []
var node_progress: Dictionary = {}

## Set to true after a dungeon battle ends so MainMenu re-opens the map overlay.
var return_to_dungeon_map: bool = false

## Which node the player is currently battling (set at battle launch).
var active_battle_node_id: String = ""

## Dimensional Gate — unions to destroy at the start of the NEXT turn.
## Array of { "player": int, "row": int, "col": int }
var dimensional_gate_pending: Array = []

## Set by complete_node() so DailyDungeonMap can show the result banner.
## Format: { "node_id": String, "won": bool }  —  cleared by the map after reading.
var pending_battle_result: Dictionary = {}

## Rewards earned in the last won dungeon battle; shown on GameBoard before map return.
var pending_combat_rewards: Array = []

## Player map position, wheel spin count, and wheel-acquired modifiers are stored per dungeon
## in dungeon_runs (see ensure_dungeon_run). Use get/set helpers below — not globals.

## Set by VNPlayer when a dungeon_call beat fires (runtime session only).
var vn_dungeon_id:      String = ""
var vn_dungeon_on_win:  String = ""
var vn_dungeon_on_lose: String = ""

## Per-dungeon run state. dungeon_id → {
##   spin_remaining, wheel_modifiers, player_map_node_id,
##   source_vn_scene, dungeon_on_win, dungeon_on_lose }
var dungeon_runs: Dictionary = {}

const WHEEL_NO_EFFECT: String = "no_effect"
const DEFAULT_SPIN_REMAINING: int = 1

# ─────────────────────────────────────────────────────────────
# Layout cache
# ─────────────────────────────────────────────────────────────

var _layout_cache: Dictionary = {}  # dungeon_id → parsed layout Dictionary

const LAYOUTS_DIR: String = "res://daily_dungeon/layouts/"
const DUNGEON_MAP_SCENE: String = "res://scenes/daily_dungeon_map.tscn"

const SESSION_DAILY: String = "daily"
const SESSION_STORY: String = "story"

## "daily" = main-menu overlay session, "story" = VN-launched full scene, "" = none.
var dungeon_session_kind: String = ""

# ─────────────────────────────────────────────────────────────
# _ready
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_modifier_catalog()
	# State is populated by SaveManager.load_data() calling our load_from_dict().
	# Daily reset runs there too — never call save_data() from _ready (pre-load race).

# ─────────────────────────────────────────────────────────────
# Layout loading
# ─────────────────────────────────────────────────────────────

## Load and return a dungeon layout by ID, with caching.
func get_layout(dungeon_id: String) -> Dictionary:
	if _layout_cache.has(dungeon_id):
		return _layout_cache[dungeon_id]
	var path: String = LAYOUTS_DIR + dungeon_id + ".json"
	if not FileAccess.file_exists(path):
		push_error("DailyDungeonManager: layout not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("DailyDungeonManager: invalid JSON in %s" % path)
		return {}
	_layout_cache[dungeon_id] = parsed
	return parsed

## Return all dungeon IDs found in the layouts directory.
func get_all_layout_ids() -> Array:
	var ids: Array = []
	var dir := DirAccess.open(LAYOUTS_DIR)
	if dir == null:
		return ids
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			ids.append(fname.trim_suffix(".json"))
		fname = dir.get_next()
	dir.list_dir_end()
	return ids

## Save a layout dict to its JSON file.
func save_layout(layout: Dictionary) -> void:
	var dungeon_id: String = layout.get("id", "")
	if dungeon_id.is_empty():
		push_error("DailyDungeonManager: cannot save layout with no id")
		return
	var path: String = LAYOUTS_DIR + dungeon_id + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("DailyDungeonManager: cannot write layout to %s" % path)
		return
	file.store_string(JSON.stringify(layout, "\t"))
	file.close()
	_layout_cache[dungeon_id] = layout  # update cache

# ─────────────────────────────────────────────────────────────
# Daily reset
# ─────────────────────────────────────────────────────────────

func apply_daily_reset_after_load() -> void:
	if playlist.is_empty():
		_seed_default_playlist()
	_check_daily_reset()


func _check_daily_reset() -> void:
	var today: String = _today_date_string()
	if today != last_reset_date:
		_advance_to_next_day()
		last_reset_date = today
		SaveManager.save_data()

func _today_date_string() -> String:
	var dt: Dictionary = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]

func _advance_to_next_day() -> void:
	if playlist.is_empty():
		return
	# Advance playlist index (loop)
	if last_reset_date != "":  # don't advance on very first launch
		playlist_index = (playlist_index + 1) % playlist.size()
	# Pull playlist slot modifiers (daily schedule — not wheel-acquired)
	var slot: Dictionary = playlist[playlist_index]
	active_modifiers = slot.get("modifiers", []).duplicate()
	# Reset today's dungeon run (progress + wheel state)
	var dungeon_id: String = slot.get("dungeon_id", "")
	if dungeon_id != "":
		node_progress[dungeon_id] = {}
		reset_dungeon_run_wheel_state(dungeon_id)

# ─────────────────────────────────────────────────────────────
# Current dungeon queries
# ─────────────────────────────────────────────────────────────

func get_current_dungeon_id() -> String:
	if playlist.is_empty():
		return ""
	return playlist[playlist_index].get("dungeon_id", "")

func get_next_dungeon_id() -> String:
	if playlist.size() < 2:
		return get_current_dungeon_id()
	var next_idx: int = (playlist_index + 1) % playlist.size()
	return playlist[next_idx].get("dungeon_id", "")

func get_current_layout() -> Dictionary:
	return get_layout(get_current_dungeon_id())

# ─────────────────────────────────────────────────────────────
# Per-dungeon run state (wheel, map position, campaign resume)
# ─────────────────────────────────────────────────────────────

func _default_dungeon_run() -> Dictionary:
	return {
		"spin_remaining": DEFAULT_SPIN_REMAINING,
		"wheel_modifiers": [],
		"player_map_node_id": "",
		"source_vn_scene": "",
		"dungeon_on_win": "",
		"dungeon_on_lose": "",
	}

func ensure_dungeon_run(dungeon_id: String) -> Dictionary:
	if dungeon_id.is_empty():
		return _default_dungeon_run()
	if not dungeon_runs.has(dungeon_id):
		dungeon_runs[dungeon_id] = _default_dungeon_run()
	return dungeon_runs[dungeon_id]

func get_spin_remaining(dungeon_id: String) -> int:
	if dungeon_id.is_empty():
		return DEFAULT_SPIN_REMAINING
	return int(ensure_dungeon_run(dungeon_id).get("spin_remaining", DEFAULT_SPIN_REMAINING))

func get_active_spin_remaining() -> int:
	return get_spin_remaining(_get_active_dungeon_id())

func get_player_map_node(dungeon_id: String) -> String:
	if dungeon_id.is_empty():
		return ""
	return str(ensure_dungeon_run(dungeon_id).get("player_map_node_id", ""))

func get_active_player_map_node() -> String:
	return get_player_map_node(_get_active_dungeon_id())

func set_player_map_node(dungeon_id: String, node_id: String) -> void:
	if dungeon_id.is_empty():
		return
	var run: Dictionary = ensure_dungeon_run(dungeon_id)
	run["player_map_node_id"] = node_id
	dungeon_runs[dungeon_id] = run

func set_active_player_map_node(node_id: String) -> void:
	set_player_map_node(_get_active_dungeon_id(), node_id)

func get_wheel_modifiers(dungeon_id: String) -> Array:
	if dungeon_id.is_empty():
		return []
	var raw: Variant = ensure_dungeon_run(dungeon_id).get("wheel_modifiers", [])
	return (raw as Array).duplicate() if raw is Array else []

func get_playlist_modifiers() -> Array:
	return active_modifiers.duplicate()

## Playlist slot modifiers (daily) + wheel-acquired modifiers for this dungeon.
func get_dungeon_modifiers(dungeon_id: String) -> Array:
	var merged: Array = []
	if dungeon_id == get_current_dungeon_id() and not is_story_session():
		for key: String in active_modifiers:
			if key not in merged:
				merged.append(key)
	for key: String in get_wheel_modifiers(dungeon_id):
		if key not in merged:
			merged.append(key)
	return merged

func reset_dungeon_run_wheel_state(dungeon_id: String) -> void:
	if dungeon_id.is_empty():
		return
	var run: Dictionary = ensure_dungeon_run(dungeon_id)
	run["spin_remaining"] = DEFAULT_SPIN_REMAINING
	run["wheel_modifiers"] = []
	run["player_map_node_id"] = ""
	dungeon_runs[dungeon_id] = run

func reset_all_dungeon_spin_remaining() -> int:
	var count: int = 0
	for dungeon_id: String in dungeon_runs.keys():
		var run: Dictionary = ensure_dungeon_run(dungeon_id)
		run["spin_remaining"] = DEFAULT_SPIN_REMAINING
		dungeon_runs[dungeon_id] = run
		count += 1
	return count

func persist_dungeon_run(dungeon_id: String) -> void:
	if dungeon_id.is_empty():
		return
	var run: Dictionary = ensure_dungeon_run(dungeon_id)
	if vn_dungeon_id == dungeon_id:
		if vn_dungeon_on_win != "":
			run["dungeon_on_win"] = vn_dungeon_on_win
		if vn_dungeon_on_lose != "":
			run["dungeon_on_lose"] = vn_dungeon_on_lose
	dungeon_runs[dungeon_id] = run
	SaveManager.save_data()

func _import_legacy_run(dungeon_id: String, data: Dictionary) -> void:
	if dungeon_id.is_empty():
		return
	var run: Dictionary = ensure_dungeon_run(dungeon_id)
	if data.has("source_vn_scene"):
		run["source_vn_scene"] = str(data.get("source_vn_scene", ""))
	if data.has("dungeon_on_win"):
		run["dungeon_on_win"] = str(data.get("dungeon_on_win", ""))
	if data.has("dungeon_on_lose"):
		run["dungeon_on_lose"] = str(data.get("dungeon_on_lose", ""))
	if data.has("player_map_node_id"):
		run["player_map_node_id"] = str(data.get("player_map_node_id", ""))
	if data.has("spin_wheel_remaining"):
		run["spin_remaining"] = int(data.get("spin_wheel_remaining", DEFAULT_SPIN_REMAINING))
	elif data.has("spin_remaining"):
		run["spin_remaining"] = int(data.get("spin_remaining", DEFAULT_SPIN_REMAINING))
	var raw_mods: Variant = data.get("wheel_modifiers", data.get("active_modifiers", null))
	if raw_mods is Array:
		run["wheel_modifiers"] = (raw_mods as Array).duplicate()
	dungeon_runs[dungeon_id] = run

func _migrate_legacy_save_state(legacy: Dictionary) -> void:
	var raw_sds: Variant = legacy.get("story_dungeon_saves", {})
	if raw_sds is Dictionary:
		for dungeon_id: String in (raw_sds as Dictionary):
			_import_legacy_run(dungeon_id, (raw_sds as Dictionary)[dungeon_id])

	var legacy_spin: int = int(legacy.get("spin_wheel_remaining", DEFAULT_SPIN_REMAINING))
	var legacy_player: String = str(legacy.get("player_map_node_id", ""))
	var legacy_vn: String = str(legacy.get("vn_dungeon_id", ""))
	if legacy_spin != DEFAULT_SPIN_REMAINING or legacy_player != "" or legacy_vn != "":
		var target_id: String = legacy_vn
		if target_id.is_empty():
			for did: String in node_progress:
				if not (node_progress[did] as Dictionary).is_empty():
					target_id = did
					break
		if target_id.is_empty():
			target_id = get_current_dungeon_id()
		if target_id != "":
			var run: Dictionary = ensure_dungeon_run(target_id)
			if legacy_player != "":
				run["player_map_node_id"] = legacy_player
			if legacy_spin != DEFAULT_SPIN_REMAINING:
				run["spin_remaining"] = legacy_spin
			dungeon_runs[target_id] = run
	if not playlist.is_empty():
		var slot: Dictionary = playlist[playlist_index]
		active_modifiers = slot.get("modifiers", []).duplicate()

## True if the modifier key is active for the current dungeon run.
func has_modifier(key: String) -> bool:
	return key in get_dungeon_modifiers(_get_active_dungeon_id())

## Outcome pool for a wheel node.
## Priority: custom wheel_outcomes list → wheel_outcome_count sample → full catalog pool.
func get_wheel_outcome_pool(node: Dictionary) -> Array:
	var raw: Variant = node.get("wheel_outcomes", [])
	if raw is Array and not raw.is_empty():
		return raw.duplicate()
	var count: int = int(node.get("wheel_outcome_count", 0))
	if count > 0:
		return _build_counted_wheel_pool(node, count)
	return _full_wheel_pool()

func _full_wheel_pool() -> Array:
	var pool: Array = [WHEEL_NO_EFFECT]
	for key: String in _enabled_modifier_keys():
		pool.append(key)
	return pool

func _enabled_modifier_keys() -> Array:
	var keys: Array = []
	for key: String in get_all_modifier_keys():
		if key.is_empty():
			continue
		var entry: Variant = _modifier_by_key.get(key, null)
		if entry is Dictionary and not bool(entry.get("enabled", true)):
			continue
		keys.append(key)
	return keys

## Picks [count] segments: always includes no_effect, rest are distinct modifiers
## (deterministic per dungeon + node id so the wheel layout stays stable).
func _build_counted_wheel_pool(node: Dictionary, count: int) -> Array:
	count = maxi(1, count)
	var pool: Array = [WHEEL_NO_EFFECT]
	if count == 1:
		return pool
	var keys: Array = _enabled_modifier_keys()
	if keys.is_empty():
		return pool
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%s:wheel" % [_get_active_dungeon_id(), str(node.get("id", ""))])
	var shuffled: Array = keys.duplicate()
	for i: int in range(shuffled.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp
	var need: int = mini(count - 1, shuffled.size())
	for i: int in range(need):
		pool.append(shuffled[i])
	return pool

## Apply a wheel spin result for the current run.
## When the active layout has clear_modifiers_on_spin, replaces all prior modifiers first.
func apply_wheel_outcome(outcome_key: String) -> void:
	var dungeon_id: String = _get_active_dungeon_id()
	if dungeon_id.is_empty():
		return
	var run: Dictionary = ensure_dungeon_run(dungeon_id)
	run["spin_remaining"] = maxi(0, int(run.get("spin_remaining", DEFAULT_SPIN_REMAINING)) - 1)
	var layout: Dictionary = get_layout(dungeon_id)
	var wheel_mods: Array = get_wheel_modifiers(dungeon_id)
	if bool(layout.get("clear_modifiers_on_spin", false)):
		wheel_mods.clear()
	if outcome_key != WHEEL_NO_EFFECT and outcome_key not in wheel_mods:
		wheel_mods.append(outcome_key)
	run["wheel_modifiers"] = wheel_mods
	dungeon_runs[dungeon_id] = run
	SaveManager.save_data()

## Return credit reward multiplier from Crystal Sparkle / Risk & Reward.
func credit_multiplier() -> float:
	var mult: float = 1.0
	if has_modifier("crystal_sparkle"):
		mult += 0.20
	if has_modifier("risk_and_reward"):
		mult += 0.75
	return mult

# ─────────────────────────────────────────────────────────────
# Node status
# ─────────────────────────────────────────────────────────────

## Returns "cleared", "available", or "locked" for a node in the current dungeon.
## Rule: all nodes are freely accessible (any node can be played at any time),
## but only after arriving — i.e., the player can pick any node. We mark "locked"
## only when the dungeon hasn't started yet (no node cleared). Entry node is always available.
func get_node_status(node_id: String) -> String:
	var dungeon_id: String = _get_active_dungeon_id()
	var progress: Dictionary = node_progress.get(dungeon_id, {})
	if progress.has(node_id) and progress[node_id].get("cleared", false):
		return "cleared"
	# Entry node is always available
	var layout: Dictionary = get_layout(dungeon_id)
	for node: Dictionary in layout.get("nodes", []):
		if node.get("id", "") == node_id and node.get("is_entry", false):
			return "available"
	# Any node is available once at least one adjacent (connected) node is cleared
	for conn: Array in layout.get("connections", []):
		if conn.size() < 2:
			continue
		var a: String = conn[0]
		var b: String = conn[1]
		if b == node_id and _node_is_cleared(dungeon_id, a):
			return "available"
		if a == node_id and _node_is_cleared(dungeon_id, b):
			return "available"
	# Allow free access if any node is cleared
	if not progress.is_empty():
		return "available"
	return "locked"

func _node_is_cleared(dungeon_id: String, node_id: String) -> bool:
	return node_progress.get(dungeon_id, {}).get(node_id, {}).get("cleared", false)

## Routes progress tracking to the VN dungeon when active, otherwise to the playlist dungeon.
func _get_active_dungeon_id() -> String:
	if vn_dungeon_id != "":
		return vn_dungeon_id
	return get_current_dungeon_id()

## Returns true when the dungeon's win condition is met.
## Win = all boss nodes cleared; if no boss nodes, all nodes cleared.
func is_dungeon_cleared(dungeon_id: String) -> bool:
	var layout: Dictionary = get_layout(dungeon_id)
	var nodes: Array = layout.get("nodes", [])
	var check: Array = []
	for nd: Dictionary in nodes:
		if nd.get("type", "normal") == "boss":
			check.append(nd)
	if check.is_empty():
		check = nodes
	if check.is_empty():
		return false
	for nd: Dictionary in check:
		if not _node_is_cleared(dungeon_id, nd.get("id", "")):
			return false
	return true

func is_first_clear(node_id: String) -> bool:
	var dungeon_id: String = _get_active_dungeon_id()
	return not node_progress.get(dungeon_id, {}).get(node_id, {}).get("first_clear_done", false)

# ─────────────────────────────────────────────────────────────
# Session (daily overlay vs story scene)
# ─────────────────────────────────────────────────────────────

func is_story_session() -> bool:
	return dungeon_session_kind == SESSION_STORY

func is_daily_session() -> bool:
	return dungeon_session_kind == SESSION_DAILY

func begin_story_session(
		dungeon_id: String,
		on_win: String,
		on_lose: String,
		source_vn: String = "") -> void:
	dungeon_session_kind = SESSION_STORY
	vn_dungeon_id = dungeon_id
	vn_dungeon_on_win = on_win
	vn_dungeon_on_lose = on_lose
	var run: Dictionary = ensure_dungeon_run(dungeon_id)
	if source_vn != "":
		run["source_vn_scene"] = source_vn
	run["dungeon_on_win"] = on_win
	run["dungeon_on_lose"] = on_lose
	dungeon_runs[dungeon_id] = run
	persist_dungeon_run(dungeon_id)

func begin_daily_session() -> void:
	dungeon_session_kind = SESSION_DAILY
	vn_dungeon_id = ""
	vn_dungeon_on_win = ""
	vn_dungeon_on_lose = ""

func end_daily_session() -> void:
	if dungeon_session_kind == SESSION_DAILY:
		dungeon_session_kind = ""

func end_story_session() -> void:
	vn_dungeon_id = ""
	vn_dungeon_on_win = ""
	vn_dungeon_on_lose = ""
	if dungeon_session_kind == SESSION_STORY:
		dungeon_session_kind = ""
	SaveManager.save_data()

## Save story dungeon progress and leave the active story session (map position kept).
func exit_story_to_main_menu(from_node_id: String = "") -> void:
	if not from_node_id.is_empty() and vn_dungeon_id != "":
		set_player_map_node(vn_dungeon_id, from_node_id)
	if vn_dungeon_id != "":
		persist_dungeon_run(vn_dungeon_id)
	end_story_session()

func has_story_dungeon_save(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	var progress: Dictionary = node_progress.get(dungeon_id, {})
	if not progress.is_empty():
		return true
	if not dungeon_runs.has(dungeon_id):
		return false
	var run: Dictionary = dungeon_runs[dungeon_id]
	if not str(run.get("player_map_node_id", "")).is_empty():
		return true
	var mods: Variant = run.get("wheel_modifiers", [])
	if mods is Array and not (mods as Array).is_empty():
		return true
	if int(run.get("spin_remaining", DEFAULT_SPIN_REMAINING)) == 0:
		return true
	return false

func resume_story_dungeon(dungeon_id: String) -> void:
	var run: Dictionary = dungeon_runs.get(dungeon_id, {})
	if run.is_empty():
		return
	begin_story_session(
		dungeon_id,
		str(run.get("dungeon_on_win", "")),
		str(run.get("dungeon_on_lose", "")),
		str(run.get("source_vn_scene", "")))
	SaveManager.save_data()

func reset_story_dungeon_chapter(dungeon_id: String) -> void:
	node_progress.erase(dungeon_id)
	dungeon_runs.erase(dungeon_id)
	SaveManager.save_data()

func clear_story_dungeon_save(dungeon_id: String) -> void:
	dungeon_runs.erase(dungeon_id)
	SaveManager.save_data()

## Scan a VN JSON for the first dungeon_call beat (used by campaign chapter picker).
func find_dungeon_call_in_vn(vn_path: String) -> Dictionary:
	var path: String = vn_path.strip_edges()
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Array:
		return {}
	for beat: Variant in parsed:
		if not beat is Dictionary:
			continue
		var dungeon_id: String = str((beat as Dictionary).get("dungeon_call", "")).strip_edges()
		if dungeon_id == "":
			continue
		return {
			"dungeon_id": dungeon_id,
			"dungeon_on_win": str((beat as Dictionary).get("dungeon_on_win", "")),
			"dungeon_on_lose": str((beat as Dictionary).get("dungeon_on_lose", "")),
		}
	return {}

func get_active_dungeon_id() -> String:
	return _get_active_dungeon_id()

func get_post_battle_scene() -> String:
	if is_story_session():
		return DUNGEON_MAP_SCENE
	return "res://scenes/main_menu.tscn"

# ─────────────────────────────────────────────────────────────
# Battle launch
# ─────────────────────────────────────────────────────────────

const ENEMY_TECH_SLOTS: int = 3

## Merge battle-settings tech slots with ai_deck / enemy_deck fallback (empty slot = random at deal).
func resolve_enemy_forced_tech(slots: Variant, deck_tech: Array) -> Array:
	var out: Array = []
	var slot_arr: Array = slots if slots is Array else []
	for i: int in range(ENEMY_TECH_SLOTS):
		var n: String = ""
		if i < slot_arr.size():
			n = str(slot_arr[i]).strip_edges()
		if n.is_empty() and i < deck_tech.size():
			n = str(deck_tech[i]).strip_edges()
		out.append(n)
	return out

## Called by DailyDungeonMap when the player taps a node.
## Sets up GameState and changes to game_board.tscn.
func start_node_battle(node: Dictionary, parent_node: Node) -> void:
	var node_id: String = node.get("id", "")
	active_battle_node_id = node_id

	# Set game mode
	GameState.game_mode = GameState.GameMode.DAILY_DUNGEON
	GameState.active_dungeon_node_id = node_id

	# Configure AI deck — vault entry overrides inline ai_deck
	var bs: Dictionary = node.get("battle_settings", {})
	var vault_cfg: Dictionary = AIDeckVault.resolve_vault_from_dict(node)
	if not bool(vault_cfg.get("ok", false)):
		vault_cfg = AIDeckVault.resolve_vault_from_dict(bs)
	if bool(vault_cfg.get("ok", false)):
		AIDeckVault.apply_enemy_battle_config(vault_cfg)
	else:
		var deck: Dictionary = node.get("ai_deck", {})
		var deck_tech: Array = deck.get("tech", [])
		var merged_tech: Array = resolve_enemy_forced_tech(bs.get("ai_forced_tech", []), deck_tech)
		GameState.campaign_enemy_config = {
			"forced_characters": deck.get("characters", []),
			"forced_traps":      deck.get("traps", []),
			"forced_tech":       merged_tech,
		}
		var raw_afc: Variant = bs.get("ai_forced_cells", [])
		GameState.battle_ai_forced_cells = raw_afc if raw_afc is Array else []

	# No VN for dungeon battles — but we want _vn_battle_pending so new_game()
	# doesn't reset our modifier-adjusted config.
	GameState._vn_battle_pending = true

	# Apply per-node battle settings

	var p1n: String = str(bs.get("player1_name", ""))
	var p2n: String = str(bs.get("player2_name", ""))
	GameState.campaign_player_names = [p1n, p2n]

	var p1_port: String = str(bs.get("portrait_p1", ""))
	if p1_port != "":
		GameState.player_portraits[0] = p1_port
	var p2_port: String = str(bs.get("portrait_p2", ""))
	if p2_port != "":
		GameState.player_portraits[1] = p2_port

	GameState.portrait_p1_offset = Vector2(
		float(bs.get("portrait_p1_offset_x", 0.0)),
		float(bs.get("portrait_p1_offset_y", 0.0)))
	GameState.portrait_p1_size   = float(bs.get("portrait_p1_size", 1.0))
	GameState.portrait_p2_offset = Vector2(
		float(bs.get("portrait_p2_offset_x", 0.0)),
		float(bs.get("portrait_p2_offset_y", 0.0)))
	GameState.portrait_p2_size   = float(bs.get("portrait_p2_size", 1.0))

	var bgm: String = str(bs.get("battle_bgm", ""))
	GameState.battle_bgm_path   = bgm if bgm != "" else BGMManager.get_default_path(BGMManager.CONTEXT_BATTLE)
	GameState.battle_bgm_volume = float(bs.get("battle_bgm_volume", 100.0))

	GameState.battle_ai_union_enabled     = bool(bs.get("ai_union_enabled", true))
	GameState.battle_player_union_enabled = bool(bs.get("player_union_enabled", true))
	# AI personality overrides (empty string = pick randomly)
	var _apd: String = str(bs.get("ai_personality_defensive", ""))
	var _apo: String = str(bs.get("ai_personality_offensive", ""))
	var _aps: String = str(bs.get("ai_personality_social",    ""))
	if _apd != "": GameState.campaign_enemy_config["ai_personality_defensive"] = _apd
	if _apo != "": GameState.campaign_enemy_config["ai_personality_offensive"] = _apo
	if _aps != "": GameState.campaign_enemy_config["ai_personality_social"]    = _aps

	var raw_pfc: Variant = bs.get("player_forced_cells", [])
	GameState.battle_player_forced_cells = raw_pfc if raw_pfc is Array else []
	if not bool(vault_cfg.get("ok", false)):
		var raw_afc: Variant = bs.get("ai_forced_cells", [])
		GameState.battle_ai_forced_cells = raw_afc if raw_afc is Array else []

	# Pass today's active modifiers to GameState so GameBoard/TurnManager can read them
	GameState.active_dungeon_modifiers = get_dungeon_modifiers(_get_active_dungeon_id()).duplicate()
	dimensional_gate_pending.clear()

	# Launch the game board
	return_to_dungeon_map = true
	CheckerTransition.fade_out_to_battle(func() -> void:
		parent_node.get_tree().change_scene_to_file("res://scenes/game_board.tscn"))

# ─────────────────────────────────────────────────────────────
# Battle completion
# ─────────────────────────────────────────────────────────────

## Called by GameBoard._on_game_over() when a daily dungeon battle ends.
## node_id: the node that was fought. won: true = player won.

## Returns rewards earned in the last won battle and clears the pending list.
func take_pending_combat_rewards() -> Array:
	var result: Array = pending_combat_rewards.duplicate()
	pending_combat_rewards.clear()
	return result


func complete_node(node_id: String, won: bool) -> void:
	pending_battle_result = {"node_id": node_id, "won": won}
	pending_combat_rewards.clear()
	if not won:
		# No reward on loss; progress not recorded
		return

	var dungeon_id: String = _get_active_dungeon_id()
	if not node_progress.has(dungeon_id):
		node_progress[dungeon_id] = {}

	var was_first: bool = not node_progress[dungeon_id].get(node_id, {}).get("first_clear_done", false)

	# Record progress
	node_progress[dungeon_id][node_id] = {
		"cleared":          true,
		"first_clear_done": true,
	}

	# Find node data for type and pack reward
	var layout: Dictionary = get_layout(dungeon_id)
	var node_data: Dictionary = {}
	for n: Dictionary in layout.get("nodes", []):
		if n.get("id", "") == node_id:
			node_data = n
			break

	var node_type: String = node_data.get("type", "normal")
	var label: String     = node_data.get("label", node_id)

	# Credit reward
	var base_credits: int = REWARD_BOSS_FIRST if (node_type == "boss" and was_first) \
		else REWARD_BOSS_REVISIT if (node_type == "boss") \
		else REWARD_NORMAL_FIRST if was_first \
		else REWARD_NORMAL_REVISIT
	var credits: int = int(base_credits * credit_multiplier())

	Collection.add_credits(credits)
	if credits > 0:
		pending_combat_rewards.append({"type": "credits", "amount": credits})

	# Booster pack for boss first-clear
	if node_type == "boss" and was_first:
		var pack_name: String = node_data.get("pack_reward", "Starter Pack")
		if pack_name.is_empty():
			pack_name = "Starter Pack"
		pending_combat_rewards.append({"type": "booster_pack", "pack_name": pack_name})
		MailboxManager.send_mail(
			"Daily Dungeon",
			"Boss Clear Reward — %s" % label,
			"You defeated the boss! Here's a booster pack.",
			{"type": "booster_pack", "pack_name": pack_name}
		)

	SaveManager.save_data()

	if dungeon_session_kind == SESSION_STORY and vn_dungeon_id != "":
		persist_dungeon_run(vn_dungeon_id)

# ─────────────────────────────────────────────────────────────
# Start Over
# ─────────────────────────────────────────────────────────────

## Resets all node progress for the current dungeon and restores the spin wheel.
## Cannot be used when the player is already at the entry node.
## Returns true on success, false if the player is already at the entry node.
func start_over() -> bool:
	var dungeon_id: String = _get_active_dungeon_id()
	var layout: Dictionary = get_layout(dungeon_id)
	# Locate the entry node id
	var entry_id: String = ""
	for nd: Dictionary in layout.get("nodes", []):
		if nd.get("is_entry", false):
			entry_id = nd.get("id", "")
			break
	# Block start-over when already at the entry node
	if get_player_map_node(dungeon_id) == entry_id:
		return false
	# Reset progress and spin wheel for this dungeon only
	node_progress[dungeon_id] = {}
	set_player_map_node(dungeon_id, entry_id)
	var run: Dictionary = ensure_dungeon_run(dungeon_id)
	run["spin_remaining"] = DEFAULT_SPIN_REMAINING
	dungeon_runs[dungeon_id] = run
	SaveManager.save_data()
	return true

# ─────────────────────────────────────────────────────────────
# Playlist management (used by Activator)
# ─────────────────────────────────────────────────────────────

func set_playlist(entries: Array) -> void:
	playlist = entries.duplicate(true)
	playlist_index = clampi(playlist_index, 0, maxi(0, playlist.size() - 1))
	SaveManager.save_data()

func set_playlist_index(idx: int) -> void:
	if playlist.is_empty():
		return
	playlist_index = clampi(idx, 0, playlist.size() - 1)
	var slot: Dictionary = playlist[playlist_index]
	active_modifiers = slot.get("modifiers", []).duplicate()
	SaveManager.save_data()

func set_slot_modifiers(slot_idx: int, mods: Array) -> void:
	if slot_idx < 0 or slot_idx >= playlist.size():
		return
	playlist[slot_idx]["modifiers"] = mods.duplicate()
	if slot_idx == playlist_index:
		active_modifiers = mods.duplicate()
	SaveManager.save_data()

func add_playlist_slot(dungeon_id: String, mods: Array = []) -> void:
	playlist.append({"dungeon_id": dungeon_id, "modifiers": mods.duplicate()})
	SaveManager.save_data()

func remove_playlist_slot(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= playlist.size():
		return
	playlist.remove_at(slot_idx)
	playlist_index = clampi(playlist_index, 0, maxi(0, playlist.size() - 1))
	SaveManager.save_data()

func move_playlist_slot(from_idx: int, to_idx: int) -> void:
	if from_idx < 0 or from_idx >= playlist.size():
		return
	to_idx = clampi(to_idx, 0, playlist.size() - 1)
	var entry: Dictionary = playlist[from_idx]
	playlist.remove_at(from_idx)
	playlist.insert(to_idx, entry)
	SaveManager.save_data()

# ─────────────────────────────────────────────────────────────
# Dimensional Gate
# ─────────────────────────────────────────────────────────────

## Called by GameBoard when a union is summoned under Dimensional Gate modifier.
func register_dimensional_gate_union(player: int, row: int, col: int) -> void:
	dimensional_gate_pending.append({"player": player, "row": row, "col": col})

## Called by TurnManager.start_turn() to destroy pending Dimensional Gate unions.
func pop_dimensional_gate_pending() -> Array:
	var pending: Array = dimensional_gate_pending.duplicate()
	dimensional_gate_pending.clear()
	return pending

# ─────────────────────────────────────────────────────────────
# Default playlist seed
# ─────────────────────────────────────────────────────────────

func _seed_default_playlist() -> void:
	playlist = [
		{"dungeon_id": "dungeon_grove",    "modifiers": []},
		{"dungeon_id": "dungeon_crypt",    "modifiers": []},
		{"dungeon_id": "dungeon_starport", "modifiers": []},
	]
	playlist_index = 0

# ─────────────────────────────────────────────────────────────
# Save / Load (called by SaveManager)
# ─────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"playlist":              playlist.duplicate(true),
		"playlist_index":        playlist_index,
		"last_reset_date":       last_reset_date,
		"active_modifiers":      active_modifiers.duplicate(),
		"node_progress":         node_progress.duplicate(true),
		"dungeon_runs":          dungeon_runs.duplicate(true),
		"vn_dungeon_id":         vn_dungeon_id,
		"vn_dungeon_on_win":     vn_dungeon_on_win,
		"vn_dungeon_on_lose":    vn_dungeon_on_lose,
	}

func load_from_dict(d: Dictionary) -> void:
	var raw_pl: Variant = d.get("playlist", [])
	playlist = raw_pl if raw_pl is Array else []
	playlist_index        = int(d.get("playlist_index", 0))
	last_reset_date       = str(d.get("last_reset_date", ""))
	var raw_mods: Variant = d.get("active_modifiers", [])
	active_modifiers = raw_mods if raw_mods is Array else []
	var raw_np: Variant   = d.get("node_progress", {})
	node_progress = raw_np if raw_np is Dictionary else {}
	var raw_runs: Variant = d.get("dungeon_runs", {})
	dungeon_runs = raw_runs if raw_runs is Dictionary else {}
	vn_dungeon_id      = str(d.get("vn_dungeon_id",      ""))
	vn_dungeon_on_win  = str(d.get("vn_dungeon_on_win",  ""))
	vn_dungeon_on_lose = str(d.get("vn_dungeon_on_lose", ""))
	if playlist.is_empty():
		_seed_default_playlist()
	if dungeon_runs.is_empty():
		_migrate_legacy_save_state(d)
	else:
		# One-time merge if an old save still has story_dungeon_saves only
		var raw_sds: Variant = d.get("story_dungeon_saves", {})
		if raw_sds is Dictionary and not (raw_sds as Dictionary).is_empty():
			for dungeon_id: String in (raw_sds as Dictionary):
				_import_legacy_run(dungeon_id, (raw_sds as Dictionary)[dungeon_id])
