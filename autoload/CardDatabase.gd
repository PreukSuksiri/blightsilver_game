extends Node

# All card definitions loaded at startup
var characters: Dictionary = {}  # name -> CharacterData
var traps: Dictionary = {}       # name -> TrapData
var tech_cards: Dictionary = {}  # name -> TechCardData


func _ready() -> void:
	_load_characters()
	_load_traps()
	_load_tech_cards()
	_init_display_names()
	_apply_demo_flags()
	_apply_card_editor_overrides()

## Seeds display_name from card_name for any card that doesn't have one set yet.
func _init_display_names() -> void:
	for d: CharacterData in characters.values():
		if d.display_name.is_empty():
			d.display_name = d.card_name
	for d: TrapData in traps.values():
		if d.display_name.is_empty():
			d.display_name = d.card_name
	for d: TechCardData in tech_cards.values():
		if d.display_name.is_empty():
			d.display_name = d.card_name

func _apply_demo_flags() -> void:
	var path := "res://data/demo_flags.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return
	for card_name: String in parsed:
		var flag: bool = bool(parsed[card_name])
		if characters.has(card_name):
			(characters[card_name] as CharacterData).include_in_demo = flag
		elif traps.has(card_name):
			(traps[card_name] as TrapData).include_in_demo = flag
		elif tech_cards.has(card_name):
			(tech_cards[card_name] as TechCardData).include_in_demo = flag
		else:
			var u: UnionData = UnionDatabase.get_union(card_name)
			if u != null:
				u.include_in_demo = flag

# ────────────────────────────────────────────────────────────
# CHARACTER CARDS
# ────────────────────────────────────────────────────────────
func _load_characters() -> void:
	var defs: Array = [
		# Name, Affinity, ATK, DEF, Cost, AbilityType, Params, Description, Rarity
		["Aerial the Battlemage", CharacterData.Affinity.ARCANE, 50, 45, 750,
			CharacterData.AbilityType.ATK_DEF_BONUS_IF_UNION_ON_FIELD,
			{"atk": 20, "def": 20},
			"+20 ATK&DEF if there is Union card on your field",
			CharacterData.Rarity.RARE],

		["Angel Gatekeeper", CharacterData.Affinity.DIVINE, 40, 90, 1000,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS, "bonus": 50},
			"+50 ATK vs Chaos Affinity",
			CharacterData.Rarity.LEGENDARY],

		["Araya the Eerie Dancer", CharacterData.Affinity.CHAOS, 15, 20, 400,
			CharacterData.AbilityType.IMMUNE_TO_TECH_CARDS,
			{},
			"This card is unaffected by Tech cards",
			CharacterData.Rarity.COMMON],

		["Archbishop", CharacterData.Affinity.DIVINE, 70, 90, 1200,
			CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY,
			{"affinity": CharacterData.Affinity.DIVINE},
			"If this card would be destroyed, you can destroy 1 other Divine card on their own field instead",
			CharacterData.Rarity.LEGENDARY],

		["Armored Bee", CharacterData.Affinity.NATURE, 30, 0, 480,
			CharacterData.AbilityType.ONE_USE_DEF_BOOST,
			{"bonus": 60},
			"+60 DEF until the end of that turn once",
			CharacterData.Rarity.UNCOMMON],

		["Armored Monkey", CharacterData.Affinity.NATURE, 10, 20, 170,
			CharacterData.AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD,
			{"affinity": CharacterData.Affinity.NATURE, "bonus": 10},
			"+10 ATK if there is another face-up Nature card",
			CharacterData.Rarity.COMMON,
			true],

		["Armored Rhino", CharacterData.Affinity.NATURE, 60, 85, 720,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.RARE],

		["Asteroid Trooper", CharacterData.Affinity.COSMIC, 30, 10, 250,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Bat Swarm", CharacterData.Affinity.CHAOS, 15, 15, 200,
			CharacterData.AbilityType.INTERCEPT_ALLY_ATTACK,
			{"affinity": CharacterData.Affinity.CHAOS},
			"If a Chaos card is being attacked. You can swap this card’s position with that card",
			CharacterData.Rarity.RARE],

		["Big Thug", CharacterData.Affinity.ANIMA, 40, 35, 400,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON],

		["Bladeshifter", CharacterData.Affinity.BIO, 0, 50, 420,
			CharacterData.AbilityType.ONE_USE_DEFEND_MORPH,
			{"atk": 40, "def": 40},
			"Once, after defended: -40 DEF,+40 ATK permanently.",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Bleacher Squad", CharacterData.Affinity.BIO, 20, 20, 320,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.BIO, "bonus": 20},
			"+20 ATK vs Bio",
			CharacterData.Rarity.COMMON,
			true],

		["Blue Mage", CharacterData.Affinity.ARCANE, 35, 35, 800,
			CharacterData.AbilityType.COIN_FLIP_2_DESTROY_NON_AFFINITY,
			{"affinity": CharacterData.Affinity.ARCANE},
			"If this card battles non-Arcane card, flip two coins. If both are head, destroy it.",
			CharacterData.Rarity.RARE],

		["Bomber Fairy", CharacterData.Affinity.DIVINE, 30, 15, 500,
			CharacterData.AbilityType.ONE_USE_EXTRA_ATTACK_ON_KILL,
			{},
			"Once, if destroyed a card, this card can attack 1 more time",
			CharacterData.Rarity.UNCOMMON],

		["Book with Fangs", CharacterData.Affinity.ARCANE, 45, 55, 800,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.ARCANE, "atk": 30, "def": 30},
			"+30 ATK&DEF vs Arcane",
			CharacterData.Rarity.RARE],

		["Canyon Warg", CharacterData.Affinity.NATURE, 70, 30, 750,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.RARE],

		["Chaotic Wisp", CharacterData.Affinity.CHAOS, 20, 0, 100,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Choir Lady Abigail", CharacterData.Affinity.DIVINE, 25, 15, 250,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Choir Lady Alice", CharacterData.Affinity.DIVINE, 20, 25, 250,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Choir Lady Anna", CharacterData.Affinity.DIVINE, 20, 20, 250,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Church Guard", CharacterData.Affinity.DIVINE, 0, 35, 150,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Claw Mutant", CharacterData.Affinity.BIO, 15, 10, 180,
			CharacterData.AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES,
			{"bonus": 10, "affinities": []},
			"+10 ATK if it has mutagen flag",
			CharacterData.Rarity.COMMON],

		["Cursed Well", CharacterData.Affinity.CHAOS, 0, 25, 300,
			CharacterData.AbilityType.NOT_IMPLEMENTED,
			{"bonus": 15},
			"At the end of the turn that it's been exposed, +15 ATK",
			CharacterData.Rarity.COMMON],

		["Dark Blob", CharacterData.Affinity.CHAOS, 20, 50, 500,
			CharacterData.AbilityType.PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN,
			{"atk": 5},
			"After reckoning: +5 ATK at foe’s turn ends",
			CharacterData.Rarity.UNCOMMON],

		["Dark Monk", CharacterData.Affinity.CHAOS, 15, 25, 300,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON, true],

		["Dark Tengu", CharacterData.Affinity.CHAOS, 25, 25, 250,
			CharacterData.AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND,
			{"atk": 5, "def": 5},
			"-5 ATK once it successfully attacked. -5 DEF once it successfully defended.",
			CharacterData.Rarity.COMMON],

		["Death Cobra", CharacterData.Affinity.NATURE, 85, 50, 900,
			CharacterData.AbilityType.VENOM_FLAG_END_OF_TURN,
			{},
			"At the end of this turn, select 1 face-up foe’s card. Put 1 venom flag on it.",
			CharacterData.Rarity.LEGENDARY],

		["Death Knight", CharacterData.Affinity.CHAOS, 65, 65, 850,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 5, "def_bonus": 0, "affinity": CharacterData.Affinity.CHAOS},
			"+5 ATK per Chaos card on your side of the field",
			CharacterData.Rarity.RARE],

		["Demon Spawn", CharacterData.Affinity.CHAOS, 40, 30, 400,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON],

		["Doom Wisp", CharacterData.Affinity.CHAOS, 15, 15, 100,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Echo Bringer", CharacterData.Affinity.COSMIC, 70, 40, 900,
			CharacterData.AbilityType.EXTRA_ATTACK_VS_REVEALED,
			{},
			"When this card attacks a revealed card, it can attack a second time this turn (once per turn).",
			CharacterData.Rarity.RARE,
			true],

		["Electrogazer", CharacterData.Affinity.COSMIC, 80, 45, 1000,
			CharacterData.AbilityType.NEGATE_ZERO_COST_TRAPS_BOTH,
			{},
			"Negate all zero cost trap on both player’s field",
			CharacterData.Rarity.LEGENDARY,
			true],

		["Feral Vampire", CharacterData.Affinity.CHAOS, 40, 25, 400,
			CharacterData.AbilityType.DESTROY_SELF_VS_DIVINE_BOTH,
			{},
			"In Reckoning with Divine, destroy this card",
			CharacterData.Rarity.UNCOMMON],

		["Flame Lizard", CharacterData.Affinity.NATURE, 25, 40, 400,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.NATURE, "atk": 20, "def": 20},
			"+20 ATK&DEF vs Nature",
			CharacterData.Rarity.UNCOMMON],

		["Flame Seraph", CharacterData.Affinity.DIVINE, 50, 10, 500,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON],

		["Foul Wisp", CharacterData.Affinity.CHAOS, 0, 25, 100,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Fujin", CharacterData.Affinity.DIVINE, 35, 40, 450,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON],

		["Gamma Emitter", CharacterData.Affinity.BIO, 20, 15, 220,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.NATURE, "atk": 10, "def": 10},
			"+10 ATK&DEF vs Nature",
			CharacterData.Rarity.COMMON,
			true],

		["Giant Centipede", CharacterData.Affinity.NATURE, 20, 20, 1500,
			CharacterData.AbilityType.ATK_BONUS_VS_VENOM,
			{"bonus": 100},
			"+100 ATK vs cards with venom flag",
			CharacterData.Rarity.RARE],

		["Goblin Poacher", CharacterData.Affinity.NATURE, 30, 10, 250,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Goddess of Virtue", CharacterData.Affinity.DIVINE, 80, 100, 1400,
			CharacterData.AbilityType.DESTROY_IF_OPPONENT_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS},
			"In Reckoning, destroy Chaos",
			CharacterData.Rarity.EXOTIC],

		["Golden Senju", CharacterData.Affinity.DIVINE, 15, 0, 200,
			CharacterData.AbilityType.MULTI_ATTACK_VS_NON_CHARACTER,
			{"max_attacks": 3, "bonus_attacks": 1},
			"Once per turn, if attacked non-unit card, this card : can attack 1 more times",
			CharacterData.Rarity.UNCOMMON],

		["Grand Fort Archer", CharacterData.Affinity.ANIMA, 20, 20, 280,
			CharacterData.AbilityType.ONE_USE_ATK_BOOST,
			{"bonus": 10},
			"Once, +10 ATK when attack",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Grand Fort Footsoldier", CharacterData.Affinity.ANIMA, 25, 25, 300,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON,
			true],

		["Grand Fort Mauler", CharacterData.Affinity.ANIMA, 40, 10, 350,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Grave Worm", CharacterData.Affinity.CHAOS, 15, 30, 250,
			CharacterData.AbilityType.OPPONENT_EXTRA_CRYSTAL_LOSS,
			{"amount": 20},
			"Each time foe lose crystal: foe lose 20 more crystals",
			CharacterData.Rarity.UNCOMMON],

		["Green Mage", CharacterData.Affinity.ARCANE, 15, 15, 400,
			CharacterData.AbilityType.DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF,
			{"atk": 10, "def": 10},
			"When this card defends, the attacker permanently loses 10 ATK&DEF.",
			CharacterData.Rarity.UNCOMMON],

		["Gryphon", CharacterData.Affinity.NATURE, 100, 85, 1150,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.EXOTIC],

		["Hairpin Assassin", CharacterData.Affinity.ANIMA, 25, 15, 300,
			CharacterData.AbilityType.OPTIONAL_CRYSTAL_PAY_ATK_BOOST,
			{"cost": 100, "atk": 10},
			"In Reckoning, you can pay 100 crystal for +10 ATK bonus",
			CharacterData.Rarity.COMMON,
			true],

		["Hammer Shark", CharacterData.Affinity.NATURE, 20, 20, 250,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 10, "def_bonus": 0, "card_name_contains": "shark"},
			"+10 ATK per shark card on the field",
			CharacterData.Rarity.COMMON],

		["Hands in the Attic", CharacterData.Affinity.CHAOS, 20, 20, 300,
			CharacterData.AbilityType.TEMP_ATK_BOOST_OWN_TURN_START,
			{"atk": 10},
			"+10 ATK until Reckoning ends",
			CharacterData.Rarity.COMMON],

		["Heavy Tome Preacher", CharacterData.Affinity.DIVINE, 25, 20, 300,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Huntress of Green Glade", CharacterData.Affinity.ANIMA, 50, 50, 800,
			CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS,
			{},
			"Immune to 0-cost Traps",
			CharacterData.Rarity.RARE],

		["Ice Mage", CharacterData.Affinity.ARCANE, 50, 0, 400,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON],

		["Immortal Vampire", CharacterData.Affinity.CHAOS, 30, 80, 1200,
			CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE,
			{},
			"+50 ATK for each other face-up Chaos card on their own field. In Reckoning with Divine, destroy this card.",
			CharacterData.Rarity.LEGENDARY],

		["Jacob the Ski Mask", CharacterData.Affinity.CHAOS, 15, 20, 350,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.ANIMA, "bonus": 5},
			"+5 ATK vs Anima",
			CharacterData.Rarity.COMMON],

		["Jirayu the Rebellious Prince", CharacterData.Affinity.ANIMA, 40, 40, 600,
			CharacterData.AbilityType.PERM_DEF_BOOST_ON_DEFEND,
			{"def": 10},
			"If this card successfully defended, +10 DEF permanently",
			CharacterData.Rarity.UNCOMMON],

		["Joan the Faithful Warrior", CharacterData.Affinity.DIVINE, 25, 5, 280,
			CharacterData.AbilityType.DEF_BONUS_IF_AFFINITY_ON_FIELD,
			{"affinity": CharacterData.Affinity.DIVINE, "def": 30},
			"If at least 1 Divine card is on the field, this card gain 30 DEF",
			CharacterData.Rarity.COMMON],

		["Joseph the Battle Priest", CharacterData.Affinity.DIVINE, 60, 25, 600,
			CharacterData.AbilityType.COIN_FLIP_ATK_BOOST,
			{"bonus": 10},
			"In Reckoning, flip a coin. If head, +10 ATK",
			CharacterData.Rarity.RARE],

		["Kiyoko the Death Whisper", CharacterData.Affinity.ANIMA, 40, 35, 800,
			CharacterData.AbilityType.ATK_BONUS_VS_UNION,
			{"bonus": 50},
			"This card gain +50 ATK when attacking Union card",
			CharacterData.Rarity.LEGENDARY],

		["Lab Bloater", CharacterData.Affinity.BIO, 20, 85, 800,
			CharacterData.AbilityType.MUTAGEN_DESTROY_ATTACKER,
			{},
			"With Mutagen Flag: you can destroy both units in Reckoning. No cost is paid.",
			CharacterData.Rarity.LEGENDARY],

		["Lab Crawler", CharacterData.Affinity.BIO, 95, 60, 1200,
			CharacterData.AbilityType.MUTAGEN_IMMEDIATE_ATTACK,
			{},
			"With Mutagen Flag: this card can target 3 cards",
			CharacterData.Rarity.EXOTIC],

		["Lab Zombie", CharacterData.Affinity.BIO, 55, 40, 700,
			CharacterData.AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES,
			{"bonus": 25, "affinities": [CharacterData.Affinity.NATURE, CharacterData.Affinity.ANIMA]},
			"With Mutagen Flag: +25 ATK vs Nature or Anima.",
			CharacterData.Rarity.RARE],

		["Laser Walker", CharacterData.Affinity.COSMIC, 20, 10, 250,
			CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS,
			{},
			"This card is not affected by 0 cost traps",
			CharacterData.Rarity.COMMON,
			true],

		["Laughing Granny", CharacterData.Affinity.CHAOS, 15, 20, 350,
			CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND,
			{"atk": 10, "def": 10},
			"Once when defending, +10 DEF until end of turn. Once when attacking, +10 ATK until end of turn",
			CharacterData.Rarity.UNCOMMON],

		["Lazy Troll", CharacterData.Affinity.NATURE, 120, 60, 1000,
			CharacterData.AbilityType.COIN_FLIP_CANCEL_ATTACK,
			{},
			"If this card performs an attack, flip a coin, if tail, it stops attacking.",
			CharacterData.Rarity.EXOTIC],

		["Leech Man", CharacterData.Affinity.BIO, 60, 40, 880,
			CharacterData.AbilityType.PERM_DEF_BOOST_PER_ATTACK_SURVIVE,
			{"def": 10},
			"+10 DEF permanently after it performed attack on unit. Also +10 ATK with mutagen flag",
			CharacterData.Rarity.LEGENDARY],

		["Leopard Jailer", CharacterData.Affinity.ANIMA, 30, 45, 450,
			CharacterData.AbilityType.LOCK_TARGET_ON_ATTACK,
			{},
			"If this card attacks a unit card, the target is unable to attack until the end of their turn.",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Leorudus the Warlord", CharacterData.Affinity.ANIMA, 80, 80, 1150,
			CharacterData.AbilityType.BOOST_PER_ANIMA_ON_FIELD,
			{"atk_bonus": 20, "def_bonus": 20},
			"+20 ATK&DEF for each other face-up Anima card on their own field",
			CharacterData.Rarity.EXOTIC],

		["Mad Raccoon", CharacterData.Affinity.NATURE, 30, 15, 260,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Mafia Associates", CharacterData.Affinity.ANIMA, 45, 40, 500,
			CharacterData.AbilityType.DEF_ZERO_WHEN_EXPOSED,
			{},
			"At the end of the turn that it's been exposed, its defense becomes 0",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Magenta the Nightbloom", CharacterData.Affinity.CHAOS, 25, 40, 300,
			CharacterData.AbilityType.HALVE_DEF_ON_FIRST_EXPOSE,
			{},
			"Half its DEF permanently at the end of that turn",
			CharacterData.Rarity.COMMON],

		["Magical Butterfly", CharacterData.Affinity.NATURE, 15, 15, 180,
			CharacterData.AbilityType.TEMP_BOOST_ON_OPP_TECH,
			{"atk": 10, "def": 10},
			"Whenever foe’s tech card is activated, +10 ATK&DEF until the start of your next turn",
			CharacterData.Rarity.COMMON],

		["Mars Drill", CharacterData.Affinity.COSMIC, 40, 30, 400,
			CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS,
			{},
			"This card is not affected by 0 cost traps",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Melissa the Healer", CharacterData.Affinity.DIVINE, 0, 25, 700,
			CharacterData.AbilityType.CRYSTAL_RECOVER_ON_BIG_LOSS,
			{"threshold": 500, "amount": 300},
			"If you lose 500 or more crystals, you recover 300 crystals",
			CharacterData.Rarity.COMMON],

		["Mephisto the Fallen", CharacterData.Affinity.DIVINE, 75, 0, 860,
			CharacterData.AbilityType.ATK_ZERO_AFTER_WIN,
			{},
			"After this card attacked unit successfully, its ATK becomes 0 permanently",
			CharacterData.Rarity.RARE],

		["Mind Flayer", CharacterData.Affinity.ARCANE, 100, 70, 1500,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.ANIMA, "atk": 50, "def": 50},
			"+50 ATK&DEF against Anima",
			CharacterData.Rarity.EXOTIC],

		["Mine Guard", CharacterData.Affinity.COSMIC, 20, 15, 300,
			CharacterData.AbilityType.SACRIFICE_FOR_CARD_TYPE,
			{"name_contains": "Miner"},
			"Prevent ‘Miner’ or ‘Mining’ card from being destroyed, but destroy this card instead. Usable face-down",
			CharacterData.Rarity.UNCOMMON],

		["Miner Probe", CharacterData.Affinity.COSMIC, 10, 10, 200,
			CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEAD_END_ATTACK,
			{"amount": 20},
			"Gain 20 crystals upon hitting dead end card",
			CharacterData.Rarity.COMMON],

		["Moon Rover", CharacterData.Affinity.COSMIC, 15, 20, 200,
			CharacterData.AbilityType.REVEAL_ON_DEAD_END_ATTACK,
			{},
			"After hitting a dead end : reveal 1 foe’s cell",
			CharacterData.Rarity.COMMON,
			true],

		["Moon Tribe Marksman", CharacterData.Affinity.COSMIC, 35, 25, 300,
			CharacterData.AbilityType.ATK_PENALTY_IF_NO_NAME_ALLY,
			{"name_contains": "Moon", "penalty": 10},
			"If you do not control another Moon card, -10 ATK",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Moon Tribe Twin Blader", CharacterData.Affinity.COSMIC, 30, 20, 300,
			CharacterData.AbilityType.COIN_FLIP_EXTRA_ATTACK,
			{},
			"If this card attacks, flip a coin. If head, this card can attack twice.",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Moonrise Gentleman", CharacterData.Affinity.DIVINE, 40, 30, 400,
			CharacterData.AbilityType.DEFENSE_STANCE_BOOST,
			{"def": 10},
			"If it defends: +10 DEF,-10 ATK",
			CharacterData.Rarity.UNCOMMON],

		["Mysterious Miner", CharacterData.Affinity.CHAOS, 25, 15, 250,
			CharacterData.AbilityType.REVEAL_ON_WIN,
			{},
			"After attacked: reveal 1 foe’s cell",
			CharacterData.Rarity.UNCOMMON],

		["Needle Porcupine", CharacterData.Affinity.NATURE, 10, 10, 200,
			CharacterData.AbilityType.ONE_USE_PERM_DEBUFF_ATTACKER_ATK,
			{"atk": 5},
			"Once, when this card defends, the attacker permanently loses 5 ATK.",
			CharacterData.Rarity.COMMON],

		["Neptune Diver", CharacterData.Affinity.COSMIC, 20, 10, 200,
			CharacterData.AbilityType.REVEAL_ON_TRAP_ATTACK,
			{},
			"After hitting a trap : reveal 1 foe’s cell",
			CharacterData.Rarity.COMMON,
			true],

		["Night Whisperer", CharacterData.Affinity.CHAOS, 30, 30, 900,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 30, "def_bonus": 30, "card_name_contains": "wisp"},
			"+30 ATK&DEF for each face-up ‘wisp’ card on their own field",
			CharacterData.Rarity.RARE],

		["Nuki the Tanuki", CharacterData.Affinity.NATURE, 10, 10, 100,
			CharacterData.AbilityType.COIN_FLIP_SWAP_POSITION,
			{},
			"Before Reckoning, flip a coin. If head, swap position with any of your card",
			CharacterData.Rarity.COMMON],

		["Ostrich Cannon", CharacterData.Affinity.NATURE, 60, 30, 800,
			CharacterData.AbilityType.LOCK_SELF_AFTER_ATTACK,
			{},
			"After performed an attack, this card cannot attack during your next turn.",
			CharacterData.Rarity.UNCOMMON],

		["Ox Patrol", CharacterData.Affinity.ANIMA, 30, 35, 420,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY,
			{"affinity": CharacterData.Affinity.ANIMA, "atk": 10, "def": 10},
			"+10 ATK&DEF vs Non-Anima",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Parom the Smuggler", CharacterData.Affinity.COSMIC, 30, 20, 300,
			CharacterData.AbilityType.CRYSTAL_GAIN_ON_OPP_REVEAL,
			{"amount": 40},
			"Each time foe’s cell got revealed: gain 40 crystals.",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Pit Lord", CharacterData.Affinity.CHAOS, 120, 100, 1250,
			CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE,
			{},
			"This card is destroyed if battle with Divine Unit. After this card attacked, halve its ATK&DEF permanently",
			CharacterData.Rarity.EXOTIC],

		["Plant-29", CharacterData.Affinity.BIO, 45, 85, 900,
			CharacterData.AbilityType.TURN_START_COIN_FLIP_FLAG,
			{},
			"Start of your turn: select 1 face-up foe’s card, flip a coin. Head: put Venom Flag on it. Tail: put Mutagen Flag on it.",
			CharacterData.Rarity.RARE,
			true],

		["Poltergeist", CharacterData.Affinity.CHAOS, 0, 70, 700,
			CharacterData.AbilityType.SWAP_ATK_DEF_WHEN_ATTACKING,
			{},
			"If this card performs an attack, switch this card’s ATK and DEF",
			CharacterData.Rarity.RARE],

		["Ponycorn", CharacterData.Affinity.DIVINE, 25, 20, 300,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON],

		["Pyromancer", CharacterData.Affinity.ARCANE, 80, 0, 900,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.NATURE, "bonus": 30},
			"+30 ATK vs Nature Affinity",
			CharacterData.Rarity.LEGENDARY],

		["Raijin", CharacterData.Affinity.DIVINE, 60, 0, 550,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.RARE],

		["Red Mage", CharacterData.Affinity.ARCANE, 20, 20, 400,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.NATURE, "bonus": 10},
			"+10 ATK vs Nature",
			CharacterData.Rarity.COMMON],

		["Rotten Shrieker", CharacterData.Affinity.BIO, 50, 30, 450,
			CharacterData.AbilityType.PERM_ATK_LOSS_PER_OWN_TURN,
			{"amount": 10},
			"Without Mutagen Flag : -10 ATK permanently at your turn’s end",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Satellite Cannon", CharacterData.Affinity.COSMIC, 100, 80, 1100,
			CharacterData.AbilityType.ATK_BONUS_VS_CENTER_ZONE,
			{"bonus": 20, "center_bonus": 40},
			"+20 ATK if attacking the 3x3 center zone. +40 more ATK if attacking the very center cell.",
			CharacterData.Rarity.EXOTIC,
			true],

		["Saw Shark", CharacterData.Affinity.NATURE, 25, 10, 280,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 10, "def_bonus": 0, "card_name_contains": "shark"},
			"+10 ATK per shark card on the field",
			CharacterData.Rarity.COMMON],

		["Scarlet Mutant", CharacterData.Affinity.BIO, 35, 30, 350,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Scout Probe", CharacterData.Affinity.COSMIC, 40, 50, 700,
			CharacterData.AbilityType.REVEAL_ADJACENT_AFTER_ATTACK,
			{},
			"Choose and reveal any adjacent square after it attacked.",
			CharacterData.Rarity.RARE],

		["Scythe Shark", CharacterData.Affinity.NATURE, 35, 35, 550,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 10, "def_bonus": 0, "card_name_contains": "shark"},
			"+10 ATK per shark card on the field",
			CharacterData.Rarity.UNCOMMON],

		["Shepherd Detective", CharacterData.Affinity.ANIMA, 40, 25, 400,
			CharacterData.AbilityType.REVEAL_ON_ANY_ATTACK,
			{},
			"After attack: reveal 1 foe’s cell",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Shotgun Shark", CharacterData.Affinity.NATURE, 75, 25, 900,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 10, "def_bonus": 0, "card_name_contains": "shark"},
			"+10 ATK per shark card on the field",
			CharacterData.Rarity.RARE],

		["Shredder Doll", CharacterData.Affinity.CHAOS, 25, 5, 250,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.COMMON],

		["Silver Spearman", CharacterData.Affinity.ANIMA, 25, 20, 250,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS, "bonus": 5},
			"+5 ATK vs Chaos",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Skeleton Archer", CharacterData.Affinity.CHAOS, 35, 5, 300,
			CharacterData.AbilityType.ATK_BONUS_VS_FACEDOWN,
			{"bonus": 5},
			"+5 ATK vs face-down Defender",
			CharacterData.Rarity.UNCOMMON],

		["Skeleton Grappler", CharacterData.Affinity.CHAOS, 20, 5, 150,
			CharacterData.AbilityType.LOCK_ATTACKER_ON_DESTROYED,
			{},
			"After Reckoning: foe card must wait until foe’s turn ends",
			CharacterData.Rarity.COMMON],

		["Skeleton Lancer", CharacterData.Affinity.CHAOS, 45, 5, 300,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON],

		["Skeleton Scout", CharacterData.Affinity.CHAOS, 20, 5, 150,
			CharacterData.AbilityType.ONE_USE_EXTRA_ATTACK_ON_DEAD_END,
			{},
			"Once, if hitting dead end: attack again",
			CharacterData.Rarity.COMMON],

		["Sniping Fairy", CharacterData.Affinity.DIVINE, 40, 20, 350,
			CharacterData.AbilityType.ATK_PENALTY_WHEN_EXPOSED,
			{"penalty": 20},
			"At the end of the turn that it's been exposed, -20 ATK",
			CharacterData.Rarity.UNCOMMON],

		["Sonic Seraph", CharacterData.Affinity.DIVINE, 45, 50, 550,
			CharacterData.AbilityType.EXTRA_ATTACK_ON_DEAD_END,
			{},
			"Once per turn, if it attacked dead end card, it can attack again",
			CharacterData.Rarity.RARE],

		["Space Boy", CharacterData.Affinity.COSMIC, 75, 65, 800,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.RARE],

		["Spear Shark", CharacterData.Affinity.NATURE, 50, 20, 480,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 10, "def_bonus": 0, "card_name_contains": "shark"},
			"+10 ATK per shark card on the field",
			CharacterData.Rarity.UNCOMMON],

		["Staircase Lady", CharacterData.Affinity.CHAOS, 30, 0, 180,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON],

		["Stinky Insect", CharacterData.Affinity.NATURE, 10, 10, 400,
			CharacterData.AbilityType.LOCK_ATTACKER_ON_DEFEND,
			{},
			"If this card defended, the attacker must wait until foe’s turn ends",
			CharacterData.Rarity.COMMON],

		["Street Rogue", CharacterData.Affinity.ANIMA, 25, 20, 350,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.ANIMA, "bonus": 20},
			"+20 ATK against Anima card",
			CharacterData.Rarity.COMMON],

		["Striker Comet", CharacterData.Affinity.COSMIC, 25, 25, 200,
			CharacterData.AbilityType.DESTROY_SELF_AT_END_OF_EXPOSE_TURN,
			{},
			"Once face-up, destroy it and the end of this turn",
			CharacterData.Rarity.COMMON,
			true],

		["Succubus", CharacterData.Affinity.CHAOS, 10, 30, 600,
			CharacterData.AbilityType.ONE_USE_COPY_STATS_ON_SURVIVE,
			{},
			"Once, if survived Reckoning: +ATK&DEF equal to half of that foe’s card",
			CharacterData.Rarity.COMMON],

		["Sunrise Lady", CharacterData.Affinity.DIVINE, 20, 25, 300,
			CharacterData.AbilityType.ATTACK_STANCE_BOOST,
			{"atk": 10},
			"If it attacks: +10 ATK,-10 DEF permanently",
			CharacterData.Rarity.COMMON],

		["Swarmcaller", CharacterData.Affinity.NATURE, 45, 45, 950,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 15, "def_bonus": 15, "affinity": CharacterData.Affinity.NATURE},
			"+15 ATK&DEF for each other face-up Nature card on your field",
			CharacterData.Rarity.LEGENDARY],

		["Tiny Pixie", CharacterData.Affinity.DIVINE, 0, 0, 100,
			CharacterData.AbilityType.ONE_USE_SURVIVE_DESTRUCTION,
			{},
			"Once, this card is not destroyed",
			CharacterData.Rarity.COMMON],

		["Tomb Bandit", CharacterData.Affinity.ANIMA, 75, 60, 1000,
			CharacterData.AbilityType.IMMUNE_TO_TRAPS,
			{},
			"This Unit cannot be destroyed by Traps.",
			CharacterData.Rarity.LEGENDARY],

		["Vampire Duchess", CharacterData.Affinity.CHAOS, 50, 50, 800,
			CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE,
			{},
			"In Reckoning with Divine, destroy this card. In Reckoning with non-Divine, Drain 5 ATK&DEF permanently",
			CharacterData.Rarity.RARE],

		["Vampire Servant", CharacterData.Affinity.CHAOS, 20, 20, 800,
			CharacterData.AbilityType.SACRIFICE_FOR_CARD_TYPE,
			{"name_contains": "Vampire"},
			"If a 'Vampire' card will be destroyed, destroy this card instead. Usable face-down.",
			CharacterData.Rarity.UNCOMMON],

		["Vile Creeper", CharacterData.Affinity.BIO, 10, 30, 200,
			CharacterData.AbilityType.SWAP_ATK_DEF_PER_OPP_TURN,
			{},
			"While this card is face-up, at foe’s turn ends, swap its ATK&DEF",
			CharacterData.Rarity.COMMON,
			true],

		["Void Stalker", CharacterData.Affinity.CHAOS, 65, 25, 720,
			CharacterData.AbilityType.ATK_BOOST_VS_REVEALED,
			{"bonus": 20},
			"+20 ATK if it attack an exposed card",
			CharacterData.Rarity.RARE],

		["Wandering Swordsman", CharacterData.Affinity.ANIMA, 60, 60, 600,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.RARE],

		["War Genie", CharacterData.Affinity.ARCANE, 100, 80, 1150,
			CharacterData.AbilityType.PERM_ATK_LOSS_PER_ATTACK,
			{"amount": 10},
			"-10 ATK permanently after it attacked",
			CharacterData.Rarity.LEGENDARY],

		["White Tiger", CharacterData.Affinity.NATURE, 40, 25, 450,
			CharacterData.AbilityType.ATTACKER_ATK_DEBUFF,
			{"amount": 15},
			"In Reckoning, -15 ATK to the attacker",
			CharacterData.Rarity.UNCOMMON],

		["Witchhunter", CharacterData.Affinity.ANIMA, 20, 20, 250,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.ARCANE, "atk": 5, "def": 5},
			"+5 ATK&DEF vs Arcane",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Yaksa", CharacterData.Affinity.CHAOS, 30, 30, 500,
			CharacterData.AbilityType.NONE,
			{},
			"None",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Aether Warden", CharacterData.Affinity.DIVINE, 30, 110, 800,
			CharacterData.AbilityType.DEFEND_DRAIN_ATTACKER,
			{"drain_amount": 300},
			"Attacking player loses 300 Crystals",
			CharacterData.Rarity.RARE],

		["Ancient Lich", CharacterData.Affinity.CHAOS, 60, 60, 750,
			CharacterData.AbilityType.IMMUNE_TO_TECH_CARDS, {},
			"This card is unaffected by Tech cards.",
			CharacterData.Rarity.RARE],

		["Champion of the Valley", CharacterData.Affinity.ANIMA, 35, 45, 400,
			CharacterData.AbilityType.PERM_ATK_BOOST_ON_KILL_CAPPED, {"atk": 10, "max_bonus": 30},
			"+10 ATK permanently if it destroyed a unit. This bonus do not exceed maximum of 30",
			CharacterData.Rarity.UNCOMMON],

		["Death Stag", CharacterData.Affinity.NATURE, 45, 40, 400,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Ectoplasm", CharacterData.Affinity.BIO, 20, 0, 800,
			CharacterData.AbilityType.COPY_ALLY_STATS_ON_DESTROY, {},
			"When your unit card is destroy, you can copy ATK, DEF, Crystal Cost of the destroyed card to this card instead. Can be triggered face-down.",
			CharacterData.Rarity.EXOTIC],

		["Fierce Gladiator", CharacterData.Affinity.ANIMA, 70, 90, 1000,
			CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND,
			{"amount": 500},
			"+500 Crystal on successful defend",
			CharacterData.Rarity.RARE],

		["Giant Mosquito", CharacterData.Affinity.NATURE, 30, 20, 800,
			CharacterData.AbilityType.TEMP_ATK_HALF_TARGET, {},
			"If this card performs an attack, +ATK equal to half of target’s ATK until the end of this turn",
			CharacterData.Rarity.EXOTIC],

		["Grand Wizard", CharacterData.Affinity.ARCANE, 90, 70, 1100,
			CharacterData.AbilityType.COIN_FLIP_ATK_DEF_BOOST, {"bonus": 30},
			"In reckoning, flip a coin, if head, +30 ATK and DEF until this turn’s end",
			CharacterData.Rarity.LEGENDARY],

		["Horn Face", CharacterData.Affinity.COSMIC, 85, 60, 1350,
			CharacterData.AbilityType.COIN_FLIP_EXTRA_ATTACK, {"max_attacks": 3},
			"After successfully attack, flip a coin, if head, it can attack again. Can do up to 3 times.",
			CharacterData.Rarity.EXOTIC],

		["Hyperspeed Saucer", CharacterData.Affinity.COSMIC, 80, 40, 850,
			CharacterData.AbilityType.PERM_BOOST_END_OF_TURN,
			{"atk": 10, "def": 10},
			"Permanently increase this card's ATK and DEF by 10 at the end of each of your turn",
			CharacterData.Rarity.LEGENDARY],

		["Ironclad Sentinel", CharacterData.Affinity.ANIMA, 55, 95, 1100,
			CharacterData.AbilityType.IMMUNE_TO_TECH_DESTRUCTION, {},
			"Immune to 0-cost Traps. This Unit cannot be destroyed by Tech Cards.",
			CharacterData.Rarity.EXOTIC],

		["Lightbringer", CharacterData.Affinity.DIVINE, 80, 40, 1200,
			CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS, "bonus": 100},
			"+100 DEF vs Chaos Affinity",
			CharacterData.Rarity.RARE],

		["Mountain Sage", CharacterData.Affinity.ARCANE, 50, 30, 600,
			CharacterData.AbilityType.DOUBLE_TECH_EFFECT, {},
			"Double effect of Tech card apply to this unit",
			CharacterData.Rarity.RARE],

		["Railgun Tank", CharacterData.Affinity.ANIMA, 150, 95, 1500,
			CharacterData.AbilityType.LOCK_SELF_AFTER_ATTACK, {},
			"After successfully attack, this card cannot attack on the next of your turn.",
			CharacterData.Rarity.EXOTIC],

		["Slim Gray Trooper", CharacterData.Affinity.COSMIC, 45, 45, 750,
			CharacterData.AbilityType.ATK_DEF_BONUS_IF_OWN_REVEALED_GTE, {"min_revealed": 10, "atk": 30, "def": 30},
			"+30 ATK and DEF if 10 or more cells on your side is revealed",
			CharacterData.Rarity.UNCOMMON],
	]

	for d in defs:
		var data := CharacterData.new()
		data.card_name = d[0]
		data.affinity = d[1]
		data.base_atk = d[2]
		data.base_def = d[3]
		data.crystal_cost = d[4]
		data.ability_type = d[5]
		data.ability_params = d[6]
		data.ability_description = d[7]
		data.rarity = d[8]
		if d.size() > 9: data.placeholder_art = d[9]
		characters[data.card_name] = data

# ────────────────────────────────────────────────────────────
# TRAP CARDS
# ────────────────────────────────────────────────────────────
func _load_traps() -> void:
	var defs: Array = [
		# Name, Cost, EffectType, Params, Description, Rarity
		["Acid Trap Hole", 0, TrapData.TrapEffectType.DRAIN_ATTACKER_CRYSTALS,
			{"amount": 50, "coin_count": 2},
			"Flip 2 coin, attacking player loses 50 Crystals per each head(s).",
			CharacterData.Rarity.COMMON],

		["Alarm", 0, TrapData.TrapEffectType.FIELD_BOOST_AFFINITY_DEF,
			{"affinity": CharacterData.Affinity.ANIMA, "def": 10},
			"Until the end of this turn, All face-up Anima monster gain +10 DEF",
			CharacterData.Rarity.COMMON,
			true],

		["Bait", 0, TrapData.TrapEffectType.REVEAL_DEFENDING_CHOICE,
			{},
			"The defending player choose one square on their field and reveal it",
			CharacterData.Rarity.COMMON],

		["Blackmail", 0, TrapData.TrapEffectType.ATTACKER_DISCARD_OR_END_TURN,
			{},
			"The attacker choose either discarding 1 Tech Card or end the turn immediately",
			CharacterData.Rarity.UNCOMMON],

		["Brainwash", 1500, TrapData.TrapEffectType.FORCE_FRIENDLY_FIRE,
			{},
			"Foe choose their own ally as an attack target",
			CharacterData.Rarity.EXOTIC],

		["Bunker", 900, TrapData.TrapEffectType.NULLIFY_BLOCK_ADJACENT,
			{"directions": ["up","down","left","right"]},
			"Player cannot select adjacent cell as an attack target until the end of this turn.",
			CharacterData.Rarity.LEGENDARY],

		["Cursed Reflection", 500, TrapData.TrapEffectType.SWAP_ATTACKER_ATK_DEF_TEMP,
			{},
			"Swap the attacker's ATK&DEF until the end of this turn",
			CharacterData.Rarity.RARE],

		["Decoy Puppet", 100, TrapData.TrapEffectType.CANCEL_ATTACKER_ATTACK,
			{"max_attack_cost": 400},
			"This turn, foe cannot perform any more attack using unit with 400 or less cost.",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Defensive Pheromone", 500, TrapData.TrapEffectType.SWAP_ARMORED_NATURE,
			{},
			"Select 1 'Armored' Nature card and switch it with this cell",
			CharacterData.Rarity.RARE],

		["Echo Barrier", 1000, TrapData.TrapEffectType.LOCK_ATTACKER_REMAINING_ATTACKS,
			{},
			"This turn, foe cannot perform any more attack.",
			CharacterData.Rarity.RARE],

		["Explosive Barrels", 0, TrapData.TrapEffectType.DESTROY_ATTACKER_DEFENDER_PAYS,
			{},
			"Destroy the attacker. You also pay the same cost as foe.",
			CharacterData.Rarity.EXOTIC],

		["Flame Trap", 250, TrapData.TrapEffectType.PERMANENT_ATK_DEBUFF,
			{"amount": 10},
			"Permanently -10 ATK to the Attacking unit",
			CharacterData.Rarity.UNCOMMON],

		["Foul Gas", 0, TrapData.TrapEffectType.TEMP_DEBUFF_ALL_ATTACKER_CHARS,
			{"amount": 5},
			"-5 ATK to all the attacking player’s units until the end of this turn",
			CharacterData.Rarity.RARE],

		["Hard Scale", 700, TrapData.TrapEffectType.TEMP_DEF_BOOST_ONE_OWN,
			{"def": 5, "all_own_units": true},
			"All of your unit gain +5 DEF in Reckoning until this turn’s end",
			CharacterData.Rarity.COMMON,
			true],

		["Hostage", 200, TrapData.TrapEffectType.NULLIFY_ATTACK_REVEAL_ADJACENT,
			{"directions": ["up","down","left","right"], "lock_revealed": true},
			"Reveal 1 of your own cell. Until the foe’s turn ends, foe cannot target than cell.",
			CharacterData.Rarity.UNCOMMON],

		["Hypnosis", 800, TrapData.TrapEffectType.HYPNOTIZE_ATTACKER,
			{},
			"The attacking unit cannot attack during their next turn",
			CharacterData.Rarity.LEGENDARY],

		["Pepper Spray", 0, TrapData.TrapEffectType.COIN_FLIP_2_ATK_DEBUFF,
			{"amount": 5},
			"Flip 2 coin, if head, the attacking unit lose -5 ATK for each head(s) until the end of their next turn.",
			CharacterData.Rarity.COMMON,
			true],

		["Red Card", 0, TrapData.TrapEffectType.COIN_FLIP_2_LOCK_ATTACKER,
			{},
			"Flip 2 coin, if head, that unit cannot attack next turn",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Self-destruct", 0, TrapData.TrapEffectType.SELF_DESTROY_TEMP_ATK_BOOST,
			{"atk": 10},
			"Select 1 of your unit. +10 ATK until your next turn’s end, but also destroy it. You pay no cost.",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Snare Trap", 500, TrapData.TrapEffectType.NULLIFY_ATTACKER_EFFECT,
			{},
			"The attacker's effect becomes None until foe’s next turn ends",
			CharacterData.Rarity.LEGENDARY],

		["Spike Trap", 1500, TrapData.TrapEffectType.DESTROY_ATTACKER,
			{},
			"Destroy the attacking unit",
			CharacterData.Rarity.EXOTIC],

		["Street Joke", 0, TrapData.TrapEffectType.REVEAL_OWN_GAIN_CRYSTAL,
			{"amount": 100},
			"Reveal 1 of your cell, you receive 100 crystal",
			CharacterData.Rarity.COMMON,
			true],

		["Trap Hole", 0, TrapData.TrapEffectType.DRAIN_ATTACKER_CRYSTALS,
			{"amount": 20, "coin_count": 3},
			"Flip 3 coin, attacking player loses 20 Crystals per each head(s).",
			CharacterData.Rarity.COMMON],

		["Mana Drain", 200, TrapData.TrapEffectType.DRAIN_ATTACKER_CRYSTALS,
			{"amount": 300, "transfer_to_defender": true},
			"Attacking player loses 300 crystals. Increase your crystal by that amount",
			CharacterData.Rarity.COMMON],
	]

	for d in defs:
		var data := TrapData.new()
		data.card_name = d[0]
		data.crystal_cost = d[1]
		data.effect_type = d[2]
		data.effect_params = d[3]
		data.effect_description = d[4]
		data.rarity = d[5]
		if d.size() > 6: data.placeholder_art = d[6]
		traps[data.card_name] = data

	# Per-card artwork offsets (positive Y = down, negative Y = up)
	traps["Hypnosis"].artwork_offset = Vector2(0, -40)
	traps["Bait"].artwork_offset     = Vector2(0, -40)

# ────────────────────────────────────────────────────────────
# TECH CARDS
# ────────────────────────────────────────────────────────────
func _load_tech_cards() -> void:
	var defs: Array = [
		# Name, Cost, EffectType, Params, RequiredPrior, Description, Rarity
		["Accident", 1000, TechCardData.TechEffectType.DESTROY_FACEUP_NO_CRYSTAL_LOSS,
			{}, "",
			"Destroy 1 of foe’s face-up card. If there is no face-up card, foe must chooses the target. Foe pay no cost.",
			CharacterData.Rarity.RARE,
			true],

		["Bribe", 0, TechCardData.TechEffectType.OPPONENT_REVEALS_OR_GAINS,
			{"crystal_reward": 700}, "",
			"Your foe can choose to reveal a unit card and receive 700 crystals or do nothing",
			CharacterData.Rarity.RARE],

		["Great Diplomacy", 1000, TechCardData.TechEffectType.REVEAL_ALL_OWN_CHARACTERS,
			{"count": 5}, "",
			"Select up to 5 of your units and reveal them.",
			CharacterData.Rarity.LEGENDARY],

		["Prayer", 0, TechCardData.TechEffectType.DIVINE_PROTECTION,
			{}, "",
			"Once, until foe’s turn ends: prevent Divine card from being destroyed",
			CharacterData.Rarity.LEGENDARY],

		["Radar", 600, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE,
			{"count": 3}, "",
			"Reveal 3 of foe’s cell",
			CharacterData.Rarity.COMMON],

		["Release Mutagen", 0, TechCardData.TechEffectType.ADD_MUTAGEN_FLAG,
			{}, "",
			"Select and reveal (if face-down) 1 of your Bio Unit on the field. Add Mutagen Flag to it.",
			CharacterData.Rarity.LEGENDARY],

		["Resurrection", 1500, TechCardData.TechEffectType.REVIVE_CHARACTER_NO_ATK,
			{}, "",
			"Once, revive 1 unit. It has no ATK,DEF, or ability.",
			CharacterData.Rarity.LEGENDARY],

		["Siege Cannon", 1000, TechCardData.TechEffectType.OPPONENT_NEXT_DEFENDER_DESTROYED,
			{}, "",
			"Until the end of this turn, once, foe’s defending unit is destroyed.",
			CharacterData.Rarity.EXOTIC],

		["Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE,
			{"count": 1}, "",
			"Reveal 1 of foe’s cell",
			CharacterData.Rarity.COMMON],

		["Tease", 0, TechCardData.TechEffectType.OPPONENT_REVEALS_SQUARE,
			{}, "",
			"Your foe choose and reveal 1 of their cell",
			CharacterData.Rarity.UNCOMMON],

		["War Supply", 1000, TechCardData.TechEffectType.TEMP_ATK_DEF_BOOST_ALL,
			{"atk": 10, "def": 10}, "",
			"Your units get +10 ATK&DEF in Reckoning until turn’s end",
			CharacterData.Rarity.RARE],

		["Arcane Duplication", 1000, TechCardData.TechEffectType.CLONE_CHARACTER_AS_TOKEN,
			{"destroy_at_turn_end": true}, "",
			"Choose 1 of your face-up Units. Create a token copy of it on an empty square on your field. Destroy it at the start of your next turn.",
			CharacterData.Rarity.COMMON],

		["Arcane Nova", 3000, TechCardData.TechEffectType.DESTROY_ALL_REVEALED_OPPONENT,
			{"count": 5}, "",
			"Destroy 5 face-up foe Units. You foe do not lose crystals under this effect. Discard all of your Tech afterward.",
			CharacterData.Rarity.LEGENDARY],

		["Berserk", 2000, TechCardData.TechEffectType.MULTI_ATTACK_ONE,
			{"extra_attacks": 1}, "",
			"Select 1 of your face-up unit. You get 1 additional attack, but can only perform attack with that unit. You can’t use this card if you’ve already performed any attack.",
			CharacterData.Rarity.EXOTIC],

		["Blood Ritual", 1200, TechCardData.TechEffectType.DESTROY_OWN_BASE_ZERO_OPPONENT,
			{}, "",
			"Destroy 1 face-up card on the your field. You don't pay Crystal cost for the destroyed card. Choose 1 of your foe's face-up unit. Its ATK and DEF becomes 0 permanently",
			CharacterData.Rarity.LEGENDARY],

		["Bulletproof Vest", 850, TechCardData.TechEffectType.PERM_DEF_BOOST_ONE,
			{"def": 15}, "",
			"+15 DEF permanently for 1 face-up unit. If use on face-down card, flip it up.",
			CharacterData.Rarity.COMMON],

		["Ceasefire", 0, TechCardData.TechEffectType.BOTH_SKIP_TURN,
			{}, "",
			"Both you and your foe skip 1 turn (tax is forced to apply)",
			CharacterData.Rarity.COMMON],

		["Corrupted Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_RISKY,
			{"count": 3, "cost_per_card": 700}, "",
			"Reveal 3 square on foe's side of the field. If you found any trap or Unit, you pay 700 Crystal or each card found.",
			CharacterData.Rarity.COMMON,
			true],

		["Double Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN,
			{"count": 2}, "Spy",
			"This card only trigger if you have Spy card in your void. Reveal 2 square on foe's side of the field.",
			CharacterData.Rarity.RARE],

		["Essence Transfer", 700, TechCardData.TechEffectType.MOVE_BUFFS_BETWEEN_CHARACTERS,
			{}, "",
			"Choose 1 of your Units. Move all its ATK and DEF bonuses or debuffs to another face-up Unit on your field. If used on face-down card, you can turn it face-up and apply this effect.",
			CharacterData.Rarity.COMMON],

		["Force Shield", 600, TechCardData.TechEffectType.FORCE_SHIELD_ONE_CARD,
			{}, "",
			"Select 1 card on your field. It is not destroyed until the end of your foe's turn",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Garrison", 1500, TechCardData.TechEffectType.TEMP_DEF_BOOST_ALL,
			{"def": 20}, "",
			"Until foe's turn ends: +20 DEF to all your cards in Reckoning",
			CharacterData.Rarity.COMMON],

		["Guerrilla Tactics", 1500, TechCardData.TechEffectType.GUERRILLA_TACTICS,
			{}, "",
			"Until the end of your foe's turn. Whenever your foe attack your dead end card, flip a coin. If head, destroy it.",
			CharacterData.Rarity.COMMON,
			true],

		["Harsh Training", 500, TechCardData.TechEffectType.PERM_ATK_BOOST_ONE,
			{"atk": 10, "allow_facedown": true}, "",
			"+10 ATK permanently to one of your unit. If used on face-down card, you can turn it face-up and apply this effect.",
			CharacterData.Rarity.COMMON],

		["Illegal Steroid", 1000, TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW,
			{"atk": 30, "force_attack": false}, "",
			"+30 ATK for 1 unit until the end of this turn.",
			CharacterData.Rarity.COMMON],

		["Invisible Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN,
			{"count": 2}, "Double Spy",
			"This card only trigger if you have Double Spy card in your void. Reveal 2 square on foe's side of the field.",
			CharacterData.Rarity.LEGENDARY],

		["Lucky Day", 300, TechCardData.TechEffectType.TEMP_REROLL_DICE,
			{"coin_reward": 600}, "",
			"Flip a coin. If head, receive 600 crystals.",
			CharacterData.Rarity.UNCOMMON,
			true],

		["Make Friend", 0, TechCardData.TechEffectType.BOTH_LOCK_CHOSEN_MONSTER,
			{"allow_facedown": true}, "",
			"Both you and your foe select 1 monster from own's field (can reveal face-down card for this effect). Those monster cannot attack until the end of your next turn.",
			CharacterData.Rarity.UNCOMMON],

		["Rift Strike", 2000, TechCardData.TechEffectType.DESTROY_ROW_AROUND_TARGET,
			{}, "",
			"Select 1 face-up foe’s card. Destroy other face-up units on that same rows. Your foe don’t pay cost.",
			CharacterData.Rarity.COMMON],

		["Tech Copy", 1000, TechCardData.TechEffectType.VIEW_OPPONENT_TECH,
			{"copy_to_hand": true}, "",
			"Your foe show 1 tech card in their hand. Add a copy of that card into your Tech Stack.",
			CharacterData.Rarity.COMMON,
			true],

		["Time Travel", 1800, TechCardData.TechEffectType.REVIVE_CHARACTER_FULL,
			{"double_cost": true}, "",
			"Once only, revive 1 unit to any unoccupied or empty cell in face-up position. Double its crystal cost.",
			CharacterData.Rarity.EXOTIC],

		["Wisp Light", 250, TechCardData.TechEffectType.DESTROY_WISPS_REVEAL_OPPONENT,
			{}, "",
			"Destroy as many wisp on your side of the field  as you can. Reveal that much square on foe's field.",
			CharacterData.Rarity.UNCOMMON,
			true],
	]

	for d in defs:
		var data := TechCardData.new()
		data.card_name = d[0]
		data.crystal_cost = d[1]
		data.effect_type = d[2]
		data.effect_params = d[3]
		data.required_prior_card = d[4]
		data.effect_description = d[5]
		data.rarity = d[6]
		if d.size() > 7: data.placeholder_art = d[7]
		tech_cards[data.card_name] = data

# ────────────────────────────────────────────────────────────
# Lookup helpers
# ────────────────────────────────────────────────────────────
func get_character(card_name: String) -> CharacterData:
	return characters.get(card_name, null)

func get_trap(card_name: String) -> TrapData:
	return traps.get(card_name, null)

func get_tech(card_name: String) -> TechCardData:
	return tech_cards.get(card_name, null)

func get_all_character_names() -> Array:
	return characters.keys()

func get_all_trap_names() -> Array:
	return traps.keys()

func get_all_tech_names() -> Array:
	return tech_cards.keys()

# ────────────────────────────────────────────────────────────
# Card editor overrides (persisted to JSON)
# ────────────────────────────────────────────────────────────
const EDITOR_OVERRIDES_PATH := "res://data/card_editor_overrides.json"

func _empty_editor_overrides() -> Dictionary:
	return {"characters": {}, "traps": {}, "tech": {}, "unions": {}}

func _load_editor_overrides_file() -> Dictionary:
	var data := _empty_editor_overrides()
	if not FileAccess.file_exists(EDITOR_OVERRIDES_PATH):
		return data
	var file := FileAccess.open(EDITOR_OVERRIDES_PATH, FileAccess.READ)
	if file == null:
		return data
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return data
	for section: String in data.keys():
		if parsed.has(section) and parsed[section] is Dictionary:
			data[section] = parsed[section]
	return data

func _write_editor_overrides_file(data: Dictionary) -> bool:
	var file := FileAccess.open(EDITOR_OVERRIDES_PATH, FileAccess.WRITE)
	if file == null:
		push_error("CardDatabase: failed to write %s" % EDITOR_OVERRIDES_PATH)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func _apply_card_editor_overrides() -> void:
	var data := _load_editor_overrides_file()
	for card_name: String in data["characters"]:
		var d: CharacterData = get_character(card_name)
		if d != null:
			_apply_character_override(d, data["characters"][card_name])
	for card_name: String in data["traps"]:
		var d: TrapData = get_trap(card_name)
		if d != null:
			_apply_trap_override(d, data["traps"][card_name])
	for card_name: String in data["tech"]:
		var d: TechCardData = get_tech(card_name)
		if d != null:
			_apply_tech_override(d, data["tech"][card_name])

func apply_union_editor_overrides() -> void:
	var data := _load_editor_overrides_file()
	for card_name: String in data["unions"]:
		var u: UnionData = UnionDatabase.get_union(card_name)
		if u != null:
			_apply_union_override(u, data["unions"][card_name])

func _apply_character_override(d: CharacterData, o: Dictionary) -> void:
	if o.has("display_name"): d.display_name = str(o["display_name"])
	if o.has("base_atk"): d.base_atk = int(o["base_atk"])
	if o.has("base_def"): d.base_def = int(o["base_def"])
	if o.has("crystal_cost"): d.crystal_cost = int(o["crystal_cost"])
	if o.has("rarity"): d.rarity = int(o["rarity"])
	if o.has("affinity"): d.affinity = int(o["affinity"])
	if o.has("ability_description"): d.ability_description = str(o["ability_description"])

func _apply_trap_override(d: TrapData, o: Dictionary) -> void:
	if o.has("display_name"): d.display_name = str(o["display_name"])
	if o.has("crystal_cost"): d.crystal_cost = int(o["crystal_cost"])
	if o.has("rarity"): d.rarity = int(o["rarity"])
	if o.has("effect_description"): d.effect_description = str(o["effect_description"])

func _apply_tech_override(d: TechCardData, o: Dictionary) -> void:
	if o.has("display_name"): d.display_name = str(o["display_name"])
	if o.has("crystal_cost"): d.crystal_cost = int(o["crystal_cost"])
	if o.has("rarity"): d.rarity = int(o["rarity"])
	if o.has("effect_description"): d.effect_description = str(o["effect_description"])

func _apply_union_override(u: UnionData, o: Dictionary) -> void:
	if o.has("display_name"): u.display_name = str(o["display_name"])
	if o.has("base_atk"): u.base_atk = int(o["base_atk"])
	if o.has("base_def"): u.base_def = int(o["base_def"])
	if o.has("summon_cost"): u.summon_cost = int(o["summon_cost"])
	if o.has("rarity"): u.rarity = int(o["rarity"])
	if o.has("affinity"): u.affinity = int(o["affinity"])
	if o.has("ability_description"): u.ability_description = str(o["ability_description"])
	if o.has("partial_ability_description"):
		u.partial_ability_description = str(o["partial_ability_description"])
	if o.has("formula_description"): u.formula_description = str(o["formula_description"])
	if o.has("partial_formula_description"):
		u.partial_formula_description = str(o["partial_formula_description"])
	if o.has("union_zone") and o["union_zone"] is Array:
		u.union_zone = _deserialize_union_zone(o["union_zone"])

func _serialize_union_zone(zone: Array) -> Array:
	var out: Array = []
	for v: Variant in zone:
		if v is Vector2i:
			out.append([v.x, v.y])
	return out

func _deserialize_union_zone(arr: Array) -> Array:
	var out: Array = []
	for item: Variant in arr:
		if item is Array and item.size() >= 2:
			out.append(Vector2i(int(item[0]), int(item[1])))
	return out

func snapshot_character_editor_fields(d: CharacterData) -> Dictionary:
	return {
		"display_name": d.display_name,
		"base_atk": d.base_atk,
		"base_def": d.base_def,
		"crystal_cost": d.crystal_cost,
		"rarity": d.rarity,
		"affinity": d.affinity,
		"ability_description": d.ability_description,
	}

func snapshot_trap_editor_fields(d: TrapData) -> Dictionary:
	return {
		"display_name": d.display_name,
		"crystal_cost": d.crystal_cost,
		"rarity": d.rarity,
		"effect_description": d.effect_description,
	}

func snapshot_tech_editor_fields(d: TechCardData) -> Dictionary:
	return {
		"display_name": d.display_name,
		"crystal_cost": d.crystal_cost,
		"rarity": d.rarity,
		"effect_description": d.effect_description,
	}

func snapshot_union_editor_fields(u: UnionData) -> Dictionary:
	return {
		"display_name": u.display_name,
		"base_atk": u.base_atk,
		"base_def": u.base_def,
		"summon_cost": u.summon_cost,
		"rarity": u.rarity,
		"affinity": u.affinity,
		"ability_description": u.ability_description,
		"partial_ability_description": u.partial_ability_description,
		"formula_description": u.formula_description,
		"partial_formula_description": u.partial_formula_description,
		"union_zone": _serialize_union_zone(u.union_zone),
	}

func save_card_editor_snapshot(card_type: String, card_name: String) -> bool:
	var fields: Dictionary = {}
	match card_type:
		"characters":
			var d: CharacterData = get_character(card_name)
			if d == null:
				return false
			fields = snapshot_character_editor_fields(d)
		"traps":
			var t: TrapData = get_trap(card_name)
			if t == null:
				return false
			fields = snapshot_trap_editor_fields(t)
		"tech":
			var tech: TechCardData = get_tech(card_name)
			if tech == null:
				return false
			fields = snapshot_tech_editor_fields(tech)
		"unions":
			var u: UnionData = UnionDatabase.get_union(card_name)
			if u == null:
				return false
			fields = snapshot_union_editor_fields(u)
		_:
			return false
	var data := _load_editor_overrides_file()
	data[card_type][card_name] = fields
	return _write_editor_overrides_file(data)

# ────────────────────────────────────────────────────────────
# Demo flags persistence
# ────────────────────────────────────────────────────────────
func save_demo_flags() -> void:
	var flags: Dictionary = {}
	for card_name: String in characters:
		if (characters[card_name] as CharacterData).include_in_demo:
			flags[card_name] = true
	for card_name: String in traps:
		if (traps[card_name] as TrapData).include_in_demo:
			flags[card_name] = true
	for card_name: String in tech_cards:
		if (tech_cards[card_name] as TechCardData).include_in_demo:
			flags[card_name] = true
	for u: UnionData in UnionDatabase.get_all_unions():
		if u.include_in_demo:
			flags[u.card_name] = true
	var file := FileAccess.open("res://data/demo_flags.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(flags, "\t"))
		file.close()

# ────────────────────────────────────────────────────────────
# Artwork path cache  (scans each folder at most once per name)
# ────────────────────────────────────────────────────────────
var _art_cache: Dictionary = {}  # "subfolder/snake_name" -> full res:// path or ""

func find_artwork(card_name: String, subfolder: String, prefer_nsfw: bool = false) -> String:
	var snake: String = card_name.to_lower() \
		.replace(" ", "_").replace("'", "").replace("-", "_")

	if prefer_nsfw:
		var nsfw_result: String = _find_artwork_by_snake(snake + "_nsfw", subfolder)
		if nsfw_result != "":
			return nsfw_result

	return _find_artwork_by_snake(snake, subfolder)

func _find_artwork_by_snake(snake: String, subfolder: String) -> String:
	var key: String = subfolder + "/" + snake
	if _art_cache.has(key) and _art_cache[key] != "":
		return _art_cache[key]

	var dir_path: String = "res://assets/textures/cards/%s/" % subfolder

	# Try common extensions directly first — more reliable than DirAccess enumeration.
	for ext: String in ["png", "jpg", "jpeg", "webp"]:
		var direct: String = dir_path + snake + "." + ext
		if ResourceLoader.exists(direct):
			_art_cache[key] = direct
			return direct

	# Fallback: scan directory (handles any other extension).
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and not file_name.ends_with(".import"):
				if file_name.get_basename() == snake:
					var full_path: String = dir_path + file_name
					if ResourceLoader.exists(full_path):
						dir.list_dir_end()
						_art_cache[key] = full_path
						return full_path
			file_name = dir.get_next()
		dir.list_dir_end()

	return ""
