# Game Dialog Popup Guide

Use this guide whenever you add or change **in-game modal prompts** (confirmations, alerts, multi-choice menus, text prompts).

**Rule:** Use the shared `GameDialog` autoload skin. **Do not** use Godot native dialogs (`AcceptDialog`, `ConfirmationDialog`, etc.) and **do not** hand-build one-off `PanelContainer` / `StyleBoxFlat` popup UIs for player-facing prompts.

---

## Source of truth

| Item | Location |
|------|----------|
| Autoload API | `autoload/GameDialog.gd` |
| Registered in | `project.godot` → `GameDialog="*res://autoload/GameDialog.gd"` |
| Magitech skin (target) | [MAGITECH_UI_THEME.md](MAGITECH_UI_THEME.md) · `MagitechTheme.gd` · `resources/themes/magitech_ui.tres` |

Dialog chrome should converge on the Magitech kit above — do not invent a second VN-navy skin for new prompts.

Reference implementations:

- Deck Builder high-cost save confirm — `scripts/DeckBuilder.gd` → `_confirm_high_cost_save()`
- Quick Duel tutorial prompt — `scripts/QuickDuel.gd` → `_show_tutorial_prompt()`
- Exploration quit confirm — `scripts/ExplorationPlayer.gd`
- Campaign gallery actions — `scripts/CampaignGallery.gd`

---

## When to use `GameDialog`

| Use `GameDialog` | Do **not** use `GameDialog` |
|------------------|-----------------------------|
| Yes / No, OK / Cancel, multi-button choices | `FileDialog` / folder pickers (import/export) |
| Alert / info overlays (`accept_overlay`) | Editor-only tool windows (`VNEditor`, builders) |
| Text input prompts (`prompt_overlay`) | Specialized full-screen flows (pack opening, battle overlay, VN player) |
| Any player-facing confirmation in menus, battle HUD, Quick Duel, inventory, etc. | Re-skinning with new `StyleBoxFlat` colors per screen |

If you need a **new dialog type**, extend `GameDialog.gd` once so all screens share the same skin — do not duplicate panel/button styling elsewhere.

---

## API quick reference

All methods parent the overlay on the given `parent` node (usually `self`), set `z_index` (default `400`), and name the root `GameDialogOverlay`.

### Confirmation (two buttons)

Cancel is shown **right**, confirm / Yes **left** (same as Quick Duel tutorial).

```gdscript
GameDialog.confirmation_overlay(
    self,
    "Title",
    "Body text shown to the player.",
    "Confirm",      # OK / primary action
    "Cancel",       # secondary action
    func() -> void: _on_confirm(),
    func() -> void: _on_cancel())
```

### Alert (single OK)

```gdscript
GameDialog.accept_overlay(
    self,
    "Title",
    "Message body.",
    "OK",
    func() -> void: _after_ok())
```

### Multiple actions + optional cancel

```gdscript
GameDialog.choices_overlay(
    self,
    "Title",
    "Pick an option.",
    [
        {"text": "Option A", "callback": func() -> void: _do_a()},
        {"text": "Option B", "callback": func() -> void: _do_b()},
    ],
    "Cancel")
```

### Text prompt

```gdscript
GameDialog.prompt_overlay(
    self,
    "Title",
    "Enter a name:",
    "Placeholder",
    "OK",
    "Cancel",
    func(text: String) -> bool:
        if text.is_empty():
            return false  # keep dialog open
        _apply_name(text)
        return true,
    func() -> void: pass)
```

`on_confirm` must return `true` to close the dialog.

---

## Lifecycle helpers

```gdscript
# Avoid stacking duplicate dialogs
if GameDialog.has_open_overlay(self):
    return

# Close programmatically (e.g. before scene change)
GameDialog.close_overlay(self)
```

Overlays call `queue_free()` on themselves when a button is pressed. You do not need to free them manually unless you close early.

---

## Styling building blocks

If a screen needs **matching** panel/button look outside a full overlay (e.g. embedded panel), reuse helpers — do not invent new colors:

```gdscript
panel.add_theme_stylebox_override("panel", GameDialog.make_panel_stylebox())
GameDialog.style_title_label(title_lbl)
GameDialog.style_body_label(body_lbl)
GameDialog.style_button(btn)
```

Example: `scripts/SettingsMenu.gd`.

---

## Anti-patterns (do not do this)

```gdscript
# BAD — native Godot dialog
var d := AcceptDialog.new()
add_child(d)
d.popup_centered()

# BAD — one-off styled popup per screen
var panel := PanelContainer.new()
var sb := StyleBoxFlat.new()
sb.bg_color = Color(0.04, 0.06, 0.14, 0.97)
# ... custom buttons with no GameDialog.style_button()
```

```gdscript
# GOOD — shared skin
GameDialog.confirmation_overlay(self, "Leave battle?", "Progress will be lost.", "Leave", "Stay",
    func() -> void: _leave(),
    func() -> void: pass)
```

---

## Checklist for new popups

1. Is this a player-facing modal (not a file picker or dev editor)?
2. Use the matching `GameDialog.*_overlay()` method.
3. Guard with `has_open_overlay()` if the trigger can fire twice.
4. Call `close_overlay()` before scene transitions if the dialog might still be open.
5. Do not add new panel colors or button styles in feature scripts.
