extends Control
class_name AchievementUnlockOverlay

signal finished

const GAME_TITLE := "Blightsilver"
const PANEL_WIDTH := 380.0
const PANEL_HEIGHT := 88.0
const MARGIN := 24.0
const ICON_SIZE := 64.0
const HOLD_SECONDS := 4.0
const SLIDE_IN_SECONDS := 0.38
const SLIDE_OUT_SECONDS := 0.32

var _achievement_id: String = ""
var _reward: Dictionary = {}
var _pack_cards: Array = []
var _pack_name: String = ""
var _panel: PanelContainer = null
var _dismissing: bool = false


static func open(
		host: Node,
		achievement_id: String,
		reward: Dictionary = {},
		pack_cards: Array = [],
		pack_name: String = ""
) -> void:
	var overlay := AchievementUnlockOverlay.new()
	overlay._achievement_id = achievement_id
	overlay._reward = reward.duplicate(true) if reward is Dictionary else {}
	overlay._pack_cards = pack_cards.duplicate(true) if pack_cards is Array else []
	overlay._pack_name = pack_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 120
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(overlay)


func _ready() -> void:
	_build_ui()
	_play_entrance()


func _input(event: InputEvent) -> void:
	if _dismissing:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_dismiss()


func _build_ui() -> void:
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	anchor.offset_left = -(MARGIN + PANEL_WIDTH)
	anchor.offset_top = -(MARGIN + PANEL_HEIGHT)
	anchor.offset_right = -MARGIN
	anchor.offset_bottom = -MARGIN
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.1, 0.12, 0.94)
	sb.border_color = Color(0.22, 0.24, 0.28, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 10.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", sb)
	anchor.add_child(_panel)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(root)

	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(4.0, ICON_SIZE)
	accent.color = Color(0.42, 0.74, 0.28, 1.0)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(accent)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var def: Dictionary = AchievementManager.get_definition(_achievement_id)
	var icon_path: String = AchievementManager.get_icon_path(def)
	if not icon_path.is_empty():
		icon.texture = load(icon_path)
	root.add_child(icon)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 2)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(body)

	var game_lbl := Label.new()
	game_lbl.text = GAME_TITLE
	game_lbl.add_theme_font_size_override("font_size", 12)
	game_lbl.add_theme_color_override("font_color", Color(0.62, 0.66, 0.72))
	game_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(game_lbl)

	var name_lbl := Label.new()
	name_lbl.text = str(def.get("title", _achievement_id))
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(0.94, 0.96, 0.98))
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(name_lbl)

	var subtitle := _build_subtitle(def)
	if not subtitle.is_empty():
		var sub_lbl := Label.new()
		sub_lbl.text = subtitle
		sub_lbl.add_theme_font_size_override("font_size", 12)
		sub_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.66))
		sub_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(sub_lbl)


func _build_subtitle(def: Dictionary) -> String:
	var pose: String = ProtagonistVault.get_pose_reward_label_for_achievement(_achievement_id)
	if not pose.is_empty():
		return "New pose — %s" % pose
	var reward_txt: String = AchievementManager.format_reward_preview(_reward)
	if not reward_txt.is_empty():
		return reward_txt
	var condition: String = str(def.get("condition", "")).strip_edges()
	return condition


func _play_entrance() -> void:
	if _panel == null:
		return
	var slide_distance := PANEL_WIDTH + MARGIN
	_panel.position.x = slide_distance
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "position:x", 0.0, SLIDE_IN_SECONDS) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_panel, "modulate:a", 1.0, SLIDE_IN_SECONDS) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_interval(HOLD_SECONDS)
	tw.tween_callback(_dismiss)


func _dismiss() -> void:
	if _dismissing or not is_inside_tree():
		return
	_dismissing = true
	if _panel == null:
		_finish()
		return
	var slide_distance := PANEL_WIDTH + MARGIN
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "position:x", slide_distance, SLIDE_OUT_SECONDS) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_panel, "modulate:a", 0.0, SLIDE_OUT_SECONDS) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(_finish)


func _finish() -> void:
	finished.emit()
	var host: Node = get_tree().root if get_tree() != null else null
	if host != null:
		AchievementCelebrationRunner.play(host, _achievement_id, _reward, _pack_cards, _pack_name)
	queue_free()
