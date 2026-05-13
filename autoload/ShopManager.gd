extends Node
# Defines booster packs and handles purchase + free-draw logic.
# Registered as autoload "ShopManager" in project.godot.

# ─────────────────────────────────────────────────────────────
# Pack catalogue
# ─────────────────────────────────────────────────────────────
# Each pack entry:
#   id:          String  — unique key used in purchase_pack()
#   name:        String  — display name; also stored in card "from_pack" field
#   price:       int     — credits cost
#   description: String
#   slots:       Array[{type, count}]  — what card types and how many
#   accent:      Color   — UI accent colour
const PACKS: Array = [
	{
		"id": "starter",
		"name": "Starter Pack",
		"price": 500,
		"description": "One Character, one Trap, one Tech.\nA balanced start for any collection.",
		"slots": [
			{"type": "character", "count": 1},
			{"type": "trap",      "count": 1},
			{"type": "tech",      "count": 1},
		],
		"accent": Color(0.18, 0.65, 1.0),
	},
	{
		"id": "fighters",
		"name": "Fighters Pack",
		"price": 900,
		"description": "Three Characters.\nExpand your battle roster with new fighters.",
		"slots": [
			{"type": "character", "count": 3},
		],
		"accent": Color(1.0, 0.38, 0.25),
	},
	{
		"id": "trapmaster",
		"name": "Trapmaster Pack",
		"price": 900,
		"description": "Two Traps and one Tech card.\nMaster the art of the ambush.",
		"slots": [
			{"type": "trap", "count": 2},
			{"type": "tech", "count": 1},
		],
		"accent": Color(0.62, 0.22, 1.0),
	},
	{
		"id": "premium",
		"name": "Premium Pack",
		"price": 1800,
		"description": "Two Characters and one Tech card.\nPremium selection for serious collectors.",
		"slots": [
			{"type": "character", "count": 2},
			{"type": "tech",      "count": 1},
		],
		"accent": Color(1.0, 0.78, 0.1),
	},
]

const MUSIC_DISC_PRICE: int = 300

# ─────────────────────────────────────────────────────────────
# Music disc purchase
# ─────────────────────────────────────────────────────────────
## Returns true on success, false if insufficient credits.
func purchase_music_disc() -> bool:
	if not Collection.spend_credits(MUSIC_DISC_PRICE):
		return false
	Collection.add_music_disc(1)
	return true

# ─────────────────────────────────────────────────────────────
# Lookup
# ─────────────────────────────────────────────────────────────
func get_all_packs() -> Array:
	return PACKS

func get_pack(pack_id: String) -> Dictionary:
	for p: Dictionary in PACKS:
		if p["id"] == pack_id:
			return p
	return {}

func get_pack_by_name(pack_name: String) -> Dictionary:
	for p: Dictionary in PACKS:
		if p["name"] == pack_name:
			return p
	return {}

# ─────────────────────────────────────────────────────────────
# Purchase (deducts credits, adds cards to Collection)
# ─────────────────────────────────────────────────────────────
## Returns:
##   {"success": bool, "cards": Array[{name, type, from_pack}], "error": String}
func purchase_pack(pack_id: String) -> Dictionary:
	var pack := get_pack(pack_id)
	if pack.is_empty():
		return {"success": false, "cards": [], "error": "Unknown pack."}

	if not Collection.spend_credits(pack["price"]):
		return {"success": false, "cards": [], "error": "Not enough credits."}

	var cards := _draw_cards(pack)
	for card: Dictionary in cards:
		Collection.add_card(card["name"], card["type"], card["from_pack"])
	return {"success": true, "cards": cards, "error": ""}

# ─────────────────────────────────────────────────────────────
# Free draw (mailbox booster rewards — no credit cost)
# ─────────────────────────────────────────────────────────────
## Draws cards from the named pack without spending credits,
## and adds them to Collection. Used for mailbox booster rewards.
## Falls back to a balanced 1-of-each draw if pack_name is unknown.
func draw_pack_free(pack_name: String) -> Array:
	var pack := get_pack_by_name(pack_name)
	if pack.is_empty():
		pack = {
			"name": pack_name if not pack_name.is_empty() else "Gift Pack",
			"slots": [
				{"type": "character", "count": 1},
				{"type": "trap",      "count": 1},
				{"type": "tech",      "count": 1},
			],
		}
	var cards := _draw_cards(pack)
	for card: Dictionary in cards:
		Collection.add_card(card["name"], card["type"], card["from_pack"])
	return cards

# ─────────────────────────────────────────────────────────────
# Internal drawing
# ─────────────────────────────────────────────────────────────
func _draw_cards(pack: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var all_chars: Array = CardDatabase.get_all_character_names()
	var all_traps: Array = CardDatabase.get_all_trap_names()
	var all_techs: Array = CardDatabase.get_all_tech_names()

	var result: Array = []
	for slot: Dictionary in pack.get("slots", []):
		var pool: Array = []
		match slot["type"]:
			"character": pool = all_chars
			"trap":      pool = all_traps
			"tech":      pool = all_techs

		if pool.is_empty():
			continue

		for _i in range(slot.get("count", 1)):
			var idx: int = rng.randi() % pool.size()
			result.append({
				"name":      pool[idx],
				"type":      slot["type"],
				"from_pack": pack.get("name", "Unknown Pack"),
			})

	return result
