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
