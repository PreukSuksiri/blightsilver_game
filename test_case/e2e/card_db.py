"""Parse demo-scope card stats/abilities from Godot database files."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent


def demo_names() -> set[str]:
    flags = json.loads((ROOT / "data/demo_flags.json").read_text())
    return {n for n, ok in flags.items() if ok}


def parse_params(raw: str) -> dict:
    if not raw or raw == "{}":
        return {}
    out: dict = {}
    for m in re.finditer(r'"(\w+)":\s*([^,}\]]+)', raw):
        key, val = m.group(1), m.group(2).strip()
        if val.startswith('"'):
            out[key] = val.strip('"')
        elif val.startswith("CharacterData.Affinity."):
            out[key] = val.split(".")[-1]
        elif val.startswith("["):
            out[key] = re.findall(r"CharacterData\.Affinity\.(\w+)", val)
        elif val in ("true", "false"):
            out[key] = val == "true"
        else:
            try:
                out[key] = int(val)
            except ValueError:
                out[key] = val
    return out


def parse_card_database() -> dict[str, dict]:
    text = (ROOT / "autoload/CardDatabase.gd").read_text()
    cards: dict[str, dict] = {}

    def load_section(func: str, card_type: str) -> None:
        idx = text.find(f"func {func}")
        s = text.find("var defs: Array = [", idx)
        e = text.find("\n\t]", s)
        for part in re.split(r"\n\t\t\[", text[s : e + 4])[1:]:
            part = "[" + part
            name_m = re.match(r'\["([^"]+)"', part)
            if not name_m:
                continue
            name = name_m.group(1)
            if card_type == "character":
                m = re.match(
                    r'\["([^"]+)",\s*CharacterData\.Affinity\.(\w+),\s*(\d+),\s*(\d+),\s*(\d+),\s*'
                    r"CharacterData\.AbilityType\.(\w+),\s*(\{.*?\}),\s*\n\t\t\t\"([^\"]*)\"",
                    part,
                    re.S,
                )
                if m:
                    cards[name] = {
                        "card_type": "Character",
                        "name": name,
                        "affinity": m.group(2),
                        "atk": int(m.group(3)),
                        "def": int(m.group(4)),
                        "cost": int(m.group(5)),
                        "ability": m.group(6),
                        "params_raw": m.group(7),
                        "description": m.group(8),
                    }
            elif card_type == "trap":
                m = re.match(
                    r'\["([^"]+)",\s*(\d+),\s*TrapData\.TrapEffectType\.(\w+),\s*(\{.*?\}),\s*\n\t\t\t"([^"]*)"',
                    part,
                    re.S,
                )
                if m:
                    cards[name] = {
                        "card_type": "Trap",
                        "name": name,
                        "cost": int(m.group(2)),
                        "ability": m.group(3),
                        "params_raw": m.group(4),
                        "description": m.group(5),
                    }
            elif card_type == "tech":
                m = re.match(
                    r'\["([^"]+)",\s*(\d+),\s*TechCardData\.TechEffectType\.(\w+),\s*(\{.*?\}),\s*'
                    r'(?:"([^"]*)",\s*)?\n\t\t\t"([^"]*)"',
                    part,
                    re.S,
                )
                if m:
                    cards[name] = {
                        "card_type": "Tech",
                        "name": name,
                        "cost": int(m.group(2)),
                        "ability": m.group(3),
                        "params_raw": m.group(4),
                        "required_prior": m.group(5) or "",
                        "description": m.group(6),
                    }

    load_section("_load_characters", "character")
    load_section("_load_traps", "trap")
    load_section("_load_tech_cards", "tech")
    return cards


def parse_union_database() -> dict[str, dict]:
    text = (ROOT / "autoload/UnionDatabase.gd").read_text()
    unions: dict[str, dict] = {}
    pattern = re.compile(
        r'_add\("([^"]+)",\s*A\.(\w+),\s*(\d+),\s*(\d+),\s*(\d+),\s*R\.\w+,\s*'
        r"AB\.(\w+),\s*(\{.*?\}),\s*\"([^\"]*)\"",
        re.S,
    )
    for m in pattern.finditer(text):
        unions[m.group(1)] = {
            "card_type": "Union",
            "name": m.group(1),
            "affinity": m.group(2),
            "atk": int(m.group(3)),
            "def": int(m.group(4)),
            "summon_cost": int(m.group(5)),
            "ability": m.group(6),
            "params_raw": m.group(7),
            "description": m.group(8),
        }
    return unions


def demo_cards_merged() -> dict[str, dict]:
    demo = demo_names()
    merged = {**parse_card_database(), **parse_union_database()}
    return {n: c for n, c in merged.items() if n in demo}
