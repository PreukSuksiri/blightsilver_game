@tool
extends EditorPlugin

const REQUEST_PATH := "user://card_exporter_reimport_request.json"
const REQUEST_FILE := "card_exporter_reimport_request.json"
const REQUEST_TMP := REQUEST_FILE + ".tmp"


func _enter_tree() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if not FileAccess.file_exists(REQUEST_PATH):
		return

	var text := FileAccess.get_file_as_string(REQUEST_PATH)
	if text.is_empty():
		return

	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var req: Variant = json.get_data()
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
	var file := FileAccess.open("user://" + REQUEST_TMP, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(req))
	file.close()
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if dir.file_exists(REQUEST_FILE):
		dir.remove(REQUEST_FILE)
	dir.rename(REQUEST_TMP, REQUEST_FILE)
