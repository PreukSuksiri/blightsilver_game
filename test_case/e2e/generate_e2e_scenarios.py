#!/usr/bin/env python3
"""
Generate card-by-card AI vs AI E2E scenarios for all Demo=Yes cards.

Tier 1 (-001): smoke — full battle completes, card appears in log.
Tier 2 (-002): ability — forced setup + log regex / MSG assertions.

Output: test_case/e2e/scenarios.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

E2E_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(E2E_DIR))

from card_db import demo_cards_merged  # noqa: E402
from tier2_builder import build_tier2, slug  # noqa: E402

OUT = E2E_DIR / "scenarios.json"

# Re-use tier1 helpers (inline to avoid circular imports)
FILLER_CHARS = [
    "Chaotic Wisp", "Foul Wisp", "Doom Wisp", "Church Guard", "Big Thug",
    "Dark Monk", "Goblin Poacher", "Mad Raccoon", "Ox Patrol", "Wandering Swordsman",
    "Skeleton Lancer", "Shredder Doll", "Ponycorn", "Ice Mage", "Grand Fort Footsoldier",
]
FILLER_TRAPS = ["Trap Hole", "Hypnosis", "Spike Trap", "Snare Trap", "Flame Trap"]
FILLER_TECH = ["Radar", "Spy", "Bribe"]
WEAK_DEFENDER = "Chaotic Wisp"
ATTACKER_CELL = {"row": 2, "col": 2}
DEFENDER_CELL = {"row": 2, "col": 2}


def build_char_deck(target: str | None = None) -> dict:
    # target is excluded from the deck — it is placed exclusively via forced_cells.
    # Including it in chars would cause the engine to place a second copy on the board.
    chars: list[str] = [c for c in FILLER_CHARS if c != target][:12]
    return {
        "deck_name": "E2E T1 Character Deck",
        "characters": chars,
        "traps": FILLER_TRAPS[:5],
        "techs": FILLER_TECH[:3],
    }


def build_trap_deck(target: str) -> dict:
    # target excluded from deck traps — it is placed exclusively via forced_cells.
    traps = [t for t in FILLER_TRAPS if t != target][:5]
    deck = build_char_deck()
    deck["deck_name"] = "E2E T1 Trap Deck"
    deck["traps"] = traps
    return deck


def build_tech_deck(target: str) -> dict:
    techs = [target] + [t for t in FILLER_TECH if t != target]
    # Ox Patrol is force-placed at (2,1); exclude it from deck chars to prevent duplicates.
    deck = build_char_deck("Ox Patrol")
    deck["deck_name"] = "E2E T1 Tech Deck"
    deck["techs"] = techs[:3]
    while len(deck["techs"]) < 3:
        deck["techs"].append(FILLER_TECH[len(deck["techs"]) % len(FILLER_TECH)])
    return deck


def build_union_deck(materials: list[str]) -> dict:
    chars: list[str] = []
    seen: set[str] = set()
    for m in materials:
        if m and m not in seen:
            chars.append(m)
            seen.add(m)
    for c in FILLER_CHARS:
        if len(chars) >= 10:
            break
        if c not in seen:
            chars.append(c)
            seen.add(c)
    while len(chars) < 8:
        c = FILLER_CHARS[len(chars) % len(FILLER_CHARS)]
        if c not in seen:
            chars.append(c)
            seen.add(c)
    return {
        "deck_name": "E2E T1 Union Deck",
        "characters": chars[:12],
        "traps": FILLER_TRAPS[:4],
        "techs": FILLER_TECH[:3],
    }


def extract_union_materials(formula: str) -> list[str]:
    import re
    if not formula:
        return []
    known = [
        "Gryphon", "Tiny Pixie", "Ponycorn", "Cleaver Saint", "Cruel Angel",
        "Choir Lady Abigail", "Choir Lady Alice", "Choir Lady Anna",
        "Moon Lady Ninja", "Moon Tribe Shaman", "Colorful Mage",
        "Imperial Mech", "Jirayu the Rebel King",
        "Kiba the Giant Slayer",
        "Raijin", "Fujin", "Flame Lizard", "Hammer Shark", "Saw Shark",
        "Laser Walker", "Dark Monk", "Grand Fort Footsoldier",
        "Skeleton Archer", "Skeleton Lancer", "Skeleton Scout",
    ]
    found: list[str] = []
    lower = formula.lower()
    for name in known:
        if name.lower() in lower or name.split()[0].lower() in lower:
            found.append(name)
    if "choir lady" in lower and not any("Choir Lady" in f for f in found):
        found.extend(["Choir Lady Abigail", "Choir Lady Alice", "Choir Lady Anna"])
    return found[:4]


# Explicit deck character lists for T2 union scenarios where auto-extraction
# produces wrong or empty materials (wrong affinity, missing named cards, etc.).
# The deck must have enough correctly-typed cards so the union zone condition
# can be satisfied by random placement.
UNION_T2_DECK_CHARS: dict[str, list[str]] = {
    # needs card_name="Flame Lizard" + 1 Nature
    "Ancient Lizard": [
        "Flame Lizard", "Goblin Poacher", "Mad Raccoon", "Canyon Warg",
        "Armored Bee", "Armored Monkey", "Hammer Shark", "Saw Shark",
    ],
    # needs 2 Nature cards
    "Berserk Hyena": [
        "Flame Lizard", "Goblin Poacher", "Mad Raccoon", "Canyon Warg",
        "Armored Bee", "Armored Monkey", "Hammer Shark", "Saw Shark",
    ],
    # needs 2 Nature cards with cost >= 800
    "Barros the Colossal": [
        "Gryphon", "Death Cobra", "Shotgun Shark", "Swarmcaller",
        "Lazy Troll", "Ostrich Cannon", "Giant Centipede", "Canyon Warg",
    ],
    # needs 2 units with DEF >= 90
    "Gaia Turtle": [
        "Angel Gatekeeper", "Archbishop", "Fierce Gladiator",
        "Ironclad Sentinel", "Railgun Tank", "Church Guard", "Big Thug", "Dark Monk",
    ],
    # needs 2 characters with name_contains "grand fort"
    "Grand Fort Captain": [
        "Grand Fort Footsoldier", "Grand Fort Archer", "Grand Fort Mauler",
        "Church Guard", "Big Thug", "Dark Monk", "Goblin Poacher", "Ox Patrol",
    ],
    # needs card_name="Laser Walker" + 1 Cosmic
    "Imperial Frame": [
        "Laser Walker", "Moon Rover", "Church Guard", "Big Thug",
        "Dark Monk", "Goblin Poacher", "Mad Raccoon", "Ox Patrol",
    ],
    # needs 3 characters with name_contains "shark"
    "Katana Shark": [
        "Hammer Shark", "Saw Shark", "Shotgun Shark", "Scythe Shark",
        "Spear Shark", "Church Guard", "Big Thug", "Dark Monk",
    ],
    # needs card_name="Dark Monk" + 1 Chaos
    "Kitsune": [
        "Dark Monk", "Chaotic Wisp", "Foul Wisp", "Doom Wisp",
        "Church Guard", "Big Thug", "Goblin Poacher", "Ox Patrol",
    ],
    # needs 1 Bio (cost>=800) + 1 Anima (cost>=800)
    "Rocket Marauder": [
        "Lab Bloater", "Leech Man", "Plant 29",
        "Huntress of Green Glade", "Kiyoko the Death Whisper", "Fierce Gladiator",
        "Church Guard", "Big Thug",
    ],
    # needs 3 characters with name_contains "skeleton"
    "Skeleton Overlord": [
        "Skeleton Archer", "Skeleton Lancer", "Skeleton Scout", "Skeleton Grappler",
        "Church Guard", "Big Thug", "Dark Monk", "Goblin Poacher",
    ],
    # needs name_contains "gryphon" + 1 Divine — Gryphon + Church Guards works;
    # also add Angel Gatekeeper to ensure enough Divine cards hit the diagonal zone
    "Gryphon Rider": [
        "Gryphon", "Church Guard", "Angel Gatekeeper", "Ponycorn",
        "Archbishop", "Big Thug", "Dark Monk", "Goblin Poacher",
    ],
    # needs name_contains "raijin" + name_contains "fujin"
    "Raijin and Fujin": [
        "Raijin", "Fujin", "Church Guard", "Big Thug",
        "Dark Monk", "Goblin Poacher", "Mad Raccoon", "Ox Patrol",
    ],
}

# Custom forced_cells_0 for unions where zone positioning is critical.
# Without explicit placement, the required cards may not land in valid zone cells.
UNION_T2_FORCED_CELLS_0: dict[str, list[dict]] = {
    # Grand Fort Captain zone (5 cells): force 2 "grand fort" characters into the zone
    "Grand Fort Captain": [
        {"card_name": "Grand Fort Footsoldier", "row": 0, "col": 0},
        {"card_name": "Grand Fort Archer", "row": 0, "col": 1},
    ],
    # Gryphon Rider zone: diagonal [[0,0],[1,1],[2,2],[3,3],[4,4]].
    # Force Gryphon at (0,0) and a Divine card at (1,1) to guarantee zone match.
    "Gryphon Rider": [
        {"card_name": "Gryphon", "row": 0, "col": 0},
        {"card_name": "Church Guard", "row": 1, "col": 1},
    ],
    # Raijin and Fujin zone: columns 0 and 4 of every row.
    # (0,1) is NOT in the zone — must use (0,0) and (0,4).
    "Raijin and Fujin": [
        {"card_name": "Raijin", "row": 0, "col": 0},
        {"card_name": "Fujin", "row": 0, "col": 4},
    ],
}


def scenario_tier1(db: dict, formula: str = "") -> dict:
    name = db["name"]
    ctype = db["card_type"]
    sid = slug(name)
    base = {
        "tier": 1,
        "id": f"E2E-{sid}-001",
        "card_name": name,
        "card_type": ctype,
        "ability_type": db.get("ability", "NONE"),
        "max_turns": 50,
        "max_watchdog_timeouts": 5,
        "union_enabled": ctype == "Union",
        "expect_log_not_contains": ["SCRIPT ERROR", "Invalid call", "Stack trace"],
    }

    if ctype == "Character":
        return {
            **base,
            "role": "t1_character_attacker",
            "deck0": build_char_deck(name),
            "deck1": build_char_deck(WEAK_DEFENDER),
            "forced_cells_0": [{"card_name": name, **ATTACKER_CELL}],
            "forced_cells_1": [{"card_name": WEAK_DEFENDER, **DEFENDER_CELL}],
            "forced_tech_0": [], "forced_tech_1": [],
            "expect_log_contains": [name, "GAME OVER"],
            "notes": "Tier 1 smoke: character on field, battle completes.",
        }
    if ctype == "Trap":
        return {
            **base,
            "role": "t1_trap",
            "deck0": build_char_deck(),
            "deck1": build_trap_deck(name),
            "forced_cells_0": [],
            "forced_cells_1": [{"card_name": name, **DEFENDER_CELL}],
            "forced_tech_0": [], "forced_tech_1": [],
            "expect_log_contains": [name, "GAME OVER"],
            "notes": "Tier 1 smoke: trap on field.",
        }
    if ctype == "Tech":
        return {
            **base,
            "role": "t1_tech",
            "deck0": build_tech_deck(name),
            "deck1": build_char_deck(WEAK_DEFENDER),
            "forced_cells_0": [{"card_name": "Ox Patrol", "row": 2, "col": 1}],
            "forced_cells_1": [{"card_name": WEAK_DEFENDER, **DEFENDER_CELL}],
            "forced_tech_0": [name, "", ""],
            "forced_tech_1": [],
            "expect_log_contains": [name, "GAME OVER"],
            "notes": "Tier 1 smoke: tech in hand.",
        }
    materials = extract_union_materials(formula)
    forced = [{"card_name": m, "row": 0, "col": i} for i, m in enumerate(materials[:3])]
    return {
        **base,
        "role": "t1_union",
        "deck0": build_union_deck(materials),
        "deck1": build_char_deck(WEAK_DEFENDER),
        "forced_cells_0": forced,
        "forced_cells_1": [{"card_name": WEAK_DEFENDER, **DEFENDER_CELL}],
        "forced_tech_0": [], "forced_tech_1": [],
        "expect_log_contains": ["GAME OVER"],
        "expect_log_any": [name, "Union summoned"],
        "notes": "Tier 1 smoke: union materials placed.",
    }


def load_formulas() -> dict[str, str]:
    import openpyxl
    from card_db import demo_names, ROOT
    wb = openpyxl.load_workbook(ROOT / "context/card_data_demo.xlsx", data_only=True)
    demo = demo_names()
    formulas: dict[str, str] = {}
    for sheet in ["Unit", "Tech", "Trap", "Union"]:
        ws = wb[sheet]
        rows = list(ws.iter_rows(values_only=True))
        headers = [str(h).strip() if h else "" for h in rows[1]]
        idx = {h: i for i, h in enumerate(headers) if h}
        for row in rows[2:]:
            if not row or not row[0]:
                continue
            name = str(row[0]).strip()
            if name not in demo:
                continue
            formula = ""
            for k in ("Full Formula", "Partial Formula", "Formula"):
                if k in idx and row[idx[k]]:
                    formula = str(row[idx[k]]).strip()
                    break
            formulas[name] = formula
    return formulas


def main() -> None:
    db_all = demo_cards_merged()
    formulas = load_formulas()
    scenarios: list[dict] = []
    missing_db: list[str] = []

    for name in sorted(db_all.keys(), key=lambda n: (db_all[n]["card_type"], n)):
        db = db_all[name]
        formula = formulas.get(name, "")
        scenarios.append(scenario_tier1(db, formula))
        s2 = build_tier2(db, extract_union_materials(formula))
        if db["card_type"] == "Union":
            if name in UNION_T2_DECK_CHARS:
                s2["deck0"]["characters"] = UNION_T2_DECK_CHARS[name]
            if name in UNION_T2_FORCED_CELLS_0:
                s2["forced_cells_0"] = UNION_T2_FORCED_CELLS_0[name]
            # Remove forced-cell cards from deck chars to prevent duplicates.
            forced_names = {f["card_name"] for f in s2["forced_cells_0"]}
            s2["deck0"]["characters"] = [c for c in s2["deck0"]["characters"] if c not in forced_names]
        scenarios.append(s2)

    # Cards in demo_flags but missing from DB (shouldn't happen often)
    from card_db import demo_names
    for n in sorted(demo_names() - set(db_all.keys())):
        missing_db.append(n)

    payload = {
        "version": 2,
        "generated_from": "CardDatabase.gd + UnionDatabase.gd + demo_flags.json",
        "scenario_count": len(scenarios),
        "tier1_count": sum(1 for s in scenarios if s.get("tier") == 1),
        "tier2_count": sum(1 for s in scenarios if s.get("tier") == 2),
        "scenarios": scenarios,
    }
    if missing_db:
        payload["missing_from_database"] = missing_db

    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(scenarios)} scenarios: {payload['tier1_count']} T1 + {payload['tier2_count']} T2)")
    if missing_db:
        print(f"  Warning: {len(missing_db)} demo cards missing from DB: {missing_db[:5]}")


if __name__ == "__main__":
    main()
