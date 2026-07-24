class_name DeckData
extends Resource
# Callers may also use: const DeckData = preload("res://resources/DeckData.gd")

const TOTAL_SLOTS:    int = 25   # grid cards (characters + traps + dead ends)
const MIN_CHARACTERS: int = 8
const MAX_CHARACTERS: int = 12
const MIN_TRAPS:      int = 4
const MAX_TRAPS:      int = 6
const TECH_COUNT:     int = 3   # exactly 3 tech cards held in hand
const MAX_FORMATIONS: int = 4

@export var deck_name:  String = "My Deck"
@export var characters: Array  = []   # Array of String card names
@export var traps:      Array  = []   # Array of String card names
@export var techs:      Array  = []   # Array of String card names (exactly TECH_COUNT)
# formations: Array of Dictionary
#   { "name": String, "placements": Array[Dictionary{r,c,name,type}] }
@export var formations: Array  = []
## Last formation saved/selected in the deckbuilder (used for battle setup).
@export var preferred_formation_index: int = 0

## Stable identity for equip / gallery (UUID string).
@export var deck_id: String = ""
## Unix timestamp used for gallery sort.
@export var created_at: int = 0
@export var featured_card_name: String = ""
@export var featured_card_type: String = ""  # character | trap | tech | union
## Limited (bound) starter decks for Mayu/Kelly — caps gate editable category sizes.
@export var limited: bool = false
@export var limited_caps: Dictionary = {}  # {characters, traps, techs}
## 0 = free gallery slot; 11 = Mayu reserved; 12 = Kelly reserved.
@export var reserved_slot: int = 0
## Free Switch-Deck gallery position 0..9; -1 = unassigned / reserved.
@export var gallery_slot: int = -1


static func make_deck_id() -> String:
	return str(Time.get_unix_time_from_system()) + "_" + str(randi())


func ensure_identity() -> void:
	if deck_id.strip_edges().is_empty():
		deck_id = make_deck_id()
	if created_at <= 0:
		created_at = int(Time.get_unix_time_from_system())


func get_limited_cap(category: String) -> int:
	if not limited:
		match category:
			"characters":
				return MAX_CHARACTERS
			"traps":
				return MAX_TRAPS
			"techs":
				return TECH_COUNT
			_:
				return 99
	return int(limited_caps.get(category, 0))


func is_limited_for_protagonist_equip() -> bool:
	return limited and reserved_slot in [11, 12]

# ── Derived ───────────────────────────────────────────────────
func dead_end_count() -> int:
	return TOTAL_SLOTS - characters.size() - traps.size()

func total_cards() -> int:
	return characters.size() + traps.size() + techs.size()

func is_valid() -> bool:
	return (characters.size() >= MIN_CHARACTERS
		and characters.size() <= MAX_CHARACTERS
		and traps.size() >= MIN_TRAPS
		and traps.size() <= MAX_TRAPS
		and techs.size() == TECH_COUNT
		and dead_end_count() >= 0)

func validation_message() -> String:
	var msgs: Array = []
	if characters.size() < MIN_CHARACTERS:
		msgs.append("Need %d more Character(s)" % (MIN_CHARACTERS - characters.size()))
	elif characters.size() > MAX_CHARACTERS:
		msgs.append("Too many Characters (max %d)" % MAX_CHARACTERS)
	if traps.size() < MIN_TRAPS:
		msgs.append("Need %d more Trap(s)" % (MIN_TRAPS - traps.size()))
	elif traps.size() > MAX_TRAPS:
		msgs.append("Too many Traps (max %d)" % MAX_TRAPS)
	if techs.size() < TECH_COUNT:
		msgs.append("Need %d more Tech Card(s)" % (TECH_COUNT - techs.size()))
	elif techs.size() > TECH_COUNT:
		msgs.append("Too many Tech Cards (exactly %d required)" % TECH_COUNT)
	if dead_end_count() < 0:
		msgs.append("Exceeds 25-card grid limit")
	if msgs.is_empty():
		return "Deck ready!"
	return " | ".join(msgs)

# ── Serialisation ─────────────────────────────────────────────
func to_dict() -> Dictionary:
	ensure_identity()
	var out: Dictionary = {
		"deck_name":  deck_name,
		"characters": characters.duplicate(),
		"traps":      traps.duplicate(),
		"techs":      techs.duplicate(),
		"formations": formations.duplicate(true),
		"preferred_formation_index": preferred_formation_index,
		"deck_id": deck_id,
		"created_at": created_at,
		"featured_card_name": featured_card_name,
		"featured_card_type": featured_card_type,
		"limited": limited,
		"limited_caps": limited_caps.duplicate(true),
		"reserved_slot": reserved_slot,
		"gallery_slot": gallery_slot,
	}
	return out

func load_from_dict(d: Dictionary) -> void:
	deck_name  = d.get("deck_name", "My Deck")
	characters = d.get("characters", [])
	traps      = d.get("traps", [])
	techs      = d.get("techs", [])
	var fv: Variant = d.get("formations", [])
	formations = (fv as Array).duplicate(true) if fv is Array else []
	preferred_formation_index = int(d.get("preferred_formation_index", 0))
	deck_id = str(d.get("deck_id", "")).strip_edges()
	created_at = int(d.get("created_at", 0))
	featured_card_name = str(d.get("featured_card_name", "")).strip_edges()
	featured_card_type = str(d.get("featured_card_type", "")).strip_edges()
	limited = bool(d.get("limited", false))
	var caps_raw: Variant = d.get("limited_caps", {})
	limited_caps = (caps_raw as Dictionary).duplicate(true) if caps_raw is Dictionary else {}
	reserved_slot = int(d.get("reserved_slot", 0))
	gallery_slot = int(d.get("gallery_slot", -1))
	clamp_formations_to_max()
	ensure_identity()


## Trim excess presets when older saves exceed `MAX_FORMATIONS`.
func clamp_formations_to_max() -> void:
	if formations.size() > MAX_FORMATIONS:
		formations = formations.slice(0, MAX_FORMATIONS)
	if formations.is_empty():
		preferred_formation_index = 0
	else:
		preferred_formation_index = clampi(preferred_formation_index, 0, formations.size() - 1)

func _formation_has_placements(formation_idx: int) -> bool:
	if formation_idx < 0 or formation_idx >= formations.size():
		return false
	var fd: Variant = formations[formation_idx]
	if not fd is Dictionary:
		return false
	var pls: Variant = (fd as Dictionary).get("placements", [])
	return pls is Array and not (pls as Array).is_empty()

## Formation to pre-fill in battle setup (saved preference, else first non-empty).
func get_preferred_formation_index() -> int:
	if formations.is_empty():
		return 0
	var saved: int = clampi(preferred_formation_index, 0, formations.size() - 1)
	if _formation_has_placements(saved):
		return saved
	for i in range(formations.size()):
		if _formation_has_placements(i):
			return i
	return 0

## Working copy for the deck builder — keeps the same deck_id / limited flags.
func clone_for_edit() -> DeckData:
	var copy: DeckData = get_script().new() as DeckData
	copy.load_from_dict(to_dict())
	return copy


func duplicate_deck() -> Resource:
	var copy: DeckData = clone_for_edit()
	# Fresh identity for copied decks (not a second reference to the same equip target).
	copy.deck_id = make_deck_id()
	copy.created_at = int(Time.get_unix_time_from_system())
	copy.limited = false
	copy.limited_caps = {}
	copy.reserved_slot = 0
	copy.gallery_slot = -1
	return copy


## Featured card name for gallery previews (explicit featured, else AI-vault-style strongest).
func resolve_featured_preview_name() -> String:
	var featured: String = featured_card_name.strip_edges()
	if not featured.is_empty() and _gallery_preview_art_exists(featured):
		return featured
	var char_names: Array = characters.duplicate()
	var best_union: UnionData = null
	for u: UnionData in UnionDatabase.get_all_unions():
		if u == null:
			continue
		if SaveManager.demo_mode and not UnionDatabase.is_playable_in_demo(u):
			continue
		if not UnionDatabase.deck_can_form_union(char_names, u):
			continue
		if not _gallery_preview_art_exists(u.card_name):
			continue
		if best_union == null or u.summon_cost > best_union.summon_cost:
			best_union = u
	if best_union != null:
		return best_union.card_name
	var best_char: String = ""
	var best_cost: int = -1
	for cname: Variant in char_names:
		var cd: CharacterData = CardDatabase.get_character(str(cname))
		if cd == null:
			continue
		if not _gallery_preview_art_exists(str(cname)):
			continue
		if cd.crystal_cost > best_cost:
			best_cost = cd.crystal_cost
			best_char = str(cname)
	if not best_char.is_empty():
		return best_char
	for tname: Variant in traps:
		if _gallery_preview_art_exists(str(tname)):
			return str(tname)
	for tech_name: Variant in techs:
		if _gallery_preview_art_exists(str(tech_name)):
			return str(tech_name)
	# Last resort: names even without resolved art (caller may still find a face).
	if not featured.is_empty():
		return featured
	if not char_names.is_empty():
		return str(char_names[0])
	if not traps.is_empty():
		return str(traps[0])
	if not techs.is_empty():
		return str(techs[0])
	return ""


func _gallery_preview_art_exists(card_name: String) -> bool:
	if card_name.strip_edges().is_empty():
		return false
	var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
	for candidate: String in [
		"res://assets/textures/cards/full_cards/" + snake + ".png",
		"res://assets/textures/cards/full_cards/character_" + snake + ".png",
	]:
		if ResourceLoader.exists(candidate):
			return true
	var subfolder: String = "characters"
	if CardDatabase.get_trap(card_name) != null:
		subfolder = "traps"
	elif CardDatabase.get_tech(card_name) != null:
		subfolder = "tech"
	elif UnionDatabase.get_union(card_name) != null:
		subfolder = "union"
	var art_path: String = CardDatabase.find_artwork(
		card_name, subfolder, SaveManager.nsfw_enabled)
	return not art_path.is_empty() and ResourceLoader.exists(art_path)

## Remove placements that reference cards no longer in the deck (or exceed deck copies).
func purge_stale_formation_placements() -> int:
	var char_pool: Dictionary = {}
	var trap_pool: Dictionary = {}
	for card_name: Variant in characters:
		var n: String = str(card_name)
		char_pool[n] = int(char_pool.get(n, 0)) + 1
	for card_name: Variant in traps:
		var n: String = str(card_name)
		trap_pool[n] = int(trap_pool.get(n, 0)) + 1

	var removed: int = 0
	for f: Variant in formations:
		if not f is Dictionary:
			continue
		var fd: Dictionary = f as Dictionary
		var pls: Array = fd.get("placements", []) as Array
		var used_chars: Dictionary = {}
		var used_traps: Dictionary = {}
		for i in range(pls.size() - 1, -1, -1):
			if not pls[i] is Dictionary:
				pls.remove_at(i)
				removed += 1
				continue
			var p: Dictionary = pls[i] as Dictionary
			var n: String = str(p.get("name", "")).strip_edges()
			var t: String = str(p.get("type", ""))
			var keep: bool = false
			if not n.is_empty():
				if t == "character":
					var avail: int = int(char_pool.get(n, 0))
					var used: int = int(used_chars.get(n, 0))
					if used < avail:
						keep = true
						used_chars[n] = used + 1
				else:
					var avail: int = int(trap_pool.get(n, 0))
					var used: int = int(used_traps.get(n, 0))
					if used < avail:
						keep = true
						used_traps[n] = used + 1
			if not keep:
				pls.remove_at(i)
				removed += 1
		fd["placements"] = pls
	return removed

## VN battle beats / campaign enemy config use "tech"; deckbuilder uses "techs".
func to_vn_deck_dict() -> Dictionary:
	return {
		"characters": characters.duplicate(),
		"traps":      traps.duplicate(),
		"tech":       techs.duplicate(),
	}

## Convert a deckbuilder formation preset to VN forced-cell entries.
func get_formation_forced_cells(formation_idx: int) -> Array:
	if formation_idx < 0 or formation_idx >= formations.size():
		return []
	var fd: Variant = formations[formation_idx]
	if not fd is Dictionary:
		return []
	var pls: Variant = (fd as Dictionary).get("placements", [])
	if not pls is Array:
		return []
	var result: Array = []
	for pl: Variant in (pls as Array):
		if not pl is Dictionary:
			continue
		var p: Dictionary = pl as Dictionary
		var r: int = int(p.get("r", -1))
		var c: int = int(p.get("c", -1))
		var card_name: String = str(p.get("name", "")).strip_edges()
		if r < 0 or r > 4 or c < 0 or c > 4 or card_name.is_empty():
			continue
		result.append({"card_name": card_name, "row": r, "col": c})
	return result

static func deck_dict_to_deck_data(d: Dictionary) -> DeckData:
	var deck := DeckData.new()
	deck.characters = (d.get("characters", []) as Array).duplicate()
	deck.traps = (d.get("traps", []) as Array).duplicate()
	var tech_raw: Variant = d.get("tech", d.get("techs", []))
	deck.techs = (tech_raw as Array).duplicate() if tech_raw is Array else []
	return deck
