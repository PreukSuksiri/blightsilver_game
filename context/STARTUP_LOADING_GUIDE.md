# Startup Loading Guide

Use this guide when changing the **splash screen**, **deferred autoload bootstrap**, **DriftingCards prewarm**, or **main-menu entry** after load.

**Rule:** Loading UI must stay responsive; heavy work must be **frame-sliced** or **threaded**; scene handoff must not leave a black `FadeOverlay` or hang on `await node.ready` after `add_child()`.

---

## Source of truth

| Item | Location |
|------|----------|
| Splash scene | `scenes/splash_screen.tscn` |
| Splash orchestration | `scripts/SplashScreen.gd` |
| Coin animation | `scripts/SplashCoinFlip.gd`, `assets/shaders/splash_coin_flip.gdshader` |
| DriftingCards prewarm | `scripts/DriftingCards.gd` (`run_prewarm_async`, static `_prewarm_cache`) |
| Deferred DB bootstrap | `autoload/CardDatabase.gd`, `autoload/UnionDatabase.gd`, `autoload/SaveManager.gd` |
| Main menu fade | `scenes/main_menu.tscn` → `FadeOverlay` (starts **opaque black**), `scripts/MainMenu.gd` |
| Splash entry flag | `autoload/GameState.gd` → `entered_main_menu_from_splash` |
| Timestamp debug log | `scripts/StartupLoadDebug.gd` — filter Godot Output with **`StartupLoad`** |

Main scene: `project.godot` → `run/main_scene="res://scenes/splash_screen.tscn"`

---

## Correct startup flow (current)

```
Splash visible (bg + Now Loading + GPU coin)
  ├─ parallel: SaveManager.bootstrap_step()     (one phase per frame)
  ├─ parallel: threaded load main_menu.tscn
  └─ parallel: DriftingCards prewarm host       (_prewarm_only=true, hidden, no draw)
       └─ waits for CardDatabase bootstrap, then scans card paths with frame yields

All three gates true
  → stop coin
  → 1s fade out (splash FadeOverlay → black)
  → GameState.entered_main_menu_from_splash = true
  → change_scene_to_packed(main_menu)

Main menu
  → _enter_tree: FadeOverlay held at black
  → 1s fade in (FadeOverlay alpha → 0)
  → DriftingCards._ready: consume prewarm cache (instant; no rescan)
  → set_process(true) for title animation
```

---

## Problem-solving journey (what broke and why)

### 1. Loading happened before splash was visible

**Symptom:** Black screen, then main menu; no real loading UI.

**Cause:** `CardDatabase`, `UnionDatabase`, and `SaveManager.load_data()` ran synchronously in autoload `_ready()`.

**Fix:** Empty autoload `_ready()`; splash owns `bootstrap_step()` one phase per frame.

---

### 2. Coin frozen / laggy during load

**Symptom:** Coin only updates when frames happen; stutters during heavy scan.

**Cause:** `_process()` + texture swap on main thread while card scan blocks frames.

**Fix:** GPU shader coin (`TIME` uniform in `splash_coin_flip.gdshader`). **Do not** use GDScript type syntax in shaders (`float c: float` is invalid — use `float c = ...`).

**Principle:** Prefer GPU/time-based UI animation for loading indicators; slice CPU work with `await get_tree().process_frame` (scan yields every 2 cards, not 8).

---

### 3. Drifting cards flashed on splash

**Symptom:** Brief card drift on loading screen.

**Cause:** Prewarm helper was a normal `DriftingCards` node; `_ready()` ran full `_initialize_sync()` and drew cards.

**Fix:** `_prewarm_only` flag — skip init/draw/process in `_ready()`; `visible = false` on helper.

---

### 4. Infinite loading (bootstrap never finished)

**Symptom:** Coin spins forever; logs show `bootstrap=false` while `prewarm=true`.

**Cause:** Race — prewarm called `CardDatabase.bootstrap()` while splash stepped `CardDatabase.bootstrap_step()`. CardDatabase finished via full `bootstrap()`, but `UnionDatabase` stayed on step 0 (only advances when `bootstrap_step()` returns true).

**Fix:**
- `UnionDatabase` step 0: if `CardDatabase.is_bootstrapped()`, advance immediately.
- Prewarm: **wait** for `CardDatabase.is_bootstrapped()` — never call `CardDatabase.bootstrap()` from prewarm.

**Principle:** One owner for phased bootstrap (splash). Other systems **wait**, do not shortcut with full `bootstrap()`.

---

### 5. Black screen after load

**Symptom:** Loading completes; screen goes black (sometimes loading text still visible).

**Causes (multiple):**
- `main_menu.tscn` `FadeOverlay` defaults to `Color(0,0,0,1)`.
- Godot `_ready` order: **children before parent** — `MainMenu._ready` (clears fade) runs **after** child nodes.
- Broken scene swap: `add_child(menu)` + `await menu.ready` — if `ready` already fired during `add_child()`, **await never resumes** (splash stuck, menu underneath with black overlay).

**Fix:**
- Clear fade in `MainMenu._enter_tree()` when `GameState.entered_main_menu_from_splash`.
- Use `change_scene_to_packed()` — do not overlay splash + menu as root siblings.
- Hide splash `LoadingIndicator` before scene change.

---

## Principles (do not forget)

### Bootstrap ownership

| Do | Don't |
|----|--------|
| Splash calls `SaveManager.bootstrap_step()` once per frame | Call `CardDatabase.bootstrap()` from prewarm or other parallel work |
| Let `UnionDatabase.bootstrap_step()` advance when DB already done | Assume stepwise and full `bootstrap()` stay in sync |
| Keep autoload `_ready()` light | Load save data or card defs at autoload init |

### Prewarm / DriftingCards

**Display mode:** edit `MODE` in [`resources/DriftingCardsConfig.gd`](../resources/DriftingCardsConfig.gd).

| `MODE` | Behavior |
|--------|----------|
| `CARD_BACKS_ONLY` | Quick — card back on both faces; skips ~150 full-card path scan/load |
| `FRONTS` | Normal — random full-card art on the front face while drifting |

Prewarm cache is keyed by mode; changing `MODE` forces a fresh init.

| Do | Don't |
|----|--------|
| Use hidden `_prewarm_only` host on splash | `add_child()` a visible `DriftingCards` on splash |
| `run_prewarm_async()` → `_store_prewarm_cache()` | Run `_initialize_sync()` on prewarm host |
| Main menu `consume_prewarm()` in `_ready()` | Rescan all card art on menu entry |

### Scene transition

| Do | Don't |
|----|--------|
| `change_scene_to_packed(_packed_menu)` after threaded load | `add_child(menu)` to root + `await menu.ready` without `is_node_ready()` check |
| 1s splash fade out (`FadeOverlay` → black), then scene change, then 1s main menu fade in | Instantly clear `FadeOverlay` when coming from splash |
| Set `entered_main_menu_from_splash` **before** scene change | Rely only on `MainMenu._ready` to clear fade (runs late) |
| Keep `FadeOverlay` black in `MainMenu._enter_tree()` until fade-in tween runs | Leave default opaque fade without tween when coming from splash |

### Loading UI responsiveness

| Do | Don't |
|----|--------|
| Shader-based coin (`running` uniform to stop) | Block main thread in `add_child()` `_ready()` chains |
| `await get_tree().process_frame` in long scans | Single-frame bootstrap phases that block for seconds without yields |
| `StartupLoadDebug.log()` at phase boundaries | Debug without timestamps when diagnosing stalls |

---

## Debugging checklist

1. Run cold start (F5); filter Output: **`StartupLoad`**
2. If stuck, find the wait line: `bootstrap= menu= prewarm=` — whichever stays `false` is the blocker
3. If black after load: check `MainMenu._enter_tree (from_splash=true)` and `FadeOverlay cleared`
4. If shader errors: verify `.gdshader` uses GLSL syntax only (no `name: Type` annotations)
5. If hang after `main menu instance added — awaiting ready`: classic `ready`-already-emitted bug — use `change_scene_to_packed`

---

## Related patterns elsewhere

- **GameDialog** for load errors on splash — `SplashScreen._handle_load_errors()` (not native dialogs). See `context/GAME_DIALOG_POPUP_GUIDE.md`.
- **File deletion:** move unused assets to `trash/` (repo rule), e.g. old shader experiments.

---

## Quick Duel overlay

Quick Duel is a **main-menu overlay**, not a separate scene. Closing it uses `queue_free()` so the title screen (and DriftingCards) stay loaded.

| Item | Location |
|------|----------|
| Overlay UI | [`scenes/quick_duel_overlay.tscn`](scenes/quick_duel_overlay.tscn), [`scripts/QuickDuel.gd`](scripts/QuickDuel.gd) |
| Open from menu | [`scripts/MainMenu.gd`](scripts/MainMenu.gd) → `_on_quick_duel()` |
| Reopen after battle | `GameState.open_quick_duel_overlay_on_menu`, `GameState.quick_duel_overlay_active` |

Legacy standalone scene (`scenes/quick_duel.tscn`) was removed — see `trash/scenes/`.

---

## Return to main menu loading

All returns to the title screen should use `MainMenuReturnLoader` (autoload):

| API | Use when |
|-----|----------|
| `return_to_main_menu()` | Direct scene swap (lose screen, VN callback, exploration quit, etc.) |
| `fade_out_to_main_menu()` | Checker fade-out then title (exploration save & exit) |
| `go_to_scene(path)` | Variable destination — routes to loader when path is `main_menu.tscn` |

`CheckerTransition.fade_out_to_scene(main_menu)` also routes through the loader.

Flow: loader shows (black + coin + “Now Loading”) → main menu loads → `DriftingCards` finishes async init → loader fades out → title fades in.

`DriftingCards` prewarm cache is kept across returns (not cleared on consume) so repeat visits are faster.

---

## History

Documented from splash/loading work (2026): deferred autoload bootstrap, DriftingCards prewarm cache, threaded main menu load, GPU coin, bootstrap race fix, scene-handoff fix.
