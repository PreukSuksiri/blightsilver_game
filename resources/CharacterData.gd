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
	DESTROYED_IF_BATTLES_DIVINE,  # Destroy this card after Reckoning with Divine (either role)
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

	# ── Combat stance ──
	ATTACK_STANCE_BOOST,             # +N ATK while attacking (temp, for that battle)
	DEFENSE_STANCE_BOOST,            # +N DEF while defending (temp, for that battle)

	# ── ATK/DEF bonus conditions ──
	ATK_BONUS_VS_FACEDOWN,           # +N ATK when attacking a face-down card
	ATK_BONUS_VS_UNION,              # +N ATK when attacking a Union card
	ATK_BONUS_IF_AFFINITY_ON_FIELD,  # +N ATK if specific affinity face-up on own field
	ATK_DEF_BONUS_IF_UNION_ON_FIELD, # +N ATK/DEF if Union card on own field
	ATK_DEF_BONUS_VS_NON_AFFINITY,   # +N ATK/DEF vs cards that don't match specified affinity
	DEF_BONUS_IF_AFFINITY_ON_FIELD,  # +N DEF if specific affinity card face-up on own field
	ATK_PENALTY_WHEN_EXPOSED,        # -N ATK permanently at end of the turn this card was first exposed
	PERM_ATK_BOOST_WHEN_EXPOSED,     # +N ATK permanently at end of the turn this card was first exposed
	ATK_PENALTY_IF_NO_NAME_ALLY,     # -N ATK if no other card matching name_contains on own field
	DEF_ZERO_WHEN_EXPOSED,           # DEF becomes 0 permanently at end of the turn this card was first exposed

	# ── Coin flip ──
	COIN_FLIP_ATK_BOOST,             # Flip 1 coin; heads → +N ATK this battle
	COIN_FLIP_CANCEL_ATTACK,         # Flip 1 coin before attack; tails → own attack is cancelled
	COIN_FLIP_EXTRA_ATTACK,          # Flip 1 coin after attacking; heads → get one extra attack
	COIN_FLIP_2_DESTROY_NON_AFFINITY,# Flip 2 coins; both heads → destroy defender if not specified affinity
	COIN_FLIP_SWAP_POSITION,         # Flip 1 coin after battle; heads → player chooses own card to swap position
	TURN_START_COIN_FLIP_FLAG,       # Turn start: coin flip → venom on any face-up card (heads) or mutagen on any card (tails)

	# ── Destroy / negate conditions ──
	DESTROY_IF_OPPONENT_AFFINITY,    # At battle calc, destroy defender if they match specified affinity
	DESTROY_SELF_VS_DIVINE_BOTH,     # Destroy self before Reckoning when battling Divine (either role)
	ATK_BONUS_VS_VENOM,              # +N ATK when battling a card that has the "venom" flag
	ATTACKER_ATK_DEBUFF,             # Reduce attacker's ATK by N during battle (when this card is defender)
	SWAP_ATK_DEF_WHEN_ATTACKING,     # Swap own ATK and DEF when this card attacks (temp for battle)
	NEGATE_ZERO_COST_TRAPS_BOTH,     # Passive: zero-cost traps have no effect for either player

	# ── One-use ATK boost ──
	ONE_USE_ATK_BOOST,               # Once per card lifetime, +N ATK when attacking
	ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND, # Once: +N ATK when attacking; once: +N DEF when defending (separate uses)

	# ── Post-attack extra attacks ──
	ONE_USE_EXTRA_ATTACK_ON_KILL,    # Once: win a battle → get one extra attack this turn
	EXTRA_ATTACK_VS_REVEALED,        # Attack a face-up card → get one extra attack (once per turn)
	MULTI_ATTACK_VS_NON_CHARACTER,   # Attack non-character cell → extra attack; up to N total attacks this turn
	ONE_USE_EXTRA_ATTACK_ON_DEAD_END,# Once: attack dead_end cell → get one extra attack
	EXTRA_ATTACK_ON_DEAD_END,        # Once per turn: attack dead_end cell → get one extra attack

	# ── Post-attack field effects ──
	LOCK_TARGET_ON_ATTACK,           # Attacked character cannot attack until end of their player's next turn
	LOCK_SELF_AFTER_ATTACK,          # This card cannot attack on its next available turn
	LOCK_ATTACKER_ON_DESTROYED,      # Card that destroys this card cannot attack again this turn
	PERM_DEF_BOOST_PER_ATTACK_SURVIVE, # +N DEF permanently each time this card attacks a unit and survives
	PERM_ATK_LOSS_PER_ATTACK,        # -N ATK permanently each time this card attacks
	ATK_ZERO_AFTER_WIN,              # ATK becomes 0 permanently after this card wins a battle

	# ── Post-attack reveal ──
	REVEAL_ON_WIN,                   # Win a battle → reveal 1 opponent cell (player chooses)
	REVEAL_ON_DEAD_END_ATTACK,       # Attack dead_end cell → reveal 1 opponent cell
	REVEAL_ON_ANY_ATTACK,            # After any attack → reveal 1 opponent cell
	REVEAL_ON_TRAP_ATTACK,           # Attack a trap → reveal 1 opponent cell

	# ── Post-attack crystal ──
	CRYSTAL_GAIN_ON_DEAD_END_ATTACK, # +N crystals when this card attacks a dead_end cell

	# ── Copy stats ──
	ONE_USE_COPY_STATS_ON_SURVIVE,   # Once: survive battle → gain ATK and DEF of battled card as perm bonus

	# ── Defend effects ──
	PERM_DEF_BOOST_ON_DEFEND,        # +N DEF permanently after this card successfully defends
	LOCK_ATTACKER_ON_DEFEND,         # Attacker cannot attack until end of their player's next turn
	ONE_USE_PERM_DEBUFF_ATTACKER_ATK,# Once: when defending, attacker permanently loses N ATK
	DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF, # When defending, attacker permanently loses N ATK and DEF
	ONE_USE_DEFEND_MORPH,            # Once: after defending, permanently loses N DEF and gains N ATK vs attacker affinity

	# ── Self modification ──
	SELF_DEBUFF_ON_ATTACK_AND_DEFEND,# Once: -N ATK on first attack; once: -N DEF on first defend

	# ── Turn-based ──
	PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN, # +N ATK permanently each time this card is alive at end of opponent's turn
	TEMP_ATK_BOOST_OWN_TURN_START,   # +N ATK (temp) at start of own turn; cleared at turn end
	PERM_ATK_LOSS_PER_OWN_TURN,      # -N ATK permanently at end of each of this card owner's turns (when face-up)
	SWAP_ATK_DEF_PER_OPP_TURN,       # Swap ATK/DEF values at end of each opponent's turn (when face-up)
	HALVE_DEF_ON_FIRST_EXPOSE,       # Halve DEF permanently the first time this card becomes face-up
	DESTROY_SELF_AT_END_OF_EXPOSE_TURN, # When first becoming face-up, destroyed at end of that turn
	VENOM_FLAG_END_OF_TURN,          # End of own turn: player chooses 1 face-up opponent card → add "venom" flag

	# ── Passive field effects ──
	OPPONENT_EXTRA_CRYSTAL_LOSS,     # Opponent loses +N extra crystals on every crystal loss event
	CRYSTAL_GAIN_ON_OPP_REVEAL,      # Gain +N crystals each time an opponent grid cell is revealed
	TEMP_BOOST_ON_OPP_TECH,          # +N ATK/DEF (permanent) when opponent plays a tech card
	ATK_BONUS_VS_CENTER_ZONE,        # +N ATK attacking center 3x3 zone; +M more for the very center cell
	CRYSTAL_RECOVER_ON_BIG_LOSS,     # If own crystal loss ≥ threshold in one event, recover N crystals
	ONE_USE_SURVIVE_DESTRUCTION,     # Once: when this card would be destroyed, it survives instead
	INTERCEPT_ALLY_ATTACK,           # When an allied specific-affinity card is targeted: prompt to intercept
	SACRIFICE_FOR_CARD_TYPE,         # When a card matching name_contains would be destroyed: prompt to sacrifice self
	OPTIONAL_CRYSTAL_PAY_ATK_BOOST,  # During battle: yes/no prompt to pay N crystals for +M ATK

	# ── Union abilities ──
	DOUBLE_STATS_VS_AFFINITY,            # ATK and DEF are doubled when battling a specific affinity
	FIELD_ATK_BOOST_OWN_AFFINITY,        # Passive aura: while face-up, all own face-up chars of affinity get +N ATK
	ONE_USE_DESTROY_BY_AFFINITY,         # Once: destroy defender if it matches aff1 or aff2 (no crystal loss to defender)
	COIN_FLIP_NULLIFY_ON_DEFEND,         # When this card is attacked, flip coin; heads = attack does nothing
	CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD, # Cannot attack if any own face-up card has non-allowed affinity
	END_OF_TURN_COIN_FLIP_STAT_BOOST,    # End of own turn: flip coin; heads = +N ATK perm; tails = +N DEF perm
	STANCE_FIXED_STATS,                  # When attacking: ATK/DEF set to fixed values; when defending: different fixed values
	MULTI_ATTACK_ANY,                    # Can attack up to N times per turn (any target)
	OPTIONAL_CRYSTAL_PAY_DEF_BOOST,      # During battle: yes/no prompt to pay N crystals for +M DEF
	DESTROY_SELF_AFTER_BATTLE,           # After any battle, this card is destroyed (no crystal loss)
	IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP, # Cannot be destroyed while another own face-up card of same affinity exists
	ATK_DEF_BONUS_IF_OWN_REVEALED_GTE,  # +N ATK/DEF if own revealed cell count >= threshold
	OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT, # During battle: pay N crystals to destroy opponent (no crystal loss to defender)
	ATK_PENALTY_VS_DEAD_END,             # Lose N ATK permanently when attacking a dead-end cell
	GAIN_HALF_STATS_ON_SURVIVE,          # After surviving a battle, gain half of opponent's ATK/DEF permanently
	MULTI_ATTACK_ANY_WITH_ATK_LOSS,      # Can attack up to N times; lose M ATK permanently per attack
	HALVE_ATK_ADD_TO_DEF_ON_DEFEND,      # When this card defends (and survives), halve own ATK permanently and add that to DEF

	# ── Newly implemented ──
	PERM_ATK_BOOST_ON_KILL_CAPPED,       # +N ATK permanently when this card destroys a character; capped at max_bonus total
	COPY_ALLY_STATS_ON_DESTROY,          # When an ally character is destroyed, optionally copy its ATK/DEF/Cost (works face-down)
	TEMP_ATK_HALF_TARGET,                # When attacking, +ATK equal to half of target's effective ATK (temp, this battle)
	COIN_FLIP_ATK_DEF_BOOST,             # Flip coin; heads → +N ATK and +N DEF until end of this turn

	# ── Union abilities (card_data_demo.xlsx) ──
	TURN_START_REVEAL_OPPONENT_CELL,     # Start of turn: reveal 1 foe cell; dead end → self destroy; else gain crystals
	POST_BATTLE_COIN_FLIP_DESTROY,       # After battle: coin flip; heads → destroy 1 foe character
	UNION_SUMMON_VENOM_ALL_FOE,          # On union summon: venom flag on all foe face-up characters
	IMMUNE_DESTROY_BY_NON_UNION,         # Cannot be destroyed unless attacker is a union card
	PERM_STAT_PENALTY_VS_NON_AFFINITY,   # Permanent -N ATK&DEF when battling non-matching affinity
	DEF_PENALTY_VS_NON_AFFINITY,         # Defender: -N DEF when attacked by non-matching affinity
	PERM_ATK_BOOST_ONCE_PER_AFFINITY,    # After battle vs non-affinity: +N ATK once per defender affinity
	CRYSTAL_GAIN_ON_DESTROY,             # After destroying a foe character: gain N crystals
	DESTROY_END_TURN_BLAST_ADJACENT,     # Destroy self at turn end; destroy adjacent foe face-up chars around last attack target
	UNION_SUMMON_REVIVE_MATCH,           # On union summon: revive 1 matching graveyard card (doubled cost)
	OPPONENT_TURN_END_SWAP_ATK_DEF,      # When opponent ends turn: they swap ATK/DEF on 1 own face-up card
}

@export var card_name: String = ""
@export var display_name: String = ""   # Editable display name; falls back to card_name if empty
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
@export var include_in_demo:  bool = false
@export var placeholder_art:  bool = false   # true = still using temp art, needs real illustration

func get_affinity_name() -> String:
	return Affinity.keys()[affinity]

func get_ability_description() -> String:
	if ability_description != "":
		return ability_description
	if ability_type == AbilityType.NONE:
		return "No ability."
	return "Special ability."
