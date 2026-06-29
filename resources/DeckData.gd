class_name DeckData
extends Resource
# Callers may also use: const DeckData = preload("res://resources/DeckData.gd")

const TOTAL_SLOTS:    int = 25   # grid cards (characters + traps + dead ends)
const MIN_CHARACTERS: int = 8
const MAX_CHARACTERS: int = 12
const MIN_TRAPS:      int = 4
const MAX_TRAPS:      int = 6
const TECH_COUNT:     int = 3   # exactly 3 tech cards held in hand
const MAX_FORMATIONS: int = 5

@export var deck_name:  String = "My Deck"
@export var characters: Array  = []   # Array of String card names
@export var traps:      Array  = []   # Array of String card names
@export var techs:      Array  = []   # Array of String card names (exactly TECH_COUNT)
# formations: Array of Dictionary
#   { "name": String, "placements": Array[Dictionary{r,c,name,type}] }
@export var formations: Array  = []
## Last formation saved/selected in the deckbuilder (used for battle setup).
@export var preferred_formation_index: int = 0

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
	return {
		"deck_name":  deck_name,
		"characters": characters.duplicate(),
		"traps":      traps.duplicate(),
		"techs":      techs.duplicate(),
		"formations": formations.duplicate(true),
		"preferred_formation_index": preferred_formation_index,
	}

func load_from_dict(d: Dictionary) -> void:
	deck_name  = d.get("deck_name", "My Deck")
	characters = d.get("characters", [])
	traps      = d.get("traps", [])
	techs      = d.get("techs", [])
	var fv: Variant = d.get("formations", [])
	formations = (fv as Array).duplicate(true) if fv is Array else []
	preferred_formation_index = int(d.get("preferred_formation_index", 0))

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

func duplicate_deck() -> Resource:
	var copy: Resource = get_script().new()
	copy.load_from_dict(to_dict())
	return copy

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
