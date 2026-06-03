# AI Agent Tester — Test Framework

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
