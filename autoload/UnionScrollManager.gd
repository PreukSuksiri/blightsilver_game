extends Node
# Union Scroll — consumable that discovers one random undiscovered Union (demo pool).

const SCROLL_IMAGE: String = "res://assets/textures/inventory/ui_union_scroll.png"
const SCROLL_PRICE: int = 150
const COMPENSATION_CREDITS: int = 150
const PRODUCT_ID: String = "union_scroll"
const SHOP_NAME: String = "Union Scroll"
const SHOP_DESCRIPTION: String = "Discover 1 Union Card's formula"
const SHOP_CONTENTS: String = "Opens 1 undiscovered Union"

func get_shop_product() -> Dictionary:
	return {
		"id": PRODUCT_ID,
		"product_type": "union_scroll",
		"name": SHOP_NAME,
		"price": SCROLL_PRICE,
		"description": SHOP_DESCRIPTION,
		"contents_tag": SHOP_CONTENTS,
		"item_image": SCROLL_IMAGE,
		"unlock_requires_tutorial": true,
		"shop_available": true,
		"accent": [0.92, 0.92, 1.0],
	}

func is_scroll_purchasable() -> bool:
	return ShopManager.is_tutorial_requirement_met()

func get_discoverable_union_names() -> Array[String]:
	var result: Array[String] = []
	for u: Variant in UnionDatabase.get_all_unions():
		if not u is UnionData:
			continue
		var union: UnionData = u as UnionData
		if not u.include_in_demo:
			continue
		if SaveManager.is_union_unlocked(union.card_name):
			continue
		result.append(union.card_name)
	return result

func pick_random_discoverable_union() -> String:
	var pool: Array[String] = get_discoverable_union_names()
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]

func show_empty_pool_dialog(parent: Node) -> void:
	GameDialog.accept_overlay(
		parent,
		"Union Scroll",
		"There are no more Union cards to discover.\n"
		+ "You received %d Credits instead." % COMPENSATION_CREDITS)

func apply_empty_pool_compensation() -> void:
	Collection.add_credits(COMPENSATION_CREDITS)

## consume_inventory — when true, spends one scroll from Collection first.
## Returns {success, error, union_name, compensated}.
func use_scroll(parent: Node, consume_inventory: bool = false) -> Dictionary:
	if consume_inventory and not Collection.spend_union_scroll():
		return {"success": false, "error": "No Union Scroll.", "union_name": "", "compensated": false}

	var union_name: String = pick_random_discoverable_union()
	if union_name.is_empty():
		apply_empty_pool_compensation()
		show_empty_pool_dialog(parent)
		return {"success": true, "error": "", "union_name": "", "compensated": true}

	SaveManager.unlock_union(union_name)
	UnionScrollOpeningOverlay.open(parent, union_name)
	return {"success": true, "error": "", "union_name": union_name, "compensated": false}

func purchase_from_shop(parent: Node) -> Dictionary:
	if not is_scroll_purchasable():
		return {
			"success": false,
			"error": ShopManager.get_tutorial_unlock_hint(),
			"union_name": "",
			"compensated": false,
		}
	if not Collection.spend_credits(SCROLL_PRICE):
		return {"success": false, "error": "Not enough credits.", "union_name": "", "compensated": false}
	return use_scroll(parent, false)

func grant_union_scroll_mail(count: int, subject_override: String = "", sender: String = "System") -> void:
	if count <= 0:
		return
	var subject: String = subject_override if not subject_override.is_empty() \
		else "Union Scroll ×%d" % count
	MailboxManager.send_mail(
		sender,
		subject,
		"You received %d Union Scroll(s). Claim from your Inventory to use them." % count,
		{"type": "union_scroll", "count": count}
	)
