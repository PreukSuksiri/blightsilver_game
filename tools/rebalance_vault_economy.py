#!/usr/bin/env python3
"""Rebalance AI Deck Vault economy by tier. Run from repo root.

Balancing reference: context/AI_DECK_VAULT_BALANCING_PLAYBOOK.md
"""
import json
import re
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VAULT_PATH = ROOT / "data" / "ai_deck_vault.json"

TAG_BY_ID: dict[str, str] = {
    # Easy ×15
    "easy_kitsune": "easy",
    "easy_pixie_queen": "easy",
    "easy_diamond_unicorn": "easy",
    "easy_gamma": "easy",
    "easy_skeleton": "easy",
    "easy_ten_arms": "easy",
    "easy_rebel_king": "easy",
    "easy_sky_protector": "easy",
    "normal_vergaia": "easy",
    "norm_miner_moon": "easy",
    "norm_greater_succubus": "easy",
    "easy_lab_mutagen": "easy",
    "norm_choir_lead": "easy",
    "norm_xdeath": "easy",
    "norm_grand_fort_captain": "easy",
    # Normal ×15
    "norm_volatile_slasher": "normal",
    "easy_pure_moon": "normal",
    "easy_false_prophet_casino": "normal",
    "easy_moon_lady_ninja": "normal",
    "easy_wk17_roulette": "normal",
    "easy_kiba": "normal",
    "easy_vampire": "normal",
    "hard_venom": "normal",
    "new_ai_deck_19": "normal",
    "norm_thunder_elemental": "normal",
    "norm_legendary_locksmith": "normal",
    "norm_leorudus": "normal",
    "norm_raijin_fujin": "normal",
    "norm_shark": "normal",
    "normal_chaos_bio": "normal",
    # Hard ×15
    "norm_phoenix": "hard",
    "norm_colormage_flayer": "hard",
    "hard_barros": "hard",
    "hard_team_galaxos": "hard",
    "hard_dimensional_virus": "hard",
    "hard_full_emental": "hard",
    "hard_gaia_arcane": "hard",
    "hard_gryphon": "hard",
    "hard_helios": "hard",
    "hard_lord_of_terror": "hard",
    "hard_rocket_peacock": "hard",
    "hard_seraphim_fistmaster": "hard",
    "hard_zealot_kiba": "hard",
    "norm_armored": "hard",
    "norm_wood_elemental": "hard",
}


def normalize_tags(vault: dict) -> None:
    for entry in vault["entries"]:
        eid = entry.get("id", "")
        if eid in TAG_BY_ID:
            entry["tags"] = [TAG_BY_ID[eid]]


HARD_TECH = ["Spy", "Tease", "Radar"]
HARD_TECH_DIVINE = ["Prayer", "Spy", "Radar"]
HARD_TECH_BIO = ["Release Mutagen", "Spy", "Radar"]
NORM_TECH = ["Spy", "Bribe", "Radar"]
NORM_TECH_MID = ["Spy", "Radar", "Tease"]
EASY_TECH_LIGHT = ["Spy", "Tease", "Radar"]
EASY_TECH_FIX = ["Spy", "Bribe", "Tease"]  # max 0 cost burn

# deck_id -> {characters?, techs?, char_map? for formation renames}
PATCHES: dict[str, dict] = {
    # ── HARD (strict) ─────────────────────────────────────────
    "hard_gaia_arcane": {
        "characters": [
            "Angel Gatekeeper",
            "Archbishop",
            "Armored Rhino",
            "Lazy Troll",
            "Church Guard",
            "Nuki the Tanuki",
            "Mad Raccoon",
            "Goblin Poacher",
            "Needle Porcupine",
            "Flame Lizard",
        ],
        "techs": HARD_TECH,
        "char_map": {
            "Aerial the Battlemage": "Armored Rhino",
            "Book with Fangs": "Church Guard",
            "Ice Mage": "Nuki the Tanuki",
            "Mind Flayer": "Mad Raccoon",
            "Pyromancer": "Goblin Poacher",
            "War Genie": "Needle Porcupine",
            "Goddess of Virtue": "Lazy Troll",
            "Pit Lord": "Flame Lizard",
        },
    },
    "hard_seraphim_fistmaster": {
        "characters": [
            "Flame Seraph",
            "Sonic Seraph",
            "Archbishop",
            "Angel Gatekeeper",
            "Goddess of Virtue",
            "Joseph the Battle Priest",
            "Joan the Faithful Warrior",
            "Church Guard",
            "Tiny Pixie",
            "Bomber Fairy",
        ],
        "techs": HARD_TECH_DIVINE,
        "char_map": {
            "Mephisto the Fallen": "Church Guard",
            "Heavy Tome Preacher": "Bomber Fairy",
            "Melissa the Healer": "Tiny Pixie",
            "Padmapani": "Joseph the Battle Priest",
        },
    },
    "hard_lord_of_terror": {
        "characters": [
            "Pit Lord",
            "Immortal Vampire",
            "Death Knight",
            "Vampire Duchess",
            "Night Whisperer",
            "Dark Monk",
            "Jacob the Ski Mask",
            "Skeleton Scout",
            "Chaotic Wisp",
            "Bat Swarm",
        ],
        "techs": HARD_TECH,
        "char_map": {
            "Succubus": "Chaotic Wisp",
            "Araya the Eerie Dancer": "Skeleton Scout",
            "Magenta the Nightbloom": "Bat Swarm",
            "Poltergeist": "Dark Monk",
        },
    },
    "hard_rocket_peacock": {
        "characters": [
            "Ostrich Cannon",
            "Lazy Troll",
            "Death Cobra",
            "Armored Rhino",
            "Canyon Warg",
            "Nuki the Tanuki",
            "Mad Raccoon",
            "Goblin Poacher",
            "Needle Porcupine",
            "Flame Lizard",
        ],
        "techs": HARD_TECH,
        "char_map": {
            "Giant Centipede": "Flame Lizard",
            "Shotgun Shark": "Goblin Poacher",
            "Swarmcaller": "Needle Porcupine",
            "Venom Queen": "Armored Rhino",
            "Venom Toad": "Nuki the Tanuki",
            "Vicious Lizard": "Mad Raccoon",
        },
    },
    "hard_barros": {
        "characters": [
            "Lazy Troll",
            "Ostrich Cannon",
            "Death Cobra",
            "Armored Rhino",
            "Canyon Warg",
            "Nuki the Tanuki",
            "Mad Raccoon",
            "Goblin Poacher",
            "Needle Porcupine",
            "Flame Lizard",
        ],
        "techs": HARD_TECH,
        "char_map": {
            "Giant Centipede": "Armored Rhino",
            "Mad Raccoon": "Mad Raccoon",
        },
    },
    "hard_dimensional_virus": {
        "characters": [
            "Lab Bloater",
            "Lab Crawler",
            "Claw Mutant",
            "Lab Zombie",
            "Pyromancer",
            "Book with Fangs",
            "Red Mage",
            "Green Mage",
            "Blue Mage",
            "Gamma Emitter",
        ],
        "techs": HARD_TECH_BIO,
        "char_map": {
            "Mind Flayer": "Book with Fangs",
            "Bladeshifter": "Claw Mutant",
            "Scarlet Mutant": "Gamma Emitter",
            "Black Worms": "Red Mage",
        },
    },
    "hard_full_emental": {
        "characters": [
            "Fire Elemental",
            "Earth Elemental",
            "Water Elemental",
            "Wind Elemental",
            "Red Mage",
            "Green Mage",
            "Blue Mage",
            "Pyromancer",
            "Spell Sniper",
            "Book with Fangs",
        ],
        "techs": HARD_TECH,
        "char_map": {
            "Elemental Master": "Spell Sniper",
            "Aerial the Battlemage": "Book with Fangs",
        },
    },
    "hard_gryphon": {
        "characters": [
            "Gryphon",
            "Flame Seraph",
            "Church Guard",
            "Tiny Pixie",
            "Joseph the Battle Priest",
            "Joan the Faithful Warrior",
            "Bomber Fairy",
            "Sniping Fairy",
            "Ponycorn",
            "Angel Gatekeeper",
        ],
        "techs": HARD_TECH_DIVINE,
        "char_map": {
            "Mephisto the Fallen": "Angel Gatekeeper",
            "Melissa the Healer": "Sniping Fairy",
            "Padmapani": "Bomber Fairy",
            "Heavy Tome Preacher": "Ponycorn",
            "Sonic Seraph": "Flame Seraph",
        },
    },
    "hard_helios": {
        "characters": [
            "Space Boy",
            "Satellite Cannon",
            "Echo Bringer",
            "Scout Probe",
            "Mars Drill",
            "Methanomancer",
            "Moon Rover",
            "Miner Probe",
            "Striker Comet",
            "Laser Walker",
        ],
        "techs": HARD_TECH,
        "char_map": {
            "Nimrod the Wonder Seeker": "Scout Probe",
            "Parom the Smuggler": "Mars Drill",
            "Moon Tribe Marksman": "Miner Probe",
            "Moon Tribe Twin Blader": "Striker Comet",
        },
    },
    "hard_team_galaxos": {
        "characters": [
            "Space Boy",
            "Echo Bringer",
            "Satellite Cannon",
            "Scout Probe",
            "Miner Probe",
            "Mars Drill",
            "Zealot",
            "Huntress of Green Glade",
            "Mafia Associates",
            "Wandering Swordsman",
        ],
        "techs": HARD_TECH,
        "char_map": {
            "Electrogazer": "Echo Bringer",
            "Nimrod the Wonder Seeker": "Scout Probe",
            "Tomb Bandit": "Zealot",
        },
    },
    "hard_zealot_kiba": {
        "characters": [
            "Kiyoko the Death Whisper",
            "Silver Spearman",
            "Zealot",
            "Grand Fort Archer",
            "Grand Fort Footsoldier",
            "Tomb Bandit",
            "Ox Patrol",
            "Hairpin Assassin",
            "Lockpicker",
            "Street Rogue",
        ],
        "techs": HARD_TECH,
        "char_map": {
            "Wandering Swordsman": "Hairpin Assassin",
            "Uproaring Warband": "Lockpicker",
            "Shepherd Detective": "Street Rogue",
            "Leopard Jailer": "Ox Patrol",
            "Leorudus the Warlord": "Tomb Bandit",
        },
    },
    "norm_armored": {
        "techs": HARD_TECH,
    },
    "norm_wood_elemental": {
        "characters": [
            "Water Elemental",
            "Earth Elemental",
            "Fire Elemental",
            "Wind Elemental",
            "Red Mage",
            "Green Mage",
            "Blue Mage",
            "Pyromancer",
            "Spell Sniper",
            "Book with Fangs",
        ],
        "techs": HARD_TECH,
        "char_map": {
            "Aerial the Battlemage": "Spell Sniper",
            "Elemental Master": "Book with Fangs",
            "Ice Mage": "Green Mage",
            "Mind Flayer": "Blue Mage",
        },
    },
    "easy_false_prophet_casino": {
        "characters": [
            "False Prophet",
            "Church Guard",
            "Archbishop",
            "Joseph the Battle Priest",
            "Joan the Faithful Warrior",
            "Tiny Pixie",
            "Bomber Fairy",
            "Sniping Fairy",
            "Ponycorn",
            "Melissa the Healer",
        ],
        "techs": HARD_TECH_DIVINE,
        "char_map": {
            "Padmapani": "Melissa the Healer",
        },
    },
    "easy_wk17_roulette": {
        "characters": [
            "WK-17 the Siren",
            "Claw Mutant",
            "Lab Zombie",
            "Lab Bloater",
            "Lab Crawler",
            "Bladeshifter",
            "Plant-29",
            "Rotten Shrieker",
            "Gamma Emitter",
            "Waste Slime",
        ],
        "techs": HARD_TECH_BIO,
        "char_map": {
            "Mind Flayer": "Gamma Emitter",
            "Nanomites Beast": "Waste Slime",
            "Dystopian Cultist": "Rotten Shrieker",
            "Bleacher Squad": "Plant-29",
            "Black Worms": "Bladeshifter",
        },
    },
    # ── NORMAL (mild) ─────────────────────────────────────────
    "normal_chaos_bio": {
        "characters": [
            "Pit Lord",
            "Death Knight",
            "Vampire Duchess",
            "Immortal Vampire",
            "Claw Mutant",
            "Lab Crawler",
            "Lab Zombie",
            "Leech Man",
            "Night Whisperer",
            "Dark Monk",
            "Bat Swarm",
            "Skeleton Scout",
        ],
        "techs": ["Release Mutagen", "Spy", "Radar"],
        "char_map": {
            "Vampire Servant": "Skeleton Scout",
            "Succubus": "Bat Swarm",
            "Bladeshifter": "Dark Monk",
            "Void Stalker": "Night Whisperer",
            "Poltergeist": "Leech Man",
        },
    },
    "norm_colormage_flayer": {
        "characters": [
            "Red Mage",
            "Green Mage",
            "Blue Mage",
            "Pyromancer",
            "Fire Elemental",
            "Earth Elemental",
            "Spell Sniper",
            "Book with Fangs",
            "War Genie",
            "Aerial the Battlemage",
        ],
        "techs": NORM_TECH,
        "char_map": {
            "Mind Flayer": "Book with Fangs",
            "Ice Mage": "Spell Sniper",
        },
    },
    "norm_leorudus": {
        "techs": NORM_TECH,
        "char_swap": {
            "Kiyoko the Death Whisper": "Tomb Bandit",
            "Huntress of Green Glade": "Ox Patrol",
        },
    },
    "norm_shark": {
        "techs": NORM_TECH,
        "char_swap": {
            "Swarmcaller": "Mad Raccoon",
        },
    },
    "norm_xdeath": {
        "techs": NORM_TECH,
        "char_swap": {
            "Kiyoko the Death Whisper": "Tomb Bandit",
            "Huntress of Green Glade": "Street Rogue",
            "Tomb Bandit": "Grand Fort Footsoldier",
            "Leorudus the Warlord": "Grand Fort Archer",
        },
    },
    "norm_phoenix": {
        "techs": NORM_TECH_MID,
        "char_swap": {
            "Aerial the Battlemage": "Spell Sniper",
            "Book with Fangs": "Red Mage",
        },
    },
    "norm_raijin_fujin": {
        "techs": NORM_TECH_MID,
        "char_swap": {
            "Mephisto the Fallen": "Church Guard",
            "Melissa the Healer": "Tiny Pixie",
        },
    },
    "norm_grand_fort_captain": {
        "techs": NORM_TECH_MID,
        "char_swap": {
            "Huntress of Green Glade": "Tomb Bandit",
            "Leorudus the Warlord": "Ox Patrol",
            "Tomb Bandit": "Street Rogue",
        },
    },
    "hard_venom": {
        "techs": ["Potent Poison", "Radar", "Tease"],
        "char_swap": {
            "Vicious Lizard": "Flame Lizard",
            "Giant Centipede": "Stinky Insect",
        },
    },
    "easy_kiba": {
        "techs": NORM_TECH_MID,
    },
    "easy_lab_mutagen": {
        "techs": HARD_TECH_BIO,
    },
    "easy_vampire": {
        "techs": NORM_TECH_MID,
        "char_swap": {
            "Araya the Eerie Dancer": "Skeleton Scout",
        },
    },
    "new_ai_deck_19": {
        "techs": NORM_TECH_MID,
    },
    "norm_volatile_slasher": {
        "techs": HARD_TECH_BIO,
        "char_swap": {
            "Lab Zombie": "Waste Slime",
        },
    },
    "norm_choir_lead": {
        "techs": EASY_TECH_LIGHT,
        "char_swap": {
            "Melissa the Healer": "Padmapani",
            "Archbishop": "Joseph the Battle Priest",
            "Tomb Bandit": "Joan the Faithful Warrior",
        },
    },
    # ── EASY (light touch) ────────────────────────────────────
    "easy_kitsune": {
        "techs": EASY_TECH_LIGHT,
    },
    "easy_pixie_queen": {
        "techs": HARD_TECH_DIVINE,
    },
    "easy_diamond_unicorn": {
        "techs": HARD_TECH_DIVINE,
    },
    "easy_ten_arms": {
        "techs": EASY_TECH_FIX,
    },
    "easy_skeleton": {
        "techs": EASY_TECH_FIX,
    },
    "norm_greater_succubus": {
        "techs": EASY_TECH_LIGHT,
    },
    "normal_vergaia": {
        "techs": EASY_TECH_LIGHT,
    },
    "easy_pure_moon": {
        "techs": NORM_TECH_MID,
    },
    "easy_sky_protector": {
        "techs": NORM_TECH_MID,
    },
    "easy_moon_lady_ninja": {
        "techs": NORM_TECH_MID,
    },
    "easy_rebel_king": {
        "techs": NORM_TECH_MID,
    },
}


def load_card_data():
    cdb = (ROOT / "autoload/CardDatabase.gd").read_text()
    demo = {
        k
        for k, v in json.loads((ROOT / "data/demo_flags.json").read_text()).items()
        if v
    }
    chars = {}
    for m in re.finditer(
        r'\[\s*"([^"]+)"\s*,\s*CharacterData\.Affinity\.(\w+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)',
        cdb,
    ):
        name = m.group(1)
        if name not in demo:
            continue
        chars[name] = {
            "cost": int(m.group(5)),
            "eff": (int(m.group(3)) + int(m.group(4))) / max(int(m.group(5)), 1),
        }
    techs = {
        m.group(1): int(m.group(2))
        for m in re.finditer(r'\[\s*"([^"]+)"\s*,\s*(\d+)\s*,\s*TechCardData', cdb)
    }
    return chars, techs, demo


def apply_char_swaps(roster: list[str], swaps: dict[str, str]) -> list[str]:
    out: list[str] = []
    for c in roster:
        out.append(swaps.get(c, c))
    # Resolve duplicates introduced by swaps: replace dupes with cheap alternates.
    seen: set[str] = set()
    deduped: list[str] = []
    fallbacks = [
        "Tomb Bandit",
        "Ox Patrol",
        "Street Rogue",
        "Mafia Associates",
        "Mad Raccoon",
        "Goblin Poacher",
        "Skeleton Scout",
        "Padmapani",
    ]
    fb_i = 0
    for c in out:
        if c not in seen:
            seen.add(c)
            deduped.append(c)
            continue
        while fb_i < len(fallbacks) and fallbacks[fb_i] in seen:
            fb_i += 1
        repl = fallbacks[fb_i] if fb_i < len(fallbacks) else c
        fb_i += 1
        if repl not in seen:
            seen.add(repl)
            deduped.append(repl)
    return deduped


def sync_formations(entry: dict, char_map: dict[str, str]) -> None:
    roster = entry["deck"]["characters"]
    traps = entry["deck"]["traps"]
    roster_set = list(roster)
    used_chars: set[str] = set()

    for placement in entry["deck"]["formations"][0]["placements"]:
        ptype = placement.get("type", "")
        name = placement.get("name", "")
        if ptype == "character":
            if name in char_map:
                name = char_map[name]
            if name not in roster or name in used_chars:
                for candidate in roster_set:
                    if candidate not in used_chars:
                        name = candidate
                        break
            used_chars.add(name)
            placement["name"] = name
        elif ptype == "trap" and name not in traps:
            for t in traps:
                placement["name"] = t
                break


def dedupe_roster(roster: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for c in roster:
        if c in seen:
            continue
        seen.add(c)
        out.append(c)
    return out


def fix_non_demo_cards(deck: dict, demo: set[str]) -> None:
    swaps = {
        "Death Stag": "Canyon Warg",
        "Mana Drain": "Hypnosis",
        "Garrison": "War Supply",
        "Harsh Training": "Tease",
        "Illegal Steroid": "Potent Poison",
        "Ancient Lich": "Night Whisperer",
    }
    for key in ("characters", "traps", "techs"):
        deck[key] = [swaps.get(c, c) for c in deck[key]]
        deck[key] = dedupe_roster(deck[key])
    for p in deck["formations"][0]["placements"]:
        n = p.get("name", "")
        if n in swaps:
            p["name"] = swaps[n]


def restore_missing_decks(vault: dict) -> list[str]:
    """Re-add union / tier-pool decks if absent (safe after accidental git checkout)."""
    existing = {e["id"] for e in vault["entries"]}
    added = []
    recovered = ROOT / "trash" / "recovered_union_script.py"
    if not recovered.exists():
        return added
    text = recovered.read_text()
    start = text.index("def deck_entry")
    end = text.index("\nvault[\"entries\"]", start)
    local: dict = {}
    exec(text[start:end], {}, local)  # noqa: S102
    for entry in local["new_entries"]:
        eid = entry["id"]
        if eid in existing:
            continue
        fix_non_demo_cards(entry["deck"], set())
        vault["entries"].append(entry)
        added.append(eid)
    vault["entries"].sort(key=lambda e: e["id"])
    return added


def apply_patches(vault: dict) -> list[str]:
    logs = []
    for entry in vault["entries"]:
        eid = entry.get("id", "")
        if eid not in PATCHES:
            continue
        patch = PATCHES[eid]
        deck = entry["deck"]
        char_map = dict(patch.get("char_map", {}))

        if "characters" in patch:
            deck["characters"] = list(patch["characters"])
        if "char_swap" in patch:
            deck["characters"] = apply_char_swaps(deck["characters"], patch["char_swap"])
            for old, new in patch["char_swap"].items():
                char_map.setdefault(old, new)

        if "techs" in patch:
            deck["techs"] = list(patch["techs"])

        sync_formations(entry, char_map)
        logs.append(eid)
    return logs


def validate(vault: dict, chars: dict, techs: dict, demo: set[str]) -> list[str]:
    from collections import Counter

    issues = []
    demo_effs = sorted(chars[n]["eff"] for n in chars)
    filler_cut = demo_effs[int(len(demo_effs) * 0.35)]

    for entry in vault["entries"]:
        eid = entry["id"]
        deck = entry["deck"]
        for key in ("characters", "traps", "techs"):
            dups = [k for k, v in Counter(deck[key]).items() if v > 1]
            if dups:
                issues.append(f"{eid}: duplicate {key}: {dups}")
            for c in deck[key]:
                if c not in demo:
                    issues.append(f"{eid}: non-demo {key}: {c}")

        tag = str((entry.get("tags") or ["?"])[0]).lower()
        costs = [chars[c]["cost"] for c in deck["characters"] if c in chars]
        if not costs:
            continue
        avg = statistics.mean(costs)
        cheap = sum(1 for c in costs if c <= 400)
        exp_fill = [
            c
            for c in deck["characters"]
            if c in chars
            and chars[c]["eff"] <= filler_cut
            and chars[c]["cost"] >= 600
            and chars[c]["cost"] < 700
        ]
        tsum = sum(techs.get(t, 0) for t in deck["techs"])

        if tag == "hard":
            if avg > 720:
                issues.append(f"{eid}: hard avg {avg:.0f} > 720")
            if cheap < 2:
                issues.append(f"{eid}: hard cheap {cheap} < 2")
            if exp_fill:
                issues.append(f"{eid}: hard expensive fillers: {exp_fill}")
            if tsum > 1600:
                issues.append(f"{eid}: hard tech sum {tsum} > 1600")
        elif tag in ("normal", "norm"):
            if tsum > 2200:
                issues.append(f"{eid}: normal tech sum {tsum} > 2200")
            if exp_fill and len(exp_fill) >= 3:
                issues.append(f"{eid}: normal many expensive fillers: {exp_fill}")
        elif tag == "easy":
            if tsum > 2000:
                issues.append(f"{eid}: easy tech sum {tsum} > 2000")

        placed = {p["name"] for p in deck["formations"][0]["placements"] if p["type"] == "character"}
        for p in placed:
            if p not in deck["characters"]:
                issues.append(f"{eid}: formation char not in roster: {p}")

    return issues


def main() -> int:
    vault = json.loads(VAULT_PATH.read_text())
    chars, techs, demo = load_card_data()
    restored = restore_missing_decks(vault)
    for entry in vault["entries"]:
        fix_non_demo_cards(entry["deck"], demo)
    normalize_tags(vault)
    applied = apply_patches(vault)
    issues = validate(vault, chars, techs, demo)
    VAULT_PATH.write_text(json.dumps(vault, indent="\t", ensure_ascii=False) + "\n")
    if restored:
        print(f"Restored {len(restored)} missing decks: {', '.join(restored)}")
    print(f"Applied patches to {len(applied)} decks:")
    for eid in applied:
        print(f"  - {eid}")
    if issues:
        print(f"\nValidation issues ({len(issues)}):")
        for i in issues:
            print(f"  ! {i}")
        return 1
    print("\nValidation OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
