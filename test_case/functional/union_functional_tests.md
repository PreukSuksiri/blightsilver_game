# Union — Functional Test Cases (Demo = Yes)

Derived from Godot `CardDatabase.gd` / `UnionDatabase.gd` implementation.
Each case references the exact handler function and enum type.

**Cards:** 36

---

Card Name: Lord of Terror
Type: Union
Stats: ATK=200 DEF=100 summon_cost=1000 Affinity=CHAOS
AbilityType: ATK_PENALTY_VS_DEAD_END
ability_params: {'penalty': 50}
Description: -50 ATK if attacks dead end card.
Test Cases:

Test Case ID: TC-FUNC-Lord-of-Terror-000
Description:
Union summon: Lord of Terror
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Lord-of-Terror-001
Description:
Lord of Terror: -50 ATK permanently when attacking dead_end
Implementation Reference:
- TurnManager ATK_PENALTY_VS_DEAD_END
- AbilityType.ATK_PENALTY_VS_DEAD_END
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lord of Terror attacks dead_end.
Steps:
Step 1: Complete attack.
Expected Result:
- current_atk -= 50 permanently.

---

Card Name: Pixie Queen
Type: Union
Stats: ATK=30 DEF=30 summon_cost=1000 Affinity=DIVINE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 5, 'def_bonus': 0, 'affinity': 'A.DIVINE'}
Description: +5 ATK for each Divine card on own field.
Test Cases:

Test Case ID: TC-FUNC-Pixie-Queen-000
Description:
Union summon: Pixie Queen
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Pixie-Queen-001
Description:
Pixie Queen: field passive +5 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: A.DIVINE) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Pixie Queen.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 5 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Giant Mining Pod
Type: Union
Stats: ATK=20 DEF=80 summon_cost=1000 Affinity=COSMIC
AbilityType: CRYSTAL_GAIN_ON_DEAD_END_ATTACK
ability_params: {'amount': 200}
Description: If this card attacks a dead end card, you receive 200 crystals.
Test Cases:

Test Case ID: TC-FUNC-Giant-Mining-Pod-000
Description:
Union summon: Giant Mining Pod
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Giant-Mining-Pod-001
Description:
Giant Mining Pod: +200 crystals on dead_end attack
Implementation Reference:
- TurnManager GameState.gain_crystals
- AbilityType.CRYSTAL_GAIN_ON_DEAD_END_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Record crystals before attack.
Steps:
Step 1: Attack dead_end.
Expected Result:
- crystals[player] += 200.

---

Card Name: Seraphim Fistmaster
Type: Union
Stats: ATK=120 DEF=120 summon_cost=1500 Affinity=DIVINE
AbilityType: DOUBLE_STATS_VS_AFFINITY
ability_params: {'affinity': 'A.CHAOS'}
Description: Double ATK and DEF against Chaos.
Test Cases:

Test Case ID: TC-FUNC-Seraphim-Fistmaster-000
Description:
Union summon: Seraphim Fistmaster
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Seraphim-Fistmaster-001
Description:
Seraphim Fistmaster: double ATK/DEF vs A.CHAOS
Implementation Reference:
- BattleResolver doubles get_effective_atk/def when affinity matches
- AbilityType.DOUBLE_STATS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle vs A.CHAOS opponent.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == base_atk * 2 (when attacking A.CHAOS).
- defender_def_used == base_def * 2 (when defending vs A.CHAOS).

---

Card Name: Ancient Lizard
Type: Union
Stats: ATK=75 DEF=75 summon_cost=None Affinity=Nature
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Ancient-Lizard-001
Description:
Ancient Lizard: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 1 Flame Lizard + 1 Nature card + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: None
- Engine test blocked until _add() entry exists.

---

Card Name: Berserk Hyena
Type: Union
Stats: ATK=40 DEF=0 summon_cost=None Affinity=Nature
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Berserk-Hyena-001
Description:
Berserk Hyena: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 2 Nature + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: None
- Engine test blocked until _add() entry exists.

---

Card Name: Blood-hungry Mutant
Type: Union
Stats: ATK=55 DEF=40 summon_cost=None Affinity=Cosmic
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: If this card destroyed opponent’s card, +80 crystals
Test Cases:

Test Case ID: TC-FUNC-Blood-hungry-Mutant-001
Description:
Blood-hungry Mutant: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 2 Mutant cards + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: If this card destroyed opponent’s card, +80 crystals
- Engine test blocked until _add() entry exists.

---

Card Name: Burning Phoenix
Type: Union
Stats: ATK=110 DEF=50 summon_cost=None Affinity=Arcane
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: This card cannot be destroyed by non-union cards. When this card is targeted by tech, destroy it immediately.
Test Cases:

Test Case ID: TC-FUNC-Burning-Phoenix-001
Description:
Burning Phoenix: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 1 Arcane (≥ 1000 cost) + 1 Nature (≥ 1000 cost) + 1 Divine (≥ 1000 cost) + 2000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: This card cannot be destroyed by non-union cards. When this card is targeted by tech, destroy it immediately.
- Engine test blocked until _add() entry exists.

---

Card Name: Colorful Mage
Type: Union
Stats: ATK=55 DEF=40 summon_cost=None Affinity=Arcane
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: -10 ATK and DEF permanently if battles against non-Arcane card.
Test Cases:

Test Case ID: TC-FUNC-Colorful-Mage-001
Description:
Colorful Mage: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: Red Mage + Green Mage + Blue Mage + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: -10 ATK and DEF permanently if battles against non-Arcane card.
- Engine test blocked until _add() entry exists.

---

Card Name: False Prophet
Type: Union
Stats: ATK=20 DEF=40 summon_cost=None Affinity=Divine
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: At the start of your turn, you may flip one of your opponent face-down cards face-up. If it was a Dead End, destroy this card. If it was character or trap, gain 200 crystal
Test Cases:

Test Case ID: TC-FUNC-False-Prophet-001
Description:
False Prophet: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 2 Divine cards + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: At the start of your turn, you may flip one of your opponent face-down cards face-up. If it was a Dead End, destroy this card. If it was character or trap, gain 200 crystal
- Engine test blocked until _add() entry exists.

---

Card Name: Gamma Mermaid
Type: Union
Stats: ATK=30 DEF=20 summon_cost=None Affinity=Bio
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: -20 DEF to non-Bio defender
Test Cases:

Test Case ID: TC-FUNC-Gamma-Mermaid-001
Description:
Gamma Mermaid: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 1 Gamma cards + 1 Bio card + 1000
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: -20 DEF to non-Bio defender
- Engine test blocked until _add() entry exists.

---

Card Name: Giant Meteor Vergaia
Type: Union
Stats: ATK=60 DEF=0 summon_cost=None Affinity=Cosmic
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: Once face-up, destroy it and the end of this turn. Select all face-up opponent’s card in adjacent of target cell with 60 DEF or less, destroy them.
Test Cases:

Test Case ID: TC-FUNC-Giant-Meteor-Vergaia-001
Description:
Giant Meteor Vergaia: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: Striker Comet + 2 Cosmic card + 2000
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: Once face-up, destroy it and the end of this turn. Select all face-up opponent’s card in adjacent of target cell with 60 DEF or less, destroy them.
- Engine test blocked until _add() entry exists.

---

Card Name: Grand Fort Captain
Type: Union
Stats: ATK=45 DEF=40 summon_cost=None Affinity=Anima
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Grand-Fort-Captain-001
Description:
Grand Fort Captain: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 2 Grand Fort card + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: None
- Engine test blocked until _add() entry exists.

---

Card Name: Imperial Frame
Type: Union
Stats: ATK=45 DEF=30 summon_cost=None Affinity=Cosmic
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Imperial-Frame-001
Description:
Imperial Frame: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: Laser Walker + 1 Cosmic card + 1000
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: None
- Engine test blocked until _add() entry exists.

---

Card Name: Kiba the Giant Slayer
Type: Union
Stats: ATK=80 DEF=55 summon_cost=None Affinity=Anima
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: +30 ATK vs Union
Test Cases:

Test Case ID: TC-FUNC-Kiba-the-Giant-Slayer-001
Description:
Kiba the Giant Slayer: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: Kiyoko the Death Whisper + Silver Spearman + 1500
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: +30 ATK vs Union
- Engine test blocked until _add() entry exists.

---

Card Name: Moon Ninja Lady
Type: Union
Stats: ATK=65 DEF=50 summon_cost=None Affinity=Anima
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: Once, this card is not destroyed.
Test Cases:

Test Case ID: TC-FUNC-Moon-Ninja-Lady-001
Description:
Moon Ninja Lady: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: Kiyoko the Death Whisper + 1 Anima card + 1000
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: Once, this card is not destroyed.
- Engine test blocked until _add() entry exists.

---

Card Name: Moon Tribe Shaman
Type: Union
Stats: ATK=25 DEF=55 summon_cost=None Affinity=Cosmic
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: Upon union, revive 1 Moon card on your empty cell. Double its cost.
Test Cases:

Test Case ID: TC-FUNC-Moon-Tribe-Shaman-001
Description:
Moon Tribe Shaman: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 1 Moon card+ 1 Cosmic card + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: Upon union, revive 1 Moon card on your empty cell. Double its cost.
- Engine test blocked until _add() entry exists.

---

Card Name: Rebel King
Type: Union
Stats: ATK=60 DEF=40 summon_cost=None Affinity=Anima
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: At the end of your opponent’s turn, your opponent select 1 of their face-up card (if any) and swap ATK and DEF
Test Cases:

Test Case ID: TC-FUNC-Rebel-King-001
Description:
Rebel King: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: Jirayu the Rebellious Prince + 1 Anima card + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: At the end of your opponent’s turn, your opponent select 1 of their face-up card (if any) and swap ATK and DEF
- Engine test blocked until _add() entry exists.

---

Card Name: Rocket Peacock
Type: Union
Stats: ATK=150 DEF=100 summon_cost=None Affinity=Nature
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: After this card battles, select 1 card on your opponent’s field, flip a coin. If head, destroy that card
Test Cases:

Test Case ID: TC-FUNC-Rocket-Peacock-001
Description:
Rocket Peacock: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: Ostrich Cannon + 1 Nature card + 1500 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: After this card battles, select 1 card on your opponent’s field, flip a coin. If head, destroy that card
- Engine test blocked until _add() entry exists.

---

Card Name: Scarlet Shroom
Type: Union
Stats: ATK=0 DEF=80 summon_cost=None Affinity=Nature
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: If this card is union summoned, put venom flag on ???
Test Cases:

Test Case ID: TC-FUNC-Scarlet-Shroom-001
Description:
Scarlet Shroom: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 2 Nature cards + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: If this card is union summoned, put venom flag on ???
- Engine test blocked until _add() entry exists.

---

Card Name: Volatile Slasher
Type: Union
Stats: ATK=50 DEF=45 summon_cost=None Affinity=Bio
AbilityType: EXCEL_ONLY_NOT_IN_UNION_DATABASE
ability_params: {}
Description: While this card attacking, it gain +50 ATK bonus vs target’s affinity permanently, once per affinity.
Test Cases:

Test Case ID: TC-FUNC-Volatile-Slasher-001
Description:
Volatile Slasher: pending UnionDatabase implementation
Implementation Reference:
- UnionDatabase.gd — NOT YET REGISTERED
- Excel Demo=Yes with planned ability text
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card listed in card_data_demo.xlsx Union sheet.
- Planned formula: 1 Bladeshifter + 1 Bio card + 1000 crystals
Steps:
Step 1: Verify card appears in design spreadsheet.
Step 2: When added to UnionDatabase.gd, replace with code-derived functional tests.
Expected Result:
- Excel ability: While this card attacking, it gain +50 ATK bonus vs target’s affinity permanently, once per affinity.
- Engine test blocked until _add() entry exists.

---

Card Name: Choir Lead Amber
Type: Union
Stats: ATK=35 DEF=35 summon_cost=1000 Affinity=DIVINE
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'affinity': 'A.DIVINE', 'atk': 20}
Description: +20 ATK to all Divine characters on own field.
Test Cases:

Test Case ID: TC-FUNC-Choir-Lead-Amber-000
Description:
Union summon: Choir Lead Amber
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Choir-Lead-Amber-001
Description:
Choir Lead Amber: aura +20 ATK to own A.DIVINE characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Choir Lead Amber face-up.
- Other face-up A.DIVINE ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +20 from Choir Lead Amber aura.

---

Card Name: Greater Succubus
Type: Union
Stats: ATK=30 DEF=50 summon_cost=1000 Affinity=CHAOS
AbilityType: GAIN_HALF_STATS_ON_SURVIVE
ability_params: {}
Description: If this card survived a battle, gain half of ATK and DEF equal to the card it battled.
Test Cases:

Test Case ID: TC-FUNC-Greater-Succubus-000
Description:
Union summon: Greater Succubus
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Greater-Succubus-001
Description:
Greater Succubus: gain half of opponent ATK/DEF after surviving battle
Implementation Reference:
- TurnManager._apply_post_battle_effects GAIN_HALF_STATS_ON_SURVIVE
- AbilityType.GAIN_HALF_STATS_ON_SURVIVE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Greater Succubus attacks character and survives.
Steps:
Step 1: Complete battle.
Expected Result:
- current_atk += defender.current_atk/2; current_def += defender.current_def/2.

---

Card Name: Ten Arms Yaksa
Type: Union
Stats: ATK=45 DEF=30 summon_cost=1000 Affinity=CHAOS
AbilityType: MULTI_ATTACK_ANY_WITH_ATK_LOSS
ability_params: {'max_attacks': 3, 'atk_loss': 5}
Description: This card can attack 3 times. -5 ATK for each successful attack.
Test Cases:

Test Case ID: TC-FUNC-Ten-Arms-Yaksa-000
Description:
Union summon: Ten Arms Yaksa
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Ten-Arms-Yaksa-001
Description:
Ten Arms Yaksa: up to 3 attacks, -5 ATK per attack
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY_WITH_ATK_LOSS
- AbilityType.MULTI_ATTACK_ANY_WITH_ATK_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining sufficient.
Steps:
Step 1: Chain 3 attacks same turn.
Expected Result:
- Each attack: current_atk -= 5; extra attack while multi_attack_count < 3.

---

Card Name: Barros the Collossol
Type: Union
Stats: ATK=150 DEF=130 summon_cost=1500 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: No ability.
Test Cases:

Test Case ID: TC-FUNC-Barros-the-Collossol-000
Description:
Union summon: Barros the Collossol
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1500 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1500 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Barros-the-Collossol-001
Description:
Barros the Collossol: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: No ability.

---

Card Name: Gaia Turtle
Type: Union
Stats: ATK=0 DEF=220 summon_cost=2000 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: No ability.
Test Cases:

Test Case ID: TC-FUNC-Gaia-Turtle-000
Description:
Union summon: Gaia Turtle
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=2000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 2000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Gaia-Turtle-001
Description:
Gaia Turtle: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: No ability.

---

Card Name: Gryphon Rider
Type: Union
Stats: ATK=150 DEF=95 summon_cost=1000 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: No ability.
Test Cases:

Test Case ID: TC-FUNC-Gryphon-Rider-000
Description:
Union summon: Gryphon Rider
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Gryphon-Rider-001
Description:
Gryphon Rider: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: No ability.

---

Card Name: Katana Shark
Type: Union
Stats: ATK=75 DEF=50 summon_cost=0 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: No ability.
Test Cases:

Test Case ID: TC-FUNC-Katana-Shark-000
Description:
Union summon: Katana Shark
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=0 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 0 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Katana-Shark-001
Description:
Katana Shark: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: No ability.

---

Card Name: Kitsune
Type: Union
Stats: ATK=35 DEF=35 summon_cost=1000 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: No ability.
Test Cases:

Test Case ID: TC-FUNC-Kitsune-000
Description:
Union summon: Kitsune
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Kitsune-001
Description:
Kitsune: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: No ability.

---

Card Name: Raijin and Fujin
Type: Union
Stats: ATK=80 DEF=80 summon_cost=1000 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: No ability.
Test Cases:

Test Case ID: TC-FUNC-Raijin-and-Fujin-000
Description:
Union summon: Raijin and Fujin
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Raijin-and-Fujin-001
Description:
Raijin and Fujin: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: No ability.

---

Card Name: Rocket Tyrant
Type: Union
Stats: ATK=130 DEF=110 summon_cost=1000 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: No ability.
Test Cases:

Test Case ID: TC-FUNC-Rocket-Tyrant-000
Description:
Union summon: Rocket Tyrant
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Rocket-Tyrant-001
Description:
Rocket Tyrant: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: No ability.

---

Card Name: Skeleton Overlord
Type: Union
Stats: ATK=50 DEF=5 summon_cost=1000 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: No ability.
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Overlord-000
Description:
Union summon: Skeleton Overlord
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Skeleton-Overlord-001
Description:
Skeleton Overlord: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: No ability.

---

Card Name: Diamond Unicorn
Type: Union
Stats: ATK=50 DEF=35 summon_cost=1000 Affinity=DIVINE
AbilityType: ONE_USE_DEF_BOOST
ability_params: {'bonus': 15}
Description: +15 ATK until the end of this turn, once.
Test Cases:

Test Case ID: TC-FUNC-Diamond-Unicorn-000
Description:
Union summon: Diamond Unicorn
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Diamond-Unicorn-001
Description:
Diamond Unicorn: one-time +15 DEF when defending
Implementation Reference:
- BattleResolver._get_effective_def()
- TurnManager marks one_use_def_boost_used after battle
- AbilityType.ONE_USE_DEF_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First defense with Diamond Unicorn.
Steps:
Step 1: Opponent attacks twice across two turns.
Expected Result:
- First defense: defender_def_used == 50.
- Second defense: defender_def_used == 35.

---

Card Name: Armored Dino
Type: Union
Stats: ATK=100 DEF=60 summon_cost=1000 Affinity=NATURE
AbilityType: OPTIONAL_CRYSTAL_PAY_DEF_BOOST
ability_params: {'cost': 1000, 'def': 60}
Description: During battle calculation, pay 1000 crystal cost to +60 DEF.
Test Cases:

Test Case ID: TC-FUNC-Armored-Dino-000
Description:
Union summon: Armored Dino
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Armored-Dino-001
Description:
Armored Dino: optional pay 1000 for +60 DEF during battle
Implementation Reference:
- TurnManager OPTIONAL_CRYSTAL_PAY_DEF_BOOST on defender side
- AbilityType.OPTIONAL_CRYSTAL_PAY_DEF_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Union/card defends; crystals>=1000.
Steps:
Step 1: Accept/decline DEF boost prompt on battle overlay.
Expected Result:
- Accept: effective DEF +60; crystals -= 1000.

---

Card Name: X-Death Squad
Type: Union
Stats: ATK=50 DEF=50 summon_cost=1000 Affinity=ANIMA
AbilityType: OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT
ability_params: {'cost': 1000}
Description: Pay 1000 crystals: destroy opponent character during damage calculation. Opponent does not lose crystals under this effect.
Test Cases:

Test Case ID: TC-FUNC-X-Death-Squad-000
Description:
Union summon: X-Death Squad
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-X-Death-Squad-001
Description:
X-Death Squad: pay 1000 crystals to destroy defender (no opp crystal loss)
Implementation Reference:
- TurnManager pre-battle OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT
- GameState.place_dead_end on accept; attack_aborted signal
- AbilityType.OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- crystals[player] >= 1000.
- Defender is character.
Steps:
Step 1: Accept prompt: pay 1000; defender cell → dead_end.
Step 2: Opponent does NOT lose crystals.
Step 3: Skip prompt: normal battle proceeds.
Expected Result:

---

Card Name: Sky Protector
Type: Union
Stats: ATK=0 DEF=0 summon_cost=1000 Affinity=DIVINE
AbilityType: STANCE_FIXED_STATS
ability_params: {'atk_atk': 50, 'atk_def': 0, 'def_atk': 0, 'def_def': 50}
Description: If this card defends, DEF becomes 50, ATK becomes 0. If this card attacks, ATK becomes 50, DEF becomes 0.
Test Cases:

Test Case ID: TC-FUNC-Sky-Protector-000
Description:
Union summon: Sky Protector
Implementation Reference:
- GameBoard._perform_pending_union
- UnionDatabase.find_available_unions validation
- Once per duel per player
Preconditions:
- summon_cost=1000 crystals available.
- Material cells satisfy UnionDatabase material_conditions.
Steps:
Step 1: Enter union mode; select valid materials.
Step 2: Pay 1000 crystals; place at anchor cell.
Expected Result:
- is_union=true; face_up=true at anchor.
- Materials removed pay_cost=false.
- _union_summoned_this_duel[player]=true blocks second union.

Test Case ID: TC-FUNC-Sky-Protector-001
Description:
Sky Protector: fixed ATK/DEF by stance
Implementation Reference:
- BattleResolver STANCE_FIXED_STATS uses atk_atk/def_def params
- AbilityType.STANCE_FIXED_STATS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attack and defend scenarios separately.
Steps:
Step 1: Resolve each battle.
Expected Result:
- Attacking uses atk_atk/def_atk params; defending uses def_def params from ability_params.

---
