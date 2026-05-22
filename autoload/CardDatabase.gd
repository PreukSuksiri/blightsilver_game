extends Node

# All card definitions loaded at startup
var characters: Dictionary = {}  # name -> CharacterData
var traps: Dictionary = {}       # name -> TrapData
var tech_cards: Dictionary = {}  # name -> TechCardData


func _ready() -> void:
	_load_characters()
	_load_traps()
	_load_tech_cards()
	_apply_demo_flags()

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
		["Aerial the Battlemage", CharacterData.Affinity.ARCANE, 50, 45, 700,
			CharacterData.AbilityType.ATK_DEF_BONUS_IF_UNION_ON_FIELD,
			{"atk": 20, "def": 20},
			"+20 ATK and DEF if there is Union card on your field",
			CharacterData.Rarity.RARE],

		["Angel Gatekeeper", CharacterData.Affinity.DIVINE, 40, 90, 960,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS, "bonus": 50},
			"+50 ATK vs Chaos Affinity",
			CharacterData.Rarity.LEGENDARY],

		["Araya the Eerie Dancer", CharacterData.Affinity.CHAOS, 15, 20, 400,
			CharacterData.AbilityType.IMMUNE_TO_TECH_CARDS,
			{},
			"This card is unaffected by Tech cards",
			CharacterData.Rarity.COMMON],

		["Archbishop", CharacterData.Affinity.DIVINE, 70, 90, 850,
			CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY,
			{"affinity": CharacterData.Affinity.DIVINE},
			"If this card would be destroyed, you can destroy 1 other Divine card on their own field instead",
			CharacterData.Rarity.LEGENDARY],

		["Armored Bee", CharacterData.Affinity.NATURE, 30, 0, 480,
			CharacterData.AbilityType.ONE_USE_DEF_BOOST,
			{"bonus": 60},
			"+60 DEF until the end of that turn once",
			CharacterData.Rarity.UNCOMMON],

		["Armored Money", CharacterData.Affinity.NATURE, 10, 20, 170,
			CharacterData.AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD,
			{"affinity": CharacterData.Affinity.NATURE, "bonus": 10},
			"+10 ATK if there is face-up Nature card",
			CharacterData.Rarity.COMMON],

		["Armored Rhino", CharacterData.Affinity.NATURE, 60, 85, 700,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
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
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Bladeshifter", CharacterData.Affinity.BIO, 0, 50, 420,
			CharacterData.AbilityType.ONE_USE_DEFEND_MORPH,
			{"atk": 40, "def": 40},
			"Once, after this card defended successfully, it permanently lose -40 DEF and permanently gain +40 ATK against attacker’s affinity",
			CharacterData.Rarity.UNCOMMON],

		["Bleacher Squad", CharacterData.Affinity.BIO, 20, 20, 320,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.BIO, "bonus": 20},
			"+20 ATK vs Bio",
			CharacterData.Rarity.COMMON],

		["Blue Mage", CharacterData.Affinity.ARCANE, 45, 45, 800,
			CharacterData.AbilityType.COIN_FLIP_2_DESTROY_NON_AFFINITY,
			{"affinity": CharacterData.Affinity.ARCANE},
			"If this card battles non-Arcane card, flip 2 coins. If both are heads, destroy defender.",
			CharacterData.Rarity.RARE],

		["Bomber Fairy", CharacterData.Affinity.DIVINE, 30, 15, 500,
			CharacterData.AbilityType.ONE_USE_EXTRA_ATTACK_ON_KILL,
			{},
			"Once, if destroyed a card, this card can attack 1 more time",
			CharacterData.Rarity.UNCOMMON],

		["Book with Fangs", CharacterData.Affinity.ARCANE, 45, 55, 700,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.ARCANE, "atk": 30, "def": 30},
			"+30 ATK and DEF vs Arcane",
			CharacterData.Rarity.RARE],

		["Canyon Warg", CharacterData.Affinity.NATURE, 70, 30, 550,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.RARE],

		["Chaotic Wisp", CharacterData.Affinity.CHAOS, 20, 0, 100,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Choir Lady Abigail", CharacterData.Affinity.DIVINE, 25, 15, 250,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Choir Lady Alice", CharacterData.Affinity.DIVINE, 20, 25, 250,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Choir Lady Anna", CharacterData.Affinity.DIVINE, 20, 20, 250,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Church Guard", CharacterData.Affinity.DIVINE, 0, 35, 150,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Claw Mutant", CharacterData.Affinity.BIO, 15, 10, 180,
			CharacterData.AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES,
			{"bonus": 10, "affinities": []},
			"+10 ATK if it has mutagen flag",
			CharacterData.Rarity.COMMON],

		["Cursed Well", CharacterData.Affinity.CHAOS, 0, 25, 300,
			CharacterData.AbilityType.ATK_BOOST_VS_REVEALED,
			{"bonus": 15},
			"+15 ATK if exposed",
			CharacterData.Rarity.COMMON],

		["Dark Blob", CharacterData.Affinity.CHAOS, 20, 50, 500,
			CharacterData.AbilityType.PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN,
			{"atk": 5},
			"+5 ATK permanently at the end of each opponent’s turn this card survives.",
			CharacterData.Rarity.UNCOMMON],

		["Dark Monk", CharacterData.Affinity.CHAOS, 15, 25, 300,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Dark Tengu", CharacterData.Affinity.CHAOS, 25, 25, 250,
			CharacterData.AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND,
			{"atk": 5, "def": 5},
			"-5 ATK once it successfully attacked. -5 DEF once it successfully defended.",
			CharacterData.Rarity.COMMON],

		["Death Cobra", CharacterData.Affinity.NATURE, 85, 50, 850,
			CharacterData.AbilityType.VENOM_FLAG_END_OF_TURN,
			{},
			"At the end of this turn, a venom flag is placed on a random face-up opponent card.",
			CharacterData.Rarity.LEGENDARY],

		["Death Knight", CharacterData.Affinity.CHAOS, 65, 65, 780,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 5, "def_bonus": 0, "affinity": CharacterData.Affinity.CHAOS},
			"+5 ATK per Chaos card on your side of the field",
			CharacterData.Rarity.RARE],

		["Demon Spawn", CharacterData.Affinity.CHAOS, 40, 30, 400,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Doom Wisp", CharacterData.Affinity.CHAOS, 15, 15, 100,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Echo Bringer", CharacterData.Affinity.COSMIC, 55, 40, 500,
			CharacterData.AbilityType.EXTRA_ATTACK_VS_REVEALED,
			{},
			"When this card attacks a revealed card, it can attack a second time this turn (once per turn).",
			CharacterData.Rarity.RARE],

		["Electrogazer", CharacterData.Affinity.COSMIC, 45, 45, 600,
			CharacterData.AbilityType.NEGATE_ZERO_COST_TRAPS_BOTH,
			{},
			"Negate all zero cost trap on both player’s field",
			CharacterData.Rarity.LEGENDARY],

		["Feral Vampire", CharacterData.Affinity.CHAOS, 40, 25, 400,
			CharacterData.AbilityType.DESTROY_SELF_VS_DIVINE_BOTH,
			{},
			"Destroy this card when battling with Divine card",
			CharacterData.Rarity.UNCOMMON],

		["Flame Lizard", CharacterData.Affinity.NATURE, 25, 40, 400,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.NATURE, "atk": 20, "def": 20},
			"+20 ATK and DEF vs Nature",
			CharacterData.Rarity.UNCOMMON],

		["Flame Seraph", CharacterData.Affinity.DIVINE, 50, 10, 500,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Foul Wisp", CharacterData.Affinity.CHAOS, 0, 25, 100,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Fujin", CharacterData.Affinity.DIVINE, 35, 40, 450,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Gamma Emitter", CharacterData.Affinity.BIO, 20, 15, 220,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.NATURE, "atk": 10, "def": 10},
			"+10 ATK and DEF vs Nature",
			CharacterData.Rarity.COMMON],

		["Giant Centipede", CharacterData.Affinity.NATURE, 20, 20, 1500,
			CharacterData.AbilityType.ATK_BONUS_VS_VENOM,
			{"bonus": 100},
			"+100 ATK vs cards with venom flag",
			CharacterData.Rarity.RARE],

		["Goblin Poacher", CharacterData.Affinity.NATURE, 30, 10, 250,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Goddess of Virtue", CharacterData.Affinity.DIVINE, 80, 100, 1400,
			CharacterData.AbilityType.DESTROY_IF_OPPONENT_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS},
			"At battle calculation, destroy Chaos card",
			CharacterData.Rarity.EXOTIC],

		["Golden Senju", CharacterData.Affinity.DIVINE, 15, 0, 200,
			CharacterData.AbilityType.MULTI_ATTACK_VS_NON_CHARACTER,
			{"max_attacks": 3},
			"If this card attacked non-character card, this card can attack again, up to 3 times.",
			CharacterData.Rarity.UNCOMMON],

		["Grand Fort Archer", CharacterData.Affinity.ANIMA, 20, 20, 280,
			CharacterData.AbilityType.ONE_USE_ATK_BOOST,
			{"bonus": 10},
			"Once, +10 ATK when attack",
			CharacterData.Rarity.UNCOMMON],

		["Grand Fort Footsoldier", CharacterData.Affinity.ANIMA, 25, 25, 300,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Grand Fort Mauler", CharacterData.Affinity.ANIMA, 40, 10, 350,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Grave Worm", CharacterData.Affinity.CHAOS, 15, 30, 250,
			CharacterData.AbilityType.OPPONENT_EXTRA_CRYSTAL_LOSS,
			{"amount": 20},
			"Whenever your opponent lose crystal, they lose 20 more crystals",
			CharacterData.Rarity.UNCOMMON],

		["Green Mage", CharacterData.Affinity.ARCANE, 15, 15, 400,
			CharacterData.AbilityType.DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF,
			{"atk": 10, "def": 10},
			"When this card defends, the attacker permanently loses 10 ATK and DEF.",
			CharacterData.Rarity.UNCOMMON],

		["Gryphon", CharacterData.Affinity.NATURE, 100, 85, 1200,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.EXOTIC],

		["Hairpin Assassin", CharacterData.Affinity.ANIMA, 25, 15, 300,
			CharacterData.AbilityType.OPTIONAL_CRYSTAL_PAY_ATK_BOOST,
			{"cost": 100, "atk": 10},
			"At battle calculation, you can pay 100 crystal for +10 ATK",
			CharacterData.Rarity.COMMON],

		["Hammer Shark", CharacterData.Affinity.NATURE, 20, 20, 250,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 10, "def_bonus": 0, "card_name_contains": "shark"},
			"+10 ATK per shark card on the field",
			CharacterData.Rarity.COMMON],

		["Hands in the Attic", CharacterData.Affinity.CHAOS, 20, 20, 300,
			CharacterData.AbilityType.TEMP_ATK_BOOST_OWN_TURN_START,
			{"atk": 10},
			"+10 ATK at the start of your turn (temp, cleared at end of turn).",
			CharacterData.Rarity.COMMON],

		["Heavy Tome Preacher", CharacterData.Affinity.DIVINE, 25, 20, 300,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Huntress of Green Glade", CharacterData.Affinity.ANIMA, 50, 50, 800,
			CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS,
			{},
			"Immune to 0-cost Traps",
			CharacterData.Rarity.RARE],

		["Ice Mage", CharacterData.Affinity.ARCANE, 50, 0, 400,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Immortal Vampire", CharacterData.Affinity.CHAOS, 30, 80, 1200,
			CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE,
			{},
			"+50 ATK for each other face-up Chaos card on their own field. If it battles with Divine Character, destroy this card.",
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
			"At battle calculation, flip a coin, if head, +10 ATK",
			CharacterData.Rarity.RARE],

		["Kiyoko the Death Whisper", CharacterData.Affinity.ANIMA, 40, 35, 800,
			CharacterData.AbilityType.ATK_BONUS_VS_UNION,
			{"bonus": 50},
			"This card gain +50 ATK when attacking Union card",
			CharacterData.Rarity.LEGENDARY],

		["Lab Bloater", CharacterData.Affinity.BIO, 20, 85, 800,
			CharacterData.AbilityType.MUTAGEN_DESTROY_ATTACKER,
			{},
			"With Mutagen Flag, destroy the attacker after this card has been attacked. Also, the owner of this card does not pay Crystal Cost when it is destroyed.",
			CharacterData.Rarity.LEGENDARY],

		["Lab Crawler", CharacterData.Affinity.BIO, 90, 45, 1300,
			CharacterData.AbilityType.MUTAGEN_IMMEDIATE_ATTACK,
			{},
			"With Mutagen Flag, this card can attack twice",
			CharacterData.Rarity.EXOTIC],

		["Lab Zombie", CharacterData.Affinity.BIO, 55, 40, 700,
			CharacterData.AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES,
			{"bonus": 25, "affinities": [CharacterData.Affinity.NATURE, CharacterData.Affinity.ANIMA]},
			"With Mutagen Flag, this card gain +25 ATK against Nature or Anima Characters.",
			CharacterData.Rarity.RARE],

		["Laser Walker", CharacterData.Affinity.COSMIC, 20, 10, 250,
			CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS,
			{},
			"This card is not affected by 0 cost traps",
			CharacterData.Rarity.COMMON],

		["Laughing Granny", CharacterData.Affinity.CHAOS, 15, 20, 350,
			CharacterData.AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND,
			{"atk": 10, "def": 10},
			"Once when defending, +10 DEF until end of turn. Once when attacking, +10 ATK until end of turn",
			CharacterData.Rarity.UNCOMMON],

		["Lazy Troll", CharacterData.Affinity.NATURE, 120, 60, 900,
			CharacterData.AbilityType.COIN_FLIP_CANCEL_ATTACK,
			{},
			"If this card performs an attack, flip a coin, if tail, it stops attacking.",
			CharacterData.Rarity.EXOTIC],

		["Leech Man", CharacterData.Affinity.BIO, 60, 40, 850,
			CharacterData.AbilityType.PERM_DEF_BOOST_PER_ATTACK_SURVIVE,
			{"def": 20},
			"+20 DEF permanently each time it performed attack and survive",
			CharacterData.Rarity.LEGENDARY],

		["Leopard Jailer", CharacterData.Affinity.ANIMA, 30, 45, 450,
			CharacterData.AbilityType.LOCK_TARGET_ON_ATTACK,
			{},
			"If this card attacks a character card, the target is unable to attack until the end of their turn.",
			CharacterData.Rarity.UNCOMMON],

		["Leorudus the Warlord", CharacterData.Affinity.ANIMA, 80, 80, 1400,
			CharacterData.AbilityType.BOOST_PER_ANIMA_ON_FIELD,
			{"atk_bonus": 20, "def_bonus": 20},
			"+20 ATK and DEF for each other face-up Anima card on their own field",
			CharacterData.Rarity.EXOTIC],

		["Mad Raccoon", CharacterData.Affinity.NATURE, 30, 15, 260,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Mafia Associates", CharacterData.Affinity.ANIMA, 45, 40, 500,
			CharacterData.AbilityType.DEF_ZERO_WHEN_EXPOSED,
			{},
			"If this card is exposed, its defense becomes 0",
			CharacterData.Rarity.UNCOMMON],

		["Magenta the Nightbloom", CharacterData.Affinity.CHAOS, 25, 40, 300,
			CharacterData.AbilityType.HALVE_DEF_ON_FIRST_EXPOSE,
			{},
			"Half its DEF permanently when first revealed",
			CharacterData.Rarity.COMMON],

		["Magical Butterfly", CharacterData.Affinity.NATURE, 15, 15, 180,
			CharacterData.AbilityType.TEMP_BOOST_ON_OPP_TECH,
			{"atk": 10, "def": 10},
			"Whenever opponent’s tech card is activated, +10 ATK and DEF until the start of your next turn",
			CharacterData.Rarity.COMMON],

		["Mars Drill", CharacterData.Affinity.COSMIC, 40, 30, 400,
			CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS,
			{},
			"This card is not affected by 0 cost traps",
			CharacterData.Rarity.UNCOMMON],

		["Melissa the Healer", CharacterData.Affinity.DIVINE, 0, 25, 700,
			CharacterData.AbilityType.CRYSTAL_RECOVER_ON_BIG_LOSS,
			{"threshold": 500, "amount": 300},
			"If you lose 500 or more crystals, you recover 300 crystals",
			CharacterData.Rarity.COMMON],

		["Mephisto the Fallen", CharacterData.Affinity.DIVINE, 75, 0, 750,
			CharacterData.AbilityType.ATK_ZERO_AFTER_WIN,
			{},
			"After this card wins a battle, its ATK becomes 0 permanently",
			CharacterData.Rarity.RARE],

		["Mind Flayer", CharacterData.Affinity.ARCANE, 100, 70, 1200,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.ANIMA, "atk": 50, "def": 50},
			"+50 ATK and DEF against Anima",
			CharacterData.Rarity.EXOTIC],

		["Mine Guard", CharacterData.Affinity.COSMIC, 20, 15, 300,
			CharacterData.AbilityType.SACRIFICE_FOR_CARD_TYPE,
			{"name_contains": "Miner"},
			"If a Miner card will be destroyed, you can destroy this card instead.",
			CharacterData.Rarity.UNCOMMON],

		["Miner Probe", CharacterData.Affinity.COSMIC, 10, 10, 200,
			CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEAD_END_ATTACK,
			{"amount": 20},
			"If this card attacks a dead end card, you receive 20 crystals",
			CharacterData.Rarity.COMMON],

		["Moon Rover", CharacterData.Affinity.COSMIC, 15, 20, 200,
			CharacterData.AbilityType.REVEAL_ON_DEAD_END_ATTACK,
			{},
			"When this card attacks dead end, reveal 1 of your opponent’s cell",
			CharacterData.Rarity.COMMON],

		["Moon Tribe Marksman", CharacterData.Affinity.COSMIC, 35, 25, 300,
			CharacterData.AbilityType.ATK_PENALTY_IF_NO_NAME_ALLY,
			{"name_contains": "Moon", "penalty": 10},
			"If you do not control another Moon card, -10 ATK",
			CharacterData.Rarity.UNCOMMON],

		["Moon Tribe Twin Blades", CharacterData.Affinity.COSMIC, 30, 20, 300,
			CharacterData.AbilityType.COIN_FLIP_EXTRA_ATTACK,
			{},
			"If this card attacks, flip a coin. If head, this card can attack twice.",
			CharacterData.Rarity.UNCOMMON],

		["Moonrise Gentleman", CharacterData.Affinity.DIVINE, 40, 30, 400,
			CharacterData.AbilityType.DEFENSE_STANCE_BOOST,
			{"def": 10},
			"+10 DEF while performing defense.",
			CharacterData.Rarity.UNCOMMON],

		["Mysterious Miner", CharacterData.Affinity.CHAOS, 25, 15, 250,
			CharacterData.AbilityType.REVEAL_ON_WIN,
			{},
			"When it successfully attacked, reveal 1 cell on your opponent’s field",
			CharacterData.Rarity.UNCOMMON],

		["Needle Porcupine", CharacterData.Affinity.NATURE, 10, 10, 200,
			CharacterData.AbilityType.ONE_USE_PERM_DEBUFF_ATTACKER_ATK,
			{"atk": 5},
			"Once, when this card defends, the attacker permanently loses 5 ATK.",
			CharacterData.Rarity.COMMON],

		["Neptune Diver", CharacterData.Affinity.COSMIC, 20, 10, 200,
			CharacterData.AbilityType.REVEAL_ON_TRAP_ATTACK,
			{},
			"When this card attacks a trap, reveal 1 of your opponent’s cell",
			CharacterData.Rarity.COMMON],

		["Night Whisperer", CharacterData.Affinity.CHAOS, 30, 30, 900,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 30, "def_bonus": 30, "card_name_contains": "wisp"},
			"+30 ATK and DEF for each face-up ‘wisp’ card on their own field",
			CharacterData.Rarity.RARE],

		["Nuki the Tanuki", CharacterData.Affinity.NATURE, 10, 10, 100,
			CharacterData.AbilityType.COIN_FLIP_SWAP_POSITION,
			{},
			"At battle calculation, flip a coin, if head, swap this card’s position with any of character card on their own field",
			CharacterData.Rarity.COMMON],

		["Ostrich Cannon", CharacterData.Affinity.NATURE, 60, 30, 800,
			CharacterData.AbilityType.LOCK_SELF_AFTER_ATTACK,
			{},
			"This card cannot attack during your next turn.",
			CharacterData.Rarity.UNCOMMON],

		["Ox Patrol", CharacterData.Affinity.ANIMA, 35, 35, 420,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY,
			{"affinity": CharacterData.Affinity.ANIMA, "atk": 5, "def": 5},
			"+5 ATK and DEF vs Non-Anima",
			CharacterData.Rarity.UNCOMMON],

		["Parom the Smuggler", CharacterData.Affinity.COSMIC, 30, 20, 300,
			CharacterData.AbilityType.CRYSTAL_GAIN_ON_OPP_REVEAL,
			{"amount": 40},
			"Gain 40 crystals each time opponent’s grid is revealed",
			CharacterData.Rarity.UNCOMMON],

		["Pit Lord", CharacterData.Affinity.CHAOS, 120, 100, 1200,
			CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE,
			{},
			"his card is destroyed if battle with Divine Character. After this card attacked, halve its ATK and DEF permanently",
			CharacterData.Rarity.EXOTIC],

		["Plant 29", CharacterData.Affinity.BIO, 45, 75, 800,
			CharacterData.AbilityType.TURN_START_COIN_FLIP_FLAG,
			{},
			"At the start of your turn, a random face-up opponent card gets a venom flag (heads) or mutagen flag (tails).",
			CharacterData.Rarity.RARE],

		["Poltergeist", CharacterData.Affinity.CHAOS, 0, 70, 700,
			CharacterData.AbilityType.SWAP_ATK_DEF_WHEN_ATTACKING,
			{},
			"If this card performs an attack, switch this card’s ATK and DEF",
			CharacterData.Rarity.RARE],

		["Ponycorn", CharacterData.Affinity.DIVINE, 25, 20, 300,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Pyromancer", CharacterData.Affinity.ARCANE, 80, 0, 800,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.NATURE, "bonus": 30},
			"+30 ATK vs Nature Affinity",
			CharacterData.Rarity.LEGENDARY],

		["Raijin", CharacterData.Affinity.DIVINE, 60, 0, 550,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.RARE],

		["Red Mage", CharacterData.Affinity.ARCANE, 20, 20, 400,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.NATURE, "bonus": 10},
			"+10 ATK vs Nature",
			CharacterData.Rarity.COMMON],

		["Rotten Shrieker", CharacterData.Affinity.BIO, 50, 30, 450,
			CharacterData.AbilityType.PERM_ATK_LOSS_PER_OWN_TURN,
			{"amount": 10},
			"-10 ATK permanently at the end of your turn",
			CharacterData.Rarity.UNCOMMON],

		["Satellite Cannon", CharacterData.Affinity.COSMIC, 90, 80, 1100,
			CharacterData.AbilityType.ATK_BONUS_VS_CENTER_ZONE,
			{"bonus": 20, "center_bonus": 40},
			"+20 ATK if attacking the 3x3 center zone. +40 more ATK if attacking the very center cell.",
			CharacterData.Rarity.EXOTIC],

		["Saw Shark", CharacterData.Affinity.NATURE, 25, 10, 280,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 10, "def_bonus": 0, "card_name_contains": "shark"},
			"+10 ATK per shark card on the field",
			CharacterData.Rarity.COMMON],

		["Scarlet Mutant", CharacterData.Affinity.BIO, 35, 30, 350,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

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
			"After this card attacks, reveal 1 of your opponent’s cell",
			CharacterData.Rarity.UNCOMMON],

		["Shotgun Shark", CharacterData.Affinity.NATURE, 75, 25, 850,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 10, "def_bonus": 0, "card_name_contains": "shark"},
			"+10 ATK per shark card on the field",
			CharacterData.Rarity.RARE],

		["Shredder Doll", CharacterData.Affinity.CHAOS, 25, 5, 250,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.COMMON],

		["Silver Spearman", CharacterData.Affinity.ANIMA, 25, 20, 250,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS, "bonus": 5},
			"+5 ATK vs Chaos",
			CharacterData.Rarity.UNCOMMON],

		["Skeleton Archer", CharacterData.Affinity.CHAOS, 35, 5, 300,
			CharacterData.AbilityType.ATK_BONUS_VS_FACEDOWN,
			{"bonus": 5},
			"+5 ATK vs face-down Defender",
			CharacterData.Rarity.UNCOMMON],

		["Skeleton Grappler", CharacterData.Affinity.CHAOS, 20, 5, 150,
			CharacterData.AbilityType.LOCK_ATTACKER_ON_DESTROYED,
			{},
			"Character that destroyed this card cannot attack until the end of your opponent’s turn.",
			CharacterData.Rarity.COMMON],

		["Skeleton Lancer", CharacterData.Affinity.CHAOS, 45, 5, 300,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Skeleton Scout", CharacterData.Affinity.CHAOS, 20, 5, 150,
			CharacterData.AbilityType.ONE_USE_EXTRA_ATTACK_ON_DEAD_END,
			{},
			"Once, attack again if this card attacked dead end card",
			CharacterData.Rarity.COMMON],

		["Sniping Fairy", CharacterData.Affinity.DIVINE, 40, 20, 350,
			CharacterData.AbilityType.ATK_PENALTY_WHEN_EXPOSED,
			{"penalty": 20},
			"-20 ATK while face-up",
			CharacterData.Rarity.UNCOMMON],

		["Sonic Seraph", CharacterData.Affinity.DIVINE, 45, 50, 550,
			CharacterData.AbilityType.EXTRA_ATTACK_ON_DEAD_END,
			{},
			"Once per turn, if it attacked dead end card, it can attack again",
			CharacterData.Rarity.RARE],

		["Space Boy", CharacterData.Affinity.COSMIC, 75, 65, 750,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.RARE],

		["Spear Shark", CharacterData.Affinity.NATURE, 50, 20, 480,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 10, "def_bonus": 0, "card_name_contains": "shark"},
			"+10 ATK per shark card on the field",
			CharacterData.Rarity.UNCOMMON],

		["Staircase Lady", CharacterData.Affinity.CHAOS, 30, 0, 180,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Stinky Insect", CharacterData.Affinity.NATURE, 10, 10, 400,
			CharacterData.AbilityType.LOCK_ATTACKER_ON_DEFEND,
			{},
			"If this card defended, the attacker card cannot attack until end of their next turn.",
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
			CharacterData.Rarity.COMMON],

		["Succubus", CharacterData.Affinity.CHAOS, 10, 30, 400,
			CharacterData.AbilityType.ONE_USE_COPY_STATS_ON_SURVIVE,
			{},
			"Once, if this card survive battle, gain ATK and DEF equal to the card it battled",
			CharacterData.Rarity.COMMON],

		["Sunrise Lady", CharacterData.Affinity.DIVINE, 20, 25, 300,
			CharacterData.AbilityType.ATTACK_STANCE_BOOST,
			{"atk": 10},
			"+10 ATK and -10 DEF while performing attack.",
			CharacterData.Rarity.COMMON],

		["Swarmcaller", CharacterData.Affinity.NATURE, 45, 45, 900,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 15, "def_bonus": 15, "affinity": CharacterData.Affinity.NATURE},
			"+15 ATK and DEF for each other face-up Nature card on your field",
			CharacterData.Rarity.LEGENDARY],

		["Tiny Pixie", CharacterData.Affinity.DIVINE, 0, 0, 100,
			CharacterData.AbilityType.ONE_USE_SURVIVE_DESTRUCTION,
			{},
			"Once, this card is not destroyed",
			CharacterData.Rarity.COMMON],

		["Tomb Bandit", CharacterData.Affinity.ANIMA, 75, 60, 900,
			CharacterData.AbilityType.IMMUNE_TO_TRAPS,
			{},
			"This Character cannot be destroyed by Traps.",
			CharacterData.Rarity.LEGENDARY],

		["Vampire Duchess", CharacterData.Affinity.CHAOS, 50, 50, 800,
			CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE,
			{},
			"Destroy is card when battling with Divine card. At battle calculation, -5 ATK and DEF to the defender permanently. Also +ATK and DEF to this card permamently",
			CharacterData.Rarity.RARE],

		["Vampire Servant", CharacterData.Affinity.CHAOS, 20, 20, 500,
			CharacterData.AbilityType.SACRIFICE_FOR_CARD_TYPE,
			{"name_contains": "Vampire"},
			"If a 'Vampire' card will be destroyed, destroy this card instead. Can be triggered face-down.",
			CharacterData.Rarity.UNCOMMON],

		["Vile Creeper", CharacterData.Affinity.BIO, 10, 30, 200,
			CharacterData.AbilityType.SWAP_ATK_DEF_PER_OPP_TURN,
			{},
			"While this card is face-up, at the end of your opponent’s turn, swap its ATK and DEF",
			CharacterData.Rarity.COMMON],

		["Void Stalker", CharacterData.Affinity.CHAOS, 65, 25, 600,
			CharacterData.AbilityType.ATK_BOOST_VS_REVEALED,
			{"bonus": 20},
			"+20 ATK if it attack an exposed card",
			CharacterData.Rarity.RARE],

		["Wandering Swordsman", CharacterData.Affinity.ANIMA, 60, 60, 600,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.RARE],

		["War Genie", CharacterData.Affinity.ARCANE, 100, 80, 1000,
			CharacterData.AbilityType.PERM_ATK_LOSS_PER_ATTACK,
			{"amount": 10},
			"-10 ATK permanently after it attacked",
			CharacterData.Rarity.LEGENDARY],

		["White Tiger", CharacterData.Affinity.NATURE, 40, 25, 450,
			CharacterData.AbilityType.ATTACKER_ATK_DEBUFF,
			{"amount": 15},
			"At battle calculation, -15 ATK to the attacker",
			CharacterData.Rarity.UNCOMMON],

		["Witchhunter", CharacterData.Affinity.ANIMA, 20, 20, 250,
			CharacterData.AbilityType.ATK_DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.ARCANE, "atk": 5, "def": 5},
			"+5 ATK and DEF vs Arcane",
			CharacterData.Rarity.UNCOMMON],

		["Yaksa", CharacterData.Affinity.CHAOS, 30, 30, 500,
			CharacterData.AbilityType.NONE,
			{},
			"No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Aether Warden", CharacterData.Affinity.DIVINE, 30, 110, 950,
			CharacterData.AbilityType.DEFEND_DRAIN_ATTACKER,
			{"drain_amount": 300},
			"When this Character defends, attacker loses 300 Crystals.",
			CharacterData.Rarity.LEGENDARY],

		["Ancient Lich", CharacterData.Affinity.CHAOS, 60, 60, 900,
			CharacterData.AbilityType.IMMUNE_TO_TECH_CARDS, {},
			"Unaffected by Tech cards.",
			CharacterData.Rarity.LEGENDARY],

		["Champion of the Valley", CharacterData.Affinity.ANIMA, 50, 30, 400,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Death Stag", CharacterData.Affinity.NATURE, 50, 30, 400,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Ectoplasm", CharacterData.Affinity.BIO, 20, 0, 50,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Fierce Gladiator", CharacterData.Affinity.ANIMA, 70, 90, 1300,
			CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND,
			{"amount": 500},
			"+500 Crystal if successfully defends an attack.",
			CharacterData.Rarity.COMMON],

		["Giant Mosquito", CharacterData.Affinity.NATURE, 30, 20, 500,
			CharacterData.AbilityType.NONE, {},
			"When commanded to attack, receives half of the target's ATK.",
			CharacterData.Rarity.LEGENDARY],

		["Grand Wizard", CharacterData.Affinity.ARCANE, 90, 70, 1000,
			CharacterData.AbilityType.ATK_BONUS_IF_DICE_HIGH,
			{"threshold": 4, "bonus": 30},
			"+30 ATK if dice roll is 4 or more.",
			CharacterData.Rarity.UNCOMMON],

		["Horn Face", CharacterData.Affinity.COSMIC, 75, 60, 900,
			CharacterData.AbilityType.NONE, {},
			"Can make the opponent re-roll the dice once per turn.",
			CharacterData.Rarity.EXOTIC],

		["Hyperspeed Saucer", CharacterData.Affinity.COSMIC, 80, 40, 1000,
			CharacterData.AbilityType.PERM_BOOST_END_OF_TURN,
			{"atk": 10, "def": 10},
			"Permanently +10 ATK and DEF at the end of each of your turns.",
			CharacterData.Rarity.LEGENDARY],

		["Ironclad Sentinel", CharacterData.Affinity.ANIMA, 55, 95, 1100,
			CharacterData.AbilityType.IMMUNE_TO_TECH_DESTRUCTION, {},
			"Immune to 0-cost Traps. Cannot be destroyed by Tech Cards.",
			CharacterData.Rarity.COMMON],

		["Lightbringer", CharacterData.Affinity.DIVINE, 80, 40, 1000,
			CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS, "bonus": 100},
			"+100 DEF vs Chaos Affinity.",
			CharacterData.Rarity.UNCOMMON],

		["Mountain Sage", CharacterData.Affinity.ARCANE, 50, 30, 800,
			CharacterData.AbilityType.DOUBLE_TECH_EFFECT, {},
			"Double effect of Tech Cards applied to this character.",
			CharacterData.Rarity.COMMON],

		["Railgun Tank", CharacterData.Affinity.ANIMA, 150, 95, 1800,
			CharacterData.AbilityType.NONE, {},
			"Gains Railgun Flag when flipped face-up and cannot attack while flagged. Flag is removed at end of turn but reapplied after each attack.",
			CharacterData.Rarity.EXOTIC],

		["Slim Gray Trooper", CharacterData.Affinity.COSMIC, 50, 45, 700,
			CharacterData.AbilityType.NONE, {},
			"+30 ATK and DEF if 15 or more of your own squares are revealed.",
			CharacterData.Rarity.COMMON],
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
		characters[data.card_name] = data

# ────────────────────────────────────────────────────────────
# TRAP CARDS
# ────────────────────────────────────────────────────────────
func _load_traps() -> void:
	var defs: Array = [
		# Name, Cost, EffectType, Params, Description, Rarity
		["Acid Trap Hole", 0, TrapData.TrapEffectType.DRAIN_ATTACKER_CRYSTALS,
			{"amount": 50},
			"Attacking player loses 50 Crystals",
			CharacterData.Rarity.COMMON],

		["Alarm", 0, TrapData.TrapEffectType.FIELD_BOOST_AFFINITY_DEF,
			{"affinity": CharacterData.Affinity.ANIMA, "def": 5},
			"Unil the end of this urn, All face-up Anima monster gain +5 DEF",
			CharacterData.Rarity.COMMON],

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
			"The attacking player chooses their own ally as an attack target",
			CharacterData.Rarity.EXOTIC],

		["Bunker", 900, TrapData.TrapEffectType.NULLIFY_BLOCK_ADJACENT,
			{"directions": ["up","down","left","right"]},
			"Player cannot select adjacent cell as an attack target until the end of this turn.",
			CharacterData.Rarity.LEGENDARY],

		["Cursed Reflection", 500, TrapData.TrapEffectType.SWAP_ATTACKER_ATK_DEF_TEMP,
			{},
			"Swap the attacker's ATK and DEF until the end of this turn",
			CharacterData.Rarity.RARE],

		["Decoy Puppet", 500, TrapData.TrapEffectType.CANCEL_ATTACKER_ATTACK,
			{},
			"Can be triggered face-down. 1 attacker’s attack is cancelled",
			CharacterData.Rarity.UNCOMMON],

		["Defensive Pheromone", 500, TrapData.TrapEffectType.SWAP_ARMORED_NATURE,
			{},
			"Select 1 'Armored' Nature card and switch it with this cell",
			CharacterData.Rarity.RARE],

		["Echo Barrier", 1500, TrapData.TrapEffectType.LOCK_ATTACKER_REMAINING_ATTACKS,
			{},
			"All attacker’s characters cannot attack until the end of this turn",
			CharacterData.Rarity.RARE],

		["Explosive Barrels", 0, TrapData.TrapEffectType.DESTROY_ATTACKER_DEFENDER_PAYS,
			{},
			"Destroy the attacking character. Defending player also lose crystal equal to the attacking monster's cost.",
			CharacterData.Rarity.EXOTIC],

		["Flame Trap", 250, TrapData.TrapEffectType.PERMANENT_ATK_DEBUFF,
			{"amount": 10},
			"Permanently -10 ATK to the Attacking character",
			CharacterData.Rarity.UNCOMMON],

		["Foul Gas", 0, TrapData.TrapEffectType.TEMP_DEBUFF_ALL_ATTACKER_CHARS,
			{"amount": 5},
			"-5 ATK to all the attacking player’s characters until the end of this turn",
			CharacterData.Rarity.RARE],

		["Hard Scale", 700, TrapData.TrapEffectType.TEMP_DEF_BOOST_ONE_OWN,
			{"def": 5},
			"Can be triggered face-down. +5 DEF to 1 of your card until the end of this turn",
			CharacterData.Rarity.COMMON],

		["Hostage", 0, TrapData.TrapEffectType.NULLIFY_ATTACK_REVEAL_ADJACENT,
			{"directions": ["up","down","left","right"], "lock_revealed": true},
			"Reveal all adjacent cells. Until the end of this turn, these square cannot be selected as attack target until the end of this turn",
			CharacterData.Rarity.UNCOMMON],

		["Hypnosis", 800, TrapData.TrapEffectType.HYPNOTIZE_ATTACKER,
			{},
			"The attacking character cannot attack during their next turn",
			CharacterData.Rarity.LEGENDARY],

		["Pepper Spray", 0, TrapData.TrapEffectType.COIN_FLIP_2_ATK_DEBUFF,
			{"amount": 5},
			"Flip 2 coin, if head, the attacking character lose -5 ATK until the end of their next turn.",
			CharacterData.Rarity.COMMON],

		["Red Card", 0, TrapData.TrapEffectType.COIN_FLIP_2_LOCK_ATTACKER,
			{},
			"Flip 2 coin, if head, that character cannot attack next turn",
			CharacterData.Rarity.UNCOMMON],

		["Self-destruct", 0, TrapData.TrapEffectType.SELF_DESTROY_TEMP_ATK_BOOST,
			{"atk": 10},
			"Select 1 of your character card. Until the end of next turn, that card gain +10 ATK, but destroy it at the end of next turn. You do not lose crystal from card destroyed under this effect",
			CharacterData.Rarity.UNCOMMON],

		["Snare Trap", 500, TrapData.TrapEffectType.NULLIFY_ATTACKER_EFFECT,
			{},
			"The attacker's effect becomes None until the end of their next turn",
			CharacterData.Rarity.LEGENDARY],

		["Spike Trap", 1500, TrapData.TrapEffectType.DESTROY_ATTACKER,
			{},
			"Destroy the attacking character",
			CharacterData.Rarity.EXOTIC],

		["Street Joke", 0, TrapData.TrapEffectType.REVEAL_OWN_GAIN_CRYSTAL,
			{"amount": 100},
			"Reveal 1 of your cell, you receive 100 crystal",
			CharacterData.Rarity.COMMON],

		["Trap Hole", 0, TrapData.TrapEffectType.DRAIN_ATTACKER_CRYSTALS,
			{"amount": 20},
			"Attacking player loses 20 Crystals",
			CharacterData.Rarity.COMMON],

		["Checkpoint", 0, TrapData.TrapEffectType.NULLIFY_ATTACK_CHOICE,
			{"crystal_loss": 500},
			"Attacker chooses: lose 500 Crystals OR destroy own attacking character.",
			CharacterData.Rarity.COMMON],

		["Mana Drain", 500, TrapData.TrapEffectType.DRAIN_ATTACKER_CRYSTALS,
			{"amount": 800},
			"Attacking player loses 800 Crystals.",
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
			"Destroy 1 face-up card. If there is no face-up card, the opponent chooses the target by themselves. The owner of that card does not lose Crystal for the destroyed card.",
			CharacterData.Rarity.RARE],

		["Bribe", 0, TechCardData.TechEffectType.OPPONENT_REVEALS_OR_GAINS,
			{"crystal_reward": 700}, "",
			"Your opponent can choose to reveal a creature and receive 700 Crystals or do nothing",
			CharacterData.Rarity.RARE],

		["Great Diplomacy", 1000, TechCardData.TechEffectType.REVEAL_ALL_OWN_CHARACTERS,
			{}, "",
			"Turn all characters on your field face up",
			CharacterData.Rarity.LEGENDARY],

		["Prayer", 0, TechCardData.TechEffectType.DIVINE_PROTECTION,
			{}, "",
			"Until your opponent’s turn end, once, if a Divine Character on your side of the field will get destroyed, it is not destroyed.",
			CharacterData.Rarity.LEGENDARY],

		["Radar", 600, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE,
			{"count": 3}, "",
			"Reveal 3 square on opponent's side of the field",
			CharacterData.Rarity.COMMON],

		["Release Mutagen", 0, TechCardData.TechEffectType.ADD_MUTAGEN_FLAG,
			{}, "",
			"Select and reveal (if face-down) 1 of your Bio Character on the field. Add Mutagen Flag to it.",
			CharacterData.Rarity.LEGENDARY],

		["Resurrection", 1500, TechCardData.TechEffectType.REVIVE_CHARACTER_NO_ATK,
			{}, "",
			"Once only, revive 1 character to any unoccupied or empty cell in face-up position. The ability is None and the attack becomes 0",
			CharacterData.Rarity.LEGENDARY],

		["Siege Cannon", 1000, TechCardData.TechEffectType.OPPONENT_NEXT_DEFENDER_DESTROYED,
			{}, "",
			"Until the end of this turn, once, the opponent’s defending character is destroyed.",
			CharacterData.Rarity.EXOTIC],

		["Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE,
			{"count": 1}, "",
			"Choose and reveal 1 square on opponent's side of the field",
			CharacterData.Rarity.COMMON],

		["Tease", 0, TechCardData.TechEffectType.OPPONENT_REVEALS_SQUARE,
			{}, "",
			"Your opponent choose and reveal 1 of their square",
			CharacterData.Rarity.UNCOMMON],

		["War Supply", 800, TechCardData.TechEffectType.NOT_IMPLEMENTED,
			{}, "",
			"+10 ATK and DEF for all face up characters until the end of this turn.",
			CharacterData.Rarity.RARE],

		["Arcane Duplication", 1200, TechCardData.TechEffectType.CLONE_CHARACTER_AS_TOKEN,
			{}, "",
			"Choose 1 face-up Character. Create a token copy on an empty square (same ATK/DEF/Affinity, no ability, 0 Crystals if destroyed).",
			CharacterData.Rarity.COMMON],

		["Arcane Nova", 2000, TechCardData.TechEffectType.DESTROY_ALL_REVEALED_OPPONENT,
			{}, "",
			"Destroy all revealed opponent Characters. Discard all of your Tech afterward.",
			CharacterData.Rarity.LEGENDARY],

		["Berserk", 1500, TechCardData.TechEffectType.MULTI_ATTACK_ONE,
			{}, "",
			"Select 1 face-up character. Until end of next turn, that character can attack multiple times. You can't command any other character to attack.",
			CharacterData.Rarity.EXOTIC],

		["Blood Ritual", 1800, TechCardData.TechEffectType.DESTROY_OWN_BASE_ZERO_OPPONENT,
			{}, "",
			"Destroy 1 face-up card on your field (no crystal cost). Set base ATK and DEF of 1 opponent's character to 0 permanently.",
			CharacterData.Rarity.LEGENDARY],

		["Bulletproof Vest", 400, TechCardData.TechEffectType.PERM_DEF_BOOST_ONE,
			{"def": 40}, "",
			"+40 DEF permanently for 1 face-up character.",
			CharacterData.Rarity.COMMON],

		["Ceasefire", 0, TechCardData.TechEffectType.BOTH_SKIP_TURN,
			{}, "",
			"Both you and your opponent skip 1 turn.",
			CharacterData.Rarity.COMMON],

		["Corrupted Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_RISKY,
			{"count": 3, "cost_per_card": 700}, "",
			"Reveal 3 squares on opponent's field. Pay 700 Crystals for each Trap or Character found.",
			CharacterData.Rarity.COMMON],

		["Diplomacy Party", 500, TechCardData.TechEffectType.REVEAL_OWN_AND_OPPONENT_REVEALS,
			{}, "",
			"Reveal 1 of your face-down characters. Opponent must reveal 1 of their face-down characters (if any).",
			CharacterData.Rarity.COMMON],

		["Double Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN,
			{"count": 2}, "Spy",
			"Only triggers if Spy was used this game. Reveal 2 squares on opponent's field.",
			CharacterData.Rarity.RARE],

		["Essence Transfer", 700, TechCardData.TechEffectType.MOVE_BUFFS_BETWEEN_CHARACTERS,
			{}, "",
			"Move all ATK and DEF bonuses from 1 face-up Character to another face-up Character on your field.",
			CharacterData.Rarity.COMMON],

		["Force Shield", 600, TechCardData.TechEffectType.FORCE_SHIELD_ONE_CARD,
			{}, "",
			"Select 1 card on your field. It is not destroyed until the end of your opponent's turn.",
			CharacterData.Rarity.UNCOMMON],

		["Garrison", 400, TechCardData.TechEffectType.TEMP_DEF_BOOST_ALL,
			{"def": 50}, "",
			"+50 DEF until end of next turn for all characters on your field.",
			CharacterData.Rarity.COMMON],

		["Guerrilla Tactics", 500, TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW,
			{"atk": 5}, "",
			"+5 ATK for 1 character until end of this turn. Command that creature to attack after effect resolves.",
			CharacterData.Rarity.COMMON],

		["Harsh Training", 500, TechCardData.TechEffectType.PERM_ATK_BOOST_ONE,
			{"atk": 50}, "",
			"+50 ATK permanently for 1 face-up character.",
			CharacterData.Rarity.COMMON],

		["Hitman", 1000, TechCardData.TechEffectType.DESTROY_FACEUP_CARD,
			{}, "",
			"Destroy 1 face-up card.",
			CharacterData.Rarity.LEGENDARY],

		["Illegal Steroid", 2000, TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW,
			{"atk": 50}, "",
			"+50 ATK for 1 character until end of this turn. Command that creature to attack after effect resolves.",
			CharacterData.Rarity.COMMON],

		["Invisible Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN,
			{"count": 3}, "Double Spy",
			"Only triggers if Double Spy was used this game. Reveal 3 squares on opponent's field.",
			CharacterData.Rarity.LEGENDARY],

		["Lucky Day", 500, TechCardData.TechEffectType.TEMP_REROLL_DICE,
			{}, "",
			"Until the end of your next turn, you may re-roll the dice once.",
			CharacterData.Rarity.UNCOMMON],

		["Make Friend", 0, TechCardData.TechEffectType.BOTH_LOCK_CHOSEN_MONSTER,
			{}, "",
			"Both players select 1 monster from own field. Those monsters cannot attack until end of your next turn.",
			CharacterData.Rarity.UNCOMMON],

		["Rift Strike", 1500, TechCardData.TechEffectType.DESTROY_ROW_OR_COLUMN,
			{}, "",
			"Destroy all revealed cards in one row or column.",
			CharacterData.Rarity.COMMON],

		["Tech Copy", 1000, TechCardData.TechEffectType.VIEW_OPPONENT_TECH,
			{}, "",
			"Select 1 Tech Card in your opponent's hand. View it.",
			CharacterData.Rarity.COMMON],

		["Time Travel", 2000, TechCardData.TechEffectType.REVIVE_CHARACTER_FULL,
			{}, "",
			"Once only: Revive 1 destroyed character to any unoccupied or blank square, face-up.",
			CharacterData.Rarity.EXOTIC],

		["Wisp Light", 500, TechCardData.TechEffectType.DESTROY_WISPS_REVEAL_OPPONENT,
			{}, "",
			"Destroy as many Wisps on your side of the field as you can. Reveal that many squares on opponent's field.",
			CharacterData.Rarity.UNCOMMON],
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
		if not u.include_in_demo:
			flags[u.card_name] = false
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
	if _art_cache.has(key):
		return _art_cache[key]

	var dir_path: String = "res://assets/textures/cards/%s/" % subfolder
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

	_art_cache[key] = ""
	return ""
