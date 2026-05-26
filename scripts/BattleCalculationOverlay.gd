class_name BattleCalculationOverlay
extends Control
## Damage calculation phase overlay.
## Shows both cards side-by-side with animated battle outcome.
## Usage: await overlay.start(...) — the coroutine handles everything including queue_free.

const VELLUM_FRAME    := preload("res://assets/textures/cards/frames/vellum_card_frame_transparent.png")
const ART_PLACEHOLDER := preload("res://assets/textures/cards/placeholder.png")
const CHIVO_FONT      := preload("res://assets/fonts/Chivo-VariableFont_wght.ttf")
const SFX_CLANK       := preload("res://assets/audio/sound_axe1.mp3")
const SFX_GEAR        := preload("res://assets/audio/sound_sledgehammer1.mp3")
const SFX_SHATTER     := preload("res://assets/audio/sfx/ceramic.mp3")
const SFX_SWOOSH      := preload("res://assets/audio/sound_swoosh_2.mp3")
const SFX_SPELL       := preload("res://assets/audio/sound_spellcasting_2.mp3")

# Card layout constants (mirrors CardDetailOverlay)
const FRAME_ASPECT := 819.0 / 1126.0
const ART_L_PCT    := 0.051
const ART_R_PCT    := 0.949
const ART_T_PCT    := 0.096
const INFO_TOP_PCT := 0.520
const BADGE_H      := 56.0   # height of the stat badge strip above each card

const TYPE_COLOR_CHARACTER := Color(1.0, 0.71, 0.2, 1.0)
const TYPE_COLOR_TRAP      := Color(1.0, 0.263, 0.345, 1.0)
const TYPE_COLOR_TECH      := Color(0.18, 0.764, 0.341, 1.0)

const ICON_ATTACK := preload("res://assets/textures/ui/decorations/ui_context_menu_attack.png")
const ICON_DEFEND := preload("res://assets/textures/ui/decorations/ui_icon_defend.png")
const ICON_TRAP := preload("res://assets/textures/ui/decorations/ui_icon_trap.png")
const ICON_BLANK := preload("res://assets/textures/ui/decorations/ui_icon_blank_found.png")


var _left_ctrl:  Control  # P1 slot (always left)
var _right_ctrl: Control  # P2 slot (always right)
var _left_rest_x:  float
var _right_rest_x: float
var _card_w: float
var _card_h: float
var _skip_requested: bool = false
var _skippable:     bool = false
# Pause/resume support: set via pause_for_choice() / resume_with_result()
var _paused: bool = false
var _live_result: BattleResolver.BattleResult

## Called by GameBoard when an ability-choice overlay appears on top of this overlay.
## Prevents the overlay from animating or being dismissed until resume_with_result() is called.
## Also disables mouse blocking so the choice overlay above can receive clicks.
func pause_for_choice() -> void:
	_paused = true
	mouse_filter = MOUSE_FILTER_IGNORE

## Called by GameBoard after the ability choice is resolved.
## Updates the animation result to reflect any applied boosts, then unpauses.
func resume_with_result(new_result: BattleResolver.BattleResult) -> void:
	_live_result = new_result
	_paused = false
	mouse_filter = MOUSE_FILTER_STOP

# ─────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────
func start(
	attacker_player: int,
	attacker: GameState.CardInstance,
	defender: GameState.CardInstance,
	result: BattleResolver.BattleResult
) -> void:
	AudioManager.apply_high_pass(true)
	_build_ui(attacker_player, attacker, defender, result)
	await _run_async(attacker_player, attacker, defender, result)
	AudioManager.remove_bgm_filter(true)

# ─────────────────────────────────────────────────────────────
# UI construction
# ─────────────────────────────────────────────────────────────
func _build_ui(
	attacker_player: int,
	attacker: GameState.CardInstance,
	defender: GameState.CardInstance,
	result: BattleResolver.BattleResult
) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.96)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var vp := get_viewport().get_visible_rect().size
	_card_h = minf(vp.y * 0.72, (vp.x * 0.40) / FRAME_ASPECT)
	_card_w = _card_h * FRAME_ASPECT

	var gap      := maxf(vp.x * 0.07, 60.0)
	var total_w  := _card_w * 2.0 + gap
	var origin_x := (vp.x - total_w) * 0.5
	var origin_y := (vp.y - (_card_h + BADGE_H)) * 0.5

	_left_rest_x  = origin_x
	_right_rest_x = origin_x + _card_w + gap

	# P1 always left, P2 always right
	var left_inst:   GameState.CardInstance = attacker if attacker_player == 0 else defender
	var right_inst:  GameState.CardInstance = defender if attacker_player == 0 else attacker
	var left_is_attacker: bool = attacker_player == 0

	# Deltas: attacker shows ATK delta, defender shows DEF delta
	var left_atk_delta:  int = result.attacker_atk_delta if left_is_attacker else result.defender_atk_delta
	var left_def_delta:  int = result.attacker_def_delta if left_is_attacker else result.defender_def_delta
	var right_atk_delta: int = result.defender_atk_delta if left_is_attacker else result.attacker_atk_delta
	var right_def_delta: int = result.defender_def_delta if left_is_attacker else result.attacker_def_delta

	_left_ctrl = _build_slot(left_inst, left_is_attacker, left_atk_delta, left_def_delta)
	_left_ctrl.position = Vector2(_left_rest_x, origin_y)
	add_child(_left_ctrl)

	_right_ctrl = _build_slot(right_inst, not left_is_attacker, right_atk_delta, right_def_delta)
	_right_ctrl.position = Vector2(_right_rest_x, origin_y)
	add_child(_right_ctrl)

	modulate.a = 0.0

func _build_slot(inst: GameState.CardInstance, is_attacker: bool, atk_delta: int = 0, def_delta: int = 0) -> Control:
	var slot := Control.new()
	slot.size = Vector2(_card_w, BADGE_H + _card_h)
	slot.mouse_filter = MOUSE_FILTER_IGNORE

	# Stat badge above card — icon + number, centred
	var badge := CenterContainer.new()
	badge.position = Vector2(0.0, 0.0)
	badge.size = Vector2(_card_w, BADGE_H)
	badge.mouse_filter = MOUSE_FILTER_IGNORE

	#if inst.card_type != "dead_end":
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(_card_w * 0.04))
	row.mouse_filter = MOUSE_FILTER_IGNORE

	var icon := TextureRect.new()
	var icon_size := int(BADGE_H * 0.72)
	
	if inst.card_type == "trap":
		icon.texture = ICON_TRAP
	elif inst.card_type == "dead_end": 
		icon.texture = ICON_BLANK
	else	:
		icon.texture = ICON_ATTACK if is_attacker else ICON_DEFEND
	
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(icon)

	if inst.card_type != "trap" and inst.card_type != "dead_end":
		var num_lbl := Label.new()
		var stat_val: int = inst.get_effective_atk() if is_attacker else inst.get_effective_def()
		num_lbl.text = str(stat_val)
		num_lbl.add_theme_font_override("font", CHIVO_FONT)
		num_lbl.add_theme_font_size_override("font_size", int(_card_w * 0.10))
		var lbl_color := Color(1.0, 0.62, 0.30) if is_attacker else Color(0.38, 0.68, 1.0)
		num_lbl.add_theme_color_override("font_color", lbl_color)
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_lbl.mouse_filter = MOUSE_FILTER_IGNORE
		row.add_child(num_lbl)
	badge.add_child(row)
	slot.add_child(badge)

	# Card visual
	var card_ctrl := Control.new()
	card_ctrl.position = Vector2(0.0, BADGE_H)
	card_ctrl.size = Vector2(_card_w, _card_h)
	card_ctrl.clip_contents = true
	card_ctrl.mouse_filter = MOUSE_FILTER_IGNORE
	var art_tex: Texture2D = _build_card_visual(card_ctrl, inst)
	slot.set_meta("art_tex", art_tex)
	slot.set_meta("card_type_str", inst.card_type)
	slot.add_child(card_ctrl)

	# Stat delta overlay (only for character cards with non-zero deltas)
	if inst.card_type == "character":
		_add_stat_deltas(card_ctrl, atk_delta, def_delta)

	return slot

func _build_card_visual(parent: Control, inst: GameState.CardInstance) -> Texture2D:
	if inst.card_type == "dead_end":
		var img := TextureRect.new()
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_SCALE
		img.texture = load("res://assets/textures/cards/full_cards/blank.png")
		img.mouse_filter = MOUSE_FILTER_IGNORE
		parent.add_child(img)
		return ART_PLACEHOLDER

	var cw := _card_w
	var ch := _card_h
	var al := ART_L_PCT * cw
	var ar := ART_R_PCT * cw
	var at := ART_T_PCT * ch
	var aw := ar - al
	var ah := ch - at

	# Art background
	var art_bg := ColorRect.new()
	art_bg.position = Vector2(al, at)
	art_bg.size = Vector2(aw, ah)
	art_bg.color = Color(0.04, 0.04, 0.06)
	art_bg.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(art_bg)

	# Art texture
	var art := TextureRect.new()
	art.position = Vector2(al, at)
	art.size = Vector2(aw, ah)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(art)

	var art_path := ""
	match inst.card_type:
		"character": art_path = CardDatabase.find_artwork(inst.card_name, "characters")
		"trap":      art_path = CardDatabase.find_artwork(inst.card_name, "traps")
		"tech":      art_path = CardDatabase.find_artwork(inst.card_name, "tech")
	if inst.is_union:
		var _snake: String = inst.card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
		for _p: String in [
			"res://assets/textures/cards/union/" + _snake + ".png",
		]:
			if ResourceLoader.exists(_p):
				art_path = _p
				break
	if art_path != "" and ResourceLoader.exists(art_path):
		art.texture = load(art_path)
	else:
		art.texture = ART_PLACEHOLDER

	# Vellum frame (drawn above art)
	var frame := TextureRect.new()
	frame.position = Vector2.ZERO
	frame.size = Vector2(cw, ch)
	frame.texture = VELLUM_FRAME
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	if inst.card_type == "trap":
		frame.modulate = Color(1.0, 0.65, 0.65)
	elif inst.card_type == "tech":
		frame.modulate = Color(0.65, 1.0, 0.65)
	parent.add_child(frame)

	# Header
	var hdr_h  := at
	var fsz_hdr := maxi(int(cw * 0.044), 10)
	var pad_x   := al + 10.0

	var type_lbl := Label.new()
	type_lbl.position = Vector2(pad_x, hdr_h * 0.2)
	type_lbl.size = Vector2(cw * 0.60, hdr_h * 0.7)
	type_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", fsz_hdr)
	type_lbl.add_theme_font_override("font", CHIVO_FONT)
	parent.add_child(type_lbl)

	var cost_lbl := Label.new()
	cost_lbl.position = Vector2(cw * 0.70, hdr_h * 0.26)
	cost_lbl.size = Vector2(cw * 0.24, hdr_h * 0.62)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", fsz_hdr)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	cost_lbl.add_theme_font_override("font", CHIVO_FONT)
	parent.add_child(cost_lbl)

	# Info section
	var info_y  := INFO_TOP_PCT * ch
	var info_h  := ch - info_y
	var fsz_name := maxi(int(cw * 0.04), 5)
	var fsz_stat := maxi(int(cw * 0.035), 3)
	var fsz_desc := maxi(int(cw * 0.035), 3)

	var name_lbl := Label.new()
	name_lbl.position = Vector2(pad_x, info_y + info_h * 0.45)
	name_lbl.size = Vector2(cw - pad_x * 2.0, info_h * 0.34)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", fsz_name)
	name_lbl.add_theme_font_override("font", CHIVO_FONT)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	parent.add_child(name_lbl)

	var stats_y := info_y + info_h * 0.67
	var stats_h := info_h * 0.07
	var pill_w  := cw * 0.16

	var atk_lbl := Label.new()
	atk_lbl.position = Vector2(pad_x, stats_y)
	atk_lbl.size = Vector2(pill_w, stats_h)
	atk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atk_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	atk_lbl.add_theme_font_size_override("font_size", fsz_stat)
	atk_lbl.add_theme_color_override("font_color", Color(1.0, 0.62, 0.30))
	atk_lbl.add_theme_font_override("font", CHIVO_FONT)
	parent.add_child(atk_lbl)

	var def_lbl := Label.new()
	def_lbl.position = Vector2(pad_x + pill_w + 5.0, stats_y)
	def_lbl.size = Vector2(pill_w, stats_h)
	def_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	def_lbl.add_theme_font_size_override("font_size", fsz_stat)
	def_lbl.add_theme_color_override("font_color", Color(0.38, 0.68, 1.0))
	def_lbl.add_theme_font_override("font", CHIVO_FONT)
	parent.add_child(def_lbl)

	var aff_lbl := Label.new()
	aff_lbl.position = Vector2(pad_x, stats_y - 40.0)
	aff_lbl.size = Vector2(cw - pad_x * 2.0, stats_h)
	aff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	aff_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aff_lbl.add_theme_font_size_override("font_size", fsz_stat + 10)
	aff_lbl.add_theme_font_override("font", CHIVO_FONT)
	parent.add_child(aff_lbl)

	var desc_lbl := Label.new()
	desc_lbl.position = Vector2(pad_x, info_y + info_h * 0.76)
	desc_lbl.size = Vector2(cw - pad_x * 2.0, info_h * 0.23)
	desc_lbl.add_theme_font_size_override("font_size", fsz_desc)
	desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc_lbl.add_theme_font_override("font", CHIVO_FONT)
	parent.add_child(desc_lbl)

	# Populate
	match inst.card_type:
		"character":
			var data: CharacterData = CardDatabase.get_character(inst.card_name)
			cost_lbl.text = "%d◆" % inst.crystal_cost
			name_lbl.text = inst.card_name
			if inst.is_union:
				const UNION_CYAN: Color = Color(0.25, 0.90, 1.00)
				type_lbl.text = "UNION"
				type_lbl.add_theme_color_override("font_color", UNION_CYAN)
				var u: UnionData = UnionDatabase.get_union(inst.card_name)
				if u:
					atk_lbl.text = "ATK %d" % inst.get_effective_atk()
					def_lbl.text = "DEF %d" % inst.get_effective_def()
					var aff_keys: Array = CharacterData.Affinity.keys()
					var aff_idx: int = int(u.affinity)
					aff_lbl.text = aff_keys[aff_idx].capitalize() if aff_idx < aff_keys.size() else ""
					aff_lbl.add_theme_color_override("font_color", UNION_CYAN)
					desc_lbl.text = u.ability_description
			else:
				type_lbl.text = "CHARACTER"
				type_lbl.add_theme_color_override("font_color", TYPE_COLOR_CHARACTER)
				if data:
					atk_lbl.text = "ATK %d" % inst.get_effective_atk()
					def_lbl.text = "DEF %d" % inst.get_effective_def()
					var aff_name: String = CharacterData.Affinity.keys()[inst.affinity].capitalize()
					aff_lbl.text = aff_name
					aff_lbl.add_theme_color_override("font_color", TYPE_COLOR_CHARACTER)
					desc_lbl.text = data.get_ability_description()
			_style_pill(atk_lbl, Color(0.75, 0.28, 0.05), Color(1.0, 0.55, 0.28))
			_style_pill(def_lbl, Color(0.08, 0.28, 0.70), Color(0.35, 0.62, 1.0))
		"trap":
			var data: TrapData = CardDatabase.get_trap(inst.card_name)
			type_lbl.text = "TRAP"
			type_lbl.add_theme_color_override("font_color", TYPE_COLOR_TRAP)
			cost_lbl.text = "%d◆" % inst.crystal_cost
			name_lbl.text = inst.card_name
			if data:
				desc_lbl.text = data.get_effect_description()
				desc_lbl.position = Vector2(pad_x, info_y + info_h * 0.67)
				desc_lbl.size = Vector2(cw - pad_x * 2.0, info_h * 0.32)
		"tech":
			var data: TechCardData = CardDatabase.get_tech(inst.card_name)
			type_lbl.text = "TECH"
			type_lbl.add_theme_color_override("font_color", TYPE_COLOR_TECH)
			cost_lbl.text = "%d◆" % inst.crystal_cost
			name_lbl.text = inst.card_name
			if data:
				desc_lbl.text = data.get_effect_description()
				desc_lbl.position = Vector2(pad_x, info_y + info_h * 0.67)
				desc_lbl.size = Vector2(cw - pad_x * 2.0, info_h * 0.32)
	return art.texture if art.texture != null else ART_PLACEHOLDER

## Show stacked green/red delta labels at the bottom-right of the card art area.
## Each non-zero delta gets its own Label plus a crystal-indicator-style burst ghost.
func _add_stat_deltas(card_ctrl: Control, atk_delta: int, def_delta: int) -> void:
	var al := ART_L_PCT * _card_w
	var at := ART_T_PCT * _card_h
	var aw := (ART_R_PCT - ART_L_PCT) * _card_w
	var ah := _card_h - at

	var fsz := maxi(int(_card_w * 0.055), 9)
	var lbl_w := _card_w * 0.32
	var lbl_h := float(fsz) * 1.6

	var deltas: Array[int] = []
	var labels_str: Array[String] = []
	if atk_delta != 0:
		deltas.append(atk_delta)
		labels_str.append(("+" if atk_delta > 0 else "") + "ATK %d" % atk_delta)
	if def_delta != 0:
		deltas.append(def_delta)
		labels_str.append(("+" if def_delta > 0 else "") + "DEF %d" % def_delta)

	for i in range(deltas.size()):
		var delta_val: int = deltas[i]
		var lbl := Label.new()
		lbl.text = labels_str[i]
		lbl.add_theme_font_override("font", CHIVO_FONT)
		lbl.add_theme_font_size_override("font_size", fsz)
		var col: Color = Color(0.35, 1.0, 0.45) if delta_val > 0 else Color(1.0, 0.35, 0.35)
		lbl.add_theme_color_override("font_color", col)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = MOUSE_FILTER_IGNORE
		# Stack from bottom of art area upward
		var stack_offset: float = float(deltas.size() - 1 - i) * (lbl_h + 2.0)
		lbl.position = Vector2(al + aw - lbl_w, at + ah - lbl_h - stack_offset)
		lbl.size = Vector2(lbl_w, lbl_h)
		card_ctrl.add_child(lbl)
		_play_stat_burst(lbl)

func _play_stat_burst(lbl: Label) -> void:
	# Delay to match overlay fade-in (0.25 s), then fire crystal-indicator-style burst
	await get_tree().create_timer(0.28).timeout
	if not is_instance_valid(lbl):
		return
	var ghost: Label = lbl.duplicate() as Label
	ghost.pivot_offset = ghost.size * 0.5
	lbl.get_parent().add_child(ghost)
	ghost.position = lbl.position
	ghost.z_index = 4
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ghost, "scale", Vector2(2.4, 2.4), 0.42) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.42) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished
	if is_instance_valid(ghost):
		ghost.queue_free()

func _style_pill(lbl: Label, bg_col: Color, border_col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg_col.r, bg_col.g, bg_col.b, 0.28)
	sb.border_color = border_col
	sb.border_width_left   = 2; sb.border_width_right  = 2
	sb.border_width_top    = 2; sb.border_width_bottom = 2
	sb.corner_radius_top_left    = 5; sb.corner_radius_top_right   = 5
	sb.corner_radius_bottom_left = 5; sb.corner_radius_bottom_right = 5
	sb.content_margin_left = 6;  sb.content_margin_right  = 6
	sb.content_margin_top  = 2;  sb.content_margin_bottom = 2
	lbl.add_theme_stylebox_override("normal", sb)

# ─────────────────────────────────────────────────────────────
# Async flow
# ─────────────────────────────────────────────────────────────
func _run_async(
	attacker_player: int,
	attacker: GameState.CardInstance,
	defender: GameState.CardInstance,
	result: BattleResolver.BattleResult
) -> void:
	# Initialise _live_result from the preview passed in; may be updated via resume_with_result()
	_live_result = result

	# Fade in
	var tin := create_tween()
	tin.tween_property(self, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tin.finished

	# Wait for any pending ability-choice overlays (pause_for_choice set _paused = true)
	while _paused:
		_skip_requested = false  # don't let a stray click skip while choice is active
		await get_tree().process_frame

	# _live_result is now final — pre-build triangle fragments only for the card(s) that
	# will actually be destroyed.  This is synchronous and completes before any animation,
	# using the ~2-second display pause as free build time.
	var _att_pre: Control = _left_ctrl  if attacker_player == 0 else _right_ctrl
	var _def_pre: Control = _right_ctrl if attacker_player == 0 else _left_ctrl
	match _get_scenario(defender, _live_result):
		"3A":
			_prebuild_tri_polys(_def_pre)
		"3B":
			_prebuild_tri_polys(_att_pre)
		"3C":
			_prebuild_tri_polys(_att_pre)
			_prebuild_tri_polys(_def_pre)
		"3E":
			_prebuild_tri_polys(_att_pre)

	# Skippable 2-second pause
	_skippable = true
	var start_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_ms < 2000 and not _skip_requested:
		await get_tree().process_frame
	_skippable = false
	_skip_requested = false

	# Determine attacker/defender controls and bounce direction
	var att_ctrl: Control = _left_ctrl  if attacker_player == 0 else _right_ctrl
	var def_ctrl: Control = _right_ctrl if attacker_player == 0 else _left_ctrl
	# Positive dx means move right (toward center for P1 attacker)
	var bounce_dx: float = _card_w * 0.28 * (1.0 if attacker_player == 0 else -1.0)

	# Card effect flash — trap or character ability (use _live_result for final outcome)
	var att_rest_x: float = _left_rest_x if attacker_player == 0 else _right_rest_x
	var def_rest_x: float = _right_rest_x if attacker_player == 0 else _left_rest_x
	# Skip ability flash for trap encounters — the burst is embedded inside the scenario
	# animation (fires after the bounce), so running it here would move the attacker twice.
	if _live_result.special_trigger not in ["trap_effect", "trap_nullified"]:
		if _live_result.ability_triggered_attacker:
			await _animate_card_effect_flash(att_ctrl, att_rest_x)
		elif _live_result.ability_triggered_defender:
			await _animate_card_effect_flash(def_ctrl, def_rest_x)

	# Run scenario animation using the final (possibly boosted) result
	var scenario := _get_scenario(defender, _live_result)
	match scenario:
		"3A": await _anim_attacker_wins(att_ctrl, def_ctrl, bounce_dx)
		"3B": await _anim_defender_wins(att_ctrl, def_ctrl, bounce_dx)
		"3C": await _anim_tie(att_ctrl, def_ctrl, bounce_dx)
		"3D": await _anim_trap_survives(att_ctrl, def_ctrl, bounce_dx)
		"3E": await _anim_trap_destroys(att_ctrl, def_ctrl, bounce_dx)
		"3F": await _anim_blank(att_ctrl, def_ctrl, bounce_dx)
		_:    await _anim_exchange(att_ctrl, def_ctrl, bounce_dx)

	# Brief hold then fade out
	await get_tree().create_timer(0.2).timeout
	var tout := create_tween()
	tout.tween_property(self, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tout.finished

	queue_free()

func _get_scenario(defender: GameState.CardInstance, result: BattleResolver.BattleResult) -> String:
	# Check special_trigger FIRST — defender.card_type may read as "dead_end" if the
	# CardInstance was modified in-place after destruction, causing the dead_end guard
	# below to short-circuit before we reach the trap checks.
	if result.special_trigger == "trap_nullified":
		return "3D"
	if result.special_trigger == "trap_effect":
		# result.attacker_destroyed is NOT set by BattleResolver for traps —
		# the actual destruction happens in TurnManager._handle_trap_effect() AFTER
		# the overlay finishes.  Check the trap_data directly to determine if
		# this trap type destroys the attacker.
		var _trap_data: Variant = result.special_params.get("trap_data", null)
		if _trap_data is TrapData:
			var td: TrapData = _trap_data as TrapData
			if td.effect_type in [
				TrapData.TrapEffectType.DESTROY_ATTACKER,
				TrapData.TrapEffectType.DESTROY_ATTACKER_CHOICE_DESTROY,
				TrapData.TrapEffectType.DESTROY_ATTACKER_DEFENDER_PAYS,
			]:
				return "3E"
		return "3D"
	if defender.card_type == "dead_end":
		return "3F"
	if defender.card_type == "trap":
		return "3E" if result.attacker_destroyed else "3D"
	if result.attacker_destroyed and result.defender_destroyed:
		return "3C"
	if result.defender_destroyed:
		return "3A"
	if result.attacker_destroyed:
		return "3B"
	return "exchange"

# ─────────────────────────────────────────────────────────────
# Animation primitives
# ─────────────────────────────────────────────────────────────
func _play_sfx(stream: AudioStream) -> void:
	var asp := AudioStreamPlayer.new()
	asp.stream = stream
	asp.bus = "SFX"
	add_child(asp)
	asp.play()
	asp.finished.connect(asp.queue_free)

func _animate_card_effect_flash(ctrl: Control, rest_x: float) -> void:
	_play_sfx(SFX_SPELL)
	var vp_size := get_viewport().get_visible_rect().size
	var center_x := (vp_size.x - _card_w) * 0.5
	# Move card to center
	var t_in := create_tween()
	t_in.tween_property(ctrl, "position:x", center_x, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await t_in.finished
	# Burst ring + flash
	_play_burst_ring(ctrl)
	_flash_white(ctrl)
	_flash_screen_white()
	# Linger
	await get_tree().create_timer(1.0).timeout
	# Move back
	var t_out := create_tween()
	t_out.tween_property(ctrl, "position:x", rest_x, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await t_out.finished

func _animate_trap_flash(ctrl: Control) -> void:
	_play_sfx(SFX_SPELL)
	_play_burst_ring(ctrl)
	_flash_white(ctrl)
	_flash_screen_white()
	await get_tree().create_timer(1.0).timeout

func _play_burst_ring(ctrl: Control) -> void:
	var ring := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	sb.border_color = Color(1.0, 0.95, 0.6, 0.9)
	var bw: int = 8
	sb.border_width_left = bw; sb.border_width_right  = bw
	sb.border_width_top  = bw; sb.border_width_bottom = bw
	var r: int = 20
	sb.corner_radius_top_left = r; sb.corner_radius_top_right  = r
	sb.corner_radius_bottom_left = r; sb.corner_radius_bottom_right = r
	ring.add_theme_stylebox_override("panel", sb)
	ring.size = Vector2(_card_w, BADGE_H + _card_h)
	ring.position = ctrl.position
	ring.pivot_offset = ring.size * 0.5
	ring.mouse_filter = MOUSE_FILTER_IGNORE
	ring.z_index = 5
	add_child(ring)
	var t := create_tween()
	t.tween_property(ring, "scale", Vector2(1.6, 1.6), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.parallel().tween_property(ring, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(ring.queue_free)

func _flash_screen_white() -> void:
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 1.0, 1.0, 0.0)
	flash.mouse_filter = MOUSE_FILTER_IGNORE
	flash.z_index = 10
	add_child(flash)
	var t := create_tween()
	t.tween_property(flash, "color:a", 0.65, 0.06).set_trans(Tween.TRANS_LINEAR)
	t.tween_property(flash, "color:a", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(flash.queue_free)

func _bounce_forward(ctrl: Control, dx: float) -> void:
	var t := create_tween()
	t.tween_property(ctrl, "position:x", ctrl.position.x + dx, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await t.finished

func _bounce_back(ctrl: Control, rest_x: float) -> void:
	var t := create_tween()
	t.tween_property(ctrl, "position:x", rest_x, 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	await t.finished

func _flash_white(ctrl: Control) -> void:
	var t := create_tween()
	t.tween_property(ctrl, "modulate", Color(2.5, 2.5, 2.5, 1.0), 0.06).set_trans(Tween.TRANS_LINEAR)
	t.tween_property(ctrl, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await t.finished

func _shatter(ctrl: Control) -> void:
	_play_sfx(SFX_SHATTER)
	ctrl.pivot_offset = Vector2(_card_w * 0.5, (BADGE_H + _card_h) * 0.5)
	var t := create_tween()
	t.parallel().tween_property(ctrl, "scale", Vector2(1.18, 1.18), 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.parallel().tween_property(ctrl, "modulate:a", 0.0, 0.32).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await t.finished

## Always use triangle fragmentation — _shatter_triangles falls back to _shatter
## if tri_levels was not pre-built.
func _destroy_card(ctrl: Control) -> void:
	await _shatter_triangles(ctrl)

## Pre-builds all 4 triangle subdivision levels for a character slot.
## Caller is responsible for only passing character slots.
func _prebuild_tri_polys(slot: Control) -> void:
	var art_tex_meta: Variant = slot.get_meta("art_tex", ART_PLACEHOLDER)
	var tex: Texture2D = art_tex_meta as Texture2D
	if tex == null:
		tex = ART_PLACEHOLDER
	var tex_w: float = float(tex.get_width())
	var tex_h: float = float(tex.get_height())
	if tex_w < 1.0 or tex_h < 1.0:
		tex = ART_PLACEHOLDER
		tex_w = float(tex.get_width())
		tex_h = float(tex.get_height())

	var ax: float = slot.position.x + ART_L_PCT * _card_w
	var ay: float = slot.position.y + BADGE_H + ART_T_PCT * _card_h
	var aw: float = (ART_R_PCT - ART_L_PCT) * _card_w
	var ah: float = (1.0 - ART_T_PCT) * _card_h

	var tl := Vector2(ax,      ay)
	var tr := Vector2(ax + aw, ay)
	var br := Vector2(ax + aw, ay + ah)
	var bl := Vector2(ax,      ay + ah)
	var uv_tl := Vector2(0.0,   0.0)
	var uv_tr := Vector2(tex_w, 0.0)
	var uv_br := Vector2(tex_w, tex_h)
	var uv_bl := Vector2(0.0,   tex_h)

	var triangles: Array = [
		[PackedVector2Array([tl, tr, br]), PackedVector2Array([uv_tl, uv_tr, uv_br])],
		[PackedVector2Array([tl, br, bl]), PackedVector2Array([uv_tl, uv_br, uv_bl])],
	]

	# levels[i] = Array of Polygon2D for subdivision level i (2/8/32/128 polys)
	var levels: Array = []

	for _level: int in range(4):
		var level_polys: Array = []
		for tri: Variant in triangles:
			var arr: Array  = tri as Array
			var verts: PackedVector2Array = arr[0] as PackedVector2Array
			var uvs: PackedVector2Array   = arr[1] as PackedVector2Array
			var cx: float = (verts[0].x + verts[1].x + verts[2].x) / 3.0
			var cy: float = (verts[0].y + verts[1].y + verts[2].y) / 3.0
			var centroid := Vector2(cx, cy)
			var local_verts := PackedVector2Array()
			for v: Vector2 in verts:
				local_verts.append(v.lerp(centroid, 0.03) - centroid)
			var poly := Polygon2D.new()
			poly.texture = tex
			poly.polygon = local_verts
			poly.uv      = uvs
			poly.position = centroid
			poly.z_index  = 20
			poly.visible  = false   # hidden until _shatter_triangles activates this level
			add_child(poly)
			level_polys.append(poly)
		levels.append(level_polys)

		if _level < 3:
			var next_tris: Array = []
			for tri: Variant in triangles:
				var arr: Array = tri as Array
				for sub: Variant in _subdivide_triangle(
						arr[0] as PackedVector2Array,
						arr[1] as PackedVector2Array):
					next_tris.append(sub)
			triangles = next_tris

	slot.set_meta("tri_levels", levels)

## Triangle fragmentation destruction for character cards.
## All Polygon2D nodes were pre-built in _prebuild_tri_polys — this function only
## toggles visibility and runs tweens, so there is no instantiation delay.
func _shatter_triangles(ctrl: Control) -> void:
	_play_sfx(SFX_SHATTER)
	ctrl.modulate.a = 0.0

	var levels_meta: Variant = ctrl.get_meta("tri_levels", [])
	var levels: Array = levels_meta as Array
	if levels.is_empty():
		# Prebuild didn't run — build synchronously now so the animation still plays.
		_prebuild_tri_polys(ctrl)
		levels_meta = ctrl.get_meta("tri_levels", [])
		levels = levels_meta as Array
	if levels.is_empty():
		await _shatter(ctrl)  # true fallback — prebuild failed entirely
		return

	var ax: float = ctrl.position.x + ART_L_PCT * _card_w
	var ay: float = ctrl.position.y + BADGE_H + ART_T_PCT * _card_h
	var aw: float = (ART_R_PCT - ART_L_PCT) * _card_w
	var ah: float = (1.0 - ART_T_PCT) * _card_h

	# Cycle through subdivision levels: show current, hide previous
	for level_idx: int in range(levels.size()):
		var cur: Array = levels[level_idx] as Array
		for p: Variant in cur:
			var poly: Polygon2D = p as Polygon2D
			if is_instance_valid(poly):
				poly.visible = true
		if level_idx > 0:
			var prev: Array = levels[level_idx - 1] as Array
			for p: Variant in prev:
				var poly: Polygon2D = p as Polygon2D
				if is_instance_valid(poly):
					poly.visible = false
		if level_idx < levels.size() - 1:
			await get_tree().create_timer(0.12).timeout

	# Fly-apart: animate final level (128 triangles)
	var final_polys: Array = levels[levels.size() - 1] as Array
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var card_cx: float = ax + aw * 0.5
	var card_cy: float = ay + ah * 0.5

	for p: Variant in final_polys:
		var poly: Polygon2D = p as Polygon2D
		if not is_instance_valid(poly):
			continue
		var dir := Vector2(poly.position.x - card_cx, poly.position.y - card_cy)
		if dir.length() < 1.0:
			dir = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		dir = (dir.normalized() + Vector2(0.0, -0.4)).normalized()

		var speed: float     = rng.randf_range(100.0, 360.0)
		var duration: float  = rng.randf_range(0.42, 0.75)
		var rot_delta: float = rng.randf_range(-TAU, TAU)

		var tw := create_tween()
		tw.tween_property(poly, "position", poly.position + dir * speed, duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(poly, "modulate:a", 0.0, duration) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(poly, "rotation", poly.rotation + rot_delta, duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
		tw.tween_callback(poly.queue_free)

	await get_tree().create_timer(0.80).timeout  # covers max fly-apart duration (0.75) + buffer

## Midpoint-subdivide one triangle into 4 interlocked children.
func _subdivide_triangle(verts: PackedVector2Array, uvs: PackedVector2Array) -> Array:
	var a := verts[0]; var b := verts[1]; var c := verts[2]
	var ua := uvs[0];  var ub := uvs[1];  var uc := uvs[2]
	var mab := (a  + b)  * 0.5; var muab := (ua + ub) * 0.5
	var mbc := (b  + c)  * 0.5; var mubc := (ub + uc) * 0.5
	var mca := (c  + a)  * 0.5; var muca := (uc + ua) * 0.5
	return [
		[PackedVector2Array([a,   mab, mca]), PackedVector2Array([ua,   muab, muca])],
		[PackedVector2Array([mab, b,   mbc]), PackedVector2Array([muab, ub,   mubc])],
		[PackedVector2Array([mbc, c,   mca]), PackedVector2Array([mubc, uc,   muca])],
		[PackedVector2Array([mab, mbc, mca]), PackedVector2Array([muab, mubc, muca])],
	]

# ─────────────────────────────────────────────────────────────
# Scenario animations
# ─────────────────────────────────────────────────────────────

# 3A: Attacker wins — defender destroyed
func _anim_attacker_wins(att: Control, def: Control, dx: float) -> void:
	var att_rest := att.position.x
	_play_sfx(SFX_CLANK)
	await _bounce_forward(att, dx)
	_flash_white(def)  # runs concurrently as background coroutine
	await _bounce_back(att, att_rest)
	await get_tree().create_timer(0.1).timeout
	await _destroy_card(def)

# 3B: Defender wins — attacker destroyed
func _anim_defender_wins(att: Control, def: Control, dx: float) -> void:
	var att_rest := att.position.x
	var def_rest := def.position.x
	_play_sfx(SFX_CLANK)
	await _bounce_forward(att, dx)
	# Defender pushes back
	var push_t := create_tween()
	push_t.tween_property(def, "position:x", def_rest - dx * 0.35, 0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	push_t.tween_property(def, "position:x", def_rest, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	_flash_white(att)  # runs concurrently as background coroutine
	await _bounce_back(att, att_rest)
	await push_t.finished
	await get_tree().create_timer(0.12).timeout
	await _destroy_card(att)

# 3C: Tie — both destroyed
func _anim_tie(att: Control, def: Control, dx: float) -> void:
	var att_rest := att.position.x
	var def_rest := def.position.x
	# Both lunge toward each other simultaneously
	# First tweener must NOT use .parallel() — subsequent ones do
	var lunge_t := create_tween()
	lunge_t.tween_property(att, "position:x", att_rest + dx, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	lunge_t.parallel().tween_property(def, "position:x", def_rest - dx, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_play_sfx(SFX_CLANK)
	await lunge_t.finished
	# Flash both cards
	_flash_white(att)  # fire-and-forget, runs concurrently
	await _flash_white(def)
	await get_tree().create_timer(0.06).timeout
	# Both shatter simultaneously — fire att concurrently, await def
	_destroy_card(att)
	await _destroy_card(def)

# 3D: Trap triggered, attacker survives
func _anim_trap_survives(att: Control, def: Control, dx: float) -> void:
	var att_rest := att.position.x
	_play_sfx(SFX_GEAR)
	await _bounce_forward(att, dx)
	# Trap burst fires at the moment of contact, after the bounce
	_play_sfx(SFX_SPELL)
	_play_burst_ring(def)
	_flash_white(def)
	_flash_screen_white()
	await get_tree().create_timer(0.55).timeout
	await _bounce_back(att, att_rest)
	await get_tree().create_timer(0.15).timeout

# 3E: Trap triggered, attacker destroyed
func _anim_trap_destroys(att: Control, def: Control, dx: float) -> void:
	var att_rest := att.position.x
	_play_sfx(SFX_GEAR)
	await _bounce_forward(att, dx)
	# Trap burst fires at the moment of contact, after the bounce
	_play_sfx(SFX_SPELL)
	_play_burst_ring(def)
	_flash_white(def)
	_flash_screen_white()
	await get_tree().create_timer(0.55).timeout
	await _bounce_back(att, att_rest)
	await get_tree().create_timer(0.1).timeout
	await _destroy_card(att)

# 3F: Blank slot — attacker hits empty space
func _anim_blank(att: Control, def: Control, dx: float) -> void:
	var att_rest := att.position.x
	_play_sfx(SFX_SWOOSH)
	await _bounce_forward(att, dx)
	# Spring back + blank fade in one tween so we have a single finished signal to await
	var t := create_tween()
	t.tween_property(att, "position:x", att_rest, 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	t.parallel().tween_property(def, "modulate:a", 0.0, 0.30).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await t.finished

# Fallback: exchange (neither destroyed)
func _anim_exchange(att: Control, def: Control, dx: float) -> void:
	var att_rest := att.position.x
	_play_sfx(SFX_CLANK)
	await _bounce_forward(att, dx)
	_flash_white(def)  # runs concurrently as background coroutine
	await _bounce_back(att, att_rest)

# ─────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	# Don't consume input while an ability-choice overlay is on top — buttons need those events
	if _paused:
		return
	if _skippable:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_skip_requested = true
		elif event is InputEventKey and (event as InputEventKey).pressed:
			_skip_requested = true
	get_viewport().set_input_as_handled()
