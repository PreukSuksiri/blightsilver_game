extends Node
## OmenDatabase — global catalog of exploration Omens (chapter battle buffs).
##
## Data: data/omens.json, data/omen_rarity_weights.json
## Each omen entry: id, label, groups[], description, rarity, effects[], positive,
## implemented, include_in_demo, stackable, anoint_card_type, anoint_filter.

const OMENS_PATH: String = "res://data/omens.json"
const WEIGHTS_PATH: String = "res://data/omen_rarity_weights.json"

const DEFAULT_RARITY_WEIGHTS: Dictionary = {
	"common": 40,
	"uncommon": 20,
	"rare": 8,
	"epic": 3,
}

var _omens_by_id: Dictionary = {}
var _omens_all: Array = []
var _rarity_weights: Dictionary = DEFAULT_RARITY_WEIGHTS.duplicate()


func _ready() -> void:
	_load()


func reload() -> void:
	_load()


func _load() -> void:
	_omens_by_id.clear()
	_omens_all.clear()
	_load_rarity_weights()
	_load_omens()


func _load_rarity_weights() -> void:
	_rarity_weights = DEFAULT_RARITY_WEIGHTS.duplicate()
	if not FileAccess.file_exists(WEIGHTS_PATH):
		return
	var file := FileAccess.open(WEIGHTS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	for key: String in DEFAULT_RARITY_WEIGHTS.keys():
		var raw: Variant = parsed.get(key, null)
		if raw != null:
			_rarity_weights[key] = int(raw)


func _load_omens() -> void:
	if not FileAccess.file_exists(OMENS_PATH):
		return
	var file := FileAccess.open(OMENS_PATH, FileAccess.READ)
	if file == null:
		push_error("OmenDatabase: cannot read '%s'" % OMENS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	var entries: Variant = parsed.get("omens", []) if parsed is Dictionary else parsed
	if not entries is Array:
		push_error("OmenDatabase: expected { \"omens\": [...] } root")
		return
	for entry: Variant in entries:
		if not entry is Dictionary:
			continue
		var omen: Dictionary = (entry as Dictionary).duplicate(true)
		var id: String = str(omen.get("id", ""))
		if id.is_empty():
			continue
		_omens_by_id[id] = omen
		_omens_all.append(omen)


func get_omen(id: String) -> Dictionary:
	var found: Variant = _omens_by_id.get(id, null)
	if found is Dictionary:
		return (found as Dictionary).duplicate(true)
	return {}


func get_all_omens() -> Array:
	return _omens_all.duplicate(true)


## Unique omen group names sorted.
@warning_ignore("native_method_override")
func get_groups() -> Array:
	var seen: Dictionary = {}
	for omen: Variant in _omens_all:
		if not omen is Dictionary:
			continue
		for group_name: Variant in (omen as Dictionary).get("groups", []):
			var g: String = str(group_name).strip_edges()
			if g.is_empty():
				g = "ungrouped"
			seen[g] = true
	var groups: Array = seen.keys()
	groups.sort()
	return groups


func get_effective_weight(omen: Dictionary) -> int:
	if omen.has("weight"):
		return maxi(0, int(omen.get("weight", 0)))
	var rarity: String = str(omen.get("rarity", "common"))
	return maxi(0, int(_rarity_weights.get(rarity, _rarity_weights.get("common", 40))))


func is_anoint(omen: Dictionary) -> bool:
	return not str(omen.get("anoint_card_type", "")).strip_edges().is_empty()


func roll_offer(
		group_csv: String,
		held_ids: Array,
		count: int = 3,
		deck_card_names: Array = [],
		deck_card_meta: Array = [],
) -> Array:
	var held: Dictionary = {}
	for held_id: Variant in held_ids:
		held[str(held_id)] = true

	var requested_groups: Array = _parse_group_csv(group_csv)
	var deck_entries: Array = _build_deck_entries(deck_card_names, deck_card_meta)

	var pool: Array = []
	for omen: Variant in _omens_all:
		if not omen is Dictionary:
			continue
		var o: Dictionary = omen as Dictionary
		if not bool(o.get("implemented", false)):
			continue
		if SaveManager.demo_mode and not bool(o.get("include_in_demo", true)):
			continue
		var id: String = str(o.get("id", ""))
		if id.is_empty() or held.has(id):
			continue
		if not requested_groups.is_empty() and not _groups_intersect(o, requested_groups):
			continue
		if is_anoint(o) and get_eligible_deck_cards(o, deck_entries).is_empty():
			continue
		pool.append(o)

	return _weighted_sample_without_replacement(pool, count)


func get_eligible_deck_cards(omen: Dictionary, deck_entries: Array) -> Array:
	if not is_anoint(omen):
		return []
	var card_type: String = str(omen.get("anoint_card_type", "")).strip_edges().to_lower()
	var filt: Dictionary = omen.get("anoint_filter", {}) as Dictionary
	var eligible: Array = []
	for entry: Variant in deck_entries:
		if not entry is Dictionary:
			continue
		var card: Dictionary = entry as Dictionary
		if not _card_matches_anoint_type(card, card_type):
			continue
		if not _card_matches_anoint_filter(card, filt):
			continue
		eligible.append(card.duplicate(true))
	return eligible


func format_omen_line(held_entry: Dictionary) -> String:
	var id: String = str(held_entry.get("id", ""))
	var omen: Dictionary = get_omen(id)
	if omen.is_empty():
		return id
	var label: String = str(omen.get("label", id))
	var owner: int = int(held_entry.get("owner", 0))
	var anointed: String = str(held_entry.get("anointed_card", "")).strip_edges()
	# Enemy anoint target stays hidden until the card is public (face-up / played).
	if owner == 1:
		if anointed.is_empty() or not OmenVisuals.anoint_target_is_public(held_entry):
			return "Enemy: %s" % label
		return "Enemy: %s — %s" % [label, anointed]
	if anointed.is_empty():
		return label
	return "%s — %s" % [label, anointed]


## Public wrapper for deck-entry construction used by battle anoint helpers.
func deck_entry_from_name(card_name: String) -> Dictionary:
	return _deck_entry_from_name(card_name)


func _parse_group_csv(group_csv: String) -> Array:
	var csv: String = str(group_csv).strip_edges()
	if csv.is_empty():
		return []
	var groups: Array = []
	for part: String in csv.split(","):
		var g: String = part.strip_edges()
		if not g.is_empty():
			groups.append(g)
	return groups


func _groups_intersect(omen: Dictionary, requested_groups: Array) -> bool:
	var omen_groups: Array = omen.get("groups", []) as Array
	if omen_groups.is_empty():
		return requested_groups.has("ungrouped")
	for group_name: Variant in omen_groups:
		if requested_groups.has(str(group_name)):
			return true
	return false


func _build_deck_entries(deck_card_names: Array, deck_card_meta: Array) -> Array:
	if not deck_card_meta.is_empty():
		var entries: Array = []
		for entry: Variant in deck_card_meta:
			if entry is Dictionary:
				entries.append((entry as Dictionary).duplicate(true))
		return entries
	var entries_from_names: Array = []
	for card_name: Variant in deck_card_names:
		var name_str: String = str(card_name)
		if name_str.is_empty():
			continue
		entries_from_names.append(_deck_entry_from_name(name_str))
	return entries_from_names


func _deck_entry_from_name(card_name: String) -> Dictionary:
	var entry: Dictionary = {"name": card_name}
	var char_data: CharacterData = CardDatabase.get_character(card_name)
	if char_data != null:
		entry["type"] = "unit"
		entry["affinity"] = char_data.get_affinity_name()
		entry["cost"] = char_data.crystal_cost
		entry["atk"] = char_data.base_atk
		entry["def"] = char_data.base_def
		entry["ability_none"] = char_data.ability_type == CharacterData.AbilityType.NONE
		return entry
	var trap_data: TrapData = CardDatabase.get_trap(card_name)
	if trap_data != null:
		entry["type"] = "trap"
		entry["cost"] = trap_data.crystal_cost
		entry["ability_none"] = true
		return entry
	var tech_data: TechCardData = CardDatabase.get_tech(card_name)
	if tech_data != null:
		entry["type"] = "tech"
		entry["cost"] = tech_data.crystal_cost
		return entry
	entry["type"] = "unit"
	return entry


func _card_matches_anoint_type(card: Dictionary, card_type: String) -> bool:
	if card_type.is_empty():
		return true
	var card_entry_type: String = str(card.get("type", "unit")).strip_edges().to_lower()
	return card_entry_type == card_type


func _card_matches_anoint_filter(card: Dictionary, filt: Dictionary) -> bool:
	if filt.is_empty():
		return true
	if filt.has("affinity"):
		var want: String = str(filt.get("affinity", "")).strip_edges().to_upper()
		var have: String = str(card.get("affinity", "")).strip_edges().to_upper()
		if have != want:
			return false
	if bool(filt.get("ability_none", false)):
		if not bool(card.get("ability_none", false)):
			return false
	if filt.has("cost_max"):
		if int(card.get("cost", 0)) > int(filt.get("cost_max", 0)):
			return false
	if filt.has("cost_min"):
		if int(card.get("cost", 0)) < int(filt.get("cost_min", 0)):
			return false
	if filt.has("stat_sum_max"):
		var stat_sum: int = int(card.get("atk", 0)) + int(card.get("def", 0))
		if stat_sum > int(filt.get("stat_sum_max", 0)):
			return false
	if filt.has("name_contains"):
		var needle: String = str(filt.get("name_contains", ""))
		if not str(card.get("name", "")).contains(needle):
			return false
	if filt.has("name_contains_any"):
		var any_list: Variant = filt.get("name_contains_any", [])
		if any_list is Array:
			var card_name: String = str(card.get("name", ""))
			var matched: bool = false
			for fragment: Variant in any_list:
				if card_name.contains(str(fragment)):
					matched = true
					break
			if not matched:
				return false
	return true


func _weighted_sample_without_replacement(pool: Array, count: int) -> Array:
	if pool.is_empty() or count <= 0:
		return []
	var remaining: Array = pool.duplicate()
	var picked: Array = []
	var picks: int = mini(count, remaining.size())
	for _i: int in range(picks):
		var total_weight: int = 0
		for omen: Variant in remaining:
			if omen is Dictionary:
				total_weight += get_effective_weight(omen as Dictionary)
		if total_weight <= 0:
			break
		var roll: int = randi_range(1, total_weight)
		var cursor: int = 0
		var chosen_idx: int = -1
		for idx: int in range(remaining.size()):
			var o: Dictionary = remaining[idx] as Dictionary
			cursor += get_effective_weight(o)
			if roll <= cursor:
				chosen_idx = idx
				break
		if chosen_idx < 0:
			break
		var chosen: Dictionary = (remaining[chosen_idx] as Dictionary).duplicate(true)
		picked.append(chosen)
		remaining.remove_at(chosen_idx)
	return picked
