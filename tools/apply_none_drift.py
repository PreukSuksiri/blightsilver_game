#!/usr/bin/env python3
"""Apply ability mappings for cards stuck at NONE despite xlsx ability text."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from card_mapping_rules import CHARACTER_MAPPINGS, UNION_MAPPINGS  # noqa: E402

# Explicit drift fixes (merged into mapping dicts at runtime).
EXTRA_CHARACTER: dict[str, dict] = {
    "Lich Servant": {
        "ability_type": "DESTROY_SELF_VS_DIVINE_BOTH",
        "ability_params": {},
    },
    "Demon Spawn": {
        "ability_type": "DESTROY_SELF_VS_DIVINE_BOTH",
        "ability_params": {},
    },
    "Tall Shadow": {
        "ability_type": "DESTROY_SELF_VS_DIVINE_BOTH",
        "ability_params": {},
    },
    "Zealot": {
        "ability_type": "UNION_MATERIAL_ATK_DEF_BOOST",
        "ability_params": {"boost": 40},
    },
    "Crystal Rabbit": {
        "ability_type": "UNION_MATERIAL_CRYSTAL_GAIN",
        "ability_params": {"amount": 500},
    },
    "Elven Merchant": {
        "ability_type": "ADJACENT_AFFINITY_COST_HALVED",
        "ability_params": {"affinity": "NATURE"},
    },
    "Maria the Battle Priest": {
        "ability_type": "ADJACENT_FORCE_COIN_HEADS",
        "ability_params": {"face_down": True},
    },
}

EXTRA_UNION: dict[str, dict] = {
    "Diamond Unicorn": {
        "ability_type": "UNION_SUMMON_TEMP_STAT_BOOST",
        "ability_params": {"atk": 15, "def": 0, "until_turn_end": True},
    },
    "Beowolf": {
        "ability_type": "ATK_BONUS_WHEN_CAN_DESTROY",
        "ability_params": {"bonus": 25},
    },
    "Ice Hawk": {
        "ability_type": "LOCK_ATTACKER_ON_DEFEND",
        "ability_params": {},
    },
    "Ethereal Marquees": {
        "ability_type": "DEF_PENALTY_VS_NON_AFFINITY",
        "ability_params": {"affinity": "ARCANE", "def": 80, "survive_crystal_cost": 500},
    },
    "Charm Mistress": {
        "ability_type": "LIMIT_FOE_ATTACKS_COIN_FLIP_ONCE",
        "ability_params": {},
    },
    "Chronoteleporter": {
        "ability_type": "INTERCEPT_ALLY_ATTACK",
        "ability_params": {"affinity": "ARCANE", "swap_self": True},
    },
    "Death Colony": {
        "ability_type": "ATTACK_ONLY_UNION_ZONE_PATTERN",
        "ability_params": {},
    },
    "Acid Elemental": {
        "ability_type": "UNION_SUMMON_ACID_ALL_FOE",
        "ability_params": {"def_debuff": 10},
    },
    "Magnet Elemental": {
        "ability_type": "TAUNT_NON_ARCANE",
        "ability_params": {},
    },
    "Dwarven Berserker": {
        "ability_type": "MULTI_ATTACK_ANY",
        "ability_params": {"max_attacks": 2},
    },
    "Dark Invader": {
        "ability_type": "ATK_DEF_BONUS_IF_OWN_REVEALED_GTE",
        "ability_params": {"per_revealed": True, "atk": 5, "def": 5},
    },
    "Europan Warcraft": {
        "ability_type": "REDIRECT_DESTRUCTION_TO_ALLY",
        "ability_params": {"flag": "Europa", "any_ally": True},
    },
    "Perseus the Lightborn": {
        "ability_type": "UNION_SUMMON_DESTROY_FIELD",
        "ability_params": {"count": 1, "no_destroy_cost": True},
    },
    "Illuminatus": {
        "ability_type": "UNION_SUMMON_TEMP_STAT_BOOST",
        "ability_params": {"atk": 35, "def": 35, "until_foe_turn_end": True},
    },
    "Eldritch Warlock": {
        "ability_type": "NULLIFY_FOE_ABILITY_IN_RECKONING",
        "ability_params": {"permanent": True},
    },
    "Devilshifter": {
        "ability_type": "REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION",
        "ability_params": {"turn_end": True, "affinity_on_revive": "ANIMA"},
    },
    "Embodiment of Destiny": {
        "ability_type": "ATK_BONUS_UNION_ZONE_PATTERN",
        "ability_params": {"bonus": 60},
    },
    "Atomic Tank": {
        "ability_type": "POST_ATTACK_DESTROY_FIELD_ONCE",
        "ability_params": {"count": 1},
    },
    "Battle Maid Ayumi": {
        "ability_type": "UNION_ZONE_ALLY_DEF_AURA",
        "ability_params": {"def": 50},
    },
    "Blood Moon Mage": {
        "ability_type": "UNION_SUMMON_AVERAGE_CRYSTALS",
        "ability_params": {},
    },
    "Priestess of the Moon": {
        "ability_type": "UNION_SUMMON_CRYSTAL_GAIN",
        "ability_params": {"per_exposed_divine": 300},
    },
    "Moon Shifter": {
        "ability_type": "AVERAGE_FOE_STATS_IN_RECKONING",
        "ability_params": {"until_turn_end": True},
    },
    "Nanomites Rafflesia": {
        "ability_type": "UNION_SUMMON_CRYSTAL_GAIN",
        "ability_params": {"amount": 2000},
    },
    "Supreme Lich": {
        "ability_type": "ATK_DEF_BONUS_IF_OWN_REVEALED_GTE",
        "ability_params": {"per_revealed": True, "atk": 10, "def": 10},
    },
    "The Last Paladin": {
        "ability_type": "ATK_DEF_BONUS_IF_OWN_REVEALED_GTE",
        "ability_params": {"min_revealed": 15, "atk": 150, "def": 150},
    },
    "Raijin Fujin and Suijin": {
        "ability_type": "TURN_START_DESTROY_OR_LOSE_CRYSTALS",
        "ability_params": {"crystal_loss": 500},
    },
    "Raijin Fujin and Suigin": {
        "ability_type": "UNION_SUMMON_DESTROY_UNITS",
        "ability_params": {"both_players": True, "count": 3, "no_destroy_cost": True},
    },
    "Death Parasite": {
        "ability_type": "BOOST_PER_FIELD_UNIT",
        "ability_params": {"atk": 15, "def": 15, "field_scope": "all", "def_penalty_vs_affinity": "COSMIC", "def_penalty": 50},
    },
}


def main() -> int:
    import json

    char_map = {**CHARACTER_MAPPINGS, **EXTRA_CHARACTER}
    union_map = {**UNION_MAPPINGS, **EXTRA_UNION}

    out = {
        "characters": {k: char_map[k] for k in EXTRA_CHARACTER},
        "traps": {},
        "tech": {},
        "unions": {k: union_map[k] for k in EXTRA_UNION},
    }
    OUT = ROOT / "data" / "card_ability_mappings.json"
    OUT.write_text(json.dumps(out, indent="\t") + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(out['characters'])} chars, {len(out['unions'])} unions)")

    proc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "apply_ability_mappings.py"), "--force"],
        cwd=str(ROOT),
    )
    return proc.returncode


if __name__ == "__main__":
    raise SystemExit(main())
