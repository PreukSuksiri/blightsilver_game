extends Node
# Authored detective note content: chapters → topics → verdict maps, plus a
# global clue pool (individuals / objects / information).
# Edited via admin command: detective_note_vault
#
# Player-side progress (discovered clues, topic levels, placements) lives in
# DetectiveNoteManager — this vault is read-only authored data, like MessengerVault.
#
# Schema:
# {
#   "chapters": [{
#     "id": String,
#     "title": String | {"en": .., "th": ..},
#     "hidden": bool,          — if true, omitted from the player inventory chapter list
#     "vn_scenes": [String],   — campaign VN scene paths belonging to this chapter
#     "graphs": [String],      — exploration graph paths belonging to this chapter
#     "start_clues": [String], — clue ids pre-discovered when the player enters
#                              this chapter (silent, no toast; see apply_start_clues)
#     "topics": [{
#       "id": String,
#       "title": String | {en, th},
#       "hidden": bool,        — if true, omitted from the player topic list / preferred pick
#       "nodes": [{
#         "id": String,
#         "label": String | {en, th},          — handwritten text above the frame
#         "pos": [x, y],                        — top-left inside the notebook canvas
#         "size": [w, h],                       — drop frame size (defaults 200x128)
#         "kind": "individual"|"object"|"information"|"any",
#         "label_side": "top"|"bottom"|"left"|"right", — where the label sits (default top)
#         "min_level": 1..5,                    — visible from this topic level up
#         "prefill": String,                    — clue id pre-placed and locked (optional)
#         "var_key": String                     — override for the produced variable key
#                                                 (default: note_<topic_id>_<node_id>)
#       }],
#       "edges": [{
#         "from": String, "to": String,         — node ids
#         "label": String | {en, th},           — handwritten text on the line
#         "arrow": "none"|"end"|"start"|"both",
#         "min_level": 1..5
#       }]
#     }]
#   }],
#   "clues": [{
#     "id": String,
#     "kind": "individual"|"object"|"information",
#     "group": String,                          — vault-editor folder label (optional;
#                                                 empty = Ungrouped in the CLUES list)
#     "name": String | {en, th},
#     "caption": String | {en, th},             — short caption under the image
#     "info": String | {en, th},                — full text shown on hover-hold (image/postit)
#     "image": String,                          — res:// path (image style only)
#     "style": "image"|"postit"|"messenger",    — messenger = chat from messenger_vault
#     "conversation": String                    — messenger id (style "messenger" only)
#   }],
#   "stamps": [{
#     "id": String,
#     "name": String | {en, th},                — approver name typed under "APPROVED"
#     "image": String                           — stamp logo res:// path
#   }]
# }
#
# A stamp applied to a topic (via the VN show_note_stamp beat) marks the
# verdict map as case-closed: the stamp stays on the map indefinitely and
# the topic becomes read-only (see DetectiveNoteManager.apply_stamp).

const SAVE_PATH := "res://data/detective_note_vault.json"
const MAX_LEVEL := 5
const CLUE_KINDS := ["individual", "object", "information"]
const CLUE_STYLES := ["image", "postit", "messenger"]
const NODE_LABEL_SIDES := ["top", "bottom", "left", "right"]
## Vault-editor display label when clue.group is empty (not persisted as this string).
const CLUE_GROUP_UNGROUPED := "Ungrouped"
const MESSENGER_CLUE_ICON := "res://assets/textures/detective/icon_smart_phone.png"
## Optional texture for prefilled (locked) node badge; empty = drawn padlock.
const PREFILL_LOCK_ICON := ""
const DEFAULT_NODE_SIZE := Vector2(200.0, 164.0)

var _chapters: Array = []
var _clues: Array = []
var _clues_by_id: Dictionary = {}
var _stamps: Array = []
var _stamps_by_id: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	_chapters.clear()
	_clues.clear()
	_clues_by_id.clear()
	_stamps.clear()
	_stamps_by_id.clear()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return
	var raw_chapters: Variant = (parsed as Dictionary).get("chapters", [])
	if raw_chapters is Array:
		_chapters = (raw_chapters as Array).duplicate(true)
	var raw_clues: Variant = (parsed as Dictionary).get("clues", [])
	if raw_clues is Array:
		_clues = (raw_clues as Array).duplicate(true)
	for c: Variant in _clues:
		if not c is Dictionary:
			continue
		var cid: String = str((c as Dictionary).get("id", "")).strip_edges()
		if not cid.is_empty():
			_clues_by_id[cid] = c
	var raw_stamps: Variant = (parsed as Dictionary).get("stamps", [])
	if raw_stamps is Array:
		_stamps = (raw_stamps as Array).duplicate(true)
	for s: Variant in _stamps:
		if not s is Dictionary:
			continue
		var sid: String = str((s as Dictionary).get("id", "")).strip_edges()
		if not sid.is_empty():
			_stamps_by_id[sid] = s


# ─────────────────────────────────────────────────────────────
# Localized text helper — mirrors VNPlayer locale resolution.
# val can be a plain String or a {"en": "...", "th": "..."} dict.
# ─────────────────────────────────────────────────────────────
static func loc_text(val: Variant, locale: String = "en") -> String:
	if val is Dictionary:
		var d: Dictionary = val as Dictionary
		if d.has(locale):
			return str(d[locale])
		for k: Variant in d:
			return str(d[k])
		return ""
	return str(val) if val != null else ""


# ─────────────────────────────────────────────────────────────
# Chapters / topics
# ─────────────────────────────────────────────────────────────
func get_chapters() -> Array:
	return _chapters.duplicate(true)


func get_chapter_ids() -> Array:
	var out: Array = []
	for ch: Variant in _chapters:
		if not ch is Dictionary:
			continue
		var cid: String = str((ch as Dictionary).get("id", "")).strip_edges()
		if not cid.is_empty():
			out.append(cid)
	return out


## Chapter ids eligible for the inventory notebook list (excludes vault "hidden").
## DetectiveNoteManager.get_unlocked_chapter_ids() further filters by player progress.
func get_visible_chapter_ids() -> Array:
	var out: Array = []
	for ch: Variant in _chapters:
		if not ch is Dictionary:
			continue
		var cd: Dictionary = ch as Dictionary
		if flag_true(cd.get("hidden", false)):
			continue
		var cid: String = str(cd.get("id", "")).strip_edges()
		if not cid.is_empty():
			out.append(cid)
	return out


func get_chapter(chapter_id: String) -> Dictionary:
	var needle := chapter_id.strip_edges()
	for ch: Variant in _chapters:
		if ch is Dictionary and str((ch as Dictionary).get("id", "")) == needle:
			return (ch as Dictionary).duplicate(true)
	return {}


## Clue ids granted silently when the player first enters this chapter's context.
func get_chapter_start_clues(chapter_id: String) -> Array:
	var raw: Variant = get_chapter(chapter_id).get("start_clues", [])
	if not raw is Array:
		return []
	var out: Array = []
	for cid: Variant in (raw as Array):
		var id: String = str(cid).strip_edges()
		if not id.is_empty() and not out.has(id):
			out.append(id)
	return out


func get_topic(chapter_id: String, topic_id: String) -> Dictionary:
	var chapter: Dictionary = get_chapter(chapter_id)
	if chapter.is_empty():
		return {}
	var needle := topic_id.strip_edges()
	var topics: Variant = chapter.get("topics", [])
	if not topics is Array:
		return {}
	for t: Variant in (topics as Array):
		if t is Dictionary and str((t as Dictionary).get("id", "")) == needle:
			return (t as Dictionary).duplicate(true)
	return {}


func get_topic_ids(chapter_id: String) -> Array:
	var out: Array = []
	var topics: Variant = get_chapter(chapter_id).get("topics", [])
	if not topics is Array:
		return out
	for t: Variant in (topics as Array):
		if not t is Dictionary:
			continue
		var tid: String = str((t as Dictionary).get("id", "")).strip_edges()
		if not tid.is_empty():
			out.append(tid)
	return out


## True when a vault chapter or topic is marked hidden from player lists.
static func flag_true(val: Variant) -> bool:
	if val is bool:
		return val as bool
	if val is int or val is float:
		return int(val) != 0
	var s: String = str(val).strip_edges().to_lower()
	return s == "true" or s == "1" or s == "yes"


func is_chapter_hidden(chapter_id: String) -> bool:
	return flag_true(get_chapter(chapter_id).get("hidden", false))


func is_topic_hidden(chapter_id: String, topic_id: String) -> bool:
	return flag_true(get_topic(chapter_id, topic_id).get("hidden", false))


## Highest level referenced by any node/edge of the topic (clamped 1..MAX_LEVEL).
## Topics can be upgraded up to this level.
static func topic_max_level(topic: Dictionary) -> int:
	var highest: int = 1
	for key: String in ["nodes", "edges"]:
		var items: Variant = topic.get(key, [])
		if not items is Array:
			continue
		for item: Variant in (items as Array):
			if item is Dictionary:
				highest = maxi(highest, int((item as Dictionary).get("min_level", 1)))
	return clampi(highest, 1, MAX_LEVEL)


## Nodes visible at the given topic level (min_level <= level).
static func nodes_for_level(topic: Dictionary, level: int) -> Array:
	return _items_for_level(topic.get("nodes", []), level)


## Edges visible at the given topic level (min_level <= level).
static func edges_for_level(topic: Dictionary, level: int) -> Array:
	return _items_for_level(topic.get("edges", []), level)


static func _items_for_level(items: Variant, level: int) -> Array:
	var out: Array = []
	if not items is Array:
		return out
	for item: Variant in (items as Array):
		if item is Dictionary and int((item as Dictionary).get("min_level", 1)) <= level:
			out.append((item as Dictionary).duplicate(true))
	return out


static func get_topic_node(topic: Dictionary, node_id: String) -> Dictionary:
	var needle := node_id.strip_edges()
	var nodes: Variant = topic.get("nodes", [])
	if not nodes is Array:
		return {}
	for n: Variant in (nodes as Array):
		if n is Dictionary and str((n as Dictionary).get("id", "")) == needle:
			return (n as Dictionary).duplicate(true)
	return {}


## The exploration variable / flag key a verdict node writes its placed clue id to.
static func node_var_key(topic_id: String, node: Dictionary) -> String:
	var override: String = str(node.get("var_key", "")).strip_edges()
	if not override.is_empty():
		return override
	return "note_%s_%s" % [topic_id.strip_edges(), str(node.get("id", "")).strip_edges()]


# ─────────────────────────────────────────────────────────────
# Clues
# ─────────────────────────────────────────────────────────────
func get_clues() -> Array:
	return _clues.duplicate(true)


func get_clue_ids() -> Array:
	var out: Array = []
	for c: Variant in _clues:
		if not c is Dictionary:
			continue
		var cid: String = str((c as Dictionary).get("id", "")).strip_edges()
		if not cid.is_empty():
			out.append(cid)
	return out


func get_clue(clue_id: String) -> Dictionary:
	var found: Variant = _clues_by_id.get(clue_id.strip_edges(), null)
	if found is Dictionary:
		return (found as Dictionary).duplicate(true)
	return {}


func has_clue(clue_id: String) -> bool:
	return _clues_by_id.has(clue_id.strip_edges())


func get_clue_kind(clue_id: String) -> String:
	return str(get_clue(clue_id).get("kind", "")).strip_edges()


## Raw vault group string (may be empty = ungrouped). Does not invent "Ungrouped".
static func clue_group(clue: Dictionary) -> String:
	return str(clue.get("group", "")).strip_edges()


## Folder label for vault-editor lists (empty group → CLUE_GROUP_UNGROUPED).
static func clue_group_label(clue: Dictionary) -> String:
	var g: String = clue_group(clue)
	return g if not g.is_empty() else CLUE_GROUP_UNGROUPED


## Sorted unique non-empty group names currently authored on clues.
func get_clue_groups() -> Array:
	var seen: Dictionary = {}
	var out: Array = []
	for c: Variant in _clues:
		if not c is Dictionary:
			continue
		var g: String = clue_group(c as Dictionary)
		if g.is_empty() or seen.has(g):
			continue
		seen[g] = true
		out.append(g)
	out.sort()
	return out


static func clue_style(clue: Dictionary) -> String:
	return str(clue.get("style", "image")).strip_edges()


static func clue_is_messenger(clue: Dictionary) -> bool:
	return clue_style(clue) == "messenger"


static func clue_is_postit(clue: Dictionary) -> bool:
	if clue_is_messenger(clue):
		return false
	if clue_style(clue) == "postit":
		return true
	return str(clue.get("image", "")).strip_edges().is_empty()


## Display name for tiles / map labels; messenger clues fall back to conversation title.
static func clue_display_name(clue: Dictionary, loc: String = "en") -> String:
	var name: String = loc_text(clue.get("name", ""), loc)
	if not name.is_empty():
		return name
	if clue_is_messenger(clue):
		var conv_id: String = str(clue.get("conversation", "")).strip_edges()
		if not conv_id.is_empty():
			var conv: Dictionary = MessengerVault.get_conversation(conv_id)
			var title: String = str(conv.get("title", "")).strip_edges()
			return title if not title.is_empty() else conv_id
	return ""


func get_clue_conversation_id(clue_id: String) -> String:
	return str(get_clue(clue_id).get("conversation", "")).strip_edges()


## True when a clue of the given kind may be dropped on the node.
static func node_accepts_kind(node: Dictionary, kind: String) -> bool:
	var accepted: String = str(node.get("kind", "any")).strip_edges()
	if accepted.is_empty() or accepted == "any":
		return true
	return accepted == kind


## Which side of the node frame shows the handwritten label (default: top).
static func node_label_side(node: Dictionary) -> String:
	var side: String = str(node.get("label_side", "top")).strip_edges().to_lower()
	if NODE_LABEL_SIDES.has(side):
		return side
	return "top"


# ─────────────────────────────────────────────────────────────
# Stamps
# ─────────────────────────────────────────────────────────────
func get_stamps() -> Array:
	return _stamps.duplicate(true)


func get_stamp_ids() -> Array:
	var out: Array = []
	for s: Variant in _stamps:
		if not s is Dictionary:
			continue
		var sid: String = str((s as Dictionary).get("id", "")).strip_edges()
		if not sid.is_empty():
			out.append(sid)
	return out


func get_stamp(stamp_id: String) -> Dictionary:
	var found: Variant = _stamps_by_id.get(stamp_id.strip_edges(), null)
	if found is Dictionary:
		return (found as Dictionary).duplicate(true)
	return {}


func has_stamp(stamp_id: String) -> bool:
	return _stamps_by_id.has(stamp_id.strip_edges())


# ─────────────────────────────────────────────────────────────
# Context → chapter resolution
# Used to decide which chapter's note is active in exploration / VN.
# ─────────────────────────────────────────────────────────────
func resolve_chapter_for_context(vn_scene: String = "", graph_path: String = "") -> String:
	var vn := vn_scene.strip_edges()
	var graph := graph_path.strip_edges()
	if vn.is_empty() and graph.is_empty():
		return ""
	for ch: Variant in _chapters:
		if not ch is Dictionary:
			continue
		var cd: Dictionary = ch as Dictionary
		if not vn.is_empty():
			var scenes: Variant = cd.get("vn_scenes", [])
			if scenes is Array and (scenes as Array).has(vn):
				return str(cd.get("id", ""))
		if not graph.is_empty():
			var graphs: Variant = cd.get("graphs", [])
			if graphs is Array and (graphs as Array).has(graph):
				return str(cd.get("id", ""))
	return ""


# ─────────────────────────────────────────────────────────────
# Persistence (admin editor only)
# ─────────────────────────────────────────────────────────────
func save_vault(chapters: Array, clues: Array, stamps: Array = []) -> bool:
	_chapters = chapters.duplicate(true)
	_clues = clues.duplicate(true)
	_clues_by_id.clear()
	for c: Variant in _clues:
		if c is Dictionary:
			var cid: String = str((c as Dictionary).get("id", "")).strip_edges()
			if not cid.is_empty():
				_clues_by_id[cid] = c
	_stamps = stamps.duplicate(true)
	_stamps_by_id.clear()
	for s: Variant in _stamps:
		if s is Dictionary:
			var sid: String = str((s as Dictionary).get("id", "")).strip_edges()
			if not sid.is_empty():
				_stamps_by_id[sid] = s
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(
		{"chapters": _chapters, "clues": _clues, "stamps": _stamps}, "\t"))
	f.close()
	return true
