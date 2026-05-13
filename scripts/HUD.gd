extends Control

@onready var message_log: RichTextLabel = $MessageLog

const MAX_LOG_LINES: int = 8

func _ready() -> void:
	GameState.message_posted.connect(_on_message_posted)

func _on_message_posted(text: String) -> void:
	message_log.append_text("\n" + text)
	var line_count := message_log.get_line_count()
	if line_count > MAX_LOG_LINES:
		message_log.clear()
		message_log.append_text(text)
