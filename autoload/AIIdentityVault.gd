extends Node
## Named AI opponent identities for Quick Duel — display name + battle illustration.
## Edited via admin command: ai_identity_vault

const SAVE_PATH := "res://data/ai_identity_vault.json"
const DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]

## Bluff emoji keys authors can assign attack/avoid reaction chat for.
const BLUFF_REACTION_EMOJIS: Array[String] = [
	"😎", "🤣", "🤝", "👍", "🥺", "🧨", "🖕", "😃", "❤️", "☠️",
]

const DEF_PERSONALITY_OPTIONS: Array[String] = [
	"Frontline", "Fortress", "Watch Tower", "Mine Field", "Tomb Trap", "Bait Trap",
	"Diagonal Shield", "Cluster Defender", "Checker", "Straightforward", "Midwit",
	"Symmetric Defender", "Random Defender", "Religious", "Zoro", "Helios",
	"Helios 2", "Zoro 2", "Tomb Trap (Hard)", "Frontline (Hard)",
]

const OFF_PERSONALITY_OPTIONS: Array[String] = [
	"Center Hoarder", "Border Guard", "Corner Assassin", "Melee Fighter", "Sniper",
	"Leftist", "Rightist", "X Sabre", "Crusader", "Column Crusher", "Row Ripper",
	"Revealed Hunter", "Explorer", "Tinkerer", "Berserker", "Shadow Lurker",
	"Sleeping Dragon", "Rambo", "Spy", "X Alien", "Technophobia", "Witchhunter",
]

const SOC_PERSONALITY_OPTIONS: Array[String] = [
	"Degen", "Talkative", "Fiddly", "Flirty", "Bully", "Fun Guy", "Daredevil",
	"Vengeful", "Paranoid", "Skeptical", "Ungrateful", "Monk", "Eager", "Introvert",
]

var _entries: Array = []


func _ready() -> void:
	reload()


func reload() -> void:
	_entries.clear()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var raw: Variant = (parsed as Dictionary).get("entries", [])
		if raw is Array:
			_entries = (raw as Array).duplicate(true)


func get_entries() -> Array:
	return _entries.duplicate(true)


func get_entry(entry_id: String) -> Dictionary:
	var needle := entry_id.strip_edges()
	if needle.is_empty():
		return {}
	for e: Variant in _entries:
		if e is Dictionary and str((e as Dictionary).get("id", "")).strip_edges() == needle:
			return (e as Dictionary).duplicate(true)
	return {}


func get_birth_name(entry_id: String) -> String:
	var entry: Dictionary = get_entry(entry_id)
	if entry.is_empty():
		return ""
	var birth: String = str(entry.get("birth_name", "")).strip_edges()
	if not birth.is_empty():
		return birth
	return str(entry.get("name", "")).strip_edges()


func default_birth_name_for_entry(entry: Dictionary) -> String:
	var name: String = str(entry.get("name", "")).strip_edges()
	if name == "Nex Crowmont":
		return "Nexus Crowmont"
	return name


func pick_random_for_tier(tier: String, protagonist_id: String) -> Dictionary:
	var needle_tier := tier.strip_edges().to_lower()
	var hero_id := ProtagonistVault.normalize_id(protagonist_id)
	var candidates: Array = []
	for e: Variant in _entries:
		if not e is Dictionary:
			continue
		var entry: Dictionary = e as Dictionary
		if str(entry.get("difficulty", "")).strip_edges().to_lower() != needle_tier:
			continue
		if _is_excluded_for_protagonist(entry, hero_id):
			continue
		candidates.append(entry.duplicate(true))
	if candidates.is_empty():
		return {}
	return (candidates[randi() % candidates.size()] as Dictionary).duplicate(true)


func _is_excluded_for_protagonist(entry: Dictionary, protagonist_id: String) -> bool:
	var exclude_raw: Variant = entry.get("exclude_protagonists", [])
	if not exclude_raw is Array:
		return false
	for ex: Variant in (exclude_raw as Array):
		if ProtagonistVault.normalize_id(str(ex)) == protagonist_id:
			return true
	return false


func save_entries(entries: Array) -> bool:
	_entries = entries.duplicate(true)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"entries": _entries}, "\t"))
	f.close()
	return true


## Apply identity personality into campaign_enemy_config (empty = leave random).
## Call after deck config apply so forced cells/tech are not wiped.
func apply_personality_to_battle(entry_id: String) -> void:
	var entry: Dictionary = get_entry(entry_id)
	if entry.is_empty():
		return
	_set_or_erase_personality("ai_personality_defensive", str(entry.get("personality_defensive", "")))
	_set_or_erase_personality("ai_personality_offensive", str(entry.get("personality_offensive", "")))
	_set_or_erase_personality("ai_personality_social", str(entry.get("personality_social", "")))


func _set_or_erase_personality(key: String, value: String) -> void:
	var cleaned := value.strip_edges()
	if cleaned.is_empty() or cleaned.to_lower() == "random":
		GameState.campaign_enemy_config.erase(key)
	else:
		GameState.campaign_enemy_config[key] = cleaned


static func normalize_bluff_emoji(emoji: String) -> String:
	var e := emoji.strip_edges()
	if e == "💩":
		return "🖕"
	return e


## Reaction chat for a bluff emoji trigger: "attack" (Interested) or "avoid".
func get_bluff_reaction_chat(entry_id: String, emoji: String, trigger: String) -> String:
	var entry: Dictionary = get_entry(entry_id)
	if entry.is_empty():
		return ""
	var chats_raw: Variant = entry.get("bluff_reaction_chats", {})
	if not chats_raw is Dictionary:
		return ""
	var chats: Dictionary = chats_raw as Dictionary
	var key := normalize_bluff_emoji(emoji)
	if key.is_empty() or not chats.has(key):
		return ""
	var row_raw: Variant = chats[key]
	if not row_raw is Dictionary:
		return ""
	var row: Dictionary = row_raw as Dictionary
	var t := trigger.strip_edges().to_lower()
	if t != "attack" and t != "avoid":
		return ""
	return str(row.get(t, "")).strip_edges()
