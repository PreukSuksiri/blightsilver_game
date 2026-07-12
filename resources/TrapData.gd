class_name TrapData
extends Resource

enum TrapEffectType {
	NULLIFY_ATTACK,                   # Attack does nothing
	NULLIFY_ATTACK_ATK_DEBUFF,        # Nullify + ATK debuff on all attackers
	NULLIFY_ATTACK_REVEAL_ADJACENT,   # Nullify + reveal adjacent squares (no-target lock)
	NULLIFY_ATTACK_CHOICE,            # Attacker chooses: lose crystals OR destroy own attacker
	REVEAL_DEFENDING_CHOICE,          # Defending player reveals a square
	ATTACKER_DISCARD_OR_END_TURN,     # Attacker: discard Tech OR end turn
	COPY_ATTACKER_EFFECT,             # Copy attacker's special to one of your face-up cards
	DESTROY_ATTACKER_CHOICE_DESTROY,  # Destroy attacker; attacker chooses 1 of your revealed to destroy too (no crystal loss)
	HYPNOTIZE_ATTACKER,               # Attacker cannot attack until end of next turn
	DESTROY_ATTACKER,                 # Destroy the attacking character
	LOCK_ATTACKER_REMAINING_ATTACKS,  # Attacking player cannot attack again this turn
	DRAIN_ATTACKER_CRYSTALS,          # Attacking player loses N Crystals (optional coin_count × amount per head)
	SWAP_ARMORED_NATURE,              # Swap this trap with an 'Armored' Nature card
	PERMANENT_ATK_DEBUFF,             # Permanent -N ATK to attacker
	NULLIFY_ATTACKER_EFFECT,          # Attacker's effect becomes None until end of next turn
	FORCE_FRIENDLY_FIRE,              # Attacker must choose own ally as target
	NULLIFY_BLOCK_ADJACENT,           # Nullify + block adjacent squares from being attacked this turn
	NOT_IMPLEMENTED,                 # Effect exists but has no engine implementation yet

	# ── New implemented trap effects ──
	FIELD_BOOST_AFFINITY_DEF,         # +N DEF (temp) to all face-up specific-affinity chars until end of turn
	SWAP_ATTACKER_ATK_DEF_TEMP,       # Swap attacker's ATK and DEF until end of defender's turn
	CANCEL_ATTACKER_ATTACK,           # Cancel the attacking card's attack (trap is consumed)
	DESTROY_ATTACKER_DEFENDER_PAYS,   # Destroy attacker; defending player also loses crystals = attacker's cost
	TEMP_DEBUFF_ALL_ATTACKER_CHARS,   # -N ATK (temp) to ALL attacking player's characters until end of turn
	TEMP_DEF_BOOST_ONE_OWN,           # +N DEF (temp) to 1 chosen own character until end of turn
	COIN_FLIP_2_ATK_DEBUFF,           # Flip 2 coins; both heads → attacker loses N ATK until end of next turn
	COIN_FLIP_2_LOCK_ATTACKER,        # Flip 2 coins; both heads → attacker cannot attack next turn
	SELF_DESTROY_TEMP_ATK_BOOST,      # Choose 1 own character: +N ATK until end of next turn, destroyed at end (no crystal cost)
	REVEAL_OWN_GAIN_CRYSTAL,          # Reveal 1 own face-down cell (choice); gain N crystals
	NULLIFY_ATTACK_REVEAL_DEFENDER_CHOICE,  # Nullify + trapper reveals/locks 1 own cell until turn end

	# ── Full-release trap effects ──
	AFFINITY_COIN_FLIP_DESTROY_ATTACKER,  # If attacker matches affinity: coin flip destroy; auto-head if crystals <= threshold
	END_ATTACKER_TURN_IF_AFFINITY,        # End attacker's turn if attacker matches affinity (optional clear flags)
	DESTROY_ATTACKER_IF_FIRST_ATTACK,     # Destroy attacker if it is the first attack this turn
	REVIVE_DESTROYED_ALLY_OPTIONAL,       # When own matching ally destroyed: optional flip to revive that unit
}

@export var card_name: String = ""
@export var display_name: String = ""   # Editable display name; falls back to card_name if empty
@export var crystal_cost: int = 0
@export var rarity: CharacterData.Rarity = CharacterData.Rarity.COMMON
@export var effect_type: TrapEffectType = TrapEffectType.NULLIFY_ATTACK
@export var effect_params: Dictionary = {}
@export var effect_description: String = ""
@export var artwork_path: String = ""
@export var artwork_offset: Vector2 = Vector2.ZERO
@export var include_in_demo:  bool = false
@export var placeholder_art:  bool = false   # true = still using temp art, needs real illustration

func get_effect_description() -> String:
	if effect_description != "":
		return effect_description
	return "Trap effect."
