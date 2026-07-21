# Blightsilver — Battle HUD Style Guide (Magitech)

**Current tool for new textured UI:** [ForgeGUI](https://forgegui.com/) with **style-lock images** (not God Mode).

| Doc | Role |
|-----|------|
| **[MAGITECH_V3_FORGEGUI_PROMPTS.md](MAGITECH_V3_FORGEGUI_PROMPTS.md)** | **Active** Holy Tech / Witchhunter Corp prompts → `battle/v3_magitech/` |
| **[MAGITECH_V3_FORGEGUI_PIPELINE.md](MAGITECH_V3_FORGEGUI_PIPELINE.md)** | Style refs, `hud_skin v3` / revert `v2` |
| [MAGITECH_UI_THEME.md](MAGITECH_UI_THEME.md) | Flat chrome tokens (`MagitechTheme.gd` / GameDialog) |
| This file (below) | **Legacy Magitech v2** asset checklist + old prompt archive for `battle/v2_magitech/` |

**Skin switch:** admin `hud_skin v1|v2|v3` (`HudSkin.gd`).

---

## Active workflow (ForgeGUI) — use this

1. Open [ForgeGUI](https://forgegui.com/)  
2. Attach style refs from `assets/textures/ui/magitech_v3/_style_refs/` (holytech kit board + approved #20 panel + approved plaques)  
3. Paste **only** the **Copy this** block from [MAGITECH_V3_FORGEGUI_PROMPTS.md](MAGITECH_V3_FORGEGUI_PROMPTS.md)  
4. Save PNGs to `assets/textures/ui/battle/v3_magitech/` with the listed filenames  
5. In game: `hud_skin v3` (revert: `hud_skin v2`)  

**Consistency:** same uploaded refs every gen — ForgeGUI has no documented seed. Do not name other assets in the prompt (“match End Turn”); attach them as style images instead.  
**No baked branding** on frames (no faction names/logos) except required labels: END TURN, OPTIONS, TECH, VOID.

---

## Legacy archive — Magitech v2 (cyan / hextech)

> Historical God Mode prompt pack for `v2_magitech/`. **Do not use God Mode for new work.** Kept for shape notes and v2 asset checklist only.

**Style name (v2):** Magitech HUD / Hextech-like chrome + cyan  
**Look:** charcoal mausoleum slate **playmat floor** + polished chrome HUD/icons with electric cyan inner glow.

**Playmat vs HUD split:**

- **Playmat (#1):** cool charcoal stone / mausoleum slate plaza — stone surface, magitech silver+cyan **border frame only**
- **All other assets:** magitech chrome + cyan energy

**Approved v2 outputs (shape / finish reference for archive):**

| Asset | Status | Use as reference for |
|-------|--------|----------------------|
| `#8 ui_icon_union.png` | ✓ Approved | Round medallions; chrome + cyan finish |
| `#4 ui_end_turn.png` | ✓ Approved | Chamfered plaques |
| `#5 ui_battle_options.png` | ✓ Approved | Freeform object icons (v2 used a book) |
| `#3 ui_turn_number_panel.png` | ✓ Approved | Rounded-hex plates |

Legacy save path: `assets/textures/ui/battle/v2_magitech/`.

**Sibling legacy docs:** [BATTLE_HUD_GODMODE_PROMPTS.md](BATTLE_HUD_GODMODE_PROMPTS.md) · [BATTLE_HUD_GODMODE_PROMPTS_TOMBSTONE.md](BATTLE_HUD_GODMODE_PROMPTS_TOMBSTONE.md)

**Former tool (legacy only):** God Mode AI — superseded by ForgeGUI for Magitech v3.

### Legacy style-reference rules (still useful)

- Freeform icons: lock a freeform approved plaque — **not** a coin (coins force circles onto everything).  
- Round medallions / coins: lock a round ref only.  
- Generate one asset at a time; prompts are self-contained.  
- Fill opaque interiors on plates (hollow centers look like cutouts).  

### Labeled HUD assets (text required on art)


| Asset                    | Required text | Legibility target                 |
| ------------------------ | ------------- | --------------------------------- |
| `ui_end_turn.png`        | **END TURN**  | Readable at 160×110 display       |
| `ui_battle_options.png`  | **OPTIONS**   | Readable when lower third clipped |
| `ui_tech_stack_chip.png` | **TECH**      | Readable at 76×96 display         |
| `ui_void_stack_chip.png` | **VOID**      | Readable at 76×96 display         |


All other icons stay text-free — numbers/labels rendered in Godot.

**Avoid:** muddy brown dirt, green grass cemetery, cheap Halloween gore, oversaturated neon flood on stone, watermarks or stray text beyond the four labels above. **No pink / magenta / purple edge glow** — the Neon Cyberwave preset likes to add magenta; this kit is **chrome silver + electric cyan only**. If a result has pink/magenta rims, re-roll or refine: `Recolor all glow to electric cyan #00e5ff — remove every pink, magenta, and purple tone.`

---

## Shape variety — STOP the "circular ring everywhere" look

The kit was generating the **same chrome ring** on almost every asset. Each icon should read as its **own object silhouette**, not a coin in a ring.

> **#1 fix — the style reference image.** If you upload the coin or crystal-in-ring as the style reference, the generator copies that **circle** onto every icon no matter what the text says. For freeform icons, upload a **freeform reference (the dagger)** or **none**. This matters more than any wording below.

> **#2 fix — generate freeform icons with NO reference first.** Get the bare silhouette right (dagger, mask, shield…), then optionally upload *that* approved freeform icon as the reference for the next freeform icon — so the kit propagates a *shape-correct* look instead of a ring.

### Re-evaluated against the actual prototype HUD

The live battle screen has **almost no circular chrome**. Mapping the prototype:

- **Turn counter (top center):** a **rounded-hexagon plate** ("Turn N"), top portion clipped off-screen. NOT a circle/disc. Concentrate detail in the **lower half**.
- **Attack count (top center, tiny):** in the proto it is just **crossed swords + a number**, no ring. → **freeform**, no frame.
- **Crystal indicators (beside the score 5000 / 4700):** tiny inline crystals. → **freeform crystal**, no ring; the claw-ring base barely reads this small, keep it minimal.
- **TECH / VOID:** **circular magitech chips** with filled hextech interior (see `#9` / `#10`). **YOUR VIEW / ENEMY VIEW:** toggle uses **freeform eye-open / eye-closed icons** (`#25` / `#26`) beside label. **END TURN:** pill button / plaque.
- **OPTIONS:** spell book. **Center divider:** a diamond crest sigil.
- True circles only appear on **compass-rose card backs** (card art, not this kit) and the **coin-flip** faces.

**Intentional round / circular shapes (a ring or disc belongs here):**

- `#8 ui_icon_union` — round medallion (approved)
- `#9 ui_tech_stack_chip` / `#10 ui_void_stack_chip` — **circular chips**, hextech-filled face
- `#22 ui_coin_front` / `#23 ui_coin_back` — coin-flip overlay, round by nature

(`#3 turn counter` = **rounded-hexagon plate**, not round. Rectangular frames/bars `#20 / #21 / #15` are shaped panels, not rings.)

**Everything else (including `#7 attack count` and `#6 crystal`) = freeform object cutout, NO surrounding chrome ring or medallion border.** The shape of the dagger, mask, shield, hourglass, crystal, book, etc. IS the silhouette — note `#7` is a **shield-badge** silhouette (crossed swords behind), which is a shaped badge, not a round ring. Material/glow comes from the shared suffix — the suffix no longer forces a frame.

When a result comes back as "object floating inside a chrome ring," **first remove the circular style reference**, then refine with:

```
Remove the circular chrome frame and ring completely. Output ONLY the object — its own silhouette isolated on a transparent background. No surrounding disc, no ring, no medallion, no round border, no circle behind it.
```

---

## Shared style suffix (append to every prompt)

*(Legacy note: God Mode style presets are obsolete; Magitech v3 uses ForgeGUI style-lock images.)* The suffix describes **material and finish only** — it intentionally does **not** specify a frame or silhouette, so each asset keeps its own shape.

```
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame. Text only where asset prompt requires END TURN, OPTIONS, TECH, or VOID.
```

---

## Palette reference


| Role                       | Hex       | Notes                               |
| -------------------------- | --------- | ----------------------------------- |
| **Playmat stone base**     | `#12141a` | Charcoal mausoleum slate floor      |
| **Playmat worn flagstone** | `#181b22` | Subtle tile variation in grid zones |
| **Playmat edge vignette**  | `#0a0c10` | Outer falloff                       |
| Cracked inset (HUD/icons)  | `#141820` | Icon interior stone                 |
| Void base (HUD/icons)      | `#060810` | Medallion voids                     |
| Chrome silver              | `#c0c8d8` | Primary metal                       |
| Bright silver              | `#e8eef5` | Specular highlights                 |
| Cyan glow                  | `#00e5ff` | Inner energy conduit                |
| Cyan accent                | `#2ebfff` | Secondary glow                      |
| Deep void blue             | `#0a1628` | Medallion interiors                 |
| Tech energy                | `#00e5e5` | TECH stack edge glow                |
| Void energy                | `#7b5cff` | VOID stack — violet-cyan            |


### Playmat color (this style — stone floor + magitech frame)

**Center fill:** cool neutral `**#12141a`** charcoal mausoleum slate with subtle `**#181b22**` worn flagstone variation.  
**NOT** void-navy arena — this is a **noble necropolis plaza floor** (cool gray stone, no brown dirt, no green grass).  
**Edges:** vignette to `**#0a0c10`**.  
**Border frame (magitech):** polished chrome rails `#c0c8d8` with **cyan energy lines `#00e5ff` recessed in grooves** — same language as your coin/compass icons.  
Optional: small silver obelisk or mausoleum pillar caps at corners with faint cyan rune inlay (subtle, not cluttered).

---

## A. Full-screen backgrounds

### 1. `ui_playmat_default.png`

**Asset size:** 1280 × 720 | **Display:** full screen

**Playmat uses a different prompt** — stone floor surface, not the icon style suffix.

```
Battle playmat background frame, magitech hextech HUD on noble necropolis stone floor. Canvas exactly 1280x720 landscape PNG.

FLOOR (dominant — 80% of image):
- Cool neutral charcoal mausoleum slate #12141a, subtle worn flagstone variation #181b22
- Noble cemetery plaza texture, fine slate grain, very subtle cracks — NOT brown dirt, NOT green grass, NOT blue void navy fill
- Soft edge vignette to #0a0c10 toward screen borders
- In the center are subtle random circular Astrolabes/Astrolabes/Star Mapping Grid/ Runes

No text, no logo, no watermark, no skulls, no horror gore. Production-ready game playmat PNG.
```

**If the generator tints stone blue or brown, refine with:**

```
Cool neutral charcoal slate stone only #12141a, mausoleum floor, no blue tint, no brown dirt. Keep magitech silver cyan border frame unchanged.
```

### 2. `bg_game_over.png`

**Asset size:** 1280 × 720 | **Display:** full screen

```
Game over overlay background, magitech hextech style. Canvas exactly 1280x720 landscape PNG.
Deep void navy #060810 with heavy vignette. Ornate chrome silver arch frame #c0c8d8, electric cyan inner glow #00e5ff at center like a powered-down arcane gate. Cracked dark stone inset texture #141820. Empty center for result text. No characters, no text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

---

## B. Primary HUD chrome

### 3. `ui_turn_number_panel.png`

**Asset size:** 512 × 512 | **Display:** 280×280 (top half clipped)

**Concept:** magitech **rounded-hexagon plate** — a horizontal hex badge with softly rounded corners (not a circle, not a sharp hex). Displays top-center with the **upper portion clipped**, so weight the detail in the lower half.

> **Fill the interior!** A plain black center may be auto-removed by some generators (read as background → transparent hole). Give the face a **subtle cyan hextech interface** (circuit traces, rune ticks, hex grid) so it stays a filled, opaque screen.

```
Turn counter HUD plate, magitech hextech style. Canvas exactly 512x512, transparent PNG.
Horizontal rounded-hexagon chrome silver plate #c0c8d8 — six-sided badge with softly rounded corners and beveled metallic edges, wider than it is tall. Small chrome rivet or rune accents on the left and right points of the hex. Electric cyan inner glow #00e5ff along the inner bezel groove. Shape is a ROUNDED HEXAGON, NOT a circle, NOT a round ring or disc.

INTERIOR (must be FILLED, opaque — do NOT leave it transparent): the inside of the hexagon is a solid dark face — black to dark charcoal #0a0c12 / #141820 — covered with a SUBTLE cyan hextech interface: faint glowing circuit traces, thin hexagonal grid lines, small arcane runes, dotted data ticks and computational glyphs in #00e5ff and #2ebfff at low opacity, like a powered magitech screen. Keep it subtle and dark so a turn number stays readable on top — but the face is fully painted, never empty or cut out. ONLY the area OUTSIDE the hexagon is transparent.

Do NOT render any number or text. IMPORTANT: displays top-center with the upper portion clipped off-screen — concentrate readable detail and chrome thickness in the LOWER half. Top-center HUD.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

**If the hexagon middle comes back transparent / hollow, refine with:**

```
Fill the inside of the hexagon with a solid opaque dark screen (black to charcoal #0a0c12) covered in subtle cyan hextech detail — circuit traces, hex grid, small runes and data ticks #00e5ff. The center must NOT be transparent or hollow; only the area outside the hexagon is transparent.
```

### 4. `ui_end_turn.png`

**Asset size:** 512 × 512 | **Display:** 160×110

**✓ Approved output — reference for chamfered plaque buttons and labeled HUD chrome.**

```
End Turn button HUD element, magitech hextech style. Canvas exactly 512x512, transparent PNG.
Beveled chrome silver plaque button #c0c8d8 with chamfered corners. Cyan energy glow #00e5ff in recessed border groove. Dark cracked stone inset panel #141820. Must show readable text "END TURN" in bold chrome embossed or glowing cyan-white letters, high contrast, legible at 160x110. No other words.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 5. `ui_battle_options.png`

**Asset size:** 512 × 512 | **Display:** 230×230 (lower third clipped)

**Concept:** magitech **spell book** — standalone arcane codex; **no circular frame or medallion border**.

**✓ Approved output — reference for freeform object icons (book, sigils, standalone silhouettes).**

```
Options button, magitech hextech spell book HUD element. Canvas exactly 512x512, transparent PNG.
Closed or slightly open magitech spell book as the sole hero element — NO circular frame, NO round medallion border, NO ring surrounding the book. Standalone book only: chrome silver cover plates #c0c8d8 with beveled edges, arcane clasp or lock with cyan energy glow #00e5ff, dark cracked leather or stone-inset pages #141820 visible at spine. Subtle glowing runes or circuit-like glyph lines on cover. Book centered in composition with transparent padding around it. Must include readable text "OPTIONS" in chrome embossed or glowing cyan-white letters on cover or on a small silver nameplate above the book — legible when bottom third clipped (keep text in upper two-thirds). No other words.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 6. `ui_crystal_indicator.png`

**Asset size:** 256 × 256 | **Display:** 48×48

**Concept:** **compact crystal pylon** in a **chrome claw-prong ring** — metal **grips** the gem; moderate height, not towering.

The **pylon = slim faceted crystal** (narrow, not fat). The **mount = ring with claw prongs** wrapping the lower third — not a flat plate, not a bowl.

> **Prototype reality check:** this icon displays **tiny (~40–48px) beside the score number**, so the crystal must read clearly at a glance and the claw mount stays minimal. If the mount adds clutter at small size, fall back to a **bare faceted crystal, no mount** (matches the current prototype). It is **freeform** either way — never an outer ring/disc.

```
Crystal resource icon, magitech hextech crystal pylon in claw ring mount. Canvas exactly 256x256, transparent PNG.

CRYSTAL:
- Single **slender faceted cyan crystal** #00e5ff — narrow hexagonal prism or short obelisk, pointed or faceted top
- **Moderate height only** — crystal ~1.5–2× its width, **compact badge proportions**, NOT towering, NOT skyscraper spike, NOT fat squat orb
- Internal cyan glow, sharp facets, light refraction

MOUNT (claw prongs of ring — metal grips the crystal):
- **Chrome silver setting ring** #c0c8d8 with **3–4 curved claw prongs** gripping the **lower third** of the crystal — jeweler's claw setting or magitech gem holder ring
- Low wide ring band at the foot, prongs arc inward to hold the gem; crystal seated in the prong ring, not floating above a flat disc
- Beveled metal, subtle cyan energy seams #00e5ff in prong grooves
- Ring + prongs combined height ≤ ~30% of total icon — **NO tall chrome pillar, NO metal shaft, NO column**, **NO bowl, NO dish, NO goblet shape**

NO circular medallion frame. NO diamond badge border. Readable at 48px. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

**Refine if wrong shape:**

Too tall / towering:

```
Shorter crystal. Compact HUD badge size — crystal height only 1.5× width. Chrome claw prongs of a ring grip the lower third of the gem.
```

Fat / squat crystal:

```
Narrower crystal facets — slim pylon shape, not a fat gem blob. Still held by claw prongs of a chrome ring.
```

Flat plate or bowl instead of claw ring:

```
Metal must be a ring with curved claw prongs gripping the crystal lower third — jeweler's setting. Not a flat disc, not a bowl, not a dish under a floating gem.
```

Tall metal pillar:

```
No chrome column. Only a low claw-prong ring mount gripping the crystal base.
```

### 7. `ui_icon_attack_count.png`

**Asset size:** 256 × 256 | **Display:** 72×72

**Concept:** magitech **shield badge** with **crossed swords behind** it — the shield holds the number; swords peek out past the edges. Shield silhouette, not a round ring.

```
Attacks remaining badge, magitech hextech style. Canvas exactly 256x256, transparent PNG.
Magitech shield badge with crossed swords behind it. Beveled chrome silver heraldic shield #c0c8d8 as the front hero element, cyan energy glow #00e5ff in its grooves, dark cracked charcoal face #141820. Two chrome swords crossed in an X BEHIND the shield, their blade tips and pommels peeking out past the shield edges. Empty shield face center for the number — do NOT render numbers or text. Shield silhouette is the badge shape — NOT a round ring or disc, NOT a circular medallion. Readable at 72px.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 8. `ui_icon_union.png`

**Asset size:** 512 × 512 | **Display:** 110×110; also 52×52 in context menu

**Concept:** **two spirits / souls merging** inside a **round chrome medallion** — silver + cyan only, no pink.

**✓ Approved output — use as the kit's gold-standard style reference** (chrome finish, cyan glow, filled dark face, no pink/magenta).

```
Union summon button icon, magitech hextech style. Canvas exactly 512x512, transparent PNG.
ROUND chrome silver medallion frame #c0c8d8 with beveled metallic edges and electric cyan inner glow #00e5ff in the bezel groove — a circular button. Inside, on a solid dark void face #060810 / #0a0c12, two ghost / soul entities as the hero element: a pair of glowing translucent cyan spirit wisps #00e5ff and #2ebfff with simple wraith-like heads and flowing trailing tails, mirrored and intertwining toward each other so they merge into one at the center with a bright cyan fusion glow. Ethereal, smoky, semi-transparent souls. The interior face is FILLED/opaque (not transparent); only the area outside the round medallion is transparent. Strong readable at 110px.
COLOR: chrome silver and electric cyan ONLY — absolutely NO pink, NO magenta, NO purple/violet edge glow anywhere on the frame or souls. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

---

## C. Tech & Void stack chips

Generate **#9 and #10 separately** — each prompt is **self-contained**. Do **not** paste "match TECH" as if the tool can see other assets — attach style refs as images instead.

### 9. `ui_tech_stack_chip.png`

**Asset size:** 128 × 128 | **Display:** 76×96

**Concept:** **circular TECH chip** — round chrome disc with filled cyan hextech screen face (no cracked stone).

```
Tech discard stack widget, magitech hextech style. Canvas exactly 128x128, transparent PNG.
CIRCULAR chrome silver disc chip #c0c8d8 with beveled rim and electric cyan inner glow #00e5ff in the bezel groove — a round magitech button/badge. INTERIOR (filled, opaque — NOT cracked stone, NOT transparent): solid dark face black to charcoal #0a0c12 / #141820 covered with SUBTLE cyan hextech interface — faint circuit traces, thin hex grid lines, small arcane runes, dotted data ticks and computational glyphs in #00e5ff and #2ebfff at low opacity, like a powered magitech screen. Cyan tech energy accent #00e5e5 on inner rim optional. Must include readable text "TECH" in chrome or glowing cyan letters, centered, legible at 76x96. Empty count badge corner — do NOT render numbers. Only area outside the circle is transparent. No other words.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

**If center is transparent or shows cracked stone instead of hextech, refine with:**

```
Fill the circle with a solid opaque dark screen and subtle cyan hextech detail — circuit traces, hex grid, runes #00e5ff. No cracks, no plain empty hole; only outside the circle is transparent.
```

### 10. `ui_void_stack_chip.png`

**Asset size:** 128 × 128 | **Display:** 76×96

**Concept:** **circular VOID chip** — round chrome disc, void-violet rim accent, filled cyan hextech screen face (no cracked stone).

```
Void discard stack widget, magitech hextech style. Canvas exactly 128x128, transparent PNG.
CIRCULAR chrome silver disc chip #c0c8d8 with beveled rim and electric cyan inner glow #00e5ff in the bezel groove — a round magitech button/badge. Subtle violet-cyan void energy accent #7b5cff on the outer rim groove. INTERIOR (filled, opaque — NOT cracked stone, NOT transparent): solid dark face black to charcoal #0a0c12 / #141820 covered with SUBTLE cyan hextech interface — faint circuit traces, thin hex grid lines, small arcane runes, dotted data ticks and computational glyphs in #00e5ff and #2ebfff at low opacity, like a powered magitech void screen. Must include readable text "VOID" in chrome or glowing pale violet-white letters, centered, legible at 76x96. Empty count badge corner — do NOT render numbers. Only area outside the circle is transparent. Chrome silver and cyan glow only — NO pink, NO magenta. No other words.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

**If center is transparent or shows cracked stone instead of hextech, refine with:**

```
Fill the circle with a solid opaque dark screen and subtle cyan hextech detail — circuit traces, hex grid, runes #00e5ff. No cracks, no plain empty hole; only outside the circle is transparent.
```

---

## D. Card context menu icons (display 52×52)

Small **freeform cutouts** in the card sub-menu strip — each icon is **only the object** (blade, **"i"**, smiley…), **no circular frame**. Generate each prompt **alone**; do not rely on naming other assets in text — attach style-ref images.

### 11. `ui_context_menu_attack.png`

**Asset size:** 128 × 128 | **Display:** 52×52 in card sub-menu

**Concept:** diagonal **chrome dagger / short sword** — **sharp, crisp silhouette** for 52px sub-menu; weapon blade only, not a moon, not a ring badge.

```
Context menu icon: Attack, magitech hextech style. Canvas exactly 128x128, transparent PNG.

HERO (weapon only — fills most of the canvas):
- Single chrome silver dagger or short sword #c0c8d8, diagonal (tip upper-right, hilt lower-left)
- **SHARP CRISP SILHOUETTE** — hard beveled metal edges, razor-sharp point, clean angular blade profile (narrower blade OK). Tight readable outline at 52px
- Electric cyan energy #00e5ff in a **thin** blade fuller or edge line — accent only, NOT a soft blob filling the whole blade
- **Crisp specular highlights** on metal; **minimal bloom/blur**. Hard-edged premium game icon render, NOT painterly, NOT soft focus, NOT rounded mushy edges

FORBIDDEN — do NOT generate:
- NO circular ring, disc, medallion, or badge frame
- NO crescent moon, lunar arc, or abstract sigil
- NO fat soft glowing blade blob with blurry edges
- NO shield-only without a blade

No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

**Style reference:** upload **OPTIONS book** or **END TURN plaque** (freeform) — **NOT** Union/coin.

**If moon-in-ring or wrong symbol:**

```
Diagonal chrome dagger or short sword only. No moon, no circular frame. Cyan glow in blade fuller. Transparent background.
```

**If too soft / not sharp enough:**

```
Sharpen the silhouette. Hard crisp metal edges, razor point, tight angular blade. Reduce soft glow and bloom — thin cyan accent line in fuller only. Crisp game UI icon, not painterly blur.
```

### 12. `ui_context_menu_info.png`

**Asset size:** 128 × 128 | **Display:** 52×52 in card sub-menu

**Concept:** magitech **letter "i"** on a **hextech-filled face** — classic info glyph, not compass or magnifier.

```
Context menu icon: Info / Inspect, magitech hextech style. Canvas exactly 128x128, transparent PNG.

HERO: bold **letter "i"** (lowercase or serif) — chrome silver #c0c8d8, beveled metallic stroke, dot and stem clearly separated, electric cyan glow #00e5ff on edges. Sharp crisp silhouette readable at 52px.

BACKGROUND FACE (behind/under the "i" — filled, opaque, NOT cracked stone):
- Small dark plaque or letter backing black to charcoal #0a0c12 / #141820
- Covered with SUBTLE cyan hextech interface — faint circuit traces, thin hex grid lines, small arcane runes, dotted data ticks and computational glyphs in #00e5ff and #2ebfff at low opacity
- Fully painted screen texture — **NO cracks**, **NO plain empty transparent hole** in the middle; only area outside the icon shape is transparent

FORBIDDEN: NO compass rose, NO magnifying glass, NO circular ring or medallion frame, NO extra symbols or letters.

No other text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

**If center is transparent or shows cracks instead of hextech, refine with:**

```
Fill the area behind the letter i with solid dark screen and subtle cyan hextech detail — circuit traces, hex grid, runes #00e5ff. No cracks, no hollow center.
```

### 13. `ui_context_menu_bluff.png`

**Asset size:** 128 × 128 | **Display:** 52×52 in card sub-menu

**Concept:** **freeform smiley face** — magitech chrome/cyan, playful bluff expression; not a mask sigil.

```
Context menu icon: Bluff, magitech hextech style. Canvas exactly 128x128, transparent PNG.

HERO: a **freeform smiley face** — simple round or slightly oval face shape as the entire icon. Chrome silver #c0c8d8 metallic outline or beveled face rim, two eyes and a curved smile (sly or playful smirk OK for "bluff"). Subtle electric cyan glow #00e5ff on edges or eyes. Dark charcoal face fill #141820 optional inside the smiley only. The smiley silhouette IS the icon on transparent background.

FORBIDDEN: NO masquerade mask, NO jagged sigil, NO circular medallion frame or disc around the face, NO extra symbols.

No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 14. Union context menu

**Reuse #8** `ui_icon_union.png` — scaled to 52×52 in-engine.

### 15. `ui_context_menu_panel.png` (optional)

**Asset size:** 512 × 128

```
Card context menu strip background, magitech hextech style. Canvas exactly 512x128 PNG.
Dark cracked charcoal bar #141820 with chrome silver beveled border #c0c8d8 and cyan inner glow groove #00e5ff. Rounded pill ends. Empty center for icon slots. No embedded icons.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

---

## E. Card grid status overlays (display ~58×58)

### 16. `ui_icon_wait_2.png`

**Asset size:** 128 × 128 | **Display:** ~58×58 on card

**Concept:** **sand clock / hourglass** — cooldown / already attacked.

```
Card status: cooldown / already attacked, magitech hextech style. Canvas exactly 128x128, transparent PNG.

HERO: a **sand clock hourglass** — two glass bulbs with sand flowing (or settled) between chrome silver caps #c0c8d8. Beveled metallic top and bottom frames, visible sand grains inside, subtle cyan glow #2ebfff on glass edges optional. Freeform hourglass silhouette on transparent background — NO surrounding ring, disc, or medallion frame. Readable at 58px. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 17. `ui_icon_exposed.png`

**Asset size:** 128 × 128

```
Card status: Exposed, magitech hextech style. Canvas exactly 128x128, transparent PNG.
Chrome cracked shield or eye sigil #c0c8d8 with amber warning gem #ffd933 and cyan rim #00e5ff. Freeform sigil silhouette on transparent background — NO surrounding chrome ring or disc. Readable at 58px. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 18. `ui_icon_trap.png`

**Asset size:** 128 × 128 | **Display:** ~58×58 on card

**Concept:** **red dynamite stick** with fuse — trap armed.

```
Card status: Trap armed, magitech hextech style. Canvas exactly 128x128, transparent PNG.

HERO: a **stick of red dynamite** — cylindrical red body #ff4d4d / #cc2222 with chrome silver or dark metal end caps #c0c8d8, short lit or unlit fuse with tiny spark optional. Magitech hazard feel — subtle cyan rim accent #00e5ff on metal caps OK. Freeform dynamite silhouette on transparent background — NO jaws glyph, NO surrounding ring or disc. Readable at 58px. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 19. `ui_icon_blank_found.png`

**Asset size:** 128 × 128 | **Display:** ~58×58 on card

**Concept:** **fishbone** — blank slot found / empty grid cell marker.

```
Card status: Blank slot found, magitech hextech style. Canvas exactly 128x128, transparent PNG.

HERO: a **fishbone** skeleton — central spine with rib bones, chrome silver #c0c8d8 metallic bone texture with subtle cyan edge glow #00e5ff. Simple iconic fishbone silhouette (X-shaped ribs on a vertical spine). Freeform bone shape on transparent background — NO diamond frame, NO dashed void box, NO surrounding ring or disc. Readable at 58px. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

---

## F. Options menu panels

### 20. `ui_panel_frame_9slice.png`

**Asset size:** 512 × 512 | NinePatch margins ~110px

```
Modal panel 9-slice frame, magitech hextech style. Canvas exactly 512x512 PNG.
Dark cracked charcoal fill #141820, beveled chrome border #c0c8d8, cyan energy groove glow #00e5ff on inner edge. Diamond corner accents. Empty center. NinePatch ~110px margins.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 21. `ui_options_menu_row.png`

**Asset size:** 512 × 64 | **Display height:** 48px

```
Options menu row button, magitech hextech style. Canvas exactly 512x64 PNG.
Dark cracked inset #141820, chrome beveled border #c0c8d8, cyan hover glow in groove #00e5ff. Empty center for text. Height 48px display.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

---

## G. Secondary battle assets

### 22. `ui_coin_front.png`

**Asset size:** 512 × 512

```
Coin flip front face, magitech hextech style. Canvas exactly 512x512, transparent PNG.
Circular chrome medallion #c0c8d8 with embossed heroic bust or crest, deep void blue interior #0a1628, cyan lightning or rune ring #00e5ff. Match reference Zeus coin style. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 23. `ui_coin_back.png`

**Asset size:** 512 × 512

```
Coin flip back face, magitech hextech style. Canvas exactly 512x512, transparent PNG.
Circular chrome medallion #c0c8d8 with compass rose and runic ring, void starfield inset, cyan glow #00e5ff. Match reference compass coin back. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 24. `ui_icon_defend.png`

**Asset size:** 128 × 128 | Reckoning overlay

```
Reckoning defend icon, magitech hextech style. Canvas exactly 128x128, transparent PNG.
Chrome kite shield #c0c8d8 with cyan energy core #00e5ff. Beveled metal. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 25. `ui_view_eye_open.png`

**Asset size:** 128 × 128 | **Display:** ~24×24 beside YOUR VIEW toggle

**Concept:** **freeform open eye** — magitech chrome eyelid + cyan glow; YOUR VIEW / normal board state.

```
View toggle icon — eye open, magitech hextech style. Canvas exactly 128x128, transparent PNG.
Freeform chrome silver magitech eye OPEN #c0c8d8 — visible iris and pupil, cyan energy glow #00e5ff in lid seams and iris ring. Beveled metallic eyelid shape, readable at 24px. The eye silhouette IS the icon on transparent background — NO outer circular ring, disc, chip bar, or medallion frame. No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

### 26. `ui_view_eye_closed.png`

**Asset size:** 128 × 128 | **Display:** ~24×24 beside ENEMY VIEW toggle

**Concept:** **freeform closed eye only** — shut lid or slashed eye shape; ENEMY VIEW state. **No outer circle.**

```
View toggle icon — eye closed, magitech hextech style. Canvas exactly 128x128, transparent PNG.

HERO: a **freeform closed eye** only — chrome silver #c0c8d8 almond-shaped **shut eyelid**, OR a single eye shape with a **diagonal slash through the eye itself** (visibility-off). Muted cyan glow #2ebfff along the lid edge. Beveled metallic eyelid, readable at 24px.

FORBIDDEN — this is NOT a prohibition-sign icon:
- NO outer circular ring, disc, or medallion border around the eye
- NO thick circle frame with the eye/slash inside (like a "no" traffic sign)
- NO badge, chip bar, or round button shape — only the eye/lid silhouette on transparent background

No text.
Style: magitech hextech premium game UI icon, polished chrome silver #c0c8d8 and #e8eef5, electric cyan inner glow #00e5ff and #2ebfff in seams and grooves, dark cracked charcoal metal #141820, beveled metallic edges, subtle arcane runes optional, high-fidelity 3D game asset render, isolated on transparent background, crisp highlights, no watermark, production-ready. Only the object itself — NO enclosing circle, ring, disc, or medallion frame around the icon unless the asset description explicitly asks for a frame.
```

**Style reference:** **OPTIONS** or **END TURN** (freeform) — **NOT** Union/coin (causes circular ring).

**If result has outer circle / prohibition ring, refine with:**

```
Remove the outer circle completely. Only the closed eye or slashed eye shape on transparent background — no round frame, no medallion, no prohibition-sign ring.
```

**Godot wiring note:** YOUR VIEW / ENEMY VIEW toggle swaps `#25` open ↔ `#26` closed icon beside button text (replaces old `ui_enemy_view_chip` bar concept).

---

## Bonus: Game UI Agent moodboard (optional)

**Asset size:** 1280 × 720

```
Magitech hextech CCG battle HUD on noble necropolis stone playmat, 1280x720 landscape.

Layout:
- Charcoal mausoleum slate floor #12141a with subtle #181b22 flagstone variation (center dominant)
- Two 5x5 card grid zones on stone surface with faint thin chrome silver grid lines and subtle cyan energy accent #00e5ff
- Center column for turn info
- Top-left: crystal counter badge (compact crystal in claw-prong ring)
- Top-right: opponent crystal counter (same)
- Top-center: rounded-hexagon magitech turn counter plate with cyan tech-grid
- Top-center-right: attack count badge
- Bottom-center: end turn beveled chrome button
- Bottom edge: options magitech spell book button
- Left mid: TECH and VOID **circular magitech chips** (hextech-filled face, cyan/violet rim accents)
- Playmat border: chrome silver rails #c0c8d8 with cyan energy grooves #00e5ff, optional corner obelisk caps

Style:
- Stone floor = cool gray charcoal slate (NOT void navy arena, NOT brown dirt)
- HUD/icons = polished chrome silver #c0c8d8, electric cyan inner glow #00e5ff
- Beveled metallic edges; each icon its own silhouette (avoid stamping the same ring on everything)
- High-fidelity 3D premium game UI mockup
- No characters, no card art, no text, no watermark
- Output exactly 1280x720 PNG
```

---

## Style comparison (pick one kit)


| Variant      | Playmat base                                       | Metal                     | Accent                | Render                   |
| ------------ | -------------------------------------------------- | ------------------------- | --------------------- | ------------------------ |
| Sci-fi flat  | `#04060d` navy                                     | `#c8d4e0` flat silver     | `#2ebfff` cyan        | Flat illustrated         |
| Tombstone    | `#12141a` charcoal stone                           | `#d4dce6` polished silver | `#e8eef5` moonlight   | Flat gothic              |
| **Magitech** | `**#12141a` mausoleum slate** + chrome/cyan border | `#c0c8d8` chrome          | `#00e5ff` energy glow | **3D premium HUD icons** |


---

## Checklist (26 assets — 25 unique PNGs; union context reuses #8)

- 1  ui_playmat_default.png          1280×720
- 2  bg_game_over.png                1280×720
- 3  ui_turn_number_panel.png        512×512  ✓ approved (rounded hex)
- 4  ui_end_turn.png                 512×512  **✓ Approved**
- 5  ui_battle_options.png           512×512  **✓ Approved**
- 6  ui_crystal_indicator.png        256×256
- 7  ui_icon_attack_count.png        256×256
- 8  ui_icon_union.png               512×512  ✓ approved — **gold-standard reference**
- 9  ui_tech_stack_chip.png          128×128
- 10 ui_void_stack_chip.png          128×128
- 11 ui_context_menu_attack.png      128×128
- 12 ui_context_menu_info.png        128×128
- 13 ui_context_menu_bluff.png       128×128
- 14 (union context = reuse #8)
- 15 ui_context_menu_panel.png       512×128  (optional)
- 16 ui_icon_wait_2.png              128×128
- 17 ui_icon_exposed.png             128×128
- 18 ui_icon_trap.png                128×128
- 19 ui_icon_blank_found.png         128×128
- 20 ui_panel_frame_9slice.png       512×512
- 21 ui_options_menu_row.png         512×64
- 22 ui_coin_front.png               512×512
- 23 ui_coin_back.png                512×512
- 24 ui_icon_defend.png              128×128
- 25 ui_view_eye_open.png            128×128
- 26 ui_view_eye_closed.png          128×128

