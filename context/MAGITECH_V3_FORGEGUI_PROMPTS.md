# Magitech v3 — ForgeGUI prompts (Holy Tech / Witchhunter Corp)

**Locked look:** Holy Order / Witchhunter Corporation interface — brushed sacred silver, sanctified cyan light, seals and crests.  
**Not:** mecha HUD, cyberpunk neon city, robot plating, holographic projectors, circuit-board sci-fi.

Human workflow (do **not** paste into ForgeGUI):

- **Primary style lock:** `style_ref_holytech_kit_board.png` **+** `style_ref_panel_9slice_approved.png` (#20 ✓ approved, blank)  
- **Save to:** `assets/textures/ui/battle/v3_magitech/`  
- **Switch:** `hud_skin v3` · revert `hud_skin v2`  
- **Order:** Phase A core wired (`HudSkin` default `v3`). #27 ✓ top dashboard + #28 ✓ bottom vault wired (v3 only). **Phase A battle screen approved.**  
- **Phase B (game-wide chrome):** see **Phase B** section below → save under `magitech_v3/chrome/`. Start with **B1**. Skip B10, B12–B20, B26 this pass.  
- **Phase E (clockwork playmat):** see **Phase E** section → save under `battle/v3_magitech/clockwork/` (can run parallel later).  

- **If gen ignores the kit** (e.g. cartoon wood UI): style refs failed to upload — re-attach and confirm they are active. Do not “fix” with long negative prompts.

Paste only each **Copy this** block. Exact game labels only when listed (END TURN, OPTIONS, TECH, VOID).

### Hard rule — no baked branding

Frames, bars, playmats, turn plates, and most icons must have **zero** words, logos, faction crests, medallions-with-emblems, or title plaques. Lore lives in Godot labels.

Allowed text **only** on: END TURN, OPTIONS, TECH, VOID.  
Union/coin only may use an abstract seal (and only when that asset asks for it).

**Why “no logo” still fails:** the holytech **kit board** is full of crests. If it stays in style lock, ForgeGUI will keep pasting emblems. For blank chrome:

1. **Remove** `style_ref_holytech_kit_board.png` from the lock for that gen  
2. Keep only **blank** approved refs: `#20` panel, and other logo-free plaques  
3. Generate or refine with the lines below  

**Refine A — strip branding (paste alone, attach the almost-good image as the only style ref if possible):**

```
Identical metal frame and cyan seams, but DELETE every logo, crest, emblem, seal, medallion badge, wing icon, sword icon, heraldry, and nameplate. Bottom bar and top bar must be plain brushed silver only — no circular badge in the center. No symbols of any kind. Keep chevrons and bolts. Empty dark center. No text. No watermark.
```

**Refine B — if a crest remains, be brutal:**

```
Remove the circular emblem at the bottom completely. Replace that spot with continuous blank scratched silver metal bar matching the rest of the frame. Zero icons. Zero logos. Zero crests.
```

---

## Visual target

Brushed silver like blessed plate armor and corp dossier frames · dark charcoal recesses · **cool sanctified cyan** glow in thin seams · angular ceremonial bevels · **blank** chrome (no logos on frames) · opaque filled faces · transparent outside the object.

**Avoid:** mecha, robot, cyberpunk, hologram pedestal, circuit PCB, baked faction names/logos on chrome.

---

## #20 — `ui_magitech_panel_9slice.png` (first) · 512×512

**Copy this:**

```
Game UI modal window frame, isolated asset, square canvas 512x512, transparent background outside the frame.

Thick brushed sacred-silver border for a holy-tech dossier / case-file window. Ceremonial bevels, dark charcoal recessed center (opaque fill, not a hole), thin sanctified cyan light in inner seams only. Bolts, scratched metal, optional small cyan chevrons on the sides — decorative geometry only.

CRITICAL: completely blank chrome — NO text, NO letters, NO logos, NO crests, NO emblems, NO nameplates, NO titles on the top bar or anywhere. Do not write Witchhunter, Holy Order, or any words. No top-center logo plaque. Symmetrical nine-slice friendly corners. Match the uploaded kit’s silver-and-cyan materials only.

Not mecha, not cyberpunk. No inventory icons, no watermark.
```

---

## #4 — `ui_magitech_end_turn.png` · 512×512

**Copy this:**

```
Game UI End Turn button for a witchhunter corp interface, isolated asset, square canvas 512x512, transparent background outside the button.

Wide brushed sacred-silver plaque like an order command tablet. Dark recessed face, thin sanctified cyan seam glow. Bold readable text exactly: END TURN. Standalone plaque — no circular crest wrapping it. Match the uploaded holytech kit. Not mecha, not cyberpunk. No gibberish, no watermark.
```

---

## #5 — `ui_magitech_options.png` · 512×512

**Preferred (non-book) — Copy this:**

```
Game UI Options button, isolated asset, square canvas 512x512, transparent background outside the button.

Wide brushed sacred-silver command tablet with chamfered corners, dark recessed face, thin sanctified cyan seam glow, optional small cyan chevrons on the sides. Center: a simple sacred-silver gear / cog icon above bold readable text exactly: OPTIONS. Standalone plaque only — no book, no circular crest medallion wrapping the button, no faction logo, no gibberish words.

Match the materials of the uploaded style references (brushed silver, cyan seams, bolts, scratched metal). Not mecha, not cyberpunk. No watermark.
```

**Alternate (book — only if you want the old concept):**

```
Game UI Options as a closed rite-book / field manual, brushed sacred silver, cyan clasp, text exactly: OPTIONS in upper two-thirds. Standalone book, no medallion frame. Match uploaded holytech kit. No gibberish, no watermark.
```

---

## #1 — `ui_magitech_playmat.png` · 1280×720

**Copy this:**

```
Card game battle playmat background, landscape canvas 1280x720, full-bleed image.

Center floor: cool charcoal stone slate with subtle worn flagstone — stone plaza for the card grid, not metal plating across the floor. Soft darker vignette at the outer edges.

Outer border frame only: brushed sacred-silver metal with thin sanctified cyan seams, bolts, ceremonial bevels — match the materials of the uploaded style references. Empty center for gameplay. Blank chrome — no text or emblems. No watermark.
```

### #1B alternate — hex / astrology map field · `ui_magitech_playmat_astro.png` · 1280×720

**Not another metal plate** — panels/buttons already are. Center field is a dark void with subtle hex-tech + astrology / constellation map and faint holographic cyan lines (tactical-arcane floor under the cards). Optional thin silver+cyan **outer frame only**.

Save as `ui_magitech_playmat_astro.png`. Style lock: blank `#20` panel for frame materials; kit board optional (can add crests — be careful).

**Known ForgeGUI issue:** if style refs fail to upload/attach, gens ignore the kit and can look totally wrong (e.g. generic cartoon UI). That was a ref-upload failure, not the prompt. Confirm refs are active before re-rolling.

**Avoid in prompt:** landscape, outdoor, grass, steel floor, brushed metal plate fill, photoreal.

**Copy this:**

```
Game UI full-bleed background, exact size 1280 by 720 pixels, edge to edge.

Deep void-black to charcoal center field. Across the field: a subtle glowing cyan hexagonal grid and faint astrology / constellation map — thin star points, delicate geometric arcs, sacred geometry circles, soft holographic cyan linework at low opacity so cards stay readable on top. Quiet arcane-tech atmosphere, painted hard-surface game art matching the cyan glow of the uploaded style references.

Optional thin outer border only: brushed sacred-silver frame with a thin cyan seam (frame stays at the edges — do not fill the center with metal plating).

Empty of clutter: no logos, no crests, no text, no characters, no icons, no watermark.
```

### #1C alternate — borderless arcane celestial map · `ui_magitech_playmat_celestial.png` · 1280×720

Full-bleed astrology / constellation field only — **no outer frame, no silver border, no metal rim.** Soft runes and star chart across a dark void. Save as `ui_magitech_playmat_celestial.png`.

**Style lock tip:** do **not** attach `#20` panel / End Turn metal refs — they force a silver frame. Use only a borderless celestial ref (or none). If the map is good but framed, use the refine below.

**Copy this** (must fill the whole rectangle — not one centered round chart):

```
Game UI full-bleed background texture, exact size 1280 by 720 pixels, pattern covering the entire wide rectangle wall to wall.

Deep void-black field. Across the FULL width and height: a distributed arcane sky map — many small constellation clusters, scattered star dots, thin cyan linking lines, faint hex grid overlay, and small random runes placed here and there at low opacity. Wide panoramic chart like a table surface under cards, not a single circular emblem.

Linework only electric cyan and cool silver-white. Soft holographic glow, quiet enough for cards on top. Painted game-art matching uploaded cyan-silver style references.

No single large round star-map medallion in the center. No outer picture frame or metal border. No logos, no readable modern words, no characters, no watermark.
```

**Refine — map good, strip border only:**

```
Same wide cyan-silver celestial constellation field and hex grid and runes, exact same art, but remove the entire outer silver metal frame and all edge chrome, chevrons, and corner bolts. Star map continues to every edge of the 1280x720 rectangle on pure void black. No border.
```

---

## #2 — `ui_magitech_game_over.png` · 1280×720

**Copy this:**

```
Game UI full-bleed overlay background, exact size 1280 by 720 pixels, edge to edge.

Deep void-black with heavy vignette toward the edges. Soft cyan-silver arcane celestial lines and faint runes in the outer field only, matching the uploaded cyan-silver style references. Center stays mostly empty dark space for result text. Optional thin brushed sacred-silver ceremonial arch near the edges with a thin cyan seam — blank chrome, no emblems.

No logos, no crests, no readable words, no characters, no watermark.
```

---

## #3 — `ui_magitech_turn_number.png` · 512×512

**Copy this:**

```
Game UI turn-counter plate, isolated asset, square canvas 512x512, transparent background outside the plate.

Horizontal rounded-hexagon brushed sacred-silver badge (soft hex — not a circle), ceremonial bevels, thin sanctified cyan inner seam. Interior fully opaque dark face with faint etch lines so the center is never a hole. Put richer metal detail in the lower half — but the bottom bar is PLAIN silver only.

FORBIDDEN: logos, crests, emblems, circular medallions, wing icons, sword icons, heraldry, letters, numbers. No badge on the bottom center. No badge on the top center.

Match only the silver/cyan materials of the uploaded style references (prefer blank panel refs — do not invent new emblems). Not mecha. No watermark.
```

---

## #6 — `ui_magitech_crystal.png` · 256×256

**Copy this:**

```
Game UI crystal resource icon, isolated asset, square canvas 256x256, transparent background outside the crystal.

Slender faceted cyan crystal relic, compact badge size, optional small sacred-silver claw setting on the lower third. Freeform gem only — no outer circular medallion or ring frame. Match the cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

---

## #7 — `ui_magitech_attack_count.png` · 256×256

Pick one alt. All need a **blank dark center** for the Godot attack number (no baked digits, no crest in the middle).

**#7A — crossed stakes (default)**

```
Game UI attack-count badge, isolated asset, square canvas 256x256, transparent background outside the badge.

Small sacred-silver rounded-hex or round seal plate with a dark recessed empty center (clear space for a single digit later). Behind or along the rim only: two crossed wooden-and-silver hunter stakes with thin cyan edge glow. Center face stays blank — no crest, no rune pile, no number. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

**#7B — hammer and stake**

```
Game UI attack-count badge, isolated asset, square canvas 256x256, transparent background outside the badge.

Small sacred-silver rounded-hex or round seal plate with a dark recessed empty center (clear space for a single digit later). Along the rim only: a witchhunter hammer and one silver-tipped stake crossed or flanking — cyan edge accents. Center face stays blank — no crest, no number. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

**#7C — crossed silver arrows / quarrels**

```
Game UI attack-count badge, isolated asset, square canvas 256x256, transparent background outside the badge.

Small sacred-silver rounded-hex or round seal plate with a dark recessed empty center (clear space for a single digit later). Behind or along the rim only: two crossed silver bolts or arrows with thin cyan fletching glow. Center face stays blank — no crest, no number. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

**#7D — crossed flintlocks + blank decree placard**

```
Game UI attack-count badge, isolated asset, square canvas 256x256, transparent background outside the badge.

Two crossed realistic flintlock pistols behind a small blank royal-decree placard. Pistols: historical flintlock silhouette — polished silver metal barrels and lockwork, dark luxury leather-wrapped grips with subtle stitching, brass or cool-silver fittings; only a thin sanctified cyan seam accent (not energy-gun barrels). Center: blank sacred-silver decree placard with dark recessed empty face for a digit later, thin cyan inner seam, no writing, no crest. Match cyan-silver UI language of the uploaded style references. No text, no logos, no numbers, no watermark.
```

**#7D refine — more realistic + leather grips** (attach current flintlock result):

```
Same composition: crossed flintlocks behind the blank center placard. Make the pistols more realistic historical flintlocks — proper hammer, frizzen, and barrel. Replace solid metal grips with dark luxury leather handles, soft grain and subtle stitching. Keep silver metal on barrel and lock. Reduce neon energy lines on the barrels to a thin cyan accent only. Placard center stays blank and empty. No text, no logos, no numbers.
```

---

## #8 — `ui_magitech_union.png` · 512×512

**Copy this:**

```
Game UI union medallion, isolated 512x512, transparent outside.

Round holy-order seal: brushed sacred-silver ceremonial ring, dark face, thin cyan rim light. Center shows TWO distinct spirit forms — left and right — clearly separate at the outer tips, flowing inward and fusing into one shared cyan core. Twin souls merging, not a single wing emblem. Opaque badge. No faces with eyes, no text, no faction crest, no watermark. Match cyan and silver of the uploaded style references.
```

**#8 refine — stronger fusion read:**

```
Same round silver medallion, but make the center clearly two things becoming one: two spirit wisps or twin blade-souls on left and right, tips apart, bodies merging at the middle into one bright cyan fusion point. Must read as union / fuse at a glance. Keep sacred silver ring and dark face. No single crest, no text, no watermark.
```

**#8 alt A — clasped gauntlets:**

```
Game UI union medallion, isolated 512x512, transparent outside.

Round holy-order seal: brushed sacred-silver ceremonial ring, dark face, thin cyan rim light. Center: two armored gauntlets clasped in a firm handshake / union grip — left and right hands meeting in the middle. Sacred silver plate armor, thin cyan seam accents on the knuckles. Reads as alliance / joining. Opaque badge. No faces, no text, no faction crest, no watermark. Match cyan and silver of the uploaded style references.
```

**#8 alt B — interlocking rings:**

```
Game UI union medallion, isolated 512x512, transparent outside.

Round holy-order seal: brushed sacred-silver ceremonial ring, dark face, thin cyan rim light. Center: two sacred-silver rings interlocking like a chain-link / wedding-band overlap — clearly two loops linked as one. Cyan glow strongest where the rings cross. Opaque badge. No faces, no text, no faction crest, no watermark. Match cyan and silver of the uploaded style references.
```

---

## #9 — `ui_magitech_tech.png` · 128×128

**Copy this:**

```
Game UI TECH stack chip, isolated 128x128, transparent outside.

Circular sacred-silver order chip, dark face, thin cyan ring light, bold text exactly: TECH. Holy-corp badge, not a mecha LED. Match the uploaded kit. No watermark.
```

---

## #10 — `ui_magitech_void.png` · 128×128

**Copy this:**

```
Game UI VOID stack chip, isolated 128x128, transparent outside.

Circular sacred-silver order chip, deeper dark face, thin cyan edge light only, bold text exactly: VOID. Holy-corp badge. Match the uploaded kit. No purple flood, no watermark.
```

---

## #11 — `ui_magitech_attack.png` · 128×128

**Copy this:**

```
Game UI Attack context icon, isolated asset, square canvas 128x128, transparent background outside the object.

Single witchhunter flintlock pistol angled diagonally — realistic silver barrel and lock, dark luxury leather grip, thin cyan accent only. Freeform weapon only — no circular frame, no placard, no second pistol. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

**#11 refine — fuller 3/4 toward camera** (attach current attack PNG only as **material/style** ref — not pose):

Do **not** say “same angle / same pose.” Goal: new camera, fuller silhouette.

```
Game UI Attack context icon, isolated asset, square canvas 128x128, transparent background outside the object.

Single witchhunter flintlock pistol in a foreshortened three-quarter view aimed slightly toward the camera — muzzle closer and larger, barrel compressed in depth, grip and flintlock still readable. Fuller, stockier silhouette that fills the square; avoid flat long side-profile and skinny diagonal strip.

Sacred-silver barrel and lock, dark luxury leather or wood grip, thin cyan seam accents only — match materials of the uploaded style reference. Freeform weapon only — no circular frame, no placard, no second pistol, no hand. No text, no logos, no watermark.
```

**#11 refine — if still too long / thin:**

```
Game UI Attack icon, 128x128, transparent outside. Stronger foreshortening: muzzle more toward camera, grip compact in the lower corner, weapon mass filling most of the square. Silver + cyan accents, luxury grip. No side-profile strip. No frame, no text.
```

Drop-in filenames after export:
- Large / reckoning: `ui_magitech_attack.png`
- Context menu small: `ui_magitech_context_attack.png` (same art, smaller export or downscale)

---

## #12 — `ui_magitech_info.png` · 128×128

**Copy this:**

```
Game UI Info context icon, isolated asset, square canvas 128x128, transparent background outside the badge.

Letter i on a compact sacred-silver dossier / decree plate with a thin cyan seam — freeform badge, not a coin ring. Small badge centered with generous transparent margin — plate about half the canvas width. Match cyan and silver of the uploaded style references. No other text, no logos, no watermark.
```

**#12 refine — smaller badge:**

```
Same info placard with letter i, but scale the whole badge much smaller in the 128x128 frame — more empty transparent padding around it. Plate about half the canvas width. Keep cyan-silver materials. No other text, no logos.
```

---

## #13 — `ui_magitech_bluff.png` · 128×128

**Copy this:**

```
Game UI Bluff context icon, isolated asset, square canvas 128x128, transparent background outside the mask.

Elegant Venetian opera eye-mask covering eyes and nose only — no mouth, no lower face, no teeth, no lips. Smooth porcelain white / soft white enamel with cool silver filigree edges and a thin cyan seam accent. Gentle, refined, not scary or grotesque. Standalone mask only — no smoke haze required, no jester bells, no circular medallion frame. Match cyan-silver UI accents of the uploaded style references. No text, no logos, no watermark.
```

**#13 refine — softer white eye-mask** (attach current if useful):

```
Same opera mask icon, but eyes and nose only — remove the mouth completely. Make the mask porcelain white / soft white, not dark gunmetal. Soft elegant filigree, thin cyan edge accent. Calm and refined, not scary. No lower face, no teeth, no smoke. No text, no logos.
```

**#13 alt — three-quarter toward camera** (attach current `ui_magitech_bluff.png` as **material/style** only — not pose):

Do **not** keep a flat front-on / billboard face. Goal: depth and a fuller silhouette in the square.

```
Game UI Bluff context icon, isolated asset, square canvas 128x128, transparent background outside the mask.

Elegant Venetian opera eye-mask (eyes and nose only) in a three-quarter view turned slightly toward the camera — show cheek/side depth and nose bridge foreshortening, not a flat symmetrical front face. One eye closer, the far wing slightly receding; fuller volumetric silhouette that fills the square.

Porcelain white / soft white enamel, cool silver filigree, thin cyan seam accent only. Gentle, refined, not scary or grotesque. Standalone mask only — no mouth, no lower face, no teeth, no lips, no smoke, no jester bells, no circular medallion frame, no head. Match cyan-silver materials of the uploaded style reference. No text, no logos, no watermark.
```

**#13 alt — if still too flat / billboard:**

```
Game UI Bluff icon, 128x128, transparent outside. Stronger three-quarter turn: mask clearly angled in space, near eye larger, far edge thinner. Porcelain white + silver filigree + thin cyan accent. Eyes and nose only. No front-on symmetry. No frame, no text.
```

---

## #15 — `ui_magitech_context_panel.png` · 512×128 (optional)

**Copy this:**

```
Game UI horizontal context bar, isolated 512x128, transparent outside.

Wide brushed sacred-silver strip like a corp toolbar, dark recessed center, thin cyan seam glow. Match the uploaded holytech kit. No text, no icons in slots, no watermark. Not mecha.
```

---

## #16 — `ui_magitech_wait.png` · 128×128

**Copy this:**

```
Game UI wait icon, isolated 128x128, transparent outside.

Freeform ceremonial hourglass, sacred silver, cyan sand-light. Match the uploaded kit. No ring frame, no text, no watermark.
```

**#16 alt — simpler hourglass:**

```
Game UI wait icon, isolated 128x128, transparent outside.

Simple classic hourglass only — two clear glass bulbs, thin waist, flat silver top and bottom caps, a little cyan sand in the lower bulb. Clean silhouette, minimal ornament, no filigree, no frame, no pedestal. Centered with transparent margin. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

**#16 refine — sand still ticking** (attach current):

```
Same simple silver hourglass, but show time still running: cyan sand remaining in the top bulb, a thin stream falling through the waist, and a mound collecting in the bottom bulb. Keep the clean minimal look — flat silver caps, clear glass, no extra ornament. No text, no logos, no watermark.
```

**#16 full — simple hourglass, sand ticking:**

```
Game UI wait icon, isolated 128x128, transparent outside.

Simple classic hourglass only — two clear glass bulbs, thin waist, flat brushed sacred-silver top and bottom caps with a thin cyan seam on each cap. Time still running: cyan sand in the top bulb, a thin cyan stream falling through the waist, and a mound collecting in the bottom bulb. Clean silhouette, minimal ornament, no filigree, no frame, no pedestal. Centered with transparent margin. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

---

## #17 — `ui_magitech_exposed.png` · 128×128

**Copy this:**

```
Game UI exposed status icon, isolated 128x128, transparent outside.

Freeform revealed-seal or broken ward glyph, sacred silver, cyan glow. Match the uploaded kit. No text, no watermark.
```

---

## #18 — `ui_magitech_trap.png` · 128×128

**Copy this:**

```
Game UI trap icon, isolated 128x128, transparent outside.

Freeform snare or ward-trap glyph, sacred silver, cyan accent. Match the uploaded kit. No text, no watermark.
```

**#18 alt — dynamite (red casing):**

```
Game UI trap icon, isolated 128x128, transparent outside.

Single stick of dynamite angled diagonally — red paper casing, silver end caps, short fuse with a cyan spark tip. Freeform object only, clean silhouette, transparent margin. Match cyan and silver accents of the uploaded style references. No text, no logos, no watermark, no explosion blast.
```

**#18 alt B — dynamite, skull mark:**

```
Game UI trap icon, isolated 128x128, transparent outside.

Single stick of dynamite angled diagonally — red paper casing with a simple black skull mark stamped on the side, open red paper ends (no metal caps), short fuse with a cyan spark tip. Freeform object only, clean silhouette, transparent margin. Match cyan accents of the uploaded style references. No text, no logos, no watermark, no explosion blast.
```

---

## #19 — `ui_magitech_blank_found.png` · 128×128

**Copy this:**

```
Game UI empty-slot icon, isolated 128x128, transparent outside.

Freeform empty dashed seal frame, sacred silver, cyan corner ticks. Match the uploaded kit. No text, no watermark.
```

**#19 alt A — fish bone:**

```
Game UI empty-slot / nothing-found icon, isolated 128x128, transparent outside.

Single clean fish skeleton / fishbone — skull, spine, ribs — brushed sacred silver with a thin cyan edge accent. Freeform object only, centered with transparent margin. Empty / picked-clean feeling. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

**#19 alt B — empty can:**

```
Game UI empty-slot / nothing-found icon, isolated 128x128, transparent outside.

Single empty tin can — open top, crushed or slightly dented, brushed sacred silver metal with a thin cyan rim accent. Hollow inside visible. Freeform object only, centered with transparent margin. Empty / discarded feeling. Match cyan and silver of the uploaded style references. No label text, no logos, no watermark.
```

---

## #21 — `ui_magitech_options_row.png` · 512×64

**Copy this:**

```
Game UI settings row bar, isolated 512x64, transparent outside.

Thin brushed sacred-silver corp row with cyan end ticks, empty center for text. Match the uploaded kit. No words in art, no watermark.
```

---

## #22 — `ui_magitech_coin_front.png` · 512×512

**Copy this:**

```
Game UI coin front, isolated 512x512, transparent outside.

Round holy-order coin in brushed sacred silver with cyan crest (wing-or-blade seal). Opaque. No gibberish text, no watermark. Match the uploaded kit.
```

---

## #23 — `ui_magitech_coin_back.png` · 512×512

**Copy this:**

```
Game UI coin back, isolated 512x512, transparent outside.

Round coin reverse, same sacred silver and cyan order language, different seal. Opaque. No text, no watermark. Match the uploaded kit.
```

---

## #24 — `ui_magitech_defend.png` · 128×128

**Copy this:**

```
Game UI defend icon, isolated 128x128, transparent outside.

Freeform heater shield, brushed sacred silver, cyan ward glow. Witchhunter defense seal. No extra circular frame. Match the uploaded kit. No text, no watermark.
```

**#24 refine — down-to-earth (not superhero):**

```
Game UI defend icon, isolated 128x128, transparent outside.

Practical medieval heater / kite shield — scuffed brushed sacred silver, battle-worn dents and scratches, simple raised rim. Blank face — no crest, no wings, no gem, no chevrons, no superhero emblem. Only a thin quiet cyan seam along the rim. Humble field gear, not a power badge. Freeform shield only, no circular frame. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

---

## #25 — `ui_magitech_eye_open.png` · 128×128

**Copy this:**

```
Game UI reveal eye icon open, isolated 128x128, transparent outside.

Freeform watchful order eye, sacred silver lids, sanctified cyan iris — inquisitor’s eye, not a robot optic. No medallion ring. Match the uploaded kit. No text, no watermark.
```

**#25 refine — no logo in pupil:**

```
Game UI reveal eye icon open, isolated 128x128, transparent outside.

Freeform human-like watchful eye — brushed sacred-silver eyelid frame, cyan iris ring, simple dark round pupil only. Blank pupil and iris — no crest, no wings, no diamond emblem, no faction logo, no chevrons inside the eye. Not a robot camera lens. No outer medallion ring. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

---

## #26 — `ui_magitech_eye_closed.png` · 128×128

**Copy this:**

```
Game UI reveal eye icon closed, isolated 128x128, transparent outside.

Freeform closed eyelid only — brushed sacred silver lid curve, thin cyan seam along the lash line, no iris visible, no pupil, no crest, no logo inside. Simple shut eye silhouette. No medallion ring. Match cyan and silver of the uploaded style references. No text, no logos, no watermark.
```

---

## #27 — `ui_magitech_top_dashboard.png` · 1280×720

Full **top dashboard** band (not a thin frame). Recessed empty bays for upper HUD widgets to sit in. Lower playfield stays transparent.

**Copy this:**

```
Game UI top dashboard panel, landscape canvas 1280x720, transparent background outside the chrome.

A full-width witchhunter / holy-tech UPPER DASHBOARD occupying roughly the top 28% of the canvas — a solid ceremonial control console, not a thin outline frame. Brushed sacred silver plating, dark recessed inset faces, thin electric cyan seam glow in grooves. Continuous dashboard from left edge to right edge with beveled edges and subtle mechanical-ceremonial detail.

Include empty recessed bays / inset panels ready for overlays: wide center bay, upper-left bay, upper-right bay, a smaller bay left-of-center, and two round/hex chip wells under the side bays. Bay faces stay blank and dark — no icons, no numbers, no text inside them.

Lower ~70% of the canvas fully empty/transparent. No buttons drawn in, no icons, no numbers, no text, no faction crests, no logos, no watermark. Match cyan and silver of the uploaded style references.
```

**#27 refine — deeper console, clearer bays:**

```
Same full-width top dashboard, but make it a heavier solid console with clearer dark recessed bays and stronger cyan groove light. Still not a thin wireframe. Blank bay faces only. No text, no logos, no icons. Lower canvas transparent.
```

---

## #28 — `ui_magitech_bottom_vault.png` · 1280×720

Bottom HUD chrome (pink-marked strip). Witchhunter **archive / vault / document storage** — sits behind the Options book; leave a center notch so Options is not covered.

**Copy this:**

```
Game UI bottom HUD vault strip, landscape canvas 1280x720, transparent background outside the chrome.

ONLY the lower band of the screen: a wide witchhunter holy-tech archive / vault / document-storage console in brushed sacred silver with thin electric cyan seam accents. Sealed dossier drawers, bound archive tomes on a metal shelf, vault latches, and filing-plate grooves — ceremonial inquisition records storage, not a backpack and not a sci-fi cargo crate. Low horizontal composition across the bottom edge, roughly the bottom 22% of the canvas. Clear open gap / notch in the bottom-center. Soft left and right returns optional. Upper ~75% of the canvas fully empty/transparent.

No readable text, no fake labels, no logos, no faction crests, no watermark. Match cyan and silver of the uploaded style references.
```

**#28 alt — sealed vault drawers:**

```
Game UI bottom HUD vault strip, landscape canvas 1280x720, transparent outside.

Wide low sacred-silver vault of sealed drawer faces and archive plate seams with thin cyan edge light along the bottom of the screen. Inquisition document vault, not a bag. Empty transparent notch at bottom-center. Rest of canvas transparent. No text, no logos, no watermark. Match uploaded style references.
```

**#28 refine — wider center notch:**

```
Same bottom vault strip, but widen the center transparent notch and keep the metal lower. No text, no logos.
```

---

## Reject if

- Reads as mecha / robot / cyberpunk cockpit  
- Purple plate flood or orange neon  
- Gibberish mock labels  
- Whole inventory grid instead of one isolated asset  

---

# Phase E — Clockwork playmat pieces

**Goal:** Castlevania-style clocktower depth via **modular** gears / pistons (Godot spins them). Not one animated full-screen background.

**Save to:** `assets/textures/ui/battle/v3_magitech/clockwork/`  
**Pipeline:** [MAGITECH_V3_FORGEGUI_PIPELINE.md](MAGITECH_V3_FORGEGUI_PIPELINE.md) → Phase E  
**Order:** E00 underlay (optional) → E01–E03 face gears → E05 piston → then E04 / E06–E08 if needed.

**Style lock:** blank `#20` `ui_magitech_panel_9slice.png` + logo-free silver refs (playmat / end-turn).  
**Remove** `style_ref_holytech_kit_board.png` for these gens (crests stick to cog hubs).

**Hard rules (every piece):**

- Isolated single object · transparent outside · centered · no text · no logos · no crests · no watermark  
- Magitech brushed sacred silver + thin sanctified cyan seam accents only  
- Not Castlevania purple stone copy, not rust-only brown, not mecha robot plating, not cyberpunk neon  
- Quiet enough that cards stay readable when many are layered behind the grid  

**Refine — strip branding (any piece):**

```
Identical metal gear or machine part, but DELETE every logo, crest, emblem, seal, medallion, letter, and rune-word. Plain brushed sacred silver only with thin cyan seam accents. Transparent outside. No watermark.
```

---

## E00 — `ui_magitech_clockwork_underlay.png` · 1280×720

Far static wall behind spinning pieces. Optional — you may keep existing `#1` playmat instead.

**Copy this:**

```
Card game battle playmat underlay, landscape canvas 1280x720, full-bleed image.

Deep clocktower machine-room wall for a holy-tech card game: dark charcoal stone masonry recesses with brushed sacred-silver machine housings in the FAR background only — large soft-focus gear silhouettes, axle tunnels, and bolted plates sunk into the wall. Thin sanctified cyan light only in distant seams at very low opacity.

Center stays quieter and darker for card readability — no sharp foreground props, no platforms for a platformer character, no stairs, no railings in the play area. Soft vignette at edges.

Blank chrome — no text, no logos, no crests, no characters, no watermark. Match silver-and-cyan materials of the uploaded style references. Not purple gothic flood, not mecha cockpit, not outdoor landscape.
```

**E00 refine — quieter center:**

```
Same clocktower underlay, but darken and simplify the center third so cards stay readable. Keep machinery detail toward the outer edges and deep background only. No text, no logos.
```

---

## E01 — `ui_magitech_gear_face_lg.png` · 512×512

Large face-on cog (Godot will rotate).

**Copy this:**

```
Game UI isolated prop, square canvas 512x512, transparent background outside the object.

ONE large face-on clockwork cogwheel / gear, centered, full circle visible. Brushed sacred-silver metal teeth and rim, dark charcoal recessed face, thin sanctified cyan light only in inner ring seams and bolt recesses. Ceremonial holy-tech machine part — solid opaque gear body, clean silhouette for rotation around center.

No hub logo, no crest, no letters, no runes-as-words, no second gear, no shafts sticking out. Not a button plaque. Not mecha. No watermark. Match uploaded silver-cyan style references.
```

---

## E02 — `ui_magitech_gear_face_md.png` · 512×512

**Copy this:**

```
Game UI isolated prop, square canvas 512x512, transparent background outside the object.

ONE medium face-on clockwork cogwheel, centered, full circle. Same holy-tech materials: brushed sacred silver teeth, dark recessed face, thin sanctified cyan seam glow. Slightly more teeth detail than a tiny icon, still one solid gear for spinning.

No logo, no crest, no text, no extra parts. Transparent outside. Match uploaded style references. No watermark.
```

---

## E03 — `ui_magitech_gear_face_sm.png` · 256×256

**Copy this:**

```
Game UI isolated prop, square canvas 256x256, transparent background outside the object.

ONE small face-on cogwheel, centered, full circle, readable teeth at small size. Brushed sacred silver with a thin cyan inner seam. Simple clean silhouette for reuse at many positions.

No logo, no crest, no text. Transparent outside. Match uploaded silver-cyan references. No watermark.
```

---

## E04 — `ui_magitech_gear_side.png` · 512×512

Thick roller / side-perspective gear (Castlevania clocktower “cylinder cog” look).

**Copy this:**

```
Game UI isolated prop, square canvas 512x512, transparent background outside the object.

ONE thick clockwork gear seen from the SIDE / three-quarter view — a short toothed cylinder / roller cog showing depth, not a flat face-on disc. Brushed sacred-silver rim and teeth, dark recesses, thin sanctified cyan seam accents. Holy-tech machine part, centered, opaque metal.

No logos, no crests, no text, no attached pistons, no second gear. Transparent outside. Match uploaded silver-cyan style references. Not mecha. No watermark.
```

---

## E05 — `ui_magitech_piston.png` · 256×512

Piston head + short rod (Godot pumps vertically). Prefer portrait canvas so the stroke reads clearly.

**Copy this:**

```
Game UI isolated prop, portrait canvas 256x512, transparent background outside the object.

ONE holy-tech piston assembly centered vertically: a short sacred-silver rod with a thicker piston head / plate at the top (or bottom), dark charcoal recesses, thin sanctified cyan seam rings on the head. Clean silhouette for up-down animation — no long infinite shaft filling the whole canvas; leave transparent padding above and below.

No logos, no crests, no text, no steam clouds, no extra machinery. Transparent outside. Match uploaded silver-cyan style references. No watermark.
```

**E05 refine — clearer head:**

```
Same piston, but make the head blockier and more readable at small size, keep the rod shorter, transparent padding top and bottom. No text, no logos.
```

---

## E06 — `ui_magitech_shaft.png` · 512×128

Straight axle / shaft segment.

**Copy this:**

```
Game UI isolated prop, landscape canvas 512x128, transparent background outside the object.

ONE straight horizontal sacred-silver machine shaft / axle, centered, cylindrical metal with soft highlight and thin cyan seam rings at the ends only. Clean bar for layering behind gears.

No logos, no text, no gears attached. Transparent outside. Match uploaded style references. No watermark.
```

---

## E07 — `ui_magitech_chain_seg.png` · 128×256

One chain link (optional; scroll later).

**Copy this:**

```
Game UI isolated prop, portrait canvas 128x256, transparent background outside the object.

ONE thick metal chain link for a holy-tech hoist, brushed sacred silver with dark inner recess and a faint cyan edge highlight. Vertical oval link, centered, clean silhouette for stacking into a chain.

No logos, no text, no second link. Transparent outside. Match uploaded style references. No watermark.
```

---

## E08 — `ui_magitech_belt_strip.png` · 512×128

Short ridged belt tile (optional; scroll later). Should tile horizontally.

**Copy this:**

```
Game UI isolated prop, landscape canvas 512x128, transparent background outside the object.

ONE short horizontal ridged conveyor / drive-belt strip, tileable left-to-right. Dark charcoal belt with brushed sacred-silver ridge teeth / cleats and a thin sanctified cyan edge glint. Flat strip only — no rollers, no gears, no frame.

No logos, no text. Transparent above and below the strip. Match uploaded silver-cyan style references. No watermark.
```

---

## Phase E — Reject if

- Full clocktower stage baked into one “gear” asset  
- Platformer ledges, stairs, Alucard-like character, purple SotN palette flood  
- Hub crests / faction logos on cog centers  
- Mecha robot limbs, cyberpunk neon tubes, hologram gears  
- Photoreal photo scrap / watermark  
- Motion already baked as frames (we animate in Godot — deliver still PNGs only)  

---

# Phase B — Game-wide chrome icons

**Goal:** Replace player-facing unicode / old decoration icons with Magitech v3 holytech PNGs.  
**Gate:** Phase A battle screen approved ✓.  
**Pipeline:** [MAGITECH_V3_FORGEGUI_PIPELINE.md](MAGITECH_V3_FORGEGUI_PIPELINE.md) → Phase B.  
**Save to:** `assets/textures/ui/magitech_v3/chrome/`  

**Order:** Generate **B1** first (8 action icons) → wire in Godot → then **B2** reskins → **B3** only if unicode still sticks out.  
**Skip this pass:** Exploration HUD (**B13–B17**, **B26**); exit (**B10**); credit (**B12**); magnifier (**B18**); campaign platforms (**B19–B20**).

**Style lock:** blank `#20` panel + one approved plaque (End Turn / Options).  
Prefer **remove** holytech kit board (crests leak onto icon hubs).

**Hard rules (every B icon):**

- Isolated single icon · transparent outside · centered · readable at ~24–40px UI size  
- Brushed sacred silver + thin sanctified cyan accents · dark charcoal recesses  
- **No text, no letters, no logos, no faction crests, no watermark**  
- Not emoji / not flat Material-icon blue · not mecha · not cyberpunk neon · not purple flood  
- Destructive icons (delete / scrap): same silver kit, slightly warmer/darker void face — not a second rainbow skin  

**Shared refine — strip branding:**

```
Identical silver-cyan UI icon, but DELETE every logo, crest, emblem, seal, letter, and watermark. Plain brushed sacred silver with thin cyan accents only. Transparent outside.
```

---

## Phase B — Flat metal alt (preferred for tiny UI)

Use this **instead of** the ornate B1–B3 plaque prompts when generating chrome icons. Same filenames / save path.  
**Style lock:** blank `#20` only (or none). Do **not** attach End Turn / Options plaques — they force deep bevels.

### Master style (paste every gen) · 128×128

**Copy this**, then append the one-line **Glyph** for that ID:

```
Game UI flat icon, exact square 128x128, transparent background outside the glyph.

FLAT METAL SILHOUETTE style (not embossed UI plaque, not 3D dossier chrome):
- One bold opaque glyph centered, filling 75–90% of the canvas
- Brushed sacred-silver fill, almost flat — tiny soft shade only, NO deep grooves, NO bolts, NO heavy bevels, NO nested panels
- Thin sanctified cyan EDGE STROKE / rim light only (1–2px feel), optional single cyan accent cut
- Hard clean silhouette readable at 24px; simple shapes; minimal internal detail
- Magitech holy-tech palette: silver + cyan on transparency — not Material blue, not emoji, not mecha, not cyberpunk neon, not purple

CRITICAL: no text, no letters, no logos, no crests, no watermark. Transparent outside the glyph only.
```

### Glyph lines (append under master)

| ID | Save as | Append this Glyph line |
|----|---------|------------------------|
| B01 | `ui_v3_icon_duplicate.png` | `Glyph: two overlapping flat silver rectangles (copy / duplicate), cyan edge.` |
| B02 | `ui_v3_icon_delete.png` | `Glyph: flat silver trash-hatch or bin silhouette, slightly darker face, cyan edge.` |
| B03 | `ui_v3_icon_close.png` | `Glyph: bold flat silver X (two bars), cyan edge.` |
| B04 | `ui_v3_icon_featured.png` | `Glyph: flat five-point silver star, cyan edge.` |
| B05 | `ui_v3_icon_remove.png` | `Glyph: small flat silver X in a thin cyan ring (card-corner remove).` |
| B06 | `ui_v3_icon_add.png` | `Glyph: bold flat silver plus +, cyan edge.` |
| B07 | `ui_v3_icon_scrap.png` | `Glyph: flat silver scissors / shears silhouette, cyan edge.` |
| B08 | `ui_v3_icon_locked.png` | `Glyph: flat silver padlock, cyan edge.` |
| B09 | `ui_v3_icon_setting.png` | `Glyph: flat silver cog / gear face, cyan edge.` |
| B10 | *(skip — unused)* | Do not generate. |
| B11 | `ui_v3_mailbox.png` | `Glyph: flat silver envelope or mail hatch, cyan edge.` |
| B12 | *(skip — credit)* | Do not generate this pass. |
| B13–B17 | *(deferred — Exploration HUD)* | Skip this pass. |
| B18 | *(skip — magnifier)* | Do not generate this pass. |
| B19–B20 | *(skip — campaign platforms)* | Do not generate this pass. |
| B21 | `ui_v3_icon_back.png` | `Glyph: flat silver left chevron / back arrow, cyan edge.` |
| B22 | `ui_v3_icon_expand.png` | `Glyph: flat silver expand chevron (right or down), cyan edge.` |
| B23 | `ui_v3_icon_collapse.png` | `Glyph: flat silver collapse chevron (up), cyan edge.` |
| B24 | `ui_v3_icon_list.png` | `Glyph: three flat silver horizontal list bars, cyan ticks.` |
| B25 | `ui_v3_icon_grid.png` | `Glyph: flat silver 2x2 grid tiles, cyan seams.` |
| B26 | *(deferred — Exploration mail badge)* | Skip this pass. |
| B27 | `ui_v3_icon_formations.png` | `Glyph: flat silver tactical slate with three unit pips, cyan edge.` |
| B28 | `ui_v3_icon_copy.png` | `Glyph: simpler overlapping flat silver plates (copy), cyan edge.` |

**Example full paste (B07 scrap):**

```
Game UI flat icon, exact square 128x128, transparent background outside the glyph.

FLAT METAL SILHOUETTE style (not embossed UI plaque, not 3D dossier chrome):
- One bold opaque glyph centered, filling 75–90% of the canvas
- Brushed sacred-silver fill, almost flat — tiny soft shade only, NO deep grooves, NO bolts, NO heavy bevels, NO nested panels
- Thin sanctified cyan EDGE STROKE / rim light only (1–2px feel), optional single cyan accent cut
- Hard clean silhouette readable at 24px; simple shapes; minimal internal detail
- Magitech holy-tech palette: silver + cyan on transparency — not Material blue, not emoji, not mecha, not cyberpunk neon, not purple

CRITICAL: no text, no letters, no logos, no crests, no watermark. Transparent outside the glyph only.

Glyph: flat silver scissors / shears silhouette, cyan edge.
```

**Flat-alt reject if:** deep plaque chrome, bolts/rivets soup, tiny unreadable filigree, emoji look, blue Material icons.

---

## B1 — High-priority action icons · 128×128

*(Ornate plaque variants — use only if Flat alt above feels too plain.)*

### B01 — `ui_v3_icon_duplicate.png` · 128×128

Replaces `❐` (Deck Switch Gallery — duplicate deck).

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent background outside the icon.

ONE holy-tech duplicate / copy control: two overlapping sacred-silver dossier plaques or tablets, slightly offset, thin sanctified cyan seam accents. Reads clearly as “make a copy” at small size. Centered, opaque metal faces, clean silhouette.

No text, no letters, no logos, no crests, no watermark. Match uploaded silver-cyan style references. Not mecha, not cyberpunk.
```

---

### B02 — `ui_v3_icon_delete.png` · 128×128

Replaces `🗑` (Deck Switch Gallery — delete).

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent background outside the icon.

ONE holy-tech delete control: a brushed sacred-silver waste-chute / incinerator hatch or sealed discard vault door with a darker charcoal void face and thin sanctified cyan seam. Slightly warmer darker metal than normal icons so it reads as destructive, still same kit. Simple, readable at small size — not a cartoon trash can emoji.

No text, no logos, no crests, no skull, no watermark. Match uploaded silver-cyan style references.
```

---

### B03 — `ui_v3_icon_close.png` · 128×128

Replaces `✕` / `×` (overlay close).

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent background outside the icon.

ONE holy-tech close / dismiss mark: a bold sacred-silver X formed by two beveled metal bars with thin cyan edge light, centered in a small dark hex or circular recess. Clean geometric X — not a letter “X” typography, not a skull.

No text, no logos, no crests, no watermark. Match uploaded silver-cyan style references.
```

---

### B04 — `ui_v3_icon_featured.png` · 128×128

Replaces `★` (Deck Builder featured star).

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent background outside the icon.

ONE holy-tech featured / favorite mark: a five-point ceremonial star medallion in brushed sacred silver with a thin sanctified cyan inner glow. Solid opaque star, sharp readable points at small size. Optional tiny bolt detail — no faction crest inside.

No text, no logos, no watermark. Match uploaded silver-cyan style references.
```

---

### B05 — `ui_v3_icon_remove.png` · 128×128

Replaces `×` on cards (Deck Builder remove-from-deck).

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent background outside the icon.

ONE small holy-tech remove-from-list mark: a compact sacred-silver X inside a small dark circular chip / hex port, cyan seam ring. Smaller visual weight than the overlay close icon — meant to sit on a card corner.

No text, no logos, no crests, no watermark. Match uploaded style references.
```

---

### B06 — `ui_v3_icon_add.png` · 128×128

Replaces `⊕` (Deck Builder add).

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent background outside the icon.

ONE holy-tech add / plus control: a bold sacred-silver plus sign (+) inside a dark circular chip with thin sanctified cyan ring. Beveled metal bars, clean silhouette, readable at small size.

No text, no logos, no crests, no watermark. Match uploaded silver-cyan style references.
```

---

### B07 — `ui_v3_icon_scrap.png` · 128×128

Replaces `✂` (Card Gallery scrap).

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent background outside the icon.

ONE holy-tech scrap / cut control: ceremonial silver shears or a cutting guillotine blade plate with darker void accents and thin cyan seam. Reads as “destroy / scrap card,” same kit as delete but distinct silhouette from the trash hatch.

No text, no logos, no crests, no watermark. Match uploaded style references. Not a cute emoji scissors.
```

---

### B08 — `ui_v3_icon_locked.png` · 128×128

Replaces `🔒` (Campaign gallery locked packs).

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent background outside the icon.

ONE holy-tech lock: a brushed sacred-silver padlock / vault latch with dark charcoal shackle recess and thin sanctified cyan keyhole seam glow. Solid, readable at small size.

No text, no logos, no crests, no watermark. Match uploaded silver-cyan style references.
```

---

## B2 — Shared nav / system reskins

Often replacing existing decoration PNGs. Same style rules. Canvas **128×128** unless noted.

### B09 — `ui_v3_icon_setting.png` · 128×128

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent outside.

ONE holy-tech settings cog: face-on sacred-silver gear with cyan seam ring, clean teeth, dark hub (no crest). Match uploaded silver-cyan references. No text, no logos, no watermark.
```

---

### B10 — `ui_v3_icon_exit.png` *(skip — unused)*

Do not generate. Exit icon is not used in player UI.

---

### B11 — `ui_v3_mailbox.png` · 128×128

**Copy this:**

```
Game UI isolated icon, square canvas 128x128, transparent outside.

ONE holy-tech mailbox / courier hatch: brushed sacred-silver sealed letter slot or dossier drop box with thin cyan seam. Readable as mail. No text, no logos, no crest stamps, no watermark. Match uploaded style references.
```

---

### B12 — `ui_v3_icon_credit.png` *(skip this pass)*

Do not generate. Keep current credit icon.

---

### B13–B17 — Exploration HUD *(deferred — skip this pass)*

Do not generate compass / exploration settings / info / chat / inventory this Phase B pass. Keep current exploration HUD art.

---

### B18 — `ui_v3_icon_magnifier.png` *(skip this pass)*

Do not generate. Keep current magnifier art.

---

### B19–B20 — Campaign platforms *(skip this pass)*

Do not generate `ui_v3_campaign_platform_normal.png` / `ui_v3_campaign_platform_boss.png`. Keep current campaign map nodes.

---

## B3 — Secondary nav icons · 128×128

Generate only if unicode still sticks out after B1–B2 wiring.

### B21 — `ui_v3_icon_back.png`

```
Game UI isolated icon, 128x128, transparent outside. ONE holy-tech back chevron / left arrow in brushed sacred silver with cyan edge. No text, no logos. Match uploaded references. No watermark.
```

### B22 — `ui_v3_icon_expand.png`

```
Game UI isolated icon, 128x128, transparent outside. ONE holy-tech expand mark: sacred-silver right/down chevron or unfolded plate, cyan seam. No text, no logos. Match uploaded references. No watermark.
```

### B23 — `ui_v3_icon_collapse.png`

```
Game UI isolated icon, 128x128, transparent outside. ONE holy-tech collapse mark: sacred-silver up chevron or folded plate, cyan seam. Distinct from expand. No text, no logos. Match uploaded references. No watermark.
```

### B24 — `ui_v3_icon_list.png`

```
Game UI isolated icon, 128x128, transparent outside. ONE holy-tech list view: three horizontal sacred-silver dossier lines with cyan ticks. No text. Match uploaded references. No watermark.
```

### B25 — `ui_v3_icon_grid.png`

```
Game UI isolated icon, 128x128, transparent outside. ONE holy-tech grid view: 2x2 sacred-silver tile ports with cyan seams. No text. Match uploaded references. No watermark.
```

### B26 — `ui_v3_icon_mail_badge.png` *(deferred — Exploration HUD)*

Skip this pass. Keep current exploration mail badge.

### B27 — `ui_v3_icon_formations.png`

```
Game UI isolated icon, 128x128, transparent outside. ONE holy-tech formations / tactical slate: sacred-silver grid plaque with three unit pips and cyan seams. No text, no logos. Match uploaded references. No watermark.
```

### B28 — `ui_v3_icon_copy.png`

```
Game UI isolated icon, 128x128, transparent outside. ONE holy-tech copy mark (player UI only): overlapping silver plates similar to duplicate but simpler single glyph. No text, no logos. Match uploaded references. No watermark.
```

---

## Phase B — Reject if

- Unicode emoji look-alikes or Google Material flat icons  
- Baked words / letters (except geometric info “i” bars as metal shapes)  
- Faction crests on hubs  
- Mecha / cyberpunk / purple neon  
- Editors-only tools (out of scope)  
- Bluff reaction faces (keep unicode — do not gen)  
