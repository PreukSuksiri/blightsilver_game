extends Node
# Manages the player's mailbox: mail items, rewards, and admin commands.
# Registered as autoload "MailboxManager" in project.godot.

signal mailbox_changed()
signal mail_received(mail: Dictionary)

var mail_items: Array = []   # Array of Dicts (see _make_item)
var _next_id: int = 0
var _exporter_active: bool = false


# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────

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

func get_unclaimed_count() -> int:
	var count := 0
	for item: Dictionary in mail_items:
		if not item.get("claimed", false):
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

func admin_command(raw: String) -> String:
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
				+ "  confiscate_non_deck\n"
				+ "  grant_deck_cards\n"
				+ "  grant_all_cards"
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
			var editor: Node = load("res://scripts/CampaignMapEditor.gd").new()
			editor.name = "CampaignMapEditorOverlay"
			scene.add_child(editor)
			return "Campaign Map Editor opened."

		"vn_editor":
			var scene := get_tree().current_scene
			if scene.get_node_or_null("VNEditorOverlay") != null:
				return "VN Editor is already open."
			var vned: Node = load("res://scripts/VNEditor.gd").new()
			vned.name = "VNEditorOverlay"
			scene.add_child(vned)
			if parts.size() >= 2:
				vned.call_deferred("open_file", " ".join(PackedStringArray(parts.slice(1))))
			return "VN Beat Editor opened."

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
			var editor: Node = load("res://scripts/CardEditorOverlay.gd").new()
			editor.name = "CardEditorOverlay"
			scene.add_child(editor)
			return "Card Editor opened."

		"animation_vellum_card_commence_flip":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("VellumCardCommenceAnim") != null:
				return "Animation is already running."
			var anim: Node = load("res://scripts/VellumCardCommenceAnimation.gd").new()
			anim.name = "VellumCardCommenceAnim"
			scene.add_child(anim)
			anim.call("launch", true)
			return "Vellum Card Commence (flip) animation started."

		"animation_vellum_card_commence_facedown":
			var scene: Node = get_tree().current_scene
			if scene.get_node_or_null("VellumCardCommenceAnim") != null:
				return "Animation is already running."
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
				if Collection.get_card_count(cname) == 0:
					Collection.add_card(cname, "character", "Admin")
					granted += 1
			for tname: String in CardDatabase.get_all_trap_names():
				if Collection.get_card_count(tname) == 0:
					Collection.add_card(tname, "trap", "Admin")
					granted += 1
			for ename: String in CardDatabase.get_all_tech_names():
				if Collection.get_card_count(ename) == 0:
					Collection.add_card(ename, "tech", "Admin")
					granted += 1
			if granted == 0:
				return "All cards already owned — nothing granted."
			return "Granted %d card(s)." % granted

		_:
			return "Unknown command '%s'. Type 'help'." % cmd

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
