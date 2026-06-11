extends ExplorationPuzzleBase
## PuzzleMarioPlatformer — short Game Boy-style platformer puzzle.
## Run, jump over pits, avoid ghost monsters, reach the flag to win.
## Controls: ← → to move, ↑ to jump, Esc to quit.

# ── Game Boy DMG-01 palette ──────────────────────────────────
const GB0 := Color(0.608, 0.737, 0.059)   # lightest  — sky
const GB1 := Color(0.545, 0.675, 0.059)   # light     — clouds, highlights
const GB2 := Color(0.188, 0.384, 0.188)   # medium    — ground, player body
const GB3 := Color(0.059, 0.220, 0.059)   # darkest   — outlines, monsters

# ── World & view ─────────────────────────────────────────────
const WORLD_W  := 1920.0
const VIEW_W   := 1600.0
const VIEW_H   := 900.0
const GROUND_Y := 720.0    # y of ground top surface

# ── Player ───────────────────────────────────────────────────
const PL_W     := 28.0
const PL_H     := 44.0
const GRAVITY  := 1400.0
const JUMP_VEL := -640.0
const PL_SPEED := 240.0

# ── Monster ──────────────────────────────────────────────────
const MON_W    := 28.0
const MON_H    := 28.0
const MON_SPEED := 72.0

# ── Falling spikes (zones 2 & 3) ─────────────────────────────
const SPIKE_ZONES: Array = [
	[740.0,  1200.0],  # zone 2 ground
	[1340.0, WORLD_W], # zone 3 ground
]
const SPIKE_W          := 22.0
const SPIKE_H          := 30.0
const SPIKE_GRAVITY    := 980.0
const SPIKE_MAX        := 14
const SPIKE_SPAWN_MIN  := 0.55
const SPIKE_SPAWN_MAX  := 1.35
const SPIKE_ZONE_START := 620.0  # begin spawning once player reaches zone 2

# ── Level data ────────────────────────────────────────────────
# Ground segments: [world_x_start, world_x_end]
const GROUND_SEGS: Array = [
	[0.0,    620.0],   # opening stretch
	[740.0,  1200.0],  # after pit 1
	[1340.0, WORLD_W], # final stretch to flag
]

# One-way platforms: [world_x, world_y_top, width, height]
const PLATFORMS: Array = [
	[400.0,  640.0, 96.0,  24.0],   # bridge over first pit
	[870.0,  608.0, 128.0, 24.0],   # optional mid-air block
]

# Monsters: [patrol_min_x, patrol_max_x, start_x, start_dir]
const MONSTER_DEFS: Array = [
	[790.0,  1060.0, 790.0,  1.0],
	[1450.0, 1730.0, 1450.0, 1.0],
]

const FLAG_X     := 1840.0
const FLAG_TOP_Y := 500.0

# ── Runtime state ────────────────────────────────────────────
var _player_pos := Vector2(80.0, GROUND_Y - PL_H)
var _player_vel := Vector2.ZERO
var _on_ground  := false
var _cam_x      := 0.0
var _time       := 0.0
var _done       := false
var _monsters: Array = []
var _spikes: Array = []
var _spike_spawn_timer := 0.0
var _hint_label: Label
var _result_label: Label
var _close_btn: Button
var _hint_alpha := 1.0

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode   = Control.FOCUS_ALL
	grab_focus()

	for def in MONSTER_DEFS:
		_monsters.append({
			"pos":   Vector2(def[2], GROUND_Y - MON_H),
			"dir":   def[3],
			"min_x": def[0],
			"max_x": def[1],
		})

	_spike_spawn_timer = randf_range(SPIKE_SPAWN_MIN, SPIKE_SPAWN_MAX)

	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 1
	add_child(ui_layer)

	_hint_label = Label.new()
	_hint_label.text = "Use arrow keys to move the character   ↑ Jump   [ESC] Quit"
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", GB3)
	_hint_label.position = Vector2(12.0, 10.0)
	ui_layer.add_child(_hint_label)

	_close_btn = _make_gb_button("Close")
	_close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_close_btn.pressed.connect(func() -> void: _end_puzzle(false))
	ui_layer.add_child(_close_btn)
	call_deferred("_position_close_btn")

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 48)
	_result_label.add_theme_color_override("font_color", GB3)
	_result_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_result_label.custom_minimum_size = Vector2(700.0, 0.0)
	_result_label.visible = false
	ui_layer.add_child(_result_label)

	set_process(true)
	set_process_unhandled_input(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_position_close_btn()


func _position_close_btn() -> void:
	if _close_btn == null:
		return
	var w: float = size.x if size.x > 1.0 else get_viewport_rect().size.x
	_close_btn.position = Vector2(w - 96.0, 10.0)
	_close_btn.size = Vector2(86.0, 32.0)


func _process(delta: float) -> void:
	_time += delta

	if _time > 2.5:
		_hint_alpha = maxf(0.0, _hint_alpha - delta * 0.8)
		_hint_label.modulate.a = _hint_alpha
		if _hint_alpha <= 0.0 and _hint_label.visible:
			_hint_label.visible = false

	if not _done:
		_update_player(delta)
		_update_monsters(delta)
		_update_spikes(delta)
		_update_camera()

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_end_puzzle(false)


# ─────────────────────────────────────────────────────────────
# Physics
# ─────────────────────────────────────────────────────────────

func _update_player(delta: float) -> void:
	var move := 0.0
	if Input.is_action_pressed("ui_right"):
		move += PL_SPEED
	if Input.is_action_pressed("ui_left"):
		move -= PL_SPEED
	_player_vel.x = move

	if Input.is_action_just_pressed("ui_up") and _on_ground:
		_player_vel.y = JUMP_VEL
		_on_ground    = false
		SFXManager.play(SFXManager.SFX_BTN)

	_player_vel.y += GRAVITY * delta
	_player_pos   += _player_vel * delta
	_player_pos.x  = clampf(_player_pos.x, 0.0, WORLD_W - PL_W)

	_resolve_collisions()

	# Fell below screen
	if _player_pos.y > VIEW_H + 80.0:
		_end_puzzle(false)
		return

	# Monster collision (shrunk hitbox for forgiveness)
	var shrink := 5.0
	var pl_l   := _player_pos.x + shrink
	var pl_r   := _player_pos.x + PL_W - shrink
	var pl_t   := _player_pos.y + shrink
	var pl_b   := _player_pos.y + PL_H - shrink
	for mon in _monsters:
		var mp: Vector2 = mon["pos"]
		if pl_r > mp.x + shrink and pl_l < mp.x + MON_W - shrink \
				and pl_b > mp.y + shrink and pl_t < mp.y + MON_H - shrink:
			_end_puzzle(false)
			return

	if _player_hits_spike(pl_l, pl_r, pl_t, pl_b):
		_end_puzzle(false)
		return

	# Reach flag
	var flag_cx := FLAG_X
	var pl_cx   := _player_pos.x + PL_W * 0.5
	if abs(pl_cx - flag_cx) < 36.0 and _player_pos.y + PL_H > FLAG_TOP_Y:
		_end_puzzle(true)


func _resolve_collisions() -> void:
	_on_ground = false
	var pl_l := _player_pos.x
	var pl_r := _player_pos.x + PL_W
	var pl_b := _player_pos.y + PL_H

	# Ground
	if _player_vel.y >= 0.0:
		for seg in GROUND_SEGS:
			if pl_r > seg[0] and pl_l < seg[1] and pl_b >= GROUND_Y:
				_player_pos.y = GROUND_Y - PL_H
				_player_vel.y = 0.0
				_on_ground     = true
				return

	# One-way platforms (descend into top surface only)
	if not _on_ground and _player_vel.y >= 0.0:
		for plat in PLATFORMS:
			var px: float = plat[0]; var py: float = plat[1]; var pw: float = plat[2]
			if pl_r > px and pl_l < px + pw:
				if pl_b >= py and pl_b <= py + 18.0:
					_player_pos.y = py - PL_H
					_player_vel.y = 0.0
					_on_ground     = true
					return


func _update_monsters(delta: float) -> void:
	for mon in _monsters:
		mon["pos"].x += MON_SPEED * mon["dir"] * delta
		if mon["pos"].x <= mon["min_x"]:
			mon["dir"] = 1.0
		elif mon["pos"].x + MON_W >= mon["max_x"]:
			mon["dir"] = -1.0


func _update_spikes(delta: float) -> void:
	if _player_pos.x + PL_W >= SPIKE_ZONE_START:
		_spike_spawn_timer -= delta
		if _spike_spawn_timer <= 0.0:
			_spawn_random_spike()
			_spike_spawn_timer = randf_range(SPIKE_SPAWN_MIN, SPIKE_SPAWN_MAX)

	var to_remove: Array[int] = []
	for i: int in _spikes.size():
		var sp: Dictionary = _spikes[i]
		if bool(sp.get("fallen", false)):
			continue
		sp["vel"] = float(sp.get("vel", 0.0)) + SPIKE_GRAVITY * delta
		sp["y"] = float(sp["y"]) + float(sp["vel"]) * delta
		var sx: float = float(sp["x"])
		var sy: float = float(sp["y"])
		var landed_y: float = _spike_landing_y(sx, sy)
		if landed_y >= 0.0:
			sp["y"] = landed_y
			sp["vel"] = 0.0
			sp["fallen"] = true
		elif sy > VIEW_H + SPIKE_H:
			to_remove.append(i)
	to_remove.sort()
	to_remove.reverse()
	for idx: int in to_remove:
		_spikes.remove_at(idx)


func _spawn_random_spike() -> void:
	if _spikes.size() >= SPIKE_MAX:
		return
	var zone: Array = SPIKE_ZONES[randi() % SPIKE_ZONES.size()]
	var min_x: float = float(zone[0]) + 8.0
	var max_x: float = float(zone[1]) - SPIKE_W - 8.0
	if max_x <= min_x:
		return
	_spikes.append({
		"x": randf_range(min_x, max_x),
		"y": -SPIKE_H - randf_range(0.0, 120.0),
		"vel": randf_range(80.0, 180.0),
		"fallen": false,
	})


func _spike_landing_y(world_x: float, spike_y: float) -> float:
	var tip_y: float = spike_y + SPIKE_H
	# One-way platforms in zones 2/3
	for plat in PLATFORMS:
		var px: float = plat[0]
		var py: float = plat[1]
		var pw: float = plat[2]
		if world_x + SPIKE_W > px and world_x < px + pw and tip_y >= py and spike_y < py:
			return py - SPIKE_H
	# Ground segments in zones 2/3 only
	for zone in SPIKE_ZONES:
		var z0: float = float(zone[0])
		var z1: float = float(zone[1])
		if world_x + SPIKE_W <= z0 or world_x >= z1:
			continue
		if tip_y >= GROUND_Y and spike_y < GROUND_Y:
			return GROUND_Y - SPIKE_H
	return -1.0


func _player_hits_spike(pl_l: float, pl_r: float, pl_t: float, pl_b: float) -> bool:
	for sp: Dictionary in _spikes:
		var sx: float = float(sp["x"])
		var sy: float = float(sp["y"])
		if pl_r <= sx + 4.0 or pl_l >= sx + SPIKE_W - 4.0:
			continue
		if pl_b <= sy + 6.0 or pl_t >= sy + SPIKE_H:
			continue
		return true
	return false


func _update_camera() -> void:
	var target := _player_pos.x - VIEW_W * 0.38
	_cam_x = clampf(target, 0.0, WORLD_W - VIEW_W)


# ─────────────────────────────────────────────────────────────
# Win / Fail
# ─────────────────────────────────────────────────────────────

func _end_puzzle(success: bool) -> void:
	if _done:
		return
	_done = true
	if _close_btn != null:
		_close_btn.visible = false

	if success:
		SFXManager.play(SFXManager.SFX_CRYSTAL_GAIN)
		_result_label.text = "STAGE  CLEAR!"
	else:
		SFXManager.play(SFXManager.SFX_CANCEL)
		_result_label.text = "GAME  OVER"

	_result_label.visible = true
	queue_redraw()

	var delay := 1.4 if success else 1.0
	await get_tree().create_timer(delay).timeout
	complete_puzzle(success)


func _make_gb_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", GB0)
	var normal := StyleBoxFlat.new()
	normal.bg_color = GB3
	normal.border_color = GB0
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(0)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = GB2
	hover.border_color = GB1
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.03, 0.12, 0.03)
	btn.add_theme_stylebox_override("pressed", pressed)
	return btn


# ─────────────────────────────────────────────────────────────
# Drawing
# ─────────────────────────────────────────────────────────────

func _draw() -> void:
	# Sky
	draw_rect(Rect2(0.0, 0.0, VIEW_W, VIEW_H), GB0)

	# Clouds: initial screen positions scroll at 15% of camera speed
	_draw_cloud(180.0,  72.0)
	_draw_cloud(560.0,  110.0)
	_draw_cloud(980.0,  58.0)
	_draw_cloud(1380.0, 95.0)

	# Ground
	for seg in GROUND_SEGS:
		_draw_ground(seg[0], seg[1])

	# Platforms
	for plat in PLATFORMS:
		_draw_platform(plat[0], plat[1], plat[2], plat[3])

	# Flag (draw behind player so player overlaps pole at end)
	_draw_flag(FLAG_X)

	# Monsters
	for mon in _monsters:
		_draw_monster(mon["pos"].x, mon["pos"].y, mon["dir"] > 0.0)

	# Falling / fallen spikes (zones 2 & 3)
	for sp: Dictionary in _spikes:
		_draw_spike(float(sp["x"]), float(sp["y"]), bool(sp.get("fallen", false)))

	# Player
	_draw_player(_player_pos.x, _player_pos.y)


# ─── sub-draw helpers ────────────────────────────────────────

func _sw(wx: float) -> float:
	# World X → screen X
	return wx - _cam_x


func _draw_cloud(rest_x: float, screen_y: float) -> void:
	# rest_x is the screen x at cam_x=0; slides at 15% of camera speed.
	var x := rest_x - _cam_x * 0.15
	if x > VIEW_W + 100.0 or x < -120.0:
		return
	draw_rect(Rect2(x,        screen_y + 8.0,  68.0, 18.0), GB1)
	draw_rect(Rect2(x + 8.0,  screen_y,        52.0, 16.0), GB1)
	draw_rect(Rect2(x + 20.0, screen_y - 10.0, 32.0, 14.0), GB1)


func _draw_ground(world_start: float, world_end: float) -> void:
	var sx := _sw(world_start)
	var ex := _sw(world_end)
	if ex < 0.0 or sx > VIEW_W:
		return
	var csx := maxf(sx, 0.0)
	var cex := minf(ex, VIEW_W)
	var w   := cex - csx

	# Grass top strip
	draw_rect(Rect2(csx, GROUND_Y, w, 6.0), GB1)
	# Soil body
	draw_rect(Rect2(csx, GROUND_Y + 6.0, w, VIEW_H - GROUND_Y - 6.0), GB2)
	# Top edge line
	draw_rect(Rect2(csx, GROUND_Y, w, 2.0), GB3)

	# World-aligned tile dividers
	var first_tx := world_start + fmod(32.0 - fmod(world_start, 32.0), 32.0)
	var tx       := first_tx
	while tx < world_end:
		var stx := _sw(tx)
		if stx >= csx and stx <= cex:
			draw_rect(Rect2(stx, GROUND_Y + 6.0, 2.0, 22.0), GB3)
		tx += 32.0


func _draw_platform(world_x: float, world_y: float, w: float, h: float) -> void:
	var x := _sw(world_x)
	if x + w < 0.0 or x > VIEW_W:
		return
	# Drop shadow
	draw_rect(Rect2(x + 4.0, world_y + h + 1.0, w, 4.0), Color(GB3, 0.5))
	# Body
	draw_rect(Rect2(x, world_y, w, h), GB2)
	# Top highlight
	draw_rect(Rect2(x, world_y, w, 4.0), GB1)
	# Left highlight
	draw_rect(Rect2(x, world_y, 3.0, h), GB1)
	# Bottom shadow
	draw_rect(Rect2(x, world_y + h - 3.0, w, 3.0), GB3)
	# Right shadow
	draw_rect(Rect2(x + w - 3.0, world_y, 3.0, h), GB3)
	# Tile seams
	var tx := x + 16.0
	while tx < x + w - 4.0:
		draw_rect(Rect2(tx, world_y + 4.0, 2.0, h - 7.0), GB3)
		tx += 16.0


func _draw_monster(world_x: float, world_y: float, facing_right: bool) -> void:
	var x := _sw(world_x)
	if x + MON_W < 0.0 or x > VIEW_W:
		return
	var bob: float = floor(sin(_time * 4.2) * 2.0)
	var ry          := world_y + bob

	# Body (approximate rounded rectangle)
	draw_rect(Rect2(x + 3.0, ry + 3.0, MON_W - 6.0, MON_H - 3.0), GB3)
	draw_rect(Rect2(x + 5.0, ry,       MON_W - 10.0, MON_H), GB3)
	draw_rect(Rect2(x + 1.0, ry + 6.0, MON_W - 2.0,  MON_H - 9.0), GB3)

	# Eyes (fixed screen positions; pupils shift toward facing direction)
	draw_rect(Rect2(x + 4.0,  ry + 5.0, 9.0, 8.0), GB0)
	draw_rect(Rect2(x + 15.0, ry + 5.0, 9.0, 8.0), GB0)
	var p_off: float = 2.0 if facing_right else -2.0
	draw_rect(Rect2(x + 4.0  + 2.0 + p_off, ry + 7.0, 4.0, 4.0), GB3)
	draw_rect(Rect2(x + 15.0 + 2.0 + p_off, ry + 7.0, 4.0, 4.0), GB3)

	# Wavy feet
	var ft: float = floor(sin(_time * 7.0))
	for i in range(3):
		var fx := x + 3.0 + i * 8.0
		var fh := 4.0 + ft * (1 - 2 * (i % 2))
		draw_rect(Rect2(fx, ry + MON_H - 3.0, 7.0, fh), GB3)


func _draw_spike(world_x: float, screen_y: float, fallen: bool) -> void:
	var x := _sw(world_x)
	if x + SPIKE_W < 0.0 or x > VIEW_W:
		return
	var wobble: float = 0.0 if fallen else sin(_time * 9.0 + world_x * 0.05) * 1.5
	var y: float = screen_y + wobble
	var tip := Vector2(x + SPIKE_W * 0.5, y + SPIKE_H)
	var left := Vector2(x, y + 4.0)
	var right := Vector2(x + SPIKE_W, y + 4.0)
	draw_colored_polygon(PackedVector2Array([tip, left, right]), GB3)
	# Inner highlight
	var inner_tip := Vector2(x + SPIKE_W * 0.5, y + SPIKE_H - 6.0)
	var inner_left := Vector2(x + 5.0, y + 7.0)
	var inner_right := Vector2(x + SPIKE_W - 5.0, y + 7.0)
	draw_colored_polygon(PackedVector2Array([inner_tip, inner_left, inner_right]), GB2 if fallen else GB1)
	# Stem when embedded in ground
	if fallen:
		draw_rect(Rect2(x + SPIKE_W * 0.5 - 3.0, y + SPIKE_H - 4.0, 6.0, 6.0), GB3)


func _draw_player(world_x: float, world_y: float) -> void:
	var x := _sw(world_x)
	if x + PL_W < -10.0 or x > VIEW_W + 10.0:
		return

	var running: bool = _on_ground and absf(_player_vel.x) > 10.0
	var phase   := sin(_time * 10.0) if running else 0.0
	var lp      := int(phase  * 3.0)   # left side phase offset
	var rp      := int(-phase * 3.0)   # right side phase offset (opposite)

	# ── Shoes ────────────────────────────────────────────────
	draw_rect(Rect2(x + 2.0,  world_y + PL_H - 4.0 + lp, 11.0, 5.0), GB3)
	draw_rect(Rect2(x + 15.0, world_y + PL_H - 4.0 + rp, 11.0, 5.0), GB3)

	# ── Legs (gakuran trousers — dark) ───────────────────────
	draw_rect(Rect2(x + 5.0,  world_y + 30.0, 8.0, 10.0 + lp), GB3)
	draw_rect(Rect2(x + 15.0, world_y + 30.0, 8.0, 10.0 + rp), GB3)

	# ── Gakuran jacket body ──────────────────────────────────
	draw_rect(Rect2(x + 4.0, world_y + 17.0, 20.0, 15.0), GB2)
	# Center button-line
	draw_rect(Rect2(x + 12.0, world_y + 17.0, 4.0, 15.0), GB3)
	# Mandarin collar (light)
	draw_rect(Rect2(x + 7.0, world_y + 17.0, 4.0, 5.0), GB1)
	draw_rect(Rect2(x + 17.0, world_y + 17.0, 4.0, 5.0), GB1)

	# ── Arms ─────────────────────────────────────────────────
	draw_rect(Rect2(x,        world_y + 18.0 + lp, 5.0, 12.0), GB2)
	draw_rect(Rect2(x + 23.0, world_y + 18.0 + rp, 5.0, 12.0), GB2)

	# ── Face ─────────────────────────────────────────────────
	draw_rect(Rect2(x + 6.0, world_y + 7.0, 16.0, 12.0), GB1)
	# Eyes
	draw_rect(Rect2(x + 9.0,  world_y + 11.0, 4.0, 3.0), GB3)
	draw_rect(Rect2(x + 16.0, world_y + 11.0, 4.0, 3.0), GB3)

	# ── Backward cap ─────────────────────────────────────────
	# Cap body sits on top of head
	draw_rect(Rect2(x + 3.0, world_y + 2.0, 22.0, 8.0), GB3)
	# Brim extends LEFT (= backward; player runs right so brim is at back)
	draw_rect(Rect2(x - 3.0, world_y + 6.0, 9.0, 4.0), GB3)
	# Crown button
	draw_rect(Rect2(x + 13.0, world_y, 4.0, 4.0), GB3)
	# Hair peeking from front (right side)
	draw_rect(Rect2(x + 21.0, world_y + 8.0, 5.0, 4.0), GB2)


func _draw_flag(world_x: float) -> void:
	var x := _sw(world_x)
	if x > VIEW_W + 60.0 or x < -60.0:
		return

	# Pole
	draw_rect(Rect2(x - 1.0, FLAG_TOP_Y, 3.0, GROUND_Y - FLAG_TOP_Y), GB3)

	# Pennant (staircase triangle approximation pointing right)
	draw_rect(Rect2(x + 2.0, FLAG_TOP_Y,        36.0, 12.0), GB3)
	draw_rect(Rect2(x + 2.0, FLAG_TOP_Y + 12.0, 24.0, 11.0), GB3)
	draw_rect(Rect2(x + 2.0, FLAG_TOP_Y + 23.0, 14.0, 10.0), GB3)
	# Flag face stripe in GB2
	draw_rect(Rect2(x + 4.0, FLAG_TOP_Y + 2.0,  22.0, 8.0), GB2)

	# Ball at top of pole
	draw_rect(Rect2(x - 5.0, FLAG_TOP_Y - 10.0, 12.0, 12.0), GB3)
	draw_rect(Rect2(x - 3.0, FLAG_TOP_Y - 8.0,   8.0,  8.0), GB1)

	# Pole base block
	draw_rect(Rect2(x - 9.0, GROUND_Y - 14.0, 20.0, 14.0), GB2)
	draw_rect(Rect2(x - 9.0, GROUND_Y - 14.0, 20.0,  3.0), GB3)
