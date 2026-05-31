extends CanvasLayer
## BattleUIHideCapture — added by admin command "hide_ui" during battle.
## Hides all battle UI except the playmat background, card grids, and cyan grid borders.
## Center column and side labels stay in the layout (modulate hidden) so grids do not shift.
## Any key press or mouse click restores visibility and removes this node.

const _KEEP_ROOT_NAMES: Array = ["PlaymatBg", "Background", "MainLayout"]

var _visibility_stash: Array = []  # {path: NodePath, visible: bool}
var _modulate_stash: Array = []    # {path: NodePath, modulate: Color, mouse_filter: int}
var _restoring: bool = false

func _ready() -> void:
	layer = 99
	var board: Node = get_parent()
	_apply_hide(board)

	var blocker := ColorRect.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0.0, 0.0, 0.0, 0.0)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)

	await get_tree().process_frame
	if is_instance_valid(board) and board.has_method("refresh_grid_borders"):
		board.refresh_grid_borders()

func _apply_hide(board: Node) -> void:
	for child: Node in board.get_children():
		if _should_skip_root(child):
			continue
		_stash_visibility(board, child)

	var main_layout: Node = board.get_node_or_null("MainLayout")
	if main_layout == null:
		return

	for side_name: String in ["P1Side", "P2Side"]:
		var side: Node = main_layout.get_node_or_null(side_name)
		if side == null:
			continue
		for child: Node in side.get_children():
			if str(child.name).ends_with("Grid"):
				continue
			if child is CanvasItem:
				_stash_modulate(board, child as CanvasItem)

	var center: Node = main_layout.get_node_or_null("CenterPanel")
	if center is CanvasItem:
		_stash_modulate(board, center as CanvasItem)

func _should_skip_root(child: Node) -> bool:
	if child == self:
		return true
	if child.name in _KEEP_ROOT_NAMES:
		return true
	if child.is_in_group("battle_grid_border"):
		return true
	return false

func _stash_visibility(board: Node, node: Node) -> void:
	if not (node is CanvasItem):
		return
	var ci: CanvasItem = node as CanvasItem
	if not ci.visible:
		return
	_visibility_stash.append({
		"path": board.get_path_to(node),
		"visible": ci.visible,
	})
	ci.visible = false

func _stash_modulate(board: Node, node: CanvasItem) -> void:
	_modulate_stash.append({
		"path": board.get_path_to(node),
		"modulate": node.modulate,
		"mouse_filter": node.mouse_filter,
	})
	node.modulate = Color(node.modulate.r, node.modulate.g, node.modulate.b, 0.0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if _restoring:
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		_restore()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_restore()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_restore()
		get_viewport().set_input_as_handled()

func _restore() -> void:
	if _restoring:
		return
	_restoring = true

	var board: Node = get_parent()
	if is_instance_valid(board):
		for entry: Dictionary in _visibility_stash:
			var node: Node = board.get_node_or_null(entry["path"])
			if node is CanvasItem:
				(node as CanvasItem).visible = entry["visible"]
		for entry: Dictionary in _modulate_stash:
			var node: Node = board.get_node_or_null(entry["path"])
			if node is CanvasItem:
				var ci: CanvasItem = node as CanvasItem
				ci.modulate = entry["modulate"]
				ci.mouse_filter = entry["mouse_filter"]
		if board.has_method("refresh_grid_borders"):
			board.refresh_grid_borders()

	queue_free()
