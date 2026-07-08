# AI Deck Vault — Difficulty Guide (Quick Duel)

> **Balancing playbook (tags, retags, economy, overrides):** see [`AI_DECK_VAULT_BALANCING_PLAYBOOK.md`](AI_DECK_VAULT_BALANCING_PLAYBOOK.md).

This document defines how AI deck vault entries should be tuned and scored for **Quick Duel** difficulty tiers. Use it when authoring or reviewing decks in `data/ai_deck_vault.json`.

Quick Duel picks vault entries by tag via `data/quick_duel_config.json`:

| Quick Duel tier | Vault tags matched |
|-----------------|-------------------|
| Easy | `easy` |
| Normal | `normal`, `norm` |
| Hard | `hard` |

Each vault entry should carry **one** primary difficulty tag so it lands in the intended pool.

### Quick Duel pool size target

**15 decks per tier** (45 tagged entries total). This keeps re-roll variety high (~7% repeat chance per tier with uniform random pick).

When adding or retagging entries, keep each tier at **15** — do not leave decks untagged if they are meant for Quick Duel.

---

## Design vision by tier

### Easy

- **Stat ceiling:** ATK and DEF cap at **50**. Forgivable up to **70** on one stat if the other stat is very low (≤ 25).
- **Card quality:** Mixed roster — both high-productivity cards and deck fillers.
- **Formation / unions:** Focus only on the **featured union** (or featured unit theme). Do **not** preset Plan B or Plan C union setups in the formation.

### Normal

- **Stat ceiling:** ATK and DEF cap at **100**. Forgivable up to **120** on one stat if the other stat is very low (≤ 35).
- **Card quality:** Mostly high-productivity cards; only a few fillers.
- **Formation / unions:** Formation should attempt **Plan B** and **Plan C** union summons when the deck supports them.
- **Crystal economy:** Not strict — rough cost balance is fine.

### Hard

- **Stat ceiling:** No ATK/DEF cap.
- **Card quality:** 100% high-productivity, cost-effective cards (no fillers).
- **Formation / unions:** Formation should attempt **Plan B** and **Plan C** union summons when available.
- **Crystal economy:** Tight — deliberate cheap/mid/premium curve; avoid expensive filler bodies.

---

## How each tier was scored

Use this checklist when validating a deck against a target tier.

| Criterion | Easy | Normal | Hard |
|-----------|------|--------|------|
| **Stat cap** | All characters ≤ 50 ATK/DEF, or ≤ 70 with other stat ≤ 25 | All ≤ 100, or ≤ 120 with other stat ≤ 35 | No cap |
| **Card quality** | Mixed: ≥ 2 fillers **and** ≥ 2 high-productivity cards | Mostly strong: ≥ 50% high-productivity, ≤ 25% fillers | ≥ 85% high-productivity, **0** fillers |
| **Union planning** | Featured union only; **no** Plan B/C in formation | Plan B **or** backup unions available in deck | ≥ 2 backup unions **and** Plan B in formation |
| **Crystal economy** | Loose (not scored strictly) | Loose (not scored strictly) | Tight: avg character cost ~500–720, ≥ 2 cheap (≤ 400) **and** ≥ 2 premium (≥ 700), no expensive (≥ 600) fillers |

A deck **passes** a tier when it meets **all** rows for that tier.

---

## Scoring definitions

### Productivity (card quality)

Compare each character's efficiency to the **demo card pool**:

```
efficiency = (ATK + DEF) / crystal_cost
```

| Label | Rule (demo pool percentile) |
|-------|------------------------------|
| **High-productivity** | Top ~35% efficiency |
| **Mid** | Middle band |
| **Filler** | Bottom ~35% efficiency |

Traps and techs are not part of the productivity ratio; tier scoring focuses on the character roster.

### Stat forgiveness

When checking caps, use the **higher** of ATK/DEF as the primary stat and the **lower** as the forgiving stat:

| Tier | Primary cap | Forgiving cap | Requires low other stat |
|------|-------------|---------------|-------------------------|
| Easy | 50 | 70 | ≤ 25 |
| Normal | 100 | 120 | ≤ 35 |

Example: ATK 65 / DEF 20 passes Easy (65 ≤ 70 and DEF ≤ 25).

### Featured union vs Plan B / Plan C

- **Featured union** — `featured_union` on the vault entry. The deck character list must be able to summon it (`UnionDatabase.deck_can_form_union`).
- **Backup unions** — other demo unions the same character list can summon.
- **Plan B in formation** — preset formation placements put a backup union's material cards on that union's **zone cells** (not just in the deck list).
- **Plan C** — a second backup union also zone-ready in the formation.

Easy decks should align the formation with the featured union only. Normal and Hard decks should layer backup union setups when possible.

### Crystal economy (Hard)

Rough targets for the character roster:

| Signal | Target |
|--------|--------|
| Average cost | 500–720 |
| Cheap bodies | ≥ 2 cards at ≤ 400 cost |
| Premium threats | ≥ 2 cards at ≥ 700 cost |
| Expensive fillers | 0 cards that are both filler-quality **and** ≥ 600 cost |

### Featured union fight difficulty (loose)

Score the **threat** of the featured union in battle — **not** how hard the summon formula is.

| Union fight tier | Rule of thumb |
|------------------|---------------|
| **Easy** | Peak ATK/DEF ≤ 50, **or** weak/unstable/punishing ability, **or** high stats undermined by a bad trade-off |
| **Normal** | Between easy and hard; contextual support can bump a weak body up (see below) |
| **Hard** | Peak ATK/DEF ≥ 80, **or** a genuinely strong ability, **or** low stats but a strong ability |

Deck tag should broadly match featured-union fight tier. A Hard deck should not showcase an easy-tier union; an Easy deck should not showcase a hard-tier union.

**Deck context overrides** — score the union as it will actually be played in that vault list, and weigh **`featured_unit`** when the roster’s main threat is not the union:

| Entry | Featured union | Override |
|-------|----------------|----------|
| `hard_dimensional_virus` | Dimensional Virus (0/0) | **Normal** — deck always runs `Release Mutagen`; Mutagen Flag enables “cannot be destroyed by Non-Arcane,” so the 0/0 body is a sticky permanent debuff, not a throwaway easy union |
| `norm_colormage_flayer` | Colorful Mage (40/40) | **Hard (deck stays Hard)** — union is weak on paper, but `featured_unit` is **Mind Flayer** (100/70, +50 ATK&DEF vs Anima, 1500◆ exotic). Overall deck threat is Hard even when Colorful Mage is the union headline |
| `easy_pure_moon` | Moon Tribe Shaman (25/55) | Promoted to **Normal** — weak body but revive + double cost on summon is a hard-tier union ability; too strong for Easy |
| `norm_volatile_slasher` | Volatile Slasher (50/45) | **Normal** — starts modest but gains **+50 ATK permanently** after Reckoning vs each non-Bio affinity (stacks to 100+, 150+ in logs). Snowball union; not Easy |

**Easy deck rule** — if the roster includes an overpowered non-union ace (EXOTIC, premium statline, or fight-warping legendary like Archbishop / Lab Crawler / Kiyoko), promote the vault entry to **Normal** (or Hard if warranted). Normal decks may keep premium non-union cards without retag. Easy decks should also not showcase hard-tier featured unions or **snowballing** unions (e.g. Volatile Slasher).

---

## Related files

| File | Role |
|------|------|
| [`context/AI_DECK_VAULT_BALANCING_PLAYBOOK.md`](AI_DECK_VAULT_BALANCING_PLAYBOOK.md) | **Master balancing reference** — tier lists, retag rules, economy script, overrides |
| `data/ai_deck_vault.json` | Vault entries, decks, formations, tags |
| `data/quick_duel_config.json` | Maps Quick Duel tiers → vault tags |
| `autoload/AIDeckVault.gd` | Loads vault, picks entries by tag |
| `autoload/UnionDatabase.gd` | Union zones and material conditions |
| `resources/DeckData.gd` | Deck size limits (8–12 characters, 4–6 traps, 3 tech) |

---

## Authoring notes

1. **Tag consistently** — prefer `easy`, `normal`, `hard`. Avoid duplicate or decorative tag strings.
2. **Untagged entries never appear in Quick Duel** — only exploration, campaign, and admin picks can use them.
3. **Formation matters** — Quick Duel uses vault formations as forced AI setup cells; union zone alignment affects how threatening the opening board is.
4. **Demo scope** — Quick Duel runs in demo mode; all cards and featured unions must be demo-safe (`data/demo_flags.json`).
