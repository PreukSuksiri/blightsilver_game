extends RefCounted
class_name OmenVisuals
## Shared Omen presentation: rarity palette, static capsule chrome, placeholder art
## and lookups for the Omens anointed to a given card.
##
## OmenSelectOverlay owns the animated (fog-condense / shatter) variant of the
## capsule; everything that just needs to *show* an Omen builds it from here.

const SHADER_CAPSULE: Shader = preload("res://assets/shaders/omen_capsule.gdshader")
const SHADER_CIRCLE_ART: Shader = preload("res://assets/shaders/omen_circle_art.gdshader")

const RARITY_RING: Dictionary = {
	"common": Color(0.70, 0.74, 0.82, 1.0),
	"uncommon": Color(0.36, 0.88, 0.52, 1.0),
	"rare": Color(0.40, 0.68, 1.00, 1.0),
	"epic": Color(0.78, 0.48, 1.00, 1.0),
}

## common → 1 ★ … epic → 4 ★. Matches the card-detail language players already know.
const RARITY_STARS: Dictionary = {
	"common": 1,
	"uncommon": 2,
	"rare": 3,
	"epic": 4,
}

## Halo bleed around the disc — the capsule shader draws its glow into this margin.
const GLOW_PAD: float = 18.0


static func ring_color(omen: Dictionary) -> Color:
	var rarity: String = str(omen.get("rarity", "common")).to_lower()
	return RARITY_RING.get(rarity, RARITY_RING["common"]) as Color


static func rarity_star_count(omen: Dictionary) -> int:
	var rarity: String = str(omen.get("rarity", "common")).to_lower()
	return int(RARITY_STARS.get(rarity, 1))


## Subtle ★ row tinted to the omen's rarity. Sits under an effect description —
## never inside the capsule art itself.
static func build_rarity_stars(omen: Dictionary, font_size: int = 14) -> Control:
	var ring: Color = ring_color(omen)
	var stars := Label.new()
	stars.text = "★".repeat(maxi(rarity_star_count(omen), 1))
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stars.add_theme_font_override("font", FontManager.make_font("primary", 600))
	stars.add_theme_font_size_override("font_size", font_size)
	stars.add_theme_color_override("font_color",
			Color(ring.r, ring.g, ring.b, 0.72))
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stars


## [inner, outer] body gradient — green for boons, red for banes, steel when unset.
static func fill_colors(omen: Dictionary) -> Array:
	var positive: Variant = omen.get("positive", null)
	if positive == null:
		return [Color(0.11, 0.14, 0.22, 0.98), Color(0.02, 0.03, 0.06, 0.98)]
	if bool(positive):
		return [Color(0.09, 0.19, 0.17, 0.98), Color(0.02, 0.05, 0.06, 0.98)]
	return [Color(0.20, 0.10, 0.13, 0.98), Color(0.06, 0.02, 0.04, 0.98)]


## Fully materialised capsule disc sized `diameter`, inside a `diameter + pad * 2` box.
## Rarity is never written on the disc — callers put stars under nearby effect text.
## Pass `show_text = false` for art-only discs (Anoint header) where copy lives beside.
static func build_capsule(
		omen: Dictionary,
		diameter: float,
		glow_pad: float = GLOW_PAD,
		show_text: bool = true) -> Control:
	var d: float = maxf(diameter, 48.0)
	var box: float = d + glow_pad * 2.0
	var ring: Color = ring_color(omen)
	var fills: Array = fill_colors(omen)

	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(box, box)
	wrapper.size = Vector2(box, box)
	wrapper.pivot_offset = Vector2(box, box) * 0.5
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var chrome := ColorRect.new()
	chrome.color = Color(1, 1, 1, 1)
	chrome.size = Vector2(box, box)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chrome_mat := ShaderMaterial.new()
	chrome_mat.shader = SHADER_CAPSULE
	chrome_mat.set_shader_parameter("rect_size", Vector2(box, box))
	chrome_mat.set_shader_parameter("radius_px", d * 0.5)
	chrome_mat.set_shader_parameter("ring_a", ring)
	chrome_mat.set_shader_parameter("ring_b", ring.lightened(0.55))
	chrome_mat.set_shader_parameter("ring_px", maxf(3.0, d * 0.013))
	chrome_mat.set_shader_parameter("inner_bezel_gap", maxf(6.0, d * 0.032))
	chrome_mat.set_shader_parameter("glow_px", glow_pad * 0.9)
	chrome_mat.set_shader_parameter("glow_strength", 0.36)
	chrome_mat.set_shader_parameter("fill_inner", fills[0])
	chrome_mat.set_shader_parameter("fill_outer", fills[1])
	chrome.material = chrome_mat
	wrapper.add_child(chrome)
	wrapper.set_meta("chrome_mat", chrome_mat)

	# Top-half illustration; lower half is chrome body (and text when requested).
	var art := TextureRect.new()
	art.position = Vector2(glow_pad, glow_pad)
	art.size = Vector2(d, d * 0.5)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_mat := ShaderMaterial.new()
	art_mat.shader = SHADER_CIRCLE_ART
	art_mat.set_shader_parameter("art_size", Vector2(d, d * 0.5))
	art_mat.set_shader_parameter("edge_inset_px", maxf(4.0, d * 0.026))
	art_mat.set_shader_parameter("bottom_fade_px", d * 0.14)
	art_mat.set_shader_parameter("placeholder_color", ring.darkened(0.55))
	art_mat.set_shader_parameter("tint_color", ring)
	art_mat.set_shader_parameter("use_texture", 1.0)
	var illus_path: String = str(omen.get("illustration", "")).strip_edges()
	if not illus_path.is_empty() and ResourceLoader.exists(illus_path):
		art.texture = load(illus_path) as Texture2D
	else:
		art.texture = make_placeholder_art_tex(ring)
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art_mat.set_shader_parameter("tint_strength", 0.10)
	art.material = art_mat
	wrapper.add_child(art)

	if not show_text:
		return wrapper

	var label := Label.new()
	label.text = str(omen.get("label", omen.get("id", "Omen")))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = Vector2(glow_pad + d * 0.14, glow_pad + d * 0.52)
	label.size = Vector2(d * 0.72, d * 0.11)
	label.add_theme_font_override("font", FontManager.make_font("display_serif", 700))
	label.add_theme_font_size_override("font_size", maxi(int(d * 0.070), 13))
	label.add_theme_color_override("font_color", ring.lightened(0.42))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(label)

	var desc := Label.new()
	desc.text = str(omen.get("description", ""))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.clip_text = true
	desc.position = Vector2(glow_pad + d * 0.16, glow_pad + d * 0.635)
	desc.size = Vector2(d * 0.68, d * 0.20)
	desc.add_theme_font_override("font", FontManager.make_font("primary", 400))
	desc.add_theme_font_size_override("font_size", maxi(int(d * 0.046), 10))
	desc.add_theme_color_override("font_color", Color(0.84, 0.89, 0.96, 0.95))
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(desc)

	var stars: Control = build_rarity_stars(omen, maxi(int(d * 0.055), 11))
	stars.position = Vector2(glow_pad + d * 0.20, glow_pad + d * 0.855)
	stars.size = Vector2(d * 0.60, d * 0.08)
	wrapper.add_child(stars)

	return wrapper


## Stand-in artwork for omens without an illustration: a lit sky gradient with
## faint arcane arcs, so an unauthored capsule still reads as finished art.
static func make_placeholder_art_tex(ring: Color) -> Texture2D:
	const W: int = 192
	const H: int = 96
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var top: Color = ring.lightened(0.20).darkened(0.30)
	var bottom: Color = ring.darkened(0.78)
	var center := Vector2(W * 0.5, float(H))
	for y: int in range(H):
		var base: Color = top.lerp(bottom, pow(float(y) / float(H - 1), 0.75))
		for x: int in range(W):
			var c: Color = base
			# Soft halo behind where a sigil would sit.
			var dist: float = Vector2(float(x), float(y)).distance_to(center) / float(H)
			c = c.lerp(ring.lightened(0.45), clampf(0.30 - dist * 0.30, 0.0, 0.30))
			# Concentric arcs for a faint ritual-circle read.
			var arc: float = absf(sin(dist * 9.0))
			c = c.lightened(clampf((arc - 0.92) * 1.6, 0.0, 0.12))
			c.a = 1.0
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


# ─────────────────────────────────────────────────────────────
# Held-omen lookups
# ─────────────────────────────────────────────────────────────

## Held entries ({id, anointed_card}) from whichever context is live — the battle
## snapshot, the exploration session, or both when a battle is running mid-stage.
static func held_entries() -> Array:
	var entries: Array = []
	var seen: Dictionary = {}
	var sources: Array = [GameState.active_omens]
	if ExplorationManager.is_session_active:
		sources.append(ExplorationManager.get_active_omens())
	for src: Variant in sources:
		if not src is Array:
			continue
		for held: Variant in src as Array:
			if not held is Dictionary:
				continue
			var entry: Dictionary = held as Dictionary
			var id: String = str(entry.get("id", "")).strip_edges()
			if id.is_empty():
				continue
			var key: String = "%s|%s" % [id, str(entry.get("anointed_card", ""))]
			if seen.has(key):
				continue
			seen[key] = true
			entries.append(entry.duplicate(true))
	return entries


## Full omen catalog rows for everything the player currently holds, in held order.
## Each row: { "entry": {id, anointed_card}, "omen": <omens.json row> }.
static func held_rows() -> Array:
	var rows: Array = []
	for entry: Variant in held_entries():
		var e: Dictionary = entry as Dictionary
		var omen: Dictionary = OmenDatabase.get_omen(str(e.get("id", "")))
		if omen.is_empty():
			continue
		rows.append({"entry": e, "omen": omen})
	return rows


## Omens anointed to a specific card. Global (non-anoint) omens target no card and
## are deliberately excluded — a badge on every card would carry no information.
static func rows_for_card(card_name: String) -> Array:
	var wanted: String = card_name.strip_edges()
	if wanted.is_empty():
		return []
	var rows: Array = []
	for row: Variant in held_rows():
		var r: Dictionary = row as Dictionary
		var entry: Dictionary = r.get("entry", {}) as Dictionary
		if str(entry.get("anointed_card", "")).strip_edges() == wanted:
			rows.append(r)
	return rows


static func has_any_omen() -> bool:
	return not held_entries().is_empty()
