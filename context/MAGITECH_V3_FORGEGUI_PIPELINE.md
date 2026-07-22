# Magitech v3 — ForgeGUI pipeline

**Primary tool:** [ForgeGUI](https://forgegui.com/) (style lock). **God Mode is retired** for new textured chrome.  

**Troubleshoot:** If output ignores the kit (generic / cartoon UI), style refs likely did not upload — re-attach and confirm they are active before re-rolling.  

**Look:** Holy Tech / Witchhunter Corp — sacred brushed silver + sanctified cyan.  
**Phase A prompts:** [MAGITECH_V3_FORGEGUI_PROMPTS.md](MAGITECH_V3_FORGEGUI_PROMPTS.md) → `battle/v3_magitech/`  
**Style refs:** `assets/textures/ui/magitech_v3/_style_refs/`  
**Phase B exports:** `assets/textures/ui/magitech_v3/chrome/` (then wire in code)  
**Phase C:** Hover shaders — circuit patrol on chrome + once-per-hover metal sheen on context icons (see below)  
**Phase D:** Gradient / circulating borders on dialogs & buttons + animated battle 5×5 grid lines (see below)  
**Phase E:** Clockwork playmat — modular gears/pistons (ForgeGUI pieces + Godot spin/pump). Prompts in [MAGITECH_V3_FORGEGUI_PROMPTS.md](MAGITECH_V3_FORGEGUI_PROMPTS.md) → **Phase E**

## Revertible battle skins

| Command | Skin |
|---------|------|
| `hud_skin v3` | Magitech v3 holytech |
| `hud_skin v2` | Magitech v2 cyan/chrome |
| `hud_skin v1` | Original decorations |

Missing v3 files fall back to v2 → v1 (`HudSkin.gd`). **Default boot is `"v3"`** (`HudSkin.version`). Switch anytime: `hud_skin v1|v2|v3`.

---

## Phase A — Battle HUD (approved ✓)

Core kit in `battle/v3_magitech/` + `HudSkin` / `GameBoard` / `Card` / `BattleCalculationOverlay`.  
Skipped leftovers (fall back): #2 game over, #15 context panel, #17 exposed, #21 options row, #22–23 coins, #25–26 eyes (open is present; closed defers).  
**In-game approved** — proceed to Phase B.

---

## Phase B — Game-wide chrome actions (in progress)

Replace **player-facing** unicode/emoji control icons with holytech PNGs.  
Keep **bluff reaction emojis** as unicode.  
Skip **editor-only** tools (VNEditor, ExplorationEditor, builders) unless you later want a “dev skin.”  
**Prompts:** [MAGITECH_V3_FORGEGUI_PROMPTS.md](MAGITECH_V3_FORGEGUI_PROMPTS.md) → **Phase B**.  
**Quick-win silhouettes (wired):** `assets/textures/ui/silhouettes/` via `ChromeIcon` autoload.  
**Future Magitech chrome (optional):** `assets/textures/ui/magitech_v3/chrome/`

### B1 — High priority (menus players hit often)

| ID | Save as | Replaces | Where used today |
|----|---------|----------|------------------|
| B01 | `ui_v3_icon_duplicate.png` | `❐` | Deck Switch Gallery — duplicate deck |
| B02 | `ui_v3_icon_delete.png` | `🗑` | Deck Switch Gallery — delete deck |
| B03 | `ui_v3_icon_close.png` | `✕` / `×` | Overlays close (Protagonist, formations, gallery…) |
| B04 | `ui_v3_icon_featured.png` | `★` | Deck Builder featured star |
| B05 | `ui_v3_icon_remove.png` | `×` on cards | Deck Builder remove-from-deck |
| B06 | `ui_v3_icon_add.png` | `⊕` | Deck Builder add affordance |
| B07 | `ui_v3_icon_scrap.png` | `✂` | Card Gallery scrap / scrap-all |
| B08 | `ui_v3_icon_locked.png` | `🔒` | Campaign gallery locked packs |

### B2 — Shared nav / system (often already PNG — reskin)

| ID | Save as | Replaces / reskins | Where |
|----|---------|-------------------|--------|
| B09 | `ui_v3_icon_setting.png` | `ui_icon_setting.png` | Main menu / settings |
| B11 | `ui_v3_mailbox.png` | `ui_mailbox.png` | Mail |

### B2 deferred / skipped this pass

| ID | Save as | Why |
|----|---------|-----|
| B10 | `ui_v3_icon_exit.png` | Unused — skip |
| B12 | `ui_v3_icon_credit.png` | Skip this pass |
| B13 | `ui_v3_icon_compass.png` | Exploration HUD — later |
| B14 | `ui_v3_icon_exploration_setting.png` | Exploration HUD — later |
| B15 | `ui_v3_icon_exploration_info.png` | Exploration HUD — later |
| B16 | `ui_v3_icon_exploration_chat.png` | Exploration HUD — later |
| B17 | `ui_v3_exploration_inventory.png` | Exploration HUD — later |
| B18 | `ui_v3_icon_magnifier.png` | Skip this pass |
| B19 | `ui_v3_campaign_platform_normal.png` | Campaign map — skip this pass |
| B20 | `ui_v3_campaign_platform_boss.png` | Campaign map — skip this pass |
| B26 | `ui_v3_icon_mail_badge.png` | Exploration mail — later |

### B3 — Secondary chrome (do after B1–B2)

| ID | Save as | Replaces | Where |
|----|---------|----------|--------|
| B21 | `ui_v3_icon_back.png` | `←` | Back buttons (battle options; exploration later) |
| B22 | `ui_v3_icon_expand.png` | `▶` / `▾` | Advanced filters, expand |
| B23 | `ui_v3_icon_collapse.png` | `▼` / `▴` | Collapse |
| B24 | `ui_v3_icon_list.png` | `≡` | Deck gallery list mode |
| B25 | `ui_v3_icon_grid.png` | `⊞` | Deck gallery grid mode |
| B27 | `ui_v3_icon_formations.png` | `📋` formations | Deck Builder formations entry |
| B28 | `ui_v3_icon_copy.png` | `📋` copy | Only if used in **player** UI (editors stay text) |

*(B26 mail badge deferred with Exploration HUD — see B2 deferred.)*

### Out of scope for Phase B

| Keep as-is | Why |
|------------|-----|
| Bluff picker emojis | Content / expression, not chrome |
| TECH / VOID / END TURN labels | Phase A battle PNGs |
| Exploration HUD icons (B13–B17, B26) | Deferred — skip this pass |
| Exit icon (B10) | Unused in game — skip |
| Credit icon (B12) | Skip this pass |
| Magnifier (B18) | Skip this pass |
| Campaign platforms (B19–B20) | Skip this pass |
| VNEditor / ExplorationEditor / builders | Dev tools |
| Admin-only / vault-manager `✕` closes | Leave unicode — not player chrome |
| Card rarity `★` strings | Card data display, not chrome buttons |
| Affinity `⚙` on cards | Card glyph — separate decision later |

---

## Phase B plan (order of work)

```mermaid
flowchart LR
  A[Finish_Phase_A_battle]
  B1[ForgeGUI_B1_action_icons]
  Wire1[Wire_DeckGallery_DeckBuilder]
  B2[Reskin_shared_menu_PNGs]
  Wire2[Point_loads_to_v3_chrome]
  B3[Secondary_nav_icons]
  Flats[MagitechTheme_GameDialog]
  A --> B1 --> Wire1 --> B2 --> Wire2 --> B3
  Wire2 --> Flats
```

1. **Gate:** Phase A battle kit approved ✓ (`hud_skin v3`).  
2. **Generate B1** (8 icons) — 128×128, blank sacred-silver + cyan, no baked words.  
3. **Wire B1** — `DeckSwitchGallery`, `DeckBuilder`, `CardGallery`, `CampaignGallery`, overlay closes. Prefer one helper e.g. `ChromeIcon.tex("duplicate")` so paths stay centralized.  
4. **Generate B2** — reskin existing decoration PNGs into `magitech_v3/chrome/`.  
5. **Wire B2** — swap `load("…/decorations/…")` / scene ext_resources to v3 chrome (or a small path map like HudSkin).  
6. **B3** only if unicode still sticks out after B1–B2.  
7. **Flats** — MagitechTheme / GameDialog in parallel (not ForgeGUI).

### ForgeGUI rules for Phase B icons

- Style lock: approved `#20` panel + one approved plaque (End Turn / Options).  
- Canvas: **128×128** (campaign platforms **256×256**).  
- Freeform or small hex seal; no faction logos; no text on icon (except none).  
- Destructive (delete/scrap): same silver, slightly warmer/darker void face — not a second rainbow skin.

### Acceptance

- [ ] No `❐` / `🗑` / scrap `✂` / featured `★` unicode on player deck flows  
- [ ] Main menu setting / mailbox match holytech  
- [ ] Editors may still use unicode  
- [ ] Bluff emojis unchanged  

---

## Phase C — Hover shaders (planned)

**Gate:** Phase A battle kit in-game (`hud_skin v3`). Can start after A even if B is unfinished — battle HUD only first.

### C1 — Circuit patrol (chrome buttons)

**Effect:** Fragment shader on hover — a cyan glowing signal “patrols” through the button’s baked V-grooves / cyan seam channels (sample bright/cyan edges in the texture, animate a traveling highlight with `TIME`). Not GPU particles.

| Control | Asset / note |
|---------|----------------|
| TECH stack chip | `ui_magitech_tech.png` |
| VOID stack chip | `ui_magitech_void.png` |
| Union (big center) | `ui_magitech_union.png` |
| End Turn | `ui_magitech_end_turn.png` |
| Options | `ui_magitech_options.png` |
| Eye open / eye closed | `ui_magitech_eye_open.png` / `ui_magitech_eye_closed.png` |

### C2 — Metal reflect sweep (card context menu)

**Effect:** On the card context menu icons (**Attack / Info / Bluff / Union**), **once per hover** — a short **metal specular / sheen** that travels **left → right** across the icon, then dismisses (same feel as a “new item” shine). Does **not** loop while the cursor stays; re-fires only after mouse exit + enter again.

| Icon | Asset |
|------|--------|
| Attack | `ui_magitech_attack.png` |
| Info | `ui_magitech_info.png` |
| Bluff | `ui_magitech_bluff.png` |
| Union (context slot) | `ui_magitech_union.png` |

Wire on the context-menu icon controls in `GameBoard` (where `CTX_ICON_*` are applied).

### Implementation sketch

1. **C1:** `assets/shaders/magitech_circuit_patrol.gdshader` — params: speed, glow color, intensity; idle = identity; hover = animated patrol band.  
2. **C2:** `assets/shaders/magitech_metal_reflect.gdshader` (or shared sheen) — diagonal/vertical band of specular highlight; drive `progress` 0→1 once on `mouse_entered`, then idle; reset arming on `mouse_exited`.  
3. Shared materials / tiny helper; apply only when `HudSkin` is `v3` (v1/v2 stay plain).  
4. Keep modulate/blink (e.g. end-turn tutorial blink) compatible — don’t fight existing tweens.

### Out of scope for Phase C

- Phase B chrome icons  
- Always-on idle patrol / looping sheen while hovered  
- Groove patrol on context icons (C2 is sheen only)

### Acceptance

- [ ] Hover TECH / VOID / Union / End Turn / Options / eyes → cyan groove patrol  
- [ ] Hover Attack / Info / Bluff / Union (context) → one L→R metal sheen, then stop  
- [ ] Sheen re-arms only after mouse leaves and re-enters  
- [ ] Mouse exit → clean stop, no stuck glow/sheen  
- [ ] `hud_skin v1|v2` unchanged  
- [ ] No particle emitters required  

---

## Phase D — Gradient styling + battle grid (planned)

**Gate:** After Phase C hover shader lands (shared shader habits). Can prototype grid or one dialog earlier if needed.

**`GameDialog` stay as-is:** Keep the current flat StyleBox dialog structure/layout — it is already good. **Do not** swap in ForgeGUI `#20` `ui_magitech_panel_9slice.png`. Phase D only adds polish on top of the existing dialog chrome.

**Effect A — `GameDialog` polish (shader / StyleBox only):**
- **Gradient border** — cyan↔silver holytech rim (optional slow circulating variant via `TIME`)
- **Gradient background** — soft dark navy→void fill (not a flat single color), still readable for title/body text  
No 9-slice texture, no ForgeGUI re-bake for dialogs.

**Effect B — battle 5×5 grid lines:** Replace solid `ColorRect` strips in `GameBoard._add_grid_line_panels()` with a **gradient line** (cyan↔silver / soft cyan pulse along the strip) that **loop-animates slowly** (gentle travel / shimmer, not a fast strobe). Outer frame + inner row/column separators on both P1 and P2 grids.

### Targets (first pass)

| Surface | Notes |
|---------|--------|
| `GameDialog` panels | Keep structure; add gradient border + gradient fill only |
| Primary action buttons | Optional matching gradient rim |
| Battle 5×5 grid lines | Both boards; outer + inner separators; slow loop animation |

### Implementation sketch

1. Extend `GameDialog.make_panel_stylebox` / button styles — or a small shader overlay — for gradient fill + gradient rim; params: colors (cyan/silver), speed, `animate` on/off.  
2. Do **not** load `#20` panel 9-slice onto dialogs.  
3. Grid: e.g. `assets/shaders/magitech_grid_line.gdshader` on each strip (or one overlay per board) — 1D gradient along the line + `TIME` offset for slow loop; reuse `battle_grid_border` group + `refresh_grid_borders()`.  
4. Respect `hud_skin` — v3 holytech animated grid / dialog polish; v1/v2 keep current look unless opted in later.

### Out of scope for Phase D

- Wiring `#20` 9-slice into `GameDialog` (explicitly rejected — dialog stays StyleBox-based)  
- Rainbow / purple cyber borders  
- Always-on high-speed spin on every control (keep it sparse)  
- Fast / seizure-risk grid flashing  

### Acceptance

- [ ] `GameDialog` still same layout/structure; gradient border + gradient background only  
- [ ] Text remains readable on gradient fill  
- [ ] Optional circulating rim works without washing out text  
- [ ] 5×5 grid lines: visible gradient + slow seamless loop on both boards  
- [ ] `hud_skin v1|v2` unchanged (unless explicitly enabled)  
- [ ] No ForgeGUI re-gen / no `#20` on dialogs  

---

## Phase E — Clockwork playmat (planned)

**Gate:** Phase A playmat + chrome approved in-game. Can run in parallel with B/C/D.

**Approach (locked):** modular ForgeGUI **pieces** + Godot rotation / piston tweens.  
**Not:** one full animated 1280×720 GIF/video, not AI-video of the whole stage.

Castlevania clocktower feel = layered depth + independent RPM. Keep motion **slow and sparse** behind the card grids so boards stay readable.

### E1 — Asset kit (ForgeGUI → PNG + alpha)

Save under `assets/textures/ui/battle/v3_magitech/clockwork/`.  
Prompts: [MAGITECH_V3_FORGEGUI_PROMPTS.md](MAGITECH_V3_FORGEGUI_PROMPTS.md) → Phase E.

| ID | Save as | Role | Animate in Godot |
|----|---------|------|------------------|
| E00 | `ui_magitech_clockwork_underlay.png` | Far stone / machine wall (static) | No (optional; else keep current playmat) |
| E01 | `ui_magitech_gear_face_lg.png` | Large face-on cog | Spin |
| E02 | `ui_magitech_gear_face_md.png` | Medium face-on cog | Spin |
| E03 | `ui_magitech_gear_face_sm.png` | Small face-on cog | Spin |
| E04 | `ui_magitech_gear_side.png` | Thick side-view / roller gear | Spin on local axis (or fake with scale) |
| E05 | `ui_magitech_piston.png` | Piston head + short rod (isolated) | Vertical pump |
| E06 | `ui_magitech_shaft.png` | Straight sacred-silver shaft / axle | Optional slow drift |
| E07 | `ui_magitech_chain_seg.png` | One chain link / short segment | Optional scroll (later) |
| E08 | `ui_magitech_belt_strip.png` | Short ridged belt tile (tileable X) | Optional scroll (later) |

**Ship-first subset:** E00 (or reuse #1 playmat) + E01–E03 + E05. Add E04/E06–E08 if depth still feels thin.

### E2 — Godot wiring (after assets land)

1. Under `Background` / playmat: a `ClockworkLayer` `Control` with `clip_contents`, z below cards/grids/fog.  
2. Instance ~8–15 gear `TextureRect`s (reuse E01–E03 at different scales/modulate).  
3. Per gear: continuous `rotation` at different RPM (e.g. ±4°/s … ±18°/s).  
4. 1–2 pistons: slow Y ping-pong (1.5–3s).  
5. Far pieces darker / lower alpha; near pieces slightly brighter — fake depth, no camera parallax required.  
6. Mute or pause motion when full-info / reckoning overlays are up (optional polish).  
7. `hud_skin v3` only; v1/v2 keep static playmat.

### Style lock for Phase E

- Materials: blank `#20` panel + approved playmat / end-turn silver (logo-free).  
- Prefer **remove** holytech kit board (crests leak onto gears).  
- No text, logos, crests on any clockwork piece.  
- Magitech silver + thin cyan seams — **not** SotN purple stone flood, not rust-brown only, not mecha.

### Out of scope for Phase E

| Skip | Why |
|------|-----|
| Full-screen loop video / GIF | Size, style drift, unreadable under cards |
| Animated whole-stage AI video | Loses style lock + independent RPM |
| Dense foreground gears over card cells | Cards must stay readable |
| Fast / seizure-risk spin | Keep slow ceremonial grind |
| Replacing top dashboard / bottom vault | Separate chrome; playmat mid only |

### Acceptance

- [ ] Modular PNGs with clean alpha (no baked full stage)  
- [ ] In-game: gears spin, ≥1 piston pumps, cards remain readable  
- [ ] Motion stays behind grids; overlays still above smoke/VFX as today  
- [ ] `hud_skin v1|v2` unchanged  
- [ ] No GIF / full playmat video required for ship  

## Privacy

Prefer a paid ForgeGUI plan (or disable public catalog) before generating proprietary kit pieces.
