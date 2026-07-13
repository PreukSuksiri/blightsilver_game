extends Node
# Authored messenger/chat conversations shown as read-only evidence in VN scenes.
# Edited via admin command: messenger_vault
#
# Conversation schema:
# {
#   id, title, reveal_mode ("all" | "tap"), right_side,
#   participants: [ { name, avatar } ],            (max MAX_PARTICIPANTS)
#   messages:     [ { from, time, text, image } ]  (text and/or image)
# }
#
# VN beat key: show_messenger — conversation id to display as an overlay.

const SAVE_PATH := "res://data/messenger_vault.json"
const MAX_PARTICIPANTS := 5

var _conversations: Array = []


func _ready() -> void:
	reload()


func reload() -> void:
	_conversations.clear()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var raw: Variant = (parsed as Dictionary).get("conversations", [])
		if raw is Array:
			_conversations = (raw as Array).duplicate(true)


func get_conversations() -> Array:
	return _conversations.duplicate(true)


func get_conversation(conversation_id: String) -> Dictionary:
	var needle := conversation_id.strip_edges()
	for c: Variant in _conversations:
		if c is Dictionary and str((c as Dictionary).get("id", "")) == needle:
			return (c as Dictionary).duplicate(true)
	return {}


func get_all_ids() -> Array:
	var out: Array = []
	for c: Variant in _conversations:
		if not c is Dictionary:
			continue
		var cid: String = str((c as Dictionary).get("id", "")).strip_edges()
		if not cid.is_empty():
			out.append(cid)
	return out


func populate_conversation_option(opt: OptionButton, none_label: String = "(none)") -> void:
	if opt == null:
		return
	opt.clear()
	opt.add_item(none_label)
	opt.set_item_metadata(0, "")
	reload()
	var idx := 1
	for c: Variant in _conversations:
		if not c is Dictionary:
			continue
		var cd: Dictionary = c as Dictionary
		var cid: String = str(cd.get("id", "")).strip_edges()
		if cid.is_empty():
			continue
		var title: String = str(cd.get("title", "")).strip_edges()
		opt.add_item("%s — %s" % [cid, title] if not title.is_empty() else cid)
		opt.set_item_metadata(idx, cid)
		idx += 1


func option_conversation_id(opt: OptionButton) -> String:
	if opt == null or opt.selected < 0:
		return ""
	return str(opt.get_item_metadata(opt.selected)).strip_edges()


func select_conversation_option(opt: OptionButton, conversation_id: String) -> void:
	if opt == null:
		return
	var needle := conversation_id.strip_edges()
	for i: int in range(opt.item_count):
		if str(opt.get_item_metadata(i)).strip_edges() == needle:
			opt.select(i)
			return
	opt.select(0)


func save_conversations(conversations: Array) -> bool:
	_conversations = conversations.duplicate(true)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"conversations": _conversations}, "\t"))
	f.close()
	return true
