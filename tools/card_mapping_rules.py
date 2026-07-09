"""Ability/effect mapping rules for full-release card import."""

from __future__ import annotations

import re

# ── Traps (49 mapped) ───────────────────────────────────────────────────────

TRAP_MAPPINGS: dict[str, dict] = {
    "Choking Gas": {
        "effect_type": "TEMP_DEBUFF_ALL_ATTACKER_CHARS",
        "effect_params": {"amount": 20},
    },
    "Radiation": {
        "effect_type": "PERMANENT_ATK_DEBUFF",
        "effect_params": {"amount": 10, "also_def": True, "void_trap_bonus": 10},
    },
    "Lava Trap Hole": {
        "effect_type": "DRAIN_ATTACKER_CRYSTALS",
        "effect_params": {"amount": 100, "coin_count": 3},
    },
    "Fissure": {
        "effect_type": "DRAIN_ATTACKER_CRYSTALS",
        "effect_params": {"amount": 200, "coin_count": 0},
    },
    "Soul Blast": {
        "effect_type": "DRAIN_ATTACKER_CRYSTALS",
        "effect_params": {"amount": 150, "per_void_unit": True},
    },
    "Grudge": {
        "effect_type": "PERMANENT_ATK_DEBUFF",
        "effect_params": {"amount": 10, "per_void_unit": True},
    },
    "Anti-virus": {
        "effect_type": "AFFINITY_COIN_FLIP_DESTROY_ATTACKER",
        "effect_params": {"affinity": "BIO", "crystal_threshold": 1000},
    },
    "Witch Hunt": {
        "effect_type": "AFFINITY_COIN_FLIP_DESTROY_ATTACKER",
        "effect_params": {"affinity": "ARCANE", "crystal_threshold": 1000},
    },
    "Standoff": {
        "effect_type": "AFFINITY_COIN_FLIP_DESTROY_ATTACKER",
        "effect_params": {"affinity": "ANIMA", "crystal_threshold": 1000},
    },
    "Apple of Adam": {
        "effect_type": "AFFINITY_COIN_FLIP_DESTROY_ATTACKER",
        "effect_params": {"affinity": "DIVINE", "crystal_threshold": 1000},
    },
    "Purify": {
        "effect_type": "AFFINITY_COIN_FLIP_DESTROY_ATTACKER",
        "effect_params": {"affinity": "CHAOS", "crystal_threshold": 1000},
    },
    "Solar Flare": {
        "effect_type": "AFFINITY_COIN_FLIP_DESTROY_ATTACKER",
        "effect_params": {"affinity": "COSMIC", "crystal_threshold": 1000},
    },
    "Hunting Season": {
        "effect_type": "AFFINITY_COIN_FLIP_DESTROY_ATTACKER",
        "effect_params": {"affinity": "NATURE", "crystal_threshold": 1000},
    },
    "Dart Trap": {
        "effect_type": "DESTROY_ATTACKER_IF_FIRST_ATTACK",
        "effect_params": {},
    },
    "Science Cage": {
        "effect_type": "END_ATTACKER_TURN_IF_AFFINITY",
        "effect_params": {"affinity": "BIO", "clear_flags": True},
    },
    "Loop Hole": {
        "effect_type": "END_ATTACKER_TURN_IF_AFFINITY",
        "effect_params": {"affinity": "ARCANE"},
    },
    "Talisman of Light": {
        "effect_type": "PERMANENT_ATK_DEBUFF",
        "effect_params": {"amount": 50, "required_attacker_affinity": "CHAOS"},
    },
    "Forbidden Grail": {
        "effect_type": "PERMANENT_ATK_DEBUFF",
        "effect_params": {"amount": 0, "def_debuff": 50, "required_attacker_affinity": "DIVINE"},
    },
    "Electric Fence": {
        "effect_type": "HYPNOTIZE_ATTACKER",
        "effect_params": {"required_attacker_affinity": "NATURE"},
    },
    "Discourage": {
        "effect_type": "TEMP_DEBUFF_ALL_ATTACKER_CHARS",
        "effect_params": {"amount": 15, "attacker_side_only": True, "until_attacker_next_turn": True},
    },
    "Galaxy Toll": {
        "effect_type": "DRAIN_ATTACKER_CRYSTALS",
        "effect_params": {"amount": 1000, "coin_count": 0, "required_attacker_affinity": "COSMIC"},
    },
    "Union Cage": {
        "effect_type": "HYPNOTIZE_ATTACKER",
        "effect_params": {"requires_union_attacker": True},
    },
    "Plunder": {
        "effect_type": "NULLIFY_ATTACK_CHOICE",
        "effect_params": {"crystal_gain": 2000, "destroy_option": True},
    },
    "Steel Scale": {
        "effect_type": "TEMP_DEF_BOOST_ONE_OWN",
        "effect_params": {"amount": 15, "all_allies": True},
    },
    "Trick Door": {
        "effect_type": "SWAP_ARMORED_NATURE",
        "effect_params": {"any_unit_relocate": True},
    },
    "Boiling Oil": {
        "effect_type": "TEMP_DEBUFF_ALL_ATTACKER_CHARS",
        "effect_params": {"amount": 10},
    },
    "Lightning Rod": {
        "effect_type": "DRAIN_ATTACKER_CRYSTALS",
        "effect_params": {"amount": 1000, "coin_count": 0, "on_tech_target": True},
    },
    "Dreamcatcher": {
        "effect_type": "NULLIFY_ATTACKER_EFFECT",
        "effect_params": {"trigger_on_foe_tech": True},
    },
    "Stumble": {
        "effect_type": "END_ATTACKER_TURN_IF_AFFINITY",
        "effect_params": {"any_attacker": True, "transfer_attacks": True},
    },
    "Ruckus": {
        "effect_type": "FIELD_BOOST_AFFINITY_DEF",
        "effect_params": {"affinity": "BIO", "atk": 5, "def": 0, "both_sides": True},
    },
    "Counter Punch": {
        "effect_type": "PERMANENT_ATK_DEBUFF",
        "effect_params": {"amount": 0, "def_debuff_temp": 5},
    },
    "Counter Tackle": {
        "effect_type": "PERMANENT_ATK_DEBUFF",
        "effect_params": {"amount": 0, "def_debuff_temp": 15},
    },
    "Share the Pain": {
        "effect_type": "DRAIN_ATTACKER_CRYSTALS",
        "effect_params": {"average_crystals_if_lte": 1000},
    },
    "Tripwire": {
        "effect_type": "DESTROY_ATTACKER",
        "effect_params": {"max_attacker_atk": 20, "no_destroy_cost": True},
    },
    "Rank C Bounty": {
        "effect_type": "DESTROY_ATTACKER",
        "effect_params": {"refund_half_cost_on_kill": True},
    },
    "Soak Wet": {
        "effect_type": "PERMANENT_ATK_DEBUFF",
        "effect_params": {"amount": 0, "def_debuff_temp": 5, "coin_count": 4, "per_head": True},
    },
    "Supersonic": {
        "effect_type": "COIN_FLIP_2_ATK_DEBUFF",
        "effect_params": {"amount": 5, "per_head": True, "carry_atk_debuff": True, "coin_count": 4},
    },
    "Kill Zone": {
        "effect_type": "DESTROY_ATTACKER",
        "effect_params": {"max_attacker_atk": 50, "no_destroy_cost": True},
    },
    "Boulder Trap": {
        "effect_type": "DESTROY_ATTACKER",
        "effect_params": {"max_attacker_def": 20, "no_destroy_cost": True},
    },
    "Rank S Bounty": {
        "effect_type": "PERMANENT_ATK_DEBUFF",
        "effect_params": {"amount": 0, "double_cost_until_turn_end": True},
    },
    "Flimsy Ground": {
        "effect_type": "DESTROY_ATTACKER",
        "effect_params": {"dead_end_surround": True, "no_destroy_cost": True},
    },
    "Shaky Ground": {
        "effect_type": "PERMANENT_ATK_DEBUFF",
        "effect_params": {"amount": 0, "def_debuff": 5, "dead_end_surround": True},
    },
    "Anti-intelligence": {
        "effect_type": "NULLIFY_ATTACKER_EFFECT",
        "effect_params": {"trigger_on_foe_reveal": True},
    },
    "Amnesia": {
        "effect_type": "NULLIFY_ATTACKER_EFFECT",
        "effect_params": {"trigger_on_foe_ability": True, "until_turn_end": True},
    },
    "Confiscate": {
        "effect_type": "NULLIFY_ATTACKER_EFFECT",
        "effect_params": {"trigger_on_foe_crystal_gain": True},
    },
    "Steel Fortress": {
        "effect_type": "TEMP_DEF_BOOST_ONE_OWN",
        "effect_params": {"amount": 15, "surround_affinity": "ANIMA"},
    },
    "Casino Swindler": {
        "effect_type": "NULLIFY_ATTACKER_EFFECT",
        "effect_params": {"trigger_on_foe_coin_flip": True, "coin_manipulation": "flip_override"},
    },
    "The House Always Win": {
        "effect_type": "NULLIFY_ATTACKER_EFFECT",
        "effect_params": {"trigger_on_foe_coin_flip": True, "coin_manipulation": "force_tails"},
    },
}

# ── Characters (all NOT_IMPLEMENTED + drift cards) ─────────────────────────

CHARACTER_MAPPINGS: dict[str, dict] = {
    "Alluring Spellcaster": {
        "ability_type": "LIMIT_FOE_ATTACKS_COIN_FLIP_ONCE",
        "ability_params": {},
    },
    "Cleaver Saint": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Deep Tribe Witchdoctor": {
        "ability_type": "DESTROY_IF_OPPONENT_AFFINITY",
        "ability_params": {"affinity": "NATURE", "invert": True, "once": True},
    },
    "Slim Gray Tank": {
        "ability_type": "ATK_DEF_BONUS_IF_OWN_REVEALED_GTE",
        "ability_params": {"per_revealed": True, "atk": 10, "def": 10},
    },
    "Silver Dragon": {
        "ability_type": "OPTIONAL_CRYSTAL_PAY_ATK_BOOST",
        "ability_params": {"cost": 1000, "atk": 0, "mandatory": True, "per_attack": True},
    },
    "Armored Wolf": {
        "ability_type": "SELF_DEBUFF_ON_ATTACK_AND_DEFEND",
        "ability_params": {"atk": 50, "def": -50, "once_in_reckoning": True},
    },
    "Berserker of Ice Sea": {
        "ability_type": "SELF_DEBUFF_ON_ATTACK_AND_DEFEND",
        "ability_params": {"atk": 35, "def": 0, "once_turn_end": True},
    },
    "Armored Elephant": {
        "ability_type": "PERM_DEF_BOOST_ON_DEFEND",
        "ability_params": {"def": -50, "per_successful_defense": True},
    },
    "Battle Penguin": {
        "ability_type": "ONE_USE_ATK_BOOST",
        "ability_params": {"bonus": 15},
    },
    "Sleeping Kirin": {
        "ability_type": "PERM_ATK_BOOST_WHEN_EXPOSED",
        "ability_params": {"amount": 25},
    },
    "Nunchuck Nun": {
        "ability_type": "ATK_DEF_BONUS_VS_AFFINITY",
        "ability_params": {"affinity": "CHAOS", "atk": 5, "def": 5},
    },
    "Totem Granpa": {
        "ability_type": "DEF_BONUS_VS_AFFINITY",
        "ability_params": {"affinity": "NATURE", "bonus": 30},
    },
    "Sandy Sphinx": {
        "ability_type": "COIN_FLIP_NULLIFY_ON_DEFEND",
        "ability_params": {},
    },
    "Gemmed Sphinx": {
        "ability_type": "COIN_FLIP_NULLIFY_ON_DEFEND",
        "ability_params": {},
    },
    "Black Anubis": {
        "ability_type": "END_OF_TURN_COIN_FLIP_STAT_BOOST",
        "ability_params": {"atk": 5, "def": 0, "max_atk": 25},
    },
    "Lucky Statue": {
        "ability_type": "DEF_BONUS_VS_AFFINITY",
        "ability_params": {"affinity": "CHAOS", "bonus": 20},
    },
    "Halo Guardian": {
        "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
        "ability_params": {"affinity": "CHAOS", "atk_bonus": 5, "def_bonus": 5, "field_scope": "foe", "exposed_only": True},
    },
    "Benjamin the Holy Craftsman": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"affinity": "DIVINE", "atk_bonus": 10, "def_bonus": 10, "exclude_self": True},
    },
    "Jiro the Battlemaster": {
        "ability_type": "PERM_ATK_LOSS_PER_OWN_TURN",
        "ability_params": {"amount": 10, "if_no_attack": True},
    },
    "Angel Mauler": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {"destroyer_affinity": "CHAOS", "permanent": True},
    },
    "Bloom Fairy": {
        "ability_type": "PERM_ATK_BOOST_ON_KILL_CAPPED",
        "ability_params": {"atk": 5, "max_bonus": 25, "turn_end": True},
    },
    "Steel Angel": {
        "ability_type": "SWAP_ATK_DEF_WHEN_ATTACKING",
        "ability_params": {"vs_affinity": "CHAOS"},
    },
    "Lady of the Sacred Pond": {
        "ability_type": "ATK_DEF_BONUS_VS_AFFINITY",
        "ability_params": {"affinity": "ANIMA", "atk": 20, "def": 20, "choice_affinity": "CHAOS"},
    },
    "Jill the Merciful Priestess": {
        "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
        "ability_params": {"affinity": "DIVINE", "atk_bonus": 20, "def_bonus": 20, "field_scope": "owner", "exposed_only": True},
    },
    "Nova Angel": {
        "ability_type": "ATK_BONUS_VS_TWO_AFFINITIES",
        "ability_params": {"aff1": "ARCANE", "aff2": "COSMIC", "bonus": 25, "def_bonus": 25},
    },
    "Oak Guardian": {
        "ability_type": "SACRIFICE_FOR_CARD_TYPE",
        "ability_params": {"name_contains": "Nature", "save_ally": True, "face_down": True},
    },
    "Cloud Beast": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {"destroyer_affinity": "ANIMA", "permanent": True},
    },
    "Da Loong": {
        "ability_type": "ATTACK_STANCE_BOOST",
        "ability_params": {"atk": 60, "def": 60, "when_exposed": True},
    },
    "Rama the Justice Arrow": {
        "ability_type": "PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY",
        "ability_params": {"def": 20, "target": "defender"},
    },
    "Hanuman the Second Wind": {
        "ability_type": "REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION",
        "ability_params": {"requires_divine_ally": True, "self_revive": True},
    },
    "Aurumancer": {
        "ability_type": "PERM_DEF_BOOST_ON_DEFEND",
        "ability_params": {"cost_set": 1500},
    },
    "Full-armored Seraphim": {
        "ability_type": "LOCK_SELF_AFTER_ATTACK",
        "ability_params": {"cannot_attack_facedown": True},
    },
    "The First Angel": {
        "ability_type": "REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION",
        "ability_params": {"from_void": True, "halve_stats": True},
    },
    "Gravedigger": {
        "ability_type": "PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY",
        "ability_params": {"affinity": "CHAOS", "def": 20, "as_attacker": True},
    },
    "Night Dweller": {
        "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
        "ability_params": {"field_scope": "void", "min_void": 3, "atk_bonus": 10, "def_bonus": 10},
    },
    "Anatomy Doll": {
        "ability_type": "CRYSTAL_GAIN_ON_DEFEND",
        "ability_params": {"amount": 300, "vs_affinity": "ANIMA"},
    },
    "Franky the Steel Claw": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"temp": True, "atk_bonus": 5, "ally_only": True},
    },
    "Toyol": {
        "ability_type": "COIN_FLIP_SWAP_POSITION",
        "ability_params": {"on_targeted": True, "once": True, "face_down": True},
    },
    "Human Dog": {
        "ability_type": "ATK_BONUS_IF_AFFINITY_ON_FIELD",
        "ability_params": {"affinities": ["ANIMA", "NATURE"], "bonus": 10},
    },
    "Evil Chef": {
        "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
        "ability_params": {"affinities": ["ANIMA", "NATURE"], "atk_bonus": 5, "def_bonus": 5, "field_scope": "foe", "exposed_only": True},
    },
    "Spider Lady": {
        "ability_type": "LOCK_ATTACKER_ON_DEFEND",
        "ability_params": {"once": True},
    },
    "Coffin Spider": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "crystal_cost": 500},
    },
    "Headless Rider": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "attack_cost": 2, "once": True},
    },
    "Restless Soldier": {
        "ability_type": "FIELD_DEBUFF_ALL_VENOM_CARDS",
        "ability_params": {"atk": 5, "def": 5, "per_void_unit": True, "target": "foe_reckoning"},
    },
    "Loyal Tomb Guard": {
        "ability_type": "REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION",
        "ability_params": {"turn_end_self": True, "crystal_threshold": 1200},
    },
    "Silent Stabber": {
        "ability_type": "HALVE_STATS_AFTER_ATTACK",
        "ability_params": {"expose_turn_end": True, "once": True},
    },
    "Mirror Lady": {
        "ability_type": "OPTIONAL_CRYSTAL_PAY_ATK_BOOST",
        "ability_params": {"cost": 300, "swap_foe_stats": True, "once": True},
    },
    "Tiyanak": {
        "ability_type": "TEMP_ATK_BOOST_OWN_TURN_START",
        "ability_params": {"atk": 20, "crystal_cost": 200, "optional": True},
    },
    "Red Closet": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 3, "crystal_threshold_lte": 1000},
    },
    "Mad Doctor": {
        "ability_type": "TEMP_BOOST_ON_OPP_TECH",
        "ability_params": {"crystal_gain": 150, "any_player": True},
    },
    "Dark Mistress": {
        "ability_type": "ATK_BONUS_IF_AFFINITY_ON_FIELD",
        "ability_params": {"field_scope": "void", "min_count": 8, "bonus": 50},
    },
    "The White Lady": {
        "ability_type": "TEMP_ATK_BOOST_OWN_TURN_START",
        "ability_params": {"atk": 40, "crystal_cost": 500, "optional": True},
    },
    "Flying Dutchman": {
        "ability_type": "IMMUNE_TO_TECH_CARDS",
        "ability_params": {"once_trap_immune": True},
    },
    "Dark Cavalier": {
        "ability_type": "PERM_ATK_LOSS_PER_OWN_TURN",
        "ability_params": {"amount": 20, "if_no_attack": True},
    },
    "Nachzehrer": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "requires_affinity_on_field": "ANIMA", "name_contains": "Vampire", "atk_per_match": 15},
    },
    "Pochong": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {"foe_gain": 500, "avoid_cost": True},
    },
    "Nostra the Necromancer": {
        "ability_type": "COPY_ALLY_STATS_ON_DESTROY",
        "ability_params": {"revive_ally": True, "max_cost": 600, "face_down": True},
    },
    "Bone Dragon": {
        "ability_type": "REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION",
        "ability_params": {"foe_turn_end": True, "coin_flip": True},
    },
    "Soul Overlord": {
        "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
        "ability_params": {"field_scope": "both_void", "atk_bonus": 15, "def_bonus": 0},
    },
    "Mole Scout": {
        "ability_type": "ATTACK_STANCE_BOOST",
        "ability_params": {"atk": 15, "when_facedown_attack": True, "temp": True},
    },
    "Zomborg": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {"invert_debuff": True},
    },
    "Seraph Lawkeeper": {
        "ability_type": "UNION_SUMMON_REVIVE_MATCH",
        "ability_params": {"affinities": ["DIVINE", "ANIMA"], "turn_end": True, "face_down": True},
    },
    "Fox Mage": {
        "ability_type": "ADJACENT_ATTACK_FLIP_BUFF",
        "ability_params": {"once_on_reveal": True, "affinity": "ARCANE", "atk": 20, "def": 20},
    },
    "Doctopus": {
        "ability_type": "COPY_ALLY_STATS_ON_DESTROY",
        "ability_params": {"affinity": "NATURE", "zero_atk_revive": True, "face_down": True},
    },
    "Sickle Mantis": {
        "ability_type": "PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY",
        "ability_params": {"def": 10, "target": "defender"},
    },
    "Deep Tribe Axe Thrower": {
        "ability_type": "ONE_USE_EXTRA_ATTACK_ON_KILL",
        "ability_params": {"vs_non_affinity": "NATURE", "per_turn": True},
    },
    "Shock Jellyfish": {
        "ability_type": "COIN_FLIP_NULLIFY_ON_DEFEND",
        "ability_params": {"end_foe_turn": True, "no_coin": True},
    },
    "Deep Tribe Warrior": {
        "ability_type": "ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND",
        "ability_params": {"atk": 50, "def": 50, "vs_non_affinity": "NATURE", "temp": True},
    },
    "Moon Owl": {
        "ability_type": "CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD",
        "ability_params": {"protect_facedown": True},
    },
    "Deep Tribe Healer": {
        "ability_type": "CRYSTAL_GAIN_ON_DEFEND",
        "ability_params": {"amount": 300, "name_contains": "Tribe", "half_cost": True, "face_down": True},
    },
    "Blood Hound": {
        "ability_type": "INTERCEPT_ALLY_ATTACK",
        "ability_params": {"target": "dead_end", "swap_self": True, "face_down": True},
    },
    "Crab Ronin": {
        "ability_type": "OPTIONAL_CRYSTAL_PAY_DEF_BOOST",
        "ability_params": {"cost": 1000, "def": 20, "permanent": True},
    },
    "Dryad": {
        "ability_type": "CRYSTAL_GAIN_ON_OPP_REVEAL",
        "ability_params": {"amount": 300, "on_foe_destroy": True, "when_exposed": True},
    },
    "Fern the Mermaid Princess": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"affinity": "NATURE", "def_bonus": 10, "attacked_this_turn": True, "temp_until_foe_turn": True},
    },
    "Sharoniel the Dragon Princess": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"name_contains": "princess", "atk_bonus": 30, "exposed_only": True},
    },
    "Nelfa the Windstorm Princess": {
        "ability_type": "DESTROY_IF_OPPONENT_AFFINITY",
        "ability_params": {"atk_exceeds_def_by": 30},
    },
    "Lindsy the Brave Princess": {
        "ability_type": "VENOM_FLAG_END_OF_TURN",
        "ability_params": {"flag": "princess", "turn_start": True, "ally_target": True},
    },
    "Diamond Porcupine": {
        "ability_type": "ONE_USE_PERM_DEBUFF_ATTACKER_ATK",
        "ability_params": {"atk": 60, "permanent": True},
    },
    "Volcanic Dragon": {
        "ability_type": "CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD",
        "ability_params": {"only_exposed_self": True},
    },
    "Ivy Golem": {
        "ability_type": "DOUBLE_TECH_EFFECT",
        "ability_params": {"double_cost_reckoning": True},
    },
    "Planewalker": {
        "ability_type": "ATK_BONUS_VS_AFFINITY",
        "ability_params": {"affinity": "ARCANE", "bonus": 10},
    },
    "Gremlin Worker": {
        "ability_type": "IMMUNE_ZERO_COST_TRAPS",
        "ability_params": {},
    },
    "Greedy Gremlin": {
        "ability_type": "PERM_BOOST_END_OF_TURN",
        "ability_params": {"atk": 10, "def": 10, "on_crystal_gain": True, "once": True},
    },
    "Magical Smith": {
        "ability_type": "ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND",
        "ability_params": {"atk": 5, "def": 5, "temp": True},
    },
    "Mighty Genie": {
        "ability_type": "ATK_DEF_BONUS_IF_UNION_ON_FIELD",
        "ability_params": {"affinity": "ARCANE", "atk": 5, "def": 5},
    },
    "Ore Transporter": {
        "ability_type": "CRYSTAL_GAIN_ON_OPP_REVEAL",
        "ability_params": {"amount": 20, "on_own_tech": True},
    },
    "Cloudbender": {
        "ability_type": "DEF_BONUS_VS_AFFINITY",
        "ability_params": {"affinity": "COSMIC", "bonus": 15},
    },
    "Freya the Rift Walker": {
        "ability_type": "INTERCEPT_ALLY_ATTACK",
        "ability_params": {"affinity": "ARCANE", "swap_self": True, "face_down": True},
    },
    "Bingo the Chrono Rabbit": {
        "ability_type": "COIN_FLIP_NULLIFY_ON_DEFEND",
        "ability_params": {"once": True, "no_coin": True},
    },
    "Ethereal Enchanter": {
        "ability_type": "TEMP_BOOST_ON_OPP_TECH",
        "ability_params": {"atk": 50, "def": 50, "on_own_tech": True, "until_foe_turn": True},
    },
    "Leviathan": {
        "ability_type": "REDIRECT_DESTRUCTION_TO_ALLY",
        "ability_params": {"affinity": "ARCANE", "crystal_cost": 500, "vs_non_arcane": True, "face_down": True},
    },
    "Corrupted Gremlin": {
        "ability_type": "PERM_BOOST_END_OF_TURN",
        "ability_params": {"atk": 10, "def": 0, "on_crystal_gain": True, "max_atk": 50},
    },
    "Zetamas the Great Summoner": {
        "ability_type": "UNION_SUMMON_REVIVE_MATCH",
        "ability_params": {"token_name": "Leviathan", "turn_end": True},
    },
    "Ethereal Shielder": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {"vs_non_affinity": "ARCANE", "per_turn": True},
    },
    "Moon Nobleman": {
        "ability_type": "OPTIONAL_CRYSTAL_PAY_DEF_BOOST",
        "ability_params": {"cost": 500, "on_survive_battle": True},
    },
    "Arcane Enforcer": {
        "ability_type": "CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD",
        "ability_params": {"allowed": ["ARCANE"], "invert": True},
    },
    "Thunder Daddy": {
        "ability_type": "LOCK_SELF_AFTER_ATTACK",
        "ability_params": {"exclusive_attacker": True, "after_expose": True},
    },
    "Sweet Lure Pod": {
        "ability_type": "INTERCEPT_ALLY_ATTACK",
        "ability_params": {"force_target_self": True, "this_turn": True},
    },
    "Lessor Leech": {
        "ability_type": "DEFEND_DRAIN_ATTACKER",
        "ability_params": {"drain_amount": 400, "self_gain": 400, "mutagen_bonus": 400},
    },
    "Gamma Amoeba": {
        "ability_type": "NEGATE_ZERO_COST_TRAPS_BOTH",
        "ability_params": {"nullify_foe_ability": True, "until_foe_turn": True},
    },
    "Sticky Grappler": {
        "ability_type": "COIN_FLIP_NULLIFY_ON_DEFEND",
        "ability_params": {"end_foe_turn_on_heads": True},
    },
    "S-02 the Hatcher": {
        "ability_type": "UNION_SUMMON_REVIVE_MATCH",
        "ability_params": {"token": True, "foe_turn_end": True},
    },
    "Toxin Folk": {
        "ability_type": "ATTACKER_ATK_DEBUFF",
        "ability_params": {"amount": 5, "when_exposed": True, "foe_attackers": True, "temp_until_foe_turn": True},
    },
    "Devoted Scientist": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"mutagen_flag": True, "atk_bonus": 40, "def_bonus": 40},
    },
    "Long Tongue": {
        "ability_type": "COIN_FLIP_ATK_BOOST",
        "ability_params": {"bonus": 0, "crystal_gain_heads": 50, "after_attack": True},
    },
    "Epsilon The Wither": {
        "ability_type": "ATTACK_STANCE_BOOST",
        "ability_params": {"atk": 40, "def": 40, "debuff_allies": 10},
    },
    "Plaguespreader": {
        "ability_type": "MUTAGEN_ATK_BOOST_VS_AFFINITIES",
        "ability_params": {"spread_mutagen": True, "turn_end": True},
    },
    "NG-01 the Forgotten Failure": {
        "ability_type": "REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION",
        "ability_params": {"on_any_destroy": True, "crystal_threshold": 1000, "stat_bonus": 40},
    },
    "Hydra": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 3, "attack_cost": 2, "mutagen": True},
    },
    "Abominable Scientist": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"mutagen_flag": True, "affinity": "BIO", "atk_bonus": 40, "def_bonus": 40},
    },
    "Parasite Queen": {
        "ability_type": "LOCK_ATTACKER_ON_DESTROYED",
        "ability_params": {"attacker_not_destroyed": True},
    },
    "Blind Jaw": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 1, "only_exposed_targets": True, "without_mutagen": True},
    },
    "Hive Overlord": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"affinity": "BIO", "def_bonus": 50, "double_cost": True},
    },
    "Solarling": {
        "ability_type": "REVEAL_ON_ANY_ATTACK",
        "ability_params": {"count": 1, "own_cell": True, "when_attacked": True},
    },
    "Europan Trooper": {
        "ability_type": "REVEAL_ON_ANY_ATTACK",
        "ability_params": {"flag": "Europa", "when_attacked": True},
    },
    "Tholin Shark": {
        "ability_type": "ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND",
        "ability_params": {"atk": 10, "def": 10, "vs_trap": True, "until_next_turn": True},
    },
    "Nebulomancer": {
        "ability_type": "ON_EXPOSE_REVEAL_FOE_ONCE",
        "ability_params": {"own_cell": True, "count": 1},
    },
    "Aembar the Intel Dealer": {
        "ability_type": "TEMP_BOOST_ON_OPP_TECH",
        "ability_params": {"reveal_on_tech": True, "any_player": True, "face_down": True},
    },
    "Tholin Lobster": {
        "ability_type": "EXTRA_ATTACK_ON_DEAD_END",
        "ability_params": {"vs_trap": True, "per_turn": True, "name_contains": "Tholin"},
    },
    "Europan Architect": {
        "ability_type": "TURN_START_COIN_FLIP_FLAG",
        "ability_params": {"flag": "Europa", "count": 2},
    },
    "Mastimus the Outlaw": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {"destroy_cost": 200},
    },
    "Europan Tankmaster": {
        "ability_type": "REDIRECT_DESTRUCTION_TO_ALLY",
        "ability_params": {"flag": "Europa", "remove_flag": True},
    },
    "Stratomancer": {
        "ability_type": "ON_EXPOSE_REVEAL_FOE_ONCE",
        "ability_params": {"own_cell": True, "count": 3},
    },
    "Lukkey the Jammer": {
        "ability_type": "NEGATE_ZERO_COST_TRAPS_BOTH",
        "ability_params": {"nullify_target_ability": True, "when_attacked": True},
    },
    "Tholin Kraken": {
        "ability_type": "COIN_FLIP_SWAP_POSITION",
        "ability_params": {"vs_trap": True, "name_contains": "Tholin", "crystal_gain": 200},
    },
    "Parasite Dione": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "mutagen": True},
    },
    "Europan Engineer": {
        "ability_type": "TURN_START_COIN_FLIP_FLAG",
        "ability_params": {"flag": "Europa", "target_affinity": "COSMIC"},
    },
    "Quezil the Space Rescuer": {
        "ability_type": "CRYSTAL_GAIN_ON_DEFEND",
        "ability_params": {"amount": 100, "per_void_affinity": "COSMIC"},
    },
    "Deozhor the Europan Warlord": {
        "ability_type": "ONE_USE_DESTROY_BY_AFFINITY",
        "ability_params": {"flag_cost": "Europa", "destroy_any": True},
    },
    "Parasite Titan": {
        "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
        "ability_params": {"affinity": "COSMIC", "atk_bonus": 50, "def_bonus": 50, "mutagen": True, "exposed_only": True},
    },
    "Moon Siren": {
        "ability_type": "ONE_USE_COPY_STATS_ON_SURVIVE",
        "ability_params": {"temp": True},
    },
    "Tholin Battleship": {
        "ability_type": "PERM_BOOST_END_OF_TURN",
        "ability_params": {"atk": 50, "def": 50, "vs_trap": True},
    },
    "Superionic Leviathan": {
        "ability_type": "PERM_ATK_LOSS_PER_OWN_TURN",
        "ability_params": {"crystal_or_halve": 1000},
    },
    "Xenospawn": {
        "ability_type": "IMMUNE_TO_TRAPS",
        "ability_params": {"atk_def_loss_vs_trap": 15},
    },
    "Mina the Chemist": {
        "ability_type": "CRYSTAL_GAIN_ON_DEFEND",
        "ability_params": {"amount": 150, "on_expose": True},
    },
    "Agent Matts": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "requires_name": "Agent", "once": True},
    },
    "Brave Knight": {
        "ability_type": "ONE_USE_EXTRA_ATTACK_ON_KILL",
        "ability_params": {"grant_attack_count": 1},
    },
    "Rifleman": {
        "ability_type": "ATK_BONUS_IF_AFFINITY_ON_FIELD",
        "ability_params": {"affinity": "ANIMA", "bonus": 5, "exposed_ally": True},
    },
    "Karate Master": {
        "ability_type": "ADJACENT_ATTACK_FLIP_BUFF",
        "ability_params": {"on_expose": True, "atk": 15, "def": 15, "any_own": True},
    },
    "Agent Penelope": {
        "ability_type": "ATK_BONUS_IF_AFFINITY_ON_FIELD",
        "ability_params": {"name_contains": "Agent", "bonus": 25, "exposed": True},
    },
    "Logan the Lumberjack": {
        "ability_type": "ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND",
        "ability_params": {"atk": 50, "def": 50, "vs_affinity": "NATURE", "temp": True},
    },
    "Infiltrator Squad": {
        "ability_type": "EXTRA_ATTACK_ON_DEAD_END",
        "ability_params": {"max_per_turn": 2, "grant_attack_count": 1},
    },
    "Dragon Hunter Eugene": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {
            "destroyer_name_contains": "Dragon",
            "permanent": True,
            "reckoning_debuff": {"name_contains": "Dragon", "def": 50},
        },
    },
    "Battle Maid Naru": {
        "ability_type": "MOON_ALLY_FIELD_AURA",
        "ability_params": {"affinity": "ANIMA", "atk_bonus": 5, "def_bonus": 5, "intercept_anima": True},
    },
    "Dragoon": {
        "ability_type": "ATK_DEF_BONUS_IF_UNION_ON_FIELD",
        "ability_params": {"name_contains": "Dragon", "atk": 40, "def": 40},
    },
    "Agent Rick": {
        "ability_type": "IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP",
        "ability_params": {"name_contains": "Agent"},
    },
    "Stealth Archer": {
        "ability_type": "HALVE_DEF_ON_FIRST_EXPOSE",
        "ability_params": {"also_atk": True, "expose_turn_end": True},
    },
    "Spell Ninja": {
        "ability_type": "PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY",
        "ability_params": {"def": 5, "target": "foe_reckoning_anima"},
    },
    "Battle Maid Kyoko": {
        "ability_type": "NEGATE_ZERO_COST_TRAPS_BOTH",
        "ability_params": {"nullify_foe_anima_ability": True, "intercept_anima": True},
    },
    "Royal Guard": {
        "ability_type": "REDIRECT_DESTRUCTION_TO_ALLY",
        "ability_params": {"affinity": "ANIMA", "half_cost_until_next_turn": True},
    },
    "Howard the Trigger Happy": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 3, "once": True, "double_cost": True},
    },
    "Fierce Cavalry": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "attack_cost": 2, "vs_facedown_bonus": 50},
    },
    "Atheist Rogue": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {"destroyer_affinity": "DIVINE", "permanent": True},
    },
    "War Queen": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"name_contains": "Knight", "def_bonus": 50},
    },
    "Vicmark the Sky Overlord": {
        "ability_type": "ATK_DEF_BONUS_VS_AFFINITY",
        "ability_params": {"target": "union_zone", "atk": 90, "def": 90, "requires_union_summon": True},
    },
    "Golden Knight": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "attack_cost": 2},
    },
    "Battle Maid Midori": {
        "ability_type": "ATTACK_STANCE_BOOST",
        "ability_params": {"affinity": "ANIMA", "atk": 100, "per_turn": True, "intercept_anima": True},
    },
    "Alchemist": {
        "ability_type": "CRYSTAL_GAIN_ON_DESTROY",
        "ability_params": {"amount": 500, "or_foe_loss": True},
    },
    "Stealth Bomber": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {"expose_turn_immune": True, "foe_cannot_target": True},
    },
    "Randez the Rogue King": {
        "ability_type": "ATK_DEF_BONUS_VS_AFFINITY",
        "ability_params": {"target": "union", "atk": 100, "def": 100, "penalty_vs_affinity": {"affinity": "ANIMA", "atk": 30, "def": 30}},
    },
    "Havoc the Gatling General": {
        "ability_type": "ONE_USE_EXTRA_ATTACK_ON_DEAD_END",
        "ability_params": {"grant_attack_count": 1, "turn_start": True},
    },
    "Paladin of Avalon": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "attack_cost": 2, "lock_next_turn": True},
    },
    "Evolving Cell": {
        "ability_type": "HALVE_ATK_ADD_TO_DEF_ON_DEFEND",
        "ability_params": {"once": True, "drain": 35, "zero_def_untargetable": True},
    },
    "Armored Unicorn": {
        "ability_type": "GAIN_HALF_STATS_ON_SURVIVE",
        "ability_params": {"atk": 15, "def": 15, "permanent": True},
    },
    "Spell Tank": {
        "ability_type": "TEMP_BOOST_ON_OPP_TECH",
        "ability_params": {"atk": 40, "on_own_tech": True, "temp": True},
    },
    "Hare Soldier": {
        "ability_type": "END_OF_TURN_COIN_FLIP_STAT_BOOST",
        "ability_params": {"coin_flips": 2, "atk": 5, "def": 5, "in_reckoning": True, "per_head_atk": True, "per_tail_def": True},
    },
    "Cullan the Magic Swordsman": {
        "ability_type": "ATK_DEF_BONUS_VS_NON_AFFINITY",
        "ability_params": {"affinity": "ARCANE", "atk": 10, "def": 10, "once_exposed": True, "coin_flip": True},
    },
    "Tornado Genie": {
        "ability_type": "END_OF_TURN_COIN_FLIP_STAT_BOOST",
        "ability_params": {"coin_flips": 4, "atk": 10, "def": 10, "in_reckoning": True, "per_head_atk": True, "per_tail_def": True},
    },
    "Mini Probe": {
        "ability_type": "COIN_FLIP_ATK_DEF_BOOST",
        "ability_params": {"bonus": 10},
    },
    "Wild West Raccoon": {
        "ability_type": "COIN_FLIP_ATK_DEF_BOOST",
        "ability_params": {
            "coin_flips": 3,
            "atk_per_head": 5,
            "def_per_tail": 5,
            "three_tails_penalty": {"atk": 15, "def": 15},
        },
    },
    "Sea Fortress": {
        "ability_type": "SWAP_ATK_DEF_WHEN_ATTACKING",
        "ability_params": {"coin_flip_choice": True, "in_reckoning": True},
    },
    "Blood Mage": {
        "ability_type": "OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT",
        "ability_params": {"cost": 1000},
    },
    "Lab Bloater": {
        "ability_type": "MUTAGEN_DESTROY_ATTACKER",
        "ability_params": {"both_pay_no_cost": True},
    },
    "Library Critters": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Energy Elf": {
        "ability_type": "CRYSTAL_GAIN_ON_DEFEND",
        "ability_params": {"amount": 100, "on_expose": True},
    },
    "Spikelings": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Beast-447": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Cyborg dog": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Spine Creeper": {
        "ability_type": "MULTI_ATTACK_ANY_WITH_ATK_LOSS",
        "ability_params": {"max_attacks": 2, "atk_loss": 30, "once": True},
    },
    "Blade Biker": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Dragon Hunter Vanrose": {
        "ability_type": "ONE_USE_ATK_BOOST",
        "ability_params": {"bonus": 100, "vs_name_contains": "Dragon"},
    },
    "Winter Tropper": {
        "ability_type": "ONE_USE_EXTRA_ATTACK_ON_KILL",
        "ability_params": {"grant_attack_count": 1, "on_successful_attack": True},
    },
    "Bomb Squad": {
        "ability_type": "DESTROY_END_TURN_BLAST_ADJACENT",
        "ability_params": {"once": True, "on_defend": True},
    },
    "White Knight": {
        "ability_type": "ATTACK_STANCE_BOOST",
        "ability_params": {"when_facedown_attack": True, "attacks_at_zero_count": True},
    },
    "Dragon Hunter Lumina": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"affinity": "ANIMA", "atk_bonus": 40, "vs_name_contains": "Dragon"},
    },
    "Jet Trooper": {
        "ability_type": "IMMUNE_TO_TRAPS",
        "ability_params": {"once": True},
    },
    "Lina the Swordmistress": {
        "ability_type": "ONE_USE_EXTRA_ATTACK_ON_KILL",
        "ability_params": {"grant_attack_count": 1, "per_turn": True, "on_successful_attack": True},
    },
    "Scythe Warrior": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Justin the Vampire Hunter": {
        "ability_type": "DESTROY_IF_OPPONENT_AFFINITY",
        "ability_params": {"affinity": "CHAOS"},
    },
    "Atheist Outlaw": {
        "ability_type": "DESTROY_IF_OPPONENT_AFFINITY",
        "ability_params": {"affinity": "DIVINE", "destroy_foe": True},
    },
    "Urban Zombie": {
        "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
        "ability_params": {
            "name_contains": "Zombie",
            "atk_bonus": 20,
            "def_bonus": 20,
            "requires_mutagen": True,
            "field_scope": "all",
        },
    },
    "Necro Zombie": {
        "ability_type": "REDIRECT_DESTRUCTION_TO_ALLY",
        "ability_params": {"name_contains": "Zombie"},
    },
    "Zombie Dog": {
        "ability_type": "REVEAL_ON_WIN",
        "ability_params": {"count": 1, "adjacent_to_target": True, "requires_mutagen": True},
    },
    "Zombie Knight": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Red Zombie": {
        "ability_type": "REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION",
        "ability_params": {"union_material": True, "requires_mutagen": True, "turn_end": True},
    },
    "Zombie Hunter": {
        "ability_type": "DESTROY_IF_OPPONENT_AFFINITY",
        "ability_params": {"name_contains": "Zombie"},
    },
    "Crystal Rabbit": {
        "ability_type": "NONE",
        "ability_params": {"union_material_crystal_gain": 500},
    },
    "Elven Archer": {
        "ability_type": "SELF_DEBUFF_ON_ATTACK_AND_DEFEND",
        "ability_params": {"atk": 0, "def": -30, "on_attack": True},
    },
    "Elven Swordsman": {
        "ability_type": "PERM_DEF_BOOST_ON_DEFEND",
        "ability_params": {"def": -20},
    },
    "Elven Blacksmith": {
        "ability_type": "ADJACENT_ATTACK_FLIP_BUFF",
        "ability_params": {"once": True, "affinity": "NATURE", "atk": 5, "def": 5, "on_adjacent_expose": True, "face_down": True},
    },
    "Elven Huntsman": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "adjacent_affinity": "NATURE", "once": True, "face_down": True},
    },
    "Elven Merchant": {
        "ability_type": "NONE",
        "ability_params": {"halve_adjacent_nature_cost": True},
    },
    "Dragonling": {
        "ability_type": "DEF_BONUS_IF_AFFINITY_ON_FIELD",
        "ability_params": {"affinity": "ARCANE", "bonus": -40, "invert": True, "face_up_required": True},
    },
    "War Dragon": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"name_contains": "Dragon", "atk_bonus": 10, "def_bonus": 10},
    },
    "Lesser Dragon": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Snow Dragon": {
        "ability_type": "LOCK_TARGET_ON_ATTACK",
        "ability_params": {"when_exposed": True, "select_foe": True, "until_foe_turn_end": True},
    },
    "Gold Dragon": {
        "ability_type": "CRYSTAL_GAIN_ON_DESTROY",
        "ability_params": {"foe_loss": 500, "min_target_cost": 800},
    },
    "Orc Maceman": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Orc Berserker": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2, "once": True},
    },
    "Orc Cannoneer": {
        "ability_type": "DESTROY_END_TURN_BLAST_ADJACENT",
        "ability_params": {"once": True, "on_attack": True},
    },
    "Orc Bannerlord": {
        "ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY",
        "ability_params": {"name_contains": "Orc", "atk_bonus": 15, "def_bonus": 15},
    },
    "Maria the Battle Priest": {
        "ability_type": "NONE",
        "ability_params": {"force_coin_heads_surrounding": True, "face_down": True},
    },
    "Travis the Battle Priest": {
        "ability_type": "POST_BATTLE_COIN_FLIP_DESTROY",
        "ability_params": {"reveal_adjacent": True, "destroy_affinity": "CHAOS"},
    },
    "Benedict the Battle Priest": {
        "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
        "ability_params": {"coin_flip": True, "name_contains": "Battle Priest"},
    },
    "Ninjamaster Sasuya": {
        "ability_type": "IMMUNE_DESTROY_BY_NON_UNION",
        "ability_params": {"name_contains": "Ninja", "ally_aura": True},
    },
    "Legendary Ninja": {
        "ability_type": "NEGATE_ZERO_COST_TRAPS_BOTH",
        "ability_params": {"nullify_union_effect_in_reckoning": True, "until_turn_end": True},
    },
}

# ── Tech (51 mapped) ────────────────────────────────────────────────────────

TECH_MAPPINGS: dict[str, dict] = {
    "Welcoming Door": {
        "effect_type": "REVEAL_ALL_OWN_CHARACTERS",
        "effect_params": {"count": 1, "any_own_cell": True},
        "required_prior_card": "",
    },
    "Secret Dagger": {
        "effect_type": "TEMP_ATK_BOOST_ATTACK_NOW",
        "effect_params": {"amount": 15, "face_down_only": True, "expose": True},
        "required_prior_card": "",
    },
    "Assassinate": {
        "effect_type": "DESTROY_FACEUP_CARD",
        "effect_params": {},
        "required_prior_card": "",
    },
    "Palace Party": {
        "effect_type": "REVEAL_OWN_AND_OPPONENT_REVEALS",
        "effect_params": {"own_count": 1, "opp_count": 1},
        "required_prior_card": "",
    },
    "Immortal Blood": {
        "effect_type": "REVIVE_CHARACTER_FULL",
        "effect_params": {"name_contains": "vampire"},
        "required_prior_card": "",
    },
    "Yin Yang Swap": {
        "effect_type": "MOVE_BUFFS_BETWEEN_CHARACTERS",
        "effect_params": {"swap_atk_def": True, "temp": True},
        "required_prior_card": "",
    },
    "Coin on the Street": {
        "effect_type": "OPPONENT_REVEALS_OR_GAINS",
        "effect_params": {"self_gain": 20},
        "required_prior_card": "",
    },
    "Bank Note on the Street": {
        "effect_type": "OPPONENT_REVEALS_OR_GAINS",
        "effect_params": {"self_gain": 50},
        "required_prior_card": "",
    },
    "Casual Gambling": {
        "effect_type": "TEMP_REROLL_DICE",
        "effect_params": {"coin_gain_heads": 100},
        "required_prior_card": "",
    },
    "Degen Gambling": {
        "effect_type": "TEMP_REROLL_DICE",
        "effect_params": {"coin_gain_heads": 200, "coin_loss_tails": 400},
        "required_prior_card": "",
    },
    "Gift": {
        "effect_type": "OPPONENT_REVEALS_OR_GAINS",
        "effect_params": {"opp_gain": 50},
        "required_prior_card": "",
    },
    "Hired Spanker": {
        "effect_type": "GUERRILLA_TACTICS",
        "effect_params": {"bluff_crystal_gain": 800},
        "required_prior_card": "",
    },
    "Tax Avoidance": {
        "effect_type": "BOTH_SKIP_TURN",
        "effect_params": {"skip_tax_only": True},
        "required_prior_card": "",
    },
    "Compensation": {
        "effect_type": "OPPONENT_CRYSTAL_GAIN_ON_DEAD_END",
        "effect_params": {"amount": 20},
        "required_prior_card": "",
    },
    "Tight Door": {
        "effect_type": "LIMIT_FOE_ATTACKS_NEXT_TURN",
        "effect_params": {"max_attacks": 1},
        "required_prior_card": "",
    },
    "Phony Fight": {
        "effect_type": "PERM_DEF_BOOST_ONE",
        "effect_params": {"amount": -10, "opp_gain": 500, "temp": True},
        "required_prior_card": "",
    },
    "Borrow": {
        "effect_type": "OPPONENT_REVEALS_OR_GAINS",
        "effect_params": {"self_gain": 200, "repay": 300},
        "required_prior_card": "",
    },
    "Flimsy Axe": {
        "effect_type": "TEMP_ATK_BOOST_ATTACK_NOW",
        "effect_params": {"amount": 5, "coin_flip": True},
        "required_prior_card": "",
    },
    "Flimsy Shield": {
        "effect_type": "TEMP_DEF_BOOST_ALL",
        "effect_params": {"amount": 5, "coin_flip": True, "single_target": True},
        "required_prior_card": "",
    },
    "All-out Tactics": {
        "effect_type": "PERM_ATK_BOOST_ONE",
        "effect_params": {"amount": 10, "zero_def": True},
        "required_prior_card": "",
    },
    "Fair Fight": {
        "effect_type": "PERM_BOOST_ALL_FACEUP",
        "effect_params": {"amount": 10, "both_players": True, "single_each": True},
        "required_prior_card": "",
    },
    "Loan": {
        "effect_type": "OPPONENT_REVEALS_OR_GAINS",
        "effect_params": {"self_gain": 600, "repay_next_turn": 800},
        "required_prior_card": "",
    },
    "Old Spear": {
        "effect_type": "TEMP_ATK_BOOST_ATTACK_NOW",
        "effect_params": {"amount": 5},
        "required_prior_card": "",
    },
    "Old Shield": {
        "effect_type": "TEMP_DEF_BOOST_ALL",
        "effect_params": {"amount": 5, "single_target": True},
        "required_prior_card": "",
    },
    "Provoke": {
        "effect_type": "FORCE_SHIELD_ONE_CARD",
        "effect_params": {"force_first_attack_cell": True},
        "required_prior_card": "",
    },
    "Mortgage": {
        "effect_type": "OPPONENT_REVEALS_OR_GAINS",
        "effect_params": {"self_gain": 1200, "repay": 1500},
        "required_prior_card": "",
    },
    "Pretify": {
        "effect_type": "PERM_DEF_BOOST_ONE",
        "effect_params": {"amount": 20, "zero_atk": True},
        "required_prior_card": "",
    },
    "Stone Skin": {
        "effect_type": "PERM_DEF_BOOST_ONE",
        "effect_params": {"amount": 20, "zero_atk": True, "ally_only": True},
        "required_prior_card": "",
    },
    "Battle Royale": {
        "effect_type": "PERM_BOOST_ALL_FACEUP",
        "effect_params": {"amount": 30, "both_players": True, "single_each": True},
        "required_prior_card": "",
    },
    "Toll": {
        "effect_type": "GUERRILLA_TACTICS",
        "effect_params": {"attack_tax": 500},
        "required_prior_card": "",
    },
    "Forest Fire": {
        "effect_type": "DESTROY_ALL_REVEALED_OPPONENT",
        "effect_params": {"count": 99, "affinity_filter": "NATURE", "discard_own_tech": True},
        "required_prior_card": "",
    },
    "Black Hole": {
        "effect_type": "DESTROY_ALL_REVEALED_OPPONENT",
        "effect_params": {"count": 99, "affinity_filter": "COSMIC", "discard_own_tech": True},
        "required_prior_card": "",
    },
    "Holy Arrival": {
        "effect_type": "DESTROY_ALL_REVEALED_OPPONENT",
        "effect_params": {"count": 99, "affinity_filter": "CHAOS", "discard_own_tech": True},
        "required_prior_card": "",
    },
    "Corrupted Heaven": {
        "effect_type": "DESTROY_ALL_REVEALED_OPPONENT",
        "effect_params": {"count": 99, "affinity_filter": "DIVINE", "discard_own_tech": True},
        "required_prior_card": "",
    },
    "Earthquake": {
        "effect_type": "DESTROY_ALL_REVEALED_OPPONENT",
        "effect_params": {"count": 99, "affinity_filter": "ANIMA", "discard_own_tech": True},
        "required_prior_card": "",
    },
    "Lab Destruction": {
        "effect_type": "DESTROY_ALL_REVEALED_OPPONENT",
        "effect_params": {"count": 99, "affinity_filter": "BIO", "discard_own_tech": True},
        "required_prior_card": "",
    },
    "Anti-magic Field": {
        "effect_type": "DESTROY_ALL_REVEALED_OPPONENT",
        "effect_params": {"count": 99, "affinity_filter": "ARCANE", "discard_own_tech": True},
        "required_prior_card": "",
    },
    "Air Shower": {
        "effect_type": "ADD_MUTAGEN_FLAG",
        "effect_params": {"clear_all_flags": True},
        "required_prior_card": "",
    },
    "Mining Tax": {
        "effect_type": "GUERRILLA_TACTICS",
        "effect_params": {"dead_end_drain": 200},
        "required_prior_card": "",
    },
    "Ouija": {
        "effect_type": "REVEAL_OPPONENT_SQUARE",
        "effect_params": {"count_per_void_unit": True},
        "required_prior_card": "",
    },
    "Deep Mine": {
        "effect_type": "REVEAL_OPPONENT_SQUARE",
        "effect_params": {"count": 2, "coin_flip": True},
        "required_prior_card": "",
    },
    "Bloody Machete": {
        "effect_type": "DESTROY_FACEUP_CARD",
        "effect_params": {"requires_own_card": "Bloody Mask"},
        "required_prior_card": "",
    },
    "Simple Unity": {
        "effect_type": "DESTROY_FACEUP_CARD",
        "effect_params": {"requires_union_none_ability": True},
        "required_prior_card": "",
    },
    "Nanomites Outbreak": {
        "effect_type": "DESTROY_VENOM_DOUBLE_COST",
        "effect_params": {"name_contains": "Nanomites", "count_from_own_field": True},
        "required_prior_card": "",
    },
    "Zombie Outbreak": {
        "effect_type": "PERM_DEF_BOOST_ONE",
        "effect_params": {"amount": -50, "foe_targets": True, "max_count_from_field": ["Zombie", "Mutant"]},
        "required_prior_card": "",
    },
    "Europa Supply": {
        "effect_type": "ADD_MUTAGEN_FLAG",
        "effect_params": {"flag": "Europa", "single_target": True},
        "required_prior_card": "",
    },
    "Simple Sword": {
        "effect_type": "TEMP_ATK_DEF_BOOST_ALL",
        "effect_params": {"atk": 20, "def": 20, "single_target": True, "none_ability_only": True, "until_foe_turn_end": True},
        "required_prior_card": "",
    },
    "Slim Gray Ray": {
        "effect_type": "REVEAL_ALL_OWN_CHARACTERS",
        "effect_params": {"count": 1, "both_players": True, "requires_own_card": "Slim Gray"},
        "required_prior_card": "",
    },
    "Oni Slam": {
        "effect_type": "DESTROY_FACEUP_CARD",
        "effect_params": {"foe_target": True, "requires_own_card_face_up": "Oni"},
        "required_prior_card": "",
    },
    "Knight\u2019s Oath": {
        "effect_type": "DIVINE_PROTECTION",
        "effect_params": {"name_contains": "Knight", "until_foe_turn_end": True},
        "required_prior_card": "",
    },
}

# Fill remaining tech from xlsx - add more as we discover names
# Run suggester to list unmapped

AFFINITY_WORDS = {
    "divine": "DIVINE", "chaos": "CHAOS", "nature": "NATURE", "arcane": "ARCANE",
    "cosmic": "COSMIC", "bio": "BIO", "anima": "ANIMA", "machine": "MACHINE",
}

# ── Unions (19 NOT_IMPLEMENTED + drift updates) ──────────────────────────────

UNION_MAPPINGS: dict[str, dict] = {
    "Nanomites Dragon": {
        "ability_type": "DESTROY_IF_OPPONENT_AFFINITY",
        "ability_params": {"affinity": "COSMIC"},
    },
    "Immortal Siegfried": {
        "ability_type": "IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP",
        "ability_params": {"affinity": "ANIMA", "union_zone": True},
    },
    "Dark Champion": {
        "ability_type": "ONE_USE_DESTROY_BY_AFFINITY",
        "ability_params": {"cannot_target_zero_def": True, "zero_atk_destroy_self": True},
    },
    "Europan Emperor": {
        "ability_type": "CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD",
        "ability_params": {"requires_flag": "Europa", "remove_flag_after_attack": True},
    },
    "Solarflare Dragon": {
        "ability_type": "UNION_SUMMON_REVEAL_FIELD",
        "ability_params": {"count": 3, "foe_choice": True, "crystal_per_dead_end": 500},
    },
    "Mutant Soldier": {
        "ability_type": "MUTAGEN_ATK_BOOST_VS_AFFINITIES",
        "ability_params": {"bonus": 100, "requires_mutagen": True},
    },
    "Mistress-001": {
        "ability_type": "UNION_SUMMON_PERM_ATK_OR_DEF_CHOICE",
        "ability_params": {"atk": 50, "def": -50, "target_other": True, "split": True},
    },
    "House of Flesh": {
        "ability_type": "IMMUNE_DESTROY_BY_NON_UNION",
        "ability_params": {"allowed_destroyer_affinities": ["CHAOS", "DIVINE"]},
    },
    "Eye in the Sky": {
        "ability_type": "UNION_SUMMON_REVEAL_FIELD",
        "ability_params": {"count_per_void_unit": True},
    },
    "Bloody Mask": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Cthulhu": {
        "ability_type": "PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY",
        "ability_params": {"target": "union_zone_foe", "atk": 50, "def": 50},
    },
    "Siege Engine": {
        "ability_type": "ONE_USE_DESTROY_BY_AFFINITY",
        "ability_params": {"destroy_defender": True, "once": True},
    },
    "Ultimate Railgun": {
        "ability_type": "CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD",
        "ability_params": {"void_only": "Railgun Ammo"},
    },
    "Ultimate Zombie": {
        "ability_type": "MUTAGEN_DESTROY_ATTACKER",
        "ability_params": {"destroy_foe_on_destroyed": True, "requires_mutagen": True},
    },
    "Dark Surgeon": {
        "ability_type": "UNION_SUMMON_REVIVE_MATCH",
        "ability_params": {"zero_def": True},
    },
    "One Winged Angel": {
        "ability_type": "PERM_BOOST_END_OF_TURN",
        "ability_params": {"atk": 30, "def": 0, "max_atk": 120},
    },
    "Manticore": {
        "ability_type": "END_OF_TURN_COIN_FLIP_STAT_BOOST",
        "ability_params": {"atk": 50, "flat_boost": True, "reset_on_attack": True},
    },
    "Lady Long Leng": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "White Ninja": {
        "ability_type": "NEGATE_ZERO_COST_TRAPS_BOTH",
        "ability_params": {"nullify_foe_ability_in_reckoning": True, "until_turn_end": True},
    },
    "Lab Abomination": {
        "ability_type": "NONE",
        "ability_params": {},
    },
    "Elven King": {
        "ability_type": "DEF_BONUS_IF_AFFINITY_ON_FIELD",
        "ability_params": {"affinity": "NATURE", "bonus": 100, "union_zone": True},
    },
    "Capnomancer": {
        "ability_type": "UNION_SUMMON_REVIVE_MATCH",
        "ability_params": {"revive_name": "Pyromancer", "destroy_self_turn_start": True},
    },
    "Gemina the Supreme Queen": {
        "ability_type": "IMMUNE_TO_TRAPS",
        "ability_params": {"block_tech_both_sides": True, "when_exposed": True},
    },
}


def normalize_ability(text: str) -> str:
    t = str(text or "").strip().replace("\n", " ")
    t = re.sub(r"\s+", " ", t)
    return t.lower()


def suggest_character(name: str, ability: str, affinity: str) -> dict | None:
    if name in CHARACTER_MAPPINGS:
        return CHARACTER_MAPPINGS[name]

    ab = normalize_ability(ability)
    if not ab or ab == "none":
        return {"ability_type": "NONE", "ability_params": {}}

    # Immune patterns
    if "unaffected by tech" in ab or "immune to tech" in ab:
        return {"ability_type": "IMMUNE_TO_TECH_CARDS", "ability_params": {}}
    if "unaffected by trap" in ab or "immune to trap" in ab:
        return {"ability_type": "IMMUNE_TO_TRAPS", "ability_params": {}}
    if "not affected by 0-cost trap" in ab or "0-cost trap" in ab:
        return {"ability_type": "IMMUNE_ZERO_COST_TRAPS", "ability_params": {}}


    # + N ATK&DEF vs X (space after +)
    m = re.search(r"\+\s*(\d+) atk&def vs (\w+)", ab)
    if m:
        aff = AFFINITY_WORDS.get(m.group(2).lower(), affinity.upper())
        v = int(m.group(1))
        return {"ability_type": "ATK_DEF_BONUS_VS_AFFINITY", "ability_params": {"affinity": aff, "atk": v, "def": v}}

    # +N DEF vs affinity
    m = re.search(r"\+(\d+) def vs (\w+)", ab)
    if m and "atk" not in ab[: m.start() + 5]:
        aff = AFFINITY_WORDS.get(m.group(2).lower(), affinity.upper())
        return {"ability_type": "DEF_BONUS_VS_AFFINITY", "ability_params": {"affinity": aff, "bonus": int(m.group(1))}}

    # +N ATK permanently
    m = re.search(r"\+(\d+) atk permanently", ab)
    if m:
        return {"ability_type": "PERM_ATK_BOOST_WHEN_EXPOSED", "ability_params": {"amount": int(m.group(1))}}

    # Sphinx-style defend coin flips
    if ("flip a coin" in ab or "flip 1 coin" in ab) and "defend" in ab:
        if "attack does nothing" in ab or "attack is negated" in ab or "attacker's attack is negated" in ab:
            return {"ability_type": "COIN_FLIP_NULLIFY_ON_DEFEND", "ability_params": {}}

    # ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND — once +N ATK&DEF vs affinity until end of turn
    m = re.search(r"once.*\+(\d+) atk&def vs (\w+)", ab)
    if m and "end" in ab:
        aff = AFFINITY_WORDS.get(m.group(2).lower(), affinity.upper())
        v = int(m.group(1))
        return {
            "ability_type": "ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND",
            "ability_params": {"atk": v, "def": v, "vs_affinity": aff, "temp": True},
        }

    # IMMUNE: not destroyed by affinity/name
    if "not destroyed by" in ab:
        m = re.search(r"not destroyed by [\"\']?(\w+)", ab)
        if m:
            daff = AFFINITY_WORDS.get(m.group(1).lower())
            if daff:
                return {
                    "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
                    "ability_params": {"destroyer_affinity": daff, "permanent": True},
                }
        if "dragon" in ab:
            return {
                "ability_type": "ONE_USE_SURVIVE_DESTRUCTION",
                "ability_params": {"destroyer_name_contains": "Dragon", "permanent": True},
            }

    # +N ATK until end of turn, once
    m = re.search(r"\+(\d+) atk until the end of that turn, once", ab)
    if m:
        return {"ability_type": "ONE_USE_ATK_BOOST", "ability_params": {"bonus": int(m.group(1))}}

    # +N ATK&DEF if exposed
    m = re.search(r"\+(\d+) atk&def if exposed", ab)
    if m:
        v = int(m.group(1))
        return {"ability_type": "ATTACK_STANCE_BOOST", "ability_params": {"atk": v, "def": v, "when_exposed": True}}

    # +N ATK&DEF vs two affinities
    m = re.search(r"\+(\d+) atk&def vs (\w+) and (\w+)", ab)
    if m:
        a1 = AFFINITY_WORDS.get(m.group(2).lower())
        a2 = AFFINITY_WORDS.get(m.group(3).lower())
        if a1 and a2:
            return {
                "ability_type": "ATK_BONUS_VS_TWO_AFFINITIES",
                "ability_params": {"aff1": a1, "aff2": a2, "bonus": int(m.group(1)), "def_bonus": int(m.group(1))},
            }

    # vs affinity ATK
    m = re.search(r"\+(\d+) atk vs (\w+)", ab)
    if m and "def" not in ab.split("vs")[0][-10:]:
        aff = AFFINITY_WORDS.get(m.group(2).lower(), affinity.upper())
        return {"ability_type": "ATK_BONUS_VS_AFFINITY", "ability_params": {"affinity": aff, "bonus": int(m.group(1))}}

    m = re.search(r"\+(\d+) atk&def vs non-(\w+)", ab)
    if m:
        aff = AFFINITY_WORDS.get(m.group(2).lower(), affinity.upper())
        return {"ability_type": "ATK_DEF_BONUS_VS_NON_AFFINITY", "ability_params": {"affinity": aff, "atk": int(m.group(1)), "def": int(m.group(1))}}

    m = re.search(r"\+(\d+) atk and def vs non-(\w+)", ab)
    if m:
        aff = AFFINITY_WORDS.get(m.group(2).lower(), affinity.upper())
        return {"ability_type": "ATK_DEF_BONUS_VS_NON_AFFINITY", "ability_params": {"affinity": aff, "atk": int(m.group(1)), "def": int(m.group(1))}}

    # per card on field
    m = re.search(r"\+(\d+) atk&def for each (?:other )?(\w+)", ab)
    if m:
        aff = AFFINITY_WORDS.get(m.group(2).lower())
        if aff:
            scope = "all" if "on the field" in ab and "its side" not in ab and "your" not in ab else "owner"
            return {
                "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
                "ability_params": {"affinity": aff, "atk_bonus": int(m.group(1)), "def_bonus": int(m.group(1)), "field_scope": scope},
            }

    # Mutagen
    if "mutagen flag" in ab:
        if "destroy" in ab and "reckoning" in ab:
            return {"ability_type": "MUTAGEN_DESTROY_ATTACKER", "ability_params": {}}
        if "not destroyed" in ab:
            return {"ability_type": "ONE_USE_SURVIVE_DESTRUCTION", "ability_params": {"requires_mutagen": True}}
        m = re.search(r"\+(\d+) atk", ab)
        if m:
            return {"ability_type": "MUTAGEN_ATK_BOOST_VS_AFFINITIES", "ability_params": {"bonus": int(m.group(1))}}

    # Destroy self vs divine
    if "destroy" in ab and "divine" in ab and ("reckoning" in ab or "battle" in ab):
        return {"ability_type": "DESTROY_SELF_VS_DIVINE_BOTH", "ability_params": {}}

    # Crystal gain on defend
    m = re.search(r"\+(\d+) crystal", ab)
    if m and "defend" in ab:
        return {"ability_type": "CRYSTAL_GAIN_ON_DEFEND", "ability_params": {"amount": int(m.group(1))}}

    # Reveal
    if "reveal" in ab and "foe" in ab:
        m = re.search(r"reveal (\d+)", ab)
        count = int(m.group(1)) if m else 1
        if "once" in ab:
            return {"ability_type": "TURN_END_REVEAL_OPPONENT_CELLS_ONCE", "ability_params": {"count": count}}
        return {"ability_type": "REVEAL_ON_WIN", "ability_params": {"count": count}}

    # Coin flip
    if "flip a coin" in ab or "flip 1 coin" in ab:
        if "swap position" in ab:
            return {"ability_type": "COIN_FLIP_SWAP_POSITION", "ability_params": {}}
        if "extra attack" in ab:
            return {"ability_type": "COIN_FLIP_EXTRA_ATTACK", "ability_params": {}}
        m = re.search(r"\+(\d+) atk", ab)
        if m:
            return {"ability_type": "COIN_FLIP_ATK_BOOST", "ability_params": {"amount": int(m.group(1))}}

    # Lock after attack
    if "cannot attack" in ab and "next" in ab and "successfully attacked" in ab:
        return {"ability_type": "LOCK_SELF_AFTER_ATTACK", "ability_params": {}}

    # Halve after attack
    if "halve" in ab and "attack" in ab:
        return {"ability_type": "HALVE_STATS_AFTER_ATTACK", "ability_params": {}}

    # Destroy in reckoning
    if "destroy" in ab and "reckoning" in ab:
        if "divine" in ab:
            return {"ability_type": "DESTROYED_IF_BATTLES_DIVINE", "ability_params": {}}
        return {"ability_type": "DESTROY_SELF_AFTER_BATTLE", "ability_params": {}}

    # +N ATK&DEF per typed card
    m = re.search(r"\+(\d+) atk&def for each (\w+)", ab)
    if m:
        aff = AFFINITY_WORDS.get(m.group(2).lower())
        if aff:
            scope = "all" if "field" in ab and "its side" not in ab else "owner"
            return {
                "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
                "ability_params": {"affinity": aff, "atk_bonus": int(m.group(1)), "def_bonus": int(m.group(1)), "field_scope": scope},
            }

    # +N ATK per typed card on field
    m = re.search(r"\+(\d+) atk for each (\w+)", ab)
    if m:
        aff = AFFINITY_WORDS.get(m.group(2).lower())
        if aff:
            return {
                "ability_type": "BOOST_PER_TYPED_CARD_ON_FIELD",
                "ability_params": {"affinity": aff, "atk_bonus": int(m.group(1)), "def_bonus": 0, "field_scope": "owner"},
            }

    # DEF bonus if affinity on field
    m = re.search(r"\+(\d+) def", ab)
    if m and "if" in ab and any(w in ab for w in AFFINITY_WORDS):
        for word, aff in AFFINITY_WORDS.items():
            if word in ab:
                scope = "all" if "on the field" in ab else "owner"
                return {"ability_type": "DEF_BONUS_IF_AFFINITY_ON_FIELD", "ability_params": {"affinity": aff, "bonus": int(m.group(1)), "field_scope": scope}}

    # Redirect destruction
    if "would be destroyed" in ab and "instead" in ab:
        return {"ability_type": "REDIRECT_DESTRUCTION_TO_ALLY", "ability_params": {"affinity": affinity.upper() if affinity else "DIVINE"}}

    # One use survive
    if "once" in ab and "not destroyed" in ab:
        return {"ability_type": "ONE_USE_SURVIVE_DESTRUCTION", "ability_params": {}}

    # Swap atk def when attacking
    if "switch" in ab and "atk" in ab and "def" in ab and "attack" in ab:
        return {"ability_type": "SWAP_ATK_DEF_WHEN_ATTACKING", "ability_params": {}}

    # Extra crystal loss for opponent
    if "foe loses" in ab and "more crystal" in ab:
        m = re.search(r"(\d+) more", ab)
        return {"ability_type": "OPPONENT_EXTRA_CRYSTAL_LOSS", "ability_params": {"amount": int(m.group(1)) if m else 20}}

    # Gain crystals on reveal
    if "gain" in ab and "crystal" in ab and "reveal" in ab:
        m = re.search(r"(\d+) crystal", ab)
        return {"ability_type": "CRYSTAL_GAIN_ON_OPP_REVEAL", "ability_params": {"amount": int(m.group(1)) if m else 40}}

    # Lock target on attack
    if "cannot attack" in ab and "battles this card" in ab:
        return {"ability_type": "LOCK_TARGET_ON_ATTACK", "ability_params": {}}

    # ATK bonus if union on field
    if "union" in ab and "+20" in ab:
        return {"ability_type": "ATK_DEF_BONUS_IF_UNION_ON_FIELD", "ability_params": {"atk": 20, "def": 20}}

    return None


def suggest_union(name: str, ability: str) -> dict | None:
    if name in UNION_MAPPINGS:
        return UNION_MAPPINGS[name]
    ab = normalize_ability(ability)
    if not ab or ab == "none":
        return {"ability_type": "NONE", "ability_params": {}}
    if "unaffected by trap" in ab:
        return {"ability_type": "IMMUNE_TO_TRAPS", "ability_params": {}}
    if "unaffected by tech" in ab or "cannot use tech" in ab:
        return {"ability_type": "IMMUNE_TO_TECH_CARDS", "ability_params": {}}
    if "mutagen flag" in ab and "summoned" in ab:
        return {"ability_type": "UNION_SUMMON_VENOM_ALL_FOE", "ability_params": {"mutagen": True}}
    if "venom flag" in ab and "summon" in ab:
        return {"ability_type": "UNION_SUMMON_VENOM_ALL_FOE", "ability_params": {}}
    if "not destroyed" in ab and "union" in ab:
        return {"ability_type": "IMMUNE_DESTROY_BY_NON_UNION", "ability_params": {}}
    if "revive" in ab and "summon" in ab:
        return {"ability_type": "UNION_SUMMON_REVIVE_MATCH", "ability_params": {}}
    if "summoned" in ab and "destroy" in ab and "ally" in ab:
        return {"ability_type": "UNION_SUMMON_DESTROY_OTHER_EXPOSED_ALLIES", "ability_params": {}}
    m = re.search(r"\+(\d+) atk.*vs union", ab)
    if m:
        return {"ability_type": "ATK_BONUS_VS_UNION", "ability_params": {"bonus": int(m.group(1))}}
    m = re.search(r"\+(\d+) def", ab)
    if m and "knight" in ab:
        return {"ability_type": "FIELD_ATK_BOOST_OWN_AFFINITY", "ability_params": {"def_bonus": int(m.group(1)), "name_contains": "knight"}}
    # Fallback: use character suggester patterns
    return suggest_character(name, ability, "")
