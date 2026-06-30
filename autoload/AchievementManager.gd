extends Node
## Local-first achievement tracking and threshold checks.

signal achievement_unlocked(achievement_id: String)

const DATA_PATH := "res://data/achievements.json"
const DEFAULT_ACHIEVEMENT_ICON := "res://assets/icon/game_icon.png"
const LEGACY_ACHIEVEMENT_ICON := "res://icon.svg"

const AFFINITY_TO_ACHIEVEMENT := {
	CharacterData.Affinity.DIVINE: "union_summon_divine",
	CharacterData.Affinity.CHAOS: "union_summon_chaos",
	CharacterData.Affinity.NATURE: "union_summon_nature",
	CharacterData.Affinity.ARCANE: "union_summon_arcane",
	CharacterData.Affinity.COSMIC: "union_summon_cosmic",
	CharacterData.Affinity.BIO: "union_summon_bio",
	CharacterData.Affinity.ANIMA: "union_summon_anima",
}

var _definitions: Array = []
var _definitions_by_id: Dictionary = {}
var _unlocked: Dictionary = {}
var _rewards_granted: Dictionary = {}
var _pending_reward_queue: Array = []
var _processing_rewards: bool = false


func _ready() -> void:
	reload_definitions()


func reload_definitions() -> void:
	_definitions.clear()
	_definitions_by_id.clear()
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return
	var raw: Variant = (parsed as Dictionary).get("achievements", [])
	if not raw is Array:
		return
	for entry: Variant in raw:
		if not entry is Dictionary:
			continue
		var d: Dictionary = (entry as Dictionary).duplicate(true)
		var id: String = str(d.get("id", "")).strip_edges()
		if id.is_empty():
			continue
		_definitions.append(d)
		_definitions_by_id[id] = d


func save_definitions() -> bool:
	var f := FileAccess.open(DATA_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"achievements": _definitions}, "\t"))
	f.close()
	reload_definitions()
	return true


func load_from_save(data: Dictionary) -> void:
	_unlocked.clear()
	var ua: Variant = data.get("unlocked_achievements", [])
	if ua is Array:
		for id: Variant in ua:
			var key: String = str(id).strip_edges()
			if not key.is_empty():
				_unlocked[key] = true
	_rewards_granted.clear()
	var rg: Variant = data.get("achievement_rewards_granted", [])
	if rg is Array:
		for id: Variant in rg:
			var key: String = str(id).strip_edges()
			if not key.is_empty():
				_rewards_granted[key] = true
	call_deferred("check_threshold_achievements")


func to_save_dict() -> Dictionary:
	var ids: Array = []
	for key: Variant in _unlocked.keys():
		ids.append(str(key))
	ids.sort()
	var granted: Array = []
	for key: Variant in _rewards_granted.keys():
		granted.append(str(key))
	granted.sort()
	return {
		"unlocked_achievements": ids,
		"achievement_rewards_granted": granted,
	}


func get_definitions() -> Array:
	return _definitions.duplicate(true)


func get_definition(achievement_id: String) -> Dictionary:
	return (_definitions_by_id.get(achievement_id, {}) as Dictionary).duplicate(true)


func get_icon_path(def: Dictionary) -> String:
	var path: String = str(def.get("icon", "")).strip_edges()
	if path.is_empty() or path == LEGACY_ACHIEVEMENT_ICON:
		path = DEFAULT_ACHIEVEMENT_ICON
	if ResourceLoader.exists(path):
		return path
	if ResourceLoader.exists(DEFAULT_ACHIEVEMENT_ICON):
		return DEFAULT_ACHIEVEMENT_ICON
	return ""


func is_unlocked(achievement_id: String) -> bool:
	return bool(_unlocked.get(achievement_id, false))


func is_implemented(achievement_id: String) -> bool:
	var def: Dictionary = get_definition(achievement_id)
	return bool(def.get("implemented", false))


func unlock(achievement_id: String, force: bool = false) -> bool:
	if achievement_id.is_empty():
		return false
	if is_unlocked(achievement_id):
		return false
	if not force and not is_implemented(achievement_id):
		return false
	_unlocked[achievement_id] = true
	emit_signal("achievement_unlocked", achievement_id)
	_queue_reward(achievement_id)
	SaveManager.save_data()
	return true


func revoke(achievement_id: String) -> void:
	if not _unlocked.erase(achievement_id):
		return
	SaveManager.save_data()


func get_unlocked_count() -> int:
	return _unlocked.size()


func get_total_count() -> int:
	return _definitions.size()


func get_progress(achievement_id: String) -> Dictionary:
	var def: Dictionary = get_definition(achievement_id)
	var target: int = int(def.get("progress_target", 0))
	var kind: String = str(def.get("progress_kind", "none")).strip_edges()
	var current: int = 0
	match kind:
		"none":
			current = 1 if is_unlocked(achievement_id) else 0
			target = 1
		"unique_cards":
			current = _count_unique_owned_cards()
		"unions_discovered":
			current = SaveManager.unlocked_unions.size()
		"duel_wins":
			current = GlobalStatManager.get_int("duel_win")
		"credit_balance":
			current = Collection.credits
		"deck_count":
			current = SaveManager.decks.size()
		_:
			if GlobalStatManager.has_stat(kind):
				current = GlobalStatManager.get_int(kind)
			elif target > 0:
				current = 0
			else:
				current = 1 if is_unlocked(achievement_id) else 0
	return {"current": current, "target": target, "kind": kind}


func check_threshold_achievements() -> void:
	for def: Variant in _definitions:
		if not def is Dictionary:
			continue
		var d: Dictionary = def as Dictionary
		var id: String = str(d.get("id", "")).strip_edges()
		if id.is_empty() or is_unlocked(id):
			continue
		var kind: String = str(d.get("progress_kind", "none")).strip_edges()
		if kind == "none":
			continue
		var prog: Dictionary = get_progress(id)
		if int(prog.get("target", 0)) > 0 and int(prog.get("current", 0)) >= int(prog.get("target", 0)):
			unlock(id)


func on_duel_finished(player_won: bool, context: Dictionary) -> void:
	if not player_won:
		return
	var protagonist_id: String = str(context.get("protagonist_id", "nex")).strip_edges().to_lower()
	var is_qd: bool = bool(context.get("is_quick_duel", false))
	var tier: String = str(context.get("quick_duel_battle_tier", "")).strip_edges()
	var reason: String = str(context.get("game_over_reason", "")).strip_edges()

	if protagonist_id == "nex" or not is_qd:
		unlock("win_duel_nex")
	if is_qd and protagonist_id == "mayu":
		unlock("win_duel_mayu")
	if is_qd and protagonist_id == "kelly":
		unlock("win_duel_kelly")
	if reason == "all_destroyed":
		unlock("win_wipe_all_units")
	if is_qd and tier == "hard" and not SaveManager.is_casual_mode():
		unlock("win_hard_no_casual")
	check_threshold_achievements()


func on_union_summoned(affinity: int) -> void:
	var ach_id: String = str(AFFINITY_TO_ACHIEVEMENT.get(affinity, "")).strip_edges()
	if not ach_id.is_empty():
		unlock(ach_id)
	check_threshold_achievements()


func on_opponent_destroyed_by_trap() -> void:
	unlock("destroy_by_trap")


func on_opponent_destroyed_by_tech() -> void:
	unlock("destroy_by_tech")


func on_first_exotic_card() -> void:
	unlock("first_exotic_card")


func on_deck_count_changed() -> void:
	check_threshold_achievements()


func on_collection_changed() -> void:
	check_threshold_achievements()


func on_credit_balance_changed() -> void:
	check_threshold_achievements()


func on_union_discovered() -> void:
	check_threshold_achievements()


func format_reward_preview(reward: Dictionary) -> String:
	if reward.is_empty():
		var pose_label: String = ProtagonistVault.get_pose_reward_label_for_achievement("")
		if not pose_label.is_empty():
			return pose_label
		return ""
	var t: String = str(reward.get("type", "")).strip_edges()
	match t:
		"credits", "coins":
			return "%d Credits" % int(reward.get("amount", 0))
		"card":
			return "Card: %s" % str(reward.get("card_name", "?"))
		"booster_pack":
			return "%s Pack" % str(reward.get("pack_name", "Booster"))
		"union_scroll":
			return "%d Union Scroll(s)" % int(reward.get("count", 1))
		"music_disc":
			return "Music Disc"
		"stage_bonus_card":
			return "Card: %s" % str(reward.get("card_name", "?"))
		_:
			return t.capitalize() if not t.is_empty() else ""


func format_row_reward_preview(achievement_id: String, reward: Dictionary) -> String:
	var parts: Array[String] = []
	var pose: String = ProtagonistVault.get_pose_reward_label_for_achievement(achievement_id)
	if not pose.is_empty():
		parts.append(pose)
	var item: String = format_reward_preview(reward)
	if not item.is_empty():
		parts.append(item)
	if parts.is_empty():
		return "—"
	return "Reward: " + ", ".join(parts)


func _count_unique_owned_cards() -> int:
	var count: int = 0
	for card_name: Variant in Collection.owned.keys():
		var entry: Variant = Collection.owned[card_name]
		if not entry is Dictionary:
			continue
		var t: String = str((entry as Dictionary).get("type", "")).strip_edges()
		if t in ["character", "trap", "tech"]:
			count += 1
	return count


func _queue_reward(achievement_id: String) -> void:
	if bool(_rewards_granted.get(achievement_id, false)):
		return
	_pending_reward_queue.append(achievement_id)
	_process_reward_queue()


func _process_reward_queue() -> void:
	if _processing_rewards:
		return
	if _pending_reward_queue.is_empty():
		return
	_processing_rewards = true
	while not _pending_reward_queue.is_empty():
		var ach_id: String = str(_pending_reward_queue.pop_front()).strip_edges()
		if ach_id.is_empty() or bool(_rewards_granted.get(ach_id, false)):
			continue
		var def: Dictionary = get_definition(ach_id)
		var reward: Dictionary = def.get("reward", {}) as Dictionary
		if reward is Dictionary and not (reward as Dictionary).is_empty():
			RewardGranter.grant_achievement_reward(ach_id, reward as Dictionary)
		else:
			var pose: String = ProtagonistVault.get_pose_reward_label_for_achievement(ach_id)
			if not pose.is_empty():
				RewardGranter.present_achievement_only(ach_id)
		_rewards_granted[ach_id] = true
		SaveManager.save_data()
	_processing_rewards = false


func _sync_to_steam_backend() -> void:
	pass
