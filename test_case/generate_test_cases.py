#!/usr/bin/env python3
"""Generate AI Agent Tester test cases from card_data.xlsx (Demo=Yes only)."""

import re
import openpyxl
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
XLSX = ROOT / "context" / "card_data.xlsx"
OUT = Path(__file__).resolve().parent

# Priority tiers — complex cards tested first
PRIORITY_UNIONS = [
    "X-Death Squad", "Burning Phoenix", "Giant Meteor Vergaia", "Seraphim Fistmaster",
    "Armored Dino", "Rocket Peacock", "False Prophet", "Moon Tribe Shaman",
    "Blood-hungry Mutant", "Volatile Slasher", "Ten Arms Yaksa", "Sky Protector",
    "Scarlet Shroom", "Rebel King", "Lord of Terror", "Colorful Mage",
    "Greater Succubus", "Kiba the Giant Slayer", "Choir Lead Amber", "Pixie Queen",
]
PRIORITY_CHARACTERS = [
    "Lab Bloater", "Lab Crawler", "Lab Zombie", "Plant-29", "Goddess of Virtue",
    "Pit Lord", "Archbishop", "Electrogazer", "Immortal Vampire", "Vampire Duchess",
    "Blue Mage", "Satellite Cannon", "Death Cobra", "Giant Centipede", "Tiny Pixie",
    "Tomb Bandit", "Araya the Eerie Dancer", "Bat Swarm", "Nuki the Tanuki",
    "Melissa the Healer", "Grave Worm", "Succubus", "Poltergeist", "Bladeshifter",
    "Hairpin Assassin", "Leopard Jailer", "Mine Guard", "Vampire Servant",
    "Pyromancer", "Angel Gatekeeper", "Echo Bringer", "Golden Senju",
]
PRIORITY_TRAPS = [
    "Brainwash", "Explosive Barrels", "Spike Trap", "Snare Trap", "Self-destruct",
    "Decoy Puppet", "Blackmail", "Echo Barrier", "Bunker", "Hostage",
    "Defensive Pheromone", "Cursed Reflection", "Trap Hole",
]
PRIORITY_TECH = [
    "Release Mutagen", "Resurrection", "Siege Cannon", "Accident", "Prayer",
    "Bribe", "Great Diplomacy", "War Supply", "Spy", "Radar",
]


def slug(name: str) -> str:
    s = re.sub(r"[^A-Za-z0-9]+", "-", name.strip()).strip("-")
    return s or "Unknown"


def load_demo_cards():
    wb = openpyxl.load_workbook(XLSX, data_only=True)
    cards = []
    for sheet in ["Unit", "Tech", "Trap", "Union"]:
        ws = wb[sheet]
        rows = list(ws.iter_rows(values_only=True))
        headers = [str(h).strip() if h else "" for h in rows[1]]
        demo_idx = headers.index("Demo")
        for row in rows[2:]:
            if not row or not row[0]:
                continue
            if not row[demo_idx] or str(row[demo_idx]).strip().lower() != "yes":
                continue
            card = {h: row[i] for i, h in enumerate(headers) if h and i < len(row) and row[i] is not None}
            card["_sheet"] = "Character" if sheet == "Unit" else sheet
            cards.append(card)
    return cards


def card_type_key(card: dict) -> str:
    t = str(card.get("Card Type", card["_sheet"])).strip()
    if t == "Unit":
        return "Character"
    return t


def ability_text(card: dict) -> str:
    parts = []
    for k in ("Ability", "Partial Ability", "Full Ability"):
        v = card.get(k)
        if v and str(v).strip() and str(v).strip().lower() not in ("none", ""):
            parts.append(str(v).strip())
    return " | ".join(dict.fromkeys(parts)) if parts else "None"


def formula_text(card: dict) -> str:
    for k in ("Full Formula", "Partial Formula", "Formula"):
        v = card.get(k)
        if v and str(v).strip():
            return str(v).strip()
    return ""


def sort_key(card: dict, priority_list: list) -> tuple:
    name = card.get("Card Name", "")
    try:
        pri = priority_list.index(name)
    except ValueError:
        pri = 999
    ab = ability_text(card)
    complexity = 0 if ab == "None" else len(ab)
    return (pri, -complexity, name)


def fmt_case(case_id: str, desc: str, pre: list, steps: list, expected: list) -> str:
    lines = [
        f"Test Case ID: {case_id}",
        "Description:",
        desc,
        "Preconditions:",
    ]
    for p in pre:
        lines.append(f"- {p}")
    lines.append("Steps:")
    for i, s in enumerate(steps, 1):
        lines.append(f"Step {i}: {s}")
    lines.append("Expected Result:")
    for e in expected:
        lines.append(f"- {e}")
    return "\n".join(lines)


def base_preconditions(card: dict, extra: list | None = None) -> list:
    ctype = card_type_key(card)
    pre = [
        "Start a new battle (Daily Dungeon or battle_test scene). Both players begin with 5000 crystals unless testing low-crystal edge cases.",
        f"Ensure '{card.get('Card Name')}' is in the active player's deck/hand and loaded in CardDatabase.",
        "Board is 5×5 per side; place supporting cards face-down unless the test requires face-up exposure.",
    ]
    if ctype == "Union":
        pre.append("Union summon limit: once per duel per player. Clear prior union summons if re-testing.")
    if extra:
        pre.extend(extra)
    return pre


def generate_character_cases(card: dict) -> list[str]:
    name = card["Card Name"]
    sid = slug(name)
    ab = ability_text(card)
    cost = card.get("Cost", "?")
    atk = card.get("ATK", "?")
    df = card.get("DEF", "?")
    aff = card.get("Affinity", "?")
    cases = []

    header = f"""Card Name: {name}
Type: Character
Stats: Cost={cost} ATK={atk} DEF={df} Affinity={aff}
Ability: {ab}
Test Cases:
"""

    tc = 1

    def add(desc, pre_extra, steps, expected):
        nonlocal tc
        cid = f"TC-{sid}-{tc:03d}"
        tc += 1
        pre = base_preconditions(card, pre_extra)
        cases.append(fmt_case(cid, desc, pre, steps, expected))

    # Universal baseline
    add(
        f"Happy path — {name} attacks and wins a standard battle.",
        [
            f"Place {name} face-up on Player 0 row 2 col 2 (center-adjacent).",
            "Place opponent Wandering Swordsman (60 ATK / 60 DEF) face-up at Player 1 row 2 col 2.",
        ],
        [
            f"End setup phase. Player 0 selects {name} as attacker targeting opponent character.",
            "Confirm battle calculation overlay shows effective ATK/DEF.",
            "Complete the attack and observe post-battle state.",
        ],
        [
            f"{name} participates in battle resolution without errors.",
            "Winner/loser destruction and crystal loss follow standard rules.",
            "Ability-related messages appear in battle log if applicable.",
        ],
    )

    add(
        f"Edge — {name} placed face-down, revealed on attack.",
        [
            f"Place {name} face-down on Player 0 field.",
            "Opponent has a face-down defender.",
        ],
        [
            f"Attack with another unit or reveal {name} via Tech (Spy/Radar) first if needed.",
            f"Attack opponent cell with {name}.",
        ],
        [
            f"{name} reveals correctly on attack.",
            "Face-down state does not break ability triggers that depend on exposure timing.",
        ],
    )

    if ab == "None":
        add(
            f"Baseline — {name} defends successfully.",
            ["Opponent has a weak attacker (Chaotic Wisp 20 ATK)."],
            [f"Opponent attacks {name}.", "Resolve defense."],
            [f"{name} survives if DEF ({df}) exceeds attacker ATK.", "No special post-battle effects fire."],
        )
        return [header] + cases

    ab_lower = ab.lower()

    # Pattern-based generators
    if "mutagen flag" in ab_lower:
        add(
            f"Mutagen — {name} with has_mutagen_flag active.",
            [
                "Player 0 has Release Mutagen in hand.",
                f"Place face-up Bio character {name} on field.",
            ],
            [
                f"Play Release Mutagen; select {name}.",
                "Verify mutagen flag icon appears on card.",
                f"Trigger combat scenario described: {ab}",
            ],
            [
                "has_mutagen_flag is true (not merely 'mutogen' string in flags array).",
                "Mutagen-granted ability activates per card text.",
            ],
        )
        add(
            f"Mutagen edge — {name} WITHOUT mutagen flag.",
            [f"Place {name} face-up without using Release Mutagen."],
            ["Attempt the mutagen-dependent action or battle."],
            ["Mutagen-specific bonus/effect does NOT apply."],
        )

    if "venom flag" in ab_lower:
        add(
            f"Venom — {name} vs venom-flagged target.",
            ["Apply venom flag to opponent character (via Death Cobra end-of-turn or manual test setup)."],
            [f"Attack venom-flagged target with {name}."],
            ["Venom-related ATK/DEF bonus applies during battle calculation."],
        )

    if "trap" in ab_lower and ("immune" in ab_lower or "not affected" in ab_lower or "negate" in ab_lower):
        add(
            f"Trap immunity — {name} vs zero-cost trap.",
            [
                "Opponent has Trap Hole (0 cost) face-down.",
                f"{name} on attacker's field.",
            ],
            [f"Attack Trap Hole with {name}."],
            [
                "Trap is nullified or attacker is not destroyed per immunity text.",
                "Attacker survives; crystal drain may or may not apply per exact ability.",
            ],
        )

    if "tech" in ab_lower and ("immune" in ab_lower or "not affected" in ab_lower or "unaffected" in ab_lower):
        add(
            f"Tech immunity — opponent plays Tech targeting {name}.",
            ["Opponent has Accident or Siege Cannon in hand.", f"{name} face-up on field."],
            [f"Opponent plays Tech selecting {name} if possible."],
            [f"{name} is unaffected; no destruction or debuff from Tech."],
        )

    if "vs" in ab_lower and "affinity" in ab_lower:
        add(
            f"Affinity bonus — {name} vs matching affinity defender.",
            ["Place defender with affinity mentioned in ability text."],
            [f"Attack with {name}; inspect battle overlay effective ATK."],
            ["Affinity conditional bonus is included in effective ATK/DEF."],
        )
        add(
            f"Affinity bonus absent — {name} vs non-matching affinity.",
            ["Use defender outside the stated affinity."],
            [f"Attack with {name}."],
            ["Bonus does NOT apply; stats match base + non-affinity modifiers only."],
        )

    if "union" in ab_lower:
        add(
            f"Union interaction — {name} vs Union target.",
            ["Summon a Demo Union (e.g. Gryphon Rider) on opponent field face-up."],
            [f"Attack the Union card with {name}."],
            ["Union-specific ATK/DEF modifiers apply during calculation."],
        )

    if "dead end" in ab_lower:
        add(
            f"Dead end attack — {name} hits empty/dead-end cell.",
            ["Mark a cell as dead_end or attack blank revealed cell."],
            [f"Attack dead-end with {name}."],
            ["Dead-end post-attack effect triggers (extra attack, crystal gain, reveal, etc.)."],
        )

    if "coin" in ab_lower or "flip" in ab_lower:
        add(
            f"Coin flip — {name} ability resolution.",
            ["Note: coin flip uses RNG; run multiple iterations or log outcomes."],
            [f"Trigger battle/turn event that activates coin flip for {name}."],
            ["On heads: positive branch occurs. On tails: alternate branch or no effect per card text."],
        )

    if "destroy" in ab_lower and "instead" in ab_lower:
        add(
            f"Sacrifice redirect — {name} intercepts ally destruction.",
            [
                "Place qualifying ally on field per card text (same name/affinity/type).",
                f"Place {name} face-up (or face-down if text allows).",
            ],
            ["Trigger destruction on the ally (Tech, battle loss, trap)."],
            [f"{name} is destroyed instead; ally survives if conditions met."],
        )

    if "defend" in ab_lower:
        add(
            f"Defend scenario — {name} as defender.",
            [f"Opponent attacks {name}."],
            ["Resolve defense; check defend-only crystal/stat effects."],
            ["Defend-triggered permanent/temporary stat changes apply to attacker or self."],
        )

    if "expose" in ab_lower or "face-up" in ab_lower or "face-down" in ab_lower:
        add(
            f"Exposure edge — {name} face-up vs face-down states.",
            ["Run once with defender face-up before attack; once face-down until reveal."],
            [f"Attack with {name} each time."],
            ["Exposure-dependent ATK/DEF modifiers differ correctly between scenarios."],
        )

    if "crystal" in ab_lower:
        add(
            f"Crystal interaction — {name} crystal gain/loss/drain.",
            ["Record crystal totals before trigger."],
            [f"Trigger ability: {ab}"],
            ["Crystal delta matches card text; respects insufficient-crystal edge cases where payment is optional."],
        )

    if "end of" in ab_lower and "turn" in ab_lower:
        add(
            f"End-of-turn — {name} turn boundary effect.",
            [f"{name} survives to end of relevant turn."],
            ["End turn; observe end-of-turn processing."],
            ["Turn-end stat changes, flags, or self-destruct occur as specified."],
        )

    if "cannot attack" in ab_lower or "lock" in ab_lower:
        add(
            f"Attack lock — {name} or target attack restriction.",
            ["Trigger the lock condition via battle."],
            ["Attempt additional attack on locked unit next turn."],
            ["Locked character cannot be selected as attacker until restriction expires."],
        )

    if "optional" in ab_lower or "pay" in ab_lower and "crystal" in ab_lower:
        add(
            f"Optional crystal pay — {name} with insufficient crystals.",
            ["Reduce Player 0 crystals below required pay amount."],
            [f"Enter battle with {name}; decline/accept crystal payment prompt."],
            ["Insufficient crystals: payment skipped, no bonus. Sufficient: bonus applies."],
        )

    if "reveal" in ab_lower:
        add(
            f"Reveal effect — {name} post-attack/ability reveal.",
            ["Opponent has multiple face-down cells."],
            [f"Trigger reveal via {name}'s ability."],
            ["Correct number of opponent/own cells revealed; selection UI works."],
        )

    if "swap" in ab_lower and ("position" in ab_lower or "atk" in ab_lower):
        add(
            f"Swap — {name} position or stat swap.",
            ["Set up field with swappable targets."],
            [f"Activate swap condition for {name}."],
            ["Positions or ATK/DEF swap correctly; no orphaned grid references."],
        )

    if "extra attack" in ab_lower or "attack again" in ab_lower or "attack twice" in ab_lower:
        add(
            f"Multi-attack — {name} chained attacks.",
            ["Ensure attacks_remaining > 0.", f"Meet condition for extra attack ({ab})."],
            [f"After first successful attack, attempt second attack same turn."],
            ["Second attack allowed once per text; attacks_remaining decrements correctly."],
        )

    if "center" in ab_lower and "zone" in ab_lower:
        add(
            f"Center zone — {name} attacks center vs edge.",
            ["Place defenders at (2,2), (2,1), and (0,0) on opponent grid."],
            [f"Attack each cell with {name}; compare overlay ATK."],
            ["+20 ATK in 3×3 center; +40 additional at exact center (2,2)."],
        )

    if "full board" not in ab_lower:
        add(
            f"Edge — low crystals during {name} battle.",
            ["Set Player 0 crystals to 100."],
            [f"Attack/defend with {name} and lose card (crystal cost payment)."],
            ["Crystal total floors at 0; game does not crash on bankruptcy."],
        )

    return [header] + cases


def generate_trap_cases(card: dict) -> list[str]:
    name = card["Card Name"]
    sid = slug(name)
    ab = ability_text(card)
    cost = card.get("Cost", 0)
    header = f"""Card Name: {name}
Type: Trap
Cost: {cost}
Ability: {ab}
Test Cases:
"""
    cases = []
    tc = 1

    def add(desc, pre_extra, steps, expected):
        nonlocal tc
        cid = f"TC-{sid}-{tc:03d}"
        tc += 1
        pre = base_preconditions(card, pre_extra)
        cases.append(fmt_case(cid, desc, pre, steps, expected))

    add(
        f"Happy path — opponent attacks {name}.",
        [
            f"Place {name} face-down on Player 1 field.",
            "Player 0 has an attacker ready.",
        ],
        [
            "Player 0 attacks the trap cell.",
            f"Trap reveals and {ab} resolves.",
        ],
        [
            "Trap effect applies to attacker/active player as described.",
            "Trap is consumed/destroyed after activation unless otherwise stated.",
        ],
    )

    add(
        f"Immunity — Huntress of Green Glade / Laser Walker / Electrogazer vs {name}.",
        [
            "Player 0 has trap-immune character.",
            f"{name} face-down on opponent field.",
        ],
        ["Attack trap with immune character."],
        ["Zero-cost trap nullified if applicable; attacker not destroyed by trap effect."],
    )

    if cost == 0 or str(cost) == "0":
        add(
            f"Zero-cost — Electrogazer negates {name} on field.",
            ["Player 1 has Electrogazer face-up.", f"{name} face-down on Player 1 field."],
            ["Player 0 attacks another target; verify negation state."],
            ["Zero-cost trap on both fields negated while Electrogazer is active."],
        )

    if "crystal" in ab.lower():
        add(
            f"Crystal drain — {name} reduces attacker crystals.",
            ["Record Player 0 crystals before trap trigger."],
            ["Attack trap; resolve drain."],
            ["Crystal total decreases by stated amount (20/50/etc.)."],
        )

    if "destroy" in ab.lower() and "attack" in ab.lower():
        add(
            f"Destroy attacker — {name} kills attacker.",
            ["Use high-value attacker (Pit Lord 1200 cost)."],
            ["Attack trap."],
            ["Attacker destroyed; defender crystal loss rules per Explosive Barrels/Spike Trap text."],
        )

    if "reveal" in ab.lower():
        add(
            f"Reveal — {name} reveals cells.",
            ["Multiple face-down cells adjacent or on field."],
            ["Trigger trap via attack."],
            ["Correct cells revealed; Hostage/Bait selection flows work."],
        )

    if "coin" in ab.lower():
        add(
            f"Coin flip — {name} probabilistic debuff.",
            ["Run multiple trap activations."],
            ["Observe heads/tails branches for ATK debuff or attack lock."],
            [
                "Heads branch applies debuff or attack lock per card text.",
                "Tails branch applies alternate or no effect.",
            ],
        )

    if "cannot attack" in ab.lower() or "end the turn" in ab.lower():
        add(
            f"Turn control — {name} attack/turn restriction.",
            ["Trigger trap mid-turn with attacks remaining."],
            ["Verify turn ends or next-turn attack lock on attacker."],
            ["Attacker cannot attack next turn OR turn ends immediately per Blackmail choice."],
        )

    add(
        f"Edge — {name} attacked by face-up vs face-down attacker path.",
        ["Repeat with attacker revealed before combat."],
        ["Attack trap."],
        ["Trap activates identically regardless of attacker exposure state."],
    )

    return [header] + cases


def generate_tech_cases(card: dict) -> list[str]:
    name = card["Card Name"]
    sid = slug(name)
    ab = ability_text(card)
    cost = card.get("Cost", 0)
    header = f"""Card Name: {name}
Type: Tech
Cost: {cost}
Ability: {ab}
Test Cases:
"""
    cases = []
    tc = 1

    def add(desc, pre_extra, steps, expected):
        nonlocal tc
        cid = f"TC-{sid}-{tc:03d}"
        tc += 1
        pre = base_preconditions(card, pre_extra)
        cases.append(fmt_case(cid, desc, pre, steps, expected))

    add(
        f"Happy path — play {name} during MODE_SELECT.",
        [
            f"{name} in Player 0 hand.",
            f"Player 0 has ≥ {cost} crystals.",
        ],
        [
            f"Enter tech play phase; select {name} from hand.",
            "Pay cost; complete any target selection.",
        ],
        [
            f"Effect resolves: {ab}",
            "Tech card removed from hand; crystals deducted.",
        ],
    )

    if cost == 0 or str(cost) == "0":
        add(
            f"Zero-cost — {name} with 0 crystals.",
            ["Set Player 0 crystals to 0."],
            [f"Play {name}."],
            ["Tech resolves at zero cost without error."],
        )

    if "reveal" in ab.lower():
        add(
            f"Reveal — {name} target selection.",
            ["Opponent has ≥3 face-down cells."],
            [f"Play {name}; select valid target cell(s)."],
            ["Selected cell(s) become face-up; hidden info updates for both players."],
        )

    if "mutagen" in ab.lower():
        add(
            f"Mutagen — {name} on Bio character.",
            ["Place Lab Zombie face-down.", "Place non-Bio character face-down."],
            [f"Play {name}; attempt to select each."],
            ["Only Bio character eligible; has_mutagen_flag set true on success."],
        )

    if "destroy" in ab.lower():
        add(
            f"Destroy — {name} removal without crystal loss.",
            ["Multiple face-up characters on field."],
            [f"Play {name}; destroy target."],
            ["Target removed; owner does NOT pay crystal cost for destroyed card."],
        )

    if "revive" in ab.lower() or "resurrection" in ab.lower():
        add(
            f"Revive — {name} once-per-duel limit.",
            ["Destroy a character earlier in the duel.", "Empty cell available."],
            [f"Play {name}; revive to empty cell."],
            ["Character returns face-up ATK=0 ability=None; second play blocked if once-only."],
        )

    if "skip" in ab.lower() or "turn" in ab.lower():
        add(
            f"Turn skip — {name} tax interaction.",
            ["Player has not attacked this turn."],
            [f"Play {name}."],
            ["Both players skip turns; crystal tax still applies on subsequent skipped attacks."],
        )

    if "bribe" in ab.lower() or "choose" in ab.lower() or "opponent" in ab.lower():
        add(
            f"Opponent choice — {name} decision branch.",
            ["Opponent has face-down and face-up options."],
            [f"Player 0 plays {name}; opponent chooses branch."],
            ["Each branch resolves correctly (reveal+crystals vs do nothing)."],
        )

    add(
        f"Edge — {name} with full board.",
        ["All placement cells occupied where applicable."],
        [f"Attempt to play {name}."],
        ["Invalid targets disabled; no soft-lock in target selection UI."],
    )

    return [header] + cases


def generate_union_cases(card: dict) -> list[str]:
    name = card["Card Name"]
    sid = slug(name)
    partial = card.get("Partial Ability") or "None"
    full = card.get("Full Ability") or partial
    formula = formula_text(card)
    atk = card.get("ATK", "?")
    df = card.get("DEF", "?")
    aff = card.get("Affinity", "?")
    header = f"""Card Name: {name}
Type: Union
Stats: ATK={atk} DEF={df} Affinity={aff}
Partial Ability: {partial}
Full Ability: {full}
Summon Formula: {formula}
Test Cases:
"""
    cases = []
    tc = 1

    def add(desc, pre_extra, steps, expected):
        nonlocal tc
        cid = f"TC-{sid}-{tc:03d}"
        tc += 1
        pre = base_preconditions(card, pre_extra)
        cases.append(fmt_case(cid, desc, pre, steps, expected))

    add(
        f"Summon happy path — {name} union placement.",
        [
            f"Gather material cards per formula: {formula}",
            "Player 0 has sufficient crystals for summon cost.",
            "Material cells marked in union zone pattern (5×5 bitmask).",
        ],
        [
            "Enter union summon mode; select materials matching formula.",
            f"Pay crystal cost; place {name} face-up at anchor cell.",
        ],
        [
            f"{name} appears as is_union=true, face-up.",
            "Material cards removed from grid without crystal loss.",
            "Union summon consumed for this duel (cannot summon second union).",
        ],
    )

    add(
        f"Edge — insufficient crystals for {name}.",
        ["Set crystals below required summon cost.", "Valid materials on field."],
        ["Attempt union summon."],
        ["Summon blocked; materials remain; no partial state."],
    )

    add(
        f"Edge — wrong materials for {name}.",
        ["Place non-qualifying characters in zone."],
        ["Attempt union summon."],
        ["Formula validation fails; summon does not proceed."],
    )

    ab = full if full and str(full).lower() != "none" else partial
    if ab and str(ab).lower() != "none":
        add(
            f"Ability — {name} full ability in battle.",
            [f"{name} summoned and face-up.", "Opponent has valid battle target."],
            [f"Attack or defend with {name}; verify: {full}"],
            ["Full (not partial) ability text applies after union summon."],
        )

    ab_lower = str(ab).lower()
    if "pay" in ab_lower and "crystal" in ab_lower:
        add(
            f"Optional pay — {name} battle calculation prompt.",
            ["Crystals above and below pay threshold."],
            [f"Enter battle with {name}; accept/decline pay prompt."],
            ["Paid branch grants stat bonus; unpaid branch uses base stats."],
        )

    if "destroy" in ab_lower:
        add(
            f"Destruction — {name} destroy effects.",
            ["Set up valid destroy targets per ability."],
            [f"Trigger destroy via battle or tech targeting {name}."],
            ["Destroy immunity or destroy-on-tech behavior matches full ability."],
        )

    if "revive" in ab_lower or "upon union" in ab_lower:
        add(
            f"On-summon — {name} immediate effect.",
            ["Prepare empty cell and valid revive target in graveyard/state."],
            [f"Complete union summon of {name}."],
            ["On-summon effect (revive, venom flags, etc.) fires once."],
        )

    if "coin" in ab_lower:
        add(
            f"Coin flip — {name} post-battle/on-summon RNG.",
            ["Run multiple iterations."],
            [f"Trigger coin flip for {name}."],
            ["Heads/tails branches match Rocket Peacock / False Prophet text."],
        )

    add(
        f"Battle — {name} as defender vs character.",
        ["Opponent character attacks union."],
        ["Resolve battle with union stats."],
        ["Union uses character battle rules; is_union flag preserved."],
    )

    return [header] + cases


GENERATORS = {
    "Character": generate_character_cases,
    "Tech": generate_tech_cases,
    "Trap": generate_trap_cases,
    "Union": generate_union_cases,
}

PRIORITY = {
    "Character": PRIORITY_CHARACTERS,
    "Tech": PRIORITY_TECH,
    "Trap": PRIORITY_TRAPS,
    "Union": PRIORITY_UNIONS,
}


def write_type_file(card_type: str, cards: list[dict]) -> None:
    gen = GENERATORS[card_type]
    priority = PRIORITY[card_type]
    sorted_cards = sorted(cards, key=lambda c: sort_key(c, priority))
    parts = [
        f"# {card_type} Card Test Cases (Demo = Yes)\n",
        f"Total cards: {len(sorted_cards)}\n",
        "Ordered by complexity/priority (most complex first).\n",
        "---\n",
    ]
    for card in sorted_cards:
        blocks = gen(card)
        parts.append("\n\n".join(blocks))
        parts.append("\n---\n")
    out_path = OUT / card_type.lower() / f"{card_type.lower()}_demo_test_cases.md"
    out_path.write_text("\n".join(parts), encoding="utf-8")
    print(f"Wrote {out_path} ({len(sorted_cards)} cards)")


TYPE_FILES = {
    "Character": "character/character_demo_test_cases.md",
    "Tech": "tech/tech_demo_test_cases.md",
    "Trap": "trap/trap_demo_test_cases.md",
    "Union": "union/union_demo_test_cases.md",
}


def collect_manifest_ids() -> list[str]:
    manifest: list[str] = []
    for rel in TYPE_FILES.values():
        text = (OUT / rel).read_text(encoding="utf-8")
        for m in re.finditer(r"Test Case ID: (TC-[^\n]+)", text):
            tc_id = m.group(1)
            if tc_id.startswith("TC-FUNC-"):
                continue
            manifest.append(tc_id)
    return manifest


def write_manifest(ids: list[str]) -> None:
    (OUT / "test_case_manifest.txt").write_text("\n".join(ids) + "\n", encoding="utf-8")
    print(f"Wrote test_case_manifest.txt ({len(ids)} IDs)")


def write_index(all_cards: list[dict], total_tc_count: int) -> None:
    by_type = {}
    for c in all_cards:
        t = card_type_key(c)
        by_type.setdefault(t, []).append(c["Card Name"])

    lines = [
        "# AI Agent Tester — Card Effect Test Suite",
        "",
        "Generated from `context/card_data.xlsx` filtering **Demo = Yes** only.",
        "",
        f"**Total demo cards:** {len(all_cards)}",
        "",
        "## Card counts",
        "",
    ]
    for t in sorted(by_type):
        lines.append(f"- **{t}**: {len(by_type[t])}")
    lines.extend([
        "",
        "## Test case files",
        "",
        "| File | Description |",
        "|------|-------------|",
        "| [test_framework.md](./test_framework.md) | Shared setup, Godot execution guide, verification checklist |",
    ])
    for t in sorted(TYPE_FILES):
        if t in by_type:
            rel = TYPE_FILES[t]
            lines.append(
                f"| [{rel}](./{rel}) | {len(by_type[t])} {t.lower()} cards |"
            )
    lines.extend([
        f"| [test_case_manifest.txt](./test_case_manifest.txt) | Flat list of all {total_tc_count} test case IDs for progress tracking |",
        "| [generate_test_cases.py](./generate_test_cases.py) | Regenerator script (re-run after Excel updates) |",
        "",
        "## Functional tests (code-accurate)",
        "",
        "Derived from `CardDatabase.gd`, `UnionDatabase.gd`, `BattleResolver.gd`, `TurnManager.gd`:",
        "",
        "| File | Description |",
        "|------|-------------|",
        "| [functional/implementation_index.md](./functional/implementation_index.md) | AbilityType → handler mapping |",
        "| [functional/character_functional_tests.md](./functional/character_functional_tests.md) | Code-precise character tests |",
        "| [functional/trap_functional_tests.md](./functional/trap_functional_tests.md) | TrapEffectType handler tests |",
        "| [functional/tech_functional_tests.md](./functional/tech_functional_tests.md) | TechEffectType handler tests |",
        "| [functional/union_functional_tests.md](./functional/union_functional_tests.md) | Union summon + ability tests |",
        "| [functional/functional_test_manifest.txt](./functional/functional_test_manifest.txt) | All TC-FUNC-* IDs |",
        "| [generate_functional_tests.py](./generate_functional_tests.py) | Regenerate functional suite |",
        "",
        "## Automated unit tests (Godot headless)",
        "",
        "From the **repository root**, run:",
        "",
        "```bash",
        "godot --headless --script tests/test_runner.gd",
        "```",
        "",
        "**What it does:** Starts Godot without a window, loads `tests/test_runner.gd`, and runs every unit test suite in order. Each suite prints `PASS` / `FAIL` lines to the terminal. When all suites finish, the process exits automatically.",
        "",
        "**Suites executed:**",
        "",
        "1. `tests/test_dice_roller.gd`",
        "2. `tests/test_card_database.gd`",
        "3. `tests/test_game_state.gd`",
        "4. `tests/test_battle_resolver.gd`",
        "5. `tests/test_func_characters.gd` — character `TC-FUNC-*` ability tests",
        "6. `tests/test_func_traps.gd`",
        "7. `tests/test_func_techs.gd`",
        "8. `tests/test_func_unions.gd`",
        "",
        "**Use this when:** You changed card data, battle logic, or functional tests and want a quick check that core rules still pass.",
        "",
        "**Not covered:** Full UI battle flow, union summon UI, coin-flip RNG, and other manual cases in the markdown suites above. Those still require live sessions or agent UI testing per `test_framework.md`.",
        "",
        "**Requires:** Godot 4.x on your `PATH` (or substitute the full path to your Godot binary).",
        "",
        "## Card E2E (full UI / AI vs AI)",
        "",
        "Two tiers per demo card — see [e2e/README.md](./e2e/README.md) for full docs.",
        "",
        "| Tier | ID | Checks |",
        "|------|-----|--------|",
        "| 1 | `E2E-*-001` | Smoke: battle completes, card in log |",
        "| 2 | `E2E-*-002` | Ability: forced setup + ATK/trap/tech/union log assertions |",
        "",
        "```bash",
        "python3 test_case/e2e/generate_e2e_scenarios.py   # regenerate 406 scenarios",
        "```",
        "",
        "**In-game:** AI vs AI → Run All / Tier 1 Smoke / Tier 2 Ability",
        "",
        "**Admin:** `card_e2e` | `card_e2e t1` | `card_e2e t2` | `card_e2e reset`",
        "",
        "Progress: `user://card_e2e_progress.json` (resume supported).",
        "",
        "## Execution order (recommended)",
        "",
        "1. Read `test_framework.md` for battle system conventions.",
        "2. Run **Union** tests (summoning + complex abilities).",
        "3. Run **Trap** and **Tech** interaction tests.",
        "4. Run **Character** tests starting from top of file (priority sorted).",
        "5. Run cross-system integration scenarios in framework doc.",
        "",
        "## Test case ID format",
        "",
        "`TC-{CardNameSlug}-{###}` — e.g. `TC-Pyromancer-001`",
        "",
        "## Card index by type",
        "",
    ])
    for t in sorted(by_type):
        lines.append(f"### {t}")
        for name in sorted(by_type[t]):
            lines.append(f"- {name}")
        lines.append("")
    (OUT / "README.md").write_text("\n".join(lines), encoding="utf-8")
    print("Wrote README.md")


def write_framework() -> None:
    text = """# AI Agent Tester — Test Framework

Shared conventions for executing card effect test cases in the Godot battle system.

## Environment

- **Engine:** Godot 4.x
- **Entry scenes:** `campaign/scenes/battle_test.json`, Daily Dungeon layouts, or VN battle scenes
- **Headless unit tests:** `godot --headless --script tests/test_runner.gd` (BattleResolver-only; not full UI flow)
- **Starting crystals:** 5000 each player (3000 if `sudden_death` dungeon modifier active)

## Grid notation

- Player 0 (human/AI tester): rows 0–4 bottom to top on near side
- Player 1 (opponent): rows 0–4 on far side
- Columns 0–4 left to right
- Center cell: (2, 2)
- Center 3×3 zone: rows 1–3, cols 1–3

## Card states

| State | Field | Notes |
|-------|-------|-------|
| Face-down | `face_up = false` | Default at placement |
| Face-up / exposed | `face_up = true` | Required for many targeting abilities |
| Dead end | `card_type = "dead_end"` | Blank cell marker |
| Union | `is_union = true` | Summoned face-up |
| Mutagen | `has_mutagen_flag = true` | Set by Release Mutagen tech (NOT the same as `"mutagen"` in flags array) |
| Venom | `"venom" in flags` | Set by Death Cobra, Plant-29, Scarlet Shroom, etc. |

## Phase flow for manual / agent UI tests

1. **Setup phase** — place cards face-down, assign bluff icons (cosmetic only)
2. **MODE_SELECT** — play Tech cards from hand
3. **Attack phase** — select attacker cell → target cell
4. **Battle calculation overlay** — verify effective ATK/DEF before confirm
5. **Post-battle** — destruction, crystal loss, traps, extra attacks, reveals
6. **End turn** — turn-start/end abilities, tax assessment

## Crystal tax (skip attack)

If a player can attack but ends turn without attacking: tax = 50 × 2^skip_count (50, 100, 200…).
Verify tax when testing Ceasefire-like turn skips.

## Verification checklist (every test)

- [ ] Battle calculation overlay shows expected effective ATK/DEF
- [ ] Correct player pays crystal cost on destruction (unless ability waives it)
- [ ] Card face-up/down state correct after reveal
- [ ] Game log (`GameState.post_message`) contains ability trigger text
- [ ] No soft-lock in target selection UI
- [ ] `attacks_remaining` decrements correctly
- [ ] One-use abilities respect `one_use_*_used` flags

## Cross-system integration scenarios

### INT-001: Trap immunity chain
**Preconditions:** Player 0 Electrogazer face-up; Player 1 Trap Hole face-down; Player 0 Huntress of Green Glade ready to attack.
**Steps:** Attack Trap Hole with Huntress → attack with non-immune unit.
**Expected:** Huntress negates trap; non-immune unit triggers crystal drain unless field negation active.

### INT-002: Mutagen combat pipeline
**Preconditions:** Lab Bloater face-up Bio; Release Mutagen played; opponent attacker ready.
**Steps:** Apply mutagen → opponent attacks Lab Bloater.
**Expected:** Attacker destroyed after battle; Lab Bloater owner pays no crystal on destruction.

### INT-003: Tech into immune character
**Preconditions:** Araya the Eerie Dancer face-up; Accident in opponent hand.
**Steps:** Opponent plays Accident targeting Araya.
**Expected:** Araya unaffected.

### INT-004: Union summon then immediate attack
**Preconditions:** Materials for Gryphon Rider on field; crystals ≥ 1000.
**Steps:** Summon union → attack same turn if allowed.
**Expected:** Union face-up at anchor; materials removed; battle uses union stats.

### INT-005: Zero-cost trap + Electrogazer field effect
**Preconditions:** Both players have 0-cost traps face-down; Player 0 Electrogazer face-up.
**Steps:** Attack traps on both sides.
**Expected:** Zero-cost traps nullified on both fields.

### INT-006: Crystal tax after skipped attack turn
**Preconditions:** Player 0 has ready attacker; chooses end turn without attacking.
**Steps:** End turn; note crystal deduction.
**Expected:** 50 crystal tax (first skip); doubles on consecutive skips.

### INT-007: Bluff icon cosmetic verification
**Preconditions:** Place card with bluff emoticon in setup.
**Steps:** Attack and resolve battle.
**Expected:** Bluff icon unchanged; no stat effect.

### INT-008: Face-down defender ATK bonus (Skeleton Archer)
**Preconditions:** Skeleton Archer attacker; face-down defender.
**Steps:** Attack face-down defender (revealed during flow).
**Expected:** +5 ATK bonus applies when defender was face-down at calculation.

### INT-009: Prayer + Divine destruction prevent
**Preconditions:** Prayer played; Divine character would be destroyed this turn.
**Steps:** Trigger destruction once.
**Expected:** Divine survives once; second destruction not prevented.

### INT-010: Release Mutagen + Lab Crawler double attack
**Preconditions:** Lab Crawler with mutagen; attacks_remaining = 2.
**Steps:** Attack → second attack same turn.
**Expected:** Two attacks allowed with mutagen flag.

## Automated test hints (BattleResolver)

For pure stat calculation without UI, replicate `tests/test_battle_resolver.gd` pattern:

```gdscript
var attacker := _make_char("Pyromancer", 80, 0, 800, CharacterData.Affinity.ARCANE,
    CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
    {"affinity": CharacterData.Affinity.NATURE, "bonus": 30})
var defender := _make_char("Flame Lizard", 25, 40, 400, CharacterData.Affinity.NATURE)
var result := BattleResolver.resolve_battle(attacker, defender, 3, 0, 1)
```

Populate `GameState.grids` when testing field-scanning abilities (Shark cards, Death Knight, Swarmcaller, etc.).

## Non-deterministic tests

Coin-flip abilities (Blue Mage, Joseph the Battle Priest, Pepper Spray, Lazy Troll) require multiple runs or seeded RNG. Log outcomes and verify both branches across ≥10 iterations.
"""
    (OUT / "test_framework.md").write_text(text, encoding="utf-8")
    print("Wrote test_framework.md")


def main():
    cards = load_demo_cards()
    by_type = {}
    for c in cards:
        t = card_type_key(c)
        by_type.setdefault(t, []).append(c)
    write_framework()
    for t in ["Union", "Trap", "Tech", "Character"]:
        if t in by_type:
            write_type_file(t, by_type[t])
    manifest_ids = collect_manifest_ids()
    write_manifest(manifest_ids)
    write_index(cards, len(manifest_ids))
    print(f"\nDone. {len(cards)} demo cards → test_case/")


if __name__ == "__main__":
    main()
