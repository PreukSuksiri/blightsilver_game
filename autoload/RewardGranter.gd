extends Node
## Routes achievement rewards to the mailbox; rewards apply when mail is claimed.


func grant_achievement_reward(achievement_id: String, reward: Dictionary) -> void:
	var payload: Dictionary = reward.duplicate(true) if reward is Dictionary else {}
	MailboxManager.send_achievement_reward_mail(achievement_id, payload)


func present_achievement_only(achievement_id: String) -> void:
	MailboxManager.send_achievement_reward_mail(achievement_id, {})


func is_union_formula_name(card_name: String) -> bool:
	var name: String = card_name.strip_edges()
	return not name.is_empty() and UnionDatabase.get_union(name) != null


## Grant a named card reward (mail, battle, etc.). Union names unlock the formula; others go to Collection.
## Returns "union", "card", or "" when nothing was granted.
func grant_named_card_reward(card_name: String, source: String = "") -> String:
	var name: String = card_name.strip_edges()
	if name.is_empty():
		return ""
	if is_union_formula_name(name):
		SaveManager.unlock_union(name)
		return "union"
	var card_type: String = _detect_collection_card_type(name)
	if card_type == "unknown":
		return ""
	Collection.add_card(name, card_type, source)
	return "card"


## Fix saves where union-formula mail was claimed but only Collection was updated (pre-fix).
func reconcile_claimed_union_formula_rewards() -> bool:
	var changed := false
	for item: Variant in MailboxManager.mail_items:
		if not item is Dictionary:
			continue
		var mail: Dictionary = item as Dictionary
		if not bool(mail.get("claimed", false)):
			continue
		var reward: Variant = mail.get("reward", {})
		if not reward is Dictionary:
			continue
		var r: Dictionary = reward as Dictionary
		var reward_type: String = str(r.get("type", "")).strip_edges()
		if reward_type != "card" and reward_type != "stage_bonus_card":
			continue
		var union_name: String = str(r.get("card_name", "")).strip_edges()
		if union_name.is_empty() or not is_union_formula_name(union_name):
			continue
		if SaveManager.is_union_unlocked(union_name):
			continue
		SaveManager.unlock_union(union_name)
		changed = true
	return changed


func _detect_collection_card_type(card_name: String) -> String:
	if CardDatabase.get_character(card_name) != null:
		return "character"
	if CardDatabase.get_trap(card_name) != null:
		return "trap"
	if CardDatabase.get_tech(card_name) != null:
		return "tech"
	return "unknown"
