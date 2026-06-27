extends Node
class_name AchievementCelebrationRunner

var _achievement_id: String = ""
var _reward: Dictionary = {}
var _pack_cards: Array = []
var _pack_name: String = ""


static func play(
		host: Node,
		achievement_id: String,
		reward: Dictionary = {},
		pack_cards: Array = [],
		pack_name: String = ""
) -> void:
	if host == null:
		return
	var runner := AchievementCelebrationRunner.new()
	runner._achievement_id = achievement_id
	runner._reward = reward.duplicate(true) if reward is Dictionary else {}
	runner._pack_cards = pack_cards.duplicate(true) if pack_cards is Array else []
	runner._pack_name = pack_name
	host.add_child(runner)


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _play_item_reward()
	await _play_pose_reward()
	queue_free()


func _play_item_reward() -> void:
	var t: String = str(_reward.get("type", ""))
	if t == "booster_pack" and not _pack_cards.is_empty():
		var pack_img: String = ""
		if not _pack_name.is_empty():
			var pack_dict: Dictionary = ShopManager.get_pack_by_name(_pack_name)
			pack_img = str(pack_dict.get("pack_image", ""))
		var get_name := func(i: int) -> String:
			if i >= _pack_cards.size():
				return ""
			var entry: Variant = _pack_cards[i]
			if entry is Dictionary:
				return (entry as Dictionary).get("name", "")
			return str(entry)
		var overlay: PackOpeningOverlay = PackOpeningOverlay.open(
			get_parent(),
			pack_img,
			get_name.call(0),
			get_name.call(1),
			get_name.call(2))
		await overlay.reveal_finished
	elif t == "card" or t == "stage_bonus_card":
		var card_name: String = str(_reward.get("card_name", "")).strip_edges()
		if card_name.is_empty():
			return
		var overlay: PackOpeningOverlay = PackOpeningOverlay.open_single_card_reveal(
			get_parent(), card_name)
		await overlay.reveal_finished


func _play_pose_reward() -> void:
	var pose_info: Dictionary = ProtagonistVault.get_pose_reward_for_achievement(_achievement_id)
	if pose_info.is_empty():
		return
	var portrait_path: String = str(pose_info.get("portrait_path", "")).strip_edges()
	if portrait_path.is_empty() or not ResourceLoader.exists(portrait_path):
		return
	var label: String = str(pose_info.get("label", "")).strip_edges()
	var overlay: PackOpeningOverlay = PackOpeningOverlay.open_pose_reveal(
		get_parent(), portrait_path, label)
	await overlay.reveal_finished
