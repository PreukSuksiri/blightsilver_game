extends Node

signal progress_changed

enum NodeType { STORY, BATTLE, REWARD }

# ─────────────────────────────────────────────────────────────
# Data class
# ─────────────────────────────────────────────────────────────
class CampaignNode:
	var id: String = ""
	var node_type: NodeType = NodeType.STORY
	var chapter: int = 1
	var chapter_name: String = ""
	var title: String = ""
	var map_position: Vector2 = Vector2.ZERO
	var connections: Array = []
	var data: Dictionary = {}
	# BATTLE → { difficulty, reward_credits, opponent, reward_description, vn_scene: String }
	# STORY  → { vn_scene: String }
	# REWARD → { credits, description }

# ─────────────────────────────────────────────────────────────
# State
# ─────────────────────────────────────────────────────────────
var all_nodes: Array = []
var _node_map: Dictionary = {}

var completed: Dictionary = {}
var active_node_id: String = ""
var pending_result: Dictionary = {}  # {node_id, won} — written by GameBoard, read by CampaignMap

func _ready() -> void:
	_define_nodes()
	_load_saved_positions()

# ─────────────────────────────────────────────────────────────
# Node layout
# Map canvas: 1860 × 540
#
# Prologue: ch0_s1(80,268) — left-center entry point
#
# Top row (y ~100–150):
#   Ch1: 1-1(80,150) 1-2(260,100) 1-3(440,150) 1-4(620,100) 1-5(800,150)
#   Ch2: 2-1(980,150) 2-2(1160,100) 2-3(1340,150) 2-4(1520,100) 2-5(1700,150)
#
# Vertical drop: 2-5(1700,150) → 3-1(1700,390)
#
# Bottom row (y ~390–430), going right → left:
#   Ch3: 3-1(1700,390) 3-2(1520,430) 3-3(1340,390) 3-4(1160,430) 3-5(980,390)
#   Ch4: 4-1(800,390)  4-2(620,430)  4-3(440,390)  4-4(260,430)  4-5(80,390)
#
# Final: 4-5(80,390) → final_soon(920,268) — center between rows
# ─────────────────────────────────────────────────────────────
func _define_nodes() -> void:
	all_nodes.clear()
	_node_map.clear()

	# ══════════════════════════════════════════════════════════
	# PROLOGUE — Prologue
	# ══════════════════════════════════════════════════════════
	_battle("ch0_s1", 0, "Prologue", "Flickering Midnight",
		Vector2(80, 268), ["ch0_s1"], 1, 500,
		"Kelly",
		"500 Credits + 1 Booster Pack",
		"res://campaign/scenes/ch0_s1_pre.json",
		"res://campaign/scenes/ch0_s1_post.json")

	# ══════════════════════════════════════════════════════════
	# CHAPTER 1 — Trusty Savior
	# ══════════════════════════════════════════════════════════
	_battle("ch1_s1", 1, "Trusty Savior", "Library Chaos",
		Vector2(80, 150), ["ch1_s1"], 1, 500,
		"Mayu (Ghost Possessed)",
		"500 Credits + 1 Booster Pack",
		"res://campaign/scenes/ch1_s1_pre.json")

	_battle("ch1_s2", 1, "Trusty Savior", "Plague Doctor",
		Vector2(260, 100), ["ch1_s2"], 1, 1000,
		"Doctor Rat",
		"1000 Credits + 1 Rare Booster Pack",
		"res://campaign/scenes/ch1_s2_pre.json")

	_battle("ch1_s3", 1, "Trusty Savior", "Distress Call",
		Vector2(440, 150), ["ch1_s3"], 1, 1000,
		"Backwood Punks",
		"1000 Credits + 1 Rare Booster Pack",
		"res://campaign/scenes/ch1_s3_pre.json")

	_battle("ch1_s4", 1, "Trusty Savior", "Granny in the Park",
		Vector2(620, 100), ["ch1_s4"], 1, 1000,
		"Fruit Granny",
		"1000 Credits + 1 Pack Re-Open Bonus",
		"res://campaign/scenes/ch1_s4_pre.json")

	_battle("ch1_s5", 1, "Trusty Savior", "Return of the Shadows",
		Vector2(800, 150), ["ch2_s5"], 2, 2000,
		"Midnight Shadow",
		"2000 Credits + 2 Pack Re-Opens + 1 Legendary Booster",
		"res://campaign/scenes/ch1_s5_pre.json")

	# ══════════════════════════════════════════════════════════
	# CHAPTER 2 — Under the Blight
	# ══════════════════════════════════════════════════════════
	_battle("ch2_s1", 2, "Under the Blight", "The Secret Room",
		Vector2(980, 150), ["ch2_s1"], 2, 2000,
		"Bandaged Man",
		"2000 Credits",
		"res://campaign/scenes/ch2_s1_pre.json")

	_battle("ch2_s2", 2, "Under the Blight", "Blackouts",
		Vector2(1160, 100), ["ch2_s2"], 2, 2000,
		"Mall Vampire",
		"2000 Credits + 1 Rare Booster + 1 Pack Re-Open",
		"res://campaign/scenes/ch2_s2_pre.json")

	_battle("ch2_s3", 2, "Under the Blight", "Long Way Home",
		Vector2(1340, 150), ["ch2_s3"], 2, 2000,
		"Riverside Wolves",
		"2000 Credits + 1 Rare Booster + 1 Pack Re-Open",
		"res://campaign/scenes/ch2_s3_pre.json")

	_battle("ch2_s4", 2, "Under the Blight", "Nightfalls",
		Vector2(1520, 100), ["ch2_s4"], 3, 4000,
		"Blood Ritualists",
		"4000 Credits + 1 Rare Booster + 1 Pack Re-Open",
		"res://campaign/scenes/ch2_s4_pre.json")

	_battle("ch2_s5", 2, "Under the Blight", "City Under Siege",
		Vector2(1700, 150), ["ch2_s5"], 3, 5000,
		"Vampire Spellcaster",
		"5000 Credits + 1 Legendary Booster + 3 Pack Re-Opens",
		"res://campaign/scenes/ch2_s5_pre.json")

	# ══════════════════════════════════════════════════════════
	# CHAPTER 3 — Enterprise Life
	# (bottom-right of map, going right → left)
	# ══════════════════════════════════════════════════════════
	_battle("ch3_s1", 3, "Enterprise Life", "Job Application",
		Vector2(1700, 390), ["ch3_s1"], 2, 5000,
		"Lab Crawler",
		"5000 Credits",
		"res://campaign/scenes/ch3_s1_pre.json")

	_battle("ch3_s2", 3, "Enterprise Life", "Middle Manager",
		Vector2(1520, 430), ["ch3_s2"], 2, 5000,
		"Loan Shark",
		"5000 Credits + 1 Rare Booster",
		"res://campaign/scenes/ch3_s2_pre.json")

	_battle("ch3_s3", 3, "Enterprise Life", "Lab Mayhem",
		Vector2(1340, 390), ["ch3_s3"], 2, 5000,
		"Berserk Chimera",
		"5000 Credits + 1 Rare Booster + 1 Pack Re-Open",
		"res://campaign/scenes/ch3_s3_pre.json")

	_battle("ch3_s4", 3, "Enterprise Life", "Sea of Silvers",
		Vector2(1160, 430), ["ch3_s4"], 3, 8000,
		"Greedy Workers",
		"8000 Credits + 1 Legendary Booster + 1 Pack Re-Open",
		"res://campaign/scenes/ch3_s4_pre.json")

	_battle("ch3_s5", 3, "Enterprise Life", "Slipped into Flame",
		Vector2(980, 390), ["ch3_s5"], 3, 8000,
		"Magma Djinn",
		"8000 Credits + 1 Exotic Booster",
		"res://campaign/scenes/ch3_s5_pre.json")

	# ══════════════════════════════════════════════════════════
	# CHAPTER 4 — Unforgettable Vacation
	# (bottom-left of map, continuing left from Ch3)
	# ══════════════════════════════════════════════════════════
	_battle("ch4_s1", 4, "Unforgettable Vacation", "The Order of High Gate",
		Vector2(800, 390), ["ch4_s1"], 3, 8000,
		"Angel Duelist",
		"8000 Credits + 1 Pack Re-Open",
		"res://campaign/scenes/ch4_s1_pre.json")

	_battle("ch4_s2", 4, "Unforgettable Vacation", "Family Betrayal",
		Vector2(620, 430), ["ch4_s2"], 3, 10000,
		"Security Guard",
		"10000 Credits + 1 Pack Re-Open",
		"res://campaign/scenes/ch4_s2_pre.json")

	_battle("ch4_s3", 4, "Unforgettable Vacation", "The Bond of Fate",
		Vector2(440, 390), ["ch4_s3"], 3, 10000,
		"Illusion Clown",
		"10000 Credits + 2 Pack Re-Opens",
		"res://campaign/scenes/ch4_s3_pre.json")

	_battle("ch4_s4", 4, "Unforgettable Vacation", "One Way Ticket",
		Vector2(260, 430), ["ch4_s4"], 3, 10000,
		"Bloody Woman",
		"10000 Credits + 1 Legendary Booster + 2 Pack Re-Opens",
		"res://campaign/scenes/ch4_s4_pre.json")

	_battle("ch4_s5", 4, "Unforgettable Vacation", "The Vault Master",
		Vector2(80, 390), ["final_soon"], 3, 15000,
		"Morgull's Avatar",
		"15000 Credits + 1 Exotic Booster + 2 Pack Re-Opens",
		"res://campaign/scenes/ch4_s5_pre.json")

	# ══════════════════════════════════════════════════════════
	# FINAL CHAPTER — Morgull (placeholder)
	# ══════════════════════════════════════════════════════════
	_story("final_soon", 5, "Final Chapter", "To Be Continued",
		Vector2(920, 268), [],
		"res://campaign/scenes/final_soon.json")

# ─────────────────────────────────────────────────────────────
# Saved position override (shipped data + optional editor-only user tweak)
# ─────────────────────────────────────────────────────────────
const SHIPPED_POSITIONS_PATH := "res://data/campaign_node_positions.json"
const USER_POSITIONS_PATH := "user://campaign_node_positions.json"

func _load_saved_positions() -> void:
	_apply_positions_from_file(SHIPPED_POSITIONS_PATH)
	if Engine.is_editor_hint():
		_apply_positions_from_file(USER_POSITIONS_PATH)

func _apply_positions_from_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary:
		return
	for node in all_nodes:
		if data.has(node.id):
			var arr = data[node.id]
			node.map_position = Vector2(float(arr[0]), float(arr[1]))

# ─────────────────────────────────────────────────────────────
# Factory helpers
# ─────────────────────────────────────────────────────────────
func _add_node(n: CampaignNode) -> void:
	all_nodes.append(n)
	_node_map[n.id] = n

func _battle(id: String, ch: int, ch_name: String, title: String,
			 pos: Vector2, conns: Array,
			 difficulty: int, reward_credits: int,
			 opponent: String, reward_description: String,
			 vn_scene: String, vn_scene_post: String = "") -> void:
	var n := CampaignNode.new()
	n.id = id;            n.node_type = NodeType.BATTLE
	n.chapter = ch;       n.chapter_name = ch_name
	n.title = title;      n.map_position = pos
	n.connections = conns
	n.data = {
		"difficulty": difficulty,
		"reward_credits": reward_credits,
		"opponent": opponent,
		"reward_description": reward_description,
		"vn_scene": vn_scene,
		"vn_scene_post": vn_scene_post
	}
	_add_node(n)

func _story(id: String, ch: int, ch_name: String, title: String,
			pos: Vector2, conns: Array, vn_scene: String) -> void:
	var n := CampaignNode.new()
	n.id = id;            n.node_type = NodeType.STORY
	n.chapter = ch;       n.chapter_name = ch_name
	n.title = title;      n.map_position = pos
	n.connections = conns
	n.data = {"vn_scene": vn_scene}
	_add_node(n)

func _reward(id: String, ch: int, ch_name: String, title: String,
			 pos: Vector2, conns: Array, credits: int, description: String) -> void:
	var n := CampaignNode.new()
	n.id = id;            n.node_type = NodeType.REWARD
	n.chapter = ch;       n.chapter_name = ch_name
	n.title = title;      n.map_position = pos
	n.connections = conns
	n.data = {"credits": credits, "description": description}
	_add_node(n)

# ─────────────────────────────────────────────────────────────
# Queries
# ─────────────────────────────────────────────────────────────
func get_node_data(id: String) -> CampaignNode:
	return _node_map.get(id, null)

func is_completed(id: String) -> bool:
	return completed.get(id, false)

## True if any campaign node using this VN (pre or post) is marked complete.
func is_vn_scene_completed(vn_scene: String) -> bool:
	var key: String = vn_scene.strip_edges()
	if key.is_empty():
		return false
	for node: CampaignNode in all_nodes:
		var pre: String = str(node.data.get("vn_scene", "")).strip_edges()
		var post: String = str(node.data.get("vn_scene_post", "")).strip_edges()
		if (pre == key or post == key) and is_completed(node.id):
			return true
	return false

## Campaign map node id → pre-battle vn_scene path (empty if unknown).
func get_vn_scene_for_node(node_id: String) -> String:
	var node: CampaignNode = get_node_data(node_id.strip_edges())
	if node == null:
		return ""
	return str(node.data.get("vn_scene", "")).strip_edges()

func is_unlocked(id: String) -> bool:
	if id == "ch0_s1":
		return true
	for node in all_nodes:
		if id in node.connections and is_completed(node.id):
			return true
	return false

func count_completed() -> int:
	return completed.size()

func count_total() -> int:
	return all_nodes.size()

func get_enemy_config(difficulty: int) -> Dictionary:
	match difficulty:
		1: return {"min_chars": 6,  "max_chars": 8,  "min_traps": 4, "max_traps": 5}
		2: return {"min_chars": 8,  "max_chars": 10, "min_traps": 5, "max_traps": 6}
		_: return {"min_chars": 10, "max_chars": 12, "min_traps": 6, "max_traps": 8}

# ─────────────────────────────────────────────────────────────
# Completion
# ─────────────────────────────────────────────────────────────
func complete_node(id: String) -> void:
	if is_completed(id):
		return
	completed[id] = true
	var node := get_node_data(id)
	if node:
		var vn: String = str(node.data.get("vn_scene", "")).strip_edges()
		if vn != "":
			SaveManager.mark_gallery_chapter_completed(vn)
		var credits: int = node.data.get("reward_credits", node.data.get("credits", 0))
		if credits > 0:
			Collection.add_credits(credits)
	emit_signal("progress_changed")
	SaveManager.save_data()

# ─────────────────────────────────────────────────────────────
# Serialization
# ─────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {"completed": completed.duplicate()}

func load_from_dict(d: Dictionary) -> void:
	completed = {}
	for k in d.get("completed", {}).keys():
		completed[k] = true
