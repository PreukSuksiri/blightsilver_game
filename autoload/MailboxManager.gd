extends Node
# Manages the player's mailbox: mail items, rewards, and admin commands.
# Registered as autoload "MailboxManager" in project.godot.

signal mailbox_changed()
signal mail_received(mail: Dictionary)

var mail_items: Array = []   # Array of Dicts (see _make_item)
var _next_id: int = 0
var _exporter_active: bool = false

const MAIL_KIND_ACHIEVEMENT := "achievement_reward"


# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────

## Send achievement reward mail (unclaimed until claimed in Inventory / Mailbox).
func send_achievement_reward_mail(achievement_id: String, reward: Dictionary = {}) -> void:
	var ach_id: String = achievement_id.strip_edges()
	var def: Dictionary = AchievementManager.get_definition(ach_id)
	var title: String = str(def.get("title", ach_id))
	var body: String = "Congratulations! Claim your reward from this message."
	var pose: String = ProtagonistVault.get_pose_reward_label_for_achievement(ach_id)
	if reward.is_empty() and not pose.is_empty():
		body = "You unlocked a new protagonist pose: %s." % pose
	elif not reward.is_empty():
		body = "Your reward is attached."
	var item := {
		"id": str(_next_id),
		"sender": "System",
		"subject": "Achievement: %s" % title,
		"body": body,
		"reward": reward.duplicate(true),
		"claimed": false,
		"timestamp": int(Time.get_unix_time_from_system()),
		"mail_kind": MAIL_KIND_ACHIEVEMENT,
		"achievement_id": ach_id,
		"menu_notified": false,
	}
	_next_id += 1
	mail_items.append(item)
	emit_signal("mail_received", item)
	emit_signal("mailbox_changed")
	SaveManager.save_data()


func is_achievement_reward_mail(item: Dictionary) -> bool:
	if str(item.get("mail_kind", "")) == MAIL_KIND_ACHIEVEMENT:
		return true
	return str(item.get("subject", "")).begins_with("Achievement:")


func has_unnotified_achievement_reward_mail() -> bool:
	for item: Dictionary in mail_items:
		if item.get("claimed", false):
			continue
		if not is_achievement_reward_mail(item):
			continue
		if bool(item.get("menu_notified", true)):
			continue
		return true
	return false


func mark_achievement_reward_mails_notified() -> void:
	var changed := false
	for item: Dictionary in mail_items:
		if item.get("claimed", false):
			continue
		if not is_achievement_reward_mail(item):
			continue
		if bool(item.get("menu_notified", false)):
			continue
		item["menu_notified"] = true
		changed = true
	if changed:
		emit_signal("mailbox_changed")
		SaveManager.save_data()


## Send a mail item to the player's inbox.
## reward dict keys:
##   type: "coins" | "card" | "booster_pack" | "stage_bonus_card" | ""
##   amount (coins), card_name (card/stage_bonus_card), pack_name (booster_pack)
func send_mail(sender: String, subject: String, body: String, reward: Dictionary = {}) -> void:
	var item := {
		"id": str(_next_id),
		"sender": sender,
		"subject": subject,
		"body": body,
		"reward": reward,
		"claimed": false,
		"timestamp": int(Time.get_unix_time_from_system()),
	}
	_next_id += 1
	mail_items.append(item)
	emit_signal("mail_received", item)
	emit_signal("mailbox_changed")
	SaveManager.save_data()

## Unclaimed mail count for menu badges. Credit mail is bulk-claimed, so all
## unclaimed credit messages count as 1 (not one per message).
func get_unclaimed_count() -> int:
	var count := 0
	var has_unclaimed_credits := false
	for item: Dictionary in mail_items:
		if item.get("claimed", false):
			continue
		var reward: Dictionary = item.get("reward", {})
		if is_credit_reward(reward):
			has_unclaimed_credits = true
		else:
			count += 1
	if has_unclaimed_credits:
		count += 1
	return count

## Claim a single mail by id. Returns the reward dict (may be empty).
func claim_mail(mail_id: String) -> Dictionary:
	for item: Dictionary in mail_items:
		if item["id"] == mail_id and not item.get("claimed", false):
			item["claimed"] = true
			emit_signal("mailbox_changed")
			SaveManager.save_data()
			return item.get("reward", {})
	return {}

## True when the mail reward grants shop credits (legacy "coins" included).
func is_credit_reward(reward: Dictionary) -> bool:
	var t: String = str(reward.get("type", ""))
	return t == "credits" or t == "coins"

## Unclaimed credit mail summary: { count: int, total: int }.
func get_unclaimed_credit_summary() -> Dictionary:
	var count: int = 0
	var total: int = 0
	for item: Dictionary in mail_items:
		if item.get("claimed", false):
			continue
		var reward: Dictionary = item.get("reward", {})
		if not is_credit_reward(reward):
			continue
		count += 1
		total += int(reward.get("amount", 0))
	return {"count": count, "total": total}

## Mark all unclaimed credit mail claimed. Returns { count, total } (does not apply credits).
func claim_all_credit_rewards() -> Dictionary:
	var count: int = 0
	var total: int = 0
	for item: Dictionary in mail_items:
		if item.get("claimed", false):
			continue
		var reward: Dictionary = item.get("reward", {})
		if not is_credit_reward(reward):
			continue
		item["claimed"] = true
		count += 1
		total += int(reward.get("amount", 0))
	if count > 0:
		emit_signal("mailbox_changed")
		SaveManager.save_data()
	return {"count": count, "total": total}

## Claim all unclaimed mail. Returns array of reward dicts.
func claim_all() -> Array:
	var rewards: Array = []
	for item: Dictionary in mail_items:
		if not item.get("claimed", false):
			item["claimed"] = true
			rewards.append(item.get("reward", {}))
	if not rewards.is_empty():
		emit_signal("mailbox_changed")
		SaveManager.save_data()
	return rewards

## Delete all claimed mail from the list.
func delete_claimed() -> void:
	var before := mail_items.size()
	mail_items = mail_items.filter(
		func(i: Dictionary) -> bool: return not i.get("claimed", false))
	if mail_items.size() != before:
		emit_signal("mailbox_changed")
		SaveManager.save_data()

# ─────────────────────────────────────────────────────────────
# Admin command parser
# ─────────────────────────────────────────────────────────────
# Commands (all space-delimited, use | to separate subject|body in `send`):
#   help
#   send <subject> | <body>
#   send_coins <amount> [subject]
#   send_card <card_name> [subject]
#   send_booster [pack_name]
#   send_stage_bonus <card_name> [stage_label]
#   list
#   clear_claimed
#   clear_all
#   grant_credits <amount>
#   remove_credits <amount>
#   reset_credits [amount]
#   reset_title_cheats
#   manage_bgm
#   menu_loading

func _dismiss_admin_console(scene: Node = null) -> void:
	if scene == null:
		scene = get_tree().current_scene
	if scene == null:
		return
	var admin: Node = scene.get_node_or_null("AdminConsoleOverlay")
	if admin == null:
		return
	if admin.has_method("_on_close"):
		admin._on_close()
	else:
		admin.queue_free()

func admin_command(raw: String) -> String:
	if not BuildConfig.admin_tools_enabled():
		return "Admin tools are disabled in this build."
	var line := raw.strip_edges()
	if line.is_empty():
		return ""
	var parts := line.split(" ", false)
	var cmd := parts[0].to_lower()

	match cmd:
		"help":
			return (
				"Commands:\n"
				+ "  send <subject> | <body>\n"
				+ "  send_coins <amount> [subject]\n"
				+ "  send_card <card_name> [subject]\n"
				+ "  send_booster [pack_name]\n"
				+ "  send_stage_bonus <card_name> [stage_label]\n"
				+ "  list\n"
				+ "  clear_claimed\n"
				+ "  clear_all\n"
				+ "  tts on|off\n"
				+ "  export_card <card_name>\n"
				+ "  export_all_cards\n"
				+ "  export_nsfw_card <card_name>\n"
				+ "  export_all_nsfw_cards\n"
				+ "  export_dead_end_card\n"
				+ "  win_battle\n"
				+ "  lose_battle\n"
				+ "  map_editor\n"
				+ "  vn_editor [filename]\n"
				+ "  ai_vs_ai\n"
				+ "  card_e2e [t1|t2|reset [t1|t2]]\n"
				+ "  card_info <card_name>\n"
				+ "  card_find <query>\n"
				+ "  list_chars\n"
				+ "  list_traps\n"
				+ "  list_tech\n"
				+ "  list_unions\n"
				+ "  unlock_union <union_name>\n"
				+ "  unlock_all_unions\n"
				+ "  lock_union <union_name>\n"
				+ "  lock_all_unions\n"
				+ "  lock_union_mechanism\n"
				+ "  unlock_union_mechanism\n"
				+ "  card_editor\n"
				+ "  animation_vellum_card_commence_flip\n"
				+ "  animation_vellum_card_commence_facedown\n"
				+ "  animation_pack_opening <pack_image> | <card1> | <card2> | <card3>\n"
				+ "  set_card_qty <card_name> | <quantity>\n"
				+ "  grant_card <card_name> [count]\n"
				+ "  confiscate_non_deck\n"
				+ "  grant_deck_cards\n"
				+ "  grant_all_cards\n"
				+ "  dungeon_builder [dungeon_id]\n"
				+ "  dungeon_activator\n"
				+ "  modifier_editor\n"
				+ "  dungeon_reset\n"
				+ "  dungeon_reset_wheel\n"
				+ "  dungeon_reset_all_wheels\n"
				+ "  clear_campaign_progress\n"
				+ "  campaign_progress_list\n"
				+ "  campaign_progress_complete <node_id>\n"
				+ "  campaign_progress_uncomplete <node_id>\n"
				+ "  campaign_progress_complete_all\n"
				+ "  list_packs\n"
				+ "  open_pack <pack_id_or_name>\n"
				+ "  grant_pack <pack_id_or_name>\n"
				+ "  grant_booster_packs [count]\n"
				+ "  pack_editor\n"
				+ "  disc_editor\n"
				+ "  list_discs\n"
				+ "  grant_disc <disc_id>\n"
				+ "  grant_winding_keys [count]\n"
				+ "  grant_incense [count]\n"
				+ "  grant_union_scroll [count]\n"
				+ "  remove_union_scroll [count]\n"
				+ "  send_union_scroll [count]\n"
				+ "  grant_credits <amount>\n"
				+ "  remove_credits <amount>\n"
				+ "  reset_credits [amount]\n"
				+ "  reset_title_cheats\n"
				+ "  demo_on\n"
				+ "  demo_off\n"
				+ "  demo_status\n"
				+ "  manage_bgm\n"
				+ "  simulate_win_lose_screen\n"
				+ "  manage_menu_buttons\n"
				+ "  manage_fonts\n"
				+ "  hide_ui\n"
				+ "  menu_loading\n"
				+ "  ai_trailer [on|off]\n"
				+ "  gallery_editor\n"
				+ "  tag_bug <card_name> | <message>\n"
				+ "  resolve_bug <card_name>\n"
				+ "  list_bugs\n"
				+ "  unlock_deckbuilding\n"
				+ "  lock_deckbuilding\n"
				+ "  manage_starting_deck\n"
				+ "  ai_deck_vault\n"
				+ "  ai_identity_vault\n"
				+ "  achievement_manager\n"
				+ "  global_stat_manager\n"
				+ "  protagonist_manager\n"
				+ "  quick_duel_reward\n"
				+ "  player_vs_ai\n"
				+ "  hot_seat\n"
			+ "  exploration_editor\n"
			+ "  exploration_play\n"
			+ "  tutorial_battle\n"
			+ "  hud_skin v1|v2"
			)

		"tts":
			if parts.size() < 2:
				return "tts: %s  —  use 'tts on' or 'tts off'" % \
					("ON" if AudioManager.tts_enabled else "OFF")
			match parts[1].to_lower():
				"on":
					AudioManager.set_tts_enabled(true)
					return "Narrator ON"
				"off":
					AudioManager.set_tts_enabled(false)
					return "Narrator OFF"
				_:
					return "Usage: tts on|off"

		"manage_bgm":
			var bgm_scene: Node = get_tree().current_scene
			if bgm_scene.get_node_or_null("BGMManagerOverlay") != null:
				return "BGM Manager is already open."
			_dismiss_admin_console(bgm_scene)
			var bgm_overlay: Node = load("res://scripts/BGMManagerOverlay.gd").new()
			bgm_overlay.name = "BGMManagerOverlay"
			bgm_scene.add_child(bgm_overlay)
			return "BGM Manager opened."

		"simulate_win_lose_screen":
			var wl_scene: Node = get_tree().current_scene
			if wl_scene.get_node_or_null("WinLoseScreenPreviewOverlay") != null:
				return "Win/Lose screen preview is already open."
			_dismiss_admin_console(wl_scene)
			var wl_overlay: Node = load("res://scripts/WinLoseScreenPreviewOverlay.gd").new()
			wl_overlay.name = "WinLoseScreenPreviewOverlay"
			wl_scene.add_child(wl_overlay)
			return "Win/Lose screen preview opened."

		"manage_menu_buttons", "manage_menu_butons":
			var menu_scene: Node = get_tree().current_scene
			if menu_scene.get_node_or_null("MenuButtonManagerOverlay") != null:
				return "Menu Button Manager is already open."
			_dismiss_admin_console(menu_scene)
			var menu_overlay: Node = load("res://scripts/MenuButtonManagerOverlay.gd").new()
			menu_overlay.name = "MenuButtonManagerOverlay"
			menu_scene.add_child(menu_overlay)
			return "Menu Button Manager opened."

		"manage_fonts", "font_manager":
			var font_scene: Node = get_tree().current_scene
			if font_scene.get_node_or_null("FontManagerOverlay") != null:
				return "Font Manager is already open."
			_dismiss_admin_console(font_scene)
			var font_overlay: Node = load("res://scripts/FontManagerOverlay.gd").new()
			font_overlay.name = "FontManagerOverlay"
			font_scene.add_child(font_overlay)
			return "Font Manager opened."

		"tutorial_battle":
			var tb_root: Node = get_tree().root
			if tb_root.get_node_or_null("TutorialBattleBuilder") != null:
				return "Tutorial Battle Builder is already open."
			var tb_scene: Node = get_tree().current_scene
			_dismiss_admin_console(tb_scene)
			var tb_overlay: Node = load("res://scripts/TutorialBattleBuilder.gd").new()
			tb_overlay.name = "TutorialBattleBuilder"
			tb_root.add_child(tb_overlay)
			return "Tutorial Battle Builder opened."

		"hud_skin":
			if parts.size() < 2 or parts[1] not in ["v1", "v2"]:
				return "hud_skin: current=%s  —  use 'hud_skin v1' or 'hud_skin v2'" % HudSkin.version
			HudSkin.set_version(parts[1])
			return "HUD skin switched to %s." % parts[1]

		"send":
			var rest := line.substr(5)   # everything after "send "
			var sep := rest.find("|")
			if sep < 0:
				return "Usage: send <subject> | <body>"
			var subject := rest.substr(0, sep).strip_edges()
			var body := rest.substr(sep + 1).strip_edges()
			if subject.is_empty():
				return "Subject cannot be empty."
			send_mail("Admin", subject, body, {})
			return "Sent: \"%s\"" % subject

		"send_coins":
			if parts.size() < 2:
				return "Usage: send_coins <amount> [subject]"
			var amount := int(parts[1])
			if amount <= 0:
				return "Amount must be positive."
			var subject := "Crystal Bonus" if parts.size() < 3 \
				else " ".join(PackedStringArray(parts.slice(2)))
			send_mail("Admin", subject,
				"You have been awarded %d crystals." % amount,
				{"type": "coins", "amount": amount})
			return "Sent %d crystals." % amount

		"send_card":
			if parts.size() < 2:
				return "Usage: send_card <card_name> [subject]"
			var card_name := parts[1]
			var subject := "Card Reward" if parts.size() < 3 \
				else " ".join(PackedStringArray(parts.slice(2)))
			send_mail("Admin", subject,
				"You received the card: %s." % card_name,
				{"type": "card", "card_name": card_name})
			return "Sent card: %s" % card_name

		"send_booster":
			var pack := "Standard Pack" if parts.size() < 2 \
				else " ".join(PackedStringArray(parts.slice(1)))
			send_mail("System", "Booster Pack",
				"A booster pack is waiting for you: %s." % pack,
				{"type": "booster_pack", "pack_name": pack})
			return "Sent booster: %s" % pack

		"send_stage_bonus":
			if parts.size() < 2:
				return "Usage: send_stage_bonus <card_name> [stage_label]"
			var card_name := parts[1]
			var stage := "Stage Clear" if parts.size() < 3 \
				else " ".join(PackedStringArray(parts.slice(2)))
			send_mail("System", stage + " Bonus",
				"Stage clear reward — bonus card: %s." % card_name,
				{"type": "stage_bonus_card", "card_name": card_name})
			return "Sent stage bonus: %s" % card_name

		"list":
			if mail_items.is_empty():
				return "Mailbox is empty."
			var out := "Mail (%d items):\n" % mail_items.size()
			for item: Dictionary in mail_items:
				var tag := "[NEW]     " if not item.get("claimed", false) else "[claimed] "
				out += "  #%s %s%s — %s\n" % [
					item["id"], tag, item.get("sender", "?"), item.get("subject", "")]
			return out.strip_edges()

		"clear_claimed":
			delete_claimed()
			return "Deleted claimed mail."

		"clear_all":
			mail_items.clear()
			_next_id = 0
			emit_signal("mailbox_changed")
			SaveManager.save_data()
			return "Cleared all mail."

		"export_card":
			if parts.size() < 2:
				return "Usage: export_card <card_name>"
			var card_name := " ".join(PackedStringArray(parts.slice(1)))
			var card_type := ""
			if CardDatabase.get_character(card_name):
				card_type = "character"
			elif CardDatabase.get_trap(card_name):
				card_type = "trap"
			elif CardDatabase.get_tech(card_name):
				card_type = "tech"
			else:
				return "Unknown card: '%s'" % card_name
			var exporter: Node = load("res://scripts/CardExporter.gd").new()
			add_child(exporter)
			exporter.export_one_card(card_name, card_type)
			return "Exporting '%s' (%s)..." % [card_name, card_type]

		"export_all_cards":
			if _exporter_active:
				return "Export already in progress."
			_exporter_active = true
			var total := (CardDatabase.get_all_character_names().size()
						+ CardDatabase.get_all_trap_names().size()
						+ CardDatabase.get_all_tech_names().size())
			var exporter: Node = load("res://scripts/CardExporter.gd").new()
			add_child(exporter)
			exporter.export_all_cards()
			return "Exporting %d cards to full_cards/... (check Output log)" % total

		"export_nsfw_card":
			if parts.size() < 2:
				return "Usage: export_nsfw_card <card_name>"
			var card_name: String = " ".join(PackedStringArray(parts.slice(1)))
			var card_type: String = ""
			if CardDatabase.get_character(card_name):
				card_type = "character"
			elif CardDatabase.get_trap(card_name):
				card_type = "trap"
			elif CardDatabase.get_tech(card_name):
				card_type = "tech"
			else:
				return "Unknown card: '%s'" % card_name
			if _exporter_active:
				return "Export already in progress."
			_exporter_active = true
			var exporter: Node = load("res://scripts/CardExporter.gd").new()
			add_child(exporter)
			exporter.export_one_nsfw_card(card_name, card_type)
			return "Exporting NSFW '%s' (%s)..." % [card_name, card_type]

		"export_all_nsfw_cards":
			if _exporter_active:
				return "Export already in progress."
			_exporter_active = true
			var exporter: Node = load("res://scripts/CardExporter.gd").new()
			add_child(exporter)
			exporter.export_all_nsfw_cards()
			return "Exporting NSFW cards (only those with _nsfw art)... (check Output log)"

		"export_dead_end_card":
			if _exporter_active:
				return "Export already in progress."
			_exporter_active = true
			var exporter: Node = load("res://scripts/CardExporter.gd").new()
			add_child(exporter)
			exporter.export_dead_end_card()
			return "Exporting dead end card to full_cards/dead_end.png..."

		"win_battle":
			if GameState.current_phase == GameState.Phase.GAME_OVER \
					or GameState.current_phase == GameState.Phase.NONE:
				return "Not in a battle."
			GameState.force_game_over(0)
			return "Player 1 wins — battle ended."

		"lose_battle":
			if GameState.current_phase == GameState.Phase.GAME_OVER \
					or GameState.current_phase == GameState.Phase.NONE:
				return "Not in a battle."
			GameState.force_game_over(1)
			return "Player 2 wins — battle ended."

		"map_editor":
			var scene := get_tree().current_scene
			if scene.get_node_or_null("CampaignMapEditorOverlay") != null:
				return "Map Editor is already open."
			_dismiss_admin_console(scene)
			var editor: Node = load("res://scripts/CampaignMapEditor.gd").new()
			editor.name = "CampaignMapEditorOverlay"
			scene.add_child(editor)
			return "Campaign Map Editor opened."

		"vn_editor":
			var scene := get_tree().current_scene
			if scene.get_node_or_null("VNEditorOverlay") != null:
				return "VN Editor is already open."
			_dismiss_admin_console(scene)
			var vned: Node = load("res://scripts/VNEditor.gd").new()
			vned.name = "VNEditorOverlay"
			scene.add_child(vned)
			if parts.size() >= 2:
				vned.call_deferred("open_file", " ".join(PackedStringArray(parts.slice(1))))
			return "VN Beat Editor opened."

		"ai_vs_ai":
			if get_tree().current_scene.name == "GameBoard":
				return "Cannot open AI vs AI while a match is in progress."
			if get_tree().current_scene.name == "AIvsAIConfig":
				return "AI vs AI config is already open."
			get_tree().change_scene_to_file("res://scenes/ai_vs_ai_config.tscn")
			return "Opening AI vs AI config..."

		"card_e2e":
			if get_tree().current_scene.name == "GameBoard":
				return "Cannot start Card E2E while a match is in progress."
			var tier_filter := 0
			if parts.size() >= 2:
				var arg := parts[1].to_lower()
				if arg == "reset":
					var rt := 0
					if parts.size() >= 3:
						if parts[2].to_lower() in ["t1", "tier1", "1"]:
							rt = 1
						elif parts[2].to_lower() in ["t2", "tier2", "2"]:
							rt = 2
					CardE2ERunner.reset_progress(rt)
					return "Card E2E progress reset (tier=%d)." % rt
				if arg in ["t1", "tier1", "1"]:
					tier_filter = 1
				elif arg in ["t2", "tier2", "2"]:
					tier_filter = 2
			var e2e_msg: String = CardE2ERunner.start_suite(true, tier_filter)
			if e2e_msg.begins_with("Started E2E"):
				return e2e_msg
			get_tree().change_scene_to_file("res://scenes/ai_vs_ai_config.tscn")
			return e2e_msg + " Open AI vs AI config to start manually."

		"card_info":
			if parts.size() < 2:
				return "Usage: card_info <card_name>"
			var cname: String = " ".join(PackedStringArray(parts.slice(1)))
			var char_data: CharacterData = CardDatabase.get_character(cname)
			if char_data:
				return (
					"[CHARACTER] %s\n" % char_data.card_name
					+ "  Affinity : %s\n" % CharacterData.Affinity.keys()[char_data.affinity]
					+ "  ATK / DEF: %d / %d\n" % [char_data.base_atk, char_data.base_def]
					+ "  Cost     : %d crystals\n" % char_data.crystal_cost
					+ "  Rarity   : %s\n" % CharacterData.Rarity.keys()[char_data.rarity]
					+ "  Ability  : %s" % char_data.ability_description
				)
			var trap_data: TrapData = CardDatabase.get_trap(cname)
			if trap_data:
				return (
					"[TRAP] %s\n" % trap_data.card_name
					+ "  Cost  : %d crystals\n" % trap_data.crystal_cost
					+ "  Rarity: %s\n" % CharacterData.Rarity.keys()[trap_data.rarity]
					+ "  Effect: %s" % trap_data.effect_description
				)
			var tech_data: TechCardData = CardDatabase.get_tech(cname)
			if tech_data:
				var chain: String = ("Requires '%s' played first" % tech_data.required_prior_card) \
					if tech_data.required_prior_card != "" else "No chain requirement"
				return (
					"[TECH] %s\n" % tech_data.card_name
					+ "  Cost  : %d crystals\n" % tech_data.crystal_cost
					+ "  Rarity: %s\n" % CharacterData.Rarity.keys()[tech_data.rarity]
					+ "  Chain : %s\n" % chain
					+ "  Effect: %s" % tech_data.effect_description
				)
			return "No card found: '%s'" % cname

		"card_find":
			if parts.size() < 2:
				return "Usage: card_find <query>"
			var query := " ".join(PackedStringArray(parts.slice(1))).to_lower()
			var hits: Array = []
			for n: String in CardDatabase.get_all_character_names():
				if n.to_lower().contains(query):
					hits.append("char  " + n)
			for n: String in CardDatabase.get_all_trap_names():
				if n.to_lower().contains(query):
					hits.append("trap  " + n)
			for n: String in CardDatabase.get_all_tech_names():
				if n.to_lower().contains(query):
					hits.append("tech  " + n)
			if hits.is_empty():
				return "No cards match '%s'." % query
			return "Found %d:\n  " % hits.size() + "\n  ".join(PackedStringArray(hits))

		"list_chars":
			var names: Array = CardDatabase.get_all_character_names()
			names.sort()
			return "Characters (%d):\n  " % names.size() \
				+ "\n  ".join(PackedStringArray(names))

		"list_traps":
			var names: Array = CardDatabase.get_all_trap_names()
			names.sort()
			return "Traps (%d):\n  " % names.size() \
				+ "\n  ".join(PackedStringArray(names))

		"list_tech":
			var names: Array = CardDatabase.get_all_tech_names()
			names.sort()
			return "Tech cards (%d):\n  " % names.size() \
				+ "\n  ".join(PackedStringArray(names))

		"card_editor":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("CardEditorOverlay") != null:
				return "Card Editor is already open."
			_dismiss_admin_console(scene)
			var editor: Node = load("res://scripts/CardEditorOverlay.gd").new()
			editor.name = "CardEditorOverlay"
			scene.add_child(editor)
			return "Card Editor opened."

		"hide_ui":
			var scene: Node = get_tree().current_scene
			if scene.name == "MainMenu":
				if scene.get_node_or_null("UIHideCapture") != null:
					return "UI is already hidden. Press any key or click to restore."
				var cap_menu: Node = load("res://scripts/UIHideCapture.gd").new()
				cap_menu.name = "UIHideCapture"
				scene.add_child(cap_menu)
				_dismiss_admin_console(scene)
				return ""
			if scene.name == "GameBoard":
				if scene.get_node_or_null("BattleUIHideCapture") != null:
					return "Battle UI is already hidden. Press any key or click to restore."
				var cap_battle: Node = load("res://scripts/BattleUIHideCapture.gd").new()
				cap_battle.name = "BattleUIHideCapture"
				scene.add_child(cap_battle)
				_dismiss_admin_console(scene)
				return "Battle UI hidden — grids and cards only. Click or press any key to restore."
			return "hide_ui only works on the Main Menu or in battle."

		"menu_loading", "show_menu_loading":
			var loading_scene: Node = get_tree().current_scene
			if loading_scene == null:
				return "ERROR: no active scene."
			if loading_scene.get_node_or_null("AdminMenuLoadingPreview") != null:
				return "Menu loading overlay is already showing. Tap to dismiss."
			_dismiss_admin_console(loading_scene)
			var loading_overlay: MenuLoadingOverlay = MenuLoadingOverlay.new()
			loading_overlay.name = "AdminMenuLoadingPreview"
			loading_overlay.z_index = 180
			loading_overlay.set_dismiss_on_tap(true)
			loading_scene.add_child(loading_overlay)
			loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			return "Menu loading overlay opened."

		"animation_vellum_card_commence_flip":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("VellumCardCommenceAnim") != null:
				return "Animation is already running."
			if SaveManager.get_active_deck() == null:
				return "No active deck — build or restore a deck first."
			var anim: Node = load("res://scripts/VellumCardCommenceAnimation.gd").new()
			anim.name = "VellumCardCommenceAnim"
			scene.add_child(anim)
			anim.call("launch", true)
			return "Vellum Card Commence (flip) animation started."

		"animation_vellum_card_commence_facedown":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("VellumCardCommenceAnim") != null:
				return "Animation is already running."
			if SaveManager.get_active_deck() == null:
				return "No active deck — build or restore a deck first."
			var anim: Node = load("res://scripts/VellumCardCommenceAnimation.gd").new()
			anim.name = "VellumCardCommenceAnim"
			scene.add_child(anim)
			anim.call("launch", false)
			return "Vellum Card Commence (face-down) animation started."

		"list_unions":
			var all_unions: Array = UnionDatabase.get_all_unions()
			all_unions.sort_custom(func(a: UnionData, b: UnionData) -> bool: return a.card_name < b.card_name)
			var lines: Array = []
			for u: UnionData in all_unions:
				var status: String = "[UNLOCKED]" if SaveManager.is_union_unlocked(u.card_name) else "[locked]  "
				lines.append("%s %s" % [status, u.card_name])
			return "Unions (%d):\n  " % all_unions.size() + "\n  ".join(PackedStringArray(lines))

		"unlock_union":
			if parts.size() < 2:
				return "Usage: unlock_union <union_name>"
			var uname: String = " ".join(PackedStringArray(parts.slice(1)))
			var u: UnionData = UnionDatabase.get_union(uname)
			if u == null:
				return "Union not found: '%s'" % uname
			SaveManager.unlock_union(uname)
			return "Unlocked union: %s" % uname

		"unlock_all_unions":
			var all_unions: Array = UnionDatabase.get_all_unions()
			for u: UnionData in all_unions:
				SaveManager.unlock_union(u.card_name)
			return "Unlocked all %d unions." % all_unions.size()

		"lock_union":
			if parts.size() < 2:
				return "Usage: lock_union <union_name>"
			var uname: String = " ".join(PackedStringArray(parts.slice(1)))
			var u: UnionData = UnionDatabase.get_union(uname)
			if u == null:
				return "Union not found: '%s'" % uname
			SaveManager.unlocked_unions.erase(uname)
			SaveManager.save_data()
			return "Locked union: %s" % uname

		"lock_all_unions":
			SaveManager.unlocked_unions.clear()
			SaveManager.save_data()
			return "Locked all unions."

		"lock_union_mechanism":
			SaveManager.set_union_mechanism_unlocked(false)
			return "Union mechanism locked — union UI hidden."

		"unlock_union_mechanism":
			SaveManager.set_union_mechanism_unlocked(true)
			return "Union mechanism unlocked — union UI visible."

		"animation_pack_opening":
			# Syntax: animation_pack_opening <pack_image> | <card1> | <card2> | <card3>
			# pack_image can be: empty, a filename ("booster_pack_basic.png"), or a full res:// path
			var rest: String = line.substr(cmd.length()).strip_edges()
			var segs: PackedStringArray = rest.split("|")
			if segs.size() < 4:
				return (
					"Usage: animation_pack_opening <pack_image> | <card1> | <card2> | <card3>\n"
					+ "  pack_image: filename, full res:// path, or empty for default\n"
					+ "  Example (with image):    animation_pack_opening booster_pack_howling_grave.png | Aether Warden | Radar | Bunker\n"
					+ "  Example (leading pipe):  animation_pack_opening | booster_pack_howling_grave.png | Aether Warden | Radar | Bunker\n"
					+ "  Example (no image):      animation_pack_opening | Aether Warden | Radar | Bunker"
				)
			var pack_img: String = segs[0].strip_edges()
			var c_start: int = 1
			# If user wrote "| filename | c1 | c2 | c3" the first segment is empty;
			# promote the next segment to pack image automatically.
			if pack_img == "" and segs.size() >= 5:
				pack_img = segs[1].strip_edges()
				c_start = 2
			# Resolve bare filename to the booster_pack folder
			if pack_img != "" and not pack_img.begins_with("res://"):
				pack_img = "res://assets/textures/cards/booster_pack/" + pack_img
			var c1: String = segs[c_start].strip_edges()     if segs.size() > c_start     else ""
			var c2: String = segs[c_start + 1].strip_edges() if segs.size() > c_start + 1 else ""
			var c3: String = segs[c_start + 2].strip_edges() if segs.size() > c_start + 2 else ""
			var overlay_script: GDScript = load("res://scripts/PackOpeningOverlay.gd")
			_dismiss_admin_console()
			overlay_script.open(get_tree().root, pack_img, c1, c2, c3)
			return "Pack opening animation started  [%s | %s | %s]" % [c1, c2, c3]

		"set_card_qty":
			var rest: String = line.substr(cmd.length()).strip_edges()
			var sep: int = rest.find("|")
			if sep < 0:
				return "Usage: set_card_qty <card_name> | <quantity>"
			var cname: String = rest.substr(0, sep).strip_edges()
			var qty: int = int(rest.substr(sep + 1).strip_edges())
			if cname.is_empty():
				return "Card name cannot be empty."
			Collection.set_card_quantity(cname, qty)
			return "Set '%s' quantity → %d" % [cname, qty]

		"grant_card":
			if parts.size() < 2:
				return "Usage: grant_card <card_name> [count]"
			var grant_count: int = 1
			var name_end: int = parts.size()
			if parts.size() >= 3 and String(parts[-1]).is_valid_int():
				grant_count = int(parts[-1])
				name_end = parts.size() - 1
				if grant_count <= 0:
					return "Count must be positive."
			var cname: String = " ".join(PackedStringArray(parts.slice(1, name_end)))
			if cname.is_empty():
				return "Card name cannot be empty."
			var card_type: String = ""
			if CardDatabase.get_character(cname):
				card_type = "character"
			elif CardDatabase.get_trap(cname):
				card_type = "trap"
			elif CardDatabase.get_tech(cname):
				card_type = "tech"
			if card_type.is_empty():
				return "Card not found: '%s'. Use card_find to search." % cname
			for _i in grant_count:
				Collection.add_card(cname, card_type, "Admin")
			var owned: int = Collection.get_card_count(cname)
			if grant_count == 1:
				return "Granted '%s' (%s). Now own %d." % [cname, card_type, owned]
			return "Granted %d × '%s' (%s). Now own %d." % [grant_count, cname, card_type, owned]

		"confiscate_non_deck":
			var protected: Array = []
			for deck in SaveManager.decks:
				for cname: String in deck.characters: protected.append(cname)
				for tname: String in deck.traps:      protected.append(tname)
				for ename: String in deck.techs:      protected.append(ename)
			var wiped: int = Collection.confiscate_except(protected)
			return "Confiscated %d card(s) not in any deck." % wiped

		"grant_deck_cards":
			var deck: Variant = SaveManager.get_active_deck()
			if deck == null:
				return "No active deck."
			var granted: Array = []
			for cname: String in deck.characters:
				if Collection.get_card_count(cname) == 0:
					Collection.add_card(cname, "character", "Admin")
					granted.append(cname)
			for tname: String in deck.traps:
				if Collection.get_card_count(tname) == 0:
					Collection.add_card(tname, "trap", "Admin")
					granted.append(tname)
			for ename: String in deck.techs:
				if Collection.get_card_count(ename) == 0:
					Collection.add_card(ename, "tech", "Admin")
					granted.append(ename)
			if granted.is_empty():
				return "All deck cards already owned — nothing granted."
			return "Granted %d card(s): %s" % [granted.size(), ", ".join(granted)]

		"grant_all_cards":
			var granted: int = 0
			for cname: String in CardDatabase.get_all_character_names():
				var cd: CharacterData = CardDatabase.get_character(cname)
				if cd == null:
					continue
				if SaveManager.demo_mode and not cd.include_in_demo:
					continue
				if Collection.get_card_count(cname) == 0:
					Collection.add_card(cname, "character", "Admin")
					granted += 1
			for tname: String in CardDatabase.get_all_trap_names():
				var td: TrapData = CardDatabase.get_trap(tname)
				if td == null:
					continue
				if SaveManager.demo_mode and not td.include_in_demo:
					continue
				if Collection.get_card_count(tname) == 0:
					Collection.add_card(tname, "trap", "Admin")
					granted += 1
			for ename: String in CardDatabase.get_all_tech_names():
				var tc: TechCardData = CardDatabase.get_tech(ename)
				if tc == null:
					continue
				if SaveManager.demo_mode and not tc.include_in_demo:
					continue
				if Collection.get_card_count(ename) == 0:
					Collection.add_card(ename, "tech", "Admin")
					granted += 1
			if granted == 0:
				return "All cards already owned — nothing granted."
			return "Granted %d card(s)." % granted

		"dungeon_builder":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("DungeonBuilderOverlay") != null:
				return "Dungeon Builder is already open."
			_dismiss_admin_console(scene)
			var builder: Node = load("res://scripts/DailyDungeonBuilder.gd").new()
			builder.name = "DungeonBuilderOverlay"
			scene.add_child(builder)
			if parts.size() >= 2:
				var dungeon_id: String = " ".join(PackedStringArray(parts.slice(1)))
				builder.call_deferred("_load_dungeon", dungeon_id)
			return "Daily Dungeon Builder opened."

		"dungeon_activator":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("DungeonActivatorOverlay") != null:
				return "Dungeon Activator is already open."
			_dismiss_admin_console(scene)
			var activator: Node = load("res://scripts/DailyDungeonActivator.gd").new()
			activator.name = "DungeonActivatorOverlay"
			scene.add_child(activator)
			return "Daily Dungeon Activator opened."

		"modifier_editor":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("ModifierEditorOverlay") != null:
				return "Modifier Editor is already open."
			_dismiss_admin_console(scene)
			var editor: Node = load("res://scripts/ModifierEditorOverlay.gd").new()
			editor.name = "ModifierEditorOverlay"
			scene.add_child(editor)
			return "Modifier Editor opened."

		"dungeon_reset":
			var dungeon_id: String = DailyDungeonManager.get_current_dungeon_id()
			if dungeon_id.is_empty():
				return "No active dungeon to reset."
			DailyDungeonManager.node_progress.erase(dungeon_id)
			DailyDungeonManager.reset_dungeon_run_wheel_state(dungeon_id)
			SaveManager.save_data()
			return "Daily dungeon progress reset: %s (spin wheel restored)" % dungeon_id

		"dungeon_reset_wheel":
			var wheel_id: String = DailyDungeonManager.get_current_dungeon_id()
			if wheel_id.is_empty():
				return "No active dungeon."
			var run: Dictionary = DailyDungeonManager.ensure_dungeon_run(wheel_id)
			run["spin_remaining"] = DailyDungeonManager.DEFAULT_SPIN_REMAINING
			DailyDungeonManager.dungeon_runs[wheel_id] = run
			SaveManager.save_data()
			return "Spin wheel limit reset to 1 for %s." % wheel_id

		"dungeon_reset_all_wheels":
			var reset_count: int = DailyDungeonManager.reset_all_dungeon_spin_remaining()
			SaveManager.save_data()
			if reset_count == 0:
				return "No dungeon runs found — nothing to reset."
			return "Spin wheel limit reset to 1 for %d dungeon(s)." % reset_count

		"clear_campaign_progress":
			var count: int = CampaignManager.completed.size()
			CampaignManager.completed.clear()
			CampaignManager.active_node_id = ""
			CampaignManager.pending_result = {}
			SaveManager.save_data()
			return "Campaign progress cleared (%d nodes were completed)." % count

		"campaign_progress_list":
			if CampaignManager.completed.is_empty():
				return "No campaign nodes completed yet."
			var completed_ids: Array = CampaignManager.completed.keys()
			completed_ids.sort()
			return "Completed (%d/%d):\n  " % [completed_ids.size(), CampaignManager.count_total()] \
				+ "\n  ".join(PackedStringArray(completed_ids))

		"campaign_progress_complete":
			if parts.size() < 2:
				return "Usage: campaign_progress_complete <node_id>"
			var node_id: String = parts[1]
			if CampaignManager.get_node_data(node_id) == null:
				return "Unknown node id '%s'. Use campaign_progress_list to see valid ids." % node_id
			CampaignManager.completed[node_id] = true
			SaveManager.save_data()
			return "Marked '%s' as completed." % node_id

		"campaign_progress_uncomplete":
			if parts.size() < 2:
				return "Usage: campaign_progress_uncomplete <node_id>"
			var node_id: String = parts[1]
			if not CampaignManager.completed.has(node_id):
				return "'%s' is not in the completed list." % node_id
			CampaignManager.completed.erase(node_id)
			SaveManager.save_data()
			return "Removed '%s' from completed." % node_id

		"campaign_progress_complete_all":
			var added: int = 0
			for node in CampaignManager.all_nodes:
				if not CampaignManager.completed.has(node.id):
					CampaignManager.completed[node.id] = true
					added += 1
			SaveManager.save_data()
			return "All %d nodes marked as completed (%d were already done)." % \
				[CampaignManager.count_total(), CampaignManager.count_total() - added]

		"list_packs":
			var lines: Array = []
			for p: Dictionary in ShopManager.get_all_packs():
				lines.append("  [%s]  %s  —  %d cr  (%s)" % [
					p.get("id",""), p.get("name",""),
					p.get("price", 0),
					", ".join(PackedStringArray(
						p.get("slots",[]).map(func(s: Dictionary) -> String:
							return "%dx %s" % [s.get("count",1), s.get("type","?")])
					))
				])
			return "Packs:\n" + "\n".join(PackedStringArray(lines))

		"open_pack":
			# Open a pack with full animation (deducting credits)
			if parts.size() < 2:
				return "Usage: open_pack <pack_id_or_name>"
			var query: String = " ".join(PackedStringArray(parts.slice(1)))
			var pack: Dictionary = ShopManager.get_pack(query)
			if pack.is_empty():
				pack = ShopManager.get_pack_by_name(query)
			if pack.is_empty():
				return "Pack not found: '%s'. Use list_packs to see available packs." % query
			var result: Dictionary = ShopManager.purchase_pack(pack.get("id",""))
			if result.get("error", "") != "":
				return "Purchase failed: %s" % result["error"]
			var cards: Array = result.get("cards", [])
			var c1: String = (cards[0] as Dictionary).get("name","") if cards.size() > 0 else ""
			var c2: String = (cards[1] as Dictionary).get("name","") if cards.size() > 1 else ""
			var c3: String = (cards[2] as Dictionary).get("name","") if cards.size() > 2 else ""
			var pack_img: String = str(pack.get("pack_image", ""))
			var pack_nm: String  = str(pack.get("name",""))
			var overlay_script: GDScript = load("res://scripts/PackOpeningOverlay.gd") as GDScript
			if overlay_script:
				overlay_script.open(get_tree().root, pack_img, c1, c2, c3, true, pack_nm)
			return "Opened %s: %s, %s, %s" % [pack_nm, c1, c2, c3]

		"grant_pack":
			# Grant a pack for free (no credit cost) with full animation
			if parts.size() < 2:
				return "Usage: grant_pack <pack_id_or_name>"
			var query: String = " ".join(PackedStringArray(parts.slice(1)))
			var pack: Dictionary = ShopManager.get_pack(query)
			if pack.is_empty():
				pack = ShopManager.get_pack_by_name(query)
			if pack.is_empty():
				return "Pack not found: '%s'. Use list_packs to see available packs." % query
			# draw_pack_free already adds cards to Collection
			var cards: Array = ShopManager.draw_pack_free(pack.get("name",""))
			var c1: String = (cards[0] as Dictionary).get("name","") if cards.size() > 0 else ""
			var c2: String = (cards[1] as Dictionary).get("name","") if cards.size() > 1 else ""
			var c3: String = (cards[2] as Dictionary).get("name","") if cards.size() > 2 else ""
			var pack_img: String = str(pack.get("pack_image", ""))
			var pack_nm: String  = str(pack.get("name",""))
			var overlay_script: GDScript = load("res://scripts/PackOpeningOverlay.gd") as GDScript
			if overlay_script:
				overlay_script.open(get_tree().root, pack_img, c1, c2, c3, true, pack_nm)
			return "Granted %s (free): %s, %s, %s" % [pack_nm, c1, c2, c3]

		"grant_booster_packs":
			var pack_count: int = 1
			if parts.size() >= 2:
				pack_count = int(parts[1])
			if pack_count <= 0:
				return "Count must be positive."
			var boosters: Array = []
			for p: Dictionary in ShopManager.get_all_packs_unfiltered():
				var pool: Variant = p.get("card_pool", null)
				if pool is Array and not (pool as Array).is_empty():
					boosters.append(p)
			if boosters.is_empty():
				return "No booster packs with card pools found."
			var mail_sent: int = 0
			var lines: Array = []
			for p: Dictionary in boosters:
				var pack_name: String = str(p.get("name", ""))
				if pack_name.is_empty():
					continue
				for _i: int in range(pack_count):
					send_mail(
						"Admin",
						"Booster Pack",
						"A booster pack is waiting for you: %s." % pack_name,
						{"type": "booster_pack", "pack_name": pack_name})
					mail_sent += 1
				lines.append("  %s ×%d" % [pack_name, pack_count])
			return (
				"Sent %d booster pack(s) to mail (%d types):\n"
				% [mail_sent, boosters.size()]
				+ "\n".join(PackedStringArray(lines))
			)

		"disc_editor":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("MusicDiscEditorOverlay") != null:
				return "Music Disc Editor is already open."
			_dismiss_admin_console(scene)
			var editor: Node = load("res://scripts/MusicDiscEditorOverlay.gd").new()
			editor.name = "MusicDiscEditorOverlay"
			scene.add_child(editor)
			return "Music Disc Editor opened."

		"list_discs":
			var products: Array = ShopManager.get_all_disc_products()
			if products.is_empty():
				return "No disc products defined. Use disc_editor to create some."
			var lines: Array = []
			for p: Dictionary in products:
				lines.append("  [%s]  %s  —  %d cr  |  %s" % [
					p.get("id",""), p.get("name",""),
					p.get("price", 0),
					p.get("music_path","(no file)"),
				])
			return "Disc products:\n" + "\n".join(PackedStringArray(lines))

		"grant_disc":
			if parts.size() < 2:
				return "Usage: grant_disc <disc_id>"
			var disc_id: String = " ".join(PackedStringArray(parts.slice(1)))
			var product: Dictionary = ShopManager.get_disc_product(disc_id)
			if product.is_empty():
				return "Disc product not found: '%s'. Use list_discs." % disc_id
			Collection.add_disc(disc_id)
			return "Granted disc '%s' (%s)." % [disc_id, product.get("name","")]

		"grant_winding_keys":
			var count: int = 1
			if parts.size() >= 2:
				count = int(parts[1])
			if count <= 0:
				return "Count must be positive."
			Collection.add_winding_keys(count)
			return "Granted %d winding key(s). Total: %d" % [count, Collection.winding_keys]

		"grant_incense":
			var count: int = 1
			if parts.size() >= 2:
				count = int(parts[1])
			if count <= 0:
				return "Count must be positive."
			Collection.add_incenses(count)
			return "Granted %d incense(s). Total: %d" % [count, Collection.incenses]

		"grant_union_scroll":
			var scroll_count: int = 1
			if parts.size() >= 2:
				scroll_count = int(parts[1])
			if scroll_count <= 0:
				return "Count must be positive."
			Collection.add_union_scrolls(scroll_count)
			return "Granted %d Union Scroll(s). Total: %d" % [scroll_count, Collection.union_scrolls]

		"remove_union_scroll":
			var remove_count: int = 1
			if parts.size() >= 2:
				remove_count = int(parts[1])
			if remove_count <= 0:
				return "Count must be positive."
			Collection.remove_union_scrolls(remove_count)
			return "Removed %d Union Scroll(s). Total: %d" % [remove_count, Collection.union_scrolls]

		"send_union_scroll":
			var mail_count: int = 1
			if parts.size() >= 2:
				mail_count = int(parts[1])
			if mail_count <= 0:
				return "Count must be positive."
			UnionScrollManager.grant_union_scroll_mail(mail_count, "", "Admin")
			return "Sent mailbox mail with %d Union Scroll(s)." % mail_count

		"grant_credits":
			if parts.size() < 2:
				return "Usage: grant_credits <amount>"
			var grant_amount: int = int(parts[1])
			if grant_amount <= 0:
				return "Amount must be positive."
			Collection.add_credits(grant_amount)
			return "Granted %d credits. Balance: %d" % [grant_amount, Collection.credits]

		"remove_credits":
			if parts.size() < 2:
				return "Usage: remove_credits <amount>"
			var remove_amount: int = int(parts[1])
			if remove_amount <= 0:
				return "Amount must be positive."
			var before_remove: int = Collection.credits
			Collection.remove_credits(remove_amount)
			return "Removed %d credits. Balance: %d (was %d)" % [
				mini(remove_amount, before_remove), Collection.credits, before_remove]

		"reset_credits":
			var reset_amount: int = Collection.STARTING_CREDITS
			if parts.size() >= 2:
				reset_amount = int(parts[1])
			if reset_amount < 0:
				return "Amount cannot be negative."
			var before_reset: int = Collection.credits
			Collection.set_credits(reset_amount)
			return "Credits reset to %d (was %d)." % [Collection.credits, before_reset]

		"reset_title_cheats":
			SaveManager.reset_title_cheats()
			var menu_scene: Node = get_tree().current_scene
			if menu_scene != null and menu_scene.has_method("refresh_title_cheats_from_save"):
				menu_scene.refresh_title_cheats_from_save()
			return "Title screen cheat quotas reset (apartment 10,000 cr + moon 2,500 cr)."

		"pack_editor":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("PackEditorOverlay") != null:
				return "Pack Editor is already open."
			_dismiss_admin_console(scene)
			var editor: Node = load("res://scripts/PackEditorOverlay.gd").new()
			editor.name = "PackEditorOverlay"
			scene.add_child(editor)
			return "Pack Editor opened."

		"demo_on":
			SaveManager.set_demo_mode(true)
			return "Demo mode ON. Card Gallery will show only demo-flagged cards."

		"demo_off":
			SaveManager.set_demo_mode(false)
			return "Demo mode OFF. Card Gallery shows all cards."

		"demo_status":
			var state: String = "ON" if SaveManager.demo_mode else "OFF"
			var flagged: int = 0
			for cname: String in CardDatabase.characters:
				if (CardDatabase.characters[cname] as CharacterData).include_in_demo:
					flagged += 1
			for tname: String in CardDatabase.traps:
				if (CardDatabase.traps[tname] as TrapData).include_in_demo:
					flagged += 1
			for ename: String in CardDatabase.tech_cards:
				if (CardDatabase.tech_cards[ename] as TechCardData).include_in_demo:
					flagged += 1
			return "Demo mode: %s\nCards flagged for demo: %d" % [state, flagged]

		# ── ai_trailer — set / clear trailer AI personalities ───────────────
		"ai_trailer":
			# Usage: ai_trailer [on|off]   (default: on)
			var sub: String = (parts[1].to_lower() if parts.size() > 1 else "")
			if sub == "off" or sub == "clear":
				GameState.campaign_enemy_config.erase("ai_personality_defensive")
				GameState.campaign_enemy_config.erase("ai_personality_offensive")
				GameState.campaign_enemy_config.erase("ai_personality_social")
				return "Trailer AI personalities cleared. Next VS AI game uses random personalities."
			else:
				GameState.campaign_enemy_config["ai_personality_defensive"] = "Trailer Defensive"
				GameState.campaign_enemy_config["ai_personality_offensive"] = "Trailer Offensive"
				GameState.campaign_enemy_config["ai_personality_social"]    = "Trailer Social"
				return ("Trailer AI personalities set.\n"
					+ "  Defensive: Trailer Defensive (Explosive Barrels centre, strong chars border)\n"
					+ "  Offensive: Trailer Offensive (attack x2, target 💩/🖕 first, ATK tech only, no union)\n"
					+ "  Social:    Trailer Social (laugh 🤣 on every character kill)\n"
					+ "Start a VS AI game to apply. Use 'ai_trailer off' to revert.")

		"ai_no_placeholder":
			SaveManager.ai_exclude_placeholder = true
			return "AI deck pool will exclude placeholder-art cards this session."

		"ai_no_placeholder_off":
			SaveManager.ai_exclude_placeholder = false
			return "AI deck pool restored to full card pool."

		# ── Gallery Campaign Editor ──────────────────────────────
		"gallery_editor":
			var scene := get_tree().current_scene
			if scene.get_node_or_null("CampaignGalleryEditorOverlay") != null:
				return "Gallery Editor is already open."
			_dismiss_admin_console(scene)
			var ed: Node = load("res://scripts/CampaignGalleryEditor.gd").new()
			ed.name = "CampaignGalleryEditorOverlay"
			scene.add_child(ed)
			return "Campaign Gallery Editor opened."

		"tag_bug":
			var rest_tag: String = line.substr(cmd.length()).strip_edges()
			if rest_tag.is_empty():
				return "Usage: tag_bug <card_name> | <message>"
			var sep_tag: int = rest_tag.find("|")
			var cname_tag: String
			var msg_tag: String = ""
			if sep_tag >= 0:
				cname_tag = rest_tag.substr(0, sep_tag).strip_edges()
				msg_tag   = rest_tag.substr(sep_tag + 1).strip_edges()
			else:
				cname_tag = rest_tag
			if cname_tag.is_empty():
				return "Usage: tag_bug <card_name> | <message>"
			SaveManager.tag_bug(cname_tag, msg_tag)
			return "Bugged: %s" % cname_tag if msg_tag.is_empty() \
				else "Bugged: %s — %s" % [cname_tag, msg_tag]

		"resolve_bug":
			var cname_res: String = line.substr(cmd.length()).strip_edges()
			if cname_res.is_empty():
				return "Usage: resolve_bug <card_name>"
			if not SaveManager.is_bugged(cname_res):
				return "'%s' is not tagged as bugged." % cname_res
			SaveManager.resolve_bug(cname_res)
			return "Bug resolved: %s" % cname_res

		"list_bugs":
			if SaveManager.bugged_cards.is_empty():
				return "No bugged cards."
			var lines: Array = []
			for cname: String in SaveManager.bugged_cards:
				var msg: String = SaveManager.bugged_cards[cname] as String
				lines.append(("  %s — %s" % [cname, msg]) if msg != "" else ("  %s" % cname))
			return "Bugged cards:\n" + "\n".join(lines)

		# ── Deckbuilding gate ────────────────────────────────────
		"unlock_deckbuilding":
			SaveManager.deckbuilding_unlocked     = true
			SaveManager.deckbuilding_admin_locked = false
			SaveManager.save_data()
			return "Deckbuilding unlocked (admin override — bypasses prologue gate)."

		"lock_deckbuilding":
			SaveManager.deckbuilding_admin_locked = true
			SaveManager.deckbuilding_unlocked     = false
			SaveManager.save_data()
			return "Deckbuilding hard-locked (overrides even prologue completion)."

		# ── Starting Deck Manager ────────────────────────────────
		"manage_starting_deck":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("StartingDeckManagerOverlay") != null:
				return "Starting Deck Manager is already open."
			_dismiss_admin_console(scene)
			var mgr: Node = load("res://scripts/StartingDeckManager.gd").new()
			mgr.name = "StartingDeckManagerOverlay"
			scene.add_child(mgr)
			return "Starting Deck Manager opened."

		"ai_deck_vault":
			var vault_scene: Node = get_tree().current_scene
			if vault_scene.get_node_or_null("AIDeckVaultManagerOverlay") != null:
				return "AI Deck Vault is already open."
			_dismiss_admin_console(vault_scene)
			var vault_mgr: Node = load("res://scripts/AIDeckVaultManager.gd").new()
			vault_mgr.name = "AIDeckVaultManagerOverlay"
			vault_scene.add_child(vault_mgr)
			return "AI Deck Vault opened."

		"ai_identity_vault":
			var id_scene: Node = get_tree().current_scene
			if id_scene.get_node_or_null("AIIdentityVaultManagerOverlay") != null:
				return "AI Identity Vault is already open."
			_dismiss_admin_console(id_scene)
			var id_mgr: Node = load("res://scripts/AIIdentityVaultManager.gd").new()
			id_mgr.name = "AIIdentityVaultManagerOverlay"
			id_scene.add_child(id_mgr)
			return "AI Bot Identity Vault opened."

		"achievement_manager":
			var ach_scene: Node = get_tree().current_scene
			if ach_scene.get_node_or_null("ProgressAdminOverlay") != null:
				return "Progress Admin is already open."
			_dismiss_admin_console(ach_scene)
			ProgressAdminOverlay.open(ach_scene, "achievements")
			return "Achievement Manager opened."

		"global_stat_manager":
			var stat_scene: Node = get_tree().current_scene
			if stat_scene.get_node_or_null("ProgressAdminOverlay") != null:
				return "Progress Admin is already open."
			_dismiss_admin_console(stat_scene)
			ProgressAdminOverlay.open(stat_scene, "stats")
			return "Global Stat Manager opened."

		"protagonist_manager":
			var pro_scene: Node = get_tree().current_scene
			if pro_scene.get_node_or_null("ProtagonistManagerOverlay") != null:
				return "Protagonist Manager is already open."
			_dismiss_admin_console(pro_scene)
			ProtagonistManagerOverlay.open(pro_scene)
			return "Protagonist Manager opened."

		"quick_duel_reward":
			var qd_scene: Node = get_tree().current_scene
			if qd_scene.get_node_or_null("QuickDuelRewardEditor") != null:
				return "Quick Duel Reward Editor is already open."
			_dismiss_admin_console(qd_scene)
			var qd_mgr: Node = load("res://scripts/QuickDuelRewardEditor.gd").new()
			qd_mgr.name = "QuickDuelRewardEditor"
			qd_scene.add_child(qd_mgr)
			return "Quick Duel Reward Editor opened."

		# ── Quick-start match modes ─────────────────────────────
		"player_vs_ai":
			if get_tree().current_scene.name == "GameBoard":
				return "Cannot start VS AI while a match is in progress."
			BGMManager.stop(0.0)
			_dismiss_admin_console()
			CheckerTransition.fade_out_to_battle(func() -> void:
				get_tree().change_scene_to_file("res://scenes/vs_ai_config.tscn"))
			return ""

		"hot_seat":
			if get_tree().current_scene.name == "GameBoard":
				return "Cannot start Hot Seat while a match is in progress."
			BGMManager.stop(0.0)
			GameState.game_mode = GameState.GameMode.HOT_SEAT
			_dismiss_admin_console()
			CheckerTransition.fade_out_to_battle(func() -> void:
				get_tree().change_scene_to_file("res://scenes/game_board.tscn"))
			return ""

		"exploration_editor":
			_dismiss_admin_console()
			get_tree().change_scene_to_file("res://scenes/exploration_editor.tscn")
			return ""

		"exploration_play":
			var current_scene_ep: Node = get_tree().current_scene
			if current_scene_ep.get_node_or_null("ExplorationLauncherOverlay") != null:
				return "Exploration Launcher is already open."
			_dismiss_admin_console(current_scene_ep)
			var launcher: Node = load("res://scripts/ExplorationLauncherOverlay.gd").new()
			launcher.name = "ExplorationLauncherOverlay"
			current_scene_ep.add_child(launcher)
			return ""

		_:
			return "Unknown command '%s'. Type 'help'." % cmd

# ─────────────────────────────────────────────────────────────
# Gallery helpers
# ─────────────────────────────────────────────────────────────
const _GALLERY_PATH := "res://campaign/gallery_data.json"

func _gallery_load() -> Array:
	if not FileAccess.file_exists(_GALLERY_PATH):
		return []
	var f := FileAccess.open(_GALLERY_PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed as Array if parsed is Array else []

func _gallery_save(data: Array) -> void:
	var f := FileAccess.open(_GALLERY_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

# ─────────────────────────────────────────────────────────────
# Serialisation — called by SaveManager
# ─────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"next_id": _next_id,
		"items": mail_items.duplicate(true),
	}

func load_from_dict(d: Dictionary) -> void:
	_next_id = d.get("next_id", 0)
	mail_items = d.get("items", [])
