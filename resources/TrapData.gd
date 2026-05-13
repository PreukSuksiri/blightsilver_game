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
	DRAIN_ATTACKER_CRYSTALS,          # Attacking player loses N Crystals
	SWAP_ARMORED_NATURE,              # Swap this trap with an 'Armored' Nature card
	PERMANENT_ATK_DEBUFF,             # Permanent -N ATK to attacker
	NULLIFY_ATTACKER_EFFECT,          # Attacker's effect becomes None until end of next turn
	FORCE_FRIENDLY_FIRE,              # Attacker must choose own ally as target
	NULLIFY_BLOCK_ADJACENT,           # Nullify + block adjacent squares from being attacked this turn
}

@export var card_name: String = ""
@export var crystal_cost: int = 0
@export var rarity: CharacterData.Rarity = CharacterData.Rarity.COMMON
@export var effect_type: TrapEffectType = TrapEffectType.NULLIFY_ATTACK
@export var effect_params: Dictionary = {}
@export var effect_description: String = ""
@export var artwork_path: String = ""
@export var artwork_offset: Vector2 = Vector2.ZERO

func get_effect_description() -> String:
	if effect_description != "":
		return effect_description
	return "Trap effect."
