# Blightsilver — Dev Problem-Solving Journal

Record of non-obvious discoveries, bugs found + fixed, and design decisions made during development.
Each entry: **date → problem → finding/solution**.

---

## 2026-04-27 — Initial Prototype Build

### Private method called across nodes
**Problem:** `GameBoard.gd` called `turn_manager._end_turn(player)` — a private (underscore-prefixed) method on `TurnManager`.
**Finding:** GDScript 4 allows calling underscore methods externally but it's bad practice and can break with tooling/linting. Added a public wrapper `end_turn(player)` on `TurnManager` and updated the call site.

### HUD as separate scene vs inline
**Problem:** Initially designed `HUD.gd` as a standalone scene (`hud.tscn`) expecting `$P1Panel`, `$MessageLog`, etc. as direct children. But in `game_board.tscn` the HUD is inline under a `$HUD` Control node, and `MessageLog` lives in `$MainLayout/CenterPanel/MessageLog`.
**Finding:** Keeping HUD logic in a separate script that uses `@onready` paths causes fragile path mismatches when nodes are embedded. Merged all HUD update logic into `GameBoard.gd` using full absolute paths from the scene root. `hud.tscn` kept as a standalone reference but not used in-game.

### SetupPhase @onready path mismatch
**Problem:** `SetupPhase.gd` referenced `$GridContainer` and `$CardList` directly, but in `setup_phase.tscn` they sit under `$MainLayout/GridContainer` and `$MainLayout/CardList`.
**Finding:** Always verify `@onready` paths match the actual scene tree before running. Fixed paths to `$MainLayout/GridContainer` and `$MainLayout/CardList`.

### Card artwork: TextureRect stretch mode
**Problem:** Card illustrations are portrait (e.g. ~832×1216) but the artwork display area in the card is landscape-ish (110×60px). Naive stretch would distort the image.
**Finding:** `stretch_mode = 6` (COVER in Godot 4 enum) fills the rect and crops edges rather than squashing. Combined with `expand_mode = 1`, the art always fills the slot cleanly regardless of source ratio.

### Artwork auto-discovery convention
**Problem:** Defining `artwork_path` on every card resource manually is tedious and error-prone.
**Finding:** Card.gd auto-discovers artwork by converting the card name to `snake_case` and checking `assets/textures/cards/{subfolder}/{snake_name}.{ext}` for `.png`, `.jpg`, `.jpeg`, `.webp` in order. `artwork_path` on the resource only needed for overrides. No code change needed to add art for a new card — just drop the file.

### await on non-async function
**Problem:** `perform_attack` in `TurnManager` uses `await _handle_trap_effect(...)` but `_handle_trap_effect` doesn't itself `await` anything — it's synchronous.
**Finding:** In GDScript 4, `await` on a non-coroutine function resolves immediately on the next frame. This is valid and harmless here since trap resolution is event-driven via signals anyway. No change needed, but noted for future refactors.

---

## 2026-04-27 — Type inference errors on nested Array access

**Problem:** Godot reported "Cannot infer the type of X variable because the value doesn't have a set type" on variables assigned from `grids[player][r][c]` and from iterating an untyped `dirs` array.

**Finding:** GDScript 4 does not support deeply typed nested arrays (`Array[Array[CardInstance]]`), so `grids` must stay as plain `Array`. Any variable inferred with `:=` from indexing an untyped Array becomes `Variant` — Godot strict mode rejects this. Fix: annotate the variable explicitly at the point of use (e.g. `var card: CardInstance = grids[p][r][c]`). Same applies to for-loop iteration variables over untyped arrays (e.g. `for d: Vector2i in dirs`).

## 2026-04-27 — Untyped card variables spread across multiple files

**Problem:** Same "Cannot infer type" error kept appearing in different files (`BattleResolver.gd`, `TurnManager.gd`, `GameBoard.gd`, `AIPlayer.gd`) because `GameState.get_card()` returns `CardInstance` but Godot couldn't always propagate that through cross-autoload calls, and direct `grids[p][r][c]` indexing always returns untyped `Variant`.

**Finding:** Even when a function declares `-> CardInstance`, callers using `:=` may still fail type inference when the function is on an autoload accessed via global name. Safest rule: **always use explicit type annotation** (`var card: GameState.CardInstance = ...`) for any variable sourced from an autoload method or untyped array — never rely on `:=` inference across autoload boundaries. Used `sed` to batch-fix all occurrences across files at once.

## 2026-04-28 — Figma UI Apply Pass

### VBoxContainer cannot have a background StyleBoxFlat

**Problem:** `deck_builder.tscn` had `LeftPanel` and `RightPanel` as `VBoxContainer` nodes. Figma required dark panel backgrounds with colored borders on both panels.

**Finding:** `VBoxContainer` does not accept `theme_override_styles/panel` — only `Panel`/`PanelContainer` nodes support StyleBoxFlat backgrounds. Attempting to set `panel` on a VBoxContainer is silently ignored in Godot 4.

**Solution:** Changed both nodes to `Panel`, added a child `VBoxContainer` named `Inner` inside each, moved all functional children under `Inner`. Then did a find-replace in `DeckBuilder.gd`:
- `$MainLayout/LeftPanel/` → `$MainLayout/LeftPanel/Inner/`
- `$MainLayout/RightPanel/` → `$MainLayout/RightPanel/Inner/`

---

### Label nodes cannot have a background

**Problem:** Main menu needed a deck status panel (dark bg + border) around a label. `Label` has no background property.

**Solution:** Wrapped `DeckStatusLabel` in a `Panel` node (`DeckStatusBg`) with a StyleBoxFlat. Updated `@onready` path in `MainMenu.gd` from `$DeckStatusLabel` to `$DeckStatusBg/DeckStatusLabel`.

---

### Figma absolute pixel coordinates → Godot anchor+offset

**Problem:** Figma specifies buttons at exact pixel positions on a 1280×720 canvas; Godot layout uses normalized anchors + pixel offsets.

**Finding:** For horizontally centered elements, set `anchor_left = anchor_right = 0.5`. Then `offset_left = -halfWidth`, `offset_right = halfWidth` gives a fixed-width centered button. Vertical positions map 1:1 from Figma Y to `offset_top`/`offset_bottom`.

---

### load_steps must stay in sync with resource block count

**Problem:** `load_steps` in `.tscn` header must equal the count of `[ext_resource]` + `[sub_resource]` blocks + 1. Godot throws a load error if it's wrong.

**Finding:** Adding `shadow_color`/`shadow_size` properties to an existing `StyleBoxFlat` block does **not** change the count — those are just properties on the existing sub-resource. Only adding a new `[sub_resource]` block increments the count. Always recount after adding new resource blocks.

---

## 2026-05-06 — Title Screen & Splash Screen Visual Pass

### Drifting cards "thrown" at start
**Problem:** Cards spawned mid-screen and flew into position, looking like someone just launched them.
**Solution:** Run 30 s of physics via `_tick(0.2)` called 150× in `_ready()` before the first draw. Cards appear already mid-drift.

### Jellyfish float instead of leaf drift
**Problem:** Simple sine-wave position produced bouncy, symmetric motion.
**Solution:** Model *velocity* (not position) with 3 incommensurate sine frequencies summed. Add angular-velocity model with exponential drag for rotation. Add gust modulation on top.

### Larger (closer) cards not always on top
**Problem:** Draw order followed array insertion order, not depth order.
**Solution:** Sort `_cards` by `card_scale` in `_draw()` before iterating — smaller scale (farther) drawn first.

### Cards disappear mid-screen at Z boundary
**Problem:** When `card_scale` hit `Z_MIN` while still on screen, the card popped invisible.
**Solution:** Teleport the card off-screen to the left whenever a Z boundary is hit so the re-entry is never visible.

### GDScript type inference error on flip_cos (DriftingCards.gd)
**Problem:** `var w := CARD_W * s * abs(flip_cos)` failed because `flip_cos` came from a cast expression.
**Solution:** Declare explicitly `var flip_cos: float = cos(...)` and use `absf()`.

---

## 2026-05-06 — Splash Screen: Studio Logo Shadow & Glow

### Shadow makes thin logo look blurry
**Problem:** A scaled/blurred duplicate of the logo texture caused thin strokes to bleed into each other, making the logo unreadable.
**Solution:** Use a separate `TextureRect` (LogoShadow) behind the logo, driven by `silhouette.gdshader`. The shader reads only the texture alpha and outputs a flat `glow_color` — producing a clean solid silhouette with no bleed.

### Shadow shows original texture colours instead of white
**Problem:** `modulate = Color(1,1,1,1)` is default — it renders the original texture as-is.
**Solution:** `silhouette.gdshader` discards all RGB and outputs the `glow_color` uniform (white) for every pixel that has any alpha.

### Shader discards inherited parent modulate
**Problem:** Shaders writing `COLOR = vec4(...)` directly discard the inherited `modulate.a` from parent nodes, breaking tween-based fade sequences.
**Solution:** Read `float inherited_alpha = COLOR.a` *before* overwriting `COLOR`, then multiply it into the final alpha: `COLOR = vec4(rgb, a * inherited_alpha)`.

### Outer lantern glow invisible / too dim
**Problem:** Adding `center * 40.0` to `total_weight` massively diluted the normalised glow for pixels outside the logo (where `center = 0`), making the halo nearly invisible.
**Solution:** Remove center from the ring glow calculation entirely. Compute `glow_alpha = clamp((ring_glow / ring_total_weight) * glow_boost, 0.0, 1.0)`, then `max(glow_alpha, center)` keeps the silhouette solid independently.

### Logo fades out with a snap instead of smoothly
**Problem:** `logo_outline.gdshader` set `COLOR = texel` for inside-logo pixels, throwing away inherited `modulate.a`. The logo stayed fully opaque through the tween and snapped invisible at the end.
**Solution:** Change to `COLOR = vec4(texel.rgb, texel.a * COLOR.a)` — multiply inherited fade alpha so the logo transitions smoothly.

## 2026-05-06 — TTS, Card Interaction, and Frame Integration

### RegEx.sub() does not accept a Callable
**Problem:** Tried to use `RegEx.sub(text, callable, true)` to replace `+N`/`-N` patterns with "increase N"/"decrease N" dynamically. Got parser error: "argument 2 should be String but is Callable."
**Finding:** GDScript's `RegEx.sub()` only accepts a literal replacement String, not a function. There is no callable variant.
**Solution:** Use `rx.search_all(text)` to get all matches, then manually build the output string by iterating over matches, inserting replacements between the unmatched spans.

---

### DeckBuilder card thumbnail not tappable
**Problem:** Tapping the card art or background in the preview area did not trigger the full-card modal. Only the very edge of the preview container responded.
**Finding:** Child nodes (TextureRect, ColorRect) inside a Control have `mouse_filter = MOUSE_FILTER_STOP` by default. They silently consumed all mouse events before they could bubble up to the parent `gui_input` connection.
**Solution:** After connecting `preview_card_area.gui_input`, iterate over all Control children and set `mouse_filter = Control.MOUSE_FILTER_PASS`.

---

### CardGallery crash: nil node on `visible` assignment
**Problem:** `entry["node"].visible = show` threw "Invalid assignment on Nil" when the gallery was rebuilt while old nodes were queue_free()'d but still referenced in `_tiles`.
**Finding:** `queue_free()` is deferred — nodes are not immediately destroyed. If any code path reads `_tiles` between the free call and the next frame, the stored node reference is invalid.
**Solution:** Guard both `_apply_filter()` and `_update_stats()` with `is_instance_valid(entry["node"])` before accessing any property.

---

### Card.gd @onready vars null when called before scene tree entry
**Problem:** CardGallery calls `card.set_card_data(inst, ...)` immediately after `CARD_SCENE.instantiate()`, before the card is added to the scene tree. `set_card_data` called `_refresh_display()`, which accessed `@onready` vars that were all null, causing a crash.
**Finding:** `@onready` variables are populated when `_ready()` fires, which only happens after the node enters the scene tree. Calling any function that uses them before `add_child()` always fails.
**Solution:** In `set_card_data()`, check `is_inside_tree()` before calling `_refresh_display()`. Since `_ready()` already calls `_refresh_display()`, the data is correctly applied once the node enters the tree.

---

### Vellum card frame: layered rendering approach
**Problem:** A card frame image needs artwork to show through the illustration window while the top/bottom info strips remain opaque.
**Finding:** Use a transparent PNG frame (`vellum_card_frame_transparent.png`) as the top-most layer (`FrameRect`, `mouse_filter=PASS`). Artwork (`ArtworkRect`) sits beneath it and shows through the transparent window. Text labels are positioned to sit over the dark strips — name + cost in the top strip (y≈1–12), stats + ability in the bottom strip (y≈120–149), at card size 110×150.
**Solution:** Set `FrameRect.texture = VELLUM_FRAME` in face-up show functions instead of `null`. Use `VELLUM_BACK` (the full opaque frame PNG) for face-down cards, replacing the old FaceDownOverlay. Layout offsets derived from the frame image's proportions: ~8% top strip, ~71% illustration window, ~21% bottom strip.

## 2026-05-09 — Attack Flow, Card Context Menu, and Input Propagation

### Card flip animation not via middle axis
**Problem:** `play_reveal_animation()` tweened X-scale from 0→1 on the card Control, but the pivot defaulted to top-left (0,0), so the card appeared to grow from its left edge instead of flipping in place.
**Finding:** Godot 4 Control nodes default `pivot_offset` to `Vector2.ZERO`. Scale tweens collapse/expand relative to that point. `_play_peek_flip()` already set `pivot_offset = size * 0.5` — the same fix was missing from `play_reveal_animation()`.
**Solution:** Add `pivot_offset = size * 0.5` immediately before the tween in `play_reveal_animation()`.

---

### Context menu required double-tap to open
**Problem:** Tapping a card opened the context menu, but a second tap was needed to interact with it. Tapping a different card while the menu was open required first dismissing the old menu.
**Finding:** `_card_context_panel` had a full-screen `ColorRect` backdrop with `mouse_filter = MOUSE_FILTER_STOP`. This intercepted every card click as a dismiss event, closing the menu in the same frame it opened. Any click on a second card was first consumed by the backdrop, so the new menu only opened on the *next* tap.
**Solution:** Remove the backdrop ColorRect entirely. Set `_card_context_panel.mouse_filter = MOUSE_FILTER_IGNORE` so clicks fall through to card nodes beneath. Clicks on empty space reach `_unhandled_input`, which handles dismiss via `_hide_card_context()`.

---

### Context menu never appeared (mouse)
**Problem:** After removing the backdrop, clicking a card still produced no context menu.
**Finding:** `Card._gui_input()` emitted `card_clicked` but did not call `accept_event()`. The mouse button event continued propagating to `_unhandled_input`, which called `_hide_card_context()` — cancelling the menu in the same frame it was shown.
**Rule:** In Godot 4, `_gui_input` consuming an event must explicitly call `accept_event()`. Without it, the event reaches `_unhandled_input` even after a `MOUSE_FILTER_STOP` control has processed it.
**Solution:** Call `accept_event()` after `card_clicked.emit()` in both the mouse and touch branches of `Card._gui_input()`.

---

### Context menu never appeared (touch)
**Problem:** On touch devices, tapping a card produced no context menu even after the mouse fix.
**Finding:** The `InputEventScreenTouch` branch in `Card._gui_input()` called `_on_mouse_entered()` instead of emitting `card_clicked`. Touch events were being silently swallowed into hover logic.
**Solution:** Change touch handler to emit `card_clicked` and call `accept_event()`, identical to the mouse path.

---

### No context menu on first turn — three root causes
**Problem:** On the very first turn, tapping own cards showed no context menu and cards appeared greyed out.

**Root cause 1 — `get_node()` crash risk:**
`_show_card_context()` used `_card_context_panel.get_node("ContextPopup")` at runtime to find the popup. If the node name didn't match (or `_card_context_panel` hadn't fully settled), the result was null. Any subsequent `popup.position = ...` call crashed before `visible = true` was reached — the panel silently never appeared.
**Solution:** Store the popup as a typed member variable (`_card_context_popup: Panel`) in `_build_card_context_panel()` and reference it directly everywhere instead of using `get_node()`.

**Root cause 2 — `queue_free()` stale count:**
`_show_card_context()` used `queue_free()` to remove old buttons before building new ones. `queue_free()` is deferred — nodes stay in the tree until end of frame. `get_child_count()` then overcounted, producing a wrong popup height calculation and the popup being positioned off-screen.
**Solution:** Use `free()` (immediate) instead of `queue_free()` for old buttons. Compute button count explicitly as `int(can_attack) + int(can_info)` instead of reading `get_child_count()`.

**Root cause 3 — null crash in `_toggle_reveal_preview()`:**
`_toggle_reveal_preview()` accessed a `Button` variable (`btn`) without a null guard. If the reveal button node hadn't been created yet (early in setup), the null dereference crashed the function before `set_preview_revealed()` was called on any card nodes. This left all cards visually face-down (greyed out), and since `_show_card_context()` requires the card node to be in a visible state to position the popup correctly, the menu silently failed.
**Solution:** Add `if btn:` guard before `btn.text = ...` in `_toggle_reveal_preview()`.

---

### `face_up` incorrectly required for attacking
**Problem:** Characters couldn't be attacked or selected as attackers, even after setup. The ATTACK option never appeared in the context menu.
**Finding:** `can_player_attack()` in `GameState.gd`, `perform_attack()` in `TurnManager.gd`, `_highlight_attackable_chars()` in `GameBoard.gd`, and `can_attack` in `_show_card_context()` all checked `card.face_up == true`. But by design, characters start face-down and are *revealed* when they attack — `face_up` should be an *outcome* of attacking, not a prerequisite.
**Solution:** Remove `card.face_up` from all four attack-eligibility checks. Cards are eligible to attack as soon as they're placed — their face-up status is set by `reveal_card()` inside `perform_attack()`.

---

### Two-step attack confirmation with blink tween
**Design:** Rather than executing attacks immediately on target selection, the flow became: tap attacker → tap target → confirmation panel appears with ATTACK / CANCEL buttons. The target card blinks red during this state.
**Implementation:** A looping `create_tween().set_loops()` pings the target card node's `modulate` between `Color(1.8, 0.4, 0.4, 1.0)` and `Color(1.0, 1.0, 1.0, 1.0)`. The tween is killed and modulate reset in both `_confirm_attack()` and `_cancel_confirm_attack()`.
**State tracking:** Added `CONFIRMING_ATTACK` to `SelectionState` enum. Member vars `_confirm_target_pos` and `_confirm_target_player` hold the pending target during this state.

## 2026-05-09 — HOT_SEAT Cards Greyed Out / Context Menu Disabled Buttons

### HOT_SEAT: all cards go face-down after every attack
**Problem:** In HOT_SEAT mode, after each attack resolved, the current player's cards went dark (face-down appearance) mid-turn. Cards would briefly go dark and the "pass the device" handoff screen would appear — even though it was the same player continuing their turn.
**Finding:** `TurnManager.perform_attack()` ends with `GameState.set_phase(MODE_SELECT)` after every attack. `_on_phase_changed(MODE_SELECT)` unconditionally called `_reset_reveal_previews()` (hides all cards) and then showed the HOT_SEAT handoff screen — regardless of whether the player actually changed. This caused repeated "your turn" handoffs within a single player's turn.
**Solution:** Track `_handoff_last_player` and `_handoff_last_turn`. Only call `_reset_reveal_previews()` and show the handoff when `current_player` or `turn_number` actually changed. Same-player mid-turn MODE_SELECT returns skip the handoff and go directly to `_enter_mode_select()`.

---

### Context menu: trap cards showed menu, character cards showed nothing
**Problem:** Tapping a trap card opened the context menu correctly (INFO button visible). Tapping a character card produced no visible context menu at all.
**Finding (first hypothesis — wrong):** Suspected the click-through issue — popup appears under the mouse cursor, mouse-up fires the top button immediately, executing `_hide_card_context()` before the user sees the menu. Added `btn.disabled = true` + `btn.set_deferred("disabled", false)` to prevent this.
**Finding (actual root cause):** `set_deferred("disabled", false)` is unreliable on freshly-instantiated nodes that haven't completed a layout pass. The deferred setter silently failed, leaving buttons permanently `disabled = true` — appearing grey and unresponsive. Character cards show both ATTACK and INFO buttons; trap cards show only INFO. All buttons were grey/disabled, but the effect was most noticeable on character cards because ATTACK (the first button, and the reason the user tapped the card) was always disabled.
**Rule:** `set_deferred` on newly-added child nodes can fail silently before their first idle tick. Do not use `set_deferred` as a same-frame input guard for freshly-created nodes.
**Solution:** Remove `disabled = true` / `set_deferred` entirely. The popup always appears to the SIDE of the tapped card (`cpos.x + card_width + 6` or mirrored to the left), never under the tap point. There is no click-through risk, so no disable guard is needed.

---

### Context menu re-implementation: persistent recycled VBox → fresh node per open
**Problem:** The original context menu used a persistent `Control → Panel → VBoxContainer` structure. Buttons were cleared via `free()` (not `queue_free()`) and the popup was repositioned each open. This caused several compounding bugs: stale child counts, timing issues with freed nodes, and `get_node()` returning null for the popup.
**Solution:** Replaced with a fresh `Panel` node created per `_show_card_context()` call and `queue_free()`'d on `_hide_card_context()`. No persistent child container — every open creates a brand-new node tree. `is_instance_valid()` guards the free call. Callbacks capture card name/type and position as local snapshots before `_hide_card_context()` can reset the member vars to `-1`.

---

## 2026-05-09 — HOT_SEAT Character Cards Completely Unresponsive to Clicks

### Character cards don't respond to clicks — HighlightBorder Panel eating input
**Problem:** In HOT_SEAT battle phase, tapping character cards produced zero response — no context menu, no log output, nothing. Trap cards in the same grid opened the context menu fine. Trap cards are NOT highlighted; character cards ARE highlighted (they pass `_highlight_attackable_chars()` check). Suggested causes explored: `set_locked` state, berserk flag, `attacked_this_turn`, wrong `current_player` index — all were clear.
**Debugging method:** Added diagnostic `print()` calls inside `_gui_input()` indirectly via `_on_card_node_clicked()` and `_show_card_context()`. Trap card clicks logged correctly. Character card clicks produced **zero log output at all** — meaning `card_clicked` signal never emitted, meaning `_gui_input` on the Card node was never called.
**Finding:** `HighlightBorder` is a full-rect `Panel` child of the Card node. `Panel` nodes default to `mouse_filter = MOUSE_FILTER_STOP` (value 0) in Godot 4. When `set_highlighted(true)` makes `HighlightBorder` visible, it covers the entire card and silently intercepts every mouse click. The parent Card node's `_gui_input` is never reached. Trap cards are never highlighted so their border stays hidden — clicks pass through to the parent normally. `SelectionBorder` had the same latent bug.
**Rule:** Any full-rect child Panel/Control that is purely cosmetic (borders, overlays, indicators) must explicitly set `mouse_filter = 2` (`MOUSE_FILTER_IGNORE`) in the scene file. Godot 4's default `MOUSE_FILTER_STOP` on Panel will silently block all input to parent nodes.
**Solution:** Added `mouse_filter = 2` to both `HighlightBorder` and `SelectionBorder` nodes in `card.tscn`. The visual highlight still renders; clicks now pass through to the Card node.

## 2026-05-17 — SQLite Integration (godot-sqlite addon)

### godot-sqlite: source release vs binary release
**Problem:** Downloaded the addon from GitHub and placed it in `addons/godot-sqlite/`. Got `Could not find type "SQLite"` parse error. The `bin/` folder only contained a `binaries_here.txt` placeholder and empty `.framework` folders.
**Finding:** The GitHub repo has two kinds of releases: "Source code" zips (config files only, no `.dylib`) and a proper release zip with compiled binaries. The source zip looks complete but the `bin/` folder is intentionally empty — binaries must be downloaded separately or built from source.
**Solution:** Built from source using `scons platform=macos arch=arm64 target=template_debug/release` from the cloned repo. Required: Xcode CLT + `brew install scons`. Output binaries go into `demo/addons/godot-sqlite/bin/` (not the repo root `addons/`).

### godot-sqlite: `SQLite` type annotation causes parse error when binary missing
**Problem:** `var _db: SQLite = null` caused "Could not find type 'SQLite'" even with the plugin enabled in project.godot, because the GDExtension binary wasn't loading.
**Finding:** GDScript validates type annotations at parse time. If the GDExtension binary fails to load (missing, wrong platform, empty framework), the class is never registered and any static reference to `SQLite` fails at parse time — before the script can even run.
**Solution:** Use `var _db: Variant = null` and replace `SQLite.new()` with `ClassDB.instantiate("SQLite")`, guarded by `ClassDB.class_exists("SQLite")`. This lets the script always parse cleanly and fail gracefully at runtime with a clear error message.

### godot-sqlite: `_is_open` must be set before PRAGMA queries
**Problem:** `DatabaseManager._open()` ran `_query("PRAGMA journal_mode = WAL")` before setting `_is_open = true`. `_query()` checks `_is_open` as a guard and returned early, causing `push_error` spam on every run.
**Solution:** Move `_is_open = true` to immediately after `_db.open_db()` succeeds, before any PRAGMA calls.

### godot-sqlite: `.db` extension is appended automatically
**Finding:** The godot-sqlite addon appends `.db` to the path automatically. Set `_db.path = "user://blightsilver"` (no extension) — the file on disk will be `blightsilver.db`. Setting `"user://blightsilver.db"` creates `blightsilver.db.db`.

### Save data location (macOS)
**Finding:** Godot user data (`save_data.json`, `blightsilver.db`) lives at:
`~/Library/Application Support/Godot/app_userdata/Blightsilver/`
This is outside the repo and is machine-local. Never commit save files to git. To move save data between machines, manually copy both files to the same path on the target machine.

---

## 2026-05-17 — AI Bug: Reveal Cards (Radar, Spy, etc.) Get Stuck

### AI targets dead_end cells with reveal tech, game hangs
**Problem:** When the AI played a reveal tech card (Radar/Spy/Double Spy), the game sometimes got stuck — the reveal sequence never completed.
**Finding:** `_random_unrevealed_opponent()` in `AIPlayer.gd` filtered for `not card.face_up` but did NOT exclude `dead_end` cells. Dead_end cells are placed face-down during setup (they're empty grid slots), so they passed the filter. But `_handle_tech_target()` in `GameBoard.gd` rejects dead_end cells with an early `return` without decrementing `_tech_reveals_remaining` or calling `_finish_tech_action()` — leaving the reveal sequence hung.
**Solution:** Add `and card.card_type != "dead_end"` to the filter in `_random_unrevealed_opponent()`. This applies to all reveal-type cards since they all share this function.
**Affected cards:** Radar, Spy, Double Spy, Corrupted Spy (any card using `REVEAL_OPPONENT_SQUARE` / `REVEAL_OPPONENT_SQUARE_CHAIN` effect type).

---

## 2026-05-17 — PackOpeningOverlay: Skippable Parameter

### Added `skippable` flag to PackOpeningOverlay
**Design:** Added `skippable: bool = true` parameter to `PackOpeningOverlay.open()`. When `false`, `_input()` ignores all click/Space input, forcing the player to watch the full animation (including the 3.5s hold phase).
**Usage:** `PackOpeningOverlay.open(parent, img, c1, c2, c3, false)` — e.g. for story-critical pack reveals in VN sequences.
**Default:** `true` — all existing callers (ShopMenu, admin command) are unaffected.

<!-- New entries go above this line, newest first -->
