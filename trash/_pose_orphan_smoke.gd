extends Node
## godot --headless --path . res://tools/_pose_orphan_smoke.tscn


func _ready() -> void:
	print("pose_orphan_smoke…")
	SaveManager.load_data()
	await get_tree().process_frame
	var unlocked: bool = AchievementManager.is_unlocked("win_duel_nex")
	var granted: bool = AchievementManager.is_reward_granted("win_duel_nex")
	var claimed: bool = MailboxManager.is_achievement_reward_claimed("win_duel_nex")
	var pose4: bool = ProtagonistVault.is_pose_unlocked("nex", 4)
	print("  unlocked=", unlocked, " granted=", granted, " claimed=", claimed, " pose4=", pose4)
	var ok: bool = unlocked and granted and claimed and pose4
	# Unclaimed mail must still block.
	MailboxManager.send_achievement_reward_mail("win_duel_mayu", {})
	AchievementManager.unlock("win_duel_mayu", true)
	var mayu_blocked: bool = not MailboxManager.is_achievement_reward_claimed("win_duel_mayu") \
			or not ProtagonistVault.is_pose_unlocked("mayu", 4)
	# mayu pose index - check protagonists.json; mayu pose 4 might be win_duel_mayu
	print("  mayu unclaimed still locked path claimed=", MailboxManager.is_achievement_reward_claimed("win_duel_mayu"))
	if ok and not MailboxManager.is_achievement_reward_claimed("win_duel_mayu"):
		print("SMOKE OK")
		get_tree().quit(0)
	else:
		print("SMOKE FAILED")
		get_tree().quit(1)
