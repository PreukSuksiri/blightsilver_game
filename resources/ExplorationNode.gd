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

## Descriptive flavour text shown to the player.
@export var description: String = ""

## Behaviour type — controls what happens when the player enters this node.
@export var node_type: NodeType = NodeType.NORMAL

## Path to a background image (res:// path). Empty = keep the previous background.
@export var background: String = ""

## Path to a VN beat JSON file. Used by STORY nodes (or as an optional entry cutscene).
@export var vn_scene: String = ""

## If true, the node's vn_scene plays only once per session (default true).
@export var vn_play_once: bool = true

## If true, the info panel (title + description) opens automatically when the player enters.
## When a vn_scene is also set, the info panel appears first; VN plays after it is dismissed.
@export var show_info_on_enter: bool = true

## If true, a "Who is here" section listing characters is shown inside the info panel.
@export var show_who_is_here: bool = true

## Path to a BGM track to start when entering this node. Empty = keep current music.
@export var music: String = ""

## Events fired in order when the player ENTERS this node.
## Each entry is a Dictionary (see format above).
@export var on_enter_events: Array = []

## Events fired in order when the player LEAVES this node.
@export var on_exit_events: Array = []

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
##                                           extra action types: "play_vn", "navigate_to", "play_puzzle"
##                                           play_puzzle: value = puzzle id, key = optional params (JSON or text)
##                                           play_puzzle gates all other actions until solved
##     "conditions": Array                 — condition dicts (same format as connection conditions)
##     "vn_scene": String                  — legacy field; treated as play_vn action if actions empty
##   }
@export var clickable_spots: Array = []

## Characters that can be spoken to at this node.
## Each entry is a Dictionary:
##   { "name": String, "vn_scene": String, "conditions": Array,
##     "canon_story": bool, "play_once": bool, "thumbnail": String }
## conditions format is the same as connection conditions (all must pass to show).
## canon_story — when true, pulses the chat HUD icon while this character can be talked to.
@export var characters: Array = []

## Editor-only: position of this GraphNode in the ExplorationEditor canvas.
@export var editor_position: Vector2 = Vector2.ZERO

# ─────────────────────────────────────────────────────────────
# Serialization helpers
# ─────────────────────────────────────────────────────────────

## Convert this node to a plain Dictionary suitable for JSON serialization.
func to_dict() -> Dictionary:
	return {
		"id":              id,
		"title":           title,
		"description":     description,
		"node_type":       NodeType.keys()[node_type],
		"background":      background,
		"vn_scene":           vn_scene,
		"vn_play_once":       vn_play_once,
		"show_info_on_enter": show_info_on_enter,
		"show_who_is_here":   show_who_is_here,
		"music":              music,
		"on_enter_events": on_enter_events.duplicate(true),
		"on_exit_events":  on_exit_events.duplicate(true),
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
	node.description = str(d.get("description", ""))
	node.background  = str(d.get("background",  ""))
	node.vn_scene           = str(d.get("vn_scene",    ""))
	node.vn_play_once       = bool(d.get("vn_play_once", true))
	node.show_info_on_enter = bool(d.get("show_info_on_enter", true))
	node.show_who_is_here   = bool(d.get("show_who_is_here",   true))
	node.music       = str(d.get("music",       ""))

	var type_str: String = str(d.get("node_type", "NORMAL")).to_upper()
	if NodeType.keys().has(type_str):
		node.node_type = NodeType[type_str]

	var oe: Variant = d.get("on_enter_events", [])
	node.on_enter_events = oe if oe is Array else []

	var ox: Variant = d.get("on_exit_events", [])
	node.on_exit_events = ox if ox is Array else []

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
