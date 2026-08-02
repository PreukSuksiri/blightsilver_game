extends Control
class_name OmenBadge
## Pulsing procedural sigil marking a card that an Omen has anointed.
##
## Drawn rather than textured so it tints to the omen's rarity and stays crisp at
## any tile size. The pulse is a looping tween on the node, so `_draw` runs once.

const RARITY_ORDER: Array = ["common", "uncommon", "rare", "epic"]

const PULSE_DUR: float = 0.85
const PULSE_SCALE: float = 1.16
const PULSE_ALPHA_LOW: float = 0.72

var _ring: Color = Color(0.70, 0.74, 0.82, 1.0)


## Badge for every omen anointed to `card_name`, anchored to the tile's top-left.
## Returns null when the card carries no omen.
static func attach_to_tile(tile: Control, card_name: String, badge_size: float = 22.0) -> OmenBadge:
	if tile == null:
		return null
	var rows: Array = OmenVisuals.rows_for_card(card_name)
	if rows.is_empty():
		return null
	var badge := OmenBadge.new()
	badge._ring = _strongest_ring(rows)
	badge.size = Vector2(badge_size, badge_size)
	badge.custom_minimum_size = badge.size
	badge.pivot_offset = badge.size * 0.5
	badge.position = Vector2(2.0, 2.0)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(badge)
	return badge


func set_ring(color: Color) -> void:
	_ring = color
	queue_redraw()


static func _strongest_ring(rows: Array) -> Color:
	var best: int = -1
	var best_omen: Dictionary = {}
	for row: Variant in rows:
		var omen: Dictionary = (row as Dictionary).get("omen", {}) as Dictionary
		var rank: int = RARITY_ORDER.find(str(omen.get("rarity", "common")).to_lower())
		if rank > best:
			best = rank
			best_omen = omen
	return OmenVisuals.ring_color(best_omen)


func _ready() -> void:
	pivot_offset = size * 0.5
	var tw: Tween = create_tween().set_loops()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE * PULSE_SCALE, PULSE_DUR) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "modulate:a", 1.0, PULSE_DUR) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, PULSE_DUR) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "modulate:a", PULSE_ALPHA_LOW, PULSE_DUR) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5
	if r <= 1.0:
		return

	# Halo, faked with stacked discs since canvas_item has no radial gradient.
	for i: int in range(3):
		var t: float = float(i) / 3.0
		draw_circle(c, r * (1.0 - t * 0.22), Color(_ring.r, _ring.g, _ring.b, 0.09 + t * 0.05))

	draw_circle(c, r * 0.78, Color(0.02, 0.03, 0.07, 0.92))
	draw_arc(c, r * 0.78, 0.0, TAU, 28, _ring, maxf(r * 0.10, 1.0), true)

	# Ritual diamond.
	var d: float = r * 0.42
	var diamond: PackedVector2Array = PackedVector2Array([
		c + Vector2(0.0, -d), c + Vector2(d, 0.0),
		c + Vector2(0.0, d), c + Vector2(-d, 0.0), c + Vector2(0.0, -d),
	])
	draw_polyline(diamond, _ring.lightened(0.45), maxf(r * 0.07, 1.0), true)

	# Diagonal spokes reaching for the rim.
	var spoke: float = r * 0.72
	var inner: float = r * 0.50
	for i: int in range(4):
		var ang: float = PI * 0.25 + float(i) * PI * 0.5
		var dir := Vector2(cos(ang), sin(ang))
		draw_line(c + dir * inner, c + dir * spoke,
				Color(_ring.r, _ring.g, _ring.b, 0.85), maxf(r * 0.06, 1.0), true)

	draw_circle(c, maxf(r * 0.13, 1.0), _ring.lightened(0.6))
