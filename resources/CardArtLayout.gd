class_name CardArtLayout
extends RefCounted
## Shared vellum-frame art window math for battle grid cards and full-card export.
## CardDetailOverlay keeps its own inline constants (unchanged); values here match it.

# Reference vellum export size (819×1126 px frame)
const REF_WIDTH: float = 819.0
const REF_HEIGHT: float = 1126.0
const FRAME_ASPECT: float = REF_WIDTH / REF_HEIGHT

# Full-card art window — same proportions as CardDetailOverlay
const ART_L_PCT: float = 0.051
const ART_R_PCT: float = 0.949
const ART_T_PCT: float = 0.096
const ART_B_PCT: float = 1.000
const INFO_TOP_PCT: float = 0.520

# Battle grid tile reference (GameBoard.BATTLE_CARD_MIN)
const GRID_REF_SIZE := Vector2(110.0, 150.0)
# Stats row begins at y=120 on the reference tile; art ends at y=119
const GRID_ART_B_PCT: float = 119.0 / 150.0


static func full_art_rect(card_w: float, card_h: float) -> Rect2:
	var left: float = ART_L_PCT * card_w
	var top: float = ART_T_PCT * card_h
	return Rect2(
		left,
		top,
		(ART_R_PCT - ART_L_PCT) * card_w,
		(ART_B_PCT - ART_T_PCT) * card_h
	)


static func grid_art_rect(card_w: float, card_h: float) -> Rect2:
	var left: float = ART_L_PCT * card_w
	var top: float = ART_T_PCT * card_h
	return Rect2(
		left,
		top,
		(ART_R_PCT - ART_L_PCT) * card_w,
		(GRID_ART_B_PCT - ART_T_PCT) * card_h
	)


static func scale_artwork_offset(offset: Vector2, card_w: float, card_h: float) -> Vector2:
	if offset == Vector2.ZERO:
		return Vector2.ZERO
	return Vector2(
		offset.x * (card_w / REF_WIDTH),
		offset.y * (card_h / REF_HEIGHT)
	)
