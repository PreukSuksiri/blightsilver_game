extends Control
class_name CombatRewardOverlay

## Full-screen overlay listing combat rewards earned after a dungeon battle win.
## Dismiss with click or any key.

signal dismissed

const CREDIT_ICON_PATH: String = "res://assets/textures/ui/decorations/ui_icon_credit.png"
const DEFAULT_PACK_PATH: String = "res://assets/textures/cards/booster_pack/booster_pack_basic.png"
const FULL_CARDS_DIR: String = "res://assets/textures/cards/full_cards/"

var _rewards: Array = []
var _dismissed: bool = false

static func present(parent: Node, rewards: Array) -> void:
	if rewards.is_empty():
		return
	var overlay := CombatRewardOverlay.new()
	overlay._rewards = rewards.duplicate()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 25
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	await overlay.dismissed


func _ready() -> void:
	_build_ui()
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _input(event: InputEvent) -> void:
	if _dismissed:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			_dismiss()
	elif event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo:
			_dismiss()


func _dismiss() -> void:
	if _dismissed:
		return
	_dismissed = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		dismissed.emit()
		queue_free())


func _build_ui() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.04, 0.10, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root.offset_left = -vp.x * 0.42
	root.offset_right = vp.x * 0.42
	root.offset_top = -vp.y * 0.40
	root.offset_bottom = vp.y * 0.40
	root.add_theme_constant_override("separation", 28)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	var title := Label.new()
	title.text = "Rewards"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 36)
	root.add_child(row)

	var slot_h: float = vp.y * (0.50 if _rewards.size() == 1 else 0.38)
	for reward: Variant in _rewards:
		if reward is Dictionary:
			row.add_child(_make_reward_slot(reward as Dictionary, slot_h))

	var hint := Label.new()
	hint.text = "Click or press any key to continue"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	root.add_child(hint)


func _make_reward_slot(reward: Dictionary, slot_h: float) -> Control:
	var slot_vbox := VBoxContainer.new()
	slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_vbox.add_theme_constant_override("separation", 10)

	var icon_area := _make_reward_icon(reward, slot_h)
	slot_vbox.add_child(icon_area)

	var caption := Label.new()
	caption.text = _caption_for_reward(reward)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size = Vector2(slot_h * 1.1, 0.0)
	caption.add_theme_font_size_override("font_size", 18)
	caption.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	slot_vbox.add_child(caption)

	return slot_vbox


func _make_reward_icon(reward: Dictionary, slot_h: float) -> Control:
	var reward_type: String = str(reward.get("type", ""))
	var tex: Texture2D = _texture_for_reward(reward)

	if reward_type == "booster_pack" and tex != null:
		var aspect: float = float(tex.get_width()) / maxf(1.0, float(tex.get_height()))
		var pack_h: float = slot_h
		var pack_w: float = pack_h * aspect
		var pack_rect := TextureRect.new()
		pack_rect.custom_minimum_size = Vector2(pack_w, pack_h)
		pack_rect.texture = tex
		pack_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pack_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pack_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return pack_rect

	var box_side: float = minf(slot_h, 160.0)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(box_side, box_side)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.20, 0.95)
	sb.border_color = Color(0.45, 0.65, 0.95, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", sb)

	if tex != null:
		var icon := TextureRect.new()
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 12.0
		icon.offset_top = 12.0
		icon.offset_right = -12.0
		icon.offset_bottom = -12.0
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
	else:
		var question := Label.new()
		question.text = "?"
		question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		question.add_theme_font_size_override("font_size", int(box_side * 0.45))
		question.add_theme_color_override("font_color", Color(0.75, 0.80, 0.90))
		frame.add_child(question)

	return frame


static func _caption_for_reward(reward: Dictionary) -> String:
	match str(reward.get("type", "")):
		"credits", "coins":
			return "+%d Credits" % int(reward.get("amount", 0))
		"booster_pack":
			return str(reward.get("pack_name", "Booster Pack"))
		"card":
			return str(reward.get("card_name", "Card"))
		"stage_bonus_card":
			return "Stage Bonus\n%s" % str(reward.get("card_name", "Card"))
		"music_disc":
			return "Music Disc ×%d" % int(reward.get("count", 1))
		_:
			return str(reward.get("label", "Reward"))


static func _texture_for_reward(reward: Dictionary) -> Texture2D:
	match str(reward.get("type", "")):
		"credits", "coins":
			if ResourceLoader.exists(CREDIT_ICON_PATH):
				return load(CREDIT_ICON_PATH) as Texture2D
		"booster_pack":
			var pack_name: String = str(reward.get("pack_name", ""))
			var pack_dict: Dictionary = ShopManager.get_pack_by_name(pack_name)
			var pack_path: String = str(pack_dict.get("pack_image", ""))
			if pack_path != "" and ResourceLoader.exists(pack_path):
				return load(pack_path) as Texture2D
			if ResourceLoader.exists(DEFAULT_PACK_PATH):
				return load(DEFAULT_PACK_PATH) as Texture2D
		"card", "stage_bonus_card":
			var card_name: String = str(reward.get("card_name", ""))
			if card_name == "":
				return null
			var card_type: String = "character"
			if CardDatabase.get_trap(card_name) != null:
				card_type = "trap"
			elif CardDatabase.get_tech(card_name) != null:
				card_type = "tech"
			var art_path: String = CardDatabase.find_artwork(card_name, card_type, SaveManager.nsfw_enabled)
			if art_path != "" and ResourceLoader.exists(art_path):
				return load(art_path) as Texture2D
			var snake: String = card_name.to_lower().replace(" ", "_").replace("'", "").replace("-", "_")
			for candidate: String in [
				FULL_CARDS_DIR + snake + ".png",
				FULL_CARDS_DIR + card_type + "_" + snake + ".png",
			]:
				if ResourceLoader.exists(candidate):
					return load(candidate) as Texture2D
		_:
			pass
	return null
