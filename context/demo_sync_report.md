# Demo sync report (2026-07-08)

Source: `context/card_data.xlsx` → `CardDatabase.gd`, `UnionDatabase.gd`, `demo_flags.json`

Scope: **DEMO=Yes only** (stats, ability text, union zone, full/partial formula & ability)

## Run summary

| Target | Touches |
|--------|---------|
| CardDatabase characters | 283 stat/desc |
| CardDatabase traps | 46 |
| CardDatabase tech | 24 |
| UnionDatabase unions | 184 |
| demo_flags.json | 240 demo=yes |

Validation: **0 stat/zone mismatches**, **0 ability/formula mismatches** for in-game DEMO cards.

## Non-DEMO stat update (2026-07-08)

| Card | Field | Change |
|------|-------|--------|
| Death Stag | DEF | 40 → 30 |

## Removed from DEMO scope (2026-07-08)

These xlsx rows are no longer `Demo=Yes`; `demo_flags.json` set to `false`:

- Spell Tank
- Death Parasite
- Raijin Fujin and Suijin
- Raijin Fujin and Suigin

## Not in game (previously DEMO=Yes, now cleared)

These rows exist only in the spreadsheet and are **not** demo-scoped:

| Name | Sheet | Notes |
|------|-------|-------|
| Spell Tank | Unit | New unit (not in game DB) |
| Death Parasite | Union | New union (not in game DB) |
| Raijin Fujin and Suijin | Union | Placeholder |
| Raijin Fujin and Suigin | Union | Placeholder |

Canonical Raijin union in game: **Raijin and Fujin**.

## Sync script

`tools/sync_card_data_from_xlsx.py` now filters **DEMO=Yes** for database writes (demo_flags still reflects full xlsx DEMO column).

```bash
python3 tools/sync_card_data_from_xlsx.py
```
