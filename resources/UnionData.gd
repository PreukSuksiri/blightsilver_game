class_name UnionData
extends Resource

## UnionData — static definition of one Union card.
##
## union_zone: Array of Vector2i (row_offset, col_offset) from anchor.
##   Anchor = top-left of bounding box (min row and col offsets are both 0).
##   Example: vertical 2-cell zone = [Vector2i(0,0), Vector2i(1,0)]
##
## material_conditions: unordered list — one condition dict per zone cell.
##   The validator finds an assignment of zone cells to conditions such that
##   every condition is satisfied by a distinct zone cell.
##   Remaining unassigned zone cells need only have any character card.
##
##   Condition dict keys (all optional):
##     "card_name"    : String — exact card_name match
##     "name_contains": String — card_name.to_lower() contains this substring
##     "affinity"     : int    — CharacterData.Affinity value (-1 = any)
##     "min_cost"     : int    — crystal_cost >= value
##     "min_atk"      : int    — base_atk >= value
##     "min_def"      : int    — base_def >= value
##     "has_flag"     : String — card.flags contains this string
##   Empty dict {} = any character card (no special requirement).

@export var card_name: String = ""
@export var display_name: String = ""   # Editable display name; falls back to card_name if empty
@export var affinity: CharacterData.Affinity = CharacterData.Affinity.DIVINE
@export var base_atk: int = 0
@export var base_def: int = 0
@export var summon_cost: int = 1000
@export var rarity: CharacterData.Rarity = CharacterData.Rarity.RARE
@export var ability_type: CharacterData.AbilityType = CharacterData.AbilityType.NONE
@export var ability_params: Dictionary = {}
@export var ability_description: String = ""
@export var partial_ability_description: String = ""
@export var formula_description: String = ""
@export var partial_formula_description: String = ""
@export var artwork_path: String = ""

## Whether this union card is included in the demo build.
@export var include_in_demo: bool = true

## Zone cell offsets from anchor (row, col).
@export var union_zone: Array = []  # Array[Vector2i]

## One condition dict per required material slot (parallel count to union_zone).
@export var material_conditions: Array = []  # Array[Dictionary]
