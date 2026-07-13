extends Node
# Player-side detective note progress: discovered clues, unlocked topics,
# topic levels (verdict map upgrades) and clue placements on verdict nodes.
# Authored content lives in DetectiveNoteVault; this autoload only tracks
# what the player has found and arranged. Persisted inside save_data.json.
#
# Verdict output — every placement writes the placed clue id to:
#   • an exploration session var (when a session is active), and
#   • a persistent exploration flag (always),
# both under the node's var key (see DetectiveNoteVault.node_var_key).
# Story content reads these with var_equals / flag_equals conditions;
# no correctness judgement happens here.

## kind ∈ ["individual", "object", "information", "topic", "topic_expanded"]
signal note_notification(kind: String, chapter_id: String, ref_id: String)
signal clue_added(chapter_id: String, clue_id: String)
signal topic_unlocked(chapter_id: String, topic_id: String)
signal topic_upgraded(chapter_id: String, topic_id: String, level: int)
signal placement_changed(chapter_id: String, topic_id: String, node_id: String, clue_id: String)
signal topic_stamped(chapter_id: String, topic_id: String, stamp_id: String)

# _progress[chapter_id] = {
#   "clues":  [clue_id, ...],
#   "topics": { topic_id: {
#     "level": int,
#     "placements": { node_id: clue_id },
#     "stamp": stamp_id          — present once APPROVED; locks the topic
#     "stamp_angle": float       — random tilt (degrees), fixed when stamped
#   } }
# }
const STAMP_TILT_MIN_DEG := -14.0
const STAMP_TILT_MAX_DEG := 14.0
var _progress: Dictionary = {}


# ─────────────────────────────────────────────────────────────
# Clues
# ─────────────────────────────────────────────────────────────
func add_clue(chapter_id: String, clue_id: String, silent: bool = false) -> bool:
	var ch := chapter_id.strip_edges()
	var cid := clue_id.strip_edges()
	if ch.is_empty() or cid.is_empty():
		return false
	if not DetectiveNoteVault.has_clue(cid):
		push_warning("DetectiveNoteManager.add_clue: unknown clue '%s'" % cid)
		return false
	var clue_list: Array = _chapter_entry(ch)["clues"]
	if clue_list.has(cid):
		return false
	clue_list.append(cid)
	SaveManager.save_data()
	if not silent:
		emit_signal("clue_added", ch, cid)
		emit_signal("note_notification", DetectiveNoteVault.get_clue_kind(cid), ch, cid)
	return true


## Grant vault-authored start_clues for a chapter (silent — no discovery toast).
## Called when the player enters a chapter's VN scene, exploration graph, or
## opens that chapter in the detective notebook. Idempotent.
func apply_start_clues(chapter_id: String) -> void:
	var ch := chapter_id.strip_edges()
	if ch.is_empty():
		return
	for cid: Variant in DetectiveNoteVault.get_chapter_start_clues(ch):
		add_clue(ch, str(cid), true)


func has_clue(chapter_id: String, clue_id: String) -> bool:
	var entry: Dictionary = _progress.get(chapter_id.strip_edges(), {})
	var clue_list: Variant = entry.get("clues", [])
	return clue_list is Array and (clue_list as Array).has(clue_id.strip_edges())


func get_discovered_clues(chapter_id: String) -> Array:
	var entry: Dictionary = _progress.get(chapter_id.strip_edges(), {})
	var clue_list: Variant = entry.get("clues", [])
	return (clue_list as Array).duplicate() if clue_list is Array else []


## Discovered clues of one kind ("individual" | "object" | "information").
func get_discovered_clues_by_kind(chapter_id: String, kind: String) -> Array:
	var out: Array = []
	for cid: Variant in get_discovered_clues(chapter_id):
		if DetectiveNoteVault.get_clue_kind(str(cid)) == kind:
			out.append(str(cid))
	return out


# ─────────────────────────────────────────────────────────────
# Topics
# ─────────────────────────────────────────────────────────────
func unlock_topic(chapter_id: String, topic_id: String) -> bool:
	var ch := chapter_id.strip_edges()
	var tid := topic_id.strip_edges()
	if ch.is_empty() or tid.is_empty():
		return false
	if DetectiveNoteVault.get_topic(ch, tid).is_empty():
		push_warning("DetectiveNoteManager.unlock_topic: unknown topic '%s/%s'" % [ch, tid])
		return false
	var topics: Dictionary = _chapter_entry(ch)["topics"]
	if topics.has(tid):
		return false
	topics[tid] = {"level": 1, "placements": {}}
	SaveManager.save_data()
	emit_signal("topic_unlocked", ch, tid)
	emit_signal("note_notification", "topic", ch, tid)
	return true


func is_topic_unlocked(chapter_id: String, topic_id: String) -> bool:
	return _topic_entry(chapter_id, topic_id) != null


func get_unlocked_topics(chapter_id: String) -> Array:
	var entry: Dictionary = _progress.get(chapter_id.strip_edges(), {})
	var topics: Variant = entry.get("topics", {})
	if not topics is Dictionary:
		return []
	# Preserve authored ordering from the vault, not insertion order.
	var out: Array = []
	for tid: Variant in DetectiveNoteVault.get_topic_ids(chapter_id):
		if (topics as Dictionary).has(str(tid)):
			out.append(str(tid))
	return out


func get_topic_level(chapter_id: String, topic_id: String) -> int:
	var entry: Variant = _topic_entry(chapter_id, topic_id)
	if entry == null:
		return 0
	return int((entry as Dictionary).get("level", 1))


## Raise the topic to `level` (auto-unlocks at level 1 first if needed).
## Levels only go up; previously visible nodes/edges are always retained.
func upgrade_topic(chapter_id: String, topic_id: String, level: int) -> bool:
	var ch := chapter_id.strip_edges()
	var tid := topic_id.strip_edges()
	var topic: Dictionary = DetectiveNoteVault.get_topic(ch, tid)
	if topic.is_empty():
		push_warning("DetectiveNoteManager.upgrade_topic: unknown topic '%s/%s'" % [ch, tid])
		return false
	if not is_topic_unlocked(ch, tid):
		unlock_topic(ch, tid)
	var target: int = clampi(level, 1, DetectiveNoteVault.topic_max_level(topic))
	var entry: Dictionary = _topic_entry(ch, tid) as Dictionary
	if target <= int(entry.get("level", 1)):
		return false
	entry["level"] = target
	SaveManager.save_data()
	emit_signal("topic_upgraded", ch, tid, target)
	emit_signal("note_notification", "topic_expanded", ch, tid)
	return true


# ─────────────────────────────────────────────────────────────
# Verdict map placements
# ─────────────────────────────────────────────────────────────
## Place a clue on a verdict node (empty clue_id clears the node).
## Writes the exploration variable/flag for the node — story content decides
## what any given value means.
func set_placement(chapter_id: String, topic_id: String, node_id: String, clue_id: String) -> bool:
	var ch := chapter_id.strip_edges()
	var tid := topic_id.strip_edges()
	var nid := node_id.strip_edges()
	var cid := clue_id.strip_edges()
	var topic: Dictionary = DetectiveNoteVault.get_topic(ch, tid)
	var node: Dictionary = DetectiveNoteVault.get_topic_node(topic, nid)
	if node.is_empty():
		push_warning("DetectiveNoteManager.set_placement: unknown node '%s/%s/%s'" % [ch, tid, nid])
		return false
	if is_topic_stamped(ch, tid):
		return false  # case closed — stamped verdict maps are read-only
	if not str(node.get("prefill", "")).strip_edges().is_empty():
		return false  # pre-defined nodes are locked
	if not cid.is_empty():
		if not has_clue(ch, cid):
			return false
		if not DetectiveNoteVault.node_accepts_kind(node, DetectiveNoteVault.get_clue_kind(cid)):
			return false
	if not is_topic_unlocked(ch, tid):
		unlock_topic(ch, tid)
	var placements: Dictionary = (_topic_entry(ch, tid) as Dictionary)["placements"]
	if str(placements.get(nid, "")) == cid:
		return false
	if cid.is_empty():
		placements.erase(nid)
	else:
		placements[nid] = cid
	_write_node_variable(tid, node, cid)
	SaveManager.save_data()
	emit_signal("placement_changed", ch, tid, nid, cid)
	return true


func clear_placement(chapter_id: String, topic_id: String, node_id: String) -> bool:
	return set_placement(chapter_id, topic_id, node_id, "")


## Placed (or prefilled) clue id on a node; "" when empty.
func get_placement(chapter_id: String, topic_id: String, node_id: String) -> String:
	var topic: Dictionary = DetectiveNoteVault.get_topic(chapter_id, topic_id)
	var node: Dictionary = DetectiveNoteVault.get_topic_node(topic, node_id)
	var prefill: String = str(node.get("prefill", "")).strip_edges()
	if not prefill.is_empty():
		return prefill
	var entry: Variant = _topic_entry(chapter_id, topic_id)
	if entry == null:
		return ""
	var placements: Dictionary = (entry as Dictionary).get("placements", {})
	return str(placements.get(node_id.strip_edges(), ""))


func get_placements(chapter_id: String, topic_id: String) -> Dictionary:
	var entry: Variant = _topic_entry(chapter_id, topic_id)
	if entry == null:
		return {}
	return ((entry as Dictionary).get("placements", {}) as Dictionary).duplicate()


func _write_node_variable(topic_id: String, node: Dictionary, clue_id: String) -> void:
	var key: String = DetectiveNoteVault.node_var_key(topic_id, node)
	if key.is_empty():
		return
	if ExplorationManager.is_session_active:
		ExplorationManager.set_var(key, clue_id)
	# Persistent flag so VN scenes outside exploration (flag_equals) and future
	# sessions can also react to the verdict.
	SaveManager.exploration_flags[key] = clue_id


# ─────────────────────────────────────────────────────────────
# Stamps (case-closed approval)
# ─────────────────────────────────────────────────────────────
## Apply an APPROVED stamp to a topic's verdict map. The stamp stays on the
## map indefinitely and the topic becomes read-only. Triggered by the VN
## show_note_stamp beat once the story deems the verdict complete.
func apply_stamp(chapter_id: String, topic_id: String, stamp_id: String) -> bool:
	var ch := chapter_id.strip_edges()
	var tid := topic_id.strip_edges()
	var sid := stamp_id.strip_edges()
	if DetectiveNoteVault.get_topic(ch, tid).is_empty():
		push_warning("DetectiveNoteManager.apply_stamp: unknown topic '%s/%s'" % [ch, tid])
		return false
	if not DetectiveNoteVault.has_stamp(sid):
		push_warning("DetectiveNoteManager.apply_stamp: unknown stamp '%s'" % sid)
		return false
	if is_topic_stamped(ch, tid):
		return false
	if not is_topic_unlocked(ch, tid):
		unlock_topic(ch, tid)
	var entry: Dictionary = _topic_entry(ch, tid) as Dictionary
	entry["stamp"] = sid
	entry["stamp_angle"] = randf_range(STAMP_TILT_MIN_DEG, STAMP_TILT_MAX_DEG)
	SaveManager.save_data()
	emit_signal("topic_stamped", ch, tid, sid)
	return true


func is_topic_stamped(chapter_id: String, topic_id: String) -> bool:
	return not get_topic_stamp(chapter_id, topic_id).is_empty()


## Stamp id applied to the topic; "" when not stamped.
func get_topic_stamp(chapter_id: String, topic_id: String) -> String:
	var entry: Variant = _topic_entry(chapter_id, topic_id)
	if entry == null:
		return ""
	return str((entry as Dictionary).get("stamp", "")).strip_edges()


## Saved stamp tilt in degrees; 0 when the topic is not stamped.
func get_topic_stamp_angle(chapter_id: String, topic_id: String) -> float:
	var entry: Variant = _topic_entry(chapter_id, topic_id)
	if entry == null:
		return 0.0
	if not is_topic_stamped(chapter_id, topic_id):
		return 0.0
	var ed: Dictionary = entry as Dictionary
	if ed.has("stamp_angle"):
		return float(ed["stamp_angle"])
	# Legacy saves: assign once and persist so the tilt stays stable.
	var angle: float = randf_range(STAMP_TILT_MIN_DEG, STAMP_TILT_MAX_DEG)
	ed["stamp_angle"] = angle
	SaveManager.save_data()
	return angle


# ─────────────────────────────────────────────────────────────
# Chapter helpers
# ─────────────────────────────────────────────────────────────
## True when the chapter has anything for the player to see.
func chapter_has_content(chapter_id: String) -> bool:
	var entry: Dictionary = _progress.get(chapter_id.strip_edges(), {})
	if entry.is_empty():
		return false
	var clue_list: Variant = entry.get("clues", [])
	if clue_list is Array and not (clue_list as Array).is_empty():
		return true
	var topics: Variant = entry.get("topics", {})
	return topics is Dictionary and not (topics as Dictionary).is_empty()


## The chapter whose note should be active for the current game context.
## Prefers the active exploration graph, then the supplied VN scene path.
func resolve_active_chapter(vn_scene: String = "") -> String:
	var graph_path: String = ""
	if ExplorationManager.is_session_active and ExplorationManager.current_graph != null:
		graph_path = str(ExplorationManager.current_graph._source_path)
	return DetectiveNoteVault.resolve_chapter_for_context(vn_scene, graph_path)


# ─────────────────────────────────────────────────────────────
# Persistence — merged into SaveManager.save_data() / load_data()
# ─────────────────────────────────────────────────────────────
func to_save_dict() -> Dictionary:
	return {"detective_notes": _progress.duplicate(true)}


func load_from_save(data: Dictionary) -> void:
	_progress.clear()
	var raw: Variant = data.get("detective_notes", {})
	if raw is Dictionary:
		_progress = (raw as Dictionary).duplicate(true)


func reset_all() -> void:
	_progress.clear()


func _chapter_entry(chapter_id: String) -> Dictionary:
	if not _progress.has(chapter_id):
		_progress[chapter_id] = {"clues": [], "topics": {}}
	return _progress[chapter_id]


## Topic progress dict, or null when the topic is not unlocked.
func _topic_entry(chapter_id: String, topic_id: String) -> Variant:
	var entry: Dictionary = _progress.get(chapter_id.strip_edges(), {})
	var topics: Variant = entry.get("topics", {})
	if not topics is Dictionary:
		return null
	return (topics as Dictionary).get(topic_id.strip_edges(), null)
