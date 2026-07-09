class_name TechCardData
extends Resource

enum TechEffectType {
	REVEAL_OPPONENT_SQUARE,           # Reveal N squares on opponent's field
	REVEAL_OPPONENT_SQUARE_CHAIN,     # Only works if previous chain card used
	REVEAL_OPPONENT_SQUARE_RISKY,     # Reveal N squares; pay 700 per card found
	OPPONENT_REVEALS_SQUARE,          # Opponent chooses and reveals 1 of their squares
	OPPONENT_REVEALS_OR_GAINS,        # Opponent can reveal a creature and receive N Crystals or do nothing
	BOTH_SKIP_TURN,                   # Both players skip 1 turn
	BOTH_LOCK_CHOSEN_MONSTER,         # Both players lock a chosen monster from attacking
	ADD_MUTAGEN_FLAG,                 # Add Mutagen Flag to a Bio Character
	DIVINE_PROTECTION,                # If a Divine on your field would be destroyed, it is not (once)
	DESTROY_ALL_REVEALED_OPPONENT,    # Destroy all revealed opponent Characters; discard all your Tech
	DESTROY_ROW_OR_COLUMN,            # Destroy all revealed cards in one row or column
	DESTROY_ROW_AROUND_TARGET,        # Destroy other face-up cards on anchor's row (anchor survives)
	REVEAL_ALL_OWN_CHARACTERS,        # Reveal up to N of your own units (count in effect_params)
	PERM_BOOST_ALL_FACEUP,            # +N ATK and DEF permanently to all face-up characters
	PERM_ATK_BOOST_ONE,               # +N ATK permanently to 1 face-up character
	TEMP_ATK_BOOST_ATTACK_NOW,        # +N ATK until end of turn; can attack immediately after
	TEMP_DEF_BOOST_ALL,               # +N DEF until end of next turn for all your characters
	PERM_DEF_BOOST_ONE,               # +N DEF permanently to 1 face-up character
	OPPONENT_NEXT_DEFENDER_DESTROYED, # Opponent's next defending character is destroyed (once)
	DESTROY_FACEUP_CARD,              # Destroy 1 face-up card
	DESTROY_FACEUP_NO_CRYSTAL_LOSS,   # Destroy 1 face-up card; owner doesn't lose crystals
	MULTI_ATTACK_ONE,                 # 1 character can attack multiple times; no other attacks allowed
	REVEAL_OWN_AND_OPPONENT_REVEALS,  # You reveal 1 your face-down; opponent must reveal 1 of theirs
	MOVE_BUFFS_BETWEEN_CHARACTERS,    # Move all ATK/DEF bonuses from one to another face-up
	DESTROY_OWN_BASE_ZERO_OPPONENT,   # Destroy 1 own card (no crystal); target opponent base ATK/DEF → 0
	CLONE_CHARACTER_AS_TOKEN,         # Copy a face-up character as token (no ability, 0 cost on destroy)
	REVIVE_CHARACTER_FULL,            # Revive 1 destroyed character to blank square, face-up
	REVIVE_CHARACTER_NO_ATK,          # Revive 1 destroyed character; ability None, ATK=0
	VIEW_OPPONENT_TECH,               # View 1 card in opponent's hand
	FORCE_SHIELD_ONE_CARD,            # 1 card on your field is not destroyed until end of opponent's turn
	DESTROY_WISPS_REVEAL_OPPONENT,    # Destroy all wisps on your field; reveal that many opponent squares
	TEMP_REROLL_DICE,                 # Until end of your next turn, you may re-roll the dice once
	TEMP_ATK_DEF_BOOST_ALL,          # +N ATK and +N DEF (temp) to all face-up characters until end of this turn
	GUERRILLA_TACTICS,               # Until opponent turn ends: coin flip when they attack your dead end
	DESTROY_VENOM_DOUBLE_COST,       # Select venom-flagged card; double its cost, then destroy it
	LIMIT_FOE_ATTACKS_NEXT_TURN,     # Next turn, foe can attack only once
	OPPONENT_CRYSTAL_GAIN_ON_DEAD_END, # This turn: foe gains N crystals per dead-end attack
	NOT_IMPLEMENTED,                 # Effect exists but has no engine implementation yet
}

@export var card_name: String = ""
@export var display_name: String = ""   # Editable display name; falls back to card_name if empty
@export var crystal_cost: int = 0
@export var rarity: CharacterData.Rarity = CharacterData.Rarity.COMMON
@export var effect_type: TechEffectType = TechEffectType.REVEAL_OPPONENT_SQUARE
@export var effect_params: Dictionary = {}
@export var effect_description: String = ""
@export var artwork_path: String = ""
@export var artwork_offset: Vector2 = Vector2.ZERO
@export var include_in_demo:  bool = false
@export var placeholder_art:  bool = false   # true = still using temp art, needs real illustration
# For chain cards that require prior cards to have been played
@export var required_prior_card: String = ""

func get_effect_description() -> String:
	if effect_description != "":
		return effect_description
	return "Tech card effect."
