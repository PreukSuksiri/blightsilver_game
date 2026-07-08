# AI Deck Vault — Balancing Playbook

**Last updated:** 2026-07-07

This is the **master reference** for Quick Duel vault balancing decisions. Use it when retagging decks, revisiting difficulty, or running economy passes.

Companion doc (scoring checklist): [`AI_DECK_VAULT_DIFFICULTY_GUIDE.md`](AI_DECK_VAULT_DIFFICULTY_GUIDE.md).

---

## Quick reference

| Item | Value |
|------|-------|
| Pool size | **15 decks per tier** (45 total) |
| Source of truth (tags) | `tools/rebalance_vault_economy.py` → `TAG_BY_ID` |
| Source of truth (decks) | `data/ai_deck_vault.json` |
| Apply tags + economy | `python3 tools/rebalance_vault_economy.py` |
| Quick Duel tag mapping | `data/quick_duel_config.json` (`easy` / `normal` / `hard`) |
| Demo scope | All roster cards + featured unions must be in `data/demo_flags.json` |

---

## Two different “difficulty” axes (do not confuse)

### 1. Fight difficulty (what we score for tiers)

How threatening the deck is **in battle** — union stats/abilities, non-union aces, tech support, formation.

### 2. Summon formula difficulty (NOT used for tier tags)

How expensive or fiddly a union is to assemble (summon fee, named materials, `min_cost` gates). A 300◆ affinity-only union can be **easy to summon** but still **weak in combat** (e.g. False Prophet). Do **not** use summon formula alone to set Easy/Normal/Hard.

---

## Tier design vision

### Easy

- Character ATK/DEF ceiling: **50** (forgiving **70** on one stat if the other ≤ 25).
- Mixed roster: fillers + some strong cards.
- Formation: **featured union only** — no Plan B/C preset in formation.
- **No overpowered non-union aces** in the live roster.
- **No hard-tier featured unions** (see union fight rules below).
- Crystal economy: loose; anti-suicidal tech only.

### Normal

- Character ceiling: **100** (forgiving **120** / other stat ≤ 35).
- Mostly productive cards; a few fillers OK.
- Plan B (or backup unions) in formation when the list supports it.
- **May include overpowered non-union cards** — no retag required.
- Crystal economy: mild tightening OK.

### Hard

- No stat cap; **no fillers**; cost-effective curve.
- Plan B + multiple backup unions when possible.
- Tight crystal economy: avg ~500–720◆, cheap + premium bodies, no expensive fillers.
- Featured union should be a real threat (or documented override below).

---

## Union fight difficulty (loose)

Score **`featured_union`** combat threat, not summon cost.

| Union fight tier | Rule of thumb |
|------------------|---------------|
| **Easy** | Peak ATK/DEF ≤ 50, **or** weak/unstable/punishing ability, **or** strong-looking stats undermined by bad trade-off |
| **Normal** | In between; deck context can bump a weak body (see overrides) |
| **Hard** | Peak ATK/DEF ≥ 80, **or** genuinely strong ability, **or** low stats but strong ability |

**Easy deck:** featured union should be Easy (or at most Normal).  
**Hard deck:** featured union should not be Easy-tier unless overridden.

---

## Non-union ace (“featured_unit”) rules

The real threat may be a **character**, not the union.

### Overpowered non-union (promote Easy → Normal)

Treat as OP if **any** of:

- `EXOTIC` rarity
- ATK ≥ 100 or DEF ≥ 100
- ATK + DEF ≥ 150 **and** cost ≥ 1000◆
- `+50 ATK&DEF` style affinity bonus (e.g. Mind Flayer, Kiyoko)
- Known bombs: Archbishop, Lab Crawler, Tomb Bandit, Pit Lord, Immortal Vampire, Leorudus the Warlord, Mind Flayer

**Easy decks must not run these in the live roster.** Promote to **Normal** (or Hard if the whole package warrants it). When promoting, demote a safe Easy deck to keep **15 per tier**.

**Normal decks may keep OP non-union cards** — no retag required.

### `featured_unit` vs roster

- `featured_unit` is metadata for theme/docs; **tier scoring uses the actual roster**.
- If `featured_unit` names a card not in `deck.characters`, it does **not** count unless you restore that card.

---

## Documented deck context overrides

| Vault ID | Tag | Featured union | Notes |
|----------|-----|----------------|-------|
| `hard_dimensional_virus` | Hard | Dimensional Virus (0/0) | Union body is weak alone; deck always runs **`Release Mutagen`** → Mutagen Flag → “cannot be destroyed by Non-Arcane.” Treat union threat as **Normal**, deck stays **Hard**. |
| `norm_colormage_flayer` | Hard | Colorful Mage (40/40) | Union is easy-tier; **`featured_unit` = Mind Flayer** (100/70, +50 vs Anima). Deck threat is **Hard**. **Known gap:** economy pass swapped Mind Flayer → Book with Fangs in roster; metadata kept for identity. Restore Mind Flayer if you want live Hard ace. |
| `easy_pure_moon` | **Normal** | Moon Tribe Shaman (25/55) | Promoted from Easy: revive + double revived cost is hard-tier union play. |

---

## Economy rebalance (`rebalance_vault_economy.py`)

### Tech loadouts by tier

| Tier | Typical tech trio |
|------|-------------------|
| Hard | `Spy`, `Tease`, `Radar` (bio: `Release Mutagen`, `Spy`, `Radar`; divine: `Prayer`, `Spy`, `Radar`) |
| Normal | `Spy`, `Bribe`, `Radar` or `Spy`, `Radar`, `Tease` |
| Easy | `Spy`, `Tease`, `Radar` or light fix: `Spy`, `Bribe`, `Tease` |

### What the script does

1. `normalize_tags()` — applies `TAG_BY_ID` to every vault entry.
2. `apply_patches()` — roster/tech/formation swaps per deck (`PATCHES` dict).
3. `validate()` — demo-safe cards, deck size, duplicates.
4. Writes `data/ai_deck_vault.json`.

**Always edit `TAG_BY_ID` and `PATCHES` in the script, then run:**

```bash
python3 tools/rebalance_vault_economy.py
```

Do not hand-edit tags in JSON without updating `TAG_BY_ID` — they will be overwritten on the next run.

---

## Current tier assignment (2026-07-07)

Canonical list lives in `tools/rebalance_vault_economy.py` → `TAG_BY_ID`. Snapshot:

### Easy ×15

`easy_kitsune`, `easy_pixie_queen`, `easy_diamond_unicorn`, `easy_gamma`, `easy_skeleton`, `easy_ten_arms`, `easy_rebel_king`, `easy_sky_protector`, `normal_vergaia`, `norm_miner_moon`, `norm_greater_succubus`, `easy_lab_mutagen`, `norm_choir_lead`, `norm_xdeath`, `norm_grand_fort_captain`

### Normal ×15

`norm_volatile_slasher`, `easy_pure_moon`, `easy_false_prophet_casino`, `easy_moon_lady_ninja`, `easy_wk17_roulette`, `easy_kiba`, `easy_vampire`, `hard_venom`, `new_ai_deck_19`, `norm_thunder_elemental`, `norm_legendary_locksmith`, `norm_leorudus`, `norm_raijin_fujin`, `norm_shark`, `normal_chaos_bio`

### Hard ×15

`norm_phoenix`, `norm_colormage_flayer`, `hard_barros`, `hard_team_galaxos`, `hard_dimensional_virus`, `hard_full_emental`, `hard_gaia_arcane`, `hard_gryphon`, `hard_helios`, `hard_lord_of_terror`, `hard_rocket_peacock`, `hard_seraphim_fistmaster`, `hard_zealot_kiba`, `norm_armored`, `norm_wood_elemental`

---

## Retag workflow (checklist)

When adding or changing a vault deck:

1. **Demo-safe** — every character, trap, tech, featured union in `demo_flags.json`.
2. **Fight difficulty** — featured union tier + scan roster for OP non-union aces.
3. **Easy gate** — if Easy: no OP non-union in roster; no hard featured union.
4. **Economy** — Hard gets strict curve; Normal mild; Easy light / fix suicidal tech.
5. **Update `TAG_BY_ID`** — keep 15/15/15.
6. **Update `PATCHES`** if roster/tech swaps needed (e.g. remove Archbishop from Easy choir deck).
7. **Run** `python3 tools/rebalance_vault_economy.py` → must print `Validation OK`.
8. **Document overrides** in this file if a deck is an intentional exception.

---

## Audit snippets (copy-paste)

Tag counts:

```bash
python3 -c "
import json; from collections import Counter
v=json.load(open('data/ai_deck_vault.json'))
print(dict(Counter(e['tags'][0] for e in v['entries'])))
"
```

Sync tags from script without full patches (tags only):

```bash
python3 -c "
import json, sys; sys.path.insert(0,'tools')
from rebalance_vault_economy import TAG_BY_ID, normalize_tags, VAULT_PATH
v=json.loads(VAULT_PATH.read_text()); normalize_tags(v)
VAULT_PATH.write_text(json.dumps(v, indent='\t')+'\n')
"
```

---

## History of major balancing decisions (2026-06 / 2026-07)

- Removed duplicate / clone vault decks; expanded to **45 demo-scoped** entries with union showcases.
- **False Prophet** and **WK-17** removed from Hard (weak union bodies); replaced on Hard by **Phoenix** and **Colormage Flayer**.
- Strict **Hard economy** pass: productive rosters, tiered tech, no expensive fillers.
- **Easy OP promotion:** False Prophet (Archbishop), Moon Lady Ninja (Kiyoko), WK-17 (Lab Crawler), Pure Moon (Moon Tribe Shaman union).
- **Easy replacements:** Lab Mutagen, Volatile Slasher, Choir Lead (roster trimmed), X-Death (roster trimmed), Venom/Shark returned to Normal.
- **Duplicate Helios removed:** `hard_cos_dreadnought` (clone of `hard_helios`) replaced by **`hard_team_galaxos`** — unfeatured demo union (85/85, summon immunity for Cosmic+Anima allies) + **Satellite Cannon** OP ace.

---

## Related files

| File | Role |
|------|------|
| [`context/AI_DECK_VAULT_DIFFICULTY_GUIDE.md`](AI_DECK_VAULT_DIFFICULTY_GUIDE.md) | Scoring checklist, stat caps, productivity math |
| [`tools/rebalance_vault_economy.py`](../tools/rebalance_vault_economy.py) | `TAG_BY_ID`, `PATCHES`, rebalance runner |
| [`data/ai_deck_vault.json`](../data/ai_deck_vault.json) | Vault entries |
| [`data/quick_duel_config.json`](../data/quick_duel_config.json) | Quick Duel tier → tag mapping |
| [`autoload/AIDeckVault.gd`](../autoload/AIDeckVault.gd) | Vault load, demo validation, random pick |
| [`trash/data/ai_deck_vault_replaced_clones.json`](../trash/data/ai_deck_vault_replaced_clones.json) | Removed duplicate decks (soft-delete) |
