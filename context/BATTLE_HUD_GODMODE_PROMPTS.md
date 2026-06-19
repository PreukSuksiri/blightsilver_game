# Blightsilver — Battle HUD God Mode AI Prompts

**Variant:** Modern sci-fi fantasy CCG · cyan + silver  
**Sibling docs:**
- [`BATTLE_HUD_GODMODE_PROMPTS_TOMBSTONE.md`](BATTLE_HUD_GODMODE_PROMPTS_TOMBSTONE.md) — noble necropolis / tombstone silver
- [`BATTLE_HUD_GODMODE_PROMPTS_MAGITECH.md`](BATTLE_HUD_GODMODE_PROMPTS_MAGITECH.md) — magitech / hextech chrome + cyan glow (matches your God Mode outputs)

**Tool:** [God Mode AI](https://www.godmodeai.co/) → Game UI Generator  
**Viewport:** 1280×720  
**Workflow:** Manual — paste each prompt, set Asset Size, generate, download PNG  
**Save exports to:** `assets/textures/ui/battle/v2/`

### God Mode style preset (UI only — do not paste into prompts)

If God Mode offers a **style** or **overlay** picker, choose the closest flat sci-fi / HUD preset there. **Do not** paste preset names into the copy-paste prompts below — the shared style suffix describes the look in plain language.

**ORDER:** Generate #1 (playmat) first, then upload it as style reference for all other assets.

### Labeled HUD assets (text required on art)

These four assets **must include readable text baked into the PNG**. Godot will still scale the texture; do not leave empty label zones.

| Asset | Required text | Legibility target |
|-------|---------------|-------------------|
| `ui_end_turn.png` | **END TURN** | Readable at 160×110 display |
| `ui_battle_options.png` | **OPTIONS** | Readable when lower third clipped |
| `ui_tech_stack_chip.png` | **TECH** | Readable at 76×96 display |
| `ui_void_stack_chip.png` | **VOID** | Readable at 76×96 display |

All other icons (crystal, attack count, context menu, etc.) stay **text-free** — numbers/labels are rendered in Godot.

---

## Shared style suffix (append to every prompt)

God Mode **style preset** is selected in the generator UI — not in this text.

```
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready. Text only where asset prompt requires END TURN, OPTIONS, TECH, or VOID.
```

---

## A. Full-screen backgrounds

### 1. `ui_playmat_default.png`
**Asset size:** 1280 × 720 | **Display:** full screen

```
Battle playmat background frame. Canvas exactly 1280x720 landscape PNG.
Dark navy center play area #04060d. Silver border rails #c8d4e0 on all edges. Thin inset cyan accent line #2ebfff. Chamfered corner brackets. Soft edge vignette. Empty center for two 5x5 card grids and center column. No characters, no cards, no text, no logo.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 2. `bg_game_over.png`
**Asset size:** 1280 × 720 | **Display:** full screen

```
Game over overlay background. Canvas exactly 1280x720 landscape PNG.
Dark navy with heavy vignette #04060d. Silver ornamental frame #c8d4e0, subtle cyan glow #2ebfff at center. Empty center for result text. No characters, no text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

---

## B. Primary HUD chrome

### 3. `ui_turn_number_panel.png`
**Asset size:** 512 × 512 | **Display:** 280×280 (top half clipped)

```
Turn counter medallion HUD element. Canvas exactly 512x512, transparent PNG.
Silver hex/octagonal frame #c8d4e0 on dark navy. Empty center for turn number — do NOT render numbers or text. Thin cyan inner accent #2ebfff. Top-center HUD element, lower half visible on screen.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 4. `ui_end_turn.png`
**Asset size:** 512 × 512 | **Display:** 160×110

```
End Turn button HUD element. Canvas exactly 512x512, transparent PNG.
Prominent silver chamfered button #c8d4e0, subtle cyan glow #2ebfff. Center must show readable text "END TURN" in clean bold sans-serif, white or pale cyan #e8f4ff, high contrast against button. Text must remain legible when scaled to 160x110. No other words.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 5. `ui_battle_options.png`
**Asset size:** 512 × 512 | **Display:** 230×230 (lower third clipped)

```
Options settings button. Canvas exactly 512x512, transparent PNG.
Silver mechanical gear/cog inside circular silver frame #c8d4e0. Subtle cyan accent #2ebfff. Must include readable text "OPTIONS" in clean bold sans-serif below or beside icon, white or silver #e8eef5, legible when bottom third is clipped off-screen. No other words.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 6. `ui_crystal_indicator.png`
**Asset size:** 256 × 256 | **Display:** 48×48

```
Crystal resource icon. Canvas exactly 256x256, transparent PNG.
Faceted crystal silhouette, silver-white core #c8d4e0, subtle cyan edge glow #2ebfff. Readable at 48px. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 7. `ui_icon_attack_count.png`
**Asset size:** 256 × 256 | **Display:** 72×72

```
Attacks remaining badge. Canvas exactly 256x256, transparent PNG.
Circular or hex silver frame #c8d4e0 with crossed swords or strike marks. Empty center for number overlay — do NOT render numbers. Restrained red combat accent optional. Readable at 72px.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 8. `ui_icon_union.png`
**Asset size:** 512 × 512 | **Display:** 110×110; also 52×52 in context menu

```
Union summon button icon. Canvas exactly 512x512, transparent PNG.
Two interlocking silver rings or linked hex frames #c8d4e0 symbolizing fusion. Cyan glow accent #2ebfff. Strong silhouette at 110px. No text. Also used in card context menu at smaller size.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

---

## C. Tech & Void stack chips

### 9. `ui_tech_stack_chip.png`
**Asset size:** 128 × 128 | **Display:** 76×96

```
Tech discard stack widget. Canvas exactly 128x128, transparent PNG.
Mini stacked card pile (3 cards offset). Teal tech accent #00e5e5 on card edges. Silver frame trim #c8d4e0. Must include readable engraved text "TECH" in silver or pale cyan, centered on chip, legible at 76x96 display. Empty count badge corner bottom-right for number overlay — do NOT render numbers. No other words.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 10. `ui_void_stack_chip.png`
**Asset size:** 128 × 128 | **Display:** 76×96

```
Void discard stack widget. Canvas exactly 128x128, transparent PNG.
Mini stacked card pile (3 cards offset). Violet void accent #a61ae5 on card edges. Silver frame trim #c8d4e0. Must include readable engraved text "VOID" in silver or pale lavender-white, centered on chip, legible at 76x96 display. Empty count badge corner bottom-right for number overlay — do NOT render numbers. No other words.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

---

## D. Card context menu icons (display 52×52)

### 11. `ui_context_menu_attack.png`
**Asset size:** 128 × 128

```
Context menu icon: Attack. Canvas exactly 128x128, transparent PNG.
Silver sword or blade strike symbol #c8d4e0, restrained red accent #ff4d4d. High contrast at 52px. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 12. `ui_context_menu_info.png`
**Asset size:** 128 × 128

```
Context menu icon: Info / Inspect card. Canvas exactly 128x128, transparent PNG.
Silver magnifying glass or eye-over-card symbol #c8d4e0, cyan accent #2ebfff. High contrast at 52px. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 13. `ui_context_menu_bluff.png`
**Asset size:** 128 × 128

```
Context menu icon: Bluff. Canvas exactly 128x128, transparent PNG.
Silver mask or misdirection symbol #c8d4e0, subtle cyan accent #2ebfff. High contrast at 52px. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 14. Union context menu
**Reuse #8** `ui_icon_union.png` — scaled to 52×52 in-engine.

### 15. `ui_context_menu_panel.png` (optional)
**Asset size:** 512 × 128

```
Card context menu horizontal strip background. Canvas exactly 512x128 PNG.
Dark navy pill bar #04060d, silver border #c8d4e0, cyan edge #2ebfff. Rounded ends. Empty center for 2–4 icon slots. Do not embed icons.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

---

## E. Card grid status overlays (display ~58×58)

### 16. `ui_icon_wait_2.png`
**Asset size:** 128 × 128

```
Card status icon: Already attacked / cooldown. Canvas exactly 128x128, transparent PNG.
Silver hourglass or circular arrow #c8d4e0, muted cyan #2ebfff. Readable at 58px on card corner. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 17. `ui_icon_exposed.png`
**Asset size:** 128 × 128

```
Card status icon: Exposed / vulnerable. Canvas exactly 128x128, transparent PNG.
Silver broken shield or eye symbol #c8d4e0, amber warning accent #ffd933. Readable at 58px. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 18. `ui_icon_trap.png`
**Asset size:** 128 × 128

```
Card status icon: Trap armed. Canvas exactly 128x128, transparent PNG.
Silver bear trap or hazard symbol #c8d4e0, red trap accent #ff4d4d. Readable at 58px. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 19. `ui_icon_blank_found.png`
**Asset size:** 128 × 128

```
Card status icon: Blank slot discovered. Canvas exactly 128x128, transparent PNG.
Silver hollow frame or dashed outline #c8d4e0, empty center, cyan sparkle #2ebfff. Readable at 58px. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

---

## F. Options menu panels

Options sub-items (Battle Log, Rules, Settings, Surrender) are text buttons in code — generate panel chrome only.

### 20. `ui_panel_frame_9slice.png`
**Asset size:** 512 × 512 | NinePatch margins ~110px

```
Modal panel 9-slice frame. Canvas exactly 512x512 PNG.
Dark navy fill #04060d, silver chamfered border #c8d4e0, cyan corner accents #2ebfff. Empty center. NinePatch margins ~110px. Used for Options, Battle Log, Rules, Settings, Surrender modals.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 21. `ui_options_menu_row.png`
**Asset size:** 512 × 64 | **Display height:** 48px

```
Options menu row button template. Canvas exactly 512x64 PNG.
Dark navy button #04060d, silver border #c8d4e0, subtle cyan hover glow #2ebfff. Empty center for text label. Display height 48px.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

---

## G. Secondary battle assets

### 22. `ui_coin_front.png`
**Asset size:** 512 × 512

```
Coin flip front face. Canvas exactly 512x512, transparent PNG.
Silver coin #c8d4e0, cyan holographic edge #2ebfff, sci-fi fantasy currency. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 23. `ui_coin_back.png`
**Asset size:** 512 × 512

```
Coin flip back face. Canvas exactly 512x512, transparent PNG.
Matching silver coin reverse, void crest or blank emblem. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 24. `ui_icon_defend.png`
**Asset size:** 128 × 128 | Reckoning overlay

```
Reckoning overlay defend icon. Canvas exactly 128x128, transparent PNG.
Silver shield #c8d4e0, cyan core glow #2ebfff. No text.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

### 25. `ui_enemy_view_chip.png`
**Asset size:** 512 × 64 | **Display:** 160×30

```
Enemy View toggle button chip. Canvas exactly 512x64 PNG.
Dark navy #04060d, silver border #c8d4e0, silver eye/binoculars icon on left, empty space for "ENEMY VIEW" text. Display 160x30.
Style: modern sci-fi fantasy CCG HUD, dark navy #04060d, silver metallic trim #c8d4e0, secondary silver #8a9bb0, accent cyan #2ebfff used sparingly. Chamfered geometric frames, thin inner glow, flat illustrated game UI (not 3D), top-left lighting, no watermark, production-ready.
```

---

## Bonus: Game UI Agent moodboard (optional, 1 credit)

**Asset size:** 1280 × 720

```
Modern sci-fi fantasy CCG battle HUD, 1280x720 pixels, landscape.

Layout:
- Dark navy background #04060d
- Two 5x5 card grid zones (left and right) with thin silver grid lines
- Center column for turn info and action prompts
- Top-left: player name + crystal counter badge
- Top-right: opponent name + crystal counter badge
- Top-center: turn number medallion (silver hex frame)
- Top-center-right: attack count badge (small icon + number slot)
- Bottom-center: end turn button (prominent, silver rim, subtle cyan glow)
- Bottom edge: small options/settings gear button
- Left side mid: TECH stack chip (teal accent) and VOID stack chip (violet accent)

Style:
- Silver metallic trim #c8d4e0, secondary silver #8a9bb0
- Accent cyan #2ebfff used sparingly on active/highlight elements only
- Chamfered geometric frames, thin inner glow, minimal ornament
- No characters, no card artwork, no text labels, no watermark
- Professional game UI mockup, flat illustrated HUD (not 3D render)
- Consistent top-left lighting
- Output exactly 1280x720 PNG
```

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
