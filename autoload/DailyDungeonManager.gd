extends Node
# DailyDungeonManager — autoload that owns all Daily Dungeon state.
#
# Responsibilities:
#   • Load dungeon layout files from res://daily_dungeon/layouts/
#   • Check and apply the daily reset (advance playlist, roll modifiers)
#   • Track per-node progress (first clear vs revisit)
#   • Provide API used by DailyDungeonMap, Builder, Activator, GameBoard
#   • Handle Dimensional Gate cross-battle destruction list

# ─────────────────────────────────────────────────────────────
# Modifier catalogue
# ─────────────────────────────────────────────────────────────

const ALL_MODIFIER_KEYS: Array = [
	"frenzy_strike",       # +1 attack per turn (both players)
	"affinity_day",        # 1 random affinity gets +20% ATK or DEF today
	"risk_and_reward",     # +75% credit reward; crystal loss ×1.25
	"crystal_sparkle",     # +20% credit reward
	"lighthouse",          # end of turn: reveal 1 random hidden opponent cell
	"dimensional_gate",    # union costs 0 crystals; union destroyed at next turn start
	"tax_free_zone",       # no crystal tax increase when skipping attack
	"tech_royale",         # multiple Tech cards allowed per turn (still discard after use)
	"sudden_death",        # starting crystals = 3000 instead of default
	"monster_overload",    # all characters +50% ATK and +50% DEF
	"stone_age",           # Tech cards disabled for all players
	"bare_hands_brawling", # character abilities cancelled
	"honored_duel",        # trap effects cancelled
]

const MODIFIER_LABEL: Dictionary = {
	"frenzy_strike":       "Frenzy Strike",
	"affinity_day":        "Affinity Day",
	"risk_and_reward":     "Risk & Reward",
	"crystal_sparkle":     "Crystal Sparkle",
	"lighthouse":          "Lighthouse",
	"dimensional_gate":    "Dimensional Gate",
	"tax_free_zone":       "Tax Free Zone",
	"tech_royale":         "Tech Royale",
	"sudden_death":        "Sudden Death",
	"monster_overload":    "Monster Overload",
	"stone_age":           "Stone Age",
	"bare_hands_brawling": "Bare Hands Brawling",
	"honored_duel":        "Honored Duel",
}

const MODIFIER_DESC: Dictionary = {
	"frenzy_strike":       "+1 attack per turn for both players.",
	"affinity_day":        "A random affinity gets +20% ATK or DEF today.",
	"risk_and_reward":     "+75% credit reward, but losing cards costs 25% more crystals.",
	"crystal_sparkle":     "+20% credit reward from all nodes.",
	"lighthouse":          "End of each turn: 1 random hidden opponent cell is revealed.",
	"dimensional_gate":    "Union summons cost 0 crystals. Union is destroyed at the start of next turn.",
	"tax_free_zone":       "No crystal tax increase when skipping your attack turn.",
	"tech_royale":         "Multiple Tech cards can be played per turn. Each is still discarded after use.",
	"sudden_death":        "Both players start with only 3,000 crystals.",
	"monster_overload":    "All character cards have +50% ATK and +50% DEF.",
	"stone_age":           "Tech cards are disabled for all players.",
	"bare_hands_brawling": "All character card abilities are cancelled.",
	"honored_duel":        "All trap card effects are cancelled.",
}

# Modifier is positive (shown in green) or negative (shown in red) — for UI colouring
const MODIFIER_POSITIVE: Dictionary = {
	"frenzy_strike": true, "affinity_day": true, "risk_and_reward": true,
	"crystal_sparkle": true, "lighthouse": true, "dimensional_gate": true,
	"tax_free_zone": true, "tech_royale": true,
	"sudden_death": false, "monster_overload": false,
	"stone_age": false, "bare_hands_brawling": false, "honored_duel": false,
}

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

## For Affinity Day: which affinity and which stat are boosted today.
var affinity_day_affinity: String = ""  # e.g. "ARCANE"
var affinity_day_stat:     String = ""  # "atk" or "def"

## Progress: dungeon_id → { node_id → { "cleared": bool, "first_clear_done": bool } }
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

## Player's current node on the dungeon map — persisted across scene changes so the
## sprite walks from the correct position after returning from a battle.
var player_map_node_id: String = ""

## Set by VNPlayer when a dungeon_call beat fires.
## Non-empty = player is in a VN-launched dungeon session.
var vn_dungeon_id:      String = ""
var vn_dungeon_on_win:  String = ""
var vn_dungeon_on_lose: String = ""

# ─────────────────────────────────────────────────────────────
# Layout cache
# ─────────────────────────────────────────────────────────────

var _layout_cache: Dictionary = {}  # dungeon_id → parsed layout Dictionary

const LAYOUTS_DIR: String = "res://daily_dungeon/layouts/"

# ─────────────────────────────────────────────────────────────
# _ready
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# State is populated by SaveManager.load_data() calling our load_from_dict().
	# Seed the default playlist if none exists yet (first run).
	if playlist.is_empty():
		_seed_default_playlist()
	_check_daily_reset()

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
	# Pull modifiers from current slot
	var slot: Dictionary = playlist[playlist_index]
	active_modifiers = slot.get("modifiers", []).duplicate()
	# Roll affinity_day fresh each day
	if "affinity_day" in active_modifiers:
		_roll_affinity_day()
	# Clear today's node progress (fresh dungeon each day)
	var dungeon_id: String = slot.get("dungeon_id", "")
	if dungeon_id != "":
		node_progress[dungeon_id] = {}

func _roll_affinity_day() -> void:
	var affinities: Array = ["ARCANE", "DIVINE", "NATURE", "ANIMA", "CHAOS", "COSMIC", "BIO"]
	affinity_day_affinity = affinities[randi() % affinities.size()]
	affinity_day_stat = "atk" if randf() > 0.5 else "def"

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

## True if the modifier key is active today.
func has_modifier(key: String) -> bool:
	return key in active_modifiers

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
# Battle launch
# ─────────────────────────────────────────────────────────────

## Called by DailyDungeonMap when the player taps a node.
## Sets up GameState and changes to game_board.tscn.
func start_node_battle(node: Dictionary, parent_node: Node) -> void:
	var node_id: String = node.get("id", "")
	active_battle_node_id = node_id

	# Set game mode
	GameState.game_mode = GameState.GameMode.DAILY_DUNGEON
	GameState.active_dungeon_node_id = node_id

	# Configure AI deck via campaign_enemy_config pattern
	var deck: Dictionary = node.get("ai_deck", {})
	GameState.campaign_enemy_config = {
		"forced_characters": deck.get("characters", []),
		"forced_traps":      deck.get("traps", []),
		"forced_tech":       deck.get("tech", []),
	}

	# No VN for dungeon battles — but we want _vn_battle_pending so new_game()
	# doesn't reset our modifier-adjusted config.
	GameState._vn_battle_pending = true

	# Apply per-node battle settings
	var bs: Dictionary = node.get("battle_settings", {})

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
	GameState.battle_bgm_path   = bgm if bgm != "" else "res://assets/audio/bgm_battle_2.mp3"
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
	var raw_afc: Variant = bs.get("ai_forced_cells", [])
	GameState.battle_player_forced_cells = raw_pfc if raw_pfc is Array else []
	GameState.battle_ai_forced_cells     = raw_afc if raw_afc is Array else []

	# Pass today's active modifiers to GameState so GameBoard/TurnManager can read them
	GameState.active_dungeon_modifiers = active_modifiers.duplicate()

	# Affinity Day state
	GameState.dungeon_affinity_day_affinity = affinity_day_affinity
	GameState.dungeon_affinity_day_stat     = affinity_day_stat

	# Launch the game board
	return_to_dungeon_map = true
	CheckerTransition.fade_out_to_battle(func() -> void:
		parent_node.get_tree().change_scene_to_file("res://scenes/game_board.tscn"))

# ─────────────────────────────────────────────────────────────
# Battle completion
# ─────────────────────────────────────────────────────────────

## Called by GameBoard._on_game_over() when a daily dungeon battle ends.
## node_id: the node that was fought. won: true = player won.
func complete_node(node_id: String, won: bool) -> void:
	pending_battle_result = {"node_id": node_id, "won": won}
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

	# Booster pack for boss first-clear
	if node_type == "boss" and was_first:
		var pack_name: String = node_data.get("pack_reward", "Starter Pack")
		if pack_name.is_empty():
			pack_name = "Starter Pack"
		MailboxManager.send_mail(
			"Daily Dungeon",
			"Boss Clear Reward — %s" % label,
			"You defeated the boss! Here's a booster pack.",
			{"type": "booster_pack", "pack_name": pack_name}
		)

	SaveManager.save_data()

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
	if "affinity_day" in active_modifiers:
		_roll_affinity_day()
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
		"affinity_day_affinity": affinity_day_affinity,
		"affinity_day_stat":     affinity_day_stat,
		"node_progress":         node_progress.duplicate(true),
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
	affinity_day_affinity = str(d.get("affinity_day_affinity", ""))
	affinity_day_stat     = str(d.get("affinity_day_stat", ""))
	var raw_np: Variant   = d.get("node_progress", {})
	node_progress = raw_np if raw_np is Dictionary else {}
	vn_dungeon_id      = str(d.get("vn_dungeon_id",      ""))
	vn_dungeon_on_win  = str(d.get("vn_dungeon_on_win",  ""))
	vn_dungeon_on_lose = str(d.get("vn_dungeon_on_lose", ""))
	if playlist.is_empty():
		_seed_default_playlist()
