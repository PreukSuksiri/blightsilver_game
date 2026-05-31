# Card E2E — Full UI / Battle Testing (AI vs AI)

Automated end-to-end tests run **real Godot battles** (AI vs AI mode) for every **Demo = Yes** card. Two tiers per card:

| Tier | ID suffix | What it checks |
|------|-----------|----------------|
| **Tier 1** | `-001` | **Smoke** — card appears, battle reaches `GAME OVER`, no crashes |
| **Tier 2** | `-002` | **Ability** — forced board/tech setup + log regex / MSG assertions |

**406 scenarios** total (203 cards × 2 tiers).

## Quick start

```bash
# Regenerate scenarios after card data / database changes
python3 test_case/e2e/generate_e2e_scenarios.py
```

### In-game (AI vs AI config screen)

1. Main Menu → admin mailbox → `ai_vs_ai`
2. Use one of:
   - **Run All (T1+T2)** — full suite, both tiers
   - **Tier 1 Smoke** — `-001` scenarios only
   - **Tier 2 Ability** — `-002` ability scenarios only
   - **Reset E2E** — clear saved progress

Progress shows as: `E2E: T1 12/203  T2 5/203  (queue 406)`

### Admin commands

| Command | Action |
|---------|--------|
| `card_e2e` | Run all tiers (resume from progress) |
| `card_e2e t1` | Tier 1 smoke only |
| `card_e2e t2` | Tier 2 ability only |
| `card_e2e reset` | Reset all E2E progress |
| `card_e2e reset t2` | Reset Tier 2 progress only |

## What Tier 1 does (smoke)

Does **not** verify ability math. Confirms:

- Card is placed / appears in the battle log
- Full battle completes (`GAME OVER`)
- No script errors or excessive AI watchdog timeouts

## What Tier 2 does (ability)

Uses **CardDatabase / UnionDatabase ability types** to build targeted setups:

| Card type | Tier 2 setup | Typical assertions |
|-----------|--------------|-------------------|
| **Character (NONE)** | Solo attacker vs weak defender | `Attack … "Card" … ATK=<base>` |
| **Character (ATK bonus)** | Matching affinity defender forced | `ATK=<base+bonus>` in attack line |
| **Character (field boost)** | Ally forced adjacent on grid | Boosted `ATK=` in attack line |
| **Character (coin flip / complex)** | Solo attacker | Card in combat + `Coin flip:` or `MSG:` |
| **Trap** | Trap at P1 center, Ox Patrol attacks | `Trap triggered` + trap name |
| **Tech** | Tech in P0 hand slot 0 | `Tech played P0: "TechName"` + effect hints |
| **Union** | Materials pre-placed, union enabled | `Union summoned` and/or union attacks |

Scoring uses:

- `expect_log_contains` — all required (AND)
- `expect_log_regex` — attack lines, ATK values, trap/tech patterns
- `expect_log_any` — at least one match (OR), e.g. union summon **or** union name in combat
- `expect_log_not_contains` — script errors
- Turn / watchdog limits

## Architecture

```
generate_e2e_scenarios.py
  ├── card_db.py          ← parse CardDatabase / UnionDatabase
  ├── tier2_builder.py    ← ability-specific layouts + assertions
  └── scenarios.json      ← 406 scenarios

CardE2ERunner.gd (autoload)
  → AIvsAIManager → GameBoard (AI_VS_AI)
  → score log → save progress → next scenario
```

Progress: `user://card_e2e_progress.json`  
Session summary: `logs/results/<session>/card_e2e_summary.json`

Each E2E battle log includes a **Card E2E Test** header (scenario ID, highlight card, related `TC-FUNC-*` spec, verification checklist) and a **Card E2E Result** footer (PASS/FAIL + reason) appended at game over.

## Scenario ID format

`E2E-{CardNameSlug}-001` — Tier 1 smoke  
`E2E-{CardNameSlug}-002` — Tier 2 ability

Example Tier 2 (Pyromancer):

- Forces Pyromancer P0 `(2,2)` vs Flame Lizard (NATURE) P1 `(2,2)`
- Requires regex: `Attack P0(2,2)"Pyromancer".*ATK=110` (80 + 30 vs Nature)

## Iteration behavior

1. Loads `scenarios.json` (optionally filtered by tier)
2. Skips scenario IDs already in progress file
3. Runs battle → scores log → saves on pass
4. Auto-chains to next scenario (no manual click between cards)
5. Returns to AI vs AI config with summary when queue finishes

Failed scenarios stay unmarked — re-run the same tier to retry failures only.

## Known limitations

- **AI variance**: AI may not always pick the forced attacker or play tech turn 1; some Tier 2 cases use `expect_log_any` as fallback.
- **Complex abilities**: Coin flips, optional crystal pay, and multi-step TurnManager flows use best-effort MSG/combat checks—not full branch coverage.
- **Not a replacement for** `tests/test_func_*.gd` (deterministic BattleResolver math).
- **Runtime**: ~400 battles × ~2–5 min each if running all tiers unattended.

## Related test layers

| Layer | How to run | Scope |
|-------|------------|--------|
| BattleResolver unit | `godot --headless --script tests/test_runner.gd` | Stat math, no UI |
| Functional specs | `test_case/functional/` | Code-accurate `TC-FUNC-*` docs |
| Manual UI checklist | `test_case/*_demo_test_cases.md` | Human/agent verification |
| **Card E2E (this)** | AI vs AI buttons / `card_e2e` | Full battle loop, all demo cards |

## Files

| File | Purpose |
|------|---------|
| `generate_e2e_scenarios.py` | Regenerate `scenarios.json` |
| `card_db.py` | Parse Godot card databases |
| `tier2_builder.py` | Tier 2 ability scenario builder |
| `scenarios.json` | Generated queue (do not hand-edit) |
| `../../autoload/CardE2ERunner.gd` | Runtime orchestrator + scorer |
