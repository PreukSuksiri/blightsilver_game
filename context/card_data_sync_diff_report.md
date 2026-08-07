# Card data sync diff report

Source: `context/card_data.xlsx` vs in-game `autoload/CardDatabase.gd`, `autoload/UnionDatabase.gd`, `data/demo_flags.json`.  
Compared with flexible extraction (same-line descriptions included).  
Generated for sync planning — **no apply performed**.

## Trust rules

| Domain | Trust | Notes |
|--------|-------|-------|
| Booster pack membership | **In-game** (`shop/custom_packs.json`) | Do not sync from xlsx booster columns |
| Stats, Ability text, demo flags, effect params / behavior when they contradict xlsx Ability | **Xlsx** | Report game → xlsx as needing sync |

## Why Plunder (and many others) were previously ignored

`tools/sync_card_data_from_xlsx.py` trap/tech description regex **requires** a newline + tabs before the description quote:

```text
}, \n\t\t\t"description"
```

Most trap/tech entries put the description on the **same line** as params, e.g. Plunder:

```gdscript
["Plunder", 500, TrapData.TrapEffectType.NULLIFY_ATTACK_CHOICE,
    {"crystal_gain": 2000, "destroy_option": true}, "The attacker chooses to let you receive 2000 Crystals, or destroy the attacking unit.",
```

| Format | Count | Sync desc regex |
|--------|------:|-----------------|
| Trap same-line desc | 89 | **fails** (includes Plunder) |
| Trap newline desc | 24 | matches (Hostage, Bunker, Self-destruct, …) |
| Tech same-line desc | 98 | **fails** |
| Tech newline desc | 33 | matches |

**Prior dry-run false positive:** ~89 traps / ~98 techs were reported as “empty in-game Ability.” Flexible parsing shows **0** empty fills — descriptions exist; the regex never saw them.

### Sync tool gaps (for a later apply)

1. **Same-line description regex** — `sync_traps` / `sync_tech` cannot update Plunder and most other trap/tech Ability strings until the pattern accepts `}, "desc"` as well as `},\n\t\t\t"desc"`.
2. **No effect param / type updates** — the tool only rewrites cost + description strings (plus unit stats / union fields). Text-only sync would leave Plunder, Compensation, Dart Trap, etc. with xlsx wording but old gameplay numbers/types. Mechanic rows below need manual or extended param/type sync.
3. **Do not run pack rewrite** — leave `shop/custom_packs.json` untouched.

---

## Summary

| Category | Count |
|----------|------:|
| Unit affinity / ATK / DEF / cost mismatches | 0 |
| Union mismatches | 0 |
| Trap / tech cost mismatches | 0 |
| Empty-desc fills (game empty, xlsx has text) | **0** |
| Ability wording diffs (game text ≠ xlsx) | **20** |
| Of those, same-line (sync regex blind) | **17** |
| Mechanic / number changes (need param/type too) | see §B |
| Silent param bugs (desc already matches xlsx) | **5** |
| Demo flag mismatches | **2** |
| Pack membership | out of scope (in-game trusted) |

---

## A. Ability wording diffs (game ≠ xlsx) — 20 cards

Canonical text: **xlsx**. `same_line=yes` means current sync tool cannot update the description without a regex fix.

### Traps (15)

#### Hostage — phrasing — `same_line=no`

- **GAME:** Usable when foe attacks. Reveal 1 of your units. Until this turn ends, foe cannot target that unit. If already targeted, foe must choose another cell.
- **XLSX:** Usable when foe attacks. You can reveal one of your unit. Until this turn ends, foe cannot target that unit. If already targeted it, foe must choose other cell.

#### Bunker — phrasing — `same_line=no`

- **GAME:** Usable when foe attacks this card or surrounding cells. Foe cannot target surrounding cells until the end of this turn. If already targeted, they must choose another cell.
- **XLSX:** Usable when foe attack this card or surround cells. Foe cannot target surrounding cells until the end of this turn. If already targeted, they must choose other cell.

#### Dart Trap — **mechanic** — `same_line=yes`

- **GAME:** If the attacking unit is the first one in that turn, destroy it.
- **XLSX:** If the attacking unit is the first one to attack in that turn, -50 DEF
- **Also update:** effect type/params (`DESTROY_ATTACKER_IF_FIRST_ATTACK` → DEF debuff −50)

#### Science Cage — phrasing — `same_line=yes`

- **GAME:** If attacking unit Is Bio affinity, end your turn immediately. Remove all flags from it.
- **XLSX:** If attacker Is Bio affinity, end their turn immediately. Remove all flags from it.

#### Loop Hole — **mechanic** — `same_line=yes`

- **GAME:** If attacker is Arcane, end your turn immediately.
- **XLSX:** If attacker is Arcane, its ability become None permanently.
- **Also update:** effect type/params (not `END_ATTACKER_TURN_IF_AFFINITY`)

#### Union Cage — phrasing — `same_line=yes`

- **GAME:** If attacking unit Is Union card, that unit cannot attack until the attacker’s next turn ends.
- **XLSX:** If attacker Is Union card, that unit cannot attack until the attacker’s next turn ends.

#### Plunder — **number** — `same_line=yes`

- **GAME:** The attacker chooses to let you receive 2000 Crystals, or destroy the attacking unit.
- **XLSX:** The attacker chooses to let you receive 1000 Crystals, or destroy the attacking unit.
- **Also update:** `crystal_gain` **2000 → 1000**

#### Trick Door — phrasing — `same_line=yes`

- **GAME:** You select 1 unit and swap or relocate to any cell. Repeat Reckoning if it’s this cell.
- **XLSX:** You select 1 of your unit and swap or relocate to any cell. Repeat Reckoning if it’s this cell.

#### Boiling Oil — **mechanic** — `same_line=yes`

- **GAME:** All of attacker’s unit get -10 ATK in Reckoning until this turn’s end
- **XLSX:** All of attacker’s unit get -10 ATK&DEF until your turn ends.
- **Also update:** params (ATK-only → ATK&DEF; duration wording)

#### Self-destruct — phrasing — `same_line=no`

- **GAME:** You select 1 of your units. +50 ATK&DEF until your turn ends, but also destroy it. You pay no cost.
- **XLSX:** You select 1 of your unit. +50 ATK&DEF until your turn ends, but also destroy it. You pay no cost.

#### Rank C Bounty — **mechanic** — `same_line=yes`

- **GAME:** Until the end of your turn, if you destroy that unit, you receive Crystal equal to half of the unit's cost
- **XLSX:** The attacker’s cost is increased by 100 until the end of your turn.
- **Also update:** effect type/params (`refund_half_cost_on_kill` → +100 attacker cost)

#### Rank S Bounty — phrasing (same double-cost intent) — `same_line=yes`

- **GAME:** Double the attacker’s cost until your turn ends
- **XLSX:** The attacker’s cost is doubled until the end of your turn.

#### Flimsy Ground — **mechanic** — `same_line=yes`

- **GAME:** If any Dead-end surrounding this card is being attacked, turn this card face-up, destroy the attacking unit. Attacker pay no cost
- **XLSX:** If any Dead-end surrounding this card is being attacked, turn this card face-up, flip a coin. Heads: destroy the attacking unit. Attacker pay no cost
- **Also update:** params (add coin-flip Heads gate)

#### Confiscate — phrasing — `same_line=yes`

- **GAME:** If foe use any effect that increase Crystal, turn this card face-up and cancel it.
- **XLSX:** If foe use any effect that increase Crystal, flip this card face-up and cancel it.

#### Ancestral Spirit — phrasing (xlsx typo “unt”) — `same_line=yes`

- **GAME:** Whenever Tribe unit on your side is destroyed, you can flip this card face-up and revive that unit.
- **XLSX:** Whenever Tribe unit on your side is destroyed, you can flip this card face-up and revive that unt.

### Techs (5)

#### Compensation — **mechanic / number** — `same_line=yes`

- **GAME:** This turn, whenever you attack a Dead End, they receive 20 Crystals
- **XLSX:** This turn, whenever you attack a Dead End, you receive 100 Crystals
- **Also update:** `amount` **20 → 100**; effect semantics (foe gain → self gain). Type today: `OPPONENT_CRYSTAL_GAIN_ON_DEAD_END`.

#### Borrow — **timing / who pays** — `same_line=yes`

- **GAME:** Receive 200 Crystals. At the end of your turn, they lose 300 Crystals
- **XLSX:** Receive 200 Crystals. At the end of your next turn, you lose 300 Crystals
- **Also update:** repay timing keys (`repay` → next-turn self loss)

#### Loan — **number** — `same_line=yes`

- **GAME:** Receive 600 Crystals. At your next turn’s end: lose 800 Crystals
- **XLSX:** Receive 600 Crystals. At the end of your next turn, you lose 900 Crystals
- **Also update:** `repay_next_turn` **800 → 900**

#### Mortgage — **number / timing** — `same_line=yes`

- **GAME:** Receive 1200 Crystals. At the end of your turn, lose 1500 Crystals
- **XLSX:** Receive 1200 Crystals. At the end of your next turn, you lose 1700 Crystals
- **Also update:** repay **1500 → 1700**; timing end-of-turn → end of next turn

#### Institutionalization — **targeting** — `same_line=yes`

- **GAME:** Target 1 foe’s unit. Its ability becomes None until foe’s next turn ends
- **XLSX:** Target 1 unit on either’s side. Its ability becomes None until foe’s turn ends
- **Also update:** targeting (foe-only → either side). Params today look incomplete vs description (`REVEAL_OPPONENT_SQUARE` / `count: 1`).

---

## B. Mechanic / number changes (text alone is not enough)

| Card | Game | Xlsx (canonical) | Also update |
|------|------|------------------|---------------|
| Plunder | 2000 crystals | **1000** | `crystal_gain` |
| Dart Trap | destroy first attacker | **-50 DEF** | effect type/params |
| Loop Hole | end turn (Arcane) | **ability → None permanently** | effect type/params |
| Rank C Bounty | half-cost crystal on kill | **+100 attacker cost** | effect type/params |
| Flimsy Ground | auto-destroy | **coin flip Heads: destroy** | params |
| Boiling Oil | -10 ATK | **-10 ATK&DEF** | params |
| Compensation | foe +20 on Dead End | **you +100** | `amount` + effect semantics |
| Borrow | repay 300 end of your turn / “they lose” | repay 300 end of **next** turn / **you** lose | repay timing keys |
| Loan | repay **800** | repay **900** | `repay_next_turn` |
| Mortgage | repay **1500** end of turn | repay **1700** end of **next** turn | repay amount + timing |
| Institutionalization | foe’s unit only | **either side** | targeting |

---

## C. Silent param bugs (desc already matches xlsx; params wrong)

Prior description-only compare missed these. Desc/xlsx agree; **params must move to xlsx numbers**.

| Card | Desc / xlsx | Game param | Sync to |
|------|-------------|------------|---------|
| Fierce Gladiator | +**200** Crystal if successfully defended | `amount`: **500** | `amount`: **200** |
| Slim Gray Trooper | +**65** ATK&DEF if ≥10 own cells revealed | `atk`/`def`: **30** | `atk`/`def`: **65** |
| Dryad | gain **400** Crystals on foe destroy (exposed) | `amount`: **300** | `amount`: **400** |
| Ore Eater | receive **100** Crystals whenever any player uses tech | `amount`: **20** | `amount`: **100** |
| Magical Craftsman | end of foe’s turn, +**10** ATK&DEF permanently to 1 ally | `atk`/`def`: **5**, type `ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND` | `atk`/`def`: **10**; likely wrong `AbilityType` (needs permanent EOT ally boost, usable face-down) |

---

## D. Demo flags (trust xlsx)

| Card | Game (`demo_flags.json`) | Xlsx Demo | Sync to |
|------|--------------------------|-----------|---------|
| Harsh Training | `true` | No / blank | **false** |
| Illegal Steroid | `false` | Yes | **true** |

---

## E. Out of scope — booster packs

Xlsx booster columns still disagree with curated in-game packs (achievement-reward cards, Garrison, etc.). **Keep** `shop/custom_packs.json` as source of truth. Do not run `sync_custom_packs` / full pack rewrite from xlsx.

---

## Recommended next apply (not done here)

1. Fix same-line description regex in `tools/sync_card_data_from_xlsx.py` (traps + techs).
2. Sync Ability text for §A from xlsx (after regex fix).
3. Manually (or via extended tool) update params/types for §B and §C.
4. Sync demo flags in §D.
5. Leave packs alone.
