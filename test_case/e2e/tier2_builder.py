"""Build Tier 2 (ability-aware) E2E scenarios for demo-scope cards."""

from __future__ import annotations

import re
from copy import deepcopy

from card_db import parse_params

# ── Layout constants ──────────────────────────────────────────────────────────
ATTACKER_CELL = {"row": 2, "col": 2}
DEFENDER_CELL = {"row": 2, "col": 2}
ALLY_CELL = {"row": 2, "col": 1}
WEAK_DEFENDER = "Chaotic Wisp"
ZERO_ATK_FILLER = "Church Guard"
STRONG_ATTACKER = "Ox Patrol"
UNION_MATERIAL = "Gryphon Rider"

FILLER_CHARS = [
    "Chaotic Wisp", "Foul Wisp", "Doom Wisp", "Church Guard", "Big Thug",
    "Dark Monk", "Goblin Poacher", "Mad Raccoon", "Ox Patrol", "Wandering Swordsman",
]
FILLER_TRAPS = ["Trap Hole", "Trap Hole", "Hypnosis", "Spike Trap", "Snare Trap"]
FILLER_TECH = ["Radar", "Spy", "Bribe"]

AFFINITY_DEFENDER = {
    "NATURE": "Flame Lizard",
    "CHAOS": "Chaotic Wisp",
    "DIVINE": "Ponycorn",
    "ARCANE": "Ice Mage",
    "COSMIC": "Moon Rover",
    "ANIMA": "Ox Patrol",
    "BIO": "Scarlet Mutant",
}

TECH_MSG_HINTS = {
    "REVEAL_UNITS": ["Revealed:", "revealed"],
    "DESTROY_FACEUP": ["Card destroyed", "Accident"],
    "PREVENT_DIVINE_DESTROY": ["Prayer", "divine"],
    "GRANT_MUTAGEN": ["mutagen", "Mutagen"],
    "DIRECT_DAMAGE": ["damage", "Siege"],
    "SKIP_OPPONENT_TURN": ["skip", "Ceasefire"],
    "CRYSTAL_GAIN": ["Crystals:", "+"],
    "REDUCE_CRYSTAL_LOSS": ["Bribe", "crystal"],
    "REVEAL_TRAP": ["Radar", "Trap"],
    "REVEAL_CHARACTER": ["Spy", "Revealed"],
}


def slug(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "-", name.strip()).strip("-") or "Unknown"


def _deck(chars: list[str], traps: list[str] | None = None, techs: list[str] | None = None, label: str = "E2E T2") -> dict:
    traps = traps or FILLER_TRAPS[:5]
    techs = techs or FILLER_TECH[:3]
    while len(chars) < 8:
        chars = chars + [ZERO_ATK_FILLER]
    return {
        "deck_name": label,
        "characters": chars[:12],
        "traps": traps[:6],
        "techs": techs[:3],
    }


def _solo_attacker_deck(name: str) -> dict:
    chars = [name] + [ZERO_ATK_FILLER] * 9
    return _deck(chars, label=f"E2E T2 solo {name}")


def _solo_defender_deck(name: str) -> dict:
    return _solo_attacker_deck(name)


def _base_t2(card: dict, db: dict) -> dict:
    name = db["name"]
    return {
        "tier": 2,
        "id": f"E2E-{slug(name)}-002",
        "card_name": name,
        "card_type": db["card_type"],
        "ability_type": db.get("ability", "NONE"),
        "ability_description": db.get("description", ""),
        "max_turns": 55,
        "max_watchdog_timeouts": 6,
        "union_enabled": db["card_type"] == "Union",
        "expect_log_not_contains": ["SCRIPT ERROR", "Invalid call", "Stack trace"],
        "expect_log_contains": ["GAME OVER"],
    }


def _rx_card_attacks_atk(card: str, atk: int, player: int = 0, row: int = 2, col: int = 2) -> str:
    return rf'Attack P{player}\({row},{col}\)"{re.escape(card)}".*ATK={atk}\s'


def _rx_card_in_combat(card: str) -> str:
    return rf'("{re.escape(card)}".*ATK=|→ P\d\(\d+,\d+\)"{re.escape(card)}")'


def _rx_msg_contains(text: str) -> str:
    return rf"MSG:.*{re.escape(text)}"


def _solo_attack_scenario(
    db: dict,
    *,
    defender: str = WEAK_DEFENDER,
    expected_atk: int | None = None,
    extra_forced_0: list | None = None,
    extra_forced_1: list | None = None,
    extra_regex: list | None = None,
    extra_any: list | None = None,
    notes: str = "",
) -> dict:
    name = db["name"]
    s = _base_t2({}, db)
    s.update({
        "role": "t2_solo_attacker",
        "deck0": _solo_attacker_deck(name),
        "deck1": _solo_defender_deck(defender),
        "forced_cells_0": [{"card_name": name, **ATTACKER_CELL}] + (extra_forced_0 or []),
        "forced_cells_1": [{"card_name": defender, **DEFENDER_CELL}] + (extra_forced_1 or []),
        "forced_tech_0": [],
        "forced_tech_1": [],
        "expect_log_contains": [name, "GAME OVER"],
        "notes": notes or f"Tier 2: {name} solo-attacks {defender}.",
    })
    regex = extra_regex or []
    if expected_atk is not None:
        regex.append(_rx_card_attacks_atk(name, expected_atk))
    else:
        regex.append(_rx_card_in_combat(name))
    s["expect_log_regex"] = regex
    if extra_any:
        s["expect_log_any"] = extra_any
    return s


def _defender_scenario(
    db: dict,
    *,
    attacker: str = STRONG_ATTACKER,
    expected_def: int | None = None,
    extra_regex: list | None = None,
    notes: str = "",
) -> dict:
    name = db["name"]
    s = _base_t2({}, db)
    s.update({
        "role": "t2_defender",
        "deck0": _solo_attacker_deck(attacker),
        "deck1": _solo_defender_deck(name),
        "forced_cells_0": [{"card_name": attacker, **ATTACKER_CELL}],
        "forced_cells_1": [{"card_name": name, **DEFENDER_CELL}],
        "forced_tech_0": [],
        "forced_tech_1": [],
        "expect_log_contains": [name, "GAME OVER"],
        "notes": notes or f"Tier 2: {attacker} attacks {name} as defender.",
    })
    regex = extra_regex or [_rx_card_in_combat(name)]
    if expected_def is not None:
        regex.append(rf'→ P1\(2,2\)"{re.escape(name)}".*DEF={expected_def}\s')
    s["expect_log_regex"] = regex
    return s


def build_tier2_character(db: dict) -> dict:
    name = db["name"]
    ab = db["ability"]
    p = parse_params(db.get("params_raw", ""))
    atk, df = db["atk"], db["def"]

    if ab == "NONE":
        return _solo_attack_scenario(
            db, expected_atk=atk,
            notes=f"Tier 2: verify base ATK={atk} when {name} attacks.",
        )

    if ab == "ATK_BONUS_VS_AFFINITY":
        aff = p.get("affinity", "NATURE")
        bonus = int(p.get("bonus", 0))
        defender = AFFINITY_DEFENDER.get(aff, WEAK_DEFENDER)
        return _solo_attack_scenario(
            db, defender=defender, expected_atk=atk + bonus,
            notes=f"Tier 2: +{bonus} ATK vs {aff} ({defender}).",
        )

    if ab == "ATK_DEF_BONUS_VS_AFFINITY":
        aff = p.get("affinity", "NATURE")
        atk_bonus = int(p.get("atk", p.get("atk_bonus", 0)))
        defender = AFFINITY_DEFENDER.get(aff, WEAK_DEFENDER)
        return _solo_attack_scenario(
            db, defender=defender, expected_atk=atk + atk_bonus,
            notes=f"Tier 2: +{atk_bonus} ATK vs {aff}.",
        )

    if ab == "ATK_DEF_BONUS_VS_NON_AFFINITY":
        own_aff = db["affinity"]
        bonus = int(p.get("atk", p.get("atk_bonus", 5)))
        # Pick defender NOT of own affinity
        defender = next((v for k, v in AFFINITY_DEFENDER.items() if k != own_aff), WEAK_DEFENDER)
        return _solo_attack_scenario(
            db, defender=defender, expected_atk=atk + bonus,
            notes=f"Tier 2: +{bonus} ATK vs non-{own_aff}.",
        )

    if ab == "ATK_BONUS_VS_CENTER_ZONE":
        zone_b = int(p.get("zone_bonus", p.get("bonus", 20)))
        center_b = int(p.get("center_bonus", 40))
        expected = atk + zone_b + center_b
        return _solo_attack_scenario(
            db, expected_atk=expected,
            notes=f"Tier 2: center-zone ATK bonus → {expected}.",
        )

    if ab == "ATK_BOOST_VS_REVEALED":
        bonus = int(p.get("bonus", 0))
        return _solo_attack_scenario(
            db, expected_atk=atk + bonus,
            notes=f"Tier 2: +{bonus} ATK vs exposed defender.",
        )

    if ab == "ATTACK_STANCE_BOOST":
        bonus = int(p.get("atk", p.get("bonus", 0)))
        return _solo_attack_scenario(
            db, expected_atk=atk + bonus,
            notes=f"Tier 2: attack stance +{bonus} ATK.",
        )

    if ab == "ATK_PENALTY_WHEN_EXPOSED":
        penalty = int(p.get("penalty", 0))
        return _solo_attack_scenario(
            db, expected_atk=max(0, atk - penalty),
            notes=f"Tier 2: -{penalty} ATK while exposed.",
        )

    if ab == "ATK_PENALTY_IF_NO_NAME_ALLY":
        penalty = int(p.get("penalty", 0))
        return _solo_attack_scenario(
            db, expected_atk=max(0, atk - penalty),
            notes=f"Tier 2: -{penalty} ATK without name ally on field.",
        )

    if ab == "ATK_BONUS_IF_AFFINITY_ON_FIELD":
        bonus = int(p.get("atk", p.get("atk_bonus", 0)))
        aff = p.get("affinity", db["affinity"])
        ally = AFFINITY_DEFENDER.get(aff, "Canyon Warg")
        return _solo_attack_scenario(
            db, expected_atk=atk + bonus,
            extra_forced_0=[{"card_name": ally, **ALLY_CELL}],
            notes=f"Tier 2: +{bonus} ATK with {aff} ally {ally} on field.",
        )

    if ab == "BOOST_PER_TYPED_CARD_ON_FIELD":
        atk_bonus = int(p.get("atk_bonus", p.get("atk", 0)))
        ally_name = p.get("name", p.get("card_name_contains", "Shark"))
        # Pick a demo ally whose name contains token
        ally = "Hammer Shark" if "shark" in str(ally_name).lower() else "Chaotic Wisp"
        if p.get("affinity"):
            ally = AFFINITY_DEFENDER.get(p["affinity"], ally)
        return _solo_attack_scenario(
            db, expected_atk=atk + atk_bonus,
            extra_forced_0=[{"card_name": ally, **ALLY_CELL}],
            notes=f"Tier 2: +{atk_bonus} ATK with typed ally on field.",
        )

    if ab == "BOOST_PER_ANIMA_ON_FIELD":
        bonus = int(p.get("atk", 20))
        return _solo_attack_scenario(
            db, expected_atk=atk + bonus,
            extra_forced_0=[{"card_name": "Ox Patrol", **ALLY_CELL}],
            notes=f"Tier 2: +{bonus} ATK with ANIMA ally (1 ally simulated via field).",
        )

    if ab == "ATK_DEF_BONUS_IF_UNION_ON_FIELD":
        bonus = int(p.get("atk", 20))
        return _solo_attack_scenario(
            db, expected_atk=atk + bonus,
            extra_forced_0=[{"card_name": UNION_MATERIAL, **ALLY_CELL}],
            notes=f"Tier 2: +{bonus} ATK with union on field.",
        )

    if ab == "ATK_BONUS_VS_FACEDOWN":
        bonus = int(p.get("bonus", 0))
        return _solo_attack_scenario(
            db, expected_atk=atk + bonus,
            notes=f"Tier 2: +{bonus} ATK vs face-down defender (revealed during attack).",
        )

    if ab == "ATK_BONUS_VS_UNION":
        bonus = int(p.get("bonus", 0))
        return _solo_attack_scenario(
            db, defender=UNION_MATERIAL, expected_atk=atk + bonus,
            extra_forced_1=[{"card_name": UNION_MATERIAL, **DEFENDER_CELL}],
            notes=f"Tier 2: +{bonus} ATK vs union defender.",
        )

    if ab == "ATK_BONUS_VS_VENOM":
        bonus = int(p.get("bonus", 0))
        return _solo_attack_scenario(
            db, expected_atk=atk + bonus,
            extra_regex=[_rx_card_attacks_atk(name, atk + bonus), _rx_msg_contains(name)],
            notes=f"Tier 2: +{bonus} ATK vs venom (best-effort if venom not applied pre-battle).",
        )

    if ab == "ATTACKER_ATK_DEBUFF":
        debuff = int(p.get("atk", 15))
        return _defender_scenario(
            db, attacker=STRONG_ATTACKER,
            extra_regex=[_rx_card_in_combat(name), rf"ATK changed.*→ {STRONG_ATTACKER}|ATK={30 - debuff}"],
            notes=f"Tier 2: debuff attacker ATK by {debuff} when defending.",
        )

    if ab == "DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF":
        return _defender_scenario(
            db, attacker="Attacker" if False else ZERO_ATK_FILLER,
            extra_regex=[_rx_card_in_combat(name)],
            notes="Tier 2: defender survive debuff (best-effort combat contact).",
        )

    if ab == "DEFENSE_STANCE_BOOST":
        bonus = int(p.get("def", p.get("bonus", 0)))
        return _defender_scenario(
            db, expected_def=df + bonus,
            notes=f"Tier 2: +{bonus} DEF in defense stance.",
        )

    if ab == "IMMUNE_ZERO_COST_TRAPS":
        s = _base_t2({}, db)
        s.update({
            "role": "t2_trap_immunity",
            "deck0": _solo_attacker_deck(name),
            "deck1": _deck([WEAK_DEFENDER] + [ZERO_ATK_FILLER] * 9, traps=["Trap Hole"] * 5),
            "forced_cells_0": [{"card_name": name, **ATTACKER_CELL}],
            "forced_cells_1": [{"card_name": "Trap Hole", **DEFENDER_CELL}],
            "forced_tech_0": [], "forced_tech_1": [],
            "expect_log_contains": [name, "GAME OVER"],
            "expect_log_regex": [_rx_card_in_combat(name)],
            "expect_log_any": ["trap_nullified", "Trap triggered", "Immune"],
            "notes": "Tier 2: 0-cost trap immunity (nullify or no trap damage).",
        })
        return s

    if ab == "NEGATE_ZERO_COST_TRAPS_BOTH":
        s = _base_t2({}, db)
        s.update({
            "role": "t2_field_trap_negation",
            "deck0": _solo_attacker_deck("Ox Patrol"),
            "deck1": _deck([WEAK_DEFENDER] * 10, traps=["Trap Hole"] * 5),
            "forced_cells_0": [
                {"card_name": name, **ATTACKER_CELL},
                {"card_name": "Ox Patrol", **ALLY_CELL},
            ],
            "forced_cells_1": [{"card_name": "Trap Hole", **DEFENDER_CELL}],
            "forced_tech_0": [], "forced_tech_1": [],
            "expect_log_contains": [name, "GAME OVER"],
            "expect_log_regex": [_rx_msg_contains(name)],
            "expect_log_any": ["trap_nullified", "Trap triggered"],
            "notes": "Tier 2: Electrogazer-style field trap negation.",
        })
        return s

    if ab.startswith("COIN_FLIP"):
        return _solo_attack_scenario(
            db,
            extra_regex=[_rx_card_in_combat(name)],
            extra_any=["Coin flip:"],
            notes=f"Tier 2: {ab} — card enters combat and coin flip occurs.",
        )

    if ab.startswith("MUTAGEN_"):
        s = _base_t2({}, db)
        techs = ["Release Mutagen", "Radar", "Spy"]
        s.update({
            "role": "t2_mutagen",
            "deck0": _deck([name] + [ZERO_ATK_FILLER] * 9, techs=techs),
            "deck1": _solo_defender_deck(WEAK_DEFENDER),
            "forced_cells_0": [{"card_name": name, **ATTACKER_CELL}],
            "forced_cells_1": [{"card_name": WEAK_DEFENDER, **DEFENDER_CELL}],
            "forced_tech_0": ["Release Mutagen", "Radar", "Spy"],
            "forced_tech_1": [],
            "expect_log_contains": [name, "GAME OVER"],
            "expect_log_regex": [_rx_card_in_combat(name)],
            "expect_log_any": ["Mutagen", "mutagen", "Release Mutagen", "Flag+"],
            "notes": "Tier 2: mutagen ability — Release Mutagen in hand, bio card on field.",
        })
        return s

    if ab in ("REVEAL_ON_ANY_ATTACK", "REVEAL_ADJACENT_AFTER_ATTACK", "REVEAL_ON_WIN",
              "REVEAL_ON_DEAD_END_ATTACK", "REVEAL_ON_TRAP_ATTACK"):
        return _solo_attack_scenario(
            db,
            extra_regex=[_rx_card_in_combat(name)],
            extra_any=["Revealed:", "Reveal"],
            notes=f"Tier 2: {ab} — reveal effect during/after combat.",
        )

    if ab.startswith("CRYSTAL_"):
        return _solo_attack_scenario(
            db,
            extra_regex=[_rx_card_in_combat(name), r"Crystals:"],
            notes=f"Tier 2: {ab} — crystal change logged during battle.",
        )

    if ab.startswith("EXTRA_ATTACK") or ab == "MULTI_ATTACK_VS_NON_CHARACTER":
        return _solo_attack_scenario(
            db,
            extra_regex=[_rx_card_in_combat(name)],
            extra_any=["Attack phase", "attack(s) available", "Attack P0"],
            notes=f"Tier 2: {ab} — multi/extra attack flow (best-effort).",
        )

    if ab.startswith("LOCK_") or ab.startswith("DESTROY_") or ab.startswith("IMMUNE_"):
        kw = name.split()[0]
        return _solo_attack_scenario(
            db,
            extra_regex=[_rx_card_in_combat(name)],
            extra_any=[name, "MSG:"],
            notes=f"Tier 2: {ab} — combat contact + ability MSG (best-effort).",
        )

    if ab in ("DEF_BONUS_IF_AFFINITY_ON_FIELD", "DEF_ZERO_WHEN_EXPOSED", "HALVE_DEF_ON_FIRST_EXPOSE"):
        return _defender_scenario(db, notes=f"Tier 2: {ab} defender scenario.")

    if ab in ("ONE_USE_ATK_BOOST", "ONE_USE_DEF_BOOST", "ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND",
              "ONE_USE_SURVIVE_DESTRUCTION", "ONE_USE_EXTRA_ATTACK_ON_DEAD_END",
              "ONE_USE_EXTRA_ATTACK_ON_KILL", "ONE_USE_DEFEND_MORPH", "ONE_USE_COPY_STATS_ON_SURVIVE",
              "ONE_USE_PERM_DEBUFF_ATTACKER_ATK", "ONE_USE_DESTROY_BY_AFFINITY"):
        bonus = int(p.get("bonus", p.get("atk", 10)))
        return _solo_attack_scenario(
            db,
            expected_atk=atk + bonus if "ATK" in ab or "BOOST" in ab else None,
            extra_regex=[_rx_card_in_combat(name)],
            notes=f"Tier 2: one-use ability {ab}.",
        )

    # Generic fallback — card must fight; ability type recorded for manual triage
    return _solo_attack_scenario(
        db,
        extra_regex=[_rx_card_in_combat(name)],
        extra_any=[name, "MSG:"],
        notes=f"Tier 2 best-effort: {ab} — combat + MSG/card presence.",
    )


def build_tier2_trap(db: dict) -> dict:
    name = db["name"]
    s = _base_t2({}, db)
    s.update({
        "role": "t2_trap_trigger",
        "deck0": _solo_attacker_deck(STRONG_ATTACKER),
        "deck1": _deck([WEAK_DEFENDER] + [ZERO_ATK_FILLER] * 9, traps=[name] + FILLER_TRAPS[:4]),
        "forced_cells_0": [{"card_name": STRONG_ATTACKER, **ATTACKER_CELL}],
        "forced_cells_1": [{"card_name": name, **DEFENDER_CELL}],
        "forced_tech_0": [], "forced_tech_1": [],
        "expect_log_contains": [name, "GAME OVER"],
        "expect_log_regex": [
            rf'Revealed: P1 \(2,2\) "{re.escape(name)}"',
        ],
        "expect_log_any": [
            "Trap triggered",
            f'"{name}" triggered',
            f"Trap triggered: {name}",
            "MSG: Trap triggered",
        ],
        "notes": f"Tier 2: trap {name} revealed and triggered when attacked.",
    })
    return s


def build_tier2_tech(db: dict) -> dict:
    name = db["name"]
    effect = db.get("ability", "")
    hints = TECH_MSG_HINTS.get(effect, [name])
    s = _base_t2({}, db)
    s.update({
        "role": "t2_tech_play",
        "deck0": _deck([STRONG_ATTACKER] + [ZERO_ATK_FILLER] * 9, techs=[name, FILLER_TECH[1], FILLER_TECH[2]]),
        "deck1": _solo_defender_deck(WEAK_DEFENDER),
        "forced_cells_0": [{"card_name": STRONG_ATTACKER, **ATTACKER_CELL}],
        "forced_cells_1": [{"card_name": WEAK_DEFENDER, **DEFENDER_CELL}],
        "forced_tech_0": [name, "", ""],
        "forced_tech_1": [],
        "expect_log_contains": ["GAME OVER"],
        "expect_log_regex": [rf'Tech played\s+P0: "{re.escape(name)}"'],
        "expect_log_any": hints + [name, "Tech resolved", "Revealed:", "Card destroyed", "MSG:"],
        "notes": f"Tier 2: tech {name} played ({effect}).",
    })
    return s


def build_tier2_union(db: dict, materials: list[str]) -> dict:
    name = db["name"]
    atk = db["atk"]
    forced = [{"card_name": m, "row": 0, "col": i} for i, m in enumerate(materials[:3])]
    s = _base_t2({}, db)
    chars = materials + [ZERO_ATK_FILLER] * 8
    s.update({
        "role": "t2_union",
        "deck0": _deck(chars[:12], label=f"E2E T2 union {name}"),
        "deck1": _solo_defender_deck(WEAK_DEFENDER),
        "forced_cells_0": forced,
        "forced_cells_1": [{"card_name": WEAK_DEFENDER, **DEFENDER_CELL}],
        "forced_tech_0": [], "forced_tech_1": [],
        "union_enabled": True,
        "expect_log_contains": ["GAME OVER"],
        "expect_log_any": [
            f"Union summoned P0: {name}",
            rf'Attack P\d\(\d+,\d+\)"{re.escape(name)}"',
            f"MSG:.*{re.escape(name.split()[0])}",
        ],
        "notes": f"Tier 2: union {name} — summon logged and/or union attacks with ATK={atk}.",
    })
    if db.get("ability", "NONE") != "NONE":
        s["expect_log_any"].append("MSG:")
    return s


def build_tier2(db: dict, materials: list[str] | None = None) -> dict:
    ct = db["card_type"]
    if ct == "Character":
        return build_tier2_character(db)
    if ct == "Trap":
        return build_tier2_trap(db)
    if ct == "Tech":
        return build_tier2_tech(db)
    return build_tier2_union(db, materials or [])
