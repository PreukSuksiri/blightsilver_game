#!/usr/bin/env python3
"""Generate missing CardDatabase.gd / UnionDatabase.gd entries from context/card_data.xlsx."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from sync_card_data_from_xlsx import (  # noqa: E402
    CARD_DB,
    RARITY,
    UNION_DB,
    XLSX,
    conds_to_gd,
    esc,
    gd_name,
    load_workbook,
    parse_formula_conditions,
    parse_summon_cost,
    parse_zone,
    resolve_affinity,
    sheet_rows,
    zone_to_gd,
)

REPORT_PATH = ROOT / "context" / "full_release_import_report.md"

INSERT_MARKERS = {
    "characters": (
        CARD_DB,
        r"(func _load_characters\(\) -> void:[\s\S]*?\n)(\t\]\n\n\tfor d in defs:)",
    ),
    "traps": (
        CARD_DB,
        r"(func _load_traps\(\) -> void:[\s\S]*?\n)(\t\]\n\n\tfor d in defs:)",
    ),
    "tech": (
        CARD_DB,
        r"(func _load_tech_cards\(\) -> void:[\s\S]*?\n)(\t\]\n\n\tfor d in defs:)",
    ),
    "unions": (
        UNION_DB,
        r"(\n)(func _add\()",
    ),
}


def parse_rarity(card: dict) -> str:
    raw = card.get("Rarity")
    if raw is None:
        return "COMMON"
    if isinstance(raw, (int, float)):
        return RARITY.get(str(int(raw)), "COMMON")
    text = str(raw).strip()
    return RARITY.get(text, "COMMON")


def read_game_names() -> dict[str, set[str]]:
    card_text = CARD_DB.read_text(encoding="utf-8")
    union_text = UNION_DB.read_text(encoding="utf-8")
    return {
        "Unit": set(re.findall(r'^\t\t\["([^"]+)",\s*CharacterData', card_text, re.M)),
        "Trap": set(re.findall(r'^\t\t\["([^"]+)",\s*\d+,\s*TrapData', card_text, re.M)),
        "Tech": set(re.findall(r'^\t\t\["([^"]+)",\s*\d+,\s*TechCardData', card_text, re.M)),
        "Union": set(re.findall(r'^\t_add\("([^"]+)"', union_text, re.M)),
    }


def unit_is_complete(card: dict) -> bool:
    name = gd_name(card["_name"])
    aff = resolve_affinity(card.get("Affinity"), card_name=name)
    if not aff:
        return False
    for key in ("ATK", "DEF", "Cost"):
        if card.get(key) is None or str(card.get(key)).strip() == "":
            return False
    return True


def union_is_complete(card: dict) -> bool:
    aff = resolve_affinity(card.get("Affinity"), card_name=gd_name(card["_name"]))
    if not aff:
        return False
    for key in ("ATK", "DEF"):
        if card.get(key) is None or str(card.get(key)).strip() == "":
            return False
    if not str(card.get("Full Formula") or "").strip():
        return False
    return True


def ability_text(card: dict) -> str:
    return esc(str(card.get("Ability") or "").strip().replace("\n", " "))


def gen_character(card: dict) -> str:
    name = gd_name(card["_name"])
    aff = resolve_affinity(card.get("Affinity"), card_name=name)
    if not aff:
        raise ValueError(f"Cannot resolve affinity for unit {name}")
    atk = int(card.get("ATK") or 0)
    def_ = int(card.get("DEF") or 0)
    cost = int(card.get("Cost") or 0)
    rarity = parse_rarity(card)
    ab = ability_text(card)
    if not ab or ab.lower() == "none":
        ab = "None"
    return (
        f'\t\t["{esc(name)}", CharacterData.Affinity.{aff}, {atk}, {def_}, {cost},\n'
        f"\t\t\tCharacterData.AbilityType.NOT_IMPLEMENTED, {{}},\n"
        f'\t\t\t"{ab}",\n'
        f"\t\t\tCharacterData.Rarity.{rarity},\n"
        f"\t\t\ttrue],"
    )


def gen_trap(card: dict) -> str:
    name = gd_name(card["_name"])
    cost = int(card.get("Cost") or 0)
    rarity = parse_rarity(card)
    ab = ability_text(card)
    if not ab:
        ab = "None"
    return (
        f'\t\t["{esc(name)}", {cost}, TrapData.TrapEffectType.NOT_IMPLEMENTED,\n'
        f'\t\t\t{{}}, "{ab}",\n'
        f"\t\t\tCharacterData.Rarity.{rarity},\n"
        f"\t\t\ttrue],"
    )


def gen_tech(card: dict) -> str:
    name = gd_name(card["_name"])
    cost = int(card.get("Cost") or 0)
    rarity = parse_rarity(card)
    ab = ability_text(card)
    if not ab:
        ab = "None"
    return (
        f'\t\t["{esc(name)}", {cost}, TechCardData.TechEffectType.NOT_IMPLEMENTED,\n'
        f'\t\t\t{{}}, "", "{ab}",\n'
        f"\t\t\tCharacterData.Rarity.{rarity},\n"
        f"\t\t\ttrue],"
    )


def gen_union(card: dict) -> str:
    name = gd_name(card["_name"])
    aff = resolve_affinity(card.get("Affinity"), card_name=name)
    if not aff:
        raise ValueError(f"Cannot resolve affinity for union {name}")
    atk = int(card.get("ATK") or 0)
    def_ = int(card.get("DEF") or 0)
    full_f = str(card.get("Full Formula") or "").strip().replace("\n", " ")
    part_f = str(card.get("Partial Formula") or full_f).strip().replace("\n", " ")
    full_ab = esc(str(card.get("Full Ability") or "None").strip().replace("\n", " "))
    part_ab = esc(str(card.get("Partial Ability") or full_ab).strip().replace("\n", " "))
    summon = parse_summon_cost(full_f) or int(card.get("Cost") or 0)
    rarity = parse_rarity(card)
    zone_cells = parse_zone(card.get("Union Zone"))
    parsed_conds = parse_formula_conditions(full_f)
    zone_size = len(zone_cells) if zone_cells else max(len(parsed_conds), 1)
    zone_gd = zone_to_gd(zone_cells) if zone_cells else "_z([])"
    conds_gd = conds_to_gd(parsed_conds, zone_size)
    return (
        f'\n\t_add("{esc(name)}", A.{aff}, {atk}, {def_}, {summon}, R.{rarity},\n'
        f'\t\tAB.NOT_IMPLEMENTED, {{}}, "{full_ab}", "{part_ab}",\n'
        f'\t\t"{esc(full_f)}", "{esc(part_f)}",\n'
        f"\t\t{zone_gd},\n"
        f"\t\t{conds_gd})"
    )


def collect_missing(wb) -> tuple[dict[str, list[str]], dict[str, list[str]], dict[str, list[str]]]:
    existing = read_game_names()
    generated: dict[str, list[str]] = {"Unit": [], "Trap": [], "Tech": [], "Union": []}
    skipped: dict[str, list[str]] = {"Unit": [], "Union": []}
    already: dict[str, int] = {k: 0 for k in generated}

    for sheet, gen_fn, complete_fn in [
        ("Unit", gen_character, unit_is_complete),
        ("Trap", gen_trap, lambda c: True),
        ("Tech", gen_tech, lambda c: True),
        ("Union", gen_union, union_is_complete),
    ]:
        _, cards = sheet_rows(wb, sheet)
        for card in cards:
            name = gd_name(card["_name"])
            if name in existing[sheet]:
                already[sheet] += 1
                continue
            if not complete_fn(card):
                if sheet in skipped:
                    skipped[sheet].append(name)
                continue
            generated[sheet].append(gen_fn(card))

    return generated, skipped, already


def insert_block(path: Path, pattern: str, block: str, label: str) -> None:
    text = path.read_text(encoding="utf-8")
    m = re.search(pattern, text)
    if not m:
        raise RuntimeError(f"Could not find insertion point for {label} in {path}")
    if not block.strip():
        return
    header = f"\n\t\t# ── Full-release import ({label}) ──\n"
    new_text = text[: m.start(2)] + header + block + "\n" + text[m.start(2) :]
    path.write_text(new_text, encoding="utf-8")


def write_report(
    generated: dict[str, list[str]],
    skipped: dict[str, list[str]],
    already: dict[str, int],
) -> None:
    total_added = sum(len(v) for v in generated.values())
    in_game = {k: already[k] + len(generated[k]) for k in generated}
    lines = [
        "# Full-release card import report",
        "",
        f"Source: `{XLSX.relative_to(ROOT)}`",
        "",
        "## Generated entries",
        "",
        "| Sheet | Added | Already in game | Skipped (incomplete xlsx) | In-game now |",
        "|-------|------:|----------------:|------------------------:|------------:|",
    ]
    for sheet in ("Unit", "Trap", "Tech", "Union"):
        lines.append(
            f"| {sheet} | {len(generated[sheet])} | {already[sheet]} | "
            f"{len(skipped.get(sheet, []))} | {in_game[sheet]} |"
        )
    lines.extend(
        [
            "",
            f"**Total added this run:** {total_added}",
            f"**In-game total:** {sum(in_game.values())} / 770 xlsx rows "
            f"({sum(len(skipped.get(s, [])) for s in ('Unit', 'Union'))} skipped)",
            "",
            "## Validation",
            "",
            "After import, run:",
            "",
            "```bash",
            "python3 tools/sync_card_data_from_xlsx.py",
            "python3 tools/validate_card_database.py",
            "```",
            "",
            "Expected: **Validation OK** with 0 missing (excluding skipped rows).",
            "",
            "## Skipped rows (fix xlsx before import)",
            "",
        ]
    )
    if skipped.get("Union"):
        lines.append("### Unions (empty Full Formula or missing stats)")
        for name in sorted(skipped["Union"]):
            lines.append(f"- {name}")
        lines.append("")
    if skipped.get("Unit"):
        lines.append("### Units (missing ATK/DEF/Cost/Affinity)")
        for name in sorted(skipped["Unit"]):
            lines.append(f"- {name}")
        lines.append("")
    lines.extend(
        [
            "## Follow-up checklist",
            "",
            "- Map `NOT_IMPLEMENTED` cards to real AbilityType / TrapEffectType / TechEffectType",
            "- Add card art (generated entries use `placeholder_art: true`)",
            "- Fix skipped xlsx rows and re-run generator",
            "- Run `python3 tools/sync_card_data_from_xlsx.py` after xlsx edits",
            "- Run `python3 tools/validate_card_database.py`",
            "",
        ]
    )
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--write",
        action="store_true",
        help="Patch CardDatabase.gd and UnionDatabase.gd (default: dry-run)",
    )
    args = parser.parse_args()

    if not XLSX.exists():
        print(f"Missing {XLSX}")
        return 1

    wb = load_workbook()
    generated, skipped, already = collect_missing(wb)

    print("Full-release card generation")
    for sheet in ("Unit", "Trap", "Tech", "Union"):
        print(
            f"  {sheet}: add {len(generated[sheet])}, "
            f"skip {len(skipped.get(sheet, []))}, already {already[sheet]}"
        )
    print(f"  Total to add: {sum(len(v) for v in generated.values())}")

    if skipped.get("Union"):
        print(f"  Skipped unions: {', '.join(sorted(skipped['Union'])[:5])}...")
    if skipped.get("Unit"):
        print(f"  Skipped units: {len(skipped['Unit'])}")

    write_report(generated, skipped, already)

    if not args.write:
        print(f"Dry-run only. Report: {REPORT_PATH.relative_to(ROOT)}")
        return 0

    if generated["Unit"]:
        insert_block(
            CARD_DB,
            INSERT_MARKERS["characters"][1],
            "\n".join(generated["Unit"]),
            "characters",
        )
    if generated["Trap"]:
        insert_block(
            CARD_DB,
            INSERT_MARKERS["traps"][1],
            "\n".join(generated["Trap"]),
            "traps",
        )
    if generated["Tech"]:
        insert_block(
            CARD_DB,
            INSERT_MARKERS["tech"][1],
            "\n".join(generated["Tech"]),
            "tech",
        )
    if generated["Union"]:
        union_block = "\n".join(generated["Union"])
        text = UNION_DB.read_text(encoding="utf-8")
        marker = "\nfunc _add("
        idx = text.rfind(marker)
        if idx < 0:
            raise RuntimeError("Could not find UnionDatabase _add insertion point")
        header = "\n\t# ── Full-release import (unions) ──"
        text = text[:idx] + header + union_block + text[idx:]
        UNION_DB.write_text(text, encoding="utf-8")

    print(f"Wrote entries to {CARD_DB.name} and {UNION_DB.name}")
    print(f"Report: {REPORT_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
