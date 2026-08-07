extends ExplorationPuzzleBase
## PuzzleGameBoyPlatformer — period-authentic DMG handheld platformer (clone of Mario stage).
## Letterboxed 160×144 LCD, pixel-snapped draw, lives + STAGE CLEAR / GAME OVER ceremony.
## Controls: ← → to move, ↑ to jump, Esc to quit.

# ── Game Boy DMG-01 palette ──────────────────────────────────
const GB0 := Color(0.608, 0.737, 0.059)   # lightest  — sky
const GB1 := Color(0.545, 0.675, 0.059)   # light     — clouds, highlights
const GB2 := Color(0.188, 0.384, 0.188)   # medium    — ground, player body
const GB3 := Color(0.059, 0.220, 0.059)   # darkest   — outlines, monsters
const BEZEL := Color(0.06, 0.07, 0.06)     # outer frame (off-LCD)
const BEZEL_RIM := Color(0.12, 0.14, 0.11)

# ── Native LCD + logical camera (GB 10:9 aspect) ─────────────
const GB_NATIVE_W := 160.0
const GB_NATIVE_H := 144.0
const WORLD_W  := 1920.0
const VIEW_H   := 900.0
const VIEW_W   := VIEW_H * GB_NATIVE_W / GB_NATIVE_H  # 1000 — matches LCD aspect
const GROUND_Y := 720.0    # y of ground top surface
const HUD_H    := 48.0     # top status strip in world/view units

# ── Player ───────────────────────────────────────────────────
const PL_W     := 28.0
const PL_H     := 44.0
const GRAVITY  := 1400.0
const JUMP_VEL := -640.0
const PL_SPEED := 240.0
const START_X  := 80.0
const START_LIVES := 3

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
var _player_pos := Vector2(START_X, GROUND_Y - PL_H)
var _player_vel := Vector2.ZERO
var _on_ground  := false
var _cam_x      := 0.0
var _time       := 0.0
var _done       := false
var _won        := false
var _cancelled  := false
var _lives      := START_LIVES
var _monsters: Array = []
var _spikes: Array = []
var _spike_spawn_timer := 0.0
var _close_btn: Button
var _hint_alpha := 1.0
var _invuln_t := 0.0

# LCD layout (screen space)
var _lcd_rect := Rect2()
var _px_scale := 1.0
var _font_hud: Font
var _font_end: Font

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode   = Control.FOCUS_ALL
	grab_focus()

	_font_hud = FontManager.make_font("primary", 700)
	_font_end = FontManager.make_font("primary", 700)

	_reset_monsters()
	_spike_spawn_timer = randf_range(SPIKE_SPAWN_MIN, SPIKE_SPAWN_MAX)
	_recompute_lcd()

	_close_btn = _make_gb_button("Quit")
	_close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_close_btn.pressed.connect(func() -> void: _cancel_puzzle())
	add_child(_close_btn)
	call_deferred("_layout_chrome")

	set_process(true)
	set_process_unhandled_input(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_chrome()


func _layout_chrome() -> void:
	_recompute_lcd()
	_position_close_btn()
	queue_redraw()


func _recompute_lcd() -> void:
	var vw: float = size.x if size.x > 1.0 else get_viewport_rect().size.x
	var vh: float = size.y if size.y > 1.0 else get_viewport_rect().size.y
	# Leave margin for bezel / Quit button
	var max_w := maxf(vw - 48.0, GB_NATIVE_W)
	var max_h := maxf(vh - 48.0, GB_NATIVE_H)
	var scale_x := floori(max_w / GB_NATIVE_W)
	var scale_y := floori(max_h / GB_NATIVE_H)
	var iscale: int = maxi(1, mini(scale_x, scale_y))
	var lw := GB_NATIVE_W * float(iscale)
	var lh := GB_NATIVE_H * float(iscale)
	_lcd_rect = Rect2(
		floorf((vw - lw) * 0.5),
		floorf((vh - lh) * 0.5),
		lw,
		lh
	)
	_px_scale = lw / VIEW_W


func _position_close_btn() -> void:
	if _close_btn == null:
		return
	var vw: float = size.x if size.x > 1.0 else get_viewport_rect().size.x
	# Outside the LCD — top-right bezel margin
	_close_btn.size = Vector2(72.0, 28.0)
	var bx := maxf(_lcd_rect.position.x + _lcd_rect.size.x + 8.0, vw - 80.0)
	var by := maxf(8.0, _lcd_rect.position.y - 36.0)
	if bx + 72.0 > vw - 4.0:
		bx = vw - 76.0
		by = 8.0
	_close_btn.position = Vector2(bx, by)


func _process(delta: float) -> void:
	_time += delta
	if _invuln_t > 0.0:
		_invuln_t = maxf(0.0, _invuln_t - delta)

	if _time > 2.5:
		_hint_alpha = maxf(0.0, _hint_alpha - delta * 0.8)

	if not _done:
		_update_player(delta)
		_update_monsters(delta)
		_update_spikes(delta)
		_update_camera()

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_cancel_puzzle()


# ─────────────────────────────────────────────────────────────
# Lives / reset
# ─────────────────────────────────────────────────────────────

func _reset_monsters() -> void:
	_monsters.clear()
	for def in MONSTER_DEFS:
		_monsters.append({
			"pos":   Vector2(def[2], GROUND_Y - MON_H),
			"dir":   def[3],
			"min_x": def[0],
			"max_x": def[1],
		})


func _respawn_stage() -> void:
	_player_pos = Vector2(START_X, GROUND_Y - PL_H)
	_player_vel = Vector2.ZERO
	_on_ground = false
	_cam_x = 0.0
	_spikes.clear()
	_spike_spawn_timer = randf_range(SPIKE_SPAWN_MIN, SPIKE_SPAWN_MAX)
	_reset_monsters()
	_invuln_t = 1.0


func _on_player_death() -> void:
	if _done or _invuln_t > 0.0:
		return
	_lives -= 1
	SFXManager.play(SFXManager.SFX_CANCEL)
	if _lives <= 0:
		_end_puzzle(false)
	else:
		_respawn_stage()


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
		_on_player_death()
		return

	if _invuln_t <= 0.0:
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
				_on_player_death()
				return

		if _player_hits_spike(pl_l, pl_r, pl_t, pl_b):
			_on_player_death()
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
	_cam_x = clampf(target, 0.0, maxf(0.0, WORLD_W - VIEW_W))


# ─────────────────────────────────────────────────────────────
# Win / Fail / Cancel
# ─────────────────────────────────────────────────────────────

func _cancel_puzzle() -> void:
	if _done:
		return
	_done = true
	_cancelled = true
	_won = false
	if _close_btn != null:
		_close_btn.visible = false
	complete_puzzle(false)


func _end_puzzle(success: bool) -> void:
	if _done:
		return
	_done = true
	_won = success
	if _close_btn != null:
		_close_btn.visible = false

	if success:
		SFXManager.play(SFXManager.SFX_CRYSTAL_GAIN)
	else:
		SFXManager.play(SFXManager.SFX_CANCEL)

	queue_redraw()

	var delay := 1.6 if success else 1.2
	await get_tree().create_timer(delay).timeout
	complete_puzzle(success)


func _make_gb_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 12)
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
# Coordinate mapping (world → pixel-snapped LCD screen)
# ─────────────────────────────────────────────────────────────

func _sx(wx: float) -> float:
	return floorf(_lcd_rect.position.x + (wx - _cam_x) * _px_scale)


func _sy(wy: float) -> float:
	return floorf(_lcd_rect.position.y + wy * _px_scale)


func _ss(v: float) -> float:
	return floorf(v * _px_scale)


func _px_rect(wx: float, wy: float, ww: float, wh: float) -> Rect2:
	var x := _sx(wx)
	var y := _sy(wy)
	var w := maxf(1.0, _ss(ww))
	var h := maxf(1.0, _ss(wh))
	return Rect2(x, y, w, h)


func _fill_px(wx: float, wy: float, ww: float, wh: float, col: Color) -> void:
	draw_rect(_px_rect(wx, wy, ww, wh), col)


func _fill_view(vx: float, vy: float, ww: float, wh: float, col: Color) -> void:
	## View-space fill (already camera-relative; used for parallax clouds).
	var r := Rect2(
		floorf(_lcd_rect.position.x + vx * _px_scale),
		floorf(_lcd_rect.position.y + vy * _px_scale),
		maxf(1.0, floorf(ww * _px_scale)),
		maxf(1.0, floorf(wh * _px_scale))
	)
	draw_rect(r, col)


func _paint_bezel(vw: float, vh: float) -> void:
	## Cover anything that spilled past the LCD edges; draw rim outside only.
	var lx := _lcd_rect.position.x
	var ly := _lcd_rect.position.y
	var lw := _lcd_rect.size.x
	var lh := _lcd_rect.size.y
	draw_rect(Rect2(0.0, 0.0, vw, ly), BEZEL)
	draw_rect(Rect2(0.0, ly + lh, vw, maxf(0.0, vh - ly - lh)), BEZEL)
	draw_rect(Rect2(0.0, ly, lx, lh), BEZEL)
	draw_rect(Rect2(lx + lw, ly, maxf(0.0, vw - lx - lw), lh), BEZEL)
	var g6 := 6.0
	draw_rect(Rect2(lx - g6, ly - g6, lw + g6 * 2.0, g6), BEZEL_RIM)
	draw_rect(Rect2(lx - g6, ly + lh, lw + g6 * 2.0, g6), BEZEL_RIM)
	draw_rect(Rect2(lx - g6, ly, g6, lh), BEZEL_RIM)
	draw_rect(Rect2(lx + lw, ly, g6, lh), BEZEL_RIM)
	var g2 := 2.0
	draw_rect(Rect2(lx - g2, ly - g2, lw + g2 * 2.0, g2), GB3)
	draw_rect(Rect2(lx - g2, ly + lh, lw + g2 * 2.0, g2), GB3)
	draw_rect(Rect2(lx - g2, ly, g2, lh), GB3)
	draw_rect(Rect2(lx + lw, ly, g2, lh), GB3)


# ─────────────────────────────────────────────────────────────
# Drawing
# ─────────────────────────────────────────────────────────────

func _draw() -> void:
	var vw: float = size.x if size.x > 1.0 else get_viewport_rect().size.x
	var vh: float = size.y if size.y > 1.0 else get_viewport_rect().size.y

	# Full bezel first
	draw_rect(Rect2(0.0, 0.0, vw, vh), BEZEL)
	_paint_bezel(vw, vh)

	# Sky fill (whole LCD)
	draw_rect(_lcd_rect, GB0)

	# Clouds: rest positions in view space, parallax
	_draw_cloud(180.0,  72.0)
	_draw_cloud(420.0,  110.0)
	_draw_cloud(680.0,  58.0)
	_draw_cloud(900.0,  95.0)

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

	# Player (blink while invulnerable after respawn)
	if _invuln_t <= 0.0 or int(_time * 10.0) % 2 == 0:
		_draw_player(_player_pos.x, _player_pos.y)

	# Mask spill past LCD, restore bezel + rim
	_paint_bezel(vw, vh)

	# HUD strip (period status bar) — inside LCD
	_draw_hud()

	# Hint fade (drawn in LCD, not a misplaced Label)
	if _hint_alpha > 0.01 and not _done:
		_draw_hint()

	# End overlay centered in LCD (not on ESC/Quit cancel)
	if _done and not _cancelled:
		_draw_end_overlay()


func _draw_hud() -> void:
	var bar := Rect2(
		_lcd_rect.position.x,
		_lcd_rect.position.y,
		_lcd_rect.size.x,
		maxf(1.0, _ss(HUD_H))
	)
	draw_rect(bar, GB1)
	# Bottom hairline
	draw_rect(Rect2(bar.position.x, bar.position.y + bar.size.y - 2.0, bar.size.x, 2.0), GB3)

	var fs := maxi(10, int(round(_px_scale * 18.0)))
	var pad := maxf(4.0, _ss(10.0))
	var ty := bar.position.y + pad * 0.4
	draw_string(_font_hud, Vector2(bar.position.x + pad, ty + float(fs)),
			"STAGE 1-1", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GB3)
	var lives_txt := "×%d" % maxi(0, _lives)
	var lives_w := _font_hud.get_string_size(lives_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(_font_hud, Vector2(bar.position.x + bar.size.x - pad - lives_w, ty + float(fs)),
			lives_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GB3)


func _draw_hint() -> void:
	var fs := maxi(8, int(round(_px_scale * 12.0)))
	var col := Color(GB3.r, GB3.g, GB3.b, _hint_alpha)
	var text := "← → MOVE   ↑ JUMP   ESC QUIT"
	var tw := _font_hud.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var hx := _lcd_rect.position.x + (_lcd_rect.size.x - tw) * 0.5
	var hy := _lcd_rect.position.y + _ss(HUD_H) + _ss(16.0) + float(fs)
	draw_string(_font_hud, Vector2(floorf(hx), floorf(hy)), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_end_overlay() -> void:
	# Dim LCD
	draw_rect(_lcd_rect, Color(GB0.r, GB0.g, GB0.b, 0.35))

	var box_w := _ss(420.0)
	var box_h := _ss(120.0)
	var bx := floorf(_lcd_rect.position.x + (_lcd_rect.size.x - box_w) * 0.5)
	var by := floorf(_lcd_rect.position.y + (_lcd_rect.size.y - box_h) * 0.5)
	var box := Rect2(bx, by, box_w, box_h)

	# Outer dark frame
	draw_rect(box.grow(4.0), GB3)
	draw_rect(box, GB0)
	draw_rect(Rect2(box.position.x + 4.0, box.position.y + 4.0,
			box.size.x - 8.0, box.size.y - 8.0), GB1)
	draw_rect(Rect2(box.position.x + 8.0, box.position.y + 8.0,
			box.size.x - 16.0, box.size.y - 16.0), GB0)

	var msg := "STAGE CLEAR" if _won else "GAME OVER"
	var fs := maxi(14, int(round(_px_scale * 28.0)))
	var tw := _font_end.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tx := floorf(box.position.x + (box.size.x - tw) * 0.5)
	var ty := floorf(box.position.y + (box.size.y + float(fs)) * 0.5 - float(fs) * 0.25)
	draw_string(_font_end, Vector2(tx, ty), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GB3)


# ─── sub-draw helpers ────────────────────────────────────────

func _draw_cloud(rest_x: float, screen_y: float) -> void:
	# rest_x is view-space x at cam_x=0; slides at 15% of camera speed.
	var x := rest_x - _cam_x * 0.15
	if x > VIEW_W + 100.0 or x < -120.0:
		return
	_fill_view(x,        screen_y + 8.0,  68.0, 18.0, GB1)
	_fill_view(x + 8.0,  screen_y,        52.0, 16.0, GB1)
	_fill_view(x + 20.0, screen_y - 10.0, 32.0, 14.0, GB1)


func _draw_ground(world_start: float, world_end: float) -> void:
	var sx := world_start - _cam_x
	var ex := world_end - _cam_x
	if ex < 0.0 or sx > VIEW_W:
		return
	var csx := maxf(sx, 0.0)
	var cex := minf(ex, VIEW_W)
	var w   := cex - csx
	var wx0 := _cam_x + csx

	# Grass top strip
	_fill_px(wx0, GROUND_Y, w, 6.0, GB1)
	# Soil body
	_fill_px(wx0, GROUND_Y + 6.0, w, VIEW_H - GROUND_Y - 6.0, GB2)
	# Top edge line
	_fill_px(wx0, GROUND_Y, w, 2.0, GB3)

	# World-aligned tile dividers
	var first_tx := world_start + fmod(32.0 - fmod(world_start, 32.0), 32.0)
	var tx       := first_tx
	while tx < world_end:
		var stx := tx - _cam_x
		if stx >= csx and stx <= cex:
			_fill_px(tx, GROUND_Y + 6.0, 2.0, 22.0, GB3)
		tx += 32.0


func _draw_platform(world_x: float, world_y: float, w: float, h: float) -> void:
	var x := world_x - _cam_x
	if x + w < 0.0 or x > VIEW_W:
		return
	# Drop shadow
	draw_rect(_px_rect(world_x + 4.0, world_y + h + 1.0, w, 4.0), Color(GB3, 0.5))
	# Body
	_fill_px(world_x, world_y, w, h, GB2)
	# Top highlight
	_fill_px(world_x, world_y, w, 4.0, GB1)
	# Left highlight
	_fill_px(world_x, world_y, 3.0, h, GB1)
	# Bottom shadow
	_fill_px(world_x, world_y + h - 3.0, w, 3.0, GB3)
	# Right shadow
	_fill_px(world_x + w - 3.0, world_y, 3.0, h, GB3)
	# Tile seams
	var tx := world_x + 16.0
	while tx < world_x + w - 4.0:
		_fill_px(tx, world_y + 4.0, 2.0, h - 7.0, GB3)
		tx += 16.0


func _draw_monster(world_x: float, world_y: float, facing_right: bool) -> void:
	var x := world_x - _cam_x
	if x + MON_W < 0.0 or x > VIEW_W:
		return
	var bob: float = floor(sin(_time * 4.2) * 2.0)
	var ry          := world_y + bob

	# Body (approximate rounded rectangle)
	_fill_px(world_x + 3.0, ry + 3.0, MON_W - 6.0, MON_H - 3.0, GB3)
	_fill_px(world_x + 5.0, ry,       MON_W - 10.0, MON_H, GB3)
	_fill_px(world_x + 1.0, ry + 6.0, MON_W - 2.0,  MON_H - 9.0, GB3)

	# Eyes
	_fill_px(world_x + 4.0,  ry + 5.0, 9.0, 8.0, GB0)
	_fill_px(world_x + 15.0, ry + 5.0, 9.0, 8.0, GB0)
	var p_off: float = 2.0 if facing_right else -2.0
	_fill_px(world_x + 4.0  + 2.0 + p_off, ry + 7.0, 4.0, 4.0, GB3)
	_fill_px(world_x + 15.0 + 2.0 + p_off, ry + 7.0, 4.0, 4.0, GB3)

	# Wavy feet
	var ft: float = floor(sin(_time * 7.0))
	for i in range(3):
		var fx := world_x + 3.0 + i * 8.0
		var fh := 4.0 + ft * (1 - 2 * (i % 2))
		_fill_px(fx, ry + MON_H - 3.0, 7.0, fh, GB3)


func _draw_spike(world_x: float, screen_y: float, fallen: bool) -> void:
	var x := world_x - _cam_x
	if x + SPIKE_W < 0.0 or x > VIEW_W:
		return
	var wobble: float = 0.0 if fallen else sin(_time * 9.0 + world_x * 0.05) * 1.5
	var y: float = screen_y + wobble
	var tip := Vector2(_sx(world_x + SPIKE_W * 0.5), _sy(y + SPIKE_H))
	var left := Vector2(_sx(world_x), _sy(y + 4.0))
	var right := Vector2(_sx(world_x + SPIKE_W), _sy(y + 4.0))
	draw_colored_polygon(PackedVector2Array([tip, left, right]), GB3)
	# Inner highlight
	var inner_tip := Vector2(_sx(world_x + SPIKE_W * 0.5), _sy(y + SPIKE_H - 6.0))
	var inner_left := Vector2(_sx(world_x + 5.0), _sy(y + 7.0))
	var inner_right := Vector2(_sx(world_x + SPIKE_W - 5.0), _sy(y + 7.0))
	draw_colored_polygon(PackedVector2Array([inner_tip, inner_left, inner_right]), GB2 if fallen else GB1)
	# Stem when embedded in ground
	if fallen:
		_fill_px(world_x + SPIKE_W * 0.5 - 3.0, y + SPIKE_H - 4.0, 6.0, 6.0, GB3)


func _draw_player(world_x: float, world_y: float) -> void:
	var x := world_x - _cam_x
	if x + PL_W < -10.0 or x > VIEW_W + 10.0:
		return

	var running: bool = _on_ground and absf(_player_vel.x) > 10.0
	var phase   := sin(_time * 10.0) if running else 0.0
	var lp      := int(phase  * 3.0)   # left side phase offset
	var rp      := int(-phase * 3.0)   # right side phase offset (opposite)

	# ── Shoes ────────────────────────────────────────────────
	_fill_px(world_x + 2.0,  world_y + PL_H - 4.0 + lp, 11.0, 5.0, GB3)
	_fill_px(world_x + 15.0, world_y + PL_H - 4.0 + rp, 11.0, 5.0, GB3)

	# ── Legs (gakuran trousers — dark) ───────────────────────
	_fill_px(world_x + 5.0,  world_y + 30.0, 8.0, 10.0 + lp, GB3)
	_fill_px(world_x + 15.0, world_y + 30.0, 8.0, 10.0 + rp, GB3)

	# ── Gakuran jacket body ──────────────────────────────────
	_fill_px(world_x + 4.0, world_y + 17.0, 20.0, 15.0, GB2)
	# Center button-line
	_fill_px(world_x + 12.0, world_y + 17.0, 4.0, 15.0, GB3)
	# Mandarin collar (light)
	_fill_px(world_x + 7.0, world_y + 17.0, 4.0, 5.0, GB1)
	_fill_px(world_x + 17.0, world_y + 17.0, 4.0, 5.0, GB1)

	# ── Arms ─────────────────────────────────────────────────
	_fill_px(world_x,        world_y + 18.0 + lp, 5.0, 12.0, GB2)
	_fill_px(world_x + 23.0, world_y + 18.0 + rp, 5.0, 12.0, GB2)

	# ── Face ─────────────────────────────────────────────────
	_fill_px(world_x + 6.0, world_y + 7.0, 16.0, 12.0, GB1)
	# Eyes
	_fill_px(world_x + 9.0,  world_y + 11.0, 4.0, 3.0, GB3)
	_fill_px(world_x + 16.0, world_y + 11.0, 4.0, 3.0, GB3)

	# ── Backward cap ─────────────────────────────────────────
	_fill_px(world_x + 3.0, world_y + 2.0, 22.0, 8.0, GB3)
	_fill_px(world_x - 3.0, world_y + 6.0, 9.0, 4.0, GB3)
	_fill_px(world_x + 13.0, world_y, 4.0, 4.0, GB3)
	_fill_px(world_x + 21.0, world_y + 8.0, 5.0, 4.0, GB2)


func _draw_flag(world_x: float) -> void:
	var x := world_x - _cam_x
	if x > VIEW_W + 60.0 or x < -60.0:
		return

	# Pole
	_fill_px(world_x - 1.0, FLAG_TOP_Y, 3.0, GROUND_Y - FLAG_TOP_Y, GB3)

	# Pennant (staircase triangle approximation pointing right)
	_fill_px(world_x + 2.0, FLAG_TOP_Y,        36.0, 12.0, GB3)
	_fill_px(world_x + 2.0, FLAG_TOP_Y + 12.0, 24.0, 11.0, GB3)
	_fill_px(world_x + 2.0, FLAG_TOP_Y + 23.0, 14.0, 10.0, GB3)
	# Flag face stripe in GB2
	_fill_px(world_x + 4.0, FLAG_TOP_Y + 2.0,  22.0, 8.0, GB2)

	# Ball at top of pole
	_fill_px(world_x - 5.0, FLAG_TOP_Y - 10.0, 12.0, 12.0, GB3)
	_fill_px(world_x - 3.0, FLAG_TOP_Y - 8.0,   8.0,  8.0, GB1)

	# Pole base block
	_fill_px(world_x - 9.0, GROUND_Y - 14.0, 20.0, 14.0, GB2)
	_fill_px(world_x - 9.0, GROUND_Y - 14.0, 20.0,  3.0, GB3)
