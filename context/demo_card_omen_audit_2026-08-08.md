# Demo Card and Omen Audit — 2026-08-08

## Scope and method

This audit compares the current working tree—not `HEAD`—against `context/card_data.xlsx`.

Reproducibility snapshot:

- Git `HEAD`: `7a31be97e1c73d7c9ae8cbcb38b595eea9ef8bf5`
- The tree was dirty, including relevant uncommitted changes in `TurnManager.gd`, `GameBoard.gd`, and `AIPlayer.gd`.
- `card_data.xlsx` SHA-256: `16b201072e748321b8ff948a1e6a48a6e807cc5ca05ca94240328ec5aa55de48`
- `omens.json` SHA-256: `9cf2e9576030de02d28f0c9a1667e597846c391577c982bfb3ea0d3111cddf05`

- Cards: every workbook row where `Demo = Yes`
  - Units: 166
  - Unions: 46
  - Traps: 31
  - Techs: 15
  - Total: 258
- Omens: every `data/omens.json` entry whose `groups` contains `chapter_1` or `boss_chapter_1`
  - `chapter_1` only: 172
  - both groups: 6
  - `boss_chapter_1` only: 3
  - Total: 181
  - `include_in_demo = true`: 173
  - `include_in_demo = false`: 8

Checks used:

1. Workbook-to-runtime identity and field comparison.
2. Static tracing from player-facing text to enum, parameters, resolver/turn/UI code, and AI routing.
3. Omen effect-type and consumer tracing, including holder ownership.
4. Copy review against workbook Rule terminology and actual runtime behavior.

No Godot runtime tests were performed. Findings labeled confirmed have direct data or deterministic control-flow evidence; complex contract questions are listed as design-dependent.

Severity labels describe player impact:

- Critical: unusable content, materially different effect, or match-integrity risk.
- High: major numerical, targeting, ownership, or duration error.
- Medium: narrower behavior, edge case, or meaningful UX/AI discrepancy.
- Low: data hygiene with little or no gameplay impact.

Evidence confidence is High for confirmed findings unless explicitly qualified. “Design-dependent” means code and text differ in a way that requires an authority decision before either can be called wrong.

## Executive summary

- All 258 expected demo card rows exist in the runtime databases.
- Unit ATK, DEF, cost, affinity, and rarity match the workbook for all 166 demo units.
- Trap and Tech base costs match. All workbook-specified rarities match; Potent Poison has no workbook rarity, so its runtime Exotic rarity cannot be checked.
- All 46 demo Unions match on name, ATK, DEF, affinity, full ability, full formula, parsed summon cost, and Union Zone. Union rarity is blank in the workbook and therefore cannot be parity-checked.
- All 258 workbook-selected cards are enabled in `data/demo_flags.json`; 259 runtime flags are true because Harsh Training is additionally enabled despite a blank workbook Demo cell.
- No scoped card uses a `NOT_IMPLEMENTED` enum. This does not mean behavior is correct; the audit found numerous incorrect or incomplete handlers.
- The 181 scoped Omens contain 95 unique effect types. `union_material_wildcard` has no runtime consumer; several other types are only partially consumed, incorrectly parameterized, or owner-asymmetric.
- Highest-risk defects:
  - Defensive Pheromone is a paid cosmetic no-op.
  - Plunder performs a different choice from its text.
  - Armored Dino and Giant Mining Pod cannot be summoned.
  - Bone Dragon ignores its authored timing and coin flip.
  - Great Diplomacy reveals five units instead of three.
  - Berserk can reduce remaining attacks instead of adding one.
  - Omen anoints can affect the opposing player's same-named card.
  - Substitute Seal is marked implemented but has no effect.
  - Three “cannot gain Crystals” Omens do not block Crystal gain.
  - Many enemy-held global Omens either do not function for the enemy or incorrectly benefit Player 0.

## 1. Workbook and runtime parity

### Confirmed parity

- Runtime counts: 511 Units, 113 Traps, 131 Techs, and 134 Unions.
- Missing workbook cards after trimming names: 0.
- Runtime orphans: 0.
- Demo Units:
  - ATK: 166/166
  - DEF: 166/166
  - cost: 166/166
  - affinity: 166/166
  - rarity: 166/166
- Demo Traps:
  - name after trimming: 31/31
  - cost: 31/31
  - workbook-specified rarity: 31/31
- Demo Techs:
  - name: 15/15
  - cost: 15/15
  - workbook-specified rarity: 14/14
- Demo Unions:
  - name, ATK, DEF, affinity, full ability, full formula, parsed cost, and zone: 46/46
  - parsed material structures match the current workbook parser: 46/46

### Confirmed parity defects

1. **Harsh Training — extra runtime demo card**
   - Workbook: Demo is blank.
   - Runtime: `data/demo_flags.json` is `true`.
   - Impact: the runtime demo Tech pool contains 16 Techs instead of the workbook's 15.
   - Decision needed: disable it in runtime or mark it Yes in the workbook.

2. **Union partial formulas contradict their full/runtime summon costs**
   - Armored Dino: partial 700, full/runtime 800.
   - Ten Arms Yaksa: partial 600, full/runtime 800.
   - Gamma Mermaid: partial 1000, full/runtime 500.
   - Dimensional Virus: partial 1500, full/runtime 800.
   - Impact: the hidden-information teaser gives the player a false cost.

### Data hygiene

1. **War Genie — malformed workbook name**
   - Workbook name has trailing whitespace; runtime key is `War Genie`.
   - No gameplay impact after normalization.

2. **Hypnosis — malformed workbook name**
   - Workbook name has trailing whitespace; runtime key is normalized.
   - No gameplay impact after normalization.

3. **Ability-text trailing whitespace**
   - Leorudus the Warlord, Demon Spawn, Lunar Wraith, Explosive Barrels, and Scarlet Shroom contain whitespace-only differences.

## 2. Demo Unit behavior

### Confirmed mismatches

1. **Aerial the Battlemage — High**
   - Text: +20 ATK&DEF if there is a Union card on your side.
   - Actual: ATK gains +20 for each qualifying row; DEF receives no bonus.
   - Human/AI: same incorrect Reckoning math.
   - Evidence: `BattleResolver._get_effective_atk()` and missing equivalent DEF case.

2. **Fierce Gladiator — High**
   - Text: +200 Crystals after a successful defense.
   - Data/actual: `amount = 500`.
   - Human/AI: owner receives 300 too many.

3. **Immortal Vampire — High**
   - Text: +30 ATK per other exposed Chaos card.
   - Data/actual: +50 per card.
   - Divine self-destruction portion works.

4. **Dark Tengu — Medium**
   - Text: lose 10 ATK after a successful attack and 10 DEF after a successful defense.
   - Data/actual: loses 5.

5. **Grave Worm — High**
   - Text: whenever foe loses Crystals, foe loses 200 more.
   - Data/actual: 20 more.

6. **Succubus — High**
   - Text: once, after surviving Reckoning, gain half the foe's ATK&DEF.
   - Actual: gains the foe's full stats and also requires the foe to survive.

7. **Leech Man — High**
   - Text: surviving an attack grants +10 DEF permanently; Mutagen also grants +10 ATK.
   - Actual: DEF portion exists; Mutagen ATK portion has no parameter or handler.

8. **Bone Dragon — Critical**
   - Text: at foe turn end, flip a coin; Heads revives it.
   - Actual: a non-Union destruction queues an unconditional revival at the start of the owner's turn. The authored `foe_turn_end` and `coin_flip` parameters are ignored.

9. **Nimrod the Wonder Seeker — Medium**
   - Text: once at turn end, reveal two foe cells and one own cell.
   - Actual: reveals only two foe cells.

10. **Skeleton Grappler — High**
    - Text: after Reckoning, the foe unit cannot attack until foe turn end.
    - Actual: the duration blocks it through its next turn.

11. **Methanomancer — High**
    - Text: triggers when a surrounding cell is targeted.
    - Actual: scans both boards by coordinate, so a target adjacent on the opposite board can trigger it.

12. **Slim Gray Tank — Medium**
    - Text: +10 ATK&DEF per revealed cell on your side.
    - Actual: counts exposed non-Dead-End cards, not all revealed cells.

13. **Armored Bee / Laughing Granny — Medium**
    - Text: temporary bonuses last until turn end.
    - Actual: bonuses apply to one Reckoning only.

14. **Tomb Bandit — High**
    - Text: cannot be destroyed by Traps and loses 20 DEF after attacking a Trap.
    - Actual: the shared `IMMUNE_TO_TRAPS` branch nullifies every Trap effect, not only Trap destruction.
    - Human/AI: both receive broader immunity than advertised.

### Confirmed human/AI difference

1. **Nuki the Tanuki — Medium**
   - Human selection can choose an own face-down unit.
   - AI uses a face-up-only selector and can fail when legal face-down choices exist.

### Design-dependent Unit cases

- Mysterious Miner says “After attacked” but triggers only after destroying the defender.
- Scout Probe does not say that “adjacent” means adjacent to the attacked target.
- Death Knight and the Shark family do not say that field-count bonuses exclude the source and hidden cards.
- WK-17 the Siren does not define the one-Heads/one-Tails result.
- Nuki the Tanuki says “Before Reckoning” and then “Repeat Reckoning.”
- Lab Crawler says “target 3 cards” rather than “attack up to 3 times.”
- Magenta the Nightbloom does not define “that turn.”
- Striker Comet contains “destroy it and the end.”
- Pit Lord does not establish whether a nullified attack counts as “after this card attacked”; runtime skips the halving in that interaction.

## 3. Demo Trap behavior

### Confirmed mismatches

1. **Plunder — Critical**
   - Workbook: attacker chooses between giving the trap owner 1000 Crystals or destroying the attacker.
   - Displayed runtime text/data: 2000 Crystals.
   - Actual handler: prompt is labeled Checkpoint and chooses between attacker losing 500 Crystals or being destroyed.
   - `crystal_gain` is never read.

2. **Defensive Pheromone — Critical**
   - Text: swap an Armored Nature unit into the trap cell and repeat Reckoning.
   - Actual: target selection posts a “swapped positions” message but does not move a card or repeat Reckoning.

3. **Soul Blast — High**
   - Text: attacker loses 150 per unit in the trap owner's Void.
   - Actual: counts every entry in the attacker's Void and enforces a minimum count of one.

4. **Grudge — High**
   - Text: permanent ATK loss per unit in the trap owner's Void.
   - Actual: counts all Void entries and enforces a minimum penalty when the Void has no units.

5. **Radiation — High**
   - Text: -10 ATK&DEF plus another -10 per trap in owner's Void.
   - Actual: always applies only the base -10; `void_trap_bonus` is ignored.

6. **Pepper Spray — High**
   - Text: ATK penalty lasts through foe's next turn.
   - Actual: carry penalty is cleared at the start of that turn.

7. **Foul Gas — Medium**
   - Text: all attacking player's units lose ATK.
   - Actual: only face-up units are changed.

8. **Choking Gas — Medium**
   - Same face-up-only discrepancy as Foul Gas.

9. **Alarm — Medium**
   - Text: all Anima units gain the turn-duration bonus.
   - Actual: only currently face-up Anima units are changed.

10. **Hostage — Medium**
    - Text says the trap owner “can” reveal a unit, implying optional use.
    - Actual selection is mandatory when a unit exists, can select an already exposed unit, nullifies the attack, and grants retargeting. There is no decline choice.

### Confirmed human/AI difference

1. **Bunker and Hostage retargeting — High**
   - Current uncommitted code preserves the same attacker and asks a human for another target.
   - AI enters the generic abort path, records the attacker as aborted, and does not retarget with that attacker.

### Design-dependent Trap cases

- Union Cage does not clearly state whether an adjacent-cell attack is canceled or only creates a future lock.
- Explosive Barrels' “You also pay” can reasonably mean the trap owner pays in addition to normal attacker loss, but should be confirmed.
- Self-destruct text can imply immediate destruction; runtime destroys the chosen unit at the end of the trap owner's turn.

## 4. Demo Tech behavior

### Confirmed mismatches

1. **Great Diplomacy — High**
   - Text: reveal up to three own units.
   - Data/actual: `count = 5`; human and AI can reveal five.

2. **Berserk — Critical**
   - Text: gain one attack count this turn.
   - Actual: choose one face-up unit, restrict all further attacks to it, and set remaining attacks to one.
   - Playing it with two attacks remaining can reduce the player to one.

3. **Accident — High**
   - Text: target a foe exposed card; if none exists, foe chooses.
   - Actual: either player's exposed card can be selected. With no exposed card, the effect cancels; foe is not prompted.

4. **Prayer — High**
   - Text: once this turn, prevent a Divine card from being destroyed.
   - Actual: protects only against Reckoning destruction, not generic Tech/trap/ability destruction.

5. **Siege Cannon — High**
   - Text: effect lasts until turn end.
   - Actual: flag can persist into later turns if no qualifying surviving defender consumes it.

6. **Resurrection — High**
   - Text: revive one unit with 0 ATK, 0 DEF, and no ability.
   - Confirmed actual: current stats and ability are cleared, but permanent/temporary/aura/flag bonuses can leave nonzero effective ATK/DEF.
   - Design question: runtime automatically uses the latest graveyard entry; “revive one” does not explicitly promise player selection.

7. **Tease — Medium**
   - Text refers to choosing and revealing a cell.
   - Actual requires a face-down unit, excluding face-down traps and other cells.

### Confirmed AI or UI differences

- War Supply has no AI score and is never voluntarily played by AI.
- Release Mutagen AI requires a face-up Bio target although runtime permits any own unit.
- Garrison AI requires a face-up unit although hidden units receive the effect.
- Great Diplomacy AI counts hidden traps when deciding usefulness, but legal targets are units.
- Tease and Bribe AI count hidden cards although runtime targets hidden units.
- Bribe AI defender always passes without evaluating the 700-Crystal option.
- Accident AI evaluates only exposed characters although runtime can target traps.
- Rift Strike AI refuses to play without an exposed foe character although the current effect can destroy hidden cards.
- Potent Poison target routing discards player ownership and can hit the wrong same-coordinate card.
- Human Tech-button and AI affordability checks use raw costs in places where final validation uses modified costs.

### Rift Strike current-worktree assessment

The uncommitted implementation is substantially aligned:

- human and AI select three foe cells;
- each new cell must be orthogonally adjacent to an existing selection;
- hidden cards can be destroyed;
- no destruction cost is paid;
- Dead Ends are selectable but not destroyed;
- Tech-immune units survive.

Remaining contract questions:

- “Adjacent” currently permits straight or L-shaped connected triples.
- The completion message can over-report destruction when another effect blocks it.
- The first selected cell may be a Dead End.

## 5. Demo Union behavior

### Confirmed mismatches

1. **Armored Dino — Critical**
   - Formula: one Armored Nature card.
   - Runtime condition requires the contiguous name substring `armored nature`; no card matches.
   - Result: cannot be summoned.

2. **Giant Mining Pod — Critical**
   - Runtime condition requires exact `Miner probe`.
   - Registered card is `Miner Probe`; matching is case-sensitive.
   - Result: cannot be summoned.

3. **Burning Phoenix — High**
   - Runtime has undocumented `tech_target_self_destruct = true`.
   - Any targeted Tech destroys it, and that destruction is excluded from its revival.

4. **Dimensional Virus — High**
   - Text: foe units lose 10 ATK&DEF permanently in Reckoning.
   - Actual: Bio foes are excluded.

5. **Helios the Prideful Fortress — High**
   - Text explicitly says this card cannot be destroyed while a qualifying Cosmic ally is exposed.
   - Actual protection is limited to character-vs-character resolution; generic destruction can bypass it.

6. **Final summon affordability — Critical system defect**
   - Human/AI validation checks one effective cost.
   - Omen material multiplier and some later loss modifiers can increase payment after material commitment.
   - Payment can end the duel, but execution continues removing materials and placing the Union because there is no post-payment game-over guard.

7. **Reunion AI parity — High**
   - GameBoard permits the second Union summon.
   - AI's `_union_used` boolean prevents AI from using it.

8. **Mannaz material parity — High**
    - Availability check permits a Mannaz wildcard.
    - Human and AI material assignment cannot complete that wildcard match.

### Design-dependent Union cases

- Greater Succubus, Volatile Slasher, Bioterrorist, and Rocket Peacock say “after Reckoning” or “battles,” but runtime applies attacker-only and often survivor-only logic.
- X-Death Squad payment is offered before Reckoning and only while attacking.
- Giant Meteor Vergaia uses four orthogonal surrounding cells; text does not define adjacency.
- Lord of Terror applies a permanent ATK loss, but text omits duration.
- Legendary Locksmith randomly reveals three cards; text does not say whether the player selects.
- Formula family tokens such as Shark, Gryphon, Yaksa, Raijin, and Fujin use substring matching; exact-versus-family intent should be explicit.
- Pixie Queen's “each Divine card” and Choir Lead Amber's “all Divine units” exclude the source; decide whether source inclusion is intended.
- Team Galaxos stores one protection owner globally; if both players may legally field it, the second summon overwrites the first owner's protection.

## 6. Chapter 1 and boss Omen behavior

### Confirmed critical defects

1. **Anoint owner leakage**
   - Runtime anoint storage is keyed only by `card_name`.
   - General unit matching returns true on name equality before checking owner.
   - Same-named cards on both fields can receive one player's anoint.
   - Cost, affinity, aura, immunity, revival, and combat effects can inherit this leakage; a few specialized helpers add their own owner checks, but ownership is not centralized.
   - Correction: key effects by owner and card name, and require owner in every anoint query.

2. **Three “cannot gain Crystals” Omens do not block gains**
   - `quiet_funeral_lock`
   - `cheap_snare_lock`
   - `cheap_circuit_lock`
   - Data uses `crystal_gain_pct = 0`.
   - Runtime interprets the value as a delta percentage; zero means no change.
   - A `-100` data value would block Player 0 in the current model, but does not solve enemy ownership and can interact poorly with other percentages. A dedicated owner-aware gain lock is the safer correction.

3. **Enemy-held global Omen asymmetry**
   - Pre-battle accumulation discards non-player-owner effects except starting Crystal bonuses.
   - Confirmed affected families include attack-count bonuses, first-turn attack lock, extra Tech, Union cost, Crystal gain/loss percentages, and reward modifiers.
   - Additional P0-only gates exist in turn initialization, max-Tech handling, Union cost, and Crystal gain/loss.
   - Some owner-blind queries invert the effect instead: enemy Overclock can increase Player 0's Tech allowance; enemy Barrel Gospel can convert Player 0's traps; enemy Grave Dividend, Bait Purse, and Staggering Bait can reward Player 0.
   - Correction must make helper queries owner-filtered as well as making state per-player.

### Other confirmed Omen mismatches

4. **Null Aegis / Mutagen Aegis — High**
   - Both promise Tech immunity.
   - Omen immunity is used for unit/trap interactions, but centralized Tech immunity checks only a card's own ability enum.
   - Null Aegis' Trap immunity query is also owner-blind and can protect the opposing player's qualifying unit.
   - Centralized immunity needs both card identity and owner.

5. **Golden Reckoning — High**
   - Enemy holder cannot receive the winning-Reckoning Crystal reward because the consumer requires `player == 0`.

6. **Etched Brand and other stat-duration Omens — High**
   - Copy promises broad permanence/extension for ATK/DEF changes caused by an anointed Unit, Trap, or Tech.
   - Only a subset of Tech and Trap stat-mutation paths route through the duration helper.
   - Etched Brand is effectively unsupported for ordinary Unit-caused changes.

7. **Star Peek, Mine Survey, Cannonade Ruin — Medium**
   - “After Reckoning” effects execute only when the attacker survives a unit Reckoning.
   - Text does not state the survivor or attacker-only restriction.
   - Mine Survey says “on the field,” but target selection reveals only foe cells.

8. **Choir Lead Amber's Vigil — High data/text contradiction**
   - Description: Choir Lead Amber gains +50 DEF.
   - Effect filter: Diamond Unicorn.
   - It is `include_in_demo = false` but remains in the required `chapter_1` group audit scope.

9. **Mass Transfiguration — Medium UX contradiction**
   - Description/effect changes all own units to Anima.
   - `anoint_card_type = unit` forces the player to choose one irrelevant unit first.

10. **Substitute Seal — Critical**
    - Description: the chosen unit counts as any one Union material requirement.
    - Effect: `union_material_wildcard`.
    - Actual: the effect type has no GDScript consumer and is absent from the anoint runtime type registry.

### Stacking and taxonomy findings

- All 181 scoped entries say `stackable = true`, but normal offer logic unconditionally excludes already-held IDs; same-ID stacking is therefore unavailable.
- Aggregation of different Omens sharing an effect type varies by implementation:
  - some values add;
  - some multipliers multiply;
  - post-Reckoning counts use maximum rather than sum;
  - `anoint_effect()` returns the first match for some types.
- `insight` and `insights` are separate group names; requesting one does not include the other.
- `shadow_hunter_mark` and `hidden_bane_brand` have the same description and effect. No duplicate scoped descriptions with conflicting effects were found.

## 7. Player-facing text defects

The following need a design or behavior decision, not only grammar correction:

- WK-17 the Siren: missing mixed coin result.
- Mysterious Miner: “After attacked” does not identify actor or success condition.
- Nuki the Tanuki: “Before Reckoning” conflicts with “Repeat Reckoning.”
- Magenta the Nightbloom: “that turn” has no clear antecedent.
- Blue Mage: “destroy it” has two possible referents.
- Venom Toad: ordering makes it sound as though a newly applied Venom destroys the same foe immediately.
- Methanomancer: bonus duration is omitted.
- Silver Dragon: attack-payment frequency is omitted and “tax” may imply a different mechanic.
- White Tiger: text does not say it applies only while defending.
- Siege Cannon: text does not identify “the next surviving defender.”
- Resurrection: text does not define graveyard selection or placement.
- Rift Strike: singular “destroy it” follows three cells; adjacency is undefined.
- Armored Dino: payment optionality and bonus duration are omitted.
- Lord of Terror: penalty duration is omitted.
- Gamma Mermaid: Mutagen subject is unclear.
- Dimensional Virus: Mutagen subject and destruction source are unclear.
- Giant Meteor Vergaia: pronouns do not identify the Union versus its last target.
- Ice Elemental: a card does not own a turn; the intended wait duration should name the unit's owner.
- Dowsers Instinct: “refunded” does not say whether it refunds attack count or Crystals.

Systematic copy cleanup:

- Use “Tech,” not “spell,” in insight Omens.
- Use “Exposed,” “Reckoning,” “Dead End,” “Crystal(s),” “ATK&DEF,” and Heads/Tails consistently.
- Replace “foe's cell” with “foe cell.”
- Fix singular/plural forms such as “Flip 3 coin,” “each heads,” “1 of your unit,” and “for each Divine cards.”
- Clarify whether “all” and “each” include the source card.
- Clarify whether “on your side” includes hidden cards.

## 8. Proposed correction batches

No source is assumed universally authoritative. Each batch requires a case-by-case design decision.

### Batch A — Data/parity and clearly broken wiring

- Resolve Harsh Training's Demo flag.
- Correct four Union partial costs.
- Fix Armored Dino and Giant Mining Pod material conditions.
- Resolve Plunder's 1000/2000/lose-500 contradiction and connect its parameter to the handler.
- Set Great Diplomacy's intended count.
- Introduce an owner-aware gain lock for the three no-Crystal-gain Omens.
- Fix Choir Lead Amber's Vigil filter or description.
- Remove irrelevant target selection from Mass Transfiguration if the global effect is intended.
- Implement Substitute Seal or mark it unimplemented and remove it from demo offers.

### Batch B — Card behavior

- Units: Aerial, Fierce Gladiator, Immortal Vampire, Dark Tengu, Grave Worm, Succubus, Leech Man, Bone Dragon, Nimrod, Skeleton Grappler, Methanomancer, Slim Gray Tank, Armored Bee/Laughing Granny, Tomb Bandit, and Nuki AI.
- Traps: Defensive Pheromone, Soul Blast, Grudge, Radiation, Pepper Spray, Foul Gas, Choking Gas, Alarm, Hostage, and AI retargeting.
- Techs: Berserk, Accident, Prayer, Siege Cannon, Resurrection, Tease, and listed AI affordability/targeting defects.
- Unions: Burning Phoenix, Dimensional Virus, Helios, final-cost validation, Reunion AI, and Mannaz selection. Resolve Pixie Queen, Choir Lead Amber, and Team Galaxos contracts before changing them.

### Batch C — Omen architecture

- Make anoints owner-aware.
- Make all enemy-held global effects and helper queries owner-symmetric.
- Include owner-aware Omen immunity in centralized Tech immunity.
- Remove the P0-only Golden Reckoning gate.
- Centralize source-aware stat mutation before claiming broad stat-duration support.
- Define per-effect stacking behavior.

### Batch D — Copy and contract alignment

- Decide all cases listed as design-dependent.
- Update workbook/card descriptions and Omen descriptions to the chosen behavior.
- Normalize Rule-sheet terminology and grammar without changing mechanics.

## 9. Verification limits

Static tracing proves the data and deterministic branches cited above. It does not prove animation sequencing, focus/overlay usability, or emergent AI strategy. After approved fixes, targeted Godot tests are appropriate for:

- Defensive Pheromone repeat-Reckoning flow;
- Bunker/Hostage AI retargeting;
- Bone Dragon turn-end coin revival;
- multi-owner anoint behavior with duplicate card names;
- enemy-held global Omen symmetry;
- Union final-cost confirmation under stacked Omen modifiers.

## 10. Implementation status (2026-08-08, post-approval)

All batches A–D were approved and applied in the working tree (not committed). Authority choices used:

- Harsh Training → non-demo (`demo_flags.json` false).
- Union partial costs → match full/runtime (800 / 800 / 500 / 800).
- Plunder → workbook **1000** Crystal gain to trap owner.
- Choir Lead Amber’s Vigil → filter **Choir Lead Amber**.
- Prefer matching text/workbook numbers for wrong params.
- Pixie Queen / Choir Lead Amber: literal “all/each” → include source (`exclude_self: false`).
- Sharks / historical field-count: default `exclude_self: true`.
- Tomb Bandit: keep non-destroy trap resolution via `trap_destroy_immunity_only` (do not blank-nullify all traps).

### Batch A — Resolved

- Harsh Training demo flag cleared.
- Four Union partial costs corrected in `UnionDatabase.gd` + workbook.
- Armored Dino / Giant Mining Pod materials fixed.
- Plunder handler + `crystal_gain: 1000`.
- Great Diplomacy `count: 3`.
- Owner-aware `cannot_gain_crystals` for quiet_funeral_lock / cheap_snare_lock / cheap_circuit_lock.
- Choir Lead Amber’s Vigil filter corrected.
- Mass Transfiguration `anoint_card_type` cleared.
- Substitute Seal / `union_material_wildcard` wired through material solver + anoint runtime types.

### Batch B — Resolved

- Units, traps, techs, and unions listed in §8 Batch B were corrected in `CardDatabase.gd`, `UnionDatabase.gd`, `BattleResolver.gd`, `TurnManager.gd`, `GameBoard.gd`, and `AIPlayer.gd`.
- Regression guards: IMMUNE_TO_TRAPS full nullify restored by default; field-count default `exclude_self: true` with Pixie/Amber overrides; `has_ability_immunity_vs_units(card, owner)` call sites updated.

### Batch C — Mostly resolved; residual gaps

- Owner-aware anoints and many helper queries.
- Null/Mutagen Aegis → `is_immune_to_tech_cards` + owner-aware trap immunity.
- Golden Reckoning not P0-only.
- Mine Survey copy → foe cells.
- Etched Brand: more paths via `apply_stat_change_from_source`; **unit-ability-caused stat changes may still miss Etched Brand**.
- Some legacy enemy-global P0 asymmetries may remain; treat as follow-up if playtests show them.
- Per-effect `stack_mode` documentation still incomplete (behavior left as existing consumers define it).

### Batch D — Resolved for demo scope

- Demo ability/omen copy updated in databases, workbook, and `omens.json` (Tech Ledger labels, Dowser’s Instinct, etched_* clarifications, Rule terminology where touched).
- Remaining design-dependent wording cases in §7 were not all rewritten when behavior already matched an accepted contract.

### Static revalidation

- `python3 tools/validate_card_database.py` → OK (demo NOT_IMPLEMENTED: 0; global stubs remain Trap=37 Tech=1 Union=2 outside demo scope).
- Core: CardDatabase / BattleResolver / GameState / VN → all passing.
- Func: Characters 260 / Traps 57 / Techs 17 / Unions 248 → **582 passed, 0 failed**.
- Ethereal Marquees summon test deck corrected to `Moon Nobleman` + `Ethereal Soldiers` (Energy Wisp does not match `name_contains: ethereal`).

### Focused Godot pass (2026-08-08)

Runner: `godot --headless --path . res://tests/run_focused_godot_pass.tscn`  
Suite: `tests/test_focused_godot_pass.gd`  
Result: **32 passed, 0 failed**

| Residual case | Result | What was exercised |
|---|---|---|
| Defensive Pheromone repeat Reckoning | PASS | Swap into trap cell + `_pending_pheromone_swap_done` |
| Bunker/Hostage AI retarget | PASS | `AIPlayer.choose_retarget_for` with one legal cell |
| Bone Dragon foe-turn-end coin revive | PASS | Queue on Union destroy + `TurnManager._process_foe_turn_end_revives` Heads path |
| Multi-owner anoint (duplicate names) | PASS | Etched Brand / Substitute Seal owner keys; same name on both sides |
| Enemy-held global Omen symmetry | PASS | `quiet_funeral_lock`, Null Aegis, Golden Reckoning owner gates |
| Union final cost under stacked omens | PASS | Material anoint × Risk&Reward; enemy anoint does not affect P0 |

Known remaining gap (documented earlier, not a fail of this pass): unit-ability self-buffs still bypass `apply_stat_change_from_source`, so Etched Brand does not rewrite those paths. No commit was created; tree remains dirty pending human review.
