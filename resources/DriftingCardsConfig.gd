extends Object
class_name DriftingCardsConfig
## Title-screen drifting cards — display mode toggle.
##
## Edit MODE below to switch between normal full-card art and quick card-back-only.

enum Mode {
	## Random full-card fronts while drifting (scans/loads full_cards art).
	FRONTS,
	## Card back on both faces — skips front texture scan/load (faster).
	CARD_BACKS_ONLY,
}

# ── Switch display mode here ─────────────────────────────────────
const MODE := Mode.CARD_BACKS_ONLY
# const MODE := Mode.FRONTS
# ────────────────────────────────────────────────────────────────


static func card_backs_only() -> bool:
	return MODE == Mode.CARD_BACKS_ONLY


static func mode_name() -> String:
	return "card_backs_only" if card_backs_only() else "fronts"
