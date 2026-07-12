# Full-release card import report

Source: `context/card_data.xlsx`

## Generated entries

| Sheet | Added | Already in game | Skipped (incomplete xlsx) | In-game now |
|-------|------:|----------------:|------------------------:|------------:|
| Unit | 0 | 509 | 0 | 509 |
| Trap | 1 | 72 | 0 | 73 |
| Tech | 10 | 117 | 0 | 127 |
| Union | 1 | 131 | 0 | 132 |

**Total added this run:** 12
**In-game total:** 841 / 770 xlsx rows (0 skipped)

## Validation

After import, run:

```bash
python3 tools/sync_card_data_from_xlsx.py
python3 tools/validate_card_database.py
```

Expected: **Validation OK** with 0 missing (excluding skipped rows).

## Skipped rows (fix xlsx before import)

## Follow-up checklist

- Map `NOT_IMPLEMENTED` cards to real AbilityType / TrapEffectType / TechEffectType
- Add card art (generated entries use `placeholder_art: true`)
- Fix skipped xlsx rows and re-run generator
- Run `python3 tools/sync_card_data_from_xlsx.py` after xlsx edits
- Run `python3 tools/validate_card_database.py`

