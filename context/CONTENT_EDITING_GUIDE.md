# Blightsilver — Content Editing Guide

This guide explains how to manage campaign stages, visual novel scenes, and card data without needing to understand the full codebase. All changes are made in plain text files.

---

## Part 1 — Campaign Stages (Episodes)

**File:** `autoload/CampaignManager.gd`
**Section:** the `_define_nodes()` function (starts around line 52)

Each stage is one line that calls either `_battle()` or `_story()`. All 21 stages are listed here in map order.

---

### How to read a stage definition

A battle stage looks like this:

```gdscript
_battle("ch1_s1", 1, "The First Veil", "Library Chaos",
    Vector2(80, 150), ["ch1_s2"], 1, 500,
    "Mayu (Ghost Possessed)",
    "500 Credits + 1 Booster Pack",
    "res://campaign/scenes/ch1_s1_pre.json")
```

The arguments in order:

| Position | Example | Meaning |
|---|---|---|
| 1 | `"ch1_s1"` | Unique ID. Never change this once the game has save data. |
| 2 | `1` | Chapter number (1–5). Controls which band it appears in on the map. |
| 3 | `"The First Veil"` | Chapter name shown in the detail panel. |
| 4 | `"Library Chaos"` | Stage title shown on the map node and detail panel. |
| 5 | `Vector2(80, 150)` | Position on the campaign map canvas (1860×540). |
| 6 | `["ch1_s2"]` | List of stage IDs this stage connects to. Usually one ID. |
| 7 | `1` | Difficulty (1, 2, or 3). Controls AI deck strength. |
| 8 | `500` | Credits awarded on victory. |
| 9 | `"Mayu (Ghost Possessed)"` | Opponent name shown in the detail panel. |
| 10 | `"500 Credits + 1 Booster Pack"` | Reward text shown in the detail panel. |
| 11 | `"res://campaign/scenes/ch1_s1_pre.json"` | Path to the VN scene file played before battle. |

A story stage looks like this:

```gdscript
_story("final_soon", 5, "Final Chapter", "To Be Continued",
    Vector2(920, 268), [],
    "res://campaign/scenes/final_soon.json")
```

Arguments: ID, chapter, chapter name, title, position, connections, VN scene path.
Story stages grant no credits — they just play the VN and mark themselves complete.

---

### Create a new stage

**Step 1.** Choose a unique ID. Use the pattern `ch{chapter}_{type}{number}`, for example `ch2_s6` or `ch3_event1`.

**Step 2.** Decide where it sits on the map. The canvas is 1860 wide × 540 tall. Use a `Vector2(x, y)` that fits near related stages. Top row is around y=100–150. Bottom row is around y=390–430.

**Step 3.** Update connections. Find the stage that should lead **into** your new stage and add your new ID to its connections list. Then set your new stage's connections to the stage that should come **after** it.

**Step 4.** Add the line inside `_define_nodes()`. Copy an existing `_battle()` or `_story()` call and edit the values. Place it in the correct order (the list reads top-to-bottom, left-to-right in map order, but the actual order of lines doesn't affect gameplay — only the connection lists do).

**Step 5.** Create the VN scene file (see Part 2).

Example — adding a new battle after `ch1_s5`:

```gdscript
# Change ch1_s5 connections from ["ch2_s1"] to ["ch1_bonus"]
_battle("ch1_s5", 1, "The First Veil", "Return of the Shadows",
    Vector2(800, 150), ["ch1_bonus"], 2, 2000, ...)   # ← changed

# Add the new stage
_battle("ch1_bonus", 1, "The First Veil", "Bonus Fight",
    Vector2(900, 200), ["ch2_s1"], 2, 1500,
    "Mystery Enemy",
    "1500 Credits",
    "res://campaign/scenes/ch1_bonus_pre.json")
```

---

### Modify an existing stage

Find the stage by its ID in `_define_nodes()` and edit the values directly. Safe to change at any time:
- Title, chapter name, opponent name, reward description text
- Difficulty, credit reward
- VN scene file path
- Map position

**Avoid changing** the ID or connection list once players have save data — their progress is stored by ID.

---

### Remove a stage

**Step 1.** Find which stage has this stage's ID in its connections list. Remove the ID from that connections list, and replace it with the ID of the stage that comes *after* the one you're deleting. This keeps the chain intact.

**Step 2.** Delete the `_battle()` or `_story()` line for the stage you are removing.

**Step 3.** (Optional) Move the JSON file to `trash/` if you no longer need it.

> **Warning:** If any player's save has this stage marked as completed, their progress will be unaffected but the stage will no longer appear on the map. This is safe — it will not crash.

---

## Part 2 — Visual Novel Scenes

**Files:** `campaign/scenes/*.json`
**Asset folders:** `assets/textures/vn/backgrounds/` and `assets/textures/vn/characters/`

Each JSON file contains an array of "beats." One beat = one screen of the VN (one background state + one dialogue line). The player clicks (or presses Space) to advance to the next beat.

---

### Beat format

```json
{
  "background": "res://assets/textures/vn/backgrounds/library_night.png",
  "characters": [
    { "sprite": "res://assets/textures/vn/characters/nex_neutral.png", "position": "left" },
    { "sprite": "res://assets/textures/vn/characters/mayu_scared.png",  "position": "right" }
  ],
  "speaker": "Nex",
  "text": "Your eyes just went white.",
  "dim_others": true
}
```

**Field reference:**

| Field | Type | Meaning |
|---|---|---|
| `background` | string or `null` | Path to a full-screen background image. Use `null` or omit the field entirely to keep the previous background. |
| `characters` | array | Which character sprites to show and where. Replaces all current characters when present. Use `[]` (empty array) to clear all characters. Omit the field entirely to leave characters unchanged. |
| `speaker` | string | Name shown in the speaker nameplate. Use `""` (empty string) or omit for narration style (no nameplate). |
| `text` | string | The dialogue or narration text. |
| `dim_others` | boolean | If `true`, all characters except the ones listed in this beat's `characters` array are dimmed. Optional, defaults to `false`. |
| `wait` | number | Auto-advance to the next beat after this many seconds. Input is blocked during the wait — the player cannot click through. Optional. |
| `shake` | array or `"all"` | Shake character sprites. Pass an array of position names (e.g. `["left", "right"]`) or the string `"all"` to shake every visible character. The shake plays while the player reads — they can still click through. Optional. |
| `shake_magnitude` | number | How far characters move during a shake, in pixels. Default is `8`. Use larger values (e.g. `20`, `40`) for dramatic impacts. Only has effect when `shake` is also set. Optional. |
| `shake_screen` | boolean or number | Shake the entire screen. Use `true` for a default magnitude of 10px, or pass a number (e.g. `25`) to control the strength. Can be combined with `shake` to shake both characters and screen simultaneously. Optional. |
| `sfx` | string | Path to a sound file to play when this beat is shown (e.g. `"res://assets/audio/sfx/explosion.ogg"`). Fire-and-forget — does not block input. Supports `.ogg`, `.wav`, `.mp3`. Also accepted as `sound`. Optional. |
| `sfx_volume` | number | Volume for the sound effect as a percentage. `100` = normal, `200` = twice as loud, `0` = silent. Also accepted as `sound_volume`. Valid range: `0`–`200`. Optional, defaults to `100`. |
| `music` | string or `null` | Start a looping background music track (e.g. `"res://assets/audio/music/theme.ogg"`). The track loops until a later beat changes it or the scene ends. Set to `null` to stop music. If the same path is already playing, it is not restarted. Optional. |
| `music_fade_out` | number | Fade out the current track over this many seconds. Works standalone (no `music` field needed) to fade out whatever is playing. Also works alongside `music` when stopping or switching tracks. Optional. |
| `music_fade_in` | number | Fade the new track in over this many seconds. Default `0` (instant full volume). Only applies when `music` starts a new track. Optional. |
| `fade_out` | number | Fades the screen to a solid color over this many seconds, then blocks until complete. Happens **before** background and character updates — use this to hide a scene change. Optional. |
| `fade_in` | number | Fades the screen from a solid color back to visible over this many seconds, then blocks until complete. Happens **after** background and character updates — use this to reveal a new scene. Optional. |
| `fade_color` | string | HTML hex color for the fade overlay. Default `"#000000"` (black). Use `"#ffffff"` for a white flash. Applies to whichever of `fade_out` / `fade_in` is on the same beat. The color persists on the overlay until changed by a later beat. Optional. |
| `flash_color` | string | HTML hex color of the flash overlay. Default `"#ffffff"` (white). Required to trigger a flash (or use `flash_count`). Optional. |
| `flash_count` | number | How many times to flash. Default `1`. Setting this field alone (without `flash_color`) triggers a white flash. Optional. |
| `flash_duration` | number | Duration of one full flash cycle (fade in + fade out) in seconds. Default `0.2`. Optional. |
| `flash_delay` | number | Pause between each flash in seconds. Default `0.05`. Only relevant when `flash_count` > 1. Optional. |
| `flash_target` | string or array | What to flash. `"screen"` (default) flashes the full-screen overlay. `"all"` flashes every visible character. An array of position names (e.g. `["left", "right"]`) flashes only those slots. If the target slots are empty, falls back to screen. Optional. |

**Character entry fields:**

| Field | Type | Meaning |
|---|---|---|
| `sprite` | string | Path to the character sprite image. |
| `position` | string | Where to place the sprite. See valid values below. |
| `flip` | boolean | If `true`, the sprite is mirrored horizontally. Useful when you want a character who normally faces left to face right. Optional, defaults to `false`. |
| `crop_bottom` | number | Hides the bottom N% of the character image. For example, `20` hides the bottom 20% (feet/legs). The remaining image stays anchored to the dialog box. Valid range: `0`–`99`. Optional, defaults to `0`. |
| `scale` | number | Enlarges or shrinks the character by percentage. `100` is the default size, `150` is 50% larger, `75` is 25% smaller. The character stays bottom-anchored to the dialog box and centered on its slot. Compatible with `crop_bottom`. Valid range: `10`–`500`. Optional, defaults to `100`. |

**Valid position values:**

```
"far_left"   "left"   "center"   "right"   "far_right"
```

---

### Language translation (localisation)

`text` and `speaker` fields accept either a plain string **or** a dictionary of language codes. VNPlayer displays the string matching its `locale` property (default `"en"`). If the current locale key is not present, it falls back to the first language in the dictionary.

**Plain string (no translation needed):**
```json
{ "speaker": "Nex", "text": "Sorry!" }
```

**Localised:**
```json
{
  "speaker": { "en": "Nex", "th": "เน็กซ์" },
  "text": {
    "en": "Sorry! I'm so sorry!!",
    "th": "ขอโทษ! ขอโทษมากเลย!!"
  }
}
```

You can mix — beats without a dict just use the plain string regardless of locale.

**Setting the locale in code (before `play_scene`):**
```gdscript
vn_player.locale = "th"
vn_player.play_scene(path, callback)
```

Language codes are arbitrary strings — use whatever convention fits your project (`"en"`, `"th"`, `"ja"`, etc.).

---

### Fade transition between scenes

Use `fade_out` + `fade_in` across two beats to create a seamless scene transition. The screen goes to solid color, the new background/characters load invisibly, then the scene reveals.

```json
[
  { "fade_out": 0.6, "fade_color": "#ffffff" },
  {
    "background": "res://assets/textures/vn/backgrounds/new_bg.png",
    "characters": [],
    "fade_in": 0.6,
    "fade_color": "#ffffff",
    "text": "Later that day..."
  }
]
```

- `fade_out` blocks input until the screen is fully covered
- `fade_in` blocks input until the screen is fully revealed
- `fade_color` defaults to `"#000000"` (black); set on the `fade_out` beat — it persists automatically for the `fade_in`

---

### Ken Burns effect (slow background zoom/pan)

Add `bg_ken_burns` to any beat to slowly zoom or pan the background. The animation runs in the background — it does not block input and the player can click through while it plays. The effect continues across beats until a new background is set (which resets it automatically).

**Field reference:**

| Field | Type | Meaning |
|---|---|---|
| `zoom` | number | End scale of the background. `1.0` = no zoom, `1.05` = zoom in 5%, `1.1` = zoom in 10%. Keep between `1.0`–`1.15` to avoid visible bleed edges. Default `1.05`. |
| `pan_x` | number | Horizontal pan offset in pixels at the end of the animation. Negative = image moves left (shows more of the right side). Positive = image moves right (shows more of the left side). Default `0`. |
| `pan_y` | number | Vertical pan offset in pixels at the end of the animation. Negative = image moves up (shows more of the bottom). Positive = image moves down (shows more of the top). Default `0`. Note: this follows Godot's coordinate system where Y increases downward. |
| `duration` | number | How long the animation takes in seconds. Default `4.0`. |

**Examples:**

Gentle zoom-in while a character speaks (no pan):
```json
{
  "background": "res://assets/textures/vn/backgrounds/your_bg.png",
  "bg_ken_burns": { "zoom": 1.06, "duration": 6.0 },
  "speaker": "Kelly",
  "text": "Something is watching us."
}
```

Slow upward pan (camera drifts up):
```json
{
  "background": "res://assets/textures/vn/backgrounds/city_night.png",
  "bg_ken_burns": { "zoom": 1.08, "pan_y": -25, "duration": 8.0 },
  "text": "The city never sleeps."
}
```

Diagonal drift (zoom + pan together):
```json
{
  "bg_ken_burns": { "zoom": 1.1, "pan_x": -30, "pan_y": -20, "duration": 5.0 }
}
```

**Notes:**
- The effect resets automatically when a new `background` is set on any beat
- You can start a new `bg_ken_burns` on a later beat to change the motion while keeping the same background
- Zoom values above `1.15` risk showing the dark base layer at screen edges — test before shipping
- The animation eases in and out (smooth acceleration) using a sine curve

---

### Flash effect

Use `flash_color` (or `flash_count`) to trigger a quick brightness pulse. The flash blocks input while it runs, then releases.

**Full-screen white flash (e.g. magic burst, gunshot):**
```json
{ "flash_color": "#ffffff", "flash_duration": 0.15 }
```

**Repeating red screen flash (e.g. alarm, danger):**
```json
{ "flash_color": "#FF6B6B", "flash_count": 3, "flash_duration": 0.12, "flash_delay": 0.08 }
```

**Flash a specific character (e.g. they take a hit) — use an array even for one slot:**
```json
{ "flash_color": "#FF6B6B", "flash_target": ["right"], "flash_count": 2, "flash_duration": 0.1 }
```

**Flash all visible characters (e.g. magic affects everyone):**
```json
{ "flash_color": "#C89BFF", "flash_target": "all", "flash_duration": 0.3 }
```

**Combined with shake and sound:**
```json
{
  "flash_color": "#ffffff",
  "flash_count": 2,
  "flash_duration": 0.1,
  "shake_screen": 20,
  "sound": "res://assets/audio/sound_sledgehammer1.mp3"
}
```

- `flash_target` accepts `"screen"` (default), `"all"`, or an array of position names like `["left"]`, `["left", "right"]`
- If the target slots are empty (no visible characters), the flash falls back to screen mode
- Character flash preserves the slot's original modulate — dimmed characters stay dimmed after the flash

---

### Recommended text colors (BBCode)

The dialog box uses a dark navy background (`#05091F`) with near-white default text. The colors below are tuned to be readable and to complement the dark blue/silver theme without clashing with the blue UI borders.

| Purpose | Color | BBCode tag |
|---|---|---|
| Danger / Pain / Enemy | Desaturated red | `[color=#FF6B6B]text[/color]` |
| Warning / Caution | Warm amber | `[color=#FFB347]text[/color]` |
| System / Magic (matches UI accent) | Ice blue | `[color=#7EC8F4]text[/color]` |
| Positive / Heal / Good | Mint green | `[color=#6DFFA0]text[/color]` |
| Mysterious / Dark power | Soft violet | `[color=#C89BFF]text[/color]` |
| Gold / Credits / Important | Pale gold | `[color=#FFE566]text[/color]` |
| Whisper / Inner thought / Quiet | Muted steel blue | `[color=#8BA8C8]text[/color]` |
| Emphasis / Silver highlight | Bright silver-white | `[color=#E8F4FF]text[/color]` |

**Usage examples:**

```json
{ "speaker": "Nex", "text": "My head... [color=#FF6B6B]it's splitting apart[/color]..." }
```
```json
{ "text": "[color=#FFE566]★ +500 Credits[/color] have been added to your account." }
```
```json
{ "speaker": "Nex", "text": "[color=#8BA8C8](I shouldn't trust her...)[/color]" }
```

> Avoid fully-saturated colors like `#FF0000` or `#00FF00` — they look harsh on dark navy and clash with the UI palette. Use the muted versions above instead.

---

### Recommended image sizes

| Asset type | Recommended size | Format |
|---|---|---|
| Background | 1600 × 900 px | PNG or JPG |
| Character sprite | ~320 × 560 px | PNG with transparent background |

---

### Create a new VN scene

**Step 1.** Create a new file in `campaign/scenes/`. Name it after the stage:
- For a battle's pre-battle briefing: `{stage_id}_pre.json`
- For a story node: `{stage_id}.json`

**Step 2.** Write an array of beats:

```json
[
  {
    "background": null,
    "characters": [],
    "speaker": "",
    "text": "The city is silent. Something is wrong."
  },
  {
    "speaker": "Kelly",
    "text": "Stay close. Do not use your cards until I say."
  }
]
```

**Step 3.** Point the stage to this file. In `CampaignManager.gd`, find the stage's `_battle()` or `_story()` call and set the last argument to the file path:

```gdscript
"res://campaign/scenes/ch1_s1_pre.json"
```

---

### Add a background to an existing scene

Open the scene's JSON file. On the beat where you want the background to first appear, add:

```json
"background": "res://assets/textures/vn/backgrounds/your_image.png"
```

The background stays on screen for all subsequent beats until another beat changes it. You do not need to repeat it on every beat.

---

### Add character sprites to an existing scene

On the beat where the character should appear, add a `characters` field:

```json
"characters": [
  { "sprite": "res://assets/textures/vn/characters/nex_neutral.png", "position": "left" }
]
```

On any beat where you want to **change** who is on screen, set a new `characters` array. On beats where you want to **keep the same characters**, simply omit the `characters` field.

To **clear all characters** from the screen (e.g. for a pure narration beat):

```json
"characters": []
```

---

### Modify existing dialogue

Open the JSON file and edit the `"text"` or `"speaker"` values of any beat directly.

---

### Add, remove, or reorder beats

- **Add a beat:** insert a new `{ ... }` object into the array at the correct position.
- **Remove a beat:** delete the `{ ... }` object. Make sure to remove the trailing comma from the previous beat if needed.
- **Reorder beats:** cut and paste the objects within the array.

The array must remain valid JSON. Check for missing commas between objects, or extra commas after the last object.

---

### Test a scene without launching the full game

A dedicated test runner lets you preview any JSON file instantly without going through the main menu or campaign map.

**Step 1.** Open `scripts/VNTest.gd` and set `TEST_PATH` to the file you want to test:

```gdscript
const TEST_PATH := "res://campaign/scenes/test_scene.json"
```

**Step 2.** In the Godot editor, open `scenes/vn_test.tscn` (double-click it in the FileSystem panel).

**Step 3.** Press **F6** (Run Current Scene). The VN plays immediately.

**Step 4.** When the scene ends, a green "Scene finished" message appears. Press **Escape** to close the window.

> You can keep `vn_test.tscn` open in a tab and just edit the JSON file, then press F6 again to re-run — no need to touch any GDScript between iterations.

---

### Clear a scene (remove all VN from a stage)

In `CampaignManager.gd`, find the stage and set `vn_scene` to an empty string:

```gdscript
""
```

The game will skip the VN entirely and go straight to the battle (or mark the story stage complete immediately).

---

## Part 3 — Card Data

**File:** `autoload/CardDatabase.gd`

There are three card types, each defined in their own function:
- **Character cards** — `_load_characters()` (around line 16)
- **Trap cards** — `_load_traps()` (around line 160)
- **Tech cards** — `_load_tech_cards()` (around line 240)

Each card is one entry in the `defs` array inside those functions.

---

### Character card format

```gdscript
["Card Name", CharacterData.Affinity.ARCANE, 80, 0, 800,
    CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
    {"affinity": CharacterData.Affinity.NATURE, "bonus": 30},
    "+30 ATK vs Nature Affinity"],
```

Fields in order:

| # | Example | Meaning |
|---|---|---|
| 1 | `"Card Name"` | Card name. Must be unique. Used as the key everywhere. |
| 2 | `CharacterData.Affinity.ARCANE` | Affinity. See valid values below. |
| 3 | `80` | Base ATK. |
| 4 | `0` | Base DEF. |
| 5 | `800` | Crystal cost. |
| 6 | `CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY` | Ability type. Use `CharacterData.AbilityType.NONE` for no ability. |
| 7 | `{"affinity": ..., "bonus": 30}` | Ability parameters. Contents depend on the ability type. Use `{}` if no ability. |
| 8 | `"+30 ATK vs Nature Affinity"` | Human-readable ability description shown in the UI. |

**Valid affinities:**
```
DIVINE   CHAOS   NATURE   ARCANE   COSMIC   BIO   ANIMA
```

### Field scope (`ability_params.field_scope`)

When an ability counts or checks cards **on the field**, interpret the card text like this:

| Card text wording | `field_scope` | Grid scanned |
|---|---|---|
| **"on the field"** with **no** possessive (no *its side*, *your field*, *foe's field*, *owner's field*, *their own field*, etc.) | `"all"` | **Both players** (P0 + P1) |
| **"its side"**, **"your field"**, **"their own field"**, **"on your side"**, etc. | `"owner"` (default) | **Rule owner's grid only** |

Implementation: `BattleResolver._field_players()` — used by field-count abilities (`BOOST_PER_*_ON_FIELD`, `DEF_BONUS_IF_AFFINITY_ON_FIELD`, `ATK_BONUS_IF_AFFINITY_ON_FIELD`, etc.).

**Examples (current data):**

```gdscript
# Joan — "exposed Divine unit is on the field"
{"affinity": CharacterData.Affinity.DIVINE, "def": 35, "field_scope": "all"}

# Hammer Shark — "+10 ATK per shark card on the field"
{"card_name_contains": "shark", "atk_bonus": 10, "def_bonus": 0, "field_scope": "all"}

# Death Knight — "+5 ATK per Chaos unit on their side"  (no field_scope → owner)
{"atk_bonus": 5, "def_bonus": 0, "affinity": CharacterData.Affinity.CHAOS}

# Balthier — Divine on the field, bonus capped at 100 per stat
{"atk_bonus": 50, "def_bonus": 50, "affinity": CharacterData.Affinity.DIVINE,
 "field_scope": "all", "bonus_cap": 100}
```

Omit `field_scope` for owner-only abilities. Only add `"field_scope": "all"` when the published ability text uses bare **"on the field"**.

**Valid ability types** (see `resources/CharacterData.gd` for the full list):
```
NONE
ATK_BONUS_VS_AFFINITY          {"affinity": ..., "bonus": N}
DEF_BONUS_VS_AFFINITY          {"affinity": ..., "bonus": N}
IMMUNE_ZERO_COST_TRAPS         {}
IMMUNE_TO_TRAPS                {}
IMMUNE_TO_TECH_CARDS           {}
IMMUNE_TO_TECH_DESTRUCTION     {}
CRYSTAL_GAIN_ON_DEFEND         {"amount": N}
BOOST_PER_ANIMA_ON_FIELD       {"atk_bonus": N, "def_bonus": N}
PERM_BOOST_END_OF_TURN         {"atk": N, "def": N}
ATK_BONUS_IF_DICE_HIGH         {"threshold": N, "bonus": N}
ATK_BOOST_VS_REVEALED          {"bonus": N}
DEFEND_DRAIN_ATTACKER          {"drain_amount": N}
ONE_USE_DEF_BOOST              {"bonus": N}
REDIRECT_DESTRUCTION_TO_ALLY   {"affinity": ...}
REVEAL_ADJACENT_AFTER_ATTACK   {}
DOUBLE_TECH_EFFECT             {}
DESTROYED_IF_BATTLES_DIVINE    {}
MUTAGEN_ATK_BOOST_VS_AFFINITIES  {"bonus": N, "affinities": [...]}
MUTAGEN_DESTROY_ATTACKER       {}
MUTAGEN_IMMEDIATE_ATTACK       {}
```

**Valid rarities** (add as an optional 9th field if you need to override — default is COMMON):
`CharacterData.Rarity.COMMON / UNCOMMON / RARE / LEGENDARY / EXOTIC`

To set rarity, add a 9th entry and then set it after creation. However, the current factory loop does not read a 9th field — to set rarity you must add a dedicated line after the loop, or ask Claude to add rarity support to the factory. For now, rarity is `COMMON` for all cards unless manually changed in code.

---

### Trap card format

```gdscript
["Card Name", 400, TrapData.TrapEffectType.DESTROY_ATTACKER,
    {"requires_faceup_defender": true},
    "Human-readable effect description."],
```

Fields in order:

| # | Example | Meaning |
|---|---|---|
| 1 | `"Card Name"` | Unique card name. |
| 2 | `400` | Crystal cost. Use `0` for free traps. |
| 3 | `TrapData.TrapEffectType.DESTROY_ATTACKER` | Effect type. |
| 4 | `{"requires_faceup_defender": true}` | Effect parameters. Use `{}` if none needed. |
| 5 | `"Destroy the attacking character."` | Description shown in the UI. |

**Valid trap effect types** (see `resources/TrapData.gd` for the full list):
```
NULLIFY_ATTACK
NULLIFY_ATTACK_ATK_DEBUFF          {"atk_debuff": N}
NULLIFY_ATTACK_REVEAL_ADJACENT     {"directions": [...], "lock_revealed": true}
NULLIFY_ATTACK_CHOICE              {"crystal_loss": N}
NULLIFY_BLOCK_ADJACENT             {"directions": [...]}
REVEAL_DEFENDING_CHOICE            {}
ATTACKER_DISCARD_OR_END_TURN       {}
COPY_ATTACKER_EFFECT               {}
DESTROY_ATTACKER                   {}
DESTROY_ATTACKER_CHOICE_DESTROY    {"requires_faceup_defender": true}
HYPNOTIZE_ATTACKER                 {}
LOCK_ATTACKER_REMAINING_ATTACKS    {}
DRAIN_ATTACKER_CRYSTALS            {"amount": N}
SWAP_ARMORED_NATURE                {}
PERMANENT_ATK_DEBUFF               {"amount": N}
NULLIFY_ATTACKER_EFFECT            {}
FORCE_FRIENDLY_FIRE                {}
```

---

### Tech card format

```gdscript
["Card Name", 500, TechCardData.TechEffectType.PERM_ATK_BOOST_ONE,
    {"atk": 50}, "",
    "+50 ATK permanently for 1 face-up character."],
```

Fields in order:

| # | Example | Meaning |
|---|---|---|
| 1 | `"Card Name"` | Unique card name. |
| 2 | `500` | Crystal cost. |
| 3 | `TechCardData.TechEffectType.PERM_ATK_BOOST_ONE` | Effect type. |
| 4 | `{"atk": 50}` | Effect parameters. Use `{}` if none needed. |
| 5 | `""` | Required prior card name (for chain cards like Double Spy). Use `""` for none. |
| 6 | `"Description."` | Description shown in the UI. |

**Valid tech effect types** (see `resources/TechCardData.gd` for the full list):
```
REVEAL_OPPONENT_SQUARE             {"count": N}
REVEAL_OPPONENT_SQUARE_CHAIN       {"count": N}       + set field 5 to prior card name
REVEAL_OPPONENT_SQUARE_RISKY       {"count": N, "cost_per_card": N}
OPPONENT_REVEALS_SQUARE            {}
OPPONENT_REVEALS_OR_GAINS          {"crystal_reward": N}
BOTH_SKIP_TURN                     {}
BOTH_LOCK_CHOSEN_MONSTER           {}
ADD_MUTAGEN_FLAG                   {}
DIVINE_PROTECTION                  {}
DESTROY_ALL_REVEALED_OPPONENT      {}
DESTROY_ROW_OR_COLUMN              {}
REVEAL_ALL_OWN_CHARACTERS          {"count": N}  # e.g. Great Diplomacy count=5
PERM_BOOST_ALL_FACEUP              {"atk": N, "def": N}
PERM_ATK_BOOST_ONE                 {"atk": N}
TEMP_ATK_BOOST_ATTACK_NOW          {"atk": N}
TEMP_DEF_BOOST_ALL                 {"def": N}
PERM_DEF_BOOST_ONE                 {"def": N}
OPPONENT_NEXT_DEFENDER_DESTROYED   {}
DESTROY_FACEUP_CARD                {}
DESTROY_FACEUP_NO_CRYSTAL_LOSS     {}
MULTI_ATTACK_ONE                   {}
REVEAL_OWN_AND_OPPONENT_REVEALS    {}
MOVE_BUFFS_BETWEEN_CHARACTERS      {}
DESTROY_OWN_BASE_ZERO_OPPONENT     {}
CLONE_CHARACTER_AS_TOKEN           {}
REVIVE_CHARACTER_FULL              {}
REVIVE_CHARACTER_NO_ATK            {}
VIEW_OPPONENT_TECH                 {}
FORCE_SHIELD_ONE_CARD              {}
```

---

### Card ability text — writing rules

These rules apply to the **human-readable ability string** in card data (column **Ability** in `context/card_data.xlsx`, field 8 in `CardDatabase.gd` defs, and Union **Partial / Full Ability** columns).

**Priority:** as short as possible while keeping correct English and clarity for **both players** (owner and opponent reading the same card).

Refined copies with before/after columns live in `context/card_data_refine_*.xlsx` (sheet **Ability Text Rules** + **Old Ability** / **Comment** columns). Regenerate with `python3 tools/refine_card_data_xlsx.py`. Master source for refinement is **`card_data.xlsx`**.

#### Terminology

| Use | Avoid | Notes |
|-----|-------|-------|
| **Exposed** | face-up, lowercase exposed | Same as code `face_up`; card text always says Exposed |
| **face-down** | — | Hidden state; keep lowercase |
| **cell** | square, slot | Grid squares |
| **unit** | card (for characters) | Use **card** only when traps, Tech, or dead ends are included |
| **Reckoning** | in battle, when battling | Keep this jargon |
| **Trapper** | trap owner | Trapper = trap owner |
| **owner**, **this player**, **foe**, **attacker** | **You**, **Your** | Never You/Your — confuses the opponent reader |
| **Heads:** / **Tails:** | if head, Head:, head(s) | Coin results |
| **Flip 3 coins** | Flip 3 coin | Plural |
| **500 Crystals** | Crystal (standalone amount) | Plural when stating an amount |
| **500 Crystal cost**, **no Crystal cost** | Crystals (when paying cost) | Singular **Crystal** only in cost phrasing |
| **Venom flag**, **Mutagen flag**, **Princess flag** | Venom Flag, ALL CAPS | Sentence case for flags |
| **0-cost traps** | 0 cost traps | Hyphenated |
| **Tech** | lowercase tech | When meaning the card type |
| **Immune to Tech.** / **Immune to traps.** | long “unaffected by…” | Prefer short immunity lines |

#### Stats, shorthand, and symbols

Prefer **compact symbols** over spelled-out math and long phrases.

| Use | Avoid | Example |
|-----|-------|---------|
| **ATK&DEF** | ATK and DEF, ATK/DEF | `+20 ATK&DEF vs Nature` |
| **≥** / **≤** | or more, or less, at least, at most | `cost ≥800`, `≤1000 Crystals` |
| **=** | equal to, becomes 0 | `ATK&DEF=0`, `DEF=0` |
| **= # Heads** | equal to number of heads | Horn Face attack-again effect |
| **= ½** | equal to half of | Succubus-style buffs |
| **Summoned:** | Once Union, Upon union, On Union: | Union summon triggers |

Other matchups and grammar:

- **+50 ATK vs Chaos** — drop redundant **Affinity**.
- **both players**, **foe chooses**, **attacker has**, **owner may** — correct agreement.
- **per Head** — not “per each head(s)”.

#### Structure

| Pattern | Example |
|---------|---------|
| One-shot | **Once:** … |
| Battle | **In Reckoning:** … |
| Duration | **This turn:** … / **Until foe's turn ends:** … |
| End trigger | **End of turn:** … |

#### Game rules reflected in text

- **Flags on face-down units:** allowed; applying the flag **permanently Exposes** the unit (not a peek).
- **Plant-29:** `Start of owner's turn: Flip a coin. Head: put Venom Flag on 1 exposed ally or foe card. Tail: put Mutagen Flag on any of your unit.`
- **Death Cobra:** `End of turn: Choose 1 foe unit. Put Venom flag on it.` (includes face-down; Exposes on apply).

#### Union cards

- **Partial Ability:** may keep **`???` teasers** in UI.
- **Full Ability:** complete text; **one ability per card** unless design explicitly combines them (do not merge unrelated effects — e.g. Capnomancer = revive Pyromancer only, no coin flip).
- **Union summon trigger:** **Summoned:** (not “Once Union”).

#### Avoid

- **You** / **Your**
- Ambiguous **their** without **owner** / **foe** / **this player**
- Broken grammar: “both player”, “attacker have”, “the this player's”
- Mixing **card** and **unit** when you mean characters only

---

### Add a new card

Find the correct function (`_load_characters`, `_load_traps`, or `_load_tech_cards`) and add a new entry anywhere inside the `defs` array. Copy an existing entry as a template and change the values.

Example — adding a new Character card:

```gdscript
["Shadow Fox", CharacterData.Affinity.CHAOS, 55, 35, 750,
    CharacterData.AbilityType.ATK_BOOST_VS_REVEALED,
    {"bonus": 25},
    "+25 ATK when attacking a revealed card."],
```

> After adding the card, it will immediately be available in the Deck Builder and Shop packs.

---

### Add card artwork

Name the image file using the card name in snake_case (spaces become underscores, apostrophes removed, lowercase). Place it in the correct folder:

| Card type | Folder |
|---|---|
| Character | `assets/textures/cards/characters/` |
| Trap | `assets/textures/cards/traps/` |
| Tech | `assets/textures/cards/tech/` |

Examples:
- `"Shadow Fox"` → `shadow_fox.png`
- `"Angel Gatekeeper"` → `angel_gatekeeper.png`
- `"Arcane Nova"` → `arcane_nova.png`

The game discovers artwork automatically by matching the filename. No extra configuration needed.

---

### Modify an existing card

Find the card's entry in `_load_characters()`, `_load_traps()`, or `_load_tech_cards()` by searching for its name string. Edit the values in that line.

Safe to change at any time: stats, cost, ability, description text.

**Avoid renaming a card** that is already present in any player's saved deck or collection — the saved deck stores card names as strings, and renaming will cause those copies to be unresolvable. If you must rename, also update any saved data or clear saves.

---

### Remove a card

Delete the card's entry from the `defs` array inside the appropriate `_load_*` function.

> If the card is present in any player's saved deck, those deck slots will silently become empty. This is safe — it will not crash — but the player's deck will be incomplete until they edit it.

---

## Part 4 — Shop Packs

**File:** `autoload/ShopManager.gd`
**Section:** the `PACKS` constant (starts around line 15)

Each pack is one dictionary inside the `PACKS` array. There are currently four packs: Starter, Fighters, Trapmaster, and Premium.

---

### How to read a pack definition

```gdscript
{
    "id":          "fighters",
    "name":        "Fighters Pack",
    "price":       900,
    "description": "Three Characters.\nExpand your battle roster with new fighters.",
    "slots": [
        {"type": "character", "count": 3},
    ],
    "accent": Color(1.0, 0.38, 0.25),
},
```

**Field reference:**

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Unique key used internally. Never change this once mailbox rewards reference it. |
| `name` | string | Display name shown in the shop UI, and stored on each pulled card as its provenance. |
| `price` | int | Cost in credits. |
| `description` | string | Flavour text shown on the pack's shop card. Use `\n` for line breaks. |
| `slots` | array | The card draw rules. Each slot has a `type` (`"character"`, `"trap"`, or `"tech"`) and a `count`. Every slot draws `count` random cards of that type. |
| `accent` | Color | Highlight colour used in the shop UI for this pack's border and glow. |

---

### Add a new pack

**Step 1.** Open `autoload/ShopManager.gd` and find the `PACKS` constant.

**Step 2.** Add a new dictionary entry inside the array. Copy an existing pack as a template.

```gdscript
{
    "id":          "chaos_pack",
    "name":        "Chaos Pack",
    "price":       1200,
    "description": "Two Traps and two Techs.\nUnleash pure disorder.",
    "slots": [
        {"type": "trap", "count": 2},
        {"type": "tech", "count": 2},
    ],
    "accent": Color(0.9, 0.2, 0.7),
},
```

**Step 3.** Make sure the `id` is unique — check that no other pack already uses the same string.

The pack will appear in the shop immediately after saving. No other files need to be changed.

---

### Edit an existing pack

Find the pack by its `id` in the `PACKS` array and change any fields directly.

**Safe to change at any time:**
- `name`, `description`, `price`, `accent`
- `slots` — adding, removing, or changing slot types/counts

**Avoid changing the `id`** if any mailbox reward already references this pack by name (`draw_pack_free` looks up packs by `name`, not `id`; so also avoid changing `name` if mailbox rewards reference it by name).

**Example — raise the Starter Pack price from 500 to 750:**
```gdscript
"price": 750,
```

**Example — change Fighters Pack to give 2 characters and 1 tech instead of 3 characters:**
```gdscript
"slots": [
    {"type": "character", "count": 2},
    {"type": "tech",      "count": 1},
],
```

---

### Remove a pack

**Step 1.** Delete the entire `{ ... }` dictionary block for that pack from the `PACKS` array. Make sure the trailing comma on the previous entry is also removed if it was the last item.

**Step 2.** Check `autoload/MailboxManager.gd` for any mail items that reward this pack by name (search for the pack's `name` string). Update or remove those mail rewards if needed, otherwise the free draw will fall back to a generic 1-of-each draw.

> Removing a pack will not crash for players who have already purchased it — their collection is stored separately and is unaffected.

---

### Change what card types a pack can draw

Packs draw randomly from the full card pool for each type. There is currently no per-pack card exclusion — all character cards are in the same pool, all traps in one pool, all techs in one pool. If you want a pack to only pull specific cards, that would require a code change to `_draw_cards()` in `ShopManager.gd`.

---

### Change the starting credits for new players

**File:** `autoload/Collection.gd`

Search for the default credits value (currently `2000`). Change it to set how many credits a brand-new player starts with.

> This only affects new players. Existing saves already have their credits stored and will not be affected.

---

## Part 5 — Removing White Backgrounds from Character Sprites

Character images exported from AI art tools often come with a white background. The game requires transparent PNGs so the character composites correctly over the scene background. A script using AI-based background removal is included — it handles complex edges like hair cleanly.

**Script location:** `tools/remove_bg.py`

---

### First-time setup (do this once)

**Step 1.** Make sure Python 3 is installed. Open a terminal and run:

```
python3 --version
```

If Python is not found, download it from python.org.

**Step 2.** Install the required libraries:

```
pip3 install "rembg[cpu]"
```

This downloads the AI model (~176MB) on first use. Subsequent runs are fast.

---

### Remove background from all character sprites at once

Open a terminal, navigate to the game folder, and run:

```
python3 tools/remove_bg.py
```

This processes every `.png` file in `assets/textures/vn/characters/` and overwrites each one in-place with a transparent PNG.

---

### Remove background from a single file

```
python3 tools/remove_bg.py assets/textures/vn/characters/char_nex_disguised.png
```

Replace the filename with the file you want to process.

---

### After running the script

Open (or refocus) the Godot editor. Godot will detect the changed files and re-import them automatically — you do not need to do anything manually.

---

### Notes

- The originals are overwritten. If you need to keep the original, make a copy before running the script.
- The AI model is downloaded to `~/.u2net/` the first time only.
- The script works for any PNG — you can also use it on card artwork or background images if needed.

---

## Part 6 — Admin Console

The Admin Console is a developer tool for testing rewards, triggering events, and exporting card assets without going through normal gameplay flows.

---

### How to open the Admin Console

1. Launch the game and go to the **Main Menu**.
2. Press **Ctrl + Shift + A**.
3. A dark overlay panel appears with a text input at the bottom.
4. Type a command and press **Enter** (or click **Send**).
5. Press **Escape** (or the × button) to close.

> The Admin Console is only accessible from the Main Menu screen.

---

### Commands

#### `help`
Lists all available commands.

```
help
```

---

#### `send <subject> | <body>`
Sends a custom mail item to the player's inbox. Use `|` to separate the subject from the body.

```
send Test Mail | This is a test message body.
```

---

#### `send_coins <amount> [subject]`
Awards the player a number of credits via mail. The subject is optional.

```
send_coins 5000
send_coins 1000 Weekend Bonus
```

---

#### `send_card <card_name> [subject]`
Sends a specific card to the player's mailbox. The card must exist in the database.

```
send_card Pyromancer
send_card Angel Gatekeeper Card Reward
```

---

#### `send_booster [pack_name]`
Sends a booster pack mail reward. Pack name is optional — omitting it sends a "Standard Pack". Use the exact pack name as defined in `ShopManager.gd`.

```
send_booster
send_booster Fighters Pack
send_booster Premium Pack
```

---

#### `send_stage_bonus <card_name> [stage_label]`
Sends a stage-clear bonus card reward. The stage label is optional and controls the mail subject line.

```
send_stage_bonus Pyromancer
send_stage_bonus Ironclad Sentinel Chapter 1 Clear
```

---

#### `list`
Displays all mail items in the inbox, showing claimed/unclaimed status, sender, and subject.

```
list
```

---

#### `clear_claimed`
Deletes all mail items that have already been claimed.

```
clear_claimed
```

---

#### `clear_all`
Deletes every mail item (claimed and unclaimed). Resets the mail ID counter.

```
clear_all
```

---

#### `tts on|off`
Enables or disables the text-to-speech narrator. Typing `tts` alone shows the current state.

```
tts on
tts off
tts
```

---

#### `export_card <card_name> <character|trap|tech>`
Renders a single card using the full card info layout and saves it as a PNG to `assets/textures/cards/full_cards/`. The card type must be `character`, `trap`, or `tech`. Multi-word card names are supported.

```
export_card Pyromancer character
export_card Angel Gatekeeper character
export_card Mirror Trap trap
export_card Spy Scout tech
```

The output file is named using the card's snake_case name (e.g. `angel_gatekeeper.png`). Progress is shown in the Godot Output log.

---

#### `export_all_cards`
Exports every card in the database (all characters, traps, and tech cards) as PNG files to `assets/textures/cards/full_cards/`. Cards are exported one per frame to avoid stalling the game. Progress is printed to the Godot Output log.

```
export_all_cards
```

Only one export job can run at a time. If an export is already in progress, the command returns an error message.

Before and after exporting, the command asks the **Card Import Regen** editor plugin to call Godot's `reimport_files()` on source art (`characters/`, `traps/`, `tech/`, `union/`) and `full_cards/`, regenerating `.import` sidecars automatically. This only works when running from the Godot editor (F5 play); exported builds skip reimport and log a warning.

---

#### `map_editor`
Opens the **Campaign Map Node Editor** — a full-screen visual tool for freely repositioning stage nodes on the campaign map without touching any code.

```
map_editor
```

---

## Part 7 — Campaign Map Node Editor

The Campaign Map Node Editor lets you drag and drop every stage node to any position on the 1860×540 map canvas. Positions are saved to a JSON file and automatically loaded by the game on startup — no code editing required.

---

### How to open

1. Launch the game and go to the **Main Menu**.
2. Press **Ctrl + Shift + A** to open the Admin Console.
3. Type `map_editor` and press **Enter**.
4. The editor opens as a full-screen overlay on top of whatever scene is active.

---

### Editor layout

| Area | Description |
|---|---|
| Header bar | Title, current node position readout, and action buttons |
| Canvas (scrollable) | 1860×540 area showing all stage nodes and connection lines |
| Node tile | Shows the node's ID (top), type icon (center), and stage title (bottom) |

**Node type colors:**
- Orange border → Battle node
- Blue border → Story node
- Yellow border → Reward node

**Connection lines** (blue) show which node unlocks which. They update live as you drag.

---

### Repositioning a node

Click and drag any node tile to a new position on the canvas. The header bar updates in real time showing the node ID and its new `(x, y)` coordinates.

The canvas is scrollable — use the scrollbar or trackpad to reach nodes near the right side.

---

### Saving positions

Click **SAVE** in the header. Positions are written to:

```
user://campaign_node_positions.json
```

The game reads this file every time it starts. Saved positions override the hardcoded `Vector2(...)` values in `CampaignManager.gd` — you do not need to edit any code.

> **Godot's user:// path on macOS:** `~/Library/Application Support/Godot/app_userdata/Blightsilver/`
> On Windows: `%APPDATA%\Godot\app_userdata\Blightsilver\`

---

### Exporting positions to code

Click **EXPORT TO LOG**. Every node's current position is printed to the **Godot Output panel** in a copy-pasteable format:

```
[CampaignMapEditor] ── Exported positions ──
    "ch0_s1": Vector2(80, 268),  # Flickering Midnight
    "ch1_s1": Vector2(80, 150),  # Library Chaos
    ...
```

Use this to bake final positions back into `CampaignManager.gd` as hardcoded values if you want to ship without the JSON override file.

---

### Resetting to defaults

Click **RESET** to snap all nodes back to the positions defined in `CampaignManager.gd`. This does **not** overwrite the save file — click Save afterward if you want to persist the reset.

---

### Workflow for adjusting the map

1. Open `map_editor` from Admin Console.
2. Drag nodes into the layout you want.
3. Check the position readout in the header to get precise coordinates.
4. Click **SAVE**.
5. Close the editor — changes take effect immediately in the campaign map (no restart needed if you re-open the campaign modal).

---

## Quick Reference

| Task | File |
|---|---|
| Add / edit / remove a campaign stage | `autoload/CampaignManager.gd` → `_define_nodes()` |
| Edit dialogue or beat order | `campaign/scenes/{stage_id}_pre.json` or `{stage_id}.json` |
| Add a background image | `assets/textures/vn/backgrounds/` |
| Add a character sprite | `assets/textures/vn/characters/` |
| Add / edit a Character card | `autoload/CardDatabase.gd` → `_load_characters()` |
| Add / edit a Trap card | `autoload/CardDatabase.gd` → `_load_traps()` |
| Add / edit a Tech card | `autoload/CardDatabase.gd` → `_load_tech_cards()` |
| Add card artwork | `assets/textures/cards/characters/`, `traps/`, or `tech/` |
| Add / edit / remove a shop pack | `autoload/ShopManager.gd` → `PACKS` constant |
| Change starting credits | `autoload/Collection.gd` → default credits value |
| Remove white background from sprites | Run `python3 tools/remove_bg.py` in terminal |
| Open Admin Console | Main Menu → Ctrl+Shift+A |
| Export a single card as PNG | Admin Console → `export_card <name> <type>` |
| Export all cards as PNG | Admin Console → `export_all_cards` |
| Reposition campaign map nodes visually | Admin Console → `map_editor` |

---

## Author’s note: Multi-protagonist

### Defaults

- **Nex** starts unlocked (not Limited).
- **Mayu** and **Kelly** start locked until a VN beat unlocks them.

### Unlocking a hero (VN Editor → MULTI-PROTAGONIST)

1. Set **Unlock protagonist** to `mayu` or `kelly`.
2. Optionally pick a **Starter vault** entry (`mayu_arcane` / `kelly_nature` by default).
3. On that beat, the game unlocks the hero, creates their **Limited** deck in reserved gallery slot **11** (Mayu) or **12** (Kelly), equips it, and grants collection cards.

**Why Limited?** So players who already opened strong packs as Nex cannot immediately slap that OP deck onto Mayu/Kelly and skip the “new to Vellum” narrative. While Limited, that hero’s capsule cannot reassign decks, and the reserved deck cannot be equipped on anyone else.

### Limited caps

Use **Set Limited caps for** + absolute **units / traps / techs** counts (e.g. after a story “unseal” moment). Players may add/replace/remove only within those counts. Use **Clear Limited** when the hero is free to use any deck.

### Switching heroes

- **Silent switch protagonist** — no UI; sets global current hero (must be unlocked). Battles use that hero’s equipped deck.
- **Show protagonist select** — full-bleed picker (also used in exploration when the graph lists multiple playable heroes).

### Exploration

- Graph field **Playable** (comma-separated, max 3): e.g. `nex, mayu`.
- Conditions: `protagonist_equals` / `protagonist_not_equals` (key or value = `nex` / `mayu` / `kelly`).

### Deck builder (player)

- **Switch Deck** — 4×3 gallery (sort by creation date).
- Capsule bar above Save — equip the open deck to a hero (confirm dialog). Disabled while that hero is Limited.
- **★** — mark a featured card for gallery previews (yellow highlight on the trunk).

### Starter vault admin

`manage_starter_deck_vault` — inspect/reload `data/starter_deck_vault.json` (edit JSON in the project for card lists).
