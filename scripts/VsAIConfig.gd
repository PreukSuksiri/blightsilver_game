extends Control
## VS AI Config — pre-battle setup screen for Player vs AI mode.
## Launched from the main menu VS AI button.
## Lets the player configure both sides' names/illustrations and deck setup (save deck or AI Deck Vault).

const DeckData = preload("res://resources/DeckData.gd")
const TECH_SLOT_COUNT: int = 3
const DEFAULT_PORTRAIT_PATHS: Array[String] = [
	"res://assets/textures/ui/portraits/profile_player_1_default.png",
	"res://assets/textures/ui/portraits/profile_player_2_default.png",
]
const DEFAULT_PLAYER_NAMES: Array[String] = ["Player 1", "Opponent"]
const DEFAULT_PORTRAIT_BROWSE_DIR: String = "res://assets/textures/profile/battle_illustrations"
const PORTRAIT_IMAGE_EXTENSIONS: Array[String] = [".png", ".jpg", ".jpeg", ".webp"]

# ── UI refs ────────────────────────────────────────────────────────────────────
var _deck_opt: OptionButton = null
var _player_vault_opt: OptionButton = null
var _player_vault_form_opt: OptionButton = null
var _vault_opt: OptionButton = null
var _vault_form_opt: OptionButton = null
var _formation_opt: OptionButton = null
var _forced_tech_btns: Array[Button] = []
var _forced_tech: Array = ["", "", ""]   # slot → tech name (empty = random on deal)
var _forced_grid: GridContainer = null
var _forced_dict: Dictionary = {}        # key="r,c" value=card_name
var _status_lbl: Label = null
var _bgm_enabled_chk: CheckBox = null
var _union_maniac_chk: CheckBox = null
var _name_edits: Array[LineEdit] = [null, null]
var _portrait_paths: Array[String] = DEFAULT_PORTRAIT_PATHS.duplicate()
var _portrait_browse_dirs: Array[String] = [
	DEFAULT_PORTRAIT_BROWSE_DIR,
	DEFAULT_PORTRAIT_BROWSE_DIR,
]
var _portrait_previews: Array[TextureRect] = [null, null]

# Union zone highlight
var _union_highlighted_name: String = ""
var _union_highlight_cells: Array = []

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	_populate_decks()
	_on_player_vault_selected()
	CheckerTransition.fade_in()

# ─────────────────────────────────────────────────────────────────────────────
# UI Construction
# ─────────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.10, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	root.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	add_child(root)

	# ── Title bar ─────────────────────────────────────────────────────────────
	var title_hb := HBoxContainer.new()
	title_hb.add_theme_constant_override("separation", 10)
	root.add_child(title_hb)

	var title_lbl := Label.new()
	title_lbl.text = "VS AI  —  Configure Battle"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(title_lbl)

	var back_btn := Button.new()
	back_btn.text = "← Back to Main Menu"
	back_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(func() -> void:
		MainMenuReturnLoader.return_to_main_menu())
	title_hb.add_child(back_btn)

	# ── Two-column config area ───────────────────────────────────────────────────
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(cols)

	_build_player_column(cols)
	_build_ai_column(cols)

	# ── Start + status row ─────────────────────────────────────────────────────
	var sep := HSeparator.new()
	root.add_child(sep)

	var action_hb := HBoxContainer.new()
	action_hb.add_theme_constant_override("separation", 12)
	root.add_child(action_hb)

	var start_btn := Button.new()
	start_btn.text = "  START BATTLE  "
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.custom_minimum_size = Vector2(220, 44)
	start_btn.pressed.connect(_on_start_battle)
	action_hb.add_child(start_btn)

	_status_lbl = Label.new()
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_hb.add_child(_status_lbl)

func _build_player_column(parent: HBoxContainer) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)

	var hdr := Label.new()
	hdr.text = "You"
	hdr.add_theme_font_size_override("font_size", 17)
	hdr.add_theme_color_override("font_color", Color(0.55, 1.0, 0.75))
	col.add_child(hdr)

	_add_name_row(col, 0)
	_add_portrait_row(col, 0, "Your Illustration")

	var player_vault_hdr := Label.new()
	player_vault_hdr.text = "Deck Vault  (overrides active save deck)"
	player_vault_hdr.add_theme_font_size_override("font_size", 13)
	player_vault_hdr.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	col.add_child(player_vault_hdr)

	var player_vault_row := HBoxContainer.new()
	player_vault_row.add_theme_constant_override("separation", 8)
	col.add_child(player_vault_row)
	var player_vault_lbl := Label.new()
	player_vault_lbl.text = "Vault:"
	player_vault_lbl.add_theme_font_size_override("font_size", 14)
	player_vault_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_vault_row.add_child(player_vault_lbl)
	_player_vault_opt = OptionButton.new()
	_player_vault_opt.add_theme_font_size_override("font_size", 13)
	_player_vault_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_vault_opt.item_selected.connect(func(_i: int) -> void: _on_player_vault_selected())
	player_vault_row.add_child(_player_vault_opt)
	AIDeckVault.populate_vault_option(_player_vault_opt, "(none — use active save deck)")

	var player_vault_form_row := HBoxContainer.new()
	player_vault_form_row.add_theme_constant_override("separation", 8)
	col.add_child(player_vault_form_row)
	var player_vault_form_lbl := Label.new()
	player_vault_form_lbl.text = "Formation:"
	player_vault_form_lbl.add_theme_font_size_override("font_size", 14)
	player_vault_form_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_vault_form_row.add_child(player_vault_form_lbl)
	_player_vault_form_opt = OptionButton.new()
	_player_vault_form_opt.add_theme_font_size_override("font_size", 13)
	_player_vault_form_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_vault_form_opt.item_selected.connect(func(_i: int) -> void: _on_player_vault_selected())
	player_vault_form_row.add_child(_player_vault_form_opt)

func _build_ai_column(parent: HBoxContainer) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)

	var hdr := Label.new()
	hdr.text = "AI Opponent"
	hdr.add_theme_font_size_override("font_size", 17)
	hdr.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	col.add_child(hdr)

	_add_name_row(col, 1)
	_add_portrait_row(col, 1, "AI Illustration")

	# ── AI Deck Vault (overrides deck + formation when set) ───────────────────
	var vault_hdr := Label.new()
	vault_hdr.text = "AI Deck Vault  (overrides deck + formation below)"
	vault_hdr.add_theme_font_size_override("font_size", 13)
	vault_hdr.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	col.add_child(vault_hdr)

	var vault_row := HBoxContainer.new()
	vault_row.add_theme_constant_override("separation", 8)
	col.add_child(vault_row)
	var vault_lbl := Label.new()
	vault_lbl.text = "Vault:"
	vault_lbl.add_theme_font_size_override("font_size", 14)
	vault_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vault_row.add_child(vault_lbl)
	_vault_opt = OptionButton.new()
	_vault_opt.add_theme_font_size_override("font_size", 13)
	_vault_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vault_opt.item_selected.connect(func(_i: int) -> void: _on_vault_selected())
	vault_row.add_child(_vault_opt)
	AIDeckVault.populate_vault_option(_vault_opt)

	var vault_form_row := HBoxContainer.new()
	vault_form_row.add_theme_constant_override("separation", 8)
	col.add_child(vault_form_row)
	var vault_form_lbl := Label.new()
	vault_form_lbl.text = "Formation:"
	vault_form_lbl.add_theme_font_size_override("font_size", 14)
	vault_form_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vault_form_row.add_child(vault_form_lbl)
	_vault_form_opt = OptionButton.new()
	_vault_form_opt.add_theme_font_size_override("font_size", 13)
	_vault_form_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vault_form_opt.item_selected.connect(func(_i: int) -> void: _on_vault_selected())
	vault_form_row.add_child(_vault_form_opt)

	# ── Deck selector ──────────────────────────────────────────────────────────
	var deck_row := HBoxContainer.new()
	deck_row.add_theme_constant_override("separation", 8)
	col.add_child(deck_row)

	var deck_lbl := Label.new()
	deck_lbl.text = "Deck:"
	deck_lbl.add_theme_font_size_override("font_size", 14)
	deck_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_row.add_child(deck_lbl)

	_deck_opt = OptionButton.new()
	_deck_opt.add_theme_font_size_override("font_size", 13)
	_deck_opt.custom_minimum_size = Vector2(300, 0)
	_deck_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_opt.item_selected.connect(func(_i: int) -> void: _on_deck_selected())
	deck_row.add_child(_deck_opt)

	# ── Formation preset selector ───────────────────────────────────────────────
	var form_row := HBoxContainer.new()
	form_row.add_theme_constant_override("separation", 8)
	col.add_child(form_row)

	var form_lbl := Label.new()
	form_lbl.text = "Formation:"
	form_lbl.add_theme_font_size_override("font_size", 14)
	form_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	form_row.add_child(form_lbl)

	_formation_opt = OptionButton.new()
	_formation_opt.add_theme_font_size_override("font_size", 13)
	_formation_opt.custom_minimum_size = Vector2(300, 0)
	_formation_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_formation_opt.item_selected.connect(func(_i: int) -> void: _on_formation_selected())
	form_row.add_child(_formation_opt)
	_refresh_formation_opt()

	# ── Forced tech hand ───────────────────────────────────────────────────────
	var ft_lbl := Label.new()
	ft_lbl.text = "Forced Tech Hand  (tap slot to assign)"
	ft_lbl.add_theme_font_size_override("font_size", 13)
	ft_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	col.add_child(ft_lbl)

	var ft_row := HBoxContainer.new()
	ft_row.add_theme_constant_override("separation", 6)
	col.add_child(ft_row)

	_forced_tech_btns = []
	for slot: int in range(TECH_SLOT_COUNT):
		var tbtn := Button.new()
		tbtn.custom_minimum_size = Vector2(0, 36)
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.clip_text = true
		tbtn.add_theme_font_size_override("font_size", 11)
		var slot_cap := slot
		tbtn.pressed.connect(func() -> void: _open_forced_tech_picker(slot_cap))
		ft_row.add_child(tbtn)
		_forced_tech_btns.append(tbtn)
	_refresh_forced_tech_row()

	# ── Forced cells grid ──────────────────────────────────────────────────────
	var fc_lbl := Label.new()
	fc_lbl.text = "Forced Formation  (tap cell to assign)"
	fc_lbl.add_theme_font_size_override("font_size", 13)
	fc_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	col.add_child(fc_lbl)

	_forced_grid = _build_forced_grid()
	col.add_child(_forced_grid)

	# ── Clear formation button ─────────────────────────────────────────────────
	var clear_btn := Button.new()
	clear_btn.text = "Clear All Cells"
	clear_btn.add_theme_font_size_override("font_size", 12)
	clear_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	clear_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	clear_btn.pressed.connect(func() -> void:
		_forced_dict.clear()
		_refresh_forced_grid())
	col.add_child(clear_btn)

	# ── Audio ──────────────────────────────────────────────────────────────────
	var bgm_row := HBoxContainer.new()
	bgm_row.add_theme_constant_override("separation", 8)
	col.add_child(bgm_row)
	_bgm_enabled_chk = CheckBox.new()
	_bgm_enabled_chk.text = "Background Music"
	_bgm_enabled_chk.button_pressed = true
	_bgm_enabled_chk.add_theme_font_size_override("font_size", 14)
	bgm_row.add_child(_bgm_enabled_chk)

	_union_maniac_chk = CheckBox.new()
	_union_maniac_chk.text = "Union Maniac"
	_union_maniac_chk.button_pressed = false
	_union_maniac_chk.add_theme_font_size_override("font_size", 14)
	bgm_row.add_child(_union_maniac_chk)

func _add_name_row(parent: Control, player_index: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = "Name:"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var edit := LineEdit.new()
	edit.placeholder_text = DEFAULT_PLAYER_NAMES[player_index]
	edit.add_theme_font_size_override("font_size", 14)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(edit)
	_name_edits[player_index] = edit

func _add_portrait_row(parent: Control, player_index: int, label_text: String) -> void:
	var illus_row := HBoxContainer.new()
	illus_row.add_theme_constant_override("separation", 10)
	parent.add_child(illus_row)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(60, 88)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.clip_contents = true
	var init_tex: Texture2D = GameState.load_portrait_texture(_portrait_paths[player_index])
	if init_tex:
		preview.texture = init_tex
	illus_row.add_child(preview)
	_portrait_previews[player_index] = preview

	var illus_vb := VBoxContainer.new()
	illus_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	illus_vb.add_theme_constant_override("separation", 4)
	illus_row.add_child(illus_vb)

	var illus_lbl := Label.new()
	illus_lbl.text = label_text
	illus_lbl.add_theme_font_size_override("font_size", 13)
	illus_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	illus_vb.add_child(illus_lbl)

	var change_btn := Button.new()
	change_btn.text = "Change..."
	change_btn.add_theme_font_size_override("font_size", 12)
	change_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var idx := player_index
	change_btn.pressed.connect(func() -> void: _open_portrait_picker(idx))
	illus_vb.add_child(change_btn)

func _populate_decks() -> void:
	_deck_opt.clear()
	_deck_opt.add_item("Random (full card pool)")  # index 0 = null deck
	for i: int in range(SaveManager.decks.size()):
		var d: DeckData = SaveManager.decks[i]
		_deck_opt.add_item(d.deck_name)

func _on_player_vault_selected() -> void:
	if _player_vault_opt == null or _player_vault_form_opt == null:
		return
	var entry_id: String = AIDeckVault.option_entry_id(_player_vault_opt)
	AIDeckVault.populate_formation_option(_player_vault_form_opt, entry_id)

func _on_vault_selected() -> void:
	if _vault_opt == null or _vault_form_opt == null:
		return
	var entry_id: String = AIDeckVault.option_entry_id(_vault_opt)
	var using_vault := not entry_id.is_empty()
	if _deck_opt != null:
		_deck_opt.disabled = using_vault
	if _formation_opt != null:
		_formation_opt.disabled = using_vault
	AIDeckVault.populate_formation_option(_vault_form_opt, entry_id)
	if not using_vault:
		return
	var cfg: Dictionary = AIDeckVault.build_ai_battle_config(
		entry_id, AIDeckVault.option_formation_index(_vault_form_opt))
	if not bool(cfg.get("ok", false)):
		return
	var deck: DeckData = cfg.get("deck") as DeckData
	if deck != null:
		for i: int in range(TECH_SLOT_COUNT):
			_forced_tech[i] = str(deck.techs[i]) if i < deck.techs.size() else ""
		_refresh_forced_tech_row()
	_forced_dict = AIDeckVault.forced_cells_to_grid_dict(cfg.get("forced_cells", []))
	_refresh_forced_grid()


func _on_deck_selected() -> void:
	# Pre-fill tech slots from the selected deck
	for i: int in range(TECH_SLOT_COUNT):
		_forced_tech[i] = ""
	if _deck_opt.selected > 0:
		var deck: DeckData = SaveManager.decks[_deck_opt.selected - 1]
		for i: int in range(mini(TECH_SLOT_COUNT, deck.techs.size())):
			_forced_tech[i] = str(deck.techs[i])
	_refresh_forced_tech_row()
	_refresh_formation_opt()

func _refresh_formation_opt() -> void:
	if _formation_opt == null:
		return
	_formation_opt.clear()
	_formation_opt.add_item("— no preset —")
	if _deck_opt != null and _deck_opt.selected > 0:
		var deck: DeckData = SaveManager.decks[_deck_opt.selected - 1]
		for f: Variant in deck.formations:
			var fd: Dictionary = f as Dictionary
			_formation_opt.add_item(str(fd.get("name", "Formation")))

func _on_formation_selected() -> void:
	if _formation_opt == null or _formation_opt.selected <= 0:
		return
	if _deck_opt == null or _deck_opt.selected <= 0:
		return
	var deck: DeckData = SaveManager.decks[_deck_opt.selected - 1]
	var form_idx: int = _formation_opt.selected - 1
	if form_idx < 0 or form_idx >= deck.formations.size():
		return
	var fd: Dictionary = deck.formations[form_idx] as Dictionary
	var pls: Variant = fd.get("placements", [])
	if not pls is Array:
		return
	_forced_dict.clear()
	for pl: Variant in (pls as Array):
		if not pl is Dictionary:
			continue
		var p: Dictionary = pl as Dictionary
		var r: int = int(p.get("r", -1))
		var c: int = int(p.get("c", -1))
		var card_name: String = str(p.get("name", ""))
		if r < 0 or r > 4 or c < 0 or c > 4 or card_name.is_empty():
			continue
		_forced_dict[str(r) + "," + str(c)] = card_name
	_refresh_forced_grid()

# ─────────────────────────────────────────────────────────────────────────────
# Start Battle
# ─────────────────────────────────────────────────────────────────────────────
func _apply_battle_identity() -> void:
	GameState.player_portraits[0] = _portrait_paths[0]
	GameState.player_portraits[1] = _portrait_paths[1]
	var names: Array[String] = []
	for i: int in range(2):
		var edit: LineEdit = _name_edits[i]
		var n: String = edit.text.strip_edges() if edit != null else ""
		if n.is_empty():
			n = DEFAULT_PLAYER_NAMES[i]
		names.append(n)
	GameState.campaign_player_names = names
	GameState.battle_bgm_enabled = _bgm_enabled_chk.button_pressed if _bgm_enabled_chk != null else true
	GameState.battle_ai_union_maniac = _union_maniac_chk.button_pressed if _union_maniac_chk != null else false
	if GameState.battle_ai_union_maniac:
		GameState.battle_ai_union_enabled = true

func _apply_player_vault_or_clear() -> Array[String]:
	var errs: Array[String] = []
	GameState.battle_player_deck = null
	GameState.battle_player_forced_cells.clear()
	while GameState.battle_featured_unions.size() < 2:
		GameState.battle_featured_unions.append("")
	GameState.battle_featured_unions[0] = ""

	var player_vault_id: String = AIDeckVault.option_entry_id(_player_vault_opt) \
		if _player_vault_opt != null else ""
	if player_vault_id.is_empty():
		return errs

	var pcfg: Dictionary = AIDeckVault.build_ai_battle_config(
		player_vault_id,
		AIDeckVault.option_formation_index(_player_vault_form_opt))
	if not bool(pcfg.get("ok", false)):
		errs.append("Invalid player deck vault entry.")
		return errs
	AIDeckVault.apply_player_battle_config(pcfg)
	return errs

func _on_start_battle() -> void:
	_status_lbl.text = ""
	for msg: String in _apply_player_vault_or_clear():
		_status_lbl.text = msg
		return

	var vault_id: String = AIDeckVault.option_entry_id(_vault_opt) if _vault_opt != null else ""
	if not vault_id.is_empty():
		var ft: Array = _collect_forced_tech()
		for msg: String in _validate_forced_tech(ft):
			_status_lbl.text = msg
			return
		var cfg: Dictionary = AIDeckVault.build_ai_battle_config(
			vault_id,
			AIDeckVault.option_formation_index(_vault_form_opt),
			ft)
		if not bool(cfg.get("ok", false)):
			_status_lbl.text = "Invalid AI deck vault entry."
			return
		GameState.game_mode              = GameState.GameMode.VS_AI
		GameState.battle_ai_deck         = cfg.get("deck")
		GameState.battle_ai_forced_cells = (cfg.get("forced_cells", []) as Array).duplicate(true)
		GameState.battle_ai_forced_tech  = (cfg.get("forced_tech", []) as Array).duplicate(true)
		GameState.battle_ai_featured_union = str(cfg.get("featured_union", "")).strip_edges()
		var _p0_union: String = str(GameState.battle_featured_unions[0]) if GameState.battle_featured_unions.size() > 0 else ""
		GameState.battle_featured_unions = [_p0_union, GameState.battle_ai_featured_union]
		GameState.campaign_enemy_config = {
			"forced_characters": (cfg.get("forced_characters", []) as Array).duplicate(),
			"forced_traps": (cfg.get("forced_traps", []) as Array).duplicate(),
			"forced_tech": (cfg.get("forced_tech", []) as Array).duplicate(),
		}
		_apply_battle_identity()
		BGMManager.stop(0.0)
		CheckerTransition.fade_out_to_battle(func() -> void:
			get_tree().change_scene_to_file("res://scenes/game_board.tscn"))
		return

	var d: Variant = null
	if _deck_opt.selected > 0:
		d = SaveManager.decks[_deck_opt.selected - 1]
		if not (d as DeckData).is_valid():
			_status_lbl.text = "Selected AI deck is invalid."
			return

	var fc: Array = _collect_forced_cells()
	var ft: Array = _collect_forced_tech()

	for msg: String in _validate_forced_tech(ft):
		_status_lbl.text = msg
		return

	GameState.game_mode               = GameState.GameMode.VS_AI
	GameState.battle_ai_deck          = d
	GameState.battle_ai_forced_cells  = fc
	GameState.battle_ai_forced_tech   = ft
	var _p0_union_manual: String = str(GameState.battle_featured_unions[0]) \
		if GameState.battle_featured_unions.size() > 0 else ""
	GameState.battle_featured_unions = [_p0_union_manual, ""]
	GameState.battle_ai_featured_union = ""
	_apply_battle_identity()

	BGMManager.stop(0.0)
	CheckerTransition.fade_out_to_battle(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game_board.tscn"))

# ─────────────────────────────────────────────────────────────────────────────
# Forced cell grid helpers
# ─────────────────────────────────────────────────────────────────────────────
func _build_forced_grid() -> GridContainer:
	var gc := GridContainer.new()
	gc.columns = 5
	gc.add_theme_constant_override("h_separation", 4)
	gc.add_theme_constant_override("v_separation", 4)
	for r: int in range(5):
		for c: int in range(5):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(64, 44)
			btn.clip_text = true
			btn.add_theme_font_size_override("font_size", 10)
			var r_cap := r
			var c_cap := c
			btn.pressed.connect(func() -> void:
				_open_forced_cell_picker(r_cap, c_cap))
			gc.add_child(btn)
	_refresh_forced_grid()
	return gc

func _refresh_forced_grid() -> void:
	if _forced_grid == null:
		return
	var children: Array = _forced_grid.get_children()
	for r: int in range(5):
		for c: int in range(5):
			var btn: Button = children[r * 5 + c] as Button
			var key: String = str(r) + "," + str(c)
			var is_hl: bool = Vector2i(r, c) in _union_highlight_cells
			if _forced_dict.has(key):
				btn.text = _forced_dict[key] as String
				btn.modulate = Color(0.0, 1.0, 1.0) if is_hl else Color(0.55, 1.0, 0.55)
			else:
				btn.text = "%d,%d" % [r, c]
				btn.modulate = Color(0.0, 0.85, 0.85, 0.75) if is_hl else Color(1.0, 1.0, 1.0, 0.45)

func _open_forced_cell_picker(r: int, c: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 70
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "AI Cell [row %d, col %d]" % [r, c]
	title.add_theme_font_size_override("font_size", 15)
	vb.add_child(title)

	var key: String = str(r) + "," + str(c)
	var current: String = str(_forced_dict.get(key, ""))

	var le := LineEdit.new()
	le.placeholder_text = "Character or trap name..."
	le.text = current
	le.add_theme_font_size_override("font_size", 14)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(le)

	var sug_scroll := ScrollContainer.new()
	sug_scroll.custom_minimum_size = Vector2(0, 140)
	sug_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(sug_scroll)
	var sug_vb := VBoxContainer.new()
	sug_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sug_scroll.add_child(sug_vb)

	var refresh_sug := func(query: String) -> void:
		for child: Node in sug_vb.get_children():
			child.queue_free()
		var q: String = query.strip_edges().to_lower()
		var names: Array = []
		for n: String in CardDatabase.characters:
			if q.is_empty() or n.to_lower().contains(q):
				names.append(n)
		for n: String in CardDatabase.traps:
			if q.is_empty() or n.to_lower().contains(q):
				names.append(n)
		names.sort()
		var shown: int = 0
		for n: String in names:
			if shown >= 30:
				break
			var sb := Button.new()
			sb.text = n
			sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			sb.add_theme_font_size_override("font_size", 12)
			sb.pressed.connect(func() -> void: le.text = n)
			sug_vb.add_child(sb)
			shown += 1

	le.text_changed.connect(refresh_sug)
	refresh_sug.call(current)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 6)
	vb.add_child(btn_hb)

	var set_btn := Button.new()
	set_btn.text = "Set"
	set_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(set_btn)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(clear_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(cancel_btn)

	set_btn.pressed.connect(func() -> void:
		var cname: String = le.text.strip_edges()
		if not cname.is_empty():
			_forced_dict[key] = cname
		else:
			_forced_dict.erase(key)
		_refresh_forced_grid()
		overlay.queue_free())

	clear_btn.pressed.connect(func() -> void:
		_forced_dict.erase(key)
		_refresh_forced_grid()
		overlay.queue_free())

	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point(
					(event as InputEventMouseButton).global_position):
				overlay.queue_free())

	le.grab_focus()
	le.select_all()

func _collect_forced_cells() -> Array:
	var result: Array = []
	for key: String in _forced_dict:
		var parts: PackedStringArray = key.split(",")
		if parts.size() == 2:
			result.append({
				"card_name": _forced_dict[key],
				"row": int(parts[0]),
				"col": int(parts[1]),
			})
	return result

# ─────────────────────────────────────────────────────────────────────────────
# Forced tech helpers
# ─────────────────────────────────────────────────────────────────────────────
func _refresh_forced_tech_row() -> void:
	for i: int in range(_forced_tech_btns.size()):
		var btn: Button = _forced_tech_btns[i]
		var n: String = str(_forced_tech[i] if i < _forced_tech.size() else "").strip_edges()
		if n.is_empty():
			btn.text = "Tech %d\n(random)" % (i + 1)
			btn.modulate = Color(1.0, 1.0, 1.0, 0.45)
		else:
			btn.text = n
			btn.modulate = Color(0.55, 0.85, 1.0)

func _open_forced_tech_picker(slot: int) -> void:
	var current: String = str(_forced_tech[slot] if slot < _forced_tech.size() else "")

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 70
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "AI Tech slot %d" % (slot + 1)
	title.add_theme_font_size_override("font_size", 15)
	vb.add_child(title)

	var le := LineEdit.new()
	le.placeholder_text = "Tech card name..."
	le.text = current
	le.add_theme_font_size_override("font_size", 14)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(le)

	var sug_scroll := ScrollContainer.new()
	sug_scroll.custom_minimum_size = Vector2(0, 160)
	sug_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(sug_scroll)
	var sug_vb := VBoxContainer.new()
	sug_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sug_scroll.add_child(sug_vb)

	var refresh_sug := func(query: String) -> void:
		for child: Node in sug_vb.get_children():
			child.queue_free()
		var q: String = query.strip_edges().to_lower()
		var names: Array = CardDatabase.get_all_tech_names()
		names.sort()
		var shown: int = 0
		for n: String in names:
			if SaveManager.demo_mode:
				var tc: TechCardData = CardDatabase.get_tech(n)
				if tc == null or not tc.include_in_demo:
					continue
			if not q.is_empty() and not n.to_lower().contains(q):
				continue
			if shown >= 30:
				break
			var sb := Button.new()
			sb.text = n
			sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			sb.add_theme_font_size_override("font_size", 12)
			sb.pressed.connect(func() -> void: le.text = n)
			sug_vb.add_child(sb)
			shown += 1

	le.text_changed.connect(refresh_sug)
	refresh_sug.call(current)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 6)
	vb.add_child(btn_hb)

	var set_btn := Button.new()
	set_btn.text = "Set"
	set_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(set_btn)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(clear_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.add_child(cancel_btn)

	set_btn.pressed.connect(func() -> void:
		var tname: String = le.text.strip_edges()
		_forced_tech[slot] = tname
		_refresh_forced_tech_row()
		overlay.queue_free())

	clear_btn.pressed.connect(func() -> void:
		_forced_tech[slot] = ""
		_refresh_forced_tech_row()
		overlay.queue_free())

	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point(
					(event as InputEventMouseButton).global_position):
				overlay.queue_free())

	le.grab_focus()
	le.select_all()

func _collect_forced_tech() -> Array:
	var result: Array = []
	for i: int in range(TECH_SLOT_COUNT):
		var n: String = str(_forced_tech[i] if i < _forced_tech.size() else "").strip_edges()
		result.append(n)
	return result

func _validate_forced_tech(slots: Array) -> Array[String]:
	var seen: Dictionary = {}
	for i: int in range(slots.size()):
		var n: String = str(slots[i]).strip_edges()
		if n.is_empty():
			continue
		if CardDatabase.get_tech(n) == null:
			return ["Tech slot %d: unknown tech \"%s\"." % [i + 1, n]]
		if seen.has(n):
			return ["Tech slot %d: duplicate \"%s\"." % [i + 1, n]]
		seen[n] = true
	return []

# ─────────────────────────────────────────────────────────────────────────────
# Portrait picker
# ─────────────────────────────────────────────────────────────────────────────
func _is_portrait_image_file(fname: String) -> bool:
	if fname.ends_with(".import"):
		return false
	var lower := fname.to_lower()
	for ext: String in PORTRAIT_IMAGE_EXTENSIONS:
		if lower.ends_with(ext):
			return true
	return false

func _portrait_file_label(fname: String) -> String:
	return fname.get_basename().trim_prefix("vn_char_").replace("_", " ")

func _short_folder_label(path: String) -> String:
	if path.begins_with("res://"):
		return path.trim_prefix("res://")
	return path

func _path_to_res_if_possible(abs_path: String) -> String:
	var normalized := abs_path.replace("\\", "/")
	var res_base := ProjectSettings.globalize_path("res://").replace("\\", "/")
	if not res_base.ends_with("/"):
		res_base += "/"
	if normalized.begins_with(res_base):
		return "res://" + normalized.substr(res_base.length())
	return normalized

func _join_dir_file(dir_path: String, fname: String) -> String:
	if dir_path.ends_with("/"):
		return dir_path + fname
	return dir_path + "/" + fname

func _open_dir_access(dir_path: String) -> DirAccess:
	var dir := DirAccess.open(dir_path)
	if dir != null:
		return dir
	if dir_path.begins_with("res://"):
		return DirAccess.open(ProjectSettings.globalize_path(dir_path))
	return null

func _get_portrait_options(default_path: String, browse_dir: String) -> Array:
	var opts: Array = []
	opts.append({
		"label": "Default",
		"path": default_path,
	})
	for entry: Dictionary in _collect_portrait_files(browse_dir, true):
		opts.append(entry)
	return opts

func _collect_portrait_files(dir_path: String, recursive: bool) -> Array:
	var results: Array = []
	var dir := _open_dir_access(dir_path)
	if dir == null:
		return results
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname.begins_with("."):
			fname = dir.get_next()
			continue
		var full_path: String = _join_dir_file(dir_path, fname)
		if dir.current_is_dir():
			if recursive:
				for sub: Dictionary in _collect_portrait_files(full_path, true):
					results.append(sub)
		elif _is_portrait_image_file(fname):
			var rel: String = full_path
			if full_path.begins_with(dir_path):
				rel = full_path.substr(dir_path.length()).trim_prefix("/")
			var label: String = _portrait_file_label(fname)
			if recursive and rel.contains("/"):
				label = rel.get_basename().replace("_", " ") + " (" + rel.get_base_dir() + ")"
			results.append({
				"label": label,
				"path": full_path,
			})
		fname = dir.get_next()
	dir.list_dir_end()
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("label", "")) < str(b.get("label", "")))
	return results

func _populate_portrait_picker_flow(
		flow: HFlowContainer,
		options: Array,
		player_index: int,
		overlay: Control,
		thumb_w: float,
		thumb_h: float) -> void:
	for child: Node in flow.get_children():
		child.queue_free()
	for opt: Dictionary in options:
		var opt_path: String = str(opt["path"])
		var opt_label: String = str(opt["label"])

		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(thumb_w, thumb_h + 24)
		cell.add_theme_constant_override("separation", 2)
		flow.add_child(cell)

		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(thumb_w, thumb_h)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex: Texture2D = GameState.load_portrait_texture(opt_path)
		if tex:
			thumb.texture = tex
		else:
			thumb.modulate = Color(0.3, 0.3, 0.3)
		if opt_path == _portrait_paths[player_index]:
			thumb.modulate = Color(0.4, 1.0, 0.6)
		cell.add_child(thumb)

		var name_lbl := Label.new()
		name_lbl.text = opt_label
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.clip_text = true
		name_lbl.custom_minimum_size = Vector2(thumb_w, 0)
		cell.add_child(name_lbl)

		var p_cap := opt_path
		var idx := player_index
		thumb.mouse_filter = Control.MOUSE_FILTER_STOP
		thumb.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				var mbe := event as InputEventMouseButton
				if mbe.pressed and mbe.button_index == MOUSE_BUTTON_LEFT:
					_portrait_paths[idx] = p_cap
					var new_tex: Texture2D = GameState.load_portrait_texture(p_cap)
					var preview: TextureRect = _portrait_previews[idx]
					if new_tex and preview != null:
						preview.texture = new_tex
					overlay.queue_free())

func _open_portrait_folder_dialog(player_index: int, overlay: Control, on_changed: Callable) -> void:
	var fd := FileDialog.new()
	fd.title = "Choose Illustration Folder"
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	var current_dir: String = _portrait_browse_dirs[player_index]
	if current_dir.begins_with("res://"):
		fd.current_dir = ProjectSettings.globalize_path(current_dir)
	else:
		fd.current_dir = current_dir
	fd.dir_selected.connect(func(dir: String) -> void:
		_portrait_browse_dirs[player_index] = _path_to_res_if_possible(dir)
		on_changed.call()
		fd.queue_free())
	fd.canceled.connect(func() -> void: fd.queue_free())
	overlay.add_child(fd)
	fd.popup_centered_ratio(0.55)

func _open_portrait_picker(player_index: int) -> void:
	var side_label: String = "Your" if player_index == 0 else "AI"

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 70
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 420)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title_hb := HBoxContainer.new()
	vb.add_child(title_hb)
	var title := Label.new()
	title.text = "Choose %s Illustration" % side_label
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_override("font", FontManager.make_font("primary", 400))
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func() -> void: overlay.queue_free())
	title_hb.add_child(close_btn)

	var folder_row := HBoxContainer.new()
	folder_row.add_theme_constant_override("separation", 8)
	vb.add_child(folder_row)

	var folder_lbl := Label.new()
	folder_lbl.add_theme_font_size_override("font_size", 11)
	folder_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	folder_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	folder_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	folder_row.add_child(folder_lbl)

	var folder_btn := Button.new()
	folder_btn.text = "Change Folder…"
	folder_btn.add_theme_font_size_override("font_size", 12)
	folder_row.add_child(folder_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(flow)

	const THUMB_W: float = 80.0
	const THUMB_H: float = 110.0

	var refresh_picker := func() -> void:
		folder_lbl.text = "Folder: %s" % _short_folder_label(_portrait_browse_dirs[player_index])
		var options: Array = _get_portrait_options(
			DEFAULT_PORTRAIT_PATHS[player_index], _portrait_browse_dirs[player_index])
		_populate_portrait_picker_flow(flow, options, player_index, overlay, THUMB_W, THUMB_H)

	folder_btn.pressed.connect(func() -> void:
		_open_portrait_folder_dialog(player_index, overlay, refresh_picker))

	refresh_picker.call()

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if not panel.get_global_rect().has_point(
					(event as InputEventMouseButton).global_position):
				overlay.queue_free())
