#!/usr/bin/env python3
"""Audit union summon zones and material conditions vs card_data.xlsx."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from sync_card_data_from_xlsx import (  # noqa: E402
    UNION_DB,
    XLSX,
    gd_name,
    load_workbook,
    parse_formula_conditions,
    parse_zone,
    sheet_rows,
)
from generate_full_card_database import union_is_complete  # noqa: E402

REPORT = ROOT / "context" / "full_release_import_report.md"
SKIPPED_UNIONS: set[str] = set()


def parse_union_block(text: str, name: str) -> dict:
    m = re.search(
        rf'_add\("{re.escape(name)}"[\s\S]*?_z\(\[([\s\S]*?)\]\)[\s\S]*?'
        rf'_conds\(\[([\s\S]*?)\],\s*(\d+)\)',
        text,
    )
    if not m:
        return {"zone": [], "conds_raw": "", "zone_size": 0}
    zone = sorted((int(r), int(c)) for r, c in re.findall(r"\[(\d+),\s*(\d+)\]", m.group(1)))
    return {"zone": zone, "conds_raw": m.group(2).strip(), "zone_size": int(m.group(3))}


def main() -> int:
    wb = load_workbook()
    _, unions = sheet_rows(wb, "Union")
    xlsx_by_name = {gd_name(c["_name"]): c for c in unions}
    union_text = UNION_DB.read_text(encoding="utf-8")
    in_game = re.findall(r'_add\("([^"]+)"', union_text)

    issues: list[str] = []
    ok = 0
    for name in in_game:
        if name in SKIPPED_UNIONS:
            continue
        card = xlsx_by_name.get(name)
        if card is None:
            issues.append(f"{name}: not in xlsx")
            continue
        if not union_is_complete(card):
            continue
        gd = parse_union_block(union_text, name)
        xz = sorted(parse_zone(card.get("Union Zone")))
        parsed = parse_formula_conditions(str(card.get("Full Formula") or ""))
        if not gd["zone"]:
            issues.append(f"{name}: empty zone in GD")
        elif gd["zone"] != xz:
            issues.append(f"{name}: zone mismatch xlsx={len(xz)} gd={len(gd['zone'])}")
        if not parsed:
            issues.append(f"{name}: xlsx formula parsed to 0 conditions")
        elif not gd["conds_raw"]:
            issues.append(f"{name}: empty _conds in GD")
        else:
            ok += 1

    print("=== Union summon audit ===")
    print(f"Checked: {ok + len(issues)} unions, OK: {ok}, issues: {len(issues)}")
    for line in issues:
        print(f"  - {line}")

    if REPORT.exists():
        text = REPORT.read_text(encoding="utf-8")
        block = ["", "## Union summon audit (latest)", "", f"OK: {ok}, Issues: {len(issues)}", ""]
        if issues:
            block.append("### Issues")
            for line in issues:
                block.append(f"- {line}")
            block.append("")
        if "## Union summon audit (latest)" in text:
            text = re.sub(
                r"\n## Union summon audit \(latest\)[\s\S]*?(?=\n## |\Z)",
                "\n".join(block) + "\n",
                text,
            )
        else:
            text += "\n".join(block) + "\n"
        REPORT.write_text(text, encoding="utf-8")

    return 0 if not issues else 1


if __name__ == "__main__":
    raise SystemExit(main())
