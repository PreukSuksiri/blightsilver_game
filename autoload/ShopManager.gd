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
const PACKS: Array = []  # Built-in packs removed — define packs via pack_editor admin command
const MUSIC_DISC_PRICE: int = 300
const CUSTOM_PACKS_PATH: String = "res://shop/custom_packs.json"
const MUSIC_DISCS_PATH:  String = "res://shop/music_discs.json"
const GALLERY_DATA_PATH: String = "res://campaign/gallery_data.json"

# ─────────────────────────────────────────────────────────────
# Custom packs (editor-managed, persisted to JSON)
# ─────────────────────────────────────────────────────────────
var _custom_packs: Array = []
var _music_disc_products: Array = []
var _gallery_chapter_labels: Dictionary = {}  # vn_scene path → "Line1 / Line2"

func _ready() -> void:
	_load_gallery_chapter_labels()
	_load_custom_packs()
	_load_music_disc_products()

func _load_custom_packs() -> void:
	if not FileAccess.file_exists(CUSTOM_PACKS_PATH):
		return
	var file := FileAccess.open(CUSTOM_PACKS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		_custom_packs = parsed as Array

func _load_gallery_chapter_labels() -> void:
	_gallery_chapter_labels.clear()
	if not FileAccess.file_exists(GALLERY_DATA_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GALLERY_DATA_PATH))
	if not parsed is Array:
		return
	for entry: Variant in (parsed as Array):
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var vn: String = str(d.get("vn_scene", "")).strip_edges()
		if vn.is_empty():
			continue
		var label: String = "%s / %s" % [str(d.get("line1", "")), str(d.get("line2", ""))]
		_gallery_chapter_labels[vn] = label.strip_edges().trim_suffix(" /").trim_prefix(" /")

func reload_gallery_chapter_labels() -> void:
	_load_gallery_chapter_labels()

## vn_scene path from gallery_data.json → display label for shop hints.
func get_gallery_chapter_label(vn_scene: String) -> String:
	var key: String = vn_scene.strip_edges()
	if key.is_empty():
		return ""
	return str(_gallery_chapter_labels.get(key, key.get_file().trim_suffix(".json")))

## Campaign chapter vn_scene that must be completed before this pack can be purchased.
func get_chapter_unlock_requirement(pack: Dictionary) -> String:
	return str(pack.get("unlock_requires_chapter", "")).strip_edges()


func requires_tutorial_completion(pack: Dictionary) -> bool:
	return bool(pack.get("unlock_requires_tutorial", false))


func is_tutorial_requirement_met() -> bool:
	return SaveManager.is_attack_tutorial_complete()


func get_tutorial_unlock_hint() -> String:
	return "Finish the tutorial to unlock."


func get_pack_unlock_hint(pack: Dictionary) -> String:
	if requires_tutorial_completion(pack) and not is_tutorial_requirement_met():
		return get_tutorial_unlock_hint()
	var req: String = get_chapter_unlock_requirement(pack)
	if not req.is_empty() and not SaveManager.is_gallery_chapter_completed(req):
		return get_chapter_unlock_hint(req)
	return ""


func is_pack_listed_in_shop(pack: Dictionary) -> bool:
	return bool(pack.get("shop_available", true))

## True when the pack may be purchased (listed in shop and unlock requirements met).
func is_pack_purchasable(pack: Dictionary) -> bool:
	if not is_pack_listed_in_shop(pack):
		return false
	if requires_tutorial_completion(pack) and not is_tutorial_requirement_met():
		return false
	var req: String = get_chapter_unlock_requirement(pack)
	if req.is_empty():
		return true
	return SaveManager.is_gallery_chapter_completed(req)

func get_chapter_unlock_hint(vn_scene: String) -> String:
	var req: String = vn_scene.strip_edges()
	if req.is_empty():
		return ""
	var label: String = get_gallery_chapter_label(req)
	if label.is_empty():
		return "Complete the required campaign chapter to unlock."
	return "Complete %s to unlock." % label

## Pack names whose unlock_requires_chapter matches this gallery vn_scene (for gallery editor).
func get_packs_unlocked_by_chapter(vn_scene: String) -> PackedStringArray:
	var key: String = vn_scene.strip_edges()
	var names: PackedStringArray = PackedStringArray()
	if key.is_empty():
		return names
	for p: Dictionary in get_all_packs_unfiltered():
		if get_chapter_unlock_requirement(p) == key:
			names.append(str(p.get("name", p.get("id", "?"))))
	return names

func _load_music_disc_products() -> void:
	if not FileAccess.file_exists(MUSIC_DISCS_PATH):
		return
	var file := FileAccess.open(MUSIC_DISCS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		_music_disc_products = parsed as Array

func save_music_disc_products() -> void:
	DirAccess.make_dir_recursive_absolute("res://shop")
	var file := FileAccess.open(MUSIC_DISCS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ShopManager: cannot write music_discs.json")
		return
	file.store_string(JSON.stringify(_music_disc_products, "\t"))
	file.close()

func get_all_disc_products() -> Array:
	return _music_disc_products.duplicate()

func get_disc_product(disc_id: String) -> Dictionary:
	for p: Dictionary in _music_disc_products:
		if p.get("id", "") == disc_id:
			return p
	return {}

func get_disc_product_by_name(disc_name: String) -> Dictionary:
	for p: Dictionary in _music_disc_products:
		if p.get("name", "") == disc_name:
			return p
	return {}

## Deducts credits and grants 1 copy of the disc. Returns {success, error}.
func purchase_disc(disc_id: String) -> Dictionary:
	var product := get_disc_product(disc_id)
	if product.is_empty():
		return {"success": false, "error": "Unknown disc product."}
	if not Collection.spend_credits(product.get("price", MUSIC_DISC_PRICE)):
		return {"success": false, "error": "Not enough credits."}
	Collection.add_disc(disc_id)
	return {"success": true, "error": ""}

func save_custom_packs() -> bool:
	if not BuildConfig.can_write_shipped_data():
		push_warning("ShopManager: custom packs can only be saved when running from the Godot editor.")
		return false
	DirAccess.make_dir_recursive_absolute("res://shop")
	var file := FileAccess.open(CUSTOM_PACKS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ShopManager: cannot write custom_packs.json")
		return false
	file.store_string(JSON.stringify(_custom_packs, "\t"))
	file.close()
	return true

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
	var result: Array = PACKS.duplicate()
	for p: Dictionary in _custom_packs:
		if is_pack_purchasable(p):
			result.append(p)
	return result

## All shop-listed packs, including chapter-locked ones. Each copy has shop_unlocked: bool.
func get_shop_catalog() -> Array:
	var result: Array = []
	for p: Dictionary in PACKS:
		if not is_pack_listed_in_shop(p):
			continue
		var copy: Dictionary = (p as Dictionary).duplicate(true)
		copy["shop_unlocked"] = is_pack_purchasable(p)
		copy["unlock_requires_chapter"] = get_chapter_unlock_requirement(p)
		copy["unlock_requires_tutorial"] = requires_tutorial_completion(p)
		result.append(copy)
	for p: Dictionary in _custom_packs:
		if not is_pack_listed_in_shop(p):
			continue
		var copy: Dictionary = p.duplicate(true)
		copy["shop_unlocked"] = is_pack_purchasable(p)
		copy["unlock_requires_chapter"] = get_chapter_unlock_requirement(p)
		copy["unlock_requires_tutorial"] = requires_tutorial_completion(p)
		result.append(copy)
	var scroll_copy: Dictionary = UnionScrollManager.get_shop_product().duplicate(true)
	scroll_copy["shop_unlocked"] = UnionScrollManager.is_scroll_purchasable()
	scroll_copy["unlock_requires_tutorial"] = requires_tutorial_completion(scroll_copy)
	result.append(scroll_copy)
	return result

## Purchase a shop catalog entry (booster pack or consumable).
func purchase_shop_item(item_id: String, parent: Node) -> Dictionary:
	if item_id == UnionScrollManager.PRODUCT_ID:
		return UnionScrollManager.purchase_from_shop(parent)
	return purchase_pack(item_id)

## Returns all custom packs regardless of shop_available (for admin/editor use).
func get_all_packs_unfiltered() -> Array:
	var result: Array = PACKS.duplicate()
	result.append_array(_custom_packs)
	return result

func get_pack(pack_id: String) -> Dictionary:
	for p: Dictionary in PACKS:
		if p["id"] == pack_id:
			return p
	for p: Dictionary in _custom_packs:
		if p.get("id", "") == pack_id:
			return p
	return {}

func get_pack_by_name(pack_name: String) -> Dictionary:
	for p: Dictionary in PACKS:
		if p["name"] == pack_name or p.get("id", "") == pack_name:
			return p
	for p: Dictionary in _custom_packs:
		if p.get("name", "") == pack_name or p.get("id", "") == pack_name:
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
	if not is_pack_purchasable(pack):
		var hint: String = get_pack_unlock_hint(pack)
		if hint.is_empty():
			hint = "This pack is not available yet."
		return {"success": false, "cards": [], "error": hint}

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
func draw_pack_free(pack_name: String, exclude_names: Dictionary = {}) -> Array:
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
	var cards := _draw_cards(pack, exclude_names)
	for card: Dictionary in cards:
		Collection.add_card(card["name"], card["type"], card["from_pack"])
	GlobalStatManager.on_pack_opened()
	return cards

# ─────────────────────────────────────────────────────────────
# Internal drawing
# ─────────────────────────────────────────────────────────────
func _draw_cards(pack: Dictionary, extra_exclude: Dictionary = {}) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pack_name: String = pack.get("name", "Unknown Pack")
	var result: Array = []
	var drawn_names: Dictionary = extra_exclude.duplicate()  # card_name → true; no duplicates within one opening

	# Pool-based draw (custom packs with weighted card_pool)
	var card_pool: Variant = pack.get("card_pool", null)
	if card_pool is Array and not (card_pool as Array).is_empty():
		var pool_arr: Array = card_pool as Array
		var count: int = int(pack.get("card_count", 3))
		for _i in range(count):
			var drawn: Dictionary = _draw_from_pool(pool_arr, rng, drawn_names)
			if drawn.is_empty():
				break
			var cname: String = str(drawn.get("name", ""))
			drawn_names[cname] = true
			drawn["from_pack"] = pack_name
			result.append(drawn)
			Collection.reset_card_boost(cname)
		return result

	# Slot-based draw (built-in packs)
	var all_chars: Array = CardDatabase.get_all_character_names()
	var all_traps: Array = CardDatabase.get_all_trap_names()
	var all_techs: Array = CardDatabase.get_all_tech_names()

	for slot: Dictionary in pack.get("slots", []):
		var pool: Array = []
		match slot["type"]:
			"character": pool = all_chars
			"trap":      pool = all_traps
			"tech":      pool = all_techs
		if pool.is_empty():
			continue
		for _i in range(slot.get("count", 1)):
			var picked: String = _pick_random_unique_name(pool, rng, drawn_names)
			if picked.is_empty():
				continue
			drawn_names[picked] = true
			result.append({
				"name":      picked,
				"type":      slot["type"],
				"from_pack": pack_name,
			})

	return result

func _pick_random_unique_name(pool: Array, rng: RandomNumberGenerator, exclude: Dictionary) -> String:
	var available: Array = []
	for name_var: Variant in pool:
		var name: String = str(name_var)
		if name.is_empty() or exclude.has(name):
			continue
		available.append(name)
	if available.is_empty():
		return ""
	return available[rng.randi() % available.size()] as String

func _draw_from_pool(pool: Array, rng: RandomNumberGenerator, exclude: Dictionary = {}) -> Dictionary:
	var total: float = 0.0
	for entry: Dictionary in pool:
		var cname: String = str(entry.get("card_name", ""))
		if cname.is_empty() or exclude.has(cname):
			continue
		var base_w: float = float(entry.get("weight", 1))
		var boost: float = Collection.get_card_boost(cname)
		total += base_w * (1.0 + boost)
	if total <= 0.0:
		return {}
	var roll: float = rng.randf() * total
	var cum: float = 0.0
	for entry: Dictionary in pool:
		var cname: String = str(entry.get("card_name", ""))
		if cname.is_empty() or exclude.has(cname):
			continue
		var base_w: float = float(entry.get("weight", 1))
		var boost: float = Collection.get_card_boost(cname)
		cum += base_w * (1.0 + boost)
		if roll < cum:
			return {
				"name": cname,
				"type": str(entry.get("card_type", "character")),
			}
	for i: int in range(pool.size() - 1, -1, -1):
		var entry: Dictionary = pool[i] as Dictionary
		var cname: String = str(entry.get("card_name", ""))
		if not cname.is_empty() and not exclude.has(cname):
			return {
				"name": cname,
				"type": str(entry.get("card_type", "character")),
			}
	return {}

# ─────────────────────────────────────────────────────────────
# Drop-rate helpers (used by PackContentsOverlay + CardDetailOverlay)
# ─────────────────────────────────────────────────────────────
## Returns sorted list of cards with effective drop chances for a pack.
## Each entry: {card_name, card_type, base_weight, eff_weight, drop_chance, is_boosted}
func get_pack_drop_rates(pack_id: String) -> Array:
	var pack := get_pack(pack_id)
	if pack.is_empty():
		return []
	var card_pool: Variant = pack.get("card_pool", null)
	if not (card_pool is Array) or (card_pool as Array).is_empty():
		return []
	var pool_arr: Array = card_pool as Array
	var total: float = 0.0
	for entry: Dictionary in pool_arr:
		var cname: String = str(entry.get("card_name", ""))
		var base_w: float = float(entry.get("weight", 1))
		var boost: float = Collection.get_card_boost(cname)
		total += base_w * (1.0 + boost)
	if total <= 0.0:
		return []
	var result: Array = []
	for entry: Dictionary in pool_arr:
		var cname: String = str(entry.get("card_name", ""))
		var base_w: float = float(entry.get("weight", 1))
		var boost: float = Collection.get_card_boost(cname)
		var eff_w: float = base_w * (1.0 + boost)
		result.append({
			"card_name":   cname,
			"card_type":   str(entry.get("card_type", "character")),
			"base_weight": base_w,
			"eff_weight":  eff_w,
			"drop_chance": eff_w / total * 100.0,
			"is_boosted":  boost > 0.0,
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["drop_chance"] as float) > (b["drop_chance"] as float))
	return result

## Returns all pack IDs whose card_pool contains the given card.
## Each entry: {pack_id, pack_name, drop_chance}
func get_packs_containing_card(card_name: String) -> Array:
	var result: Array = []
	for pack: Dictionary in get_all_packs():
		var pack_id: String = str(pack.get("id", ""))
		var card_pool: Variant = pack.get("card_pool", null)
		if not (card_pool is Array):
			continue
		for entry: Dictionary in (card_pool as Array):
			if str(entry.get("card_name", "")) == card_name:
				var rates := get_pack_drop_rates(pack_id)
				var drop_chance: float = 0.0
				for r: Dictionary in rates:
					if str(r.get("card_name", "")) == card_name:
						drop_chance = float(r.get("drop_chance", 0.0))
						break
				result.append({
					"pack_id":    pack_id,
					"pack_name":  str(pack.get("name", pack_id)),
					"drop_chance": drop_chance,
				})
				break
	return result
