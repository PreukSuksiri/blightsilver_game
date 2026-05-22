extends CanvasLayer
## UIHideCapture — added by admin command "hide_ui"
## Hides all main menu UI nodes except Background and DriftingCardsLayer.
## Any key press or mouse click restores them and removes this node.

const _UI_PATHS: Array = [
	"TitleLogo", "DecoLine",
	"SettingsBtn", "NewGameBtn", "DeckBuilderBtn",
	"MailboxBtn", "ShopBtn", "GalleryBtn", "CreditsBtn",
	"DeckStatusBg", "VersionLabel",
	"SettingsIconShadow", "SettingsIconBtn",
	"ExitIconShadow", "ExitIconBtn",
	"FadeOverlay",
]

var _hidden: Array = []

func _ready() -> void:
	layer = 99

	# Hide UI nodes in the parent scene
	var scene := get_parent()
	for path: String in _UI_PATHS:
		var node: Node = scene.get_node_or_null(path)
		if node != null and node.visible:
			node.visible = false
			_hidden.append(node)

	# Transparent full-screen control to intercept mouse clicks
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.color        = Color(0.0, 0.0, 0.0, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(rect)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed:
		_restore()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_restore()

func _restore() -> void:
	for node: Node in _hidden:
		if is_instance_valid(node):
			node.visible = true
	queue_free()
