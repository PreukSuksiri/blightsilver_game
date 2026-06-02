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
	}

func load_from_dict(d: Dictionary) -> void:
	deck_name  = d.get("deck_name", "My Deck")
	characters = d.get("characters", [])
	traps      = d.get("traps", [])
	techs      = d.get("techs", [])
	var fv: Variant = d.get("formations", [])
	formations = (fv as Array).duplicate(true) if fv is Array else []

func duplicate_deck() -> Resource:
	var copy: Resource = get_script().new()
	copy.load_from_dict(to_dict())
	return copy
