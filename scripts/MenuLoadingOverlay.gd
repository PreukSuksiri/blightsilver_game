extends Control
class_name MenuLoadingOverlay

## Full-screen loading veil with slow cyan-silver firefly lights drifting upward
## in a cold-morning swirl. Used while heavy menu overlays initialize.

const FIREFLY_COUNT := 12

const _VEIL := Color(0.03, 0.07, 0.11, 0.62)
const _CORE := Color(0.72, 0.98, 1.0, 0.95)
const _GLOW := Color(0.42, 0.86, 0.94, 0.38)
const _HALO := Color(0.78, 0.90, 0.96, 0.14)

var _fireflies: Array[Dictionary] = []
var dismiss_on_tap: bool = false


func set_dismiss_on_tap(enabled: bool = true) -> void:
	dismiss_on_tap = enabled


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	_spawn_fireflies()
	set_process(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		_spawn_fireflies()


func _spawn_fireflies() -> void:
	_fireflies.clear()
	var w: float = maxf(size.x, 1.0)
	var h: float = maxf(size.y, 1.0)
	for i: int in range(FIREFLY_COUNT):
		_fireflies.append({
			"phase": randf() * TAU + float(i) * 0.9,
			"start_x": randf_range(w * 0.12, w * 0.88),
			"start_y": randf_range(h * 0.55, h + 60.0),
			"age": randf_range(0.0, 8.0),
			"rise_speed": randf_range(22.0, 38.0),
			"swirl_h": randf_range(0.35, 0.62),
			"swirl_v": randf_range(0.48, 0.78),
			"swirl_amp_x": randf_range(28.0, 64.0),
			"swirl_amp_y": randf_range(10.0, 26.0),
			"twinkle_speed": randf_range(1.6, 2.8),
			"twinkle_t": randf_range(0.0, TAU),
			"size": randf_range(2.2, 3.6),
			"pos": Vector2.ZERO,
		})


func _process(delta: float) -> void:
	var h: float = maxf(size.y, 1.0)
	var w: float = maxf(size.x, 1.0)
	for f: Dictionary in _fireflies:
		f["age"] = float(f["age"]) + delta
		f["twinkle_t"] = float(f["twinkle_t"]) + delta * float(f["twinkle_speed"])
		var t: float = float(f["age"]) + float(f["phase"])
		var base_y: float = float(f["start_y"]) - t * float(f["rise_speed"])
		if base_y < -80.0:
			f["age"] = 0.0
			f["start_y"] = randf_range(h * 0.62, h + 70.0)
			f["start_x"] = randf_range(w * 0.12, w * 0.88)
			t = float(f["phase"])
			base_y = float(f["start_y"])
		var swirl_x: float = sin(t * float(f["swirl_h"])) * float(f["swirl_amp_x"]) \
			+ cos(t * float(f["swirl_h"]) * 0.58 + 0.7) * float(f["swirl_amp_x"]) * 0.42
		var swirl_y: float = sin(t * float(f["swirl_v"]) + 1.1) * float(f["swirl_amp_y"]) \
			+ cos(t * float(f["swirl_v"]) * 0.43) * float(f["swirl_amp_y"]) * 0.35
		f["pos"] = Vector2(float(f["start_x"]) + swirl_x, base_y + swirl_y)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _VEIL)
	for f: Dictionary in _fireflies:
		_draw_firefly(f)


func _draw_firefly(f: Dictionary) -> void:
	var p: Vector2 = f["pos"]
	var twinkle: float = 0.58 + 0.42 * sin(float(f["twinkle_t"]))
	var core_r: float = float(f["size"])

	var halo := _HALO
	halo.a *= twinkle * 0.85
	draw_circle(p, core_r * 3.4, halo)

	var glow := _GLOW
	glow.a *= twinkle
	draw_circle(p, core_r * 1.85, glow)

	var core := _CORE
	core.a *= twinkle
	draw_circle(p, core_r * 0.55, core)

	var tail := Color(0.82, 0.92, 0.98, 0.08 * twinkle)
	draw_circle(p + Vector2(0.0, core_r * 1.8), core_r * 0.75, tail)


func _gui_input(event: InputEvent) -> void:
	if not dismiss_on_tap:
		return
	if event is InputEventMouseButton and event.pressed:
		queue_free()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		queue_free()
		accept_event()
