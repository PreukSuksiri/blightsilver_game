#!/usr/bin/env python3
"""Validate CardDatabase.gd / UnionDatabase.gd parity with context/card_data.xlsx."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from generate_full_card_database import (  # noqa: E402
    CARD_DB,
    UNION_DB,
    unit_is_complete,
    union_is_complete,
)
from sync_card_data_from_xlsx import XLSX, gd_name, load_workbook, resolve_affinity, sheet_rows  # noqa: E402

SKIPPED_UNIONS: set[str] = set()


def game_names() -> dict[str, set[str]]:
    card_text = CARD_DB.read_text(encoding="utf-8")
    union_text = UNION_DB.read_text(encoding="utf-8")
    return {
        "Unit": set(re.findall(r'^\t\t\["([^"]+)",\s*CharacterData', card_text, re.M)),
        "Trap": set(re.findall(r'^\t\t\["([^"]+)",\s*\d+,\s*TrapData', card_text, re.M)),
        "Tech": set(re.findall(r'^\t\t\["([^"]+)",\s*\d+,\s*TechCardData', card_text, re.M)),
        "Union": set(re.findall(r'^\t_add\("([^"]+)"', union_text, re.M)),
    }


def skipped_units_from_xlsx(wb) -> set[str]:
    _, cards = sheet_rows(wb, "Unit")
    skipped: set[str] = set()
    for card in cards:
        name = gd_name(card["_name"])
        if not unit_is_complete(card):
            skipped.add(name)
    return skipped


def main() -> int:
    if not XLSX.exists():
        print(f"Missing {XLSX}")
        return 1

    wb = load_workbook()
    existing = game_names()
    skipped_units = skipped_units_from_xlsx(wb)
    allowed_skips = SKIPPED_UNIONS | skipped_units

    missing: list[str] = []
    orphans: list[str] = []
    stat_mismatches: list[str] = []

    card_text = CARD_DB.read_text(encoding="utf-8")
    union_text = UNION_DB.read_text(encoding="utf-8")

    for sheet, gset in existing.items():
        _, cards = sheet_rows(wb, sheet)
        xlsx_names = {gd_name(c["_name"]) for c in cards}
        for name in sorted(xlsx_names - gset):
            if name in allowed_skips:
                continue
            missing.append(f"{sheet}:{name}")
        for name in sorted(gset - xlsx_names):
            orphans.append(f"{sheet}:{name}")

    # Spot-check stats for units
    _, units = sheet_rows(wb, "Unit")
    for card in units:
        name = gd_name(card["_name"])
        if name not in existing["Unit"]:
            continue
        m = re.search(
            rf'\["{re.escape(name)}",\s*CharacterData\.Affinity\.(\w+),\s*(\d+),\s*(\d+),\s*(\d+),',
            card_text,
        )
        if not m:
            stat_mismatches.append(f"Unit:{name}: not parseable in GD")
            continue
        exp_aff = resolve_affinity(card.get("Affinity"), card_name=name)
        if exp_aff and m.group(1) != exp_aff:
            stat_mismatches.append(f"Unit:{name}: affinity {exp_aff} vs {m.group(1)}")
        for idx, key in enumerate(("ATK", "DEF", "Cost"), start=2):
            exp = int(card.get(key if key != "Cost" else "Cost") or 0)
            got = int(m.group(idx))
            if exp != got:
                stat_mismatches.append(f"Unit:{name}: {key} xlsx={exp} game={got}")

    print("=== Card database validation ===")
    print(f"In-game: Unit={len(existing['Unit'])} Trap={len(existing['Trap'])} "
          f"Tech={len(existing['Tech'])} Union={len(existing['Union'])}")
    print(f"Missing (excl. allowed skips): {len(missing)}")
    print(f"Orphans (in game, not in xlsx): {len(orphans)}")
    print(f"Stat mismatches (units sample): {len(stat_mismatches)}")
    print(f"Allowed skips: {len(allowed_skips)} ({len(SKIPPED_UNIONS)} unions + {len(skipped_units)} incomplete units)")

    ni_chars = len(re.findall(r"CharacterData\.AbilityType\.NOT_IMPLEMENTED", card_text))
    ni_traps = len(re.findall(r"TrapEffectType\.NOT_IMPLEMENTED", card_text))
    ni_tech = len(re.findall(r"TechEffectType\.NOT_IMPLEMENTED", card_text))
    ni_unions = len(re.findall(r"AB\.NOT_IMPLEMENTED", union_text))
    print(f"NOT_IMPLEMENTED: Unit={ni_chars} Trap={ni_traps} Tech={ni_tech} Union={ni_unions}")

    if ni_chars + ni_traps + ni_tech + ni_unions > 0:
        print("(WARN: ability stubs remain — run apply_ability_mappings.py after updating mappings)")

    if missing:
        print("\nMissing:")
        for line in missing[:30]:
            print(f"  - {line}")
        if len(missing) > 30:
            print(f"  ... +{len(missing) - 30} more")

    if orphans:
        print("\nOrphans:")
        for line in orphans:
            print(f"  - {line}")

    if stat_mismatches:
        print("\nStat mismatches:")
        for line in stat_mismatches[:20]:
            print(f"  - {line}")

    ok = not missing and not orphans and not stat_mismatches
    print("\nValidation", "OK" if ok else "FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
