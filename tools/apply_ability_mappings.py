#!/usr/bin/env python3
"""Apply data/card_ability_mappings.json to CardDatabase.gd and UnionDatabase.gd."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAPPINGS = ROOT / "data" / "card_ability_mappings.json"
CARD_DB = ROOT / "autoload" / "CardDatabase.gd"
UNION_DB = ROOT / "autoload" / "UnionDatabase.gd"

CHAR_ENUM = ROOT / "resources" / "CharacterData.gd"
TRAP_ENUM = ROOT / "resources" / "TrapData.gd"
TECH_ENUM = ROOT / "resources" / "TechCardData.gd"


def load_enums() -> dict[str, set[str]]:
    def parse_enum(path: Path, enum_name: str) -> set[str]:
        text = path.read_text(encoding="utf-8")
        m = re.search(rf"enum {enum_name} \{{([\s\S]*?)\n\}}", text)
        if not m:
            return set()
        return set(re.findall(r"^\t([A-Z_0-9]+),", m.group(1), re.M))

    return {
        "AbilityType": parse_enum(CHAR_ENUM, "AbilityType"),
        "TrapEffectType": parse_enum(TRAP_ENUM, "TrapEffectType"),
        "TechEffectType": parse_enum(TECH_ENUM, "TechEffectType"),
    }


def params_to_gd(params: dict, *, trap: bool = False, tech: bool = False) -> str:
    if not params:
        return "{}"
    parts: list[str] = []
    for key, val in params.items():
        if key == "affinity" and isinstance(val, str):
            parts.append(f'"affinity": CharacterData.Affinity.{val}')
        elif key in ("aff1", "aff2") and isinstance(val, str):
            parts.append(f'"{key}": CharacterData.Affinity.{val}')
        elif isinstance(val, str):
            parts.append(f'"{key}": "{val.replace(chr(92), chr(92)*2).replace(chr(34), chr(92)+chr(34))}"')
        elif isinstance(val, bool):
            parts.append(f'"{key}": {"true" if val else "false"}')
        elif isinstance(val, list):
            inner = ", ".join(
                f"CharacterData.Affinity.{x}" if isinstance(x, str) and x.isupper() else json.dumps(x)
                for x in val
            )
            parts.append(f'"{key}": [{inner}]')
        else:
            parts.append(f'"{key}": {val}')
    return "{" + ", ".join(parts) + "}"


def current_char_type(text: str, name: str) -> str | None:
    m = re.search(
        rf'\["{re.escape(name)}",[\s\S]*?CharacterData\.AbilityType\.(\w+),',
        text,
    )
    return m.group(1) if m else None


def patch_character(text: str, name: str, ability_type: str, params: dict) -> tuple[str, bool]:
    pat = (
        rf'(\["{re.escape(name)}",[\s\S]*?CharacterData\.AbilityType\.)\w+(,\s*)'
        rf'(\{{[\s\S]*?\}})(,)'
    )
    gd_params = params_to_gd(params)
    repl = rf"\g<1>{ability_type}\g<2>{gd_params}\g<4>"
    new_text, n = re.subn(pat, repl, text, count=1)
    return new_text, n > 0


def patch_trap(text: str, name: str, effect_type: str, params: dict) -> tuple[str, bool]:
    pat = (
        rf'(\["{re.escape(name)}",\s*\d+,\s*TrapData\.TrapEffectType\.)\w+(,\s*)'
        rf'(\{{[\s\S]*?\}})(,)'
    )
    gd_params = params_to_gd(params, trap=True)
    new_text, n = re.subn(pat, rf"\g<1>{effect_type}\g<2>{gd_params}\g<4>", text, count=1)
    return new_text, n > 0


def patch_tech(
    text: str, name: str, effect_type: str, params: dict, prior: str
) -> tuple[str, bool]:
    pat = (
        rf'(\["{re.escape(name)}",\s*\d+,\s*TechCardData\.TechEffectType\.)\w+(,\s*)'
        rf'(\{{[\s\S]*?\}})(,\s*")([^"]*)(")'
    )
    gd_params = params_to_gd(params, tech=True)
    new_text, n = re.subn(
        pat,
        rf"\g<1>{effect_type}\g<2>{gd_params}\g<4>{prior}\g<6>",
        text,
        count=1,
    )
    return new_text, n > 0


def patch_union(text: str, name: str, ability_type: str, params: dict) -> tuple[str, bool]:
    pat = (
        rf'(_add\("{re.escape(name)}",[\s\S]*?,\s*R\.\w+,\s*)'
        rf'AB\.\w+(,\s*)(\{{[\s\S]*?\}})(,)'
    )
    gd_params = params_to_gd(params)
    new_text, n = re.subn(pat, rf"\g<1>AB.{ability_type}\g<2>{gd_params}\g<4>", text, count=1)
    return new_text, n > 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true", help="Apply even if not NOT_IMPLEMENTED")
    args = parser.parse_args()

    if not MAPPINGS.exists():
        print(f"Missing {MAPPINGS}")
        return 1

    data = json.loads(MAPPINGS.read_text(encoding="utf-8"))
    enums = load_enums()
    card_text = CARD_DB.read_text(encoding="utf-8")
    union_text = UNION_DB.read_text(encoding="utf-8")

    stats = {"applied": 0, "skipped": 0, "missing": 0, "bad_enum": 0}
    errors: list[str] = []

    for name, entry in data.get("characters", {}).items():
        at = entry.get("ability_type", "")
        if at not in enums["AbilityType"]:
            errors.append(f"character {name}: unknown AbilityType.{at}")
            stats["bad_enum"] += 1
            continue
        cur = current_char_type(card_text, name)
        if cur is None:
            stats["missing"] += 1
            continue
        if cur != "NOT_IMPLEMENTED" and not args.force:
            stats["skipped"] += 1
            continue
        if args.dry_run:
            stats["applied"] += 1
            continue
        card_text, ok = patch_character(card_text, name, at, entry.get("ability_params", {}))
        stats["applied" if ok else "missing"] += (1 if ok else 0)

    for name, entry in data.get("traps", {}).items():
        et = entry.get("effect_type", "")
        if et not in enums["TrapEffectType"]:
            errors.append(f"trap {name}: unknown TrapEffectType.{et}")
            stats["bad_enum"] += 1
            continue
        if args.dry_run:
            stats["applied"] += 1
            continue
        card_text, ok = patch_trap(card_text, name, et, entry.get("effect_params", {}))
        stats["applied" if ok else "missing"] += (1 if ok else 0)

    for name, entry in data.get("tech", {}).items():
        et = entry.get("effect_type", "")
        if et not in enums["TechEffectType"]:
            errors.append(f"tech {name}: unknown TechEffectType.{et}")
            stats["bad_enum"] += 1
            continue
        if args.dry_run:
            stats["applied"] += 1
            continue
        card_text, ok = patch_tech(
            card_text,
            name,
            et,
            entry.get("effect_params", {}),
            entry.get("required_prior_card", ""),
        )
        stats["applied" if ok else "missing"] += (1 if ok else 0)

    for name, entry in data.get("unions", {}).items():
        at = entry.get("ability_type", "")
        if at not in enums["AbilityType"]:
            errors.append(f"union {name}: unknown AbilityType.{at}")
            stats["bad_enum"] += 1
            continue
        if args.dry_run:
            stats["applied"] += 1
            continue
        union_text, ok = patch_union(union_text, name, at, entry.get("ability_params", {}))
        stats["applied" if ok else "missing"] += (1 if ok else 0)

    print(
        f"apply_ability_mappings: applied={stats['applied']} skipped={stats['skipped']} "
        f"missing={stats['missing']} bad_enum={stats['bad_enum']}"
    )
    for err in errors[:20]:
        print(f"  ERROR: {err}")
    if len(errors) > 20:
        print(f"  ... +{len(errors) - 20} more errors")

    if not args.dry_run and stats["bad_enum"] == 0:
        CARD_DB.write_text(card_text, encoding="utf-8")
        UNION_DB.write_text(union_text, encoding="utf-8")
        print(f"Wrote {CARD_DB.name} and {UNION_DB.name}")

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
