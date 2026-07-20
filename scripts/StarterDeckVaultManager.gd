extends Control
## Admin overlay for starter_deck_vault.json
## Opened via: manage_starter_deck_vault

const SAVE_PATH := "res://data/starter_deck_vault.json"

var _list: ItemList = null
var _status: Label = null
var _entries: Array = []


static func open(parent: Node) -> void:
	if parent == null:
		return
	var existing := parent.get_node_or_null("StarterDeckVaultManager")
	if existing != null:
		existing.queue_free()
	var overlay := preload("res://scripts/StarterDeckVaultManager.gd").new()
	overlay.name = "StarterDeckVaultManager"
	parent.add_child(overlay)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.88)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(720, 480)
	panel.offset_left = -360
	panel.offset_top = -240
	panel.offset_right = 360
	panel.offset_bottom = 240
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "Starter Deck Vault"
	title.add_theme_font_size_override("font_size", 22)
	vb.add_child(title)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_list)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_status)
	var row := HBoxContainer.new()
	var reload_btn := Button.new()
	reload_btn.text = "Reload"
	reload_btn.pressed.connect(_reload)
	row.add_child(reload_btn)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(queue_free)
	row.add_child(close_btn)
	vb.add_child(row)
	_reload()


func _reload() -> void:
	StarterDeckVault.reload()
	_entries = StarterDeckVault.get_entries()
	_list.clear()
	for e: Variant in _entries:
		if not e is Dictionary:
			continue
		var d: Dictionary = e as Dictionary
		var deck_raw: Variant = d.get("deck", {})
		var chars: int = 0
		var traps: int = 0
		var techs: int = 0
		if deck_raw is Dictionary:
			chars = ((deck_raw as Dictionary).get("characters", []) as Array).size()
			traps = ((deck_raw as Dictionary).get("traps", []) as Array).size()
			techs = ((deck_raw as Dictionary).get("techs", []) as Array).size()
		_list.add_item("%s — %s  (U%d/T%d/Tech%d)" % [
			str(d.get("id", "")), str(d.get("label", "")), chars, traps, techs
		])
	_status.text = "Entries live in %s. Edit JSON in the project, then Reload. Use unlock_protagonist <id> [vault_id] to test." % SAVE_PATH


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()
