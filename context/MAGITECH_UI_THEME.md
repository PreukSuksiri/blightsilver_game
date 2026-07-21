# Magitech UI Theme (locked)

**Authority:** This document + `scripts/theme/MagitechTheme.gd` define the **one** Magitech UI language for all player-facing pages. Apply via `GameDialog` / shared helpers — **no** Godot Theme `.tres` (store Themes and project Theme defaults are out of scope).

**Textured HUD tool:** [ForgeGUI](https://forgegui.com/) (style-lock) — **not** God Mode.  
**Sibling:** Magitech **v3** prompts [MAGITECH_V3_FORGEGUI_PROMPTS.md](MAGITECH_V3_FORGEGUI_PROMPTS.md) · pipeline [MAGITECH_V3_FORGEGUI_PIPELINE.md](MAGITECH_V3_FORGEGUI_PIPELINE.md) · style guide + v2 archive [PLAYMAT_V2_EXTRA_WIDTH.md](PLAYMAT_V2_EXTRA_WIDTH.md)  
**Dialogs:** Must migrate toward this kit — [GAME_DIALOG_POPUP_GUIDE.md](GAME_DIALOG_POPUP_GUIDE.md)  
**Skin switch:** `hud_skin v1|v2|v3` via `HudSkin` (v3 ↔ v2 easily revertible).

---

## Consistency-first rule

Every surface shares the same:

1. Palette tokens  
2. Font slots (`primary` / `display_serif` / `digital`)  
3. Chrome recipe (panel, button, LineEdit, modal dim, **radius 8**)  
4. Hierarchy (primary / secondary / destructive / locked)

**If you need a new color or radius, update this doc + `MagitechTheme.gd` — do not invent a local `StyleBoxFlat`.**

### Allowed exceptions

| Exception | Where | Notes |
|-----------|--------|------|
| HudSkin `v2_magitech/` / `v3_magitech/` PNGs | Battle HUD | Textured skins; switch via `hud_skin v2\|v3` |
| Slate `#12141a` | Playmat floor only | Never dialog/menu panel fill |
| Amber / gold | Economy, cost warn, featured star | Not a second metal on every frame |

### Forbidden

- Second dialog skin (VN navy vs Magitech)
- Main-menu-only Material soft pills (12px+ soft glow stacks)
- Per-overlay unique navy recipes
- Pink / magenta / purple edge glow

---

## Palette tokens

| Token | Hex | Godot / use |
|-------|-----|-------------|
| Void | `#060810` | Panel / HUD voids |
| Charcoal | `#141820` | Inset metal face |
| Slate | `#12141a` | Playmat floor only |
| Chrome | `#c0c8d8` | Primary rim |
| Chrome bright | `#e8eef5` | Specular / hover rim |
| Cyan | `#00e5ff` | Energy / title glow / hover accent |
| Cyan soft | `#2ebfff` | Secondary glow |
| Ice text | `#E8F4FF` | Body / button labels |
| Warn amber | `#F0C040` | Cost warn / featured |
| Destructive | `#C45A4A` | Delete / surrender emphasis |

Constants: `MagitechTheme.VOID`, `.CHROME`, `.CYAN`, etc.

---

## Typography

| Slot (`fonts.json`) | Font | Use |
|---------------------|------|-----|
| `primary` | Chivo | Menus, body, buttons (all pages) |
| `display_serif` | Farro Bold | Overlay / section titles |
| `digital` | digit-tech | HUD numbers / timers only |

| Role | Size |
|------|------|
| Title | 22 |
| Body | 18 |
| Button | 17 |

---

## Shared chrome recipes

### Panel

- Fill: void `#060810` @ ~97% opacity  
- Border: chrome `#c0c8d8`, width **2**  
- Corner radius: **8**  
- Optional: cyan inner emphasis on focus/hover only (not a second border color language)

### Button

| State | Face | Border |
|-------|------|--------|
| Normal | dark void | chrome |
| Hover | slightly lifted void | cyan or bright chrome |
| Pressed | deeper void | chrome dim |
| Disabled | muted void | muted chrome; ice text @ ~55% |

Min size: `140×40` (dialog / menu CTAs). Icon-square buttons may use height = width.

### LineEdit / SpinBox line

- Fill: charcoal / deep void  
- Border: muted chrome; **cyan** on focus  
- Radius: **8**  
- Text: ice; placeholder muted ice  

### Modal dim

- Soft void vignette behind dialogs (not fully transparent blocker)

---

## Hierarchy

| Kind | Treatment |
|------|-----------|
| Primary | Cyan seam / hover energy |
| Secondary | Chrome rim, quieter face |
| Destructive | Dim void + warm/destructive edge |
| Locked | Pitch-black art; muted chrome; not hidden |

---

## Surface inventory (must use shared recipes)

- [ ] Main menu  
- [ ] Deck builder (+ Switch Deck shell)  
- [ ] Battle procedural overlays (handoff, confirm, tech modal, Options via GameDialog)  
- [ ] GameDialog (all confirms / accepts / prompts)  
- [ ] Shop / Settings / Inventory  
- [ ] Exploration overlays  
- [ ] Quick Duel  
- [ ] VN player chrome (where Control-based)

Per-surface **layout** may differ; **chrome tokens must not**.

---

## Implementation path

| Item | Path |
|------|------|
| Constants + StyleBox helpers | `res://scripts/theme/MagitechTheme.gd` |
| Shared dialog / button skin | `res://autoload/GameDialog.gd` |

**No** `Theme` resource and **no** Project Settings → GUI → Theme. Iterate by retargeting helpers and screen-local StyleBoxes to `MagitechTheme` tokens.

---

## Migration map (current violators)

| Area | Today | Target owner |
|------|--------|----------------|
| `GameDialog.gd` | VN navy blue | Retarget constants → MagitechTheme |
| Main menu buttons | StyleBoxFlat Material-lite | MagitechTheme helpers |
| Deck builder scene | Cold cyan flats + green CTAs | MagitechTheme hierarchy |
| GameBoard overlays | Per-overlay navy flats | Shared Magitech panel helper |
| HudSkin gaps | TECH/VOID flat colors | `v2_magitech` chips |

---

## Do / don’t

**Do**

- Use chrome + cyan only for energy  
- Keep radius 8 on shared chrome  
- Route new popups through `GameDialog` once Magitech-reskinned  

**Don’t**

- Invent screen-local palettes  
- Use pink/magenta glow  
- Use playmat slate as dialog fill  
- Put circular rings on freeform icons (see playmat brief)
