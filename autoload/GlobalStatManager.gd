extends Node
## Per-save global stat counters and milestone flags.

signal stat_changed(stat_id: String, new_value: int)

const DATA_PATH := "res://data/global_stats.json"
const CH1_BATTLES_PATH := "res://data/ch1_exploration_battles.json"
const PROLOGUE_VN := "res://campaign/scenes/ch0_s1_pre_DEMO_PART1.json"
const CH1_COMPLETE_VN := "res://campaign/scenes/ch1_s1_pre_DEMO_PART1.json"
const REMATCH_FAST_SECONDS := 60.0

const AFFINITY_TO_UNION_SUMMON_STAT := {
	CharacterData.Affinity.DIVINE: "union_summon_divine_count",
	CharacterData.Affinity.CHAOS: "union_summon_chaos_count",
	CharacterData.Affinity.NATURE: "union_summon_nature_count",
	CharacterData.Affinity.ARCANE: "union_summon_arcane_count",
	CharacterData.Affinity.COSMIC: "union_summon_cosmic_count",
	CharacterData.Affinity.BIO: "union_summon_bio_count",
	CharacterData.Affinity.ANIMA: "union_summon_anima_count",
}

var _definitions: Array = []
var _values: Dictionary = {}
var _first_touch: Dictionary = {}
var _ch1_battles_won: Dictionary = {}
var _current_win_streak: int = 0
var _current_loss_streak: int = 0
var _last_duel_loss_unix: float = 0.0
var _last_duel_was_loss: bool = false
var _ch1_battle_ids: Array = []
var _ch1_boss_battle_ids: Array = []
var _ch1_graph_path: String = ""


func _ready() -> void:
	reload_definitions()
	_load_ch1_battle_list()


func reload_definitions() -> void:
	_definitions.clear()
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var raw: Variant = (parsed as Dictionary).get("stats", [])
		if raw is Array:
			_definitions = (raw as Array).duplicate(true)


func _load_ch1_battle_list() -> void:
	_ch1_battle_ids.clear()
	_ch1_boss_battle_ids.clear()
	_ch1_graph_path = ""
	var f := FileAccess.open(CH1_BATTLES_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return
	var d: Dictionary = parsed as Dictionary
	_ch1_graph_path = str(d.get("graph", "")).strip_edges()
	var ids: Variant = d.get("battle_ids", [])
	if ids is Array:
		for id: Variant in ids:
			_ch1_battle_ids.append(str(id))
	var boss_ids: Variant = d.get("boss_battle_ids", [])
	if boss_ids is Array:
		for id: Variant in boss_ids:
			_ch1_boss_battle_ids.append(str(id))


func load_from_save(data: Dictionary) -> void:
	_values.clear()
	var gs: Variant = data.get("global_stats", {})
	if gs is Dictionary:
		for key: Variant in (gs as Dictionary).keys():
			_values[str(key)] = int((gs as Dictionary)[key])
	_first_touch = {}
	var ft: Variant = data.get("progress_first_touch", {})
	if ft is Dictionary:
		_first_touch = (ft as Dictionary).duplicate(true)
	_ch1_battles_won = {}
	var cw: Variant = data.get("ch1_exploration_battles_won", {})
	if cw is Dictionary:
		_ch1_battles_won = (cw as Dictionary).duplicate(true)
	_current_win_streak = int(data.get("current_win_streak", 0))
	_current_loss_streak = int(data.get("current_loss_streak", 0))
	_last_duel_loss_unix = float(data.get("last_duel_loss_unix", 0.0))
	_last_duel_was_loss = bool(data.get("last_duel_was_loss", false))
	_sync_quick_duel_loss_streak_from_save()
	call_deferred("_check_ch1_exploration_sweep_achievement")


func to_save_dict() -> Dictionary:
	_sync_quick_duel_loss_streak_to_save()
	return {
		"global_stats": _values.duplicate(true),
		"progress_first_touch": _first_touch.duplicate(true),
		"ch1_exploration_battles_won": _ch1_battles_won.duplicate(true),
		"current_win_streak": _current_win_streak,
		"current_loss_streak": _current_loss_streak,
		"last_duel_loss_unix": _last_duel_loss_unix,
		"last_duel_was_loss": _last_duel_was_loss,
	}


func get_definitions() -> Array:
	return _definitions.duplicate(true)


func get_int(stat_id: String) -> int:
	return int(_values.get(stat_id, 0))


func has_stat(stat_id: String) -> bool:
	var key: String = stat_id.strip_edges()
	if key.is_empty():
		return false
	for def: Variant in _definitions:
		if not def is Dictionary:
			continue
		if str((def as Dictionary).get("id", "")).strip_edges() == key:
			return true
	return false


func set_int(stat_id: String, value: int, persist: bool = true) -> void:
	var clamped: int = maxi(0, value)
	if int(_values.get(stat_id, 0)) == clamped:
		return
	_values[stat_id] = clamped
	emit_signal("stat_changed", stat_id, clamped)
	if persist:
		SaveManager.save_data()


func add_int(stat_id: String, delta: int = 1) -> void:
	if delta == 0:
		return
	set_int(stat_id, get_int(stat_id) + delta)


func set_flag(stat_id: String) -> void:
	if get_int(stat_id) >= 1:
		return
	set_int(stat_id, 1)


func is_flag_set(stat_id: String) -> bool:
	return get_int(stat_id) >= 1


func get_last_duel_was_loss() -> bool:
	return _last_duel_was_loss


func on_casual_mode_enabled() -> void:
	if _last_duel_was_loss:
		add_int("casual_mode_after_loss_count")


func on_protagonist_switched() -> void:
	add_int("protagonist_switch_count")


func on_quick_duel_reroll() -> void:
	add_int("quick_duel_reroll_count")


func on_credits_earned(amount: int) -> void:
	if amount > 0:
		add_int("credit_earned", amount)


func on_credits_spent(amount: int) -> void:
	if amount > 0:
		add_int("credit_spent", amount)


func on_pack_opened() -> void:
	add_int("pack_opened_count")


func on_new_card_collected() -> void:
	add_int("card_earned")


func on_union_discovered() -> void:
	set_int("union_discovered", SaveManager.unlocked_unions.size(), false)


func on_union_summoned(affinity: int = -1) -> void:
	add_int("union_summon_count")
	var stat_id: String = str(AFFINITY_TO_UNION_SUMMON_STAT.get(affinity, "")).strip_edges()
	if not stat_id.is_empty():
		add_int(stat_id)


func on_hidden_spot_clicked() -> void:
	add_int("hidden_spot_clicked")


func on_exploration_navigate() -> void:
	add_int("exploration_navigate_count")


func on_gallery_chapter_completed(vn_scene: String) -> void:
	var key: String = vn_scene.strip_edges()
	if key == PROLOGUE_VN:
		set_flag("prologue_complete")
	elif key == CH1_COMPLETE_VN:
		set_flag("chapter1_stage1_complete")
		AchievementManager.unlock("finish_chapter_1")


func on_prologue_tutorial_battle_reached() -> void:
	set_flag("prologue_tutorial_battle_reached")


func on_chapter1_boss_reached() -> void:
	set_flag("chapter1_stage1_boss_reached")


func on_first_touch(event_key: String) -> void:
	if _first_touch.get(event_key, false):
		return
	_first_touch[event_key] = true
	match event_key:
		"story_vn":
			if not _first_touch.get("quick_duel_battle", false):
				set_flag("story_vn_before_quick_duel_first")
		"quick_duel_battle":
			if not _first_touch.get("story_vn", false):
				set_flag("quick_duel_before_story_vn_first")
		"prologue_capsule":
			if not _first_touch.get("quick_duel_menu", false):
				set_flag("prologue_before_quick_duel_first")
		"quick_duel_menu":
			if not _first_touch.get("prologue_capsule", false):
				set_flag("quick_duel_before_prologue_first")
	SaveManager.save_data()


func on_exploration_battle_won(battle_id: String, graph_path: String) -> void:
	if battle_id.is_empty():
		return
	if _ch1_graph_path != "" and graph_path != _ch1_graph_path:
		return
	if battle_id not in _ch1_battle_ids:
		return
	if bool(_ch1_battles_won.get(battle_id, false)):
		return
	_ch1_battles_won[battle_id] = true
	if _ch1_exploration_sweep_complete():
		AchievementManager.unlock("ch1_all_exploration_enemies")
	SaveManager.save_data()


func _ch1_achievement_battle_ids() -> Array:
	var out: Array = []
	for bid: Variant in _ch1_battle_ids:
		var id: String = str(bid).strip_edges()
		if id.is_empty() or id in _ch1_boss_battle_ids:
			continue
		out.append(id)
	return out


func _ch1_exploration_sweep_complete() -> bool:
	var required: Array = _ch1_achievement_battle_ids()
	if required.is_empty():
		return false
	for bid: Variant in required:
		if not bool(_ch1_battles_won.get(str(bid), false)):
			return false
	return true


func _check_ch1_exploration_sweep_achievement() -> void:
	if _ch1_exploration_sweep_complete():
		AchievementManager.unlock("ch1_all_exploration_enemies")


func on_battle_abandoned() -> void:
	if _is_tutorial_context():
		return
	add_int("battle_abandon_count")


func on_duel_started(context: Dictionary) -> void:
	if _is_tutorial_context(context):
		return
	var now: float = Time.get_unix_time_from_system()
	if _last_duel_loss_unix > 0.0 and (now - _last_duel_loss_unix) < REMATCH_FAST_SECONDS:
		if bool(context.get("is_quick_duel", false)):
			add_int("quick_duel_rematch_fast_count")


func on_duel_finished(player_won: bool, context: Dictionary) -> void:
	if _is_tutorial_context(context):
		return
	var is_qd: bool = bool(context.get("is_quick_duel", false))
	var tier: String = str(context.get("quick_duel_battle_tier", "")).strip_edges()
	var reason: String = str(context.get("game_over_reason", "")).strip_edges()
	var analytics_tag: String = str(context.get("analytics_battle_tag", "")).strip_edges()

	add_int("duel_count")
	if player_won:
		add_int("duel_win")
		_current_win_streak += 1
		_current_loss_streak = 0
		_last_duel_was_loss = false
		var best: int = get_int("best_win_streak")
		if _current_win_streak > best:
			set_int("best_win_streak", _current_win_streak, false)
	else:
		add_int("duel_loss")
		_current_loss_streak += 1
		_current_win_streak = 0
		_last_duel_loss_unix = Time.get_unix_time_from_system()
		_last_duel_was_loss = true
		var max_loss: int = get_int("max_loss_streak")
		if _current_loss_streak > max_loss:
			set_int("max_loss_streak", _current_loss_streak, false)
		match reason:
			"crystals":
				add_int("duel_loss_crystals")
			"all_destroyed":
				add_int("duel_loss_wipe")
			"no_moves":
				add_int("duel_loss_no_moves")
			"surrender":
				add_int("surrender_count")
		if analytics_tag == "ch1_stage1_boss":
			add_int("chapter1_boss_loss_count")

	if is_qd:
		add_int("quick_duel_count")
		if player_won:
			add_int("quick_duel_win")
			if not is_flag_set("quick_duel_complete"):
				set_flag("quick_duel_complete")
		else:
			add_int("quick_duel_loss")
		if tier == "hard":
			add_int("quick_duel_attempts_hard")
			if not player_won:
				add_int("quick_duel_loss_hard")

	_sync_quick_duel_loss_streak_to_save()
	AchievementManager.on_duel_finished(player_won, context)
	SaveManager.save_data()


func is_frustration_high() -> bool:
	return get_int("quick_duel_loss_streak") >= 3


func _sync_quick_duel_loss_streak_from_save() -> void:
	_values["quick_duel_loss_streak"] = SaveManager.get_quick_duel_loss_streak()


func _sync_quick_duel_loss_streak_to_save() -> void:
	_values["quick_duel_loss_streak"] = SaveManager.get_quick_duel_loss_streak()


func _is_tutorial_context(context: Dictionary = {}) -> bool:
	if TutorialBattleManager.is_active or TutorialBattleManager.is_prepared:
		return true
	if bool(context.get("is_tutorial", false)):
		return true
	return false


func _sync_to_steam_backend() -> void:
	pass
