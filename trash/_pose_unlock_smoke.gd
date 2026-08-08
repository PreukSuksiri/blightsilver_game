extends Node
## godot --headless --path . res://tools/_pose_unlock_smoke.tscn


func _ready() -> void:
	print("pose_unlock_smoke…")
	# Simulate: achievement earned, mail NOT claimed.
	AchievementManager.unlock("win_duel_nex", true)
	# Ensure claim gate is not required — clear claimed flags by using a fresh check.
	var pose_ok: bool = ProtagonistVault.is_pose_unlocked("nex", 4)
	print("  nex pose 4 unlocked after achievement (no claim required): ", pose_ok)
	if not pose_ok:
		print("SMOKE FAILED")
		get_tree().quit(1)
		return
	print("SMOKE OK")
	get_tree().quit(0)
