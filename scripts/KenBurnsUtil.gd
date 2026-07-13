extends RefCounted
class_name KenBurnsUtil
## Shared Ken Burns timing curve — delay, optional ramp-in/out velocities, legacy sine ease.


static func motion_duration(kb: Dictionary) -> float:
	return maxf(float(kb.get("duration", 4.0)), 0.1)


static func total_time(kb: Dictionary) -> float:
	return maxf(float(kb.get("delay", 0.0)), 0.0) + motion_duration(kb)


static func sample_progress(elapsed: float, kb: Dictionary) -> float:
	var delay: float = maxf(float(kb.get("delay", 0.0)), 0.0)
	var dur: float = motion_duration(kb)
	if elapsed < delay:
		return 0.0
	var t: float = elapsed - delay
	if t >= dur:
		return 1.0
	var u: float = t / dur
	var has_start: bool = kb.has("start_velocity")
	var has_stop: bool = kb.has("stop_velocity")
	if not has_start and not has_stop:
		return (1.0 - cos(u * PI)) * 0.5
	var sr: float = maxf(float(kb.get("start_velocity", 0.0)), 0.0) if has_start else 0.0
	var er: float = maxf(float(kb.get("stop_velocity", 0.0)), 0.0) if has_stop else 0.0
	var total_ramp: float = sr + er
	if total_ramp > dur * 0.98:
		var ramp_scale: float = dur * 0.98 / maxf(total_ramp, 0.001)
		sr *= ramp_scale
		er *= ramp_scale
	var cruise_d: float = maxf(dur - sr - er, 0.001)
	var ramp_in_share: float = (sr / dur * 0.5) if sr > 0.0 else 0.0
	var ramp_out_share: float = (er / dur * 0.5) if er > 0.0 else 0.0
	var cruise_share: float = 1.0 - ramp_in_share - ramp_out_share
	if t <= sr and sr > 0.0:
		var lt: float = t / sr
		return ramp_in_share * (lt * lt)
	var after_in: float = t - sr
	if after_in <= cruise_d:
		return ramp_in_share + cruise_share * (after_in / cruise_d)
	var in_out: float = after_in - cruise_d
	if er > 0.0:
		var lt: float = in_out / er
		return ramp_in_share + cruise_share + ramp_out_share * (1.0 - (1.0 - lt) * (1.0 - lt))
	return 1.0


static func apply_transform(
		target: TextureRect,
		progress: float,
		from_scale: float,
		to_scale: float,
		from_pos: Vector2,
		to_pos: Vector2) -> void:
	var p: float = clampf(progress, 0.0, 1.0)
	var scale_v: float = lerpf(from_scale, to_scale, p)
	target.scale = Vector2(scale_v, scale_v)
	target.position = from_pos.lerp(to_pos, p)


static func fit_width_layout(texture: Texture2D, viewport: Vector2) -> Dictionary:
	var tw: float = maxf(float(texture.get_width()), 1.0)
	var th: float = maxf(float(texture.get_height()), 1.0)
	var layout_w: float = viewport.x
	var layout_h: float = th * (layout_w / tw)
	var layout_size := Vector2(layout_w, layout_h)
	var base_position := (viewport - layout_size) * 0.5
	return {
		"layout_size": layout_size,
		"base_position": base_position,
	}


static func pan_offset(kb: Dictionary, is_start: bool = false) -> Vector2:
	if is_start:
		return Vector2(
			float(kb.get("start_pan_x", 0.0)) if kb.has("start_pan_x") else 0.0,
			float(kb.get("start_pan_y", 0.0)) if kb.has("start_pan_y") else 0.0)
	return Vector2(float(kb.get("pan_x", 0.0)), float(kb.get("pan_y", 0.0)))


static func apply_expanded_layout(
		target: TextureRect,
		texture: Texture2D,
		viewport: Vector2) -> Dictionary:
	var layout: Dictionary = fit_width_layout(texture, viewport)
	var layout_size: Vector2 = layout["layout_size"]
	target.texture = texture
	target.stretch_mode = TextureRect.STRETCH_SCALE
	target.size = layout_size
	target.pivot_offset = layout_size * 0.5
	target.position = layout["base_position"]
	target.scale = Vector2.ONE
	return layout


static func restore_static_layout(target: TextureRect, viewport: Vector2) -> void:
	target.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	target.size = viewport
	target.pivot_offset = viewport * 0.5
	target.position = Vector2.ZERO
	target.scale = Vector2.ONE


static func effective_position(base_position: Vector2, kb: Dictionary, is_start: bool) -> Vector2:
	return base_position + pan_offset(kb, is_start)
