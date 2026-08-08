# Blightsilver — Claude Instructions

## File Deletion Rule

**Never permanently delete files or folders.**

Instead, move them to `/Users/blightsilver/blightsilver_game/trash/` and let the human decide when to permanently remove them.

- Use `mv <path> /Users/blightsilver/blightsilver_game/trash/` instead of `rm`
- This applies to all files and folders, including temporary files, old assets, and unused scenes
- The `trash/` folder at the repo root is the designated soft-delete location

## Surgical Edits Only (JSON / data / code)

**Never rewrite an entire JSON (or other data) file for a small change.**

- Prefer targeted search-and-replace / minimal patches that touch only the fields or spots required
- Do **not** round-trip files through `json.load` → `json.dump` (or equivalent) just to edit one value — that reformats the whole file and risks wiping uncommitted authoring work
- Do **not** use `git checkout` / `git restore` to “fix” a bad rewrite unless the human explicitly asks — that discards uncommitted local edits
- Same spirit for code: change the smallest surface that satisfies the requirement; avoid drive-by refactors and unrelated cleanup

**Lesson:** Clearing one spot `icon` to `""` is a one-field replace. A full-file rewrite is never the right approach for that class of task.

## Player perception: opponent face-down Dead Ends

**From another player's eye, an opponent's face-down Dead End cell counts as a card.**

- Visually it uses the same facedown frame as face-down units/traps (`Card._show_face_down()`).
- The viewer cannot distinguish blank vs unit/trap until reveal.
- UX that talks about “cards” among foe face-down cells (selection counts, confirm dialogs like Rift Strike “destroy N”, targeting copy) should treat face-down Dead Ends as cards.
- Face-up / revealed Dead Ends and destroyed empty slots do **not** count as cards.
- Resolve may still skip actually destroying Dead End cells (no crystal loss, no destroy VFX) — that is rules-engine truth, separate from player-facing “card” language.

## Destroy vs survive (counting / UX)

**Separate the ability to destroy from the ability to survive destruction.**

- An effect that destroys (e.g. Rift Strike) has a duty to destroy selected targets. It does **not** get to pre-filter the player-facing “destroy N” count by guessing who will survive.
- For Rift Strike confirm copy: **destroy N = number of selected cells** (not “expected survivors after immunity / blank / etc.”).
- Whether a card actually dies is decided by **survival** rules on the target or global systems (Dead End blanks, tech immunity, Force Shield, etc.) during resolve — not by the destroy effect “deciding” count up front.
- Keep those concerns apart in code and UX: selection/count = destroy intent; resolve outcome = survival.
- **Battle log (post-resolve)** reports **actual destroyed cards** (outcome after survival), not the pre-resolve selected-cell N. Confirm dialog = intent; chronicle = what actually died.

## Destroy face-down Dead End / trap = reveal

When a destroy effect hits a **face-down Dead End** or **face-down trap**, that destroy is performed as a **reveal** (flip animation), then the usual reveal cleanup (blank dissolve / trap void).

- **Enforced in `GameState.destroy_card`**: face-down `dead_end` / `trap` redirects to `reveal_card` (ability-sourced when analytics/omen/tech-self-destruct context is set). Callers do not need a per-card special case.
- Exception: current BATTLE defender cell keeps TurnManager’s existing reveal-then-destroy cadence (no redirect).
- GameBoard tech paths that must wait for flip/dissolve should use `_destroy_card_and_await`.
- Do **not** silently skip face-down Dead Ends on destroy effects.
- Do **not** hard-clear a face-down trap without showing its face first.
- Units (characters) still use the normal destroy pipeline; survival rules remain separate.
- Recursion-safe: `_on_card_revealed` clears blanks via `destroy_card` only after `face_up` is already true.
