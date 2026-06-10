# Blightsilver

A hidden-grid strategy card game built in **Godot 4**.

---

## Running the game

Open the project in Godot 4.x and press **Run** (F5), or launch the exported binary directly.

---

## Admin Console

Most authoring tools are accessed through the in-game **Admin Console** (the mailbox/envelope icon). Type `help` for a full command list. Key commands:

| Command | Opens |
|---------|-------|
| `tutorial_battle` | Tutorial Battle Builder |
| `map_editor` | Exploration Map Editor |
| `vn_editor` | Visual Novel Beat Editor |
| `card_editor` | Card Data Editor |
| `dungeon_builder` | Daily Dungeon Builder |
| `player_vs_ai` | Quick VS AI setup |
| `manage_fonts` | Font Manager |
| `card_e2e` | Card E2E Test Runner |
| `ai_vs_ai` | AI vs AI spectator mode |

---

## Tutorial Duel

The Tutorial Duel mode lets you design guided battle scenarios. A "mission" appears at the start of each player turn; the screen dims and a spotlight highlights exactly what to interact with.

### Quick start

1. In any scene, open the Admin Console and type `tutorial_battle`.
2. The **Tutorial Battle Builder** opens.
3. Configure decks, formations, and missions (see below).
4. Click **▶ START BATTLE** to launch.

---

### Tutorial Battle Builder

The builder is split into two panels.

#### Left panel — file management

| Control | Action |
|---------|--------|
| File list | Click a file to load it |
| **New** | Start a blank config |
| **Save** | Save current config to the filename in the text field |
| **Del** | Delete the selected file |
| Filename field | Type the filename (no `.json` extension needed) |
| **▶ START BATTLE** | Validate and launch the battle |
| **✕ Close** | Close the builder without launching |

Configs are stored in `res://data/tutorial_battles/*.json`.

#### Right panel — config editor

**Battle Settings**

| Field | Description |
|-------|-------------|
| Title | Display name for this tutorial |
| After missions | **End Immediately** — return to menu once all mission-turns are done. **Continue Normal Battle** — let the duel play out normally after missions end. |

**Player Deck & Formation / AI Deck & Formation**

Both sides have the same layout:

- **Characters / Traps / Tech** rows — click **+ Add** to open a searchable pick-list of all cards in the database. Click **Clear All** to empty that slot type.
- **Formation (5×5)** grid — click any cell to open a picker for placing a card from the configured deck. Cards placed here are forced to that cell when the battle starts. Click **Clear Cell** to remove a placement.

> Deck requirements: 8–12 characters, 4–6 traps, exactly 3 tech cards. The builder validates this before launching.

**Missions (by player turn)**

- Click **+ Add Turn** to add a new player-turn entry.
- Inside a turn, click **+ Mission** to add a mission.
- Missions execute **sequentially** in the order they appear. After all missions in a turn are complete, the player has free play for the rest of that turn.
- Use **Del Turn** / **✕** to remove turns or missions.
- Use **↑ ↓** arrows (inside the turn row) to reorder missions.

Each mission row has:

| Control | Description |
|---------|-------------|
| Type dropdown | The mission type (see table below) |
| Param fields | Inputs that depend on the type |
| Instruction field | Text shown in the cursor tooltip while the mission is active |
| **✕** button | Remove this mission |

---

### Mission types

| Type | What satisfies it | Param fields |
|------|-------------------|--------------|
| `attack` | Tap the target card on the grid → tap the ⚔ Attack icon in its sub-menu | **Card name** |
| `bluff` | Tap the target card → tap the 😐 Bluff icon in its sub-menu | **Card name** |
| `union_summon` | Tap the Union HUD button → tap the UNION button in the Union overlay | **Union name** (leave blank to accept any union) |
| `use_tech` | Tap the TECH stack chip → tap **USE** on the specified tech card | **Tech name** |
| `end_turn` | Tap the End Turn button | *(none)* |
| `options` | Tap the Options button | *(none)* |
| `tap_void_stack` | Tap the void/discard pile | **Side** (Player / Opponent) |
| `tap_tech` | Tap the TECH stack chip | **Tech name** (optional) |
| `tap_card` | Tap a specific card on the grid | **Card name**, **Side** |
| `tap_cell` | Tap a specific empty/occupied grid cell | **Row**, **Col**, **Side** |

> **Two-step missions** (`attack`, `bluff`, `union_summon`, `use_tech`): the spotlight starts on the first target, then automatically moves to the sub-action once the first tap is detected.

---

### Mission overlay behaviour

While a mission is active:

- The screen dims except for a **circular spotlight** (≈200% cursor size) around the target.
- A **yellow ▼ arrow** bounces above the spotlight.
- The **cursor tooltip** shows the instruction text you configured.
- All taps/clicks **outside** the spotlight are blocked — the player can only interact within the lit area.
- The **End Turn** button is blocked until the current mission is satisfied (unless End Turn itself is the mission).

When the mission is satisfied the overlay disappears instantly. If more missions remain in that turn, the next one activates after a brief pause. Once all missions are done, the player has free play.

---

### Auto-skip (impossible missions)

When a mission activates the system waits ~0.35 s for the board to settle, then checks whether the target is reachable:

| Mission | Skip condition |
|---------|---------------|
| `attack` / `bluff` | Target card not on player's grid |
| `attack` step 2 | Attack/Bluff icon not in the open sub-menu |
| `union_summon` | Union suggest button not visible |
| `use_tech` | Tech card not in hand, or USE button not present |
| `tap_tech` | Tech chip not visible/active |
| `end_turn` / `options` | Button not visible |
| `tap_void_stack` | Stack not visible |
| `tap_card` / `tap_cell` | Target node not found on the grid |

Skipped missions produce no visible effect — the next mission (or free play) activates automatically.

---

### JSON config reference

Tutorial configs are plain JSON stored in `res://data/tutorial_battles/`. You can edit them by hand or through the in-game builder.

```jsonc
{
  "title": "My Tutorial",

  // What happens after all mission-turns are exhausted
  "on_complete": "end_immediately",  // or "continue_normal"

  // Player deck — must pass DeckData.is_valid() (8-12 chars, 4-6 traps, 3 techs)
  "player_deck": {
    "characters": ["Church Guard", "Church Guard", ...],
    "traps":      ["Trap Hole", ...],
    "techs":      ["Radar", "Shield Wall", "Quick Draw"]
  },

  // Forced starting positions for the player (overrides saved formation)
  "player_formation": [
    { "card_name": "Church Guard", "row": 4, "col": 2 }
  ],

  // AI deck and forced formation (same structure)
  "ai_deck": { "characters": [...], "traps": [...], "techs": [...] },
  "ai_formation": [
    { "card_name": "Chaotic Wisp", "row": 0, "col": 2 }
  ],

  // Mission turns — keys are player-turn numbers (1 = player's first turn, ignoring AI turns)
  "turns": {
    "1": [
      {
        "type": "attack",
        "card_name": "Church Guard",
        "instruction": "Tap Church Guard, then tap the ⚔ icon to attack!"
      },
      {
        "type": "end_turn",
        "instruction": "Good — now end your turn."
      }
    ],
    "2": [
      {
        "type": "use_tech",
        "tech_name": "Radar",
        "instruction": "Tap the TECH stack, then tap USE on Radar."
      }
    ]
  }
}
```

**Row/Col conventions** — the grid is 5×5. Row 0 is the top of that player's half; row 4 is closest to the center line. Col 0 is the leftmost column, col 4 is rightmost.

**Side field** (`tap_void_stack`, `tap_card`, `tap_cell`) — `"player"` means the human player's grid/stack; `"opponent"` means the AI's.

---

### Example config

An example file is bundled at:

```
res://data/tutorial_battles/example_attack_tutorial.json
```

It demonstrates a 2-turn tutorial: turn 1 teaches attacking with Church Guard; turn 2 teaches using the Radar tech card then ending the turn.

---

### Architecture notes (for developers)

| File | Role |
|------|------|
| `autoload/TutorialBattleManager.gd` | Autoloaded state machine; drives mission lifecycle via async coroutines |
| `scripts/TutorialMissionOverlay.gd` | Visual dim + spotlight (shader) + bouncing arrow + tooltip + input blocker |
| `scripts/TutorialBattleBuilder.gd` | In-game editor UI |
| `assets/shaders/tutorial_dim.gdshader` | GLSL shader that draws the circular transparent cutout in the dim layer |
| `data/tutorial_battles/` | JSON config storage |

`TutorialBattleManager` is completely isolated — it only activates when `is_active` is true, which only happens after `prepare()` is called from the builder. All GameBoard hooks are guarded by `if TutorialBattleManager.is_active`, so they have zero effect on VS AI, Hot Seat, Campaign, Daily Dungeon, or E2E test battles.

---

## Battle illustrations

Side portraits shown during VS AI / campaign / exploration battles (configured in **VN Editor → BATTLE → Portrait P1 / P2**).

### How they are cropped on screen

`GameBoard` scales art to **720px tall** (× `portrait_p*_size`, default `1.0`) and shows only a strip beside the board:

| Side | Visible on screen | Off-screen bleed |
|------|-------------------|------------------|
| **P1 (left)** | Right ~**60%** of the art | Left ~40% |
| **P2 (right)** | Left ~**40%** of the art | Right ~60% |

P1 is **mirrored** (`flip_h`); P2 is not. Compose for this crop, not a full-body showcase.

### Quick checklist

1. **Canvas:** **832 × 1216** px (matches `profile_player_*_default.png` and most `battler_*.png` in `res://assets/textures/profile/battle_illustrations/`).
2. **Path:** use `battle_illustrations/` assets — avoid raw VN dialogue sprites (`vn_char_*.png`) unless they are already 832×1216 and composed for battle.
3. **P2 / enemy (right):** put **face + shoulders** in the **left third** of the PNG; character faces **left** (toward the board). The right side can bleed off-screen.
4. **P1 / player (left):** put the hero in the **right half** of the PNG (mirrored toward center); character faces **right** in the source file. The left side can bleed off-screen.
5. **Vertical:** feet near the **bottom** of the canvas; don’t place the face too high or it clips at the top.
6. **VN Editor tuning:** set **Portrait P1 / P2** on the `start_battle` beat. For bosses, start from `portrait_p2_offset_x: -160`, `portrait_p2_offset_y: 70` (see `ch1_s1_pre_DEMO.json`) and adjust until the face reads clearly. Use **Portrait size** `0.85–0.95` if the art crowds the grid.

**Visible width is narrow** (~200–300 px at size 1.0) — keep the face **large** in the inner-facing safe zone.
