extends SceneTree

func _initialize() -> void:
	var db: Node = load("res://autoload/OmenDatabase.gd").new()
	db._ready()
	assert(db.get_omen("third_eye").get("label") == "Third Eye")
	assert(db.get_all_omens().size() == 200)
	assert(db.get_groups().size() >= 10)
	assert(db.get_effective_weight({"rarity": "common"}) == 40)
	assert(db.is_anoint(db.get_omen("keen_edge")))
	assert(not db.is_anoint(db.get_omen("third_eye")))
	var offer: Array = db.roll_offer("insights", [], 3)
	assert(offer.size() == 3)
	var line: String = db.format_omen_line({"id": "keen_edge", "anointed_card": "Tiny Pixie"})
	assert(line == "Keen Edge — Tiny Pixie")
	var eligible: Array = db.get_eligible_deck_cards(
		db.get_omen("bargain_bin"),
		[
			{"name": "A", "type": "unit", "ability_none": true, "cost": 100, "atk": 10, "def": 10},
			{"name": "B", "type": "unit", "ability_none": false, "cost": 100, "atk": 10, "def": 10},
		],
	)
	assert(eligible.size() == 1)
	print("OmenDatabase smoke test OK")
	quit()
