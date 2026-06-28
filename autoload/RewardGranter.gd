extends Node
## Routes achievement rewards to the mailbox; rewards apply when mail is claimed.


func grant_achievement_reward(achievement_id: String, reward: Dictionary) -> void:
	var payload: Dictionary = reward.duplicate(true) if reward is Dictionary else {}
	MailboxManager.send_achievement_reward_mail(achievement_id, payload)


func present_achievement_only(achievement_id: String) -> void:
	MailboxManager.send_achievement_reward_mail(achievement_id, {})
