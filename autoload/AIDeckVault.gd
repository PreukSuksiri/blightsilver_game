extends Node
# Named AI deck templates for battles (exploration, campaign, etc.).
# Edited via admin command: ai_deck_vault
#
# Entry schema: { id, label, tags, featured_union, deck, ... }
# featured_union — optional union name; AI strongly prefers it when summoning.
#
# Optional config fields on VN beats, dungeon nodes, exploration BATTLE nodes:
#   ai_deck_vault            — vault entry id (highest priority over inline ai_deck)
#   ai_deck_vault_formation  — formation index in deck.formations (default 0)

const SAVE_PATH := "res://data/ai_deck_vault.json"
const DeckData = preload("res://resources/DeckData.gd")

var _entries: Array = []


func _ready() -> void:
	reload()


func reload() -> void:
	_entries.clear()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var raw: Variant = (parsed as Dictionary).get("entries", [])
		if raw is Array:
			_entries = (raw as Array).duplicate(true)


func get_entries() -> Array:
	return _entries.duplicate(true)


func get_entry(entry_id: String) -> Dictionary:
	for e: Variant in _entries:
		if e is Dictionary and str((e as Dictionary).get("id", "")) == entry_id:
			return (e as Dictionary).duplicate(true)
	return {}


func get_deck(entry_id: String) -> DeckData:
	var entry := get_entry(entry_id)
	if entry.is_empty():
		return null
	var deck_raw: Variant = entry.get("deck", {})
	if not deck_raw is Dictionary:
		return null
	var deck := DeckData.new()
	deck.load_from_dict(deck_raw as Dictionary)
	return deck


func get_tags(entry_id: String) -> Array:
	var entry := get_entry(entry_id)
	if entry.is_empty():
		return []
	var raw: Variant = entry.get("tags", [])
	return (raw as Array).duplicate() if raw is Array else []


func get_featured_union(entry_id: String) -> String:
	var entry := get_entry(entry_id)
	if entry.is_empty():
		return ""
	return str(entry.get("featured_union", "")).strip_edges()


func populate_vault_option(opt: OptionButton, none_label: String = "(none — manual deck)") -> void:
	if opt == null:
		return
	opt.clear()
	opt.add_item(none_label)
	opt.set_item_metadata(0, "")
	reload()
	var idx := 1
	for e: Variant in _entries:
		if not e is Dictionary:
			continue
		var ed: Dictionary = e as Dictionary
		var eid: String = str(ed.get("id", "")).strip_edges()
		if eid.is_empty():
			continue
		var label: String = str(ed.get("label", eid))
		opt.add_item(label)
		opt.set_item_metadata(idx, eid)
		idx += 1


func option_entry_id(opt: OptionButton) -> String:
	if opt == null or opt.selected < 0:
		return ""
	return str(opt.get_item_metadata(opt.selected)).strip_edges()


func select_vault_option(opt: OptionButton, entry_id: String) -> void:
	if opt == null:
		return
	var needle := entry_id.strip_edges()
	for i: int in range(opt.item_count):
		if str(opt.get_item_metadata(i)).strip_edges() == needle:
			opt.select(i)
			return
	opt.select(0)


func populate_formation_option(opt: OptionButton, entry_id: String) -> void:
	if opt == null:
		return
	opt.clear()
	var deck: DeckData = get_deck(entry_id)
	if deck == null or deck.formations.is_empty():
		opt.add_item("(formation 1)")
		opt.set_item_metadata(0, 0)
		return
	for i: int in range(deck.formations.size()):
		var fd: Variant = deck.formations[i]
		var name: String = "Formation %d" % (i + 1)
		if fd is Dictionary:
			name = str((fd as Dictionary).get("name", name))
		opt.add_item(name)
		opt.set_item_metadata(i, i)


func option_formation_index(opt: OptionButton) -> int:
	if opt == null or opt.selected < 0:
		return 0
	return int(opt.get_item_metadata(opt.selected))


func select_formation_option(opt: OptionButton, formation_idx: int) -> void:
	if opt == null:
		return
	for i: int in range(opt.item_count):
		if int(opt.get_item_metadata(i)) == formation_idx:
			opt.select(i)
			return
	if opt.item_count > 0:
		opt.select(0)


func build_ai_battle_config(
		entry_id: String,
		formation_idx: int = 0,
		forced_tech_slots: Array = []
) -> Dictionary:
	var eid := entry_id.strip_edges()
	if eid.is_empty():
		return {"ok": false}
	var deck: DeckData = get_deck(eid)
	if deck == null:
		return {"ok": false}
	var form_idx: int = formation_idx
	if form_idx < 0 or form_idx >= deck.formations.size():
		form_idx = 0
	var forced_cells: Array = deck.get_formation_forced_cells(form_idx)
	var deck_tech: Array = deck.to_vn_deck_dict().get("tech", [])
	var merged_tech: Array = DailyDungeonManager.resolve_enemy_forced_tech(
		forced_tech_slots, deck_tech)
	return {
		"ok": true,
		"entry_id": eid,
		"deck": deck,
		"featured_union": get_featured_union(eid),
		"forced_cells": forced_cells,
		"forced_tech": merged_tech,
		"forced_characters": deck.characters.duplicate(),
		"forced_traps": deck.traps.duplicate(),
	}


func forced_cells_to_grid_dict(forced_cells: Array) -> Dictionary:
	var grid: Dictionary = {}
	for fc: Variant in forced_cells:
		if not fc is Dictionary:
			continue
		var fd: Dictionary = fc as Dictionary
		var r: int = int(fd.get("row", fd.get("r", -1)))
		var c: int = int(fd.get("col", fd.get("c", -1)))
		var card_name: String = str(fd.get("card_name", fd.get("name", ""))).strip_edges()
		if r < 0 or c < 0 or card_name.is_empty():
			continue
		grid["%d,%d" % [r, c]] = card_name
	return grid


func _set_featured_union_for_player(player_index: int, union_name: String) -> void:
	while GameState.battle_featured_unions.size() < 2:
		GameState.battle_featured_unions.append("")
	if player_index >= 0 and player_index < 2:
		GameState.battle_featured_unions[player_index] = union_name
	if player_index == 1:
		GameState.battle_ai_featured_union = union_name


## Apply vault config to AI opponent (player 1) battle slots.
func apply_enemy_battle_config(config: Dictionary) -> void:
	if not bool(config.get("ok", false)):
		return
	var deck: DeckData = config.get("deck") as DeckData
	if deck == null:
		return
	GameState.battle_ai_deck = deck
	GameState.battle_ai_forced_cells = (config.get("forced_cells", []) as Array).duplicate(true)
	GameState.battle_ai_forced_tech = (config.get("forced_tech", []) as Array).duplicate(true)
	GameState.campaign_enemy_config = {
		"forced_characters": (config.get("forced_characters", []) as Array).duplicate(),
		"forced_traps": (config.get("forced_traps", []) as Array).duplicate(),
		"forced_tech": (config.get("forced_tech", []) as Array).duplicate(),
	}
	_set_featured_union_for_player(1, str(config.get("featured_union", "")).strip_edges())


## Apply vault config to player 0 (AI vs AI left column).
func apply_player_battle_config(config: Dictionary) -> void:
	if not bool(config.get("ok", false)):
		return
	var deck: DeckData = config.get("deck") as DeckData
	if deck == null:
		return
	GameState.battle_player_deck = deck
	GameState.battle_player_forced_cells = (config.get("forced_cells", []) as Array).duplicate(true)
	_set_featured_union_for_player(0, str(config.get("featured_union", "")).strip_edges())


func resolve_vault_from_dict(source: Dictionary) -> Dictionary:
	var entry_id: String = str(source.get("ai_deck_vault", "")).strip_edges()
	if entry_id.is_empty():
		return {"ok": false}
	var formation_idx: int = int(source.get("ai_deck_vault_formation", 0))
	var tech_slots: Variant = source.get("ai_forced_tech", [])
	return build_ai_battle_config(
		entry_id,
		formation_idx,
		tech_slots if tech_slots is Array else [])


## Load vault entry deck + featured union into GameState battle AI slots (formation 0).
func apply_entry_to_battle(entry_id: String) -> bool:
	var cfg: Dictionary = build_ai_battle_config(entry_id, 0)
	if not bool(cfg.get("ok", false)):
		return false
	apply_enemy_battle_config(cfg)
	return true


func get_entries_by_tag(tag: String) -> Array:
	var needle := tag.strip_edges().to_lower()
	if needle.is_empty():
		return []
	var out: Array = []
	for e: Variant in _entries:
		if not e is Dictionary:
			continue
		var ed: Dictionary = e as Dictionary
		var raw: Variant = ed.get("tags", [])
		if not raw is Array:
			continue
		for t: Variant in (raw as Array):
			if str(t).strip_edges().to_lower() == needle:
				out.append(ed.duplicate(true))
				break
	return out


func save_entries(entries: Array) -> bool:
	_entries = entries.duplicate(true)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"entries": _entries}, "\t"))
	f.close()
	return true
