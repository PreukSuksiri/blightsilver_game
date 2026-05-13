extends Node

# All card definitions loaded at startup
var characters: Dictionary = {}  # name -> CharacterData
var traps: Dictionary = {}       # name -> TrapData
var tech_cards: Dictionary = {}  # name -> TechCardData


func _ready() -> void:
	_load_characters()
	_load_traps()
	_load_tech_cards()

# ─────────────────────────────────────────────────────────────
# CHARACTER CARDS
# ─────────────────────────────────────────────────────────────
func _load_characters() -> void:
	var defs: Array = [
		# Name, Affinity, ATK, DEF, Cost, AbilityType, Params, Description, Rarity
		["Pyromancer", CharacterData.Affinity.ARCANE, 80, 0, 800,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.NATURE, "bonus": 30},
			"+30 ATK vs Nature Affinity",
			CharacterData.Rarity.RARE],

		["Angel Gatekeeper", CharacterData.Affinity.DIVINE, 40, 90, 1000,
			CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS, "bonus": 60},
			"+60 ATK vs Chaos Affinity",
			CharacterData.Rarity.COMMON],

		["Wandering Swordsman", CharacterData.Affinity.ANIMA, 60, 60, 600,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Huntress of Green Glade", CharacterData.Affinity.ANIMA, 50, 50, 800,
			CharacterData.AbilityType.IMMUNE_ZERO_COST_TRAPS, {},
			"Immune to 0-cost Traps.",
			CharacterData.Rarity.RARE],

		["Fierce Gladiator", CharacterData.Affinity.ANIMA, 70, 90, 1300,
			CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND,
			{"amount": 500},
			"+500 Crystal if successfully defends an attack.",
			CharacterData.Rarity.COMMON],

		["Canyon Warg", CharacterData.Affinity.NATURE, 70, 30, 500,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Armored Rhino", CharacterData.Affinity.NATURE, 60, 85, 700,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Armored Bee", CharacterData.Affinity.NATURE, 30, 0, 350,
			CharacterData.AbilityType.ONE_USE_DEF_BOOST,
			{"bonus": 40},
			"+40 DEF once (one-time).",
			CharacterData.Rarity.UNCOMMON],

		["Lightbringer", CharacterData.Affinity.DIVINE, 80, 40, 1000,
			CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY,
			{"affinity": CharacterData.Affinity.CHAOS, "bonus": 100},
			"+100 DEF vs Chaos Affinity.",
			CharacterData.Rarity.UNCOMMON],

		["Chaotic Wisp", CharacterData.Affinity.CHAOS, 20, 0, 100,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Foul Wisp", CharacterData.Affinity.CHAOS, 0, 20, 100,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Doom Wisp", CharacterData.Affinity.CHAOS, 15, 15, 100,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Night Whisperer", CharacterData.Affinity.CHAOS, 50, 50, 1500,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 30, "def_bonus": 30, "card_name_contains": "wisp"},
			"+30 ATK and DEF for each 'wisp' card on own field.",
			CharacterData.Rarity.COMMON],

		["Leorudus the Warlord", CharacterData.Affinity.ANIMA, 80, 80, 1500,
			CharacterData.AbilityType.BOOST_PER_ANIMA_ON_FIELD,
			{"atk_bonus": 20, "def_bonus": 20},
			"+20 ATK and DEF for each face-up Anima card on own field.",
			CharacterData.Rarity.COMMON],

		["Aether Warden", CharacterData.Affinity.DIVINE, 30, 110, 950,
			CharacterData.AbilityType.DEFEND_DRAIN_ATTACKER,
			{"drain_amount": 300},
			"When this Character defends, attacker loses 300 Crystals.",
			CharacterData.Rarity.LEGENDARY],

		["Void Stalker", CharacterData.Affinity.CHAOS, 65, 25, 650,
			CharacterData.AbilityType.ATK_BOOST_VS_REVEALED,
			{"bonus": 20},
			"Once per turn, gains +20 ATK when attacking a revealed card.",
			CharacterData.Rarity.COMMON],

		["Swarmcaller", CharacterData.Affinity.NATURE, 45, 45, 900,
			CharacterData.AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD,
			{"atk_bonus": 15, "def_bonus": 15, "affinity": CharacterData.Affinity.NATURE},
			"+15 ATK and DEF for each other Nature Character on your field.",
			CharacterData.Rarity.COMMON],

		["Ironclad Sentinel", CharacterData.Affinity.ANIMA, 55, 95, 1100,
			CharacterData.AbilityType.IMMUNE_TO_TECH_DESTRUCTION, {},
			"Immune to 0-cost Traps. Cannot be destroyed by Tech Cards.",
			CharacterData.Rarity.COMMON],

		["Tomb Bandit", CharacterData.Affinity.ANIMA, 75, 60, 1200,
			CharacterData.AbilityType.IMMUNE_TO_TRAPS, {},
			"Cannot be destroyed by Traps.",
			CharacterData.Rarity.COMMON],

		["Scout Probe", CharacterData.Affinity.COSMIC, 40, 50, 700,
			CharacterData.AbilityType.REVEAL_ADJACENT_AFTER_ATTACK, {},
			"Choose and reveal any adjacent square after it attacked.",
			CharacterData.Rarity.COMMON],

		["Lab Zombie", CharacterData.Affinity.BIO, 55, 40, 850,
			CharacterData.AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES,
			{"bonus": 55, "affinities": [CharacterData.Affinity.NATURE, CharacterData.Affinity.ANIMA]},
			"With Mutagen Flag: +55 ATK against Nature or Anima Characters.",
			CharacterData.Rarity.UNCOMMON],

		["Lab Bloater", CharacterData.Affinity.BIO, 20, 85, 800,
			CharacterData.AbilityType.MUTAGEN_DESTROY_ATTACKER, {},
			"With Mutagen Flag: Destroy attacker if attacked; no Crystal Cost when destroyed.",
			CharacterData.Rarity.UNCOMMON],

		["Lab Crawler", CharacterData.Affinity.BIO, 80, 45, 1200,
			CharacterData.AbilityType.MUTAGEN_IMMEDIATE_ATTACK, {},
			"With Mutagen Flag: Can attack immediately once after obtaining flag.",
			CharacterData.Rarity.LEGENDARY],

		["Pit Lord", CharacterData.Affinity.CHAOS, 120, 100, 1550,
			CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE,
			{"also_halve_after_attack": true},
			"Destroyed if battling Divine. After attacking, ATK and DEF are halved permanently.",
			CharacterData.Rarity.EXOTIC],

		["Ancient Lich", CharacterData.Affinity.CHAOS, 60, 60, 900,
			CharacterData.AbilityType.IMMUNE_TO_TECH_CARDS, {},
			"Unaffected by Tech cards.",
			CharacterData.Rarity.LEGENDARY],

		["Hyperspeed Saucer", CharacterData.Affinity.COSMIC, 80, 40, 1000,
			CharacterData.AbilityType.PERM_BOOST_END_OF_TURN,
			{"atk": 10, "def": 10},
			"Permanently +10 ATK and DEF at the end of each of your turns.",
			CharacterData.Rarity.LEGENDARY],

		["Mountain Sage", CharacterData.Affinity.ARCANE, 50, 30, 800,
			CharacterData.AbilityType.DOUBLE_TECH_EFFECT, {},
			"Double effect of Tech Cards applied to this character.",
			CharacterData.Rarity.COMMON],

		["War Genie", CharacterData.Affinity.ARCANE, 100, 80, 1200,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.RARE],

		["Grand Wizard", CharacterData.Affinity.ARCANE, 90, 70, 1000,
			CharacterData.AbilityType.ATK_BONUS_IF_DICE_HIGH,
			{"threshold": 4, "bonus": 30},
			"+30 ATK if dice roll is 4 or more.",
			CharacterData.Rarity.UNCOMMON],

		["Archbishop", CharacterData.Affinity.DIVINE, 70, 90, 1200,
			CharacterData.AbilityType.REDIRECT_DESTRUCTION_TO_ALLY,
			{"affinity": CharacterData.Affinity.DIVINE},
			"If this card would be destroyed, you can destroy 1 other Divine Character instead.",
			CharacterData.Rarity.COMMON],

		["Space Boy", CharacterData.Affinity.COSMIC, 75, 75, 850,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.UNCOMMON],

		["Slim Gray Trooper", CharacterData.Affinity.COSMIC, 50, 45, 700,
			CharacterData.AbilityType.NONE, {},
			"+30 ATK and DEF if 15 or more of your own squares are revealed.",
			CharacterData.Rarity.COMMON],

		["Horn Face", CharacterData.Affinity.COSMIC, 75, 60, 900,
			CharacterData.AbilityType.NONE, {},
			"Can make the opponent re-roll the dice once per turn.",
			CharacterData.Rarity.EXOTIC],

		["Railgun Tank", CharacterData.Affinity.ANIMA, 150, 95, 1800,
			CharacterData.AbilityType.NONE, {},
			"Gains Railgun Flag when flipped face-up and cannot attack while flagged. Flag is removed at end of turn but reapplied after each attack.",
			CharacterData.Rarity.EXOTIC],

		["Lazy Troll", CharacterData.Affinity.NATURE, 120, 60, 950,
			CharacterData.AbilityType.NONE, {},
			"Can only attack if the player rolls 2 or 4 on the dice.",
			CharacterData.Rarity.EXOTIC],

		["Leech Man", CharacterData.Affinity.CHAOS, 60, 40, 700,
			CharacterData.AbilityType.NONE, {},
			"+20 DEF permanently each time this card attacks.",
			CharacterData.Rarity.RARE],

		["Immortal Vampire", CharacterData.Affinity.CHAOS, 30, 80, 800,
			CharacterData.AbilityType.DESTROYED_IF_BATTLES_DIVINE,
			{"if_chaos_ally_atk_bonus": 50},
			"Destroyed if battling a Divine character. Gains +50 ATK while another Chaos character is on the field.",
			CharacterData.Rarity.LEGENDARY],

		["Vampire Servant", CharacterData.Affinity.CHAOS, 20, 20, 800,
			CharacterData.AbilityType.NONE, {},
			"If a 'Vampire' card would be destroyed, this card is destroyed instead.",
			CharacterData.Rarity.RARE],

		["Bat Swarm", CharacterData.Affinity.CHAOS, 20, 20, 800,
			CharacterData.AbilityType.NONE, {},
			"If a Chaos card is being attacked, you can flip this card face-up and swap positions with that card.",
			CharacterData.Rarity.COMMON],

		["Poltergeist", CharacterData.Affinity.CHAOS, 0, 70, 350,
			CharacterData.AbilityType.NONE, {},
			"When commanded to attack, swap ATK and DEF until end of this turn.",
			CharacterData.Rarity.UNCOMMON],

		["Giant Mosquito", CharacterData.Affinity.NATURE, 30, 20, 500,
			CharacterData.AbilityType.NONE, {},
			"When commanded to attack, receives half of the target's ATK.",
			CharacterData.Rarity.LEGENDARY],

		["Street Rogue", CharacterData.Affinity.ANIMA, 25, 20, 200,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Big Thug", CharacterData.Affinity.ANIMA, 40, 40, 400,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Goblin Poacher", CharacterData.Affinity.NATURE, 30, 25, 280,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Ectoplasm", CharacterData.Affinity.BIO, 20, 0, 50,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Death Stag", CharacterData.Affinity.NATURE, 50, 30, 400,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Champion of the Valley", CharacterData.Affinity.ANIMA, 50, 30, 400,
			CharacterData.AbilityType.NONE, {}, "No ability.",
			CharacterData.Rarity.COMMON],

		["Magenta the Nightbloom", CharacterData.Affinity.CHAOS, 50, 30, 400,
			CharacterData.AbilityType.NONE, {}, "No ability.",
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

# ─────────────────────────────────────────────────────────────
# TRAP CARDS
# ─────────────────────────────────────────────────────────────
func _load_traps() -> void:
	var defs: Array = [
		# Name, Cost, EffectType, Params, Description, Rarity
		["Trap Hole", 0, TrapData.TrapEffectType.NULLIFY_ATTACK_ATK_DEBUFF,
			{"atk_debuff": 5},
			"Attack does nothing. All attackers get -5 ATK until end of this turn.",
			CharacterData.Rarity.UNCOMMON],

		["Hostage", 0, TrapData.TrapEffectType.NULLIFY_ATTACK_REVEAL_ADJACENT,
			{"directions": ["up", "down", "left", "right"], "lock_revealed": true},
			"Attack does nothing. Reveal all adjacent squares; they cannot be targeted this turn.",
			CharacterData.Rarity.UNCOMMON],

		["Checkpoint", 0, TrapData.TrapEffectType.NULLIFY_ATTACK_CHOICE,
			{"crystal_loss": 500},
			"Attacker chooses: lose 500 Crystals OR destroy own attacking character.",
			CharacterData.Rarity.COMMON],

		["Bait", 0, TrapData.TrapEffectType.REVEAL_DEFENDING_CHOICE,
			{},
			"Defending player chooses any square on their field and reveals it.",
			CharacterData.Rarity.COMMON],

		["Blackmail", 0, TrapData.TrapEffectType.ATTACKER_DISCARD_OR_END_TURN,
			{},
			"Attacker chooses: discard 1 Tech Card OR end the turn immediately.",
			CharacterData.Rarity.COMMON],

		["Cursed Reflection", 0, TrapData.TrapEffectType.COPY_ATTACKER_EFFECT,
			{},
			"Attack does nothing. Copy attacking character's effect onto one of your face-up characters until end of next turn.",
			CharacterData.Rarity.UNCOMMON],

		["Explosive Barrels", 400, TrapData.TrapEffectType.DESTROY_ATTACKER_CHOICE_DESTROY,
			{"requires_faceup_defender": true},
			"Only triggers if there is at least 1 face-up defending character. Destroy attacker; attacker chooses 1 of your revealed to destroy (no crystal loss).",
			CharacterData.Rarity.EXOTIC],

		["Hypnosis", 800, TrapData.TrapEffectType.HYPNOTIZE_ATTACKER,
			{},
			"Attacker cannot attack until end of next turn.",
			CharacterData.Rarity.LEGENDARY],

		["Flame Trap", 1000, TrapData.TrapEffectType.DESTROY_ATTACKER,
			{},
			"Destroy the attacking character.",
			CharacterData.Rarity.COMMON],

		["Echo Barrier", 800, TrapData.TrapEffectType.LOCK_ATTACKER_REMAINING_ATTACKS,
			{},
			"Attacking player cannot attack again this turn.",
			CharacterData.Rarity.COMMON],

		["Mana Drain", 500, TrapData.TrapEffectType.DRAIN_ATTACKER_CRYSTALS,
			{"amount": 800},
			"Attacking player loses 800 Crystals.",
			CharacterData.Rarity.COMMON],

		["Defensive Pheromone", 500, TrapData.TrapEffectType.SWAP_ARMORED_NATURE,
			{},
			"Select 1 'Armored' Nature card and switch it with this square.",
			CharacterData.Rarity.RARE],

		["Spike Trap", 200, TrapData.TrapEffectType.PERMANENT_ATK_DEBUFF,
			{"amount": 10},
			"Permanently -10 ATK to the attacking character.",
			CharacterData.Rarity.COMMON],

		["Snare Trap", 200, TrapData.TrapEffectType.NULLIFY_ATTACKER_EFFECT,
			{},
			"Attacker's effect becomes None until end of their next turn.",
			CharacterData.Rarity.COMMON],

		["Brainwash", 1000, TrapData.TrapEffectType.FORCE_FRIENDLY_FIRE,
			{},
			"Attacker must choose their own ally as an attack target.",
			CharacterData.Rarity.LEGENDARY],

		["Bunker", 500, TrapData.TrapEffectType.NULLIFY_BLOCK_ADJACENT,
			{"directions": ["up", "down", "left", "right"]},
			"Attack does nothing. Adjacent squares cannot be targeted until end of this turn.",
			CharacterData.Rarity.EXOTIC],
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

# ─────────────────────────────────────────────────────────────
# TECH CARDS
# ─────────────────────────────────────────────────────────────
func _load_tech_cards() -> void:
	var defs: Array = [
		# Name, Cost, EffectType, Params, RequiredPrior, Description, Rarity
		["Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE,
			{"count": 1}, "",
			"Choose and reveal 1 square on opponent's field.",
			CharacterData.Rarity.COMMON],

		["Ceasefire", 0, TechCardData.TechEffectType.BOTH_SKIP_TURN,
			{}, "",
			"Both you and your opponent skip 1 turn.",
			CharacterData.Rarity.COMMON],

		["Make Friend", 0, TechCardData.TechEffectType.BOTH_LOCK_CHOSEN_MONSTER,
			{}, "",
			"Both players select 1 monster from own field. Those monsters cannot attack until end of your next turn.",
			CharacterData.Rarity.UNCOMMON],

		["Double Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN,
			{"count": 2}, "Spy",
			"Only triggers if Spy was used this game. Reveal 2 squares on opponent's field.",
			CharacterData.Rarity.RARE],

		["Invisible Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_CHAIN,
			{"count": 3}, "Double Spy",
			"Only triggers if Double Spy was used this game. Reveal 3 squares on opponent's field.",
			CharacterData.Rarity.LEGENDARY],

		["Corrupted Spy", 0, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE_RISKY,
			{"count": 3, "cost_per_card": 700}, "",
			"Reveal 3 squares on opponent's field. Pay 700 Crystals for each Trap or Character found.",
			CharacterData.Rarity.COMMON],

		["Tease", 0, TechCardData.TechEffectType.OPPONENT_REVEALS_SQUARE,
			{}, "",
			"Your opponent chooses and reveals 1 of their squares.",
			CharacterData.Rarity.COMMON],

		["Bribe", 0, TechCardData.TechEffectType.OPPONENT_REVEALS_OR_GAINS,
			{"crystal_reward": 700}, "",
			"Opponent can reveal a creature and receive 700 Crystals, or do nothing.",
			CharacterData.Rarity.RARE],

		["Release Mutagen", 0, TechCardData.TechEffectType.ADD_MUTAGEN_FLAG,
			{}, "",
			"Select and reveal (if face-down) 1 of your Bio Characters. Add Mutagen Flag to it.",
			CharacterData.Rarity.UNCOMMON],

		["Prayer", 0, TechCardData.TechEffectType.DIVINE_PROTECTION,
			{}, "",
			"Until your next turn, if a Divine Character on your field would be destroyed, it is not (triggers once).",
			CharacterData.Rarity.RARE],

		["Arcane Nova", 2000, TechCardData.TechEffectType.DESTROY_ALL_REVEALED_OPPONENT,
			{}, "",
			"Destroy all revealed opponent Characters. Discard all of your Tech afterward.",
			CharacterData.Rarity.LEGENDARY],

		["Rift Strike", 1500, TechCardData.TechEffectType.DESTROY_ROW_OR_COLUMN,
			{}, "",
			"Destroy all revealed cards in one row or column.",
			CharacterData.Rarity.COMMON],

		["Great Diplomacy", 500, TechCardData.TechEffectType.REVEAL_ALL_OWN_CHARACTERS,
			{}, "",
			"Turn all characters on your field face up.",
			CharacterData.Rarity.RARE],

		["War Supply", 700, TechCardData.TechEffectType.PERM_BOOST_ALL_FACEUP,
			{"atk": 20, "def": 20}, "",
			"+20 ATK and DEF permanently for all face-up characters.",
			CharacterData.Rarity.COMMON],

		["Harsh Training", 500, TechCardData.TechEffectType.PERM_ATK_BOOST_ONE,
			{"atk": 50}, "",
			"+50 ATK permanently for 1 face-up character.",
			CharacterData.Rarity.COMMON],

		["Illegal Steroid", 2000, TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW,
			{"atk": 50}, "",
			"+50 ATK for 1 character until end of this turn. Command that creature to attack after effect resolves.",
			CharacterData.Rarity.COMMON],

		["Guerrilla Tactics", 500, TechCardData.TechEffectType.TEMP_ATK_BOOST_ATTACK_NOW,
			{"atk": 5}, "",
			"+5 ATK for 1 character until end of this turn. Command that creature to attack after effect resolves.",
			CharacterData.Rarity.COMMON],

		["Garrison", 400, TechCardData.TechEffectType.TEMP_DEF_BOOST_ALL,
			{"def": 50}, "",
			"+50 DEF until end of next turn for all characters on your field.",
			CharacterData.Rarity.COMMON],

		["Bulletproof Vest", 400, TechCardData.TechEffectType.PERM_DEF_BOOST_ONE,
			{"def": 40}, "",
			"+40 DEF permanently for 1 face-up character.",
			CharacterData.Rarity.COMMON],

		["Siege Cannon", 500, TechCardData.TechEffectType.OPPONENT_NEXT_DEFENDER_DESTROYED,
			{}, "",
			"Until end of next turn, opponent's defending character is destroyed (resolves once).",
			CharacterData.Rarity.COMMON],

		["Hitman", 1000, TechCardData.TechEffectType.DESTROY_FACEUP_CARD,
			{}, "",
			"Destroy 1 face-up card.",
			CharacterData.Rarity.LEGENDARY],

		["Accident", 500, TechCardData.TechEffectType.DESTROY_FACEUP_NO_CRYSTAL_LOSS,
			{}, "",
			"Destroy 1 face-up card. The owner does not lose Crystals for the destroyed card.",
			CharacterData.Rarity.RARE],

		["Berserk", 1500, TechCardData.TechEffectType.MULTI_ATTACK_ONE,
			{}, "",
			"Select 1 face-up character. Until end of next turn, that character can attack multiple times. You can't command any other character to attack.",
			CharacterData.Rarity.EXOTIC],

		["Radar", 500, TechCardData.TechEffectType.REVEAL_OPPONENT_SQUARE,
			{"count": 3}, "",
			"Reveal 3 squares on opponent's field.",
			CharacterData.Rarity.RARE],

		["Diplomacy Party", 500, TechCardData.TechEffectType.REVEAL_OWN_AND_OPPONENT_REVEALS,
			{}, "",
			"Reveal 1 of your face-down characters. Opponent must reveal 1 of their face-down characters (if any).",
			CharacterData.Rarity.COMMON],

		["Essence Transfer", 700, TechCardData.TechEffectType.MOVE_BUFFS_BETWEEN_CHARACTERS,
			{}, "",
			"Move all ATK and DEF bonuses from 1 face-up Character to another face-up Character on your field.",
			CharacterData.Rarity.COMMON],

		["Blood Ritual", 1800, TechCardData.TechEffectType.DESTROY_OWN_BASE_ZERO_OPPONENT,
			{}, "",
			"Destroy 1 face-up card on your field (no crystal cost). Set base ATK and DEF of 1 opponent's character to 0 permanently.",
			CharacterData.Rarity.LEGENDARY],

		["Arcane Duplication", 1200, TechCardData.TechEffectType.CLONE_CHARACTER_AS_TOKEN,
			{}, "",
			"Choose 1 face-up Character. Create a token copy on an empty square (same ATK/DEF/Affinity, no ability, 0 Crystals if destroyed).",
			CharacterData.Rarity.COMMON],

		["Time Travel", 2000, TechCardData.TechEffectType.REVIVE_CHARACTER_FULL,
			{}, "",
			"Once only: Revive 1 destroyed character to any unoccupied or blank square, face-up.",
			CharacterData.Rarity.EXOTIC],

		["Resurrection", 1500, TechCardData.TechEffectType.REVIVE_CHARACTER_NO_ATK,
			{}, "",
			"Once only: Revive 1 destroyed character to any unoccupied or blank square. Ability becomes None and ATK becomes 0.",
			CharacterData.Rarity.LEGENDARY],

		["Tech Copy", 1000, TechCardData.TechEffectType.VIEW_OPPONENT_TECH,
			{}, "",
			"Select 1 Tech Card in your opponent's hand. View it.",
			CharacterData.Rarity.COMMON],

		["Force Shield", 600, TechCardData.TechEffectType.FORCE_SHIELD_ONE_CARD,
			{}, "",
			"Select 1 card on your field. It is not destroyed until the end of your opponent's turn.",
			CharacterData.Rarity.UNCOMMON],

		["Wisp Light", 500, TechCardData.TechEffectType.DESTROY_WISPS_REVEAL_OPPONENT,
			{}, "",
			"Destroy as many Wisps on your side of the field as you can. Reveal that many squares on opponent's field.",
			CharacterData.Rarity.UNCOMMON],

		["Lucky Day", 500, TechCardData.TechEffectType.TEMP_REROLL_DICE,
			{}, "",
			"Until the end of your next turn, you may re-roll the dice once.",
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

# ─────────────────────────────────────────────────────────────
# Lookup helpers
# ─────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────
# Artwork path cache  (scans each folder at most once per name)
# ─────────────────────────────────────────────────────────────
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
