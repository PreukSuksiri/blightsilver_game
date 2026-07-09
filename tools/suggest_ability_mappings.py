#!/usr/bin/env python3
"""Suggest and write data/card_ability_mappings.json from xlsx + rules."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from card_mapping_rules import (  # noqa: E402
    AFFINITY_WORDS,
    TRAP_MAPPINGS,
    TECH_MAPPINGS,
    normalize_ability,
    suggest_character,
    suggest_union,
)
from sync_card_data_from_xlsx import (  # noqa: E402
    AFFINITY,
    CARD_DB,
    UNION_DB,
    gd_name,
    load_workbook,
    sheet_rows,
)

OUT = ROOT / "data" / "card_ability_mappings.json"
SUGGESTIONS = ROOT / "context/card_ability_mapping_suggestions.json"


def load_char_templates(card_text: str, xlsx_abilities: dict[str, str]) -> dict[str, dict]:
    """Map normalized ability text -> mapping from all implemented characters in CardDatabase."""
    templates: dict[str, dict] = {}
    for m in re.finditer(
        r'\["([^"]+)",\s*CharacterData\.Affinity\.\w+,\s*\d+,\s*\d+,\s*\d+,\s*\n\s*'
        r"CharacterData\.AbilityType\.(\w+),\s*(\{[\s\S]*?\}),\s*\n\s*\"([^\"]*)\"",
        card_text,
    ):
        name, atype, params_raw, desc = m.group(1), m.group(2), m.group(3), m.group(4)
        if atype == "NOT_IMPLEMENTED":
            continue
        # Prefer CardDatabase description for template key; fall back to xlsx Ability text.
        ab = normalize_ability(desc)
        if not ab or ab == "none":
            ab = normalize_ability(xlsx_abilities.get(name, ""))
        if ab:
            templates[ab] = {"ability_type": atype, "ability_params_raw": params_raw}
    return templates


def params_from_demo_raw(raw: str) -> dict:
    """Best-effort parse of GD dict literal; affinity stays as string token."""
    params: dict = {}
    for m in re.finditer(r'"(\w+)":\s*(CharacterData\.Affinity\.(\w+)|(\d+)|(true|false))', raw):
        key = m.group(1)
        if m.group(3):
            params[key] = m.group(3)
        elif m.group(4) is not None:
            params[key] = int(m.group(4))
        elif m.group(5):
            params[key] = m.group(5) == "true"
    return params


def suggest_tech(name: str, ability: str, cost: int) -> dict | None:
    if name in TECH_MAPPINGS:
        return TECH_MAPPINGS[name]
    ab = normalize_ability(ability)
    if "destroy" in ab and "foe" in ab and "exposed" in ab:
        return {"effect_type": "DESTROY_FACEUP_CARD", "effect_params": {}, "required_prior_card": ""}
    if "reveal" in ab and "foe" in ab:
        m = re.search(r"reveal (\d+)", ab)
        count = int(m.group(1)) if m else 1
        return {"effect_type": "REVEAL_OPPONENT_SQUARE", "effect_params": {"count": count}, "required_prior_card": ""}
    if "revive" in ab:
        return {"effect_type": "REVIVE_CHARACTER_FULL", "effect_params": {}, "required_prior_card": ""}
    if re.search(r"\+(\d+) atk permanently", ab):
        m = re.search(r"\+(\d+) atk permanently", ab)
        return {"effect_type": "PERM_ATK_BOOST_ONE", "effect_params": {"amount": int(m.group(1))}, "required_prior_card": ""}
    if re.search(r"\+(\d+) def permanently", ab):
        m = re.search(r"\+(\d+) def permanently", ab)
        return {"effect_type": "PERM_DEF_BOOST_ONE", "effect_params": {"amount": int(m.group(1))}, "required_prior_card": ""}
    if "flip a coin" in ab and "crystal" in ab:
        return {"effect_type": "TEMP_REROLL_DICE", "effect_params": {}, "required_prior_card": ""}
    if "receive" in ab and "crystal" in ab:
        m = re.search(r"receive (\d+)", ab)
        amt = int(m.group(1)) if m else 100
        return {"effect_type": "OPPONENT_REVEALS_OR_GAINS", "effect_params": {"self_gain": amt}, "required_prior_card": ""}
    if "clear all flags" in ab:
        return {"effect_type": "ADD_MUTAGEN_FLAG", "effect_params": {"clear_all_flags": True}, "required_prior_card": ""}
    if "destroy all" in ab and "affinity" in ab.lower():
        for word, aff in AFFINITY_WORDS.items():
            if word in ab:
                return {
                    "effect_type": "DESTROY_ALL_REVEALED_OPPONENT",
                    "effect_params": {"count": 99, "affinity_filter": aff, "discard_own_tech": True},
                    "required_prior_card": "",
                }
    if cost == 0:
        return {"effect_type": "REVEAL_OPPONENT_SQUARE", "effect_params": {"count": 1}, "required_prior_card": ""}
    return {"effect_type": "REVEAL_OPPONENT_SQUARE", "effect_params": {"count": 1}, "required_prior_card": ""}


def not_implemented_chars(card_text: str) -> list[str]:
    return re.findall(
        r'^\t\t\["([^"]+)",\s*CharacterData\.Affinity\.\w+,\s*\d+,\s*\d+,\s*\d+,\s*\n'
        r"\t\t\tCharacterData\.AbilityType\.NOT_IMPLEMENTED",
        card_text,
        re.M,
    )


def not_implemented_traps(card_text: str) -> list[str]:
    return re.findall(
        r'^\t\t\["([^"]+)",\s*\d+,\s*TrapData\.TrapEffectType\.NOT_IMPLEMENTED',
        card_text,
        re.M,
    )


def not_implemented_tech(card_text: str) -> list[str]:
    return re.findall(
        r'^\t\t\["([^"]+)",\s*\d+,\s*TechCardData\.TechEffectType\.NOT_IMPLEMENTED',
        card_text,
        re.M,
    )


def not_implemented_unions(union_text: str) -> list[str]:
    names: list[str] = []
    for m in re.finditer(
        r'_add\("([^"]+)"[\s\S]*?,\s*R\.\w+,\s*\n\t\tAB\.(\w+)',
        union_text,
    ):
        if m.group(2) == "NOT_IMPLEMENTED":
            names.append(m.group(1))
    return names


def main() -> int:
    wb = load_workbook()
    card_text = CARD_DB.read_text(encoding="utf-8")
    union_text = UNION_DB.read_text(encoding="utf-8")

    _, units = sheet_rows(wb, "Unit")
    unit_xlsx = {gd_name(c["_name"]): c for c in units}

    mappings = {"characters": {}, "traps": {}, "tech": {}, "unions": {}}
    unmapped = {"characters": [], "traps": [], "tech": [], "unions": []}

    xlsx_ab = {gd_name(c["_name"]): str(c.get("Ability") or "") for c in units}
    templates = load_char_templates(card_text, xlsx_ab)

    for name in not_implemented_chars(card_text):
        card = unit_xlsx.get(name, {})
        ab = str(card.get("Ability") or "")
        aff = str(card.get("Affinity") or "")
        norm = normalize_ability(ab)
        if norm in templates:
            t = templates[norm]
            mappings["characters"][name] = {
                "ability_type": t["ability_type"],
                "ability_params": params_from_demo_raw(t["ability_params_raw"]),
            }
            continue
        sug = suggest_character(name, ab, aff)
        if sug:
            mappings["characters"][name] = sug
        else:
            unmapped["characters"].append(name)

    for name in not_implemented_traps(card_text):
        if name in TRAP_MAPPINGS:
            mappings["traps"][name] = TRAP_MAPPINGS[name]
        else:
            unmapped["traps"].append(name)

    _, techs = sheet_rows(wb, "Tech")
    tech_xlsx = {gd_name(c["_name"]): c for c in techs}
    for name in not_implemented_tech(card_text):
        card = tech_xlsx.get(name, {})
        ab = str(card.get("Ability") or "")
        cost = int(card.get("Cost") or 0)
        sug = suggest_tech(name, ab, cost)
        if sug:
            mappings["tech"][name] = sug
        else:
            unmapped["tech"].append(name)

    _, unions = sheet_rows(wb, "Union")
    union_xlsx = {gd_name(c["_name"]): c for c in unions}
    for name in not_implemented_unions(union_text):
        card = union_xlsx.get(name, {})
        ab = str(card.get("Full Ability") or card.get("Partial Ability") or "")
        sug = suggest_union(name, ab)
        if sug:
            mappings["unions"][name] = sug
        else:
            mappings["unions"][name] = {"ability_type": "NONE", "ability_params": {}}
            unmapped["unions"].append(name)

    OUT.write_text(json.dumps(mappings, indent="\t") + "\n", encoding="utf-8")
    SUGGESTIONS.write_text(json.dumps(unmapped, indent="\t") + "\n", encoding="utf-8")

    print("Wrote", OUT.relative_to(ROOT))
    for k, v in mappings.items():
        print(f"  {k}: {len(v)} mappings")
    for k, v in unmapped.items():
        if v:
            print(f"  unmapped {k}: {len(v)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
