# Blightsilver — Claude Instructions

## File Deletion Rule

**Never permanently delete files or folders.**

Instead, move them to `/Users/blightsilver/blightsilver_game/trash/` and let the human decide when to permanently remove them.

- Use `mv <path> /Users/blightsilver/blightsilver_game/trash/` instead of `rm`
- This applies to all files and folders, including temporary files, old assets, and unused scenes
- The `trash/` folder at the repo root is the designated soft-delete location
