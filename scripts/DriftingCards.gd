extends Node2D

# ─────────────────────────────────────────────────────────────
# Drifting Cards – title screen background animation
# Leaf-in-wind physics:
#   • Angular velocity model  → card tumbles and decelerates
#   • Three incommensurate Y  → no visible sine pattern
#   • Gust modulation on X    → speed lurches, not constant
# ─────────────────────────────────────────────────────────────

const CARD_COUNT := 10
const CARD_W     := 94.0
const CARD_H     := 136.0
const Z_MIN      := 0.22   # card is too far — off camera
const Z_MAX      := 1.65   # card is too close — off camera

const TEX_BACK      := "res://assets/textures/cards/sample/card_back.png"
# Debug build: show card back on both faces (no full-card texture loads).
# Set false before release to restore full-card art on the front face.
const CARD_BACKS_ONLY := true

var _tex_back:    Texture2D = null
var _safe_paths:  Array[String] = []   # one entry per base card (safe art)
var _nsfw_paths:  Array[String] = []   # one entry per base card (nsfw art, or safe fallback)
var _cards:       Array[Dictionary] = []
var _time       := 0.0
var _screen_w   := 1280.0
var _screen_h   := 720.0

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	var sz   := get_viewport_rect().size
	_screen_w = sz.x
	_screen_h = sz.y
	_tex_back = load(TEX_BACK) as Texture2D
	if not CARD_BACKS_ONLY:
		_scan_front_textures()
	_init_cards()
	SaveManager.nsfw_changed.connect(_on_nsfw_changed)
	SaveManager.demo_mode_changed.connect(_on_demo_mode_changed)
	# Pre-simulate 30 s so cards look mid-drift on the very first frame.
	# 150 steps × 0.2 s = 30 s of physics, no rendering cost.
	for _i in 150:
		_tick(0.2)


func _scan_front_textures() -> void:
	_safe_paths.clear()
	_nsfw_paths.clear()

	# Build from CardDatabase + ResourceLoader.exists — DirAccess folder scans
	# often return nothing in exported PCK builds, leaving every face as card_back.
	for cname: String in CardDatabase.characters:
		var cd: CharacterData = CardDatabase.characters[cname] as CharacterData
		if cd.placeholder_art:
			continue
		if SaveManager.demo_mode and not cd.include_in_demo:
			continue
		_append_card_paths(cname)

	for tname: String in CardDatabase.traps:
		var td: TrapData = CardDatabase.traps[tname] as TrapData
		if td.placeholder_art:
			continue
		if SaveManager.demo_mode and not td.include_in_demo:
			continue
		_append_card_paths(tname)

	for ename: String in CardDatabase.tech_cards:
		var ed: TechCardData = CardDatabase.tech_cards[ename] as TechCardData
		if ed.placeholder_art:
			continue
		if SaveManager.demo_mode and not ed.include_in_demo:
			continue
		_append_card_paths(ename)

	_safe_paths.shuffle()
	_nsfw_paths.shuffle()


func _append_card_paths(card_name: String) -> void:
	var safe_path: String = CardDatabase.find_artwork(card_name, "full_cards", false)
	if safe_path == "":
		return
	var nsfw_path: String = CardDatabase.find_artwork(card_name, "full_cards", true)
	_safe_paths.append(safe_path)
	_nsfw_paths.append(nsfw_path if nsfw_path != "" else safe_path)


func _pick_front_tex() -> Texture2D:
	if CARD_BACKS_ONLY:
		return _tex_back
	var pool: Array[String] = _nsfw_paths if SaveManager.nsfw_enabled else _safe_paths
	if pool.is_empty():
		return _tex_back
	for _attempt: int in 8:
		var path: String = pool[randi() % pool.size()]
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			return tex
	return _tex_back


func _on_nsfw_changed(_enabled: bool) -> void:
	if not CARD_BACKS_ONLY:
		_scan_front_textures()
	for card: Dictionary in _cards:
		card["tex_front"] = _pick_front_tex()

func _on_demo_mode_changed(_enabled: bool) -> void:
	if not CARD_BACKS_ONLY:
		_scan_front_textures()
	for card: Dictionary in _cards:
		card["tex_front"] = _pick_front_tex()

func _init_cards() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in CARD_COUNT:
		_cards.append({
			"tex_front":   _pick_front_tex(),
			# ── Flip (continuous slow Y-axis rotation) ───────────
			# flip_angle advances forever; width = abs(cos(flip_angle)).
			# Face is determined by sign of cos — no state machine needed.
			# primary_face = which face shows when cos > 0.
			"primary_face": 1 if i < 2 else 0,
			"flip_angle":  rng.randf_range(0.0, TAU),   # random start phase
			"flip_speed":  rng.randf_range(0.25, 0.55), # rad/s — one full turn every 11-25 s
			# ── Position ─────────────────────────────────────
			"x":           rng.randf_range(-CARD_W, _screen_w),
			"y":           rng.randf_range(0.0, _screen_h),
			"target_y":    rng.randf_range(0.0, _screen_h),
			"card_scale":  rng.randf_range(0.3, 0.8),
			"z_dir":       1 if rng.randf() > 0.5 else -1,
			"z_speed":     rng.randf_range(0.012, 0.035),
			"alpha":       1.0,
			# ── Horizontal gust ──────────────────────────────
			"base_speed":  rng.randf_range(38.0, 88.0),
			"gust_freq":   rng.randf_range(0.12, 0.35),
			"gust_phase":  rng.randf_range(0.0, TAU),
			# ── Vertical turbulence (3 incommensurate sines) ─
			"vy1_amp":     rng.randf_range(28.0, 60.0),
			"vy1_freq":    rng.randf_range(0.18, 0.42),
			"vy1_ph":      rng.randf_range(0.0, TAU),
			"vy2_amp":     rng.randf_range(14.0, 30.0),
			"vy2_freq":    rng.randf_range(0.53, 0.97),
			"vy2_ph":      rng.randf_range(0.0, TAU),
			"vy3_amp":     rng.randf_range(6.0,  16.0),
			"vy3_freq":    rng.randf_range(1.31, 2.70),
			"vy3_ph":      rng.randf_range(0.0, TAU),
			# ── Rotation — angular-velocity model ────────────
			"rot":         rng.randf_range(-PI, PI),
			"rot_vel":     rng.randf_range(-1.2, 1.2),
			"rot_drag":    rng.randf_range(0.20, 0.40),
			"torque_amp":  rng.randf_range(0.4,  1.2),
			"torque_freq": rng.randf_range(0.25, 0.70),
			"torque_ph":   rng.randf_range(0.0, TAU),
		})


func _process(delta: float) -> void:
	_tick(delta)
	queue_redraw()


func _tick(delta: float) -> void:
	_time += delta

	for card: Dictionary in _cards:
		# ── Horizontal (gust) ────────────────────────────────
		var gust := 0.25 + 0.75 * (0.5 + 0.5 * sin(
				(card["gust_freq"] as float) * _time + (card["gust_phase"] as float)))
		card["x"] = (card["x"] as float) + (card["base_speed"] as float) * gust * delta

		# ── Vertical (velocity integration) ──────────────────
		var vy := \
			(card["vy1_amp"] as float) * sin((card["vy1_freq"] as float) * _time + (card["vy1_ph"] as float)) + \
			(card["vy2_amp"] as float) * sin((card["vy2_freq"] as float) * _time + (card["vy2_ph"] as float)) + \
			(card["vy3_amp"] as float) * sin((card["vy3_freq"] as float) * _time + (card["vy3_ph"] as float))
		card["y"] = (card["y"] as float) + vy * delta

		# Soft pull toward this card's own target Y
		var offset := (card["y"] as float) - (card["target_y"] as float)
		card["y"]   = (card["y"] as float) - offset * 1.2 * delta

		# ── Rotation (angular momentum + drag + torque) ──────
		var torque := (card["torque_amp"] as float) * sin(
				(card["torque_freq"] as float) * _time + (card["torque_ph"] as float))
		card["rot_vel"] = (card["rot_vel"] as float) + torque * delta
		card["rot_vel"] = (card["rot_vel"] as float) * pow(card["rot_drag"] as float, delta)
		card["rot"]     = (card["rot"] as float) + (card["rot_vel"] as float) * delta

		# ── Flip (continuous) ────────────────────────────────
		card["flip_angle"] = fmod(
				(card["flip_angle"] as float) + (card["flip_speed"] as float) * delta, TAU)

		# ── Z drift (toward / away from camera) ─────────────
		card["card_scale"] = (card["card_scale"] as float) + \
				(card["z_dir"] as int) * (card["z_speed"] as float) * delta
		if (card["card_scale"] as float) >= Z_MAX:
			# Closest boundary — bounce back toward smaller scale
			card["card_scale"] = Z_MAX
			card["z_dir"]      = -1
		elif (card["card_scale"] as float) <= Z_MIN:
			# Farthest boundary — send off-screen so reset is invisible
			card["z_dir"]      = 1 if randf() > 0.5 else -1
			card["card_scale"] = Z_MIN if (card["z_dir"] as int) == 1 else Z_MAX
			card["x"]          = -(CARD_W * (card["card_scale"] as float) + 24.0)
			var new_y: float   = randf_range(0.0, _screen_h)
			card["y"]          = new_y
			card["target_y"]   = new_y
			card["tex_front"]  = _pick_front_tex()

		# ── Wrap off right edge ───────────────────────────────
		var edge := CARD_W * (card["card_scale"] as float) + 24.0
		if (card["x"] as float) > _screen_w + edge:
			card["x"]          = -edge
			var new_y: float   = randf_range(0.0, _screen_h)
			card["y"]          = new_y
			card["target_y"]   = new_y
			card["vy1_ph"]     = randf() * TAU
			card["vy2_ph"]     = randf() * TAU
			card["vy3_ph"]     = randf() * TAU
			card["gust_phase"] = randf() * TAU
			card["torque_ph"]  = randf() * TAU
			card["rot_vel"]    = randf_range(-1.2, 1.2)
			card["z_dir"]      = 1 if randf() > 0.5 else -1
			card["tex_front"]  = _pick_front_tex()


func _draw() -> void:
	var sorted := _cards.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["card_scale"] as float) < (b["card_scale"] as float))
	for card: Dictionary in sorted:
		var flip_cos: float = cos(card["flip_angle"] as float)
		# cos > 0 → primary face; cos < 0 → alternate face
		var show_primary: bool = flip_cos >= 0.0
		var tex: Texture2D = _tex_back
		if not CARD_BACKS_ONLY:
			var is_front: bool = show_primary == ((card["primary_face"] as int) == 1)
			tex = (card["tex_front"] as Texture2D) if is_front else _tex_back
		if tex == null:
			continue

		var s: float = card["card_scale"]
		var w: float = CARD_W * s * absf(flip_cos)
		var h: float = CARD_H * s

		draw_set_transform(Vector2(card["x"], card["y"]), card["rot"], Vector2.ONE)
		draw_texture_rect(tex, Rect2(-w * 0.5, -h * 0.5, w, h), false,
				Color(1.0, 1.0, 1.0, card["alpha"]))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
