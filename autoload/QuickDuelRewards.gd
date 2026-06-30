extends Node
## Weighted reward pools and loss-consolation helpers for Quick Duel.

const REWARDS_PATH := "res://data/quick_duel_rewards.json"
const CONFIG_PATH := "res://data/quick_duel_config.json"
const CREDIT_ICON_PATH := "res://assets/textures/ui/decorations/ui_icon_credit.png"
const DEFAULT_PACK_PATH := "res://assets/textures/cards/booster_pack/booster_pack_basic.png"
const FULL_CARDS_DIR := "res://assets/textures/cards/full_cards/"

var _data: Dictionary = {}
var _config: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	reload()


func reload() -> void:
	_data = _load_json_file(REWARDS_PATH)
	_config = _load_json_file(CONFIG_PATH)


func _load_json_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed as Dictionary if parsed is Dictionary else {}


func get_pool_for_tier(tier: String) -> Array:
	var tiers: Dictionary = _data.get("tiers", {})
	var block: Variant = tiers.get(tier, {})
	if block is Dictionary:
		return ((block as Dictionary).get("rewards", []) as Array).duplicate(true)
	return []


func get_all_tiers() -> Array:
	var tiers: Dictionary = _data.get("tiers", {})
	return tiers.keys()


func roll_offer_reward_count(tier: String) -> int:
	var chances: Dictionary = (_data.get("reward_count_chances", {}) as Dictionary).get(tier, {})
	if chances is Dictionary:
		match tier:
			"easy":
				return 2 if _rng.randf() < float((chances as Dictionary).get("two", 0.0)) else 1
			"normal":
				return 2 if _rng.randf() < float((chances as Dictionary).get("two", 0.0)) else 1
			"hard":
				return 3 if _rng.randf() < float((chances as Dictionary).get("three", 0.0)) else 2
	return 1


func pick_random_reward(tier: String) -> Dictionary:
	var pool: Array = get_pool_for_tier(tier)
	if pool.is_empty():
		return {}
	var total: float = 0.0
	for entry: Variant in pool:
		if entry is Dictionary:
			total += float((entry as Dictionary).get("weight", 1))
	if total <= 0.0:
		return {}
	var roll: float = _rng.randf() * total
	var cum: float = 0.0
	for entry: Variant in pool:
		if not entry is Dictionary:
			continue
		var ed: Dictionary = entry as Dictionary
		cum += float(ed.get("weight", 1))
		if roll < cum:
			return _finalize_pool_pick(ed)
	var last: Variant = pool.back()
	if last is Dictionary:
		return _finalize_pool_pick(last as Dictionary)
	return {}


func _finalize_pool_pick(entry: Dictionary) -> Dictionary:
	var picked: Dictionary = entry.duplicate(true)
	if str(picked.get("type", "")) == "random_card":
		return resolve_random_card_entry(picked)
	return picked


func pick_random_rewards(tier: String) -> Array:
	var count: int = roll_offer_reward_count(tier)
	var offer: Array = []
	var attempts: int = 0
	while offer.size() < count and attempts < 12:
		attempts += 1
		var reward: Dictionary = pick_random_reward(tier)
		if reward.is_empty():
			continue
		if _is_duplicate_in_offer(reward, offer):
			continue
		offer.append(reward)
	return dedupe_rewards(offer)


func dedupe_rewards(rewards: Array) -> Array:
	var out: Array = []
	for entry: Variant in rewards:
		if not entry is Dictionary:
			continue
		var reward: Dictionary = (entry as Dictionary).duplicate(true)
		if _is_duplicate_in_offer(reward, out):
			continue
		out.append(reward)
	return out


func resolve_random_card_entry(entry: Dictionary) -> Dictionary:
	# Pool JSON uses displayed star counts (1–5); CharacterData.Rarity is 0-indexed.
	var star_min: int = int(entry.get("rarity_min", 1))
	var star_max: int = int(entry.get("rarity_max", 5))
	var enum_range: Vector2i = _star_counts_to_enum_range(star_min, star_max)
	var enum_min: int = enum_range.x
	var enum_max: int = enum_range.y
	var eligible: Array[String] = []
	for cname: String in CardDatabase.get_all_character_names():
		var cd: CharacterData = CardDatabase.get_character(cname)
		if cd == null:
			continue
		if int(cd.rarity) < enum_min or int(cd.rarity) > enum_max:
			continue
		if SaveManager.demo_mode and not cd.include_in_demo:
			continue
		eligible.append(cname)
	for tname: String in CardDatabase.get_all_trap_names():
		var td: TrapData = CardDatabase.get_trap(tname)
		if td == null:
			continue
		if int(td.rarity) < enum_min or int(td.rarity) > enum_max:
			continue
		if SaveManager.demo_mode and not td.include_in_demo:
			continue
		eligible.append(tname)
	for ename: String in CardDatabase.get_all_tech_names():
		var tc: TechCardData = CardDatabase.get_tech(ename)
		if tc == null:
			continue
		if int(tc.rarity) < enum_min or int(tc.rarity) > enum_max:
			continue
		if SaveManager.demo_mode and not tc.include_in_demo:
			continue
		eligible.append(ename)
	if eligible.is_empty():
		push_warning(
			"QuickDuelRewards: no eligible random_card for %d–%d★ — fallback credits." % [star_min, star_max])
		return {"type": "credits", "amount": 100}
	var pick: String = eligible[_rng.randi_range(0, eligible.size() - 1)]
	return {"type": "card", "card_name": pick}


func tier_star_band(tier: String) -> Vector2i:
	match tier:
		"easy":
			return Vector2i(2, 3)
		"normal":
			return Vector2i(3, 4)
		"hard":
			return Vector2i(4, 5)
	return Vector2i(1, 5)


func card_star_count(card_name: String) -> int:
	var enum_r: int = _card_enum_rarity(card_name)
	return enum_r + 1 if enum_r >= 0 else 0


func reward_card_in_tier_band(tier: String, reward: Dictionary) -> bool:
	if str(reward.get("type", "")) != "card":
		return true
	var stars: int = card_star_count(str(reward.get("card_name", "")).strip_edges())
	if stars <= 0:
		return false
	var band: Vector2i = tier_star_band(tier)
	return stars >= band.x and stars <= band.y


func repair_tier_rewards(tier: String, rewards: Array) -> Array:
	var out: Array = []
	for entry: Variant in rewards:
		if not entry is Dictionary:
			continue
		var reward: Dictionary = (entry as Dictionary).duplicate(true)
		if str(reward.get("type", "")) == "card" and not reward_card_in_tier_band(tier, reward):
			reward = _pick_replacement_card_for_tier(tier, out)
		if _is_duplicate_in_offer(reward, out):
			continue
		out.append(reward)
	return out


func _pick_replacement_card_for_tier(tier: String, existing: Array) -> Dictionary:
	for _attempt: int in range(24):
		var candidate: Dictionary = _pick_random_card_for_tier(tier)
		if not _is_duplicate_in_offer(candidate, existing):
			return candidate
	return {"type": "credits", "amount": 100}


func _pick_random_card_for_tier(tier: String) -> Dictionary:
	var pool: Array = get_pool_for_tier(tier)
	var card_entries: Array = []
	for entry: Variant in pool:
		if entry is Dictionary and str((entry as Dictionary).get("type", "")) == "random_card":
			card_entries.append(entry)
	if card_entries.is_empty():
		return {"type": "credits", "amount": 100}
	for _attempt: int in range(24):
		var raw: Variant = card_entries[_rng.randi_range(0, card_entries.size() - 1)]
		if not raw is Dictionary:
			continue
		var resolved: Dictionary = resolve_random_card_entry(raw as Dictionary)
		if reward_card_in_tier_band(tier, resolved):
			return resolved
	return resolve_random_card_entry(card_entries[0] as Dictionary)


func _star_counts_to_enum_range(star_min: int, star_max: int) -> Vector2i:
	var emin: int = clampi(star_min - 1, 0, 4)
	var emax: int = clampi(star_max - 1, 0, 4)
	if emin > emax:
		emax = emin
	return Vector2i(emin, emax)


func _card_enum_rarity(card_name: String) -> int:
	var cd: CharacterData = CardDatabase.get_character(card_name)
	if cd != null:
		return int(cd.rarity)
	var td: TrapData = CardDatabase.get_trap(card_name)
	if td != null:
		return int(td.rarity)
	var tc: TechCardData = CardDatabase.get_tech(card_name)
	if tc != null:
		return int(tc.rarity)
	return -1


func get_reward_label(reward: Dictionary) -> String:
	match str(reward.get("type", "")):
		"credits", "coins":
			return "%d Credits" % int(reward.get("amount", 0))
		"booster_pack":
			return str(reward.get("pack_name", "Booster Pack"))
		"card":
			return str(reward.get("card_name", "Card"))
		"union_scroll":
			var cnt: int = int(reward.get("count", 1))
			return "Union Scroll" if cnt <= 1 else "Union Scroll ×%d" % cnt
		_:
			return str(reward.get("label", "Reward"))


func get_reward_icon_path(reward: Dictionary) -> String:
	match str(reward.get("type", "")):
		"credits", "coins":
			return CREDIT_ICON_PATH if ResourceLoader.exists(CREDIT_ICON_PATH) else ""
		"booster_pack":
			var pack_name: String = str(reward.get("pack_name", ""))
			var pack_dict: Dictionary = ShopManager.get_pack_by_name(pack_name)
			var pack_path: String = str(pack_dict.get("pack_image", ""))
			if pack_path != "" and ResourceLoader.exists(pack_path):
				return pack_path
			return DEFAULT_PACK_PATH if ResourceLoader.exists(DEFAULT_PACK_PATH) else ""
		"card":
			var card_name: String = str(reward.get("card_name", ""))
			if card_name.is_empty():
				return ""
			var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
			for candidate: String in [
				FULL_CARDS_DIR + snake + ".png",
				FULL_CARDS_DIR + "character_" + snake + ".png",
			]:
				if ResourceLoader.exists(candidate):
					return candidate
		"union_scroll":
			return UnionScrollManager.SCROLL_IMAGE
		_:
			pass
	return ""


func get_loss_consolation_min_turns() -> int:
	return int(_config.get("loss_consolation_min_turns", 4))


func get_loss_consolation_amount_for_streak(streak: int) -> int:
	var arr: Variant = _config.get("loss_consolation_streak", [200, 100, 50, 20])
	if not arr is Array or (arr as Array).is_empty():
		return 20
	var a: Array = arr as Array
	if streak < 0:
		streak = 0
	if streak >= a.size():
		return int(a[a.size() - 1])
	return int(a[streak])


func get_reroll_cost() -> int:
	return int(_config.get("reroll_cost", 100))


func get_tier_tags(tier: String) -> Array:
	var tags: Variant = (_config.get("tier_tags", {}) as Dictionary).get(tier, [])
	return (tags as Array).duplicate() if tags is Array else []


func get_tutorial_intro_vn() -> String:
	return str(_config.get("tutorial_intro_vn", "")).strip_edges()


## Last non-empty tutorial_battle path on a beat in a VN JSON array file.
func find_tutorial_battle_in_vn(vn_path: String) -> String:
	var trimmed := vn_path.strip_edges()
	if trimmed.is_empty() or not FileAccess.file_exists(trimmed):
		return ""
	var file := FileAccess.open(trimmed, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return ""
	var found := ""
	for beat: Variant in (parsed as Array):
		if not beat is Dictionary:
			continue
		var path: String = str((beat as Dictionary).get("tutorial_battle", "")).strip_edges()
		if not path.is_empty():
			found = path
	return found


func save_data(data: Dictionary) -> bool:
	if not BuildConfig.can_write_shipped_data():
		push_warning("QuickDuelRewards: shipped data can only be saved from the Godot editor.")
		return false
	var f := FileAccess.open(REWARDS_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	_data = data.duplicate(true)
	return true


func get_data() -> Dictionary:
	return _data.duplicate(true)


func _reward_fingerprint(reward: Dictionary) -> String:
	match str(reward.get("type", "")):
		"credits", "coins":
			return "credits:%d" % int(reward.get("amount", 0))
		"booster_pack":
			return "pack:%s" % str(reward.get("pack_name", ""))
		"card":
			return "card:%s" % str(reward.get("card_name", ""))
		"union_scroll":
			return "scroll:%d" % int(reward.get("count", 1))
		_:
			return JSON.stringify(reward)


func _is_duplicate_in_offer(reward: Dictionary, offer: Array) -> bool:
	var fp: String = _reward_fingerprint(reward)
	for existing: Variant in offer:
		if existing is Dictionary and _reward_fingerprint(existing as Dictionary) == fp:
			return true
	return false
