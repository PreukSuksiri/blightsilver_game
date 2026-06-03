extends Node
## UnionDatabase — autoload that holds all Union card definitions
## and provides zone-match validation.
##
## Zone shapes are defined as arrays of Vector2i (row_offset, col_offset)
## from the top-left anchor of the zone's bounding box.
##
## Admin / debug tip:
##   To test a zone, call:
##     UnionDatabase.debug_print_zone("Gryphon Rider")
##   To force-show all unions for a position (ignoring material checks):
##     UnionDatabase.find_available_unions(player, row, col, true)

# ─────────────────────────────────────────────────────────────
# Registry
# ─────────────────────────────────────────────────────────────
var _unions: Dictionary = {}  # card_name → UnionData

func _ready() -> void:
	_load_unions()
	_init_display_names()
	_apply_demo_flags()
	CardDatabase.apply_union_editor_overrides()

func _init_display_names() -> void:
	for u: UnionData in _unions.values():
		if u.display_name.is_empty():
			u.display_name = u.card_name

func _apply_demo_flags() -> void:
	var path := "res://data/demo_flags.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	for card_name: String in parsed:
		var u: UnionData = get_union(card_name)
		if u != null:
			u.include_in_demo = bool(parsed[card_name])

func get_union(name: String) -> UnionData:
	var u: Variant = _unions.get(name, null)
	return u as UnionData

func get_all_unions() -> Array:
	return _unions.values()

## When demo mode is on, only unions flagged include_in_demo are playable.
func is_playable_in_demo(u: UnionData) -> bool:
	if u == null:
		return false
	return not SaveManager.demo_mode or u.include_in_demo

# ─────────────────────────────────────────────────────────────
# Zone shape library
# (row_offset, col_offset) from top-left anchor of bounding box
# ─────────────────────────────────────────────────────────────
#
#  ── 2-cell ───────────────────────────────────────────────────
# Z_H2   = [X][X]       Z_V2 = [X]     Z_D2  = [X][ ]
#                                [X]           [ ][X]
#
# Z_D2L  = [ ][X]       Z_SH2 = [X][ ][X]    Z_SV2 = [X]
#           [X][ ]                                    [ ]
#                                                     [X]
#
# Z_FAR_D = [X][ ][ ]   Z_FAR_DL = [ ][ ][X]
#            [ ][ ][ ]              [ ][ ][ ]
#            [ ][ ][X]              [X][ ][ ]
#
#  ── 3-cell ───────────────────────────────────────────────────
# Z_V3 = [X]      Z_H3 = [X][X][X]    Z_L3 = [X][ ]
#         [X]                                  [X][X]
#         [X]
#
# Z_J3 = [ ][X]   Z_T3 = [X][X]       Z_TRI = [X][X]
#         [X][X]          [ ][X]               [X][ ]
#
# Z_DIAG3 = [X][ ][ ]
#            [ ][X][ ]
#            [ ][ ][X]
#
#  ── 4-cell ───────────────────────────────────────────────────
# Z_SQ = [X][X]   Z_T4 = [X][X][X]   Z_L4 = [X]
#         [X][X]          [ ][X][ ]           [X]
#                                             [X][X]
#
#  ── 5-cell ───────────────────────────────────────────────────
# Z_PLUS = [ ][X][ ]   Z_X = [X][ ][X]   Z_V5 = [X]
#           [X][X][X]        [ ][X][ ]           [X]
#           [ ][X][ ]        [X][ ][X]           [X]
#                                                [X]
#                                                [X]

func _z(pairs: Array) -> Array:
	var result: Array = []
	for p: Array in pairs:
		result.append(Vector2i(p[0], p[1]))
	return result

# ─────────────────────────────────────────────────────────────
# Data loading
# ─────────────────────────────────────────────────────────────
func _load_unions() -> void:
	var A := CharacterData.Affinity
	var R := CharacterData.Rarity
	var AB := CharacterData.AbilityType

	# ─────────────────────────────────────────────────────────
	# Union definitions — sourced from card_data.xlsx Union tab
	# _add(name, affinity, atk, def, summon_cost, rarity,
	#      ability_type, ability_params,
	#      full_description, partial_description, formula,
	#      zone_shape, material_conditions)
	#
	# Zone shapes are Vector2i (row,col) offsets from top-left anchor.
	# material_conditions: one dict per zone cell (unordered matching).
	#   {} = any character card.
	# ─────────────────────────────────────────────────────────

	# ── Divine ────────────────────────────────────────────────

	_add("Gryphon Rider", A.DIVINE, 125, 90, 1000, R.RARE,
		AB.NONE, {}, "None", "None",
		"Gryphon + 1 Divine + 1000 cost",
		"1 ??? + 1 ??? + 1000 cost",
		_z([[0,0], [1,1], [2,2], [3,3], [4,4]]),
		_conds([{"name_contains": "gryphon"}, {"affinity": A.DIVINE}], 5))

	_add("Seraphim Fistmaster", A.DIVINE, 120, 120, 1500, R.LEGENDARY,
		AB.DOUBLE_STATS_VS_AFFINITY, {"affinity": A.CHAOS}, "Double ATK&DEF against Chaos",
		"Double ATK&DEF against ??? Affinity",
		"1 ‘Seraph’ unit + 1 Divine (≥ 800 cost) + 1500 cost",
		"1 ??? + 1 ??? + 1500 cost",
		_z([[0,0], [0,1], [0,3], [0,4], [1,0], [1,4], [3,0], [3,4], [4,0], [4,1], [4,3], [4,4]]),
		_conds([{"name_contains": "seraph"}, {"affinity": A.DIVINE, "min_cost": 800}], 12))

	_add("One Winged Angel", A.DIVINE, 120, 120, 1500, R.LEGENDARY,
		AB.PERM_BOOST_END_OF_TURN, {"atk": 30, "def": 0},
		"Once, +30 ATK permanently at the end of your turn",
		"+??? ATK permanently at ???",
		"1 Cleaver Saint + 1 Divine card + 1500 cost",
		"1 ??? + 1 ??? + 1500 cost",
		_z([[0,3], [0,4], [1,3], [1,4], [2,3], [2,4], [3,3], [3,4], [4,3], [4,4]]),
		_conds([{"card_name": "Cleaver Saint"}, {"affinity": A.DIVINE}], 10))

	_add("Pixie Queen", A.DIVINE, 30, 30, 300, R.UNCOMMON,
		AB.BOOST_PER_TYPED_CARD_ON_FIELD, {"atk_bonus": 5, "def_bonus": 0, "affinity": A.DIVINE},
		"+5 ATK for each Divine cards on their own field",
		"+5 ATK for each ????",
		"1 Tiny Pixie + 1 Divine+ 300 cost",
		"1 ??? + 1 ??? + 300 cost",
		_z([[0,2], [1,2], [2,0], [2,4], [3,0], [3,2], [3,4], [4,1], [4,3]]),
		_conds([{"card_name": "Tiny Pixie"}, {"affinity": A.DIVINE}], 9))

	_add("Diamond Unicorn", A.DIVINE, 30, 35, 500, R.UNCOMMON,
		AB.ONE_USE_ATK_BOOST, {"bonus": 15},
		"+15 ATK until the end of this turn, once.",
		"+15 ATK until ????",
		"1 Ponycorn + 1 Divine card + 500 cost",
		"1 ??? + 1 ??? + 500 cost",
		_z([[0,2], [1,1], [1,3], [2,0], [2,4], [3,1], [3,3], [4,2]]),
		_conds([{"name_contains": "ponycorn"}, {"affinity": A.DIVINE}], 8))

	_add("Choir Lead Amber", A.DIVINE, 35, 35, 500, R.RARE,
		AB.FIELD_ATK_BOOST_OWN_AFFINITY, {"affinity": A.DIVINE, "atk": 20}, "+20 ATK to all Divine units on their own field",
		"+20 ATK to all ?????",
		"3 Choir Lady cards + 500 cost",
		"3 ??? + 500 cost",
		_z([[0,1], [0,2], [1,1], [1,3], [1,4], [2,1], [2,4], [3,0], [3,1], [4,0], [4,1]]),
		_conds([{"name_contains": "choir lady"}, {"name_contains": "choir lady"}, {"name_contains": "choir lady"}], 11))

	_add("Genesis Mech", A.DIVINE, 60, 40, 1000, R.RARE,
		AB.ONE_USE_DESTROY_BY_AFFINITY, {"aff1": A.DIVINE, "aff2": A.ANIMA}, "Once, destroy Divine or Anima card",
		"Once, destroy ???or ??? card",
		"1 Cruel Angel + 1 Anima Card + 1000 cost",
		"1 ??? + 1 ??? + 1000 cost",
		_z([[0,0], [0,1], [0,2], [0,3], [0,4], [1,0], [1,1], [1,2], [1,3], [1,4]]),
		_conds([{"card_name": "Cruel Angel"}, {"affinity": A.ANIMA}], 10))

	_add("Keeper of the Afterlife", A.DIVINE, 40, 65, 1000, R.UNCOMMON,
		AB.COIN_FLIP_NULLIFY_ON_DEFEND, {}, "At battle calculation, flip a coin. If head, the attack does nothing",
		"At battle calculation, flip a coin. If head, ????",
		"1 Sphinx unit + 1 Divine card + 1000 cost",
		"1 ??? + 1 ???+ 1000 cost",
		_z([[2,2], [3,1], [3,2], [3,3], [4,0], [4,1], [4,2], [4,3], [4,4]]),
		_conds([{"name_contains": "sphinx"}, {"affinity": A.DIVINE}], 9))

	_add("Keeper of the Sun", A.DIVINE, 70, 35, 1000, R.UNCOMMON,
		AB.CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD, {"allowed": [CharacterData.Affinity.DIVINE, CharacterData.Affinity.ANIMA]}, "This card cannot attack if there is card with affinity other than Divine or Anima on their own field",
		"This card cannot attack if there is card with affinity other than ??? Or ???",
		"1 Sphinx unit + 1 Anima + 1000 cost",
		"1 ???+ ??? + 1000 cost",
		_z([[0,0], [0,1], [0,2], [0,3], [0,4], [1,1], [1,2], [1,3], [2,2]]),
		_conds([{"name_contains": "sphinx"}, {"affinity": A.ANIMA}], 9))

	_add("Keeper of Righteous", A.DIVINE, 90, 80, 1000, R.RARE,
		AB.ATK_BONUS_VS_TWO_AFFINITIES, {"aff1": A.CHAOS, "aff2": A.ARCANE, "bonus": 20},
		"+20 ATK vs Chaos and Arcane",
		"+??? ATK vs ?? and ??",
		"2 Sphinx units + 1000 cost",
		"2 ???+ 1000 cost",
		_z([[0,0], [0,4], [1,1], [1,3], [2,2], [3,1], [3,3], [4,0], [4,4]]),
		_conds([{"name_contains": "sphinx"}, {"name_contains": "sphinx"}], 9))

	_add("Lucky Wanderer", A.DIVINE, 70, 50, 1000, R.UNCOMMON,
		AB.END_OF_TURN_COIN_FLIP_STAT_BOOST, {"atk": 10, "def": 10}, "During the end of that turn, flip a coin. If head, +10 ATK. If tail, +10 DEF",
		"During the end of that turn, flip a coin. If head, +??? ATK. If tail, +?? DEF",
		"1 Lucky Statue + 1 Divine card + 1000 cost",
		"1 ??? + 1 ??? + 1000 cost",
		_z([[0,2], [1,2], [2,2], [3,2], [4,2]]),
		_conds([{"card_name": "Lucky Statue"}, {"affinity": A.DIVINE}], 5))

	_add("Raijin and Fujin", A.DIVINE, 80, 80, 800, R.RARE,
		AB.NONE, {}, "None", "None",
		"Raijin + Fujin + 800 cost",
		"1 ??? + 1 ??? + 800 cost",
		_z([[0,0], [0,4], [1,0], [1,4], [2,0], [2,4], [3,0], [3,4], [4,0], [4,4]]),
		_conds([{"name_contains": "raijin"}, {"name_contains": "fujin"}], 10))

	_add("Joyce the Rafflesia", A.DIVINE, 45, 45, 1000, R.UNCOMMON,
		AB.PERM_BOOST_END_OF_TURN, {"atk": 5, "def": 5},
		"At the end of this turn, +5 ATK and DEF permanently.",
		"At the end of this turn, +??? ATK and DEF ????",
		"Bloom Fairy + 1 Nature card + 1000 cost",
		"1 ??? + 1 ??? + 1000 cost",
		_z([[0,0], [0,1], [0,2], [0,3], [0,4], [1,0], [1,1], [1,3], [1,4], [2,2], [3,2], [4,2]]),
		_conds([{"card_name": "Bloom Fairy"}, {"affinity": A.NATURE}], 12))

	_add("Sky Protector", A.DIVINE, 0, 0, 400, R.RARE,
		AB.STANCE_FIXED_STATS, {"atk_atk": 50, "atk_def": 0, "def_atk": 0, "def_def": 50}, "If this card defends, DEF becomes 50, ATK becomes 0. If this card performs attack, ATK becomes 50, DEF becomes 0.",
		"If this card defends, DEF becomes ???, ATK becomes ???. If this card performs attack, ATK becomes ???, DEF becomes ???.",
		"Sunrise Lady + Moonrise Gentleman + 400 cost",
		"1 ??? + 1 ??? + 400 cost",
		_z([[0,0], [0,1], [0,2], [0,3], [0,4]]),
		_conds([{"card_name": "Sunrise Lady"}, {"card_name": "Moonrise Gentleman"}], 5))

	_add("Twin Axe Saintess", A.DIVINE, 40, 30, 600, R.RARE,
		AB.MULTI_ATTACK_ANY, {"max_attacks": 2}, "This card can attack twice per turn",
		"This card can ??? per turn",
		"Lady of the Sacred Pond + 1 Anima + 600 cost",
		"1??? + 1 ??? + 1000 cost",
		_z([[0,0], [0,1], [0,3], [0,4], [1,1], [1,3], [2,1], [2,3], [3,1], [3,3]]),
		_conds([{"card_name": "Lady of the Sacred Pond"}, {"affinity": A.ANIMA}], 10))

	_add("Blast Beam Seraph", A.DIVINE, 100, 50, 1000, R.LEGENDARY,
		AB.NONE, {}, "None", "None",
		"Gerald of the Heavenly Light + 1 Divine + 1000 cost",
		"1 ??? + 1 ??? + 1000 cost",
		_z([[0,0], [0,1], [0,2], [0,3], [0,4], [1,2], [2,0], [2,1], [2,2], [2,3], [2,4], [3,2]]),
		_conds([{"card_name": "Gerald of the Heavenly Light"}, {"affinity": A.DIVINE}], 12))

	_add("Balthier the Supreme Holiness", A.DIVINE, 100, 100, 1500, R.LEGENDARY,
		AB.BOOST_PER_ANIMA_ON_FIELD, {"atk_bonus": 50, "def_bonus": 50},
		"+50 ATK and DEF for each Divine cards on the field. This bonus does not exceed maximum of 100",
		"+??? ATK and DEF for each ???cards on the field. This bonus does not exceed maximum of 1???",
		"2 Divine (≥800 cost) + 1500 cost",
		"2 ??? + 1500 cost",
		_z([[0,2], [1,0], [1,1], [1,2], [1,3], [1,4], [2,2], [3,2], [4,2]]),
		_conds([{"affinity": A.DIVINE, "min_cost": 800}, {"affinity": A.DIVINE, "min_cost": 800}], 9))

	_add("False Prophet", A.DIVINE, 20, 40, 300, R.RARE,
		AB.TURN_START_REVEAL_OPPONENT_CELL, {"gain": 200}, "Start of your turn: Reveal 1 foe’s cell. If it was a Dead End, destroy this card. Otherwise, gain 200 crystals.",
		"Start of your turn: Reveal ???. If it was a Dead End, destroy this card. Otherwise, gain ???",
		"2 Divine cards + 300 cost",
		"2 ??? + 300 cost",
		_z([[0,2], [1,1], [1,3], [2,2]]),
		_conds([{"affinity": A.DIVINE}, {"affinity": A.DIVINE}], 4))

	# ── Nature ────────────────────────────────────────────────

	_add("Gaia Turtle", A.NATURE, 0, 205, 2000, R.LEGENDARY,
		AB.NONE, {}, "None", "None",
		"2 any units (≥90 DEF) + 2000 cost",
		"2 ??? + 2000 cost",
		_z([[2,1], [2,2], [2,3], [3,1], [3,2], [3,3]]),
		_conds([{"min_def": 90}, {"min_def": 90}], 6))

	_add("Barros the Colossal", A.NATURE, 150, 130, 1500, R.RARE,
		AB.NONE, {}, "None", "None",
		"2 Nature (≥ 800 cost) + 1500 cost",
		"2 ???+ 1500 cost",
		_z([[1,1], [1,3], [2,2], [3,1], [3,3]]),
		_conds([{"affinity": A.NATURE, "min_cost": 800}, {"affinity": A.NATURE, "min_cost": 800}], 5))

	_add("Armored Dino", A.NATURE, 95, 60, 800, R.UNCOMMON,
		AB.OPTIONAL_CRYSTAL_PAY_DEF_BOOST, {"cost": 1000, "def": 60}, "In Reckoning, pay 1000 crystal cost to +60 DEF",
		"In Reckoning, pay ??? crystal cost to +??DEF",
		"1 Armored Nature card + 1 Nature (≥ 800 cost) + 800 cost",
		"1 ??? + 1 ??? + 800 cost",
		_z([[1,1], [1,2], [1,3], [2,0], [2,1], [2,2], [2,3], [2,4]]),
		_conds([{"affinity": A.NATURE, "name_contains": "armored"}, {"affinity": A.NATURE, "min_cost": 800}], 8))

	_add("Ancient Lizard", A.NATURE, 75, 75, 800, R.UNCOMMON,
		AB.NONE, {}, "None", "None",
		"1 Flame Lizard + 1 Nature + 800 cost",
		"1 ??? + 1 ???+ 800 cost",
		_z([[1,2], [2,1], [2,2], [2,3], [3,2]]),
		_conds([{"card_name": "Flame Lizard"}, {"affinity": A.NATURE}], 5))

	_add("Berserk Hyena", A.NATURE, 40, 0, 500, R.UNCOMMON,
		AB.NONE, {}, "None", "None",
		"2 Nature + 500 cost",
		"2 ???+ 500 cost",
		_z([[1,0], [1,1], [1,2], [1,3], [1,4], [2,0], [2,2], [2,4], [3,0], [3,2], [3,4]]),
		_conds([{"affinity": A.NATURE}, {"affinity": A.NATURE}], 11))

	_add("Rocket Peacock", A.NATURE, 150, 100, 1500, R.LEGENDARY,
		AB.POST_BATTLE_COIN_FLIP_DESTROY, {}, "After this card battles, select 1 foe’s card, flip a coin. Head : destroy that card",
		"After this card battles, select 1 foe’s card, flip a coin. Head : ???",
		"Ostrich Cannon + 1 Nature + 1500 cost",
		"1 ??? + 1 ??? + 1500 cost",
		_z([[0,0], [0,4], [1,0], [1,4], [2,0], [2,4], [4,2]]),
		_conds([{"card_name": "Ostrich Cannon"}, {"affinity": A.NATURE}], 7))

	_add("Scarlet Shroom", A.NATURE, 0, 80, 500, R.RARE,
		AB.UNION_SUMMON_VENOM_ALL_FOE, {}, "Once Union, put venom flag on all foe’s face-up card",
		"If ???, put venom flag on all ???.",
		"2 Nature cards + 500 cost",
		"2 ??? + 500 cost",
		_z([[0,0], [0,1], [0,2], [0,3], [0,4], [1,2], [2,2], [3,2]]),
		_conds([{"affinity": A.NATURE}, {"affinity": A.NATURE}], 8))

	# ── Arcane ────────────────────────────────────────────────

	_add("Burning Phoenix", A.ARCANE, 125, 50, 800, R.LEGENDARY,
		AB.IMMUNE_DESTROY_BY_NON_UNION, {}, "Cannot be destroyed by non-union cards. If targeted by tech, destroy this card.",
		"Cannot be destroyed by ???. If targeted by tech, ???",
		"1 Arcane (≥ 500 cost) + 1 Nature (≥ 500 cost) + 1 Divine (≥ 500 cost) + 800 cost",
		"1 ??? + 1 ??? + 1 ??? + 800 cost",
		_z([[0,2], [1,1], [1,2], [1,3], [2,0], [2,2], [2,4]]),
		_conds([{"affinity": A.ARCANE, "min_cost": 500}, {"affinity": A.NATURE, "min_cost": 500}, {"affinity": A.DIVINE, "min_cost": 500}], 7))

	_add("Colorful Mage", A.ARCANE, 40, 40, 500, R.RARE,
		AB.PERM_STAT_PENALTY_VS_NON_AFFINITY, {"affinity": A.ARCANE, "atk": 10, "def": 10}, "Foe’s non-Arcane get -10 ATK&DEF permanently in Reckoning with this card",
		"Foe’s non-Arcane get ??? in Reckoning with this card",
		"Red Mage + Green Mage + Blue Mage + 500 cost",
		"??? + ???+ ??? + 500 cost",
		_z([[0,4], [1,3], [2,1], [2,2], [3,1], [3,2], [4,0]]),
		_conds([{"card_name": "Red Mage"}, {"card_name": "Green Mage"}, {"card_name": "Blue Mage"}], 7))

	# ── Bio ───────────────────────────────────────────────────

	_add("Tendrill Tyrant", A.BIO, 90, 110, 1500, R.LEGENDARY,
		AB.MULTI_ATTACK_ANY, {"max_attacks": 3}, "Can attack 3 times per turn",
		"Can attack ? times per turn",
		"1 Bio with mutagen flag + 2 Bio (≥ 800 cost) + 1500 cost",
		"1 ??? + 2 ??? + 1500 cost",
		_z([[0,2], [1,2], [2,0], [2,1], [2,2], [2,3], [2,4], [3,2], [4,2]]),
		_conds([{"affinity": A.BIO, "has_flag": "mutagen"}, {"affinity": A.BIO, "min_cost": 800}, {"affinity": A.BIO, "min_cost": 800}], 9))

	_add("Bioterrorist", A.BIO, 150, 0, 1000, R.RARE,
		AB.DESTROY_SELF_AFTER_BATTLE, {}, "Destroy this card after battle calculation",
		"Destroy this card after ???",
		"2 Bio cards (≥ 800 cost) + 1000 cost",
		"2 ??? + 1000 cost",
		_z([[0,0], [0,4], [1,1], [1,3], [3,1], [3,3], [4,0], [4,4]]),
		_conds([{"affinity": A.BIO, "min_cost": 800}, {"affinity": A.BIO, "min_cost": 800}], 8))

	_add("Rocket Marauder", A.BIO, 125, 105, 1000, R.RARE,
		AB.NONE, {}, "None", "None",
		"1 Bio (≥ 800 cost) + 1 Anima (≥ 800 cost) + 1000 cost",
		"1 ??? + 1 ??? + 1000 cost",
		_z([[3,1], [3,3], [4,0], [4,2], [4,4]]),
		_conds([{"affinity": A.BIO, "min_cost": 800}, {"affinity": A.ANIMA, "min_cost": 800}], 5))

	_add("Gamma Mermaid", A.BIO, 30, 20, 500, R.UNCOMMON,
		AB.DEF_PENALTY_VS_NON_AFFINITY, {"affinity": A.BIO, "def": 20}, "Non-Bio defender get -20 DEF. With Mutagen Flag: +20 ATK&DEF to all your Bio units",
		"Non-Bio defender get ???. With Mutagen Flag: +20 ???",
		"1 Gamma cards + 1 Bio card + 500 cost",
		"??? + ??? + 1000 cost",
		_z([[1,1], [1,2], [1,3], [2,1], [2,3], [3,1], [3,2], [3,3]]),
		_conds([{"name_contains": "gamma"}, {"affinity": A.BIO}], 8))

	_add("Volatile Slasher", A.BIO, 50, 45, 1000, R.RARE,
		AB.PERM_ATK_BOOST_ONCE_PER_AFFINITY, {"affinity": A.BIO, "atk": 50}, "Once, after Reckoning with non-Bio, it gain +50 ATK permanently.",
		"Once, after Reckoning with non-Bio, it gain ???.",
		"1 Bladeshifter + 1 Bio card + 1000 cost",
		"1 ??? + 1 ??? + 1000 cost",
		_z([[0,0], [1,1], [1,2], [2,1], [2,2], [3,1], [3,2], [4,0]]),
		_conds([{"name_contains": "bladeshifter"}, {"affinity": A.BIO}], 8))

	# ── Cosmic ────────────────────────────────────────────────

	_add("Helios the Prideful Fortress", A.COSMIC, 145, 100, 1500, R.LEGENDARY,
		AB.IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP, {"affinity": A.COSMIC}, "With another face-up Cosmic: this card cannot be destroyed",
		"As long as there is face-up ???, this card cannot be ???",
		"2 Cosmic (≥ 800 cost) + 1500 cost",
		"2 ??? + 1500 cost",
		_z([[0,2], [1,1], [1,3], [2,0], [2,4], [3,1], [3,3], [4,2]]),
		_conds([{"affinity": A.COSMIC, "min_cost": 800}, {"affinity": A.COSMIC, "min_cost": 800}], 8))

	_add("Slim Gray Plasma Bomber", A.COSMIC, 80, 60, 1000, R.RARE,
		AB.ATK_DEF_BONUS_IF_OWN_REVEALED_GTE, {"min_revealed": 15, "atk": 100, "def": 100}, "+100 ATK and DEF if 15 or more of your cells is revealed",
		"+?? ATK and DEF if ?? or more of your cells is revealed",
		"1 Slim Gray + 1 Cosmic (≥ 800 cost) + 1000 cost",
		"1 ??? + 1 ??? + 1000 cost",
		_z([[0,2], [1,1], [1,2], [1,3], [2,1], [2,3], [3,1], [3,2], [3,3]]),
		_conds([{"card_name": "Slim Gray"}, {"affinity": A.COSMIC, "min_cost": 800}], 9))

	_add("Interplanetary Assassin", A.COSMIC, 50, 70, 1500, R.RARE,
		AB.ATK_BONUS_VS_AFFINITY, {"affinity": A.COSMIC, "bonus": 100},
		"+100 ATK vs Cosmic",
		"+?? ATK vs Cosmic",
		"1 Cosmic (≥ 500 cost) + 1 Cosmic + 1500 cost",
		"1 ??? + 1 ??? + 1500 cost",
		_z([[0,2], [1,0], [1,1], [1,2], [1,3], [1,4], [3,0], [3,1], [3,2], [3,3], [3,4], [4,2]]),
		_conds([{"affinity": A.COSMIC, "min_cost": 500}, {"affinity": A.COSMIC}], 12))

	_add("Giant Mining Pod", A.COSMIC, 20, 80, 500, R.UNCOMMON,
		AB.CRYSTAL_GAIN_ON_DEAD_END_ATTACK, {"amount": 200}, "If this card attacks a dead end card, you receive 200 crystals",
		"If this card attacks a dead end card, you receive ???crystals",
		"1 Miner probe + 1 Cosmic + 500 cost",
		"1 ??? + 1 ??? + 500 cost",
		_z([[0,0], [0,1], [0,2], [0,3], [0,4], [1,1], [1,2], [1,3], [2,1], [2,2], [2,3], [3,2]]),
		_conds([{"card_name": "Miner probe"}, {"affinity": A.COSMIC}], 12))

	_add("Blood-hungry Mutant", A.COSMIC, 55, 40, 600, R.RARE,
		AB.CRYSTAL_GAIN_ON_DESTROY, {"amount": 80}, "After destroying foe’s card: +80 crystals",
		"After destroying foe’s card: ???",
		"2 Mutant cards + 600 cost",
		"2 ??? + 600 cost",
		_z([[1,1], [1,3], [2,0], [2,2], [2,4], [3,1], [3,3]]),
		_conds([{"name_contains": "mutant"}, {"name_contains": "mutant"}], 7))

	_add("Giant Meteor Vergaia", A.COSMIC, 60, 0, 1000, R.LEGENDARY,
		AB.DESTROY_END_TURN_BLAST_ADJACENT, {}, "Destroy it at turn's end, then destroy all face-up foe units sharing a border with this card.",
		"Destroy it at turn’s end, then select all face-up ???.",
		"Striker Comet + 2 Cosmic card + 1000 cost",
		"??? + ??? + 1000 cost",
		_z([[0,0], [1,1], [3,2], [3,3], [3,4], [4,2], [4,3], [4,4]]),
		_conds([{"card_name": "Striker Comet"}, {"affinity": A.COSMIC}, {"affinity": A.COSMIC}], 8))

	_add("Imperial Frame", A.COSMIC, 45, 30, 1000, R.UNCOMMON,
		AB.NONE, {}, "None", "None",
		"Laser Walker + 1 Cosmic card + 1000 cost",
		"??? + ??? + 1000 cost",
		_z([[0,2], [0,3], [0,4], [1,4], [2,0], [2,4], [3,0], [4,0], [4,1], [4,2]]),
		_conds([{"card_name": "Laser Walker"}, {"affinity": A.COSMIC}], 10))

	_add("Moon Tribe Shaman", A.COSMIC, 25, 55, 500, R.RARE,
		AB.UNION_SUMMON_REVIVE_MATCH, {"name_contains": "moon", "exclude_union": true}, "Upon union, revive 1 Moon non-Union card. Double its cost.",
		"Upon union, revive 1 ???. Double its cost.",
		"1 Moon card+ 1 Cosmic card + 500 cost",
		"1 ??? + 1 ??? + 500 cost",
		_z([[0,0], [0,4], [1,1], [1,3], [2,2], [3,2], [4,2]]),
		_conds([{"name_contains": "moon"}, {"affinity": A.COSMIC}], 7))

	# ── Anima ─────────────────────────────────────────────────

	_add("X-Death Squad", A.ANIMA, 50, 50, 800, R.LEGENDARY,
		AB.OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT, {"cost": 1000}, "In Reckoning, pay 1000, destroy foe’s unit. They pay no cost.",
		"In Reckoning, pay ???, destroy foe’s unit. They pay ???.",
		"1 Anima (≥ 800 cost) + 2 Anima + 800 cost",
		"1 ??? + 2 ??? + 800 cost",
		_z([[0,0], [0,2], [0,4], [2,0], [2,2], [2,4], [4,0], [4,2], [4,4]]),
		_conds([{"affinity": A.ANIMA, "min_cost": 800}, {"affinity": A.ANIMA}, {"affinity": A.ANIMA}], 9))

	_add("Grand Fort Captain", A.ANIMA, 45, 40, 500, R.UNCOMMON,
		AB.NONE, {}, "None", "None",
		"2 Grand Fort card + 500 cost",
		"2 ??? + 500 cost",
		_z([[1,2], [2,1], [2,2], [2,3], [3,2]]),
		_conds([{"name_contains": "grand fort"}, {"name_contains": "grand fort"}], 5))

	_add("Kiba the Giant Slayer", A.ANIMA, 80, 55, 1000, R.RARE,
		AB.ATK_BONUS_VS_UNION, {"bonus": 30}, "+30 ATK vs Union",
		"+??? vs Union",
		"Kiyoko the Death Whisper + Silver Spearman + 1000 cost",
		"??? + ??? + 1000 cost",
		_z([[0,1], [0,3], [1,1], [1,3], [2,1], [2,3], [3,1], [3,3], [4,1], [4,3]]),
		_conds([{"card_name": "Kiyoko the Death Whisper"}, {"card_name": "Silver Spearman"}], 10))

	_add("Moon Lady Ninja", A.ANIMA, 65, 50, 800, R.RARE,
		AB.ONE_USE_SURVIVE_DESTRUCTION, {}, "Once, this card is not destroyed.",
		"Once, this card is ???.",
		"Kiyoko the Death Whisper + 1 Anima card + 800 cost",
		"??? + ??? + 800 cost",
		_z([[0,2], [1,2], [2,1], [2,2], [2,3], [3,2], [4,2]]),
		_conds([{"card_name": "Kiyoko the Death Whisper"}, {"affinity": A.ANIMA}], 7))

	_add("Rebel King", A.ANIMA, 60, 40, 800, R.RARE,
		AB.OPPONENT_TURN_END_SWAP_ATK_DEF, {}, "At foe’s turn ends: foe select 1 own unit and swap ATK&DEF",
		"At foe’s turn ends: ??? and swap ATK&DEF",
		"Jirayu the Rebellious Prince + 1 Anima card (≥ 500 cost) + 800 cost",
		"??? + ??? + 800 cost",
		_z([[0,2], [2,0], [2,2], [2,4], [3,2], [4,2]]),
		_conds([{"card_name": "Jirayu the Rebellious Prince"}, {"affinity": A.ANIMA, "min_cost": 500}], 6))

	# ── Chaos ─────────────────────────────────────────────────

	_add("Lord of Terror", A.CHAOS, 150, 100, 1500, R.LEGENDARY,
		AB.ATK_PENALTY_VS_DEAD_END, {"penalty": 50}, "-50 ATK if attacks dead end card",
		"-50 ATK if ???",
		"2 Chaos (≥ 800 cost) + 1500 cost",
		"2 ??? + 1500 cost",
		_z([[1,2], [2,2], [3,1], [3,2], [3,3], [4,2]]),
		_conds([{"affinity": A.CHAOS, "min_cost": 800}, {"affinity": A.CHAOS, "min_cost": 800}], 6))

	_add("Greater Succubus", A.CHAOS, 30, 50, 800, R.RARE,
		AB.GAIN_HALF_STATS_ON_SURVIVE, {}, "Once, after Reckoning: +ATK&DEF equal to half of that foe’s card",
		"Once, after Reckoning: +ATK&DEF equal to ???",
		"1 Succubus + 1 Chaos + 800 cost",
		"1 ??? + 1 ??? + 800 cost",
		_z([[0,2], [1,0], [1,1], [1,2], [1,3], [1,4], [2,0], [2,4]]),
		_conds([{"name_contains": "succubus"}, {"affinity": A.CHAOS}], 8))

	_add("Kitsune", A.CHAOS, 35, 35, 300, R.UNCOMMON,
		AB.NONE, {}, "None", "None",
		"Dark Monk + 1 Chaos + 300 cost",
		"1 ??? + 1 ??? + 300 cost",
		_z([[0,1], [0,2], [1,2], [1,3], [2,1], [2,2], [3,2], [3,3], [4,1], [4,2]]),
		_conds([{"card_name": "Dark Monk"}, {"affinity": A.CHAOS}], 10))

	_add("Ten Arms Yaksa", A.CHAOS, 45, 30, 600, R.RARE,
		AB.MULTI_ATTACK_ANY_WITH_ATK_LOSS, {"max_attacks": 3, "atk_loss": 5}, "This card can choose two attack targets. -5 ATK for each successful attack.",
		"This card can choose ?? attack targets. -?? ATK for each successful attack.",
		"Yaksa + 1 Chaos + 600 cost",
		"1 ??? + 1 ??? + 600 cost",
		_z([[0,0], [0,1], [0,3], [0,4], [1,2], [2,2], [3,1], [3,2], [3,3], [4,1], [4,3]]),
		_conds([{"name_contains": "yaksa"}, {"affinity": A.CHAOS}], 11))

	_add("Skeleton Overlord", A.CHAOS, 50, 5, 400, R.RARE,
		AB.NONE, {}, "None", "None",
		"3 Skeleton cards + 400 cost",
		"3 ??? + 400 cost",
		_z([[0,1], [0,2], [0,3], [2,0], [2,1], [2,2], [2,3], [2,4], [4,1], [4,2], [4,3]]),
		_conds([{"name_contains": "skeleton"}, {"name_contains": "skeleton"}, {"name_contains": "skeleton"}], 11))

	_add("Oblivion Dragon", A.CHAOS, 200, 0, 2000, R.LEGENDARY,
		AB.HALVE_ATK_ADD_TO_DEF_ON_DEFEND, {}, "When this card defends, halve its attack and increase DEF by that amount  permanently",
		"When this card defends, halve its ??? an???",
		"4 Chaos card (≥500 cost) + 2000 cost",
		"4 ??? + 2000 cost",
		_z([[0,0], [0,4], [4,0], [4,4]]),
		_conds([{"affinity": A.CHAOS, "min_cost": 500}, {"affinity": A.CHAOS, "min_cost": 500}, {"affinity": A.CHAOS, "min_cost": 500}, {"affinity": A.CHAOS, "min_cost": 500}], 4))

	# ── No affinity ───────────────────────────────────────────

	_add("Katana Shark", A.NATURE, 75, 50, 800, R.UNCOMMON,
		AB.NONE, {}, "None", "None",
		"3 ‘Sharks’ name + 800 cost",
		"3 ??? + 800 cost",
		_z([[0,0], [0,1], [1,2], [2,3], [3,3], [4,4]]),
		_conds([{"name_contains": "shark"}, {"name_contains": "shark"}, {"name_contains": "shark"}], 6))

func _add(
		name: String,
		aff: CharacterData.Affinity,
		atk: int, def_val: int,
		cost: int,
		rarity: CharacterData.Rarity,
		ability: CharacterData.AbilityType,
		params: Dictionary,
		desc: String,
		partial_desc: String,
		formula: String,
		partial_formula: String,
		zone: Array,
		conds: Array
) -> void:
	var d: UnionData
	if _unions.has(name):
		d = _unions[name] as UnionData
	else:
		d = UnionData.new()
		_unions[name] = d
	d.card_name = name
	d.affinity = aff
	d.base_atk = atk
	d.base_def = def_val
	d.summon_cost = cost
	d.rarity = rarity
	d.ability_type = ability
	d.ability_params = params
	d.ability_description = desc
	d.partial_ability_description = partial_desc if partial_desc != "" else desc
	d.formula_description = formula
	d.partial_formula_description = partial_formula if partial_formula != "" else formula
	d.union_zone = zone
	d.material_conditions = conds

## Build the material conditions for a union.
## Only the specific conditions matter — the second parameter (zone size) is ignored.
## The zone shape defines WHERE on the board materials can be, not how many are needed.
func _conds(specific: Array, _zone_size: int) -> Array:
	return specific.duplicate()

# ─────────────────────────────────────────────────────────────
# Validation
# ─────────────────────────────────────────────────────────────

## Find all unions the current player can summon using the card at (tapped_row, tapped_col).
## Returns Array of:
##   { union: UnionData, zone_cells: Array[Vector2i], tapped_pos: Vector2i }
## where zone_cells are the union's fixed absolute grid positions.
## Union zones are STATIC — the zone cells in UnionDatabase are absolute board positions,
## not offsets. A union only appears if the tapped cell is one of its fixed zone cells.
## If ignore_materials = true, skips condition checking (for admin/debug use).
func find_available_unions(
		player: int,
		tapped_row: int,
		tapped_col: int,
		ignore_materials: bool = false
) -> Array:
	var tapped := Vector2i(tapped_row, tapped_col)
	var results: Array = []

	for union: UnionData in _unions.values():
		if not is_playable_in_demo(union):
			continue
		var zone: Array = union.union_zone

		# Zone is static — tapped cell must be one of the fixed zone positions
		var tapped_in_zone: bool = false
		for zc: Variant in zone:
			if (zc as Vector2i) == tapped:
				tapped_in_zone = true
				break
		if not tapped_in_zone:
			continue

		# Sanity check: all zone cells within board bounds
		var fits: bool = true
		for zc: Variant in zone:
			var v: Vector2i = zc as Vector2i
			if v.x < 0 or v.x >= GameState.GRID_SIZE or v.y < 0 or v.y >= GameState.GRID_SIZE:
				fits = false
				break
		if not fits:
			continue

		# Material conditions checked against the fixed zone positions
		if not ignore_materials and not _materials_match(player, zone, union.material_conditions):
			continue

		results.append({
			"union": union,
			"zone_cells": zone,
			"tapped_pos": tapped,
		})

	return results

## Check whether a union's material conditions are met at its static zone positions.
## Used by SetupPhase to determine if a union is achievable given the current board state.
func check_union_materials(player: int, u: UnionData) -> bool:
	return _materials_match(player, u.union_zone, u.material_conditions)

## Check whether zone_cells (Array[Vector2i]) contain cards satisfying all material_conditions.
## Uses greedy matching: most-specific conditions first.
## The zone may have more cells than conditions — only conditions.size() cards need to match.
func _materials_match(player: int, zone_cells: Array, conditions: Array) -> bool:
	if conditions.is_empty():
		return true

	# Sort conditions by specificity descending (more keys = more specific)
	var sorted_conds: Array = conditions.duplicate()
	sorted_conds.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.size() > b.size()
	)

	var used: Array = []
	used.resize(zone_cells.size())
	used.fill(false)

	for cond: Dictionary in sorted_conds:
		var found: bool = false
		for i: int in range(zone_cells.size()):
			if used[i]:
				continue
			var pos: Vector2i = zone_cells[i]
			var card: GameState.CardInstance = GameState.get_card(player, pos.x, pos.y)
			if _card_satisfies(card, cond):
				used[i] = true
				found = true
				break
		if not found:
			return false

	return true

func _card_satisfies(card: GameState.CardInstance, cond: Dictionary) -> bool:
	if card.card_type != "character" or card.is_union:
		return false

	var cn: Variant = cond.get("card_name", "")
	if cn is String and (cn as String) != "" and card.card_name != (cn as String):
		return false

	var nc: Variant = cond.get("name_contains", "")
	if nc is String and (nc as String) != "" and not card.card_name.to_lower().contains((nc as String)):
		return false

	var aff: Variant = cond.get("affinity", -1)
	if aff is int and (aff as int) >= 0 and card.affinity != (aff as int):
		return false

	var mc: Variant = cond.get("min_cost", 0)
	if mc is int and card.crystal_cost < (mc as int):
		return false

	var ma: Variant = cond.get("min_atk", 0)
	if ma is int and card.base_atk < (ma as int):
		return false

	var md: Variant = cond.get("min_def", 0)
	if md is int and card.base_def < (md as int):
		return false

	var hf: Variant = cond.get("has_flag", "")
	if hf is String and (hf as String) != "":
		if (hf as String) == "mutagen":
			if not card.has_mutagen_flag:
				return false
		elif not card.flags.has(hf as String):
			return false

	return true

## Public wrapper — lets GameBoard check individual card/condition pairs.
func card_satisfies_condition(card: GameState.CardInstance, cond: Dictionary) -> bool:
	return _card_satisfies(card, cond)

## Check whether a character (by name) satisfies a single material condition.
## Used for deck-based union feasibility (before cards are placed on the board).
func deck_char_satisfies(card_name: String, cond: Dictionary) -> bool:
	if cond.is_empty():
		return true
	var data: CharacterData = CardDatabase.get_character(card_name)
	if data == null:
		return false
	var cn: Variant = cond.get("card_name", "")
	if cn is String and (cn as String) != "" and data.card_name != (cn as String):
		return false
	var nc: Variant = cond.get("name_contains", "")
	if nc is String and (nc as String) != "" and not data.card_name.to_lower().contains((nc as String).to_lower()):
		return false
	var aff: Variant = cond.get("affinity", -1)
	if aff is int and (aff as int) >= 0 and int(data.affinity) != (aff as int):
		return false
	var mc: Variant = cond.get("min_cost", 0)
	if mc is int and (mc as int) > 0 and data.crystal_cost < (mc as int):
		return false
	var ma: Variant = cond.get("min_atk", 0)
	if ma is int and (ma as int) > 0 and data.base_atk < (ma as int):
		return false
	var md: Variant = cond.get("min_def", 0)
	if md is int and (md as int) > 0 and data.base_def < (md as int):
		return false
	return true

## Check whether char_names (Array of String card names) can satisfy all of u's
## material_conditions. Uses greedy matching with most-specific conditions first.
func deck_can_form_union(char_names: Array, u: UnionData) -> bool:
	if u.material_conditions.is_empty():
		return true
	var sorted_conds: Array = u.material_conditions.duplicate()
	sorted_conds.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.size() > b.size())
	var remaining: Array = char_names.duplicate()
	for cond: Dictionary in sorted_conds:
		var found: int = -1
		for i: int in range(remaining.size()):
			if deck_char_satisfies(str(remaining[i]), cond):
				found = i
				break
		if found < 0:
			return false
		remaining.remove_at(found)
	return true

# ─────────────────────────────────────────────────────────────
# Debug helpers
# ─────────────────────────────────────────────────────────────

## Print the zone shape of a union card to the output log.
func debug_print_zone(union_name: String) -> void:
	var u: UnionData = get_union(union_name)
	if u == null:
		print("UnionDatabase: '%s' not found." % union_name)
		return
	var grid: Array = []
	for _r in range(GameState.GRID_SIZE):
		var row_arr: Array = []
		for _c in range(GameState.GRID_SIZE):
			row_arr.append(".")
		grid.append(row_arr)
	for cell: Vector2i in u.union_zone:
		if cell.x < GameState.GRID_SIZE and cell.y < GameState.GRID_SIZE:
			grid[cell.x][cell.y] = "X"
	print("=== Union zone: %s ===" % union_name)
	for r: int in range(GameState.GRID_SIZE):
		print(" ".join(grid[r]))
