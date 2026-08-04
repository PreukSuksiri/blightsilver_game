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
