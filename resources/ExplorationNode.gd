extends Resource
## ExplorationNode — a single location in an Exploration graph.
##
## Data is driven by JSON (use from_dict / to_dict). Resources are never saved
## as .tres files; they live inside ExplorationGraph JSON files.
##
## Node type controls runtime behaviour:
##   NORMAL  — standard navigation
##   STORY   — plays a VN scene on enter (vn_scene path required)
##   BATTLE  — starts a grid battle on enter
##   REWARD  — typically gives items/credits via on_enter_events
##   EXIT    — ends the exploration session when the player arrives
##   HUB     — safe waypoint styled differently in the UI
##
## Connections:
##   Each connection is a Dictionary:
##     {
##       "target"      : String   — ID of the destination node
##       "label"       : String   — button text shown to the player
##       "locked_hint" : String   — message shown when locked (e.g. "Requires Rusty Key")
##       "conditions"  : Array    — list of Condition Dicts (all must pass to unlock)
##       "locked_mode" : String   — when conditions fail: "hide" (default) or "disable"
##     }
##
## Condition dict format:
##   { "type": <type_string>, "key": String, "value": String }
##   Supported types:
##     "has_item"      — player inventory contains key
##     "not_has_item"  — player inventory does NOT contain key
##     "var_equals"    — exploration variable[key] == value
##     "var_not_equals"— exploration variable[key] != value
##     "var_greater"   — exploration variable[key] > value
##     "var_less"      — exploration variable[key] < value
##     "at_node"       — player is at node id (key or value)
##
## On-enter / on-exit event dict format:
##   { "action": <action_string>, "key": String, "value": String }
##   Supported actions:
##     "give_item"   — add key (or value if key empty) to session inventory
##     "remove_item" — remove key (or value) from session inventory
##     "set_var"     — set exploration variable[key] = value
##     "give_credits"— grant int(value) shop credits immediately
##     "give_booster_pack" — send pack to mailbox (value = pack name/id;
##                           key = optional mail subject override)
##     "set_flag"    — set carry-over flag[key] = value (persisted to SaveManager)
##     "show_message"— display value as a toast notification
##     "play_sfx"    — play audio at the path stored in value
##
## Usable-item dict format (entries in usable_items):
##   { "item": String, "label": String, "vn_scene": String, "consume": bool }
##   item      — inventory key that must be held for this interaction to appear
##   label     — button text shown (e.g. "Show the badge to the panel")
##   vn_scene  — VN beat JSON to play when used (can be empty for no cutscene)
##   consume   — if true, item is removed from inventory after use

class_name ExplorationNode

# ─────────────────────────────────────────────────────────────
# Node type enum
# ─────────────────────────────────────────────────────────────
enum NodeType {
	NORMAL,   ## Standard navigation — player reads description and picks a path
	STORY,    ## Plays a VN scene when entered; choices appear after the scene finishes
	BATTLE,   ## Starts a 5×5 grid battle; player can navigate after the duel
	REWARD,   ## Usually gives items/credits via on_enter_events
	EXIT,     ## Ends the exploration session; rewards are applied to the main game
	HUB,      ## Main hub node — styled differently; acts as a safe zone
}

# ─────────────────────────────────────────────────────────────
# Fields
# ─────────────────────────────────────────────────────────────

## Unique string identifier for this node (used in connections and history).
@export var id: String = ""

## Display name shown at the top of the player UI when at this node.
@export var title: String = ""

## Conditional title overrides — evaluated in order, first match wins.
## Each entry: { "var": String, "equals": String, "value": String }
@export var title_conditions: Array = []

## Descriptive flavour text shown to the player.
@export var description: String = ""

## Conditional description overrides — evaluated in order, first match wins.
## Each entry: { "var": String, "equals": String, "value": String }
@export var description_conditions: Array = []

## Behaviour type — controls what happens when the player enters this node.
@export var node_type: NodeType = NodeType.NORMAL

## Path to a background image (res:// path). Empty = keep the previous background.
@export var background: String = ""

## Conditional background overrides — evaluated in order, first match wins.
## Each entry: { "var": String, "equals": String, "path": String }
## If a match is found its "path" is used instead of `background`.
@export var background_conditions: Array = []

## Path to a VN beat JSON file. Used by STORY nodes (or as an optional entry cutscene).
@export var vn_scene: String = ""

## Conditional VN scene overrides — evaluated in order, first match wins.
## Each entry: { "var": String, "equals": String, "path": String, "play_once": bool,
##               optional "after_actions": Array (same format as vn_after_actions) }
@export var vn_scene_conditions: Array = []

## When to play vn_scene: "on_enter" (default), "on_exit", or "on_var_change".
@export var vn_trigger: String = "on_enter"

## For vn_trigger "on_var_change": session variable name to watch (empty = any var).
@export var vn_trigger_var: String = ""

## For vn_trigger "on_var_change": play when the var equals this value (empty = any value).
@export var vn_trigger_equals: String = ""

## If true, the node's vn_scene plays only once per session (default true).
@export var vn_play_once: bool = true

## When true (default), exploration keeps its current BGM through the node's VN call —
## VN music beats are ignored. When false, the VN may change music; the last track
## keeps playing after the VN ends (exploration overlay does not fade out on exit).
@export var vn_keep_bgm: bool = true

## Actions run after the default vn_scene finishes (when no vn_scene_condition matches).
## Each entry: { "action": String, "key": String, "value": String, optional "play_once" }.
@export var vn_after_actions: Array = []

## If true, the info panel (title + description) opens automatically when the player enters.
## When a vn_scene is also set, the info panel appears first; VN plays after it is dismissed.
@export var show_info_on_enter: bool = true

## If true, a "Who is here" section listing characters is shown inside the info panel.
@export var show_who_is_here: bool = true

## Path to a BGM track to start when entering this node. Empty = keep current music.
@export var music: String = ""

## Conditional music overrides — evaluated in order, first match wins.
## Each entry: { "var": String, "equals": String, "path": String }
## If a match is found its "path" is used instead of `music`.
@export var music_conditions: Array = []

## BATTLE node audio — applied when start_battle_for_node() runs.
## Blank paths fall back to engine defaults at battle start.
@export var battle_bgm: String = ""
@export var setup_bgm: String = ""
@export var almost_win_bgm: String = ""
@export var battle_bgm_volume: float = 100.0

## Events fired in order when the player ENTERS this node.
## Each entry is a Dictionary (see format above).
@export var on_enter_events: Array = []

## Conditional on-enter event overrides — evaluated in order, first match wins.
## Each entry: { "var": String, "equals": String, "events": Array }
@export var on_enter_events_conditions: Array = []

## Events fired in order when the player LEAVES this node.
@export var on_exit_events: Array = []

## Conditional on-exit event overrides — evaluated in order, first match wins.
## Each entry: { "var": String, "equals": String, "events": Array }
@export var on_exit_events_conditions: Array = []

## Outgoing connections — each is a Dictionary (see format above).
@export var connections: Array = []

## Items that can be actively "used" at this node, optionally triggering a VN scene.
## Each entry is a Dictionary (see usable-item format above).
@export var usable_items: Array = []

## Investigable points overlaid on the background image (left 52% of viewport).
## Each entry:
##   { "x_norm": float, "y_norm": float   — centre position (0.0–1.0)
##     "icon": String                      — res:// image path; empty = 24×24 invisible hitbox
##     "icon_scale": float                 — display size as % of natural image size (default 100)
##     "tooltip": String                   — text shown on hover
##     "actions": Array                    — action dicts fired on click (see on_enter_events format)
##                                           extra action types: "play_vn" (optional play_once), "navigate_to", "play_puzzle"
##                                           play_puzzle: value = puzzle id, key = optional params (JSON or text)
##                                           play_puzzle gates all other actions until solved
##     "conditions": Array                 — condition dicts (same format as connection conditions)
##     "vn_scene": String                  — legacy field; treated as play_vn action if actions empty
##   }
@export var clickable_spots: Array = []

## Characters that can be spoken to at this node.
## Each entry is a Dictionary:
##   { "name": String, "vn_scene": String, "conditions": Array,
##     "canon_story": bool, "play_once": bool, "remove_after_talk": bool, "thumbnail": String }
## conditions format is the same as connection conditions (all must pass to show).
## canon_story — when true, pulses the chat HUD icon while this character can be talked to.
@export var characters: Array = []

## Editor-only: position of this GraphNode in the ExplorationEditor canvas.
@export var editor_position: Vector2 = Vector2.ZERO

# ─────────────────────────────────────────────────────────────
# Conditional resolution (first match wins; falls back to base field)
# ─────────────────────────────────────────────────────────────

func _var_matches(vars: Dictionary, var_key: String, equals: String) -> bool:
	return not var_key.is_empty() and str(vars.get(var_key, "")) == equals

func _resolve_cond_string(base: String, conditions: Array, vars: Dictionary, value_field: String) -> String:
	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue
		var cd: Dictionary = cond as Dictionary
		if _var_matches(vars, str(cd.get("var", "")), str(cd.get("equals", ""))):
			return str(cd.get(value_field, ""))
	return base

func _resolve_cond_array(base: Array, conditions: Array, vars: Dictionary, array_field: String) -> Array:
	for cond: Variant in conditions:
		if not cond is Dictionary:
			continue
		var cd: Dictionary = cond as Dictionary
		if _var_matches(vars, str(cd.get("var", "")), str(cd.get("equals", ""))):
			var matched: Variant = cd.get(array_field, [])
			return matched.duplicate(true) if matched is Array else []
	return base.duplicate(true)

func resolve_title(vars: Dictionary) -> String:
	return _resolve_cond_string(title, title_conditions, vars, "value")

func resolve_description(vars: Dictionary) -> String:
	return _resolve_cond_string(description, description_conditions, vars, "value")

func resolve_background(vars: Dictionary) -> String:
	return _resolve_cond_string(background, background_conditions, vars, "path")

func resolve_music(vars: Dictionary) -> String:
	return _resolve_cond_string(music, music_conditions, vars, "path")

func resolve_vn_scene(vars: Dictionary) -> String:
	return _resolve_cond_string(vn_scene, vn_scene_conditions, vars, "path")

## play_once for the matching conditional VN, or node vn_play_once when no condition matches.
func resolve_vn_play_once(vars: Dictionary) -> bool:
	for cond: Variant in vn_scene_conditions:
		if not cond is Dictionary:
			continue
		var cd: Dictionary = cond as Dictionary
		if _var_matches(vars, str(cd.get("var", "")), str(cd.get("equals", ""))):
			return bool(cd.get("play_once", true))
	return vn_play_once

## After-VN actions for whichever VN plays. First matching vn_scene_condition wins.
## Uses that row's after_actions when present; otherwise falls back to vn_after_actions.
## When no condition matches, returns vn_after_actions.
func resolve_vn_after_actions(vars: Dictionary) -> Array:
	for cond: Variant in vn_scene_conditions:
		if not cond is Dictionary:
			continue
		var cd: Dictionary = cond as Dictionary
		if _var_matches(vars, str(cd.get("var", "")), str(cd.get("equals", ""))):
			if cd.has("after_actions"):
				var matched: Variant = cd.get("after_actions", [])
				return matched.duplicate(true) if matched is Array else []
			return vn_after_actions.duplicate(true)
	return vn_after_actions.duplicate(true)

func resolve_on_enter_events(vars: Dictionary) -> Array:
	return _resolve_cond_array(on_enter_events, on_enter_events_conditions, vars, "events")

func resolve_on_exit_events(vars: Dictionary) -> Array:
	return _resolve_cond_array(on_exit_events, on_exit_events_conditions, vars, "events")

func effective_vn_trigger() -> String:
	return vn_trigger if not vn_trigger.is_empty() else "on_enter"

func vn_trigger_on_enter() -> bool:
	return effective_vn_trigger() == "on_enter"

func vn_trigger_on_exit() -> bool:
	return effective_vn_trigger() == "on_exit"

func vn_trigger_on_var_change() -> bool:
	return effective_vn_trigger() == "on_var_change"

func vn_var_change_matches(changed_key: String, changed_value: String) -> bool:
	if not vn_trigger_on_var_change():
		return false
	if not vn_trigger_var.is_empty() and vn_trigger_var != changed_key:
		return false
	if not vn_trigger_equals.is_empty() and vn_trigger_equals != changed_value:
		return false
	return true

# ─────────────────────────────────────────────────────────────
# Serialization helpers
# ─────────────────────────────────────────────────────────────

## Convert this node to a plain Dictionary suitable for JSON serialization.
func to_dict() -> Dictionary:
	return {
		"id":              id,
		"title":           title,
		"title_conditions": title_conditions.duplicate(true),
		"description":     description,
		"description_conditions": description_conditions.duplicate(true),
		"node_type":       NodeType.keys()[node_type],
		"background":            background,
		"background_conditions": background_conditions.duplicate(true),
		"vn_scene":           vn_scene,
		"vn_scene_conditions": vn_scene_conditions.duplicate(true),
		"vn_trigger":         vn_trigger,
		"vn_trigger_var":     vn_trigger_var,
		"vn_trigger_equals":  vn_trigger_equals,
		"vn_play_once":       vn_play_once,
		"vn_keep_bgm":        vn_keep_bgm,
		"vn_after_actions":   vn_after_actions.duplicate(true),
		"show_info_on_enter": show_info_on_enter,
		"show_who_is_here":   show_who_is_here,
		"music":              music,
		"music_conditions":   music_conditions.duplicate(true),
		"battle_bgm":         battle_bgm,
		"setup_bgm":          setup_bgm,
		"almost_win_bgm":     almost_win_bgm,
		"battle_bgm_volume":  battle_bgm_volume,
		"on_enter_events": on_enter_events.duplicate(true),
		"on_enter_events_conditions": on_enter_events_conditions.duplicate(true),
		"on_exit_events":  on_exit_events.duplicate(true),
		"on_exit_events_conditions": on_exit_events_conditions.duplicate(true),
		"connections":     connections.duplicate(true),
		"usable_items":    usable_items.duplicate(true),
		"clickable_spots": clickable_spots.duplicate(true),
		"characters":      characters.duplicate(true),
		"editor_position": {"x": editor_position.x, "y": editor_position.y},
	}

## Create an ExplorationNode from a Dictionary (as parsed from JSON).
static func from_dict(d: Dictionary) -> ExplorationNode:
	var node := ExplorationNode.new()
	node.id          = str(d.get("id",          ""))
	node.title       = str(d.get("title",       ""))
	var tc: Variant = d.get("title_conditions", [])
	node.title_conditions = tc if tc is Array else []
	node.description = str(d.get("description", ""))
	var dc: Variant = d.get("description_conditions", [])
	node.description_conditions = dc if dc is Array else []
	node.background  = str(d.get("background",  ""))
	var bgc: Variant = d.get("background_conditions", [])
	node.background_conditions = bgc if bgc is Array else []
	node.vn_scene           = str(d.get("vn_scene",    ""))
	var vsc: Variant = d.get("vn_scene_conditions", [])
	node.vn_scene_conditions = vsc if vsc is Array else []
	node.vn_trigger         = str(d.get("vn_trigger",        "on_enter"))
	node.vn_trigger_var     = str(d.get("vn_trigger_var",    ""))
	node.vn_trigger_equals  = str(d.get("vn_trigger_equals", ""))
	node.vn_play_once       = bool(d.get("vn_play_once", true))
	node.vn_keep_bgm        = bool(d.get("vn_keep_bgm", true))
	var vaa: Variant = d.get("vn_after_actions", [])
	node.vn_after_actions = vaa if vaa is Array else []
	node.show_info_on_enter = bool(d.get("show_info_on_enter", true))
	node.show_who_is_here   = bool(d.get("show_who_is_here",   true))
	node.music       = str(d.get("music",       ""))
	var msc: Variant = d.get("music_conditions", [])
	node.music_conditions = msc if msc is Array else []
	node.battle_bgm         = str(d.get("battle_bgm", ""))
	node.setup_bgm          = str(d.get("setup_bgm", ""))
	node.almost_win_bgm     = str(d.get("almost_win_bgm", ""))
	node.battle_bgm_volume  = float(d.get("battle_bgm_volume", 100.0))

	var type_str: String = str(d.get("node_type", "NORMAL")).to_upper()
	if NodeType.keys().has(type_str):
		node.node_type = NodeType[type_str]

	var oe: Variant = d.get("on_enter_events", [])
	node.on_enter_events = oe if oe is Array else []
	var oec: Variant = d.get("on_enter_events_conditions", [])
	node.on_enter_events_conditions = oec if oec is Array else []

	var ox: Variant = d.get("on_exit_events", [])
	node.on_exit_events = ox if ox is Array else []
	var oxc: Variant = d.get("on_exit_events_conditions", [])
	node.on_exit_events_conditions = oxc if oxc is Array else []

	var conn: Variant = d.get("connections", [])
	node.connections = conn if conn is Array else []

	var ui: Variant = d.get("usable_items", [])
	node.usable_items = ui if ui is Array else []

	var cs: Variant = d.get("clickable_spots", [])
	node.clickable_spots = cs if cs is Array else []

	var ch: Variant = d.get("characters", [])
	node.characters = ch if ch is Array else []

	var ep: Variant = d.get("editor_position", {})
	if ep is Dictionary:
		var epd: Dictionary = ep as Dictionary
		node.editor_position = Vector2(float(epd.get("x", 0.0)), float(epd.get("y", 0.0)))

	return node
