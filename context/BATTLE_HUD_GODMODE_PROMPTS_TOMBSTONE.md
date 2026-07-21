# Blightsilver — Battle HUD Prompts (Tombstone / Necropolis Style) — LEGACY

> **Archive only.** New UI chrome uses **ForgeGUI** + [MAGITECH_V3_FORGEGUI_PROMPTS.md](MAGITECH_V3_FORGEGUI_PROMPTS.md). Former tool was God Mode.

**Variant:** Noble cemetery · aristocratic necropolis · polished silver metallic  
**Sibling docs:**
- [`BATTLE_HUD_GODMODE_PROMPTS.md`](BATTLE_HUD_GODMODE_PROMPTS.md) (sci-fi cyan style)
- [`BATTLE_HUD_GODMODE_PROMPTS_MAGITECH.md`](BATTLE_HUD_GODMODE_PROMPTS_MAGITECH.md) (magitech / hextech — matches your generated coin, crystal, dagger, compass icons)

**Tool:** [God Mode AI](https://www.godmodeai.co/) → Game UI Generator  
**Viewport:** 1280×720  
**Workflow:** Manual — paste each prompt, set Asset Size, generate, download PNG  
**Save exports to:** `assets/textures/ui/battle/v2_tombstone/`

### God Mode style preset (UI only — do not paste into prompts)

When God Mode AI offers a **style** or **overlay** picker, select:

**Overgrown Jungle stone**

Best for **stone surfaces and necropolis atmosphere** — weathered charcoal slate, subtle moss in cracks, ancient mausoleum floor texture. Pairs well with this kit’s silver engraved HUD.

**Important:** Set the preset in God Mode's style UI only. **Do not** include `Overgrown Jungle stone` (or any preset name) inside the copy-paste prompts below.

**Workflow with preset:**
1. Set style to **Overgrown Jungle stone** in the God Mode UI
2. Paste the asset prompt + shared style suffix (preset name omitted from text)
3. Upload approved **playmat (#1)** as style reference for remaining assets
4. For **playmat (#1):** lean into full preset — overgrown stone plaza, silver rails, minimal neon
5. For **HUD icons (#3–#25):** silver trim and engraved text must stay **clean and readable** — moss only as faint edge accent, not covering labels

If jungle/moss overwhelms silver HUD elements, refine with:
```
Reduce moss and vines on metal. Keep weathered stone texture on background only. Silver engraved text and borders must stay sharp and readable.
```

**ORDER:** Generate #1 (playmat) first, then upload it as style reference for all other assets.

### Labeled HUD assets (text required on art)

| Asset | Required text | Legibility target |
|-------|---------------|-------------------|
| `ui_end_turn.png` | **END TURN** | Readable at 160×110 display |
| `ui_battle_options.png` | **OPTIONS** | Readable when lower third clipped |
| `ui_tech_stack_chip.png` | **TECH** | Readable at 76×96 display |
| `ui_void_stack_chip.png` | **VOID** | Readable at 76×96 display |

All other icons stay text-free — numbers/labels rendered in Godot.

**Avoid:** neon glow, sci-fi HUD, cheap horror gore, skull piles, dripping blood, cheesy Halloween clip art.

---

## Shared style suffix (append to every prompt)

God Mode **style preset** is selected in the generator UI — not in this text.

```
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready. Text only where asset prompt requires END TURN, OPTIONS, TECH, or VOID.
```

---

## A. Full-screen backgrounds

### 1. `ui_playmat_default.png`
**Asset size:** 1280 × 720 | **Display:** full screen

**Playmat:** lean into **Overgrown Jungle stone** — full moss-in-cracks stone plaza; silver rails stay clean.

```
Battle playmat background frame, noble necropolis theme, weathered overgrown mausoleum plaza with moss in stone cracks. Canvas exactly 1280x720 landscape PNG.
Dark charcoal stone center #12141a like a weathered mausoleum floor with subtle moss and vine growth in cracks only — not lush jungle canopy. Polished silver railing borders #d4dce6 on all edges. Corner posts shaped like small silver tombstone obelisks or mausoleum pillars. Thin moonlight silver inset line #e8eef5. Soft mist vignette at edges. Empty center for two 5x5 card grids and center column. No characters, no cards, no text, no logo, no crosses with blood.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 2. `bg_game_over.png`
**Asset size:** 1280 × 720 | **Display:** full screen

```
Game over overlay background, noble necropolis theme. Canvas exactly 1280x720 landscape PNG.
Deep charcoal void #0a0c10 with heavy vignette. Ornate silver mausoleum arch frame #d4dce6, faint moonlight silver glow #e8eef5 at center like a memorial alcove. Empty center for result text. No characters, no text, no skulls.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

---

## B. Primary HUD chrome

### 3. `ui_turn_number_panel.png`
**Asset size:** 512 × 512 | **Display:** 280×280 (top half clipped)

```
Turn counter medallion HUD element, tombstone necropolis style. Canvas exactly 512x512, transparent PNG.
Silver memorial plaque or arched tombstone crest frame #d4dce6 on dark charcoal #12141a. Empty center for turn number — do NOT render numbers or text. Delicate silver filigree corners, moonlight edge #e8eef5. Top-center HUD, lower half visible on screen.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 4. `ui_end_turn.png`
**Asset size:** 512 × 512 | **Display:** 160×110

```
End Turn button HUD element, tombstone necropolis style. Canvas exactly 512x512, transparent PNG.
Silver engraved tombstone-shaped button or silver burial plaque #d4dce6 with subtle moonlight rim #e8eef5. Must show readable engraved text "END TURN" in silver-white serif or small-caps, high contrast, legible at 160x110. Aristocratic, solemn, not scary. No other words.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 5. `ui_battle_options.png`
**Asset size:** 512 × 512 | **Display:** 230×230 (lower third clipped)

```
Options button, tombstone necropolis style. Canvas exactly 512x512, transparent PNG.
Silver noble crest seal or mausoleum keyhole plate inside circular silver frame #d4dce6 — NOT a modern gear cog. Must include readable engraved text "OPTIONS" in silver #e8eef5 below crest, legible when bottom third clipped. Subtle moonlight accent #e8eef5. No other words.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 6. `ui_crystal_indicator.png`
**Asset size:** 256 × 256 | **Display:** 48×48

```
Crystal resource icon, tombstone necropolis style. Canvas exactly 256x256, transparent PNG.
Faceted gem set in silver reliquary or memorial crystal on silver pedestal #d4dce6, moonlight gleam #e8eef5. Readable at 48px. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 7. `ui_icon_attack_count.png`
**Asset size:** 256 × 256 | **Display:** 72×72

```
Attacks remaining badge, tombstone necropolis style. Canvas exactly 256x256, transparent PNG.
Silver memorial shield or crossed silver sabers inside arched tombstone frame #d4dce6. Empty center for number — do NOT render numbers. Restrained dull crimson accent #8b3030 optional like faded noble house color. Readable at 72px.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 8. `ui_icon_union.png`
**Asset size:** 512 × 512 | **Display:** 110×110; also 52×52 in context menu

```
Union summon button icon, tombstone necropolis style. Canvas exactly 512x512, transparent PNG.
Two interlocking silver memorial medallions or fused noble crests #d4dce6 symbolizing union of houses. Moonlight silver gleam #e8eef5. Strong silhouette at 110px. No text. Also used in card context menu at smaller size.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

---

## C. Tech & Void stack chips

### 9. `ui_tech_stack_chip.png`
**Asset size:** 128 × 128 | **Display:** 76×96

```
Tech discard stack widget, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Mini stacked card pile (3 cards offset) with pale silver-blue etched rune edges #b8c8d8. Silver frame trim #d4dce6. Must include readable silver engraved text "TECH" centered on chip, legible at 76x96. Empty count badge corner bottom-right — do NOT render numbers. No other words.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 10. `ui_void_stack_chip.png`
**Asset size:** 128 × 128 | **Display:** 76×96

```
Void discard stack widget, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Mini stacked card pile (3 cards offset) with muted lavender-silver mist accent #9a8fb0 on edges. Silver frame trim #d4dce6. Must include readable silver engraved text "VOID" centered on chip, legible at 76x96. Empty count badge corner bottom-right — do NOT render numbers. No other words.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

---

## D. Card context menu icons (display 52×52)

### 11. `ui_context_menu_attack.png`
**Asset size:** 128 × 128

```
Context menu icon: Attack, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Silver ceremonial sword or rapier strike symbol #d4dce6, restrained crimson #8b3030. High contrast at 52px. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 12. `ui_context_menu_info.png`
**Asset size:** 128 × 128

```
Context menu icon: Info / Inspect card, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Silver magnifying glass over engraved silver plaque or memorial scroll symbol #d4dce6, moonlight accent #e8eef5. High contrast at 52px. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 13. `ui_context_menu_bluff.png`
**Asset size:** 128 × 128

```
Context menu icon: Bluff, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Silver masquerade mask or veiled memorial statue motif #d4dce6, subtle moonlight #e8eef5. Misdirection, aristocratic intrigue, not horror. High contrast at 52px. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 14. Union context menu
**Reuse #8** `ui_icon_union.png` — scaled to 52×52 in-engine.

### 15. `ui_context_menu_panel.png` (optional)
**Asset size:** 512 × 128

```
Card context menu horizontal strip background, tombstone necropolis style. Canvas exactly 512x128 PNG.
Dark charcoal stone pill bar #12141a, polished silver border #d4dce6, moonlight edge #e8eef5. Rounded ends like a silver burial nameplate strip. Empty center for 2–4 icon slots. Do not embed icons.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

---

## E. Card grid status overlays (display ~58×58)

### 16. `ui_icon_wait_2.png`
**Asset size:** 128 × 128

```
Card status icon: Already attacked / cooldown, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Silver hourglass on memorial pedestal or circular silver wreath arrow #d4dce6, muted moonlight #e8eef5. Readable at 58px. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 17. `ui_icon_exposed.png`
**Asset size:** 128 × 128

```
Card status icon: Exposed / vulnerable, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Silver cracked memorial shield or opened vault eye symbol #d4dce6, pale gold warning #c9a84c like tarnished noble gilt. Readable at 58px. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 18. `ui_icon_trap.png`
**Asset size:** 128 × 128

```
Card status icon: Trap armed, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Silver cemetery gate snare or memorial hazard sigil #d4dce6, restrained crimson #8b3030. Readable at 58px. No text, no gore.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 19. `ui_icon_blank_found.png`
**Asset size:** 128 × 128

```
Card status icon: Blank slot discovered, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Silver empty grave plot outline or unmarked silver plaque frame #d4dce6, faint moonlight sparkle #e8eef5 in center. Readable at 58px. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

---

## F. Options menu panels

Options sub-items (Battle Log, Rules, Settings, Surrender) are text buttons in code — generate panel chrome only.

### 20. `ui_panel_frame_9slice.png`
**Asset size:** 512 × 512 | NinePatch margins ~110px

```
Modal panel 9-slice frame, tombstone necropolis style. Canvas exactly 512x512 PNG.
Dark charcoal stone fill #12141a, polished silver mausoleum border #d4dce6, moonlight corner filigree #e8eef5. Empty center. NinePatch margins ~110px. Used for Options, Battle Log, Rules, Settings, Surrender modals.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 21. `ui_options_menu_row.png`
**Asset size:** 512 × 64 | **Display height:** 48px

```
Options menu row button template, tombstone necropolis style. Canvas exactly 512x64 PNG.
Dark charcoal stone button #12141a, silver engraved border #d4dce6, subtle moonlight hover gleam #e8eef5. Empty center for text label. Display height 48px.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

---

## G. Secondary battle assets

### 22. `ui_coin_front.png`
**Asset size:** 512 × 512

```
Coin flip front face, tombstone necropolis style. Canvas exactly 512x512, transparent PNG.
Polished silver noble coin #d4dce6 with memorial crest emboss, moonlight rim #e8eef5. Aristocratic currency, not sci-fi. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 23. `ui_coin_back.png`
**Asset size:** 512 × 512

```
Coin flip back face, tombstone necropolis style. Canvas exactly 512x512, transparent PNG.
Matching silver coin reverse with blank memorial crest or silver wreath emblem #d4dce6. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 24. `ui_icon_defend.png`
**Asset size:** 128 × 128 | Reckoning overlay

```
Reckoning overlay defend icon, tombstone necropolis style. Canvas exactly 128x128, transparent PNG.
Silver memorial kite shield or noble house shield #d4dce6, moonlight core gleam #e8eef5. No text.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

### 25. `ui_enemy_view_chip.png`
**Asset size:** 512 × 64 | **Display:** 160×30

```
Enemy View toggle button chip, tombstone necropolis style. Canvas exactly 512x64 PNG.
Dark charcoal #12141a, silver border #d4dce6, silver all-seeing memorial eye or silver binoculars on left, empty space for "ENEMY VIEW" text. Display 160x30.
Style: noble necropolis CCG HUD, aristocratic cemetery aesthetic, dark charcoal stone #12141a, polished silver metallic trim #d4dce6 and #a8b4c4, moonlight silver highlight #e8eef5 used sparingly. Tombstone silhouettes, mausoleum arches, silver filigree, engraved silver plaques, flat illustrated game UI (not 3D), soft top-left lighting, refined gothic elegance not horror, no watermark, production-ready.
```

---

## Bonus: Game UI Agent moodboard (optional, 1 credit)

**Asset size:** 1280 × 720

```
Noble necropolis CCG battle HUD, aristocratic cemetery theme, 1280x720 pixels, landscape.

Layout:
- Dark charcoal stone background #12141a like a mausoleum plaza
- Two 5x5 card grid zones (left and right) with thin silver grid lines
- Center column for turn info and action prompts
- Top-left: player name + crystal counter badge
- Top-right: opponent name + crystal counter badge
- Top-center: turn number medallion (silver memorial plaque frame)
- Top-center-right: attack count badge (small icon + number slot)
- Bottom-center: end turn button (silver tombstone plaque shape)
- Bottom edge: small options crest seal button
- Left side mid: TECH stack chip (pale silver-blue runes) and VOID stack chip (lavender mist on silver)

Style:
- Polished silver metallic trim #d4dce6, secondary silver #a8b4c4
- Moonlight silver highlight #e8eef5 used sparingly — NO neon cyan
- Tombstone obelisks, mausoleum arches, silver filigree, refined gothic elegance
- No characters, no card artwork, no text labels, no watermark, no horror gore
- Professional game UI mockup, flat illustrated HUD (not 3D render)
- Soft top-left lighting
- Output exactly 1280x720 PNG
```

---

## Palette reference

| Role | Hex | Notes |
|------|-----|-------|
| Stone base | `#12141a` | Mausoleum floor / panels |
| Deep void | `#0a0c10` | Game over vignette |
| Silver primary | `#d4dce6` | Trim, icons, filigree |
| Silver secondary | `#a8b4c4` | Shadows on metal |
| Moonlight accent | `#e8eef5` | Highlights (replaces cyan) |
| Tech rune | `#b8c8d8` | Pale silver-blue |
| Void mist | `#9a8fb0` | Lavender cemetery fog |
| Noble crimson | `#8b3030` | Restrained combat accent |
| Tarnished gold | `#c9a84c` | Warning / exposed |

---

## Checklist (25 assets — 24 unique PNGs)

- [ ] 1  ui_playmat_default.png          1280×720
- [ ] 2  bg_game_over.png                1280×720
- [ ] 3  ui_turn_number_panel.png        512×512
- [ ] 4  ui_end_turn.png                 512×512
- [ ] 5  ui_battle_options.png           512×512
- [ ] 6  ui_crystal_indicator.png        256×256
- [ ] 7  ui_icon_attack_count.png        256×256
- [ ] 8  ui_icon_union.png               512×512
- [ ] 9  ui_tech_stack_chip.png          128×128
- [ ] 10 ui_void_stack_chip.png          128×128
- [ ] 11 ui_context_menu_attack.png      128×128
- [ ] 12 ui_context_menu_info.png        128×128
- [ ] 13 ui_context_menu_bluff.png       128×128
- [ ] 14 (union context = reuse #8)
- [ ] 15 ui_context_menu_panel.png       512×128  (optional)
- [ ] 16 ui_icon_wait_2.png              128×128
- [ ] 17 ui_icon_exposed.png             128×128
- [ ] 18 ui_icon_trap.png                128×128
- [ ] 19 ui_icon_blank_found.png         128×128
- [ ] 20 ui_panel_frame_9slice.png       512×512
- [ ] 21 ui_options_menu_row.png         512×64
- [ ] 22 ui_coin_front.png               512×512
- [ ] 23 ui_coin_back.png                512×512
- [ ] 24 ui_icon_defend.png              128×128
- [ ] 25 ui_enemy_view_chip.png          512×64
