@tool
extends EditorPlugin

const REQUEST_PATH := "user://card_exporter_reimport_request.json"


func _enter_tree() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if not FileAccess.file_exists(REQUEST_PATH):
		return

	var text := FileAccess.get_file_as_string(REQUEST_PATH)
	if text.is_empty():
		return

	var req: Variant = JSON.parse_string(text)
	if typeof(req) != TYPE_DICTIONARY:
		return
	if req.get("done", false):
		return

	var paths: PackedStringArray = PackedStringArray(req.get("paths", []))
	if paths.is_empty():
		_write_request({ "paths": [], "done": true })
		return

	var fs := get_editor_interface().get_resource_filesystem()
	if fs.is_scanning():
		return

	fs.reimport_files(paths)
	_write_request({ "paths": paths, "done": true })
	print("[CardImportRegen] Regenerated .import sidecars for %d asset(s)." % paths.size())


func _write_request(req: Dictionary) -> void:
	var file := FileAccess.open(REQUEST_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(req))
