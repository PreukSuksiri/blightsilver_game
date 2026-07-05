extends RefCounted
class_name StartupLoadDebug

## Timestamped startup trace: splash → main menu → drifting cards.
## Filter Godot Output with: StartupLoad

static var _t0_ms: int = -1
static var _enabled := true


static func log(event: String) -> void:
	if not _enabled:
		return
	var now_ms: int = Time.get_ticks_msec()
	if _t0_ms < 0:
		_t0_ms = now_ms
	var elapsed_s: float = float(now_ms - _t0_ms) / 1000.0
	print("[StartupLoad %+.3fs] %s" % [elapsed_s, event])
