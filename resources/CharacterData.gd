class_name CharacterData
extends Resource

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY,
	EXOTIC,
}

enum Affinity {
	DIVINE,
	CHAOS,
	NATURE,
	ARCANE,
	COSMIC,
	BIO,
	ANIMA
}

enum AbilityType {
	NONE,
	ATK_BONUS_VS_AFFINITY,        # +N ATK when battling specific affinity
	DEF_BONUS_VS_AFFINITY,        # +N DEF when battling specific affinity
	ATK_DEF_BONUS_VS_AFFINITY,    # +N ATK and DEF vs affinity
	IMMUNE_ZERO_COST_TRAPS,       # Not affected by 0-cost traps
	CRYSTAL_GAIN_ON_DEFEND,       # +N Crystals when successfully defends
	BOOST_PER_TYPED_CARD_ON_FIELD,# +N ATK/DEF per specific named card type on field
	BOOST_PER_ANIMA_ON_FIELD,     # +N ATK/DEF per face-up Anima card on own field
	HALVE_STATS_AFTER_ATTACK,     # Halve ATK and DEF permanently after attacking
	DESTROYED_IF_BATTLES_DIVINE,  # This card is destroyed if battling Divine
	IMMUNE_TO_TECH_CARDS,         # Not affected by Tech cards
	ATK_BONUS_IF_DICE_HIGH,       # +N ATK if dice roll >= threshold
	REVEAL_ADJACENT_AFTER_ATTACK, # Reveal an adjacent square after attacking
	ATK_BONUS_VS_TWO_AFFINITIES,  # +N ATK vs two specific affinities
	IMMUNE_TO_TRAPS,              # Cannot be destroyed by Traps
	IMMUNE_TO_TECH_DESTRUCTION,   # Cannot be destroyed by Tech Cards (but can be affected)
	REDIRECT_DESTRUCTION_TO_ALLY, # Can destroy ally of same affinity instead of self
	PERM_BOOST_END_OF_TURN,       # +N ATK/DEF permanently at end of each turn
	DOUBLE_TECH_EFFECT,           # Double effect of Tech Cards applied to this character
	ATK_BOOST_VS_REVEALED,        # +N ATK for one attack when attacking a revealed card
	DEFEND_DRAIN_ATTACKER,        # Attacker loses N Crystals when this card defends
	ONE_USE_DEF_BOOST,            # +N DEF once (one-time use)
	# Bio Mutagen abilities (activated by Release Mutagen tech card)
	MUTAGEN_ATK_BOOST_VS_AFFINITIES, # Bio: +N ATK vs affinities when Mutagen Flag active
	MUTAGEN_DESTROY_ATTACKER,        # Bio: Destroy attacker + no crystal loss when Mutagen Flag active
	MUTAGEN_IMMEDIATE_ATTACK,        # Bio: Can attack immediately once when Mutagen Flag obtained
	NOT_IMPLEMENTED,                 # Ability exists but has no engine implementation yet
}

@export var card_name: String = ""
@export var affinity: Affinity = Affinity.ANIMA
@export var base_atk: int = 0
@export var base_def: int = 0
@export var crystal_cost: int = 0
@export var ability_type: AbilityType = AbilityType.NONE
@export var ability_params: Dictionary = {}
@export var ability_description: String = ""
## Optional explicit path. If empty, Card.gd auto-discovers by snake_case name under
## res://assets/textures/cards/characters/  (e.g. "angel_gatekeeper.png")
@export var rarity: Rarity = Rarity.COMMON
@export var artwork_path: String = ""
@export var artwork_offset: Vector2 = Vector2.ZERO
@export var include_in_demo: bool = false

func get_affinity_name() -> String:
	return Affinity.keys()[affinity]

func get_ability_description() -> String:
	if ability_description != "":
		return ability_description
	if ability_type == AbilityType.NONE:
		return "No ability."
	return "Special ability."
