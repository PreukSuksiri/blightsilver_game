extends Node
func _ready() -> void:
	SaveManager.load_data()
	await get_tree().process_frame
	print("claimed_nex=", AchievementManager.is_reward_claimed("win_duel_nex"))
	print("pose4=", ProtagonistVault.is_pose_unlocked("nex", 4))
	var ok: bool = AchievementManager.is_reward_claimed("win_duel_nex") \
			and ProtagonistVault.is_pose_unlocked("nex", 4)
	print("SMOKE ", "OK" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
