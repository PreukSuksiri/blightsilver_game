extends Node
## Single entry point for granting achievement rewards (Collection + presentation).

var _ui_host: Node = null
var _last_pack_cards: Array = []
var _last_pack_name: String = ""


func grant_achievement_reward(achievement_id: String, reward: Dictionary) -> void:
	_last_pack_cards.clear()
	_last_pack_name = ""
	if reward.is_empty():
		present_achievement_only(achievement_id)
		return
	_apply_reward_to_collection(reward)
	var host: Node = _resolve_ui_host()
	if host != null:
		_present_with_host(host, achievement_id, reward)
	else:
		_mail_fallback(achievement_id, reward)


func present_achievement_only(achievement_id: String) -> void:
	var host: Node = _resolve_ui_host()
	if host != null:
		var script: GDScript = load("res://scripts/AchievementUnlockOverlay.gd") as GDScript
		if script != null:
			script.call("open", host, achievement_id, {})
	else:
		var def: Dictionary = AchievementManager.get_definition(achievement_id)
		var title: String = str(def.get("title", achievement_id))
		MailboxManager.send_mail("System", "Achievement: %s" % title, "You earned an achievement!", {})


func _apply_reward_to_collection(reward: Dictionary) -> void:
	match str(reward.get("type", "")):
		"coins", "credits":
			var amount: int = int(reward.get("amount", 0))
			if amount > 0:
				Collection.add_credits(amount)
		"card":
			var card_name: String = str(reward.get("card_name", "")).strip_edges()
			if not card_name.is_empty():
				Collection.add_card(card_name, _detect_card_type(card_name), "Achievement")
		"stage_bonus_card":
			var card_name: String = str(reward.get("card_name", "")).strip_edges()
			if not card_name.is_empty():
				Collection.add_card(card_name, _detect_card_type(card_name), "Achievement")
		"booster_pack":
			var pack_nm: String = str(reward.get("pack_name", "")).strip_edges()
			if not pack_nm.is_empty():
				_last_pack_name = pack_nm
				_last_pack_cards = ShopManager.draw_pack_free(pack_nm)
				GlobalStatManager.on_pack_opened()
		"music_disc":
			Collection.add_music_disc(int(reward.get("count", 1)))
		"union_scroll":
			Collection.add_union_scrolls(int(reward.get("count", 1)))


func _present_with_host(host: Node, achievement_id: String, reward: Dictionary) -> void:
	var script: GDScript = load("res://scripts/AchievementUnlockOverlay.gd") as GDScript
	if script == null:
		_mail_fallback(achievement_id, reward)
		return
	script.call("open", host, achievement_id, reward, _last_pack_cards, _last_pack_name)


func _mail_fallback(achievement_id: String, reward: Dictionary) -> void:
	var def: Dictionary = AchievementManager.get_definition(achievement_id)
	var title: String = str(def.get("title", achievement_id))
	MailboxManager.send_mail("System", "Achievement: %s" % title,
		"Your reward is attached.", reward.duplicate(true))


func _resolve_ui_host() -> Node:
	if _ui_host != null and is_instance_valid(_ui_host):
		return _ui_host
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var root: Node = tree.root
	if root == null:
		return null
	for child: Node in root.get_children():
		if child.name == "QuickDuel" or child.get_script() != null:
			var path: String = child.get_scene_file_path()
			if "quick_duel" in path.to_lower() or child.name == "GameBoard":
				return child
	# Prefer current scene
	var current: Node = tree.current_scene
	return current if current != null else root


func set_ui_host(host: Node) -> void:
	_ui_host = host


func clear_ui_host(host: Node) -> void:
	if _ui_host == host:
		_ui_host = null


func _detect_card_type(card_name: String) -> String:
	if CardDatabase.characters.has(card_name):
		return "character"
	if CardDatabase.traps.has(card_name):
		return "trap"
	if CardDatabase.tech_cards.has(card_name):
		return "tech"
	return "character"
