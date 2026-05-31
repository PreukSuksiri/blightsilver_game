extends Control

signal closed()

@onready var output:     RichTextLabel = $Panel/VBox/OutputScroll/Output
@onready var input_line: LineEdit      = $Panel/VBox/InputRow/InputLine

func _ready() -> void:
	z_index = 200
	mouse_filter = MOUSE_FILTER_STOP
	$Panel/VBox/Header/CloseBtn.pressed.connect(_on_close)
	$Panel/VBox/InputRow/SendBtn.pressed.connect(_on_send)
	input_line.text_submitted.connect(_on_text_submitted)
	_print("[color=#2af][b]== ADMIN CONSOLE ==[/b][/color]  |  type [b]help[/b] for commands.")
	input_line.grab_focus()

func _on_send() -> void:
	_execute(input_line.text)
	input_line.clear()
	input_line.grab_focus()

func _on_text_submitted(text: String) -> void:
	_execute(text)
	input_line.clear()

func _execute(raw: String) -> void:
	var trimmed := raw.strip_edges()
	if trimmed.is_empty():
		return
	_print("[color=#888]> %s[/color]" % trimmed.replace("[", "[lb]"))
	var result := MailboxManager.admin_command(trimmed)
	if not result.is_empty():
		# Escape BBCode in result except colour tags we add ourselves
		var safe := result.replace("[", "[lb]")
		_print("[color=#bdf]%s[/color]" % safe)
	# Close the console after triggering a pack opening animation
	var cmd: String = trimmed.split(" ")[0].to_lower()
	if cmd == "animation_pack_opening" and not result.begins_with("Usage:"):
		_on_close()

func _print(bbtext: String) -> void:
	output.append_text(bbtext + "\n")
	# Scroll to bottom after layout update
	output.scroll_to_line(output.get_line_count())

func _on_close() -> void:
	emit_signal("closed")
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_close()
