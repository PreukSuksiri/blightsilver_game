# Character — Functional Test Cases (Demo = Yes)

Derived from Godot `CardDatabase.gd` / `UnionDatabase.gd` implementation.
Each case references the exact handler function and enum type.

**Cards:** 503

---

Card Name: Elven Blacksmith
Type: Character
Stats: ATK=15 DEF=15 Cost=250 Affinity=NATURE
AbilityType: ADJACENT_ATTACK_FLIP_BUFF
ability_params: {'once': True, 'affinity': 'NATURE', 'atk': 5, 'def': 5, 'on_adjacent_expose': True, 'face_down': True}
Description: Once, if a Nature card in surrounding cell get exposed, that card get +5 ATK&DEF. Usable facedown.
Test Cases:

Test Case ID: TC-FUNC-Elven-Blacksmith-001
Description:
Elven Blacksmith: ability ADJACENT_ATTACK_FLIP_BUFF functional smoke test
Implementation Reference:
- CharacterData.AbilityType.ADJACENT_ATTACK_FLIP_BUFF
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'once': True, 'affinity': 'NATURE', 'atk': 5, 'def': 5, 'on_adjacent_expose': True, 'face_down': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, if a Nature card in surrounding cell get exposed, that card get +5 ATK&DEF. Usable facedown.

---

Card Name: Fox Mage
Type: Character
Stats: ATK=20 DEF=20 Cost=800 Affinity=NATURE
AbilityType: ADJACENT_ATTACK_FLIP_BUFF
ability_params: {'once_on_reveal': True, 'affinity': 'ARCANE', 'atk': 20, 'def': 20}
Description: Once upon revealed +20 ATK&DEF to Arcane card.
Test Cases:

Test Case ID: TC-FUNC-Fox-Mage-001
Description:
Fox Mage: ability ADJACENT_ATTACK_FLIP_BUFF functional smoke test
Implementation Reference:
- CharacterData.AbilityType.ADJACENT_ATTACK_FLIP_BUFF
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'once_on_reveal': True, 'affinity': 'ARCANE', 'atk': 20, 'def': 20}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once upon revealed +20 ATK&DEF to Arcane card.

---

Card Name: Karate Master
Type: Character
Stats: ATK=10 DEF=15 Cost=400 Affinity=ANIMA
AbilityType: ADJACENT_ATTACK_FLIP_BUFF
ability_params: {'on_expose': True, 'atk': 15, 'def': 15, 'any_own': True}
Description: Exposed : Select 1 of your unit (face-up or face-down). It gain +15 ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Karate-Master-001
Description:
Karate Master: ability ADJACENT_ATTACK_FLIP_BUFF functional smoke test
Implementation Reference:
- CharacterData.AbilityType.ADJACENT_ATTACK_FLIP_BUFF
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'on_expose': True, 'atk': 15, 'def': 15, 'any_own': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Exposed : Select 1 of your unit (face-up or face-down). It gain +15 ATK&DEF

---

Card Name: Methanomancer
Type: Character
Stats: ATK=20 DEF=20 Cost=350 Affinity=COSMIC
AbilityType: ADJACENT_ATTACK_FLIP_BUFF
ability_params: {'atk': 30, 'def': 30}
Description: If its surrounding cell is targeted for attack, flip this card face-up and gain +30 ATK&DEF.
Test Cases:

Test Case ID: TC-FUNC-Methanomancer-001
Description:
Methanomancer: ability ADJACENT_ATTACK_FLIP_BUFF functional smoke test
Implementation Reference:
- CharacterData.AbilityType.ADJACENT_ATTACK_FLIP_BUFF
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'atk': 30, 'def': 30}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: If its surrounding cell is targeted for attack, flip this card face-up and gain +30 ATK&DEF.

---

Card Name: Agent Penelope
Type: Character
Stats: ATK=10 DEF=10 Cost=200 Affinity=ANIMA
AbilityType: ATK_BONUS_IF_AFFINITY_ON_FIELD
ability_params: {'name_contains': 'Agent', 'bonus': 25, 'exposed': True}
Description: +25 ATK if there is face-up Agent card on your side
Test Cases:

Test Case ID: TC-FUNC-Agent-Penelope-001
Description:
Agent Penelope: +25 ATK when face-up ? ally on field
Implementation Reference:
- BattleResolver._get_effective_atk() scans GameState.grids
- AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place another face-up ? character on attacker's grid.
- Agent Penelope attacks (does not need to target ?).
Steps:
Step 1: Run calculate_field_bonuses if needed; resolve battle.
Expected Result:
- attacker_atk_used == 35.

---

Card Name: Armored Monkey
Type: Character
Stats: ATK=10 DEF=20 Cost=170 Affinity=NATURE
AbilityType: ATK_BONUS_IF_AFFINITY_ON_FIELD
ability_params: {'affinity': 'NATURE', 'bonus': 10}
Description: +10 ATK if there is another exposed Nature card
Test Cases:

Test Case ID: TC-FUNC-Armored-Monkey-001
Description:
Armored Monkey: +10 ATK when face-up NATURE ally on field
Implementation Reference:
- BattleResolver._get_effective_atk() scans GameState.grids
- AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place another face-up NATURE character on attacker's grid.
- Armored Monkey attacks (does not need to target NATURE).
Steps:
Step 1: Run calculate_field_bonuses if needed; resolve battle.
Expected Result:
- attacker_atk_used == 20.

---

Card Name: Dark Mistress
Type: Character
Stats: ATK=50 DEF=35 Cost=450 Affinity=CHAOS
AbilityType: ATK_BONUS_IF_AFFINITY_ON_FIELD
ability_params: {'field_scope': 'void', 'min_count': 8, 'bonus': 50}
Description: +50 ATK if there is 8 or more unit in your void.
Test Cases:

Test Case ID: TC-FUNC-Dark-Mistress-001
Description:
Dark Mistress: +50 ATK when face-up ? ally on field
Implementation Reference:
- BattleResolver._get_effective_atk() scans GameState.grids
- AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place another face-up ? character on attacker's grid.
- Dark Mistress attacks (does not need to target ?).
Steps:
Step 1: Run calculate_field_bonuses if needed; resolve battle.
Expected Result:
- attacker_atk_used == 100.

---

Card Name: Human Dog
Type: Character
Stats: ATK=20 DEF=15 Cost=250 Affinity=CHAOS
AbilityType: ATK_BONUS_IF_AFFINITY_ON_FIELD
ability_params: {'affinities': ['ANIMA'], 'bonus': 10}
Description: +10 ATK if there is Anima or Nature card on your side
Test Cases:

Test Case ID: TC-FUNC-Human-Dog-001
Description:
Human Dog: +10 ATK when face-up ? ally on field
Implementation Reference:
- BattleResolver._get_effective_atk() scans GameState.grids
- AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place another face-up ? character on attacker's grid.
- Human Dog attacks (does not need to target ?).
Steps:
Step 1: Run calculate_field_bonuses if needed; resolve battle.
Expected Result:
- attacker_atk_used == 30.

---

Card Name: Rifleman
Type: Character
Stats: ATK=20 DEF=15 Cost=150 Affinity=ANIMA
AbilityType: ATK_BONUS_IF_AFFINITY_ON_FIELD
ability_params: {'affinity': 'ANIMA', 'bonus': 5, 'exposed_ally': True}
Description: +5 ATK if there is face-up Anima ally on your side
Test Cases:

Test Case ID: TC-FUNC-Rifleman-001
Description:
Rifleman: +5 ATK when face-up ANIMA ally on field
Implementation Reference:
- BattleResolver._get_effective_atk() scans GameState.grids
- AbilityType.ATK_BONUS_IF_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place another face-up ANIMA character on attacker's grid.
- Rifleman attacks (does not need to target ANIMA).
Steps:
Step 1: Run calculate_field_bonuses if needed; resolve battle.
Expected Result:
- attacker_atk_used == 25.

---

Card Name: Padmapani
Type: Character
Stats: ATK=50 DEF=25 Cost=1000 Affinity=DIVINE
AbilityType: ATK_BONUS_IF_TECH_PLAYED
ability_params: {'tech_name': 'Prayer', 'bonus': 75}
Description: +75 ATK if there is Prayer card in your void.
Test Cases:

Test Case ID: TC-FUNC-Padmapani-001
Description:
Padmapani: ability ATK_BONUS_IF_TECH_PLAYED functional smoke test
Implementation Reference:
- CharacterData.AbilityType.ATK_BONUS_IF_TECH_PLAYED
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'tech_name': 'Prayer', 'bonus': 75}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +75 ATK if there is Prayer card in your void.

---

Card Name: Angel Gatekeeper
Type: Character
Stats: ATK=40 DEF=90 Cost=1000 Affinity=DIVINE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'bonus': 50}
Description: +50 ATK vs Chaos Affinity
Test Cases:

Test Case ID: TC-FUNC-Angel-Gatekeeper-001
Description:
Angel Gatekeeper: effective ATK +50 vs CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=CHAOS, bonus=50
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Angel Gatekeeper (base ATK 40) face-up.
- Defender: any CHAOS character with DEF < 90.
Steps:
Step 1: Call BattleResolver.resolve_battle(Angel Gatekeeper, CHAOS defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 90 (base 40 + bonus 50).
- result.attacker_atk_delta == 50.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 90)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Angel-Gatekeeper-002
Description:
Angel Gatekeeper: no bonus vs non-CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != CHAOS (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-CHAOS target with Angel Gatekeeper.
Expected Result:
- result.attacker_atk_used == 40 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 40)

---

Card Name: Bleacher Squad
Type: Character
Stats: ATK=20 DEF=20 Cost=320 Affinity=BIO
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'BIO', 'bonus': 20}
Description: +20 ATK vs Bio
Test Cases:

Test Case ID: TC-FUNC-Bleacher-Squad-001
Description:
Bleacher Squad: effective ATK +20 vs BIO defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=BIO, bonus=20
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Bleacher Squad (base ATK 20) face-up.
- Defender: any BIO character with DEF < 40.
Steps:
Step 1: Call BattleResolver.resolve_battle(Bleacher Squad, BIO defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 40 (base 20 + bonus 20).
- result.attacker_atk_delta == 20.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 40)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Bleacher-Squad-002
Description:
Bleacher Squad: no bonus vs non-BIO defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != BIO (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-BIO target with Bleacher Squad.
Expected Result:
- result.attacker_atk_used == 20 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)

---

Card Name: Eagle Bowman
Type: Character
Stats: ATK=45 DEF=35 Cost=600 Affinity=ANIMA
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ANIMA', 'bonus': 30}
Description: +30 ATK vs unit in foe’s border cells
Test Cases:

Test Case ID: TC-FUNC-Eagle-Bowman-001
Description:
Eagle Bowman: effective ATK +30 vs ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=ANIMA, bonus=30
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Eagle Bowman (base ATK 45) face-up.
- Defender: any ANIMA character with DEF < 75.
Steps:
Step 1: Call BattleResolver.resolve_battle(Eagle Bowman, ANIMA defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 75 (base 45 + bonus 30).
- result.attacker_atk_delta == 30.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 75)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Eagle-Bowman-002
Description:
Eagle Bowman: no bonus vs non-ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != ANIMA (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-ANIMA target with Eagle Bowman.
Expected Result:
- result.attacker_atk_used == 45 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 45)

---

Card Name: Holy Wisp
Type: Character
Stats: ATK=10 DEF=20 Cost=200 Affinity=DIVINE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'bonus': 10}
Description: +10 ATK vs Chaos
Test Cases:

Test Case ID: TC-FUNC-Holy-Wisp-001
Description:
Holy Wisp: effective ATK +10 vs CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=CHAOS, bonus=10
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Holy Wisp (base ATK 10) face-up.
- Defender: any CHAOS character with DEF < 20.
Steps:
Step 1: Call BattleResolver.resolve_battle(Holy Wisp, CHAOS defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 20 (base 10 + bonus 10).
- result.attacker_atk_delta == 10.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Holy-Wisp-002
Description:
Holy Wisp: no bonus vs non-CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != CHAOS (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-CHAOS target with Holy Wisp.
Expected Result:
- result.attacker_atk_used == 10 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 10)

---

Card Name: Jacob the Ski Mask
Type: Character
Stats: ATK=15 DEF=20 Cost=350 Affinity=CHAOS
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ANIMA', 'bonus': 5}
Description: +5 ATK vs Anima
Test Cases:

Test Case ID: TC-FUNC-Jacob-the-Ski-Mask-001
Description:
Jacob the Ski Mask: effective ATK +5 vs ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=ANIMA, bonus=5
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Jacob the Ski Mask (base ATK 15) face-up.
- Defender: any ANIMA character with DEF < 20.
Steps:
Step 1: Call BattleResolver.resolve_battle(Jacob the Ski Mask, ANIMA defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 20 (base 15 + bonus 5).
- result.attacker_atk_delta == 5.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Jacob-the-Ski-Mask-002
Description:
Jacob the Ski Mask: no bonus vs non-ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != ANIMA (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-ANIMA target with Jacob the Ski Mask.
Expected Result:
- result.attacker_atk_used == 15 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 15)

---

Card Name: Magic Headhunter
Type: Character
Stats: ATK=20 DEF=15 Cost=240 Affinity=ARCANE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ARCANE', 'bonus': 10}
Description: +10 ATK vs Arcane
Test Cases:

Test Case ID: TC-FUNC-Magic-Headhunter-001
Description:
Magic Headhunter: effective ATK +10 vs ARCANE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=ARCANE, bonus=10
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Magic Headhunter (base ATK 20) face-up.
- Defender: any ARCANE character with DEF < 30.
Steps:
Step 1: Call BattleResolver.resolve_battle(Magic Headhunter, ARCANE defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 30 (base 20 + bonus 10).
- result.attacker_atk_delta == 10.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 30)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Magic-Headhunter-002
Description:
Magic Headhunter: no bonus vs non-ARCANE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != ARCANE (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-ARCANE target with Magic Headhunter.
Expected Result:
- result.attacker_atk_used == 20 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)

---

Card Name: Nanomites Beast
Type: Character
Stats: ATK=50 DEF=55 Cost=800 Affinity=BIO
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'COSMIC', 'bonus': 50}
Description: +50 ATK vs Cosmic
Test Cases:

Test Case ID: TC-FUNC-Nanomites-Beast-001
Description:
Nanomites Beast: effective ATK +50 vs COSMIC defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=COSMIC, bonus=50
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Nanomites Beast (base ATK 50) face-up.
- Defender: any COSMIC character with DEF < 100.
Steps:
Step 1: Call BattleResolver.resolve_battle(Nanomites Beast, COSMIC defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 100 (base 50 + bonus 50).
- result.attacker_atk_delta == 50.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 100)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Nanomites-Beast-002
Description:
Nanomites Beast: no bonus vs non-COSMIC defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != COSMIC (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-COSMIC target with Nanomites Beast.
Expected Result:
- result.attacker_atk_used == 50 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 50)

---

Card Name: Nanomites Walker
Type: Character
Stats: ATK=15 DEF=15 Cost=170 Affinity=BIO
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'COSMIC', 'bonus': 5}
Description: +5 ATK vs Cosmic
Test Cases:

Test Case ID: TC-FUNC-Nanomites-Walker-001
Description:
Nanomites Walker: effective ATK +5 vs COSMIC defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=COSMIC, bonus=5
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Nanomites Walker (base ATK 15) face-up.
- Defender: any COSMIC character with DEF < 20.
Steps:
Step 1: Call BattleResolver.resolve_battle(Nanomites Walker, COSMIC defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 20 (base 15 + bonus 5).
- result.attacker_atk_delta == 5.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Nanomites-Walker-002
Description:
Nanomites Walker: no bonus vs non-COSMIC defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != COSMIC (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-COSMIC target with Nanomites Walker.
Expected Result:
- result.attacker_atk_used == 15 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 15)

---

Card Name: Nanomites Worms
Type: Character
Stats: ATK=0 DEF=25 Cost=150 Affinity=BIO
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'COSMIC', 'bonus': 20}
Description: +20 ATK vs Cosmic
Test Cases:

Test Case ID: TC-FUNC-Nanomites-Worms-001
Description:
Nanomites Worms: effective ATK +20 vs COSMIC defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=COSMIC, bonus=20
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Nanomites Worms (base ATK 0) face-up.
- Defender: any COSMIC character with DEF < 20.
Steps:
Step 1: Call BattleResolver.resolve_battle(Nanomites Worms, COSMIC defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 20 (base 0 + bonus 20).
- result.attacker_atk_delta == 20.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Nanomites-Worms-002
Description:
Nanomites Worms: no bonus vs non-COSMIC defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != COSMIC (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-COSMIC target with Nanomites Worms.
Expected Result:
- result.attacker_atk_used == 0 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 0)

---

Card Name: Planewalker
Type: Character
Stats: ATK=15 DEF=15 Cost=200 Affinity=ARCANE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ARCANE', 'bonus': 10}
Description: +10 ATK vs. Arcane
Test Cases:

Test Case ID: TC-FUNC-Planewalker-001
Description:
Planewalker: effective ATK +10 vs ARCANE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=ARCANE, bonus=10
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Planewalker (base ATK 15) face-up.
- Defender: any ARCANE character with DEF < 25.
Steps:
Step 1: Call BattleResolver.resolve_battle(Planewalker, ARCANE defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 25 (base 15 + bonus 10).
- result.attacker_atk_delta == 10.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 25)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Planewalker-002
Description:
Planewalker: no bonus vs non-ARCANE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != ARCANE (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-ARCANE target with Planewalker.
Expected Result:
- result.attacker_atk_used == 15 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 15)

---

Card Name: Pyromancer
Type: Character
Stats: ATK=80 DEF=0 Cost=900 Affinity=ARCANE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'bonus': 30}
Description: +30 ATK vs Nature Affinity
Test Cases:

Test Case ID: TC-FUNC-Pyromancer-001
Description:
Pyromancer: effective ATK +30 vs NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=NATURE, bonus=30
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Pyromancer (base ATK 80) face-up.
- Defender: any NATURE character with DEF < 110.
Steps:
Step 1: Call BattleResolver.resolve_battle(Pyromancer, NATURE defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 110 (base 80 + bonus 30).
- result.attacker_atk_delta == 30.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 110)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Pyromancer-002
Description:
Pyromancer: no bonus vs non-NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != NATURE (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-NATURE target with Pyromancer.
Expected Result:
- result.attacker_atk_used == 80 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 80)

---

Card Name: Red Mage
Type: Character
Stats: ATK=20 DEF=20 Cost=400 Affinity=ARCANE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'bonus': 10}
Description: +10 ATK vs Nature
Test Cases:

Test Case ID: TC-FUNC-Red-Mage-001
Description:
Red Mage: effective ATK +10 vs NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=NATURE, bonus=10
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Red Mage (base ATK 20) face-up.
- Defender: any NATURE character with DEF < 30.
Steps:
Step 1: Call BattleResolver.resolve_battle(Red Mage, NATURE defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 30 (base 20 + bonus 10).
- result.attacker_atk_delta == 10.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 30)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Red-Mage-002
Description:
Red Mage: no bonus vs non-NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != NATURE (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-NATURE target with Red Mage.
Expected Result:
- result.attacker_atk_used == 20 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 20)

---

Card Name: Silver Spearman
Type: Character
Stats: ATK=25 DEF=20 Cost=250 Affinity=ANIMA
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'bonus': 5}
Description: +5 ATK vs Chaos
Test Cases:

Test Case ID: TC-FUNC-Silver-Spearman-001
Description:
Silver Spearman: effective ATK +5 vs CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=CHAOS, bonus=5
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Silver Spearman (base ATK 25) face-up.
- Defender: any CHAOS character with DEF < 30.
Steps:
Step 1: Call BattleResolver.resolve_battle(Silver Spearman, CHAOS defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 30 (base 25 + bonus 5).
- result.attacker_atk_delta == 5.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 30)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Silver-Spearman-002
Description:
Silver Spearman: no bonus vs non-CHAOS defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != CHAOS (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-CHAOS target with Silver Spearman.
Expected Result:
- result.attacker_atk_used == 25 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 25)

---

Card Name: Street Rogue
Type: Character
Stats: ATK=25 DEF=20 Cost=350 Affinity=ANIMA
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ANIMA', 'bonus': 20}
Description: +20 ATK against Anima card
Test Cases:

Test Case ID: TC-FUNC-Street-Rogue-001
Description:
Street Rogue: effective ATK +20 vs ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=ANIMA, bonus=20
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Street Rogue (base ATK 25) face-up.
- Defender: any ANIMA character with DEF < 45.
Steps:
Step 1: Call BattleResolver.resolve_battle(Street Rogue, ANIMA defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 45 (base 25 + bonus 20).
- result.attacker_atk_delta == 20.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 45)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Street-Rogue-002
Description:
Street Rogue: no bonus vs non-ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != ANIMA (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-ANIMA target with Street Rogue.
Expected Result:
- result.attacker_atk_used == 25 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 25)

---

Card Name: Venospore Pod
Type: Character
Stats: ATK=10 DEF=20 Cost=180 Affinity=BIO
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'bonus': 20}
Description: +20 ATK vs Nature.
Test Cases:

Test Case ID: TC-FUNC-Venospore-Pod-001
Description:
Venospore Pod: effective ATK +20 vs NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=NATURE, bonus=20
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Venospore Pod (base ATK 10) face-up.
- Defender: any NATURE character with DEF < 30.
Steps:
Step 1: Call BattleResolver.resolve_battle(Venospore Pod, NATURE defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 30 (base 10 + bonus 20).
- result.attacker_atk_delta == 20.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 30)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Venospore-Pod-002
Description:
Venospore Pod: no bonus vs non-NATURE defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != NATURE (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-NATURE target with Venospore Pod.
Expected Result:
- result.attacker_atk_used == 10 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 10)

---

Card Name: Warfare Bear
Type: Character
Stats: ATK=50 DEF=50 Cost=800 Affinity=NATURE
AbilityType: ATK_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ANIMA', 'bonus': 50}
Description: +50 ATK vs Anima
Test Cases:

Test Case ID: TC-FUNC-Warfare-Bear-001
Description:
Warfare Bear: effective ATK +50 vs ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- CharacterData.AbilityType.ATK_BONUS_VS_AFFINITY
- ability_params: affinity=ANIMA, bonus=50
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Attacker Warfare Bear (base ATK 50) face-up.
- Defender: any ANIMA character with DEF < 100.
Steps:
Step 1: Call BattleResolver.resolve_battle(Warfare Bear, ANIMA defender, dice_roll=3, ...).
Step 2: Inspect battle overlay / result.attacker_atk_used.
Expected Result:
- result.attacker_atk_used == 100 (base 50 + bonus 50).
- result.attacker_atk_delta == 50.
- Defender destroyed when effective ATK > DEF.
Verification (automated):
- assert_eq(result.attacker_atk_used, 100)
- assert_true(result.defender_destroyed)

Test Case ID: TC-FUNC-Warfare-Bear-002
Description:
Warfare Bear: no bonus vs non-ANIMA defender
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATK_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity != ANIMA (e.g. ANIMA Wandering Swordsman).
Steps:
Step 1: Attack non-ANIMA target with Warfare Bear.
Expected Result:
- result.attacker_atk_used == 50 (no affinity bonus).
- result.attacker_atk_delta == 0.
Verification (automated):
- assert_eq(result.attacker_atk_used, 50)

---

Card Name: Satellite Cannon
Type: Character
Stats: ATK=100 DEF=80 Cost=1100 Affinity=COSMIC
AbilityType: ATK_BONUS_VS_CENTER_ZONE
ability_params: {'bonus': 20, 'center_bonus': 40}
Description: +20 ATK if attacking the 3x3 center zone. +40 more ATK if attacking the very center cell.
Test Cases:

Test Case ID: TC-FUNC-Satellite-Cannon-001
Description:
Satellite Cannon: center zone ATK bonuses (+20 3×3, +40 at 2,2)
Implementation Reference:
- BattleResolver._get_effective_atk() uses target_pos
- AbilityType.ATK_BONUS_VS_CENTER_ZONE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Satellite Cannon on field; attack opponent cells at edge, center-zone, and (2,2).
Steps:
Step 1: Pass target_pos to resolve_battle; compare attacker_atk_used each time.
Expected Result:
- Edge target: attacker_atk_used == 100.
- Center zone (not 2,2): attacker_atk_used == 120.
- Cell (2,2): attacker_atk_used == 160.

---

Card Name: Skeleton Archer
Type: Character
Stats: ATK=35 DEF=5 Cost=300 Affinity=CHAOS
AbilityType: ATK_BONUS_VS_FACEDOWN
ability_params: {'bonus': 5}
Description: +5 ATK vs face-down Defender
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Archer-001
Description:
Skeleton Archer: +5 ATK vs face-down defender
Implementation Reference:
- BattleResolver._get_effective_atk() checks not defender.face_up
- AbilityType.ATK_BONUS_VS_FACEDOWN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender remains face-down at calculation time (Skeleton Archer scenario).
Steps:
Step 1: Attack face-down cell with Skeleton Archer.
Expected Result:
- If defender.face_up==false at calc: attacker_atk_used == 40.

---

Card Name: Spell Sniper
Type: Character
Stats: ATK=20 DEF=50 Cost=700 Affinity=ARCANE
AbilityType: ATK_BONUS_VS_FACEDOWN
ability_params: {'bonus': 50}
Description: +50 ATK vs face-down card
Test Cases:

Test Case ID: TC-FUNC-Spell-Sniper-001
Description:
Spell Sniper: +50 ATK vs face-down defender
Implementation Reference:
- BattleResolver._get_effective_atk() checks not defender.face_up
- AbilityType.ATK_BONUS_VS_FACEDOWN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender remains face-down at calculation time (Skeleton Archer scenario).
Steps:
Step 1: Attack face-down cell with Spell Sniper.
Expected Result:
- If defender.face_up==false at calc: attacker_atk_used == 70.

---

Card Name: Nova Angel
Type: Character
Stats: ATK=50 DEF=25 Cost=650 Affinity=DIVINE
AbilityType: ATK_BONUS_VS_TWO_AFFINITIES
ability_params: {'aff1': 'ARCANE', 'aff2': 'COSMIC', 'bonus': 25, 'def_bonus': 25}
Description: +25 ATK&DEF vs Arcane and Cosmic
Test Cases:

Test Case ID: TC-FUNC-Nova-Angel-001
Description:
Nova Angel: ability ATK_BONUS_VS_TWO_AFFINITIES functional smoke test
Implementation Reference:
- CharacterData.AbilityType.ATK_BONUS_VS_TWO_AFFINITIES
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'aff1': 'ARCANE', 'aff2': 'COSMIC', 'bonus': 25, 'def_bonus': 25}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +25 ATK&DEF vs Arcane and Cosmic

---

Card Name: Kiyoko the Death Whisper
Type: Character
Stats: ATK=40 DEF=35 Cost=800 Affinity=ANIMA
AbilityType: ATK_BONUS_VS_UNION
ability_params: {'bonus': 50}
Description: This card gains +50 ATK when attacking Union card
Test Cases:

Test Case ID: TC-FUNC-Kiyoko-the-Death-Whisper-001
Description:
Kiyoko the Death Whisper: +50 ATK vs Union
Implementation Reference:
- BattleResolver._get_effective_atk() checks defender.is_union
- AbilityType.ATK_BONUS_VS_UNION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent has face-up Union (e.g. Gryphon Rider).
Steps:
Step 1: Attack Union with Kiyoko the Death Whisper.
Expected Result:
- attacker_atk_used == 90.

---

Card Name: Giant Centipede
Type: Character
Stats: ATK=20 DEF=20 Cost=850 Affinity=NATURE
AbilityType: ATK_BONUS_VS_VENOM
ability_params: {'bonus': 100}
Description: +100 ATK vs cards with venom flag
Test Cases:

Test Case ID: TC-FUNC-Giant-Centipede-001
Description:
Giant Centipede: +100 ATK vs venom-flagged target
Implementation Reference:
- BattleResolver._get_effective_atk() checks 'venom' in defender.flags
- AbilityType.ATK_BONUS_VS_VENOM
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Set defender.flags = ["venom"] (via Death Cobra end-of-turn).
Steps:
Step 1: Attack flagged defender with Giant Centipede.
Expected Result:
- attacker_atk_used == 120.

---

Card Name: Void Stalker
Type: Character
Stats: ATK=65 DEF=25 Cost=720 Affinity=CHAOS
AbilityType: ATK_BOOST_VS_REVEALED
ability_params: {'bonus': 20}
Description: +20 ATK if it attacks an exposed card.
Test Cases:

Test Case ID: TC-FUNC-Void-Stalker-001
Description:
Void Stalker: +20 ATK vs exposed defender
Implementation Reference:
- BattleResolver._get_effective_atk() checks defender.face_up
- AbilityType.ATK_BOOST_VS_REVEALED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender was face-up before attack (defender_was_exposed=true).
Steps:
Step 1: Attack revealed defender with Void Stalker.
Expected Result:
- attacker_atk_used == 85.

---

Card Name: Slim Gray Tank
Type: Character
Stats: ATK=30 DEF=30 Cost=1000 Affinity=COSMIC
AbilityType: ATK_DEF_BONUS_IF_OWN_REVEALED_GTE
ability_params: {'per_revealed': True, 'atk': 10, 'def': 10}
Description: +10 ATK/DEF per revealed cell on your side
Test Cases:

Test Case ID: TC-FUNC-Slim-Gray-Tank-001
Description:
Slim Gray Tank: +10/+10 if ≥15 own cells revealed
Implementation Reference:
- BattleResolver ATK_DEF_BONUS_IF_OWN_REVEALED_GTE
- AbilityType.ATK_DEF_BONUS_IF_OWN_REVEALED_GTE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Reveal ≥15 cells on own grid (including dead_ends face-up).
Steps:
Step 1: Battle with card.
Expected Result:
- Stats include +10 ATK / +10 DEF when threshold met.

---

Card Name: Slim Gray Trooper
Type: Character
Stats: ATK=45 DEF=45 Cost=800 Affinity=COSMIC
AbilityType: ATK_DEF_BONUS_IF_OWN_REVEALED_GTE
ability_params: {'min_revealed': 10, 'atk': 30, 'def': 30}
Description: +65 ATK&DEF if 10 or more cells on your side are revealed
Test Cases:

Test Case ID: TC-FUNC-Slim-Gray-Trooper-001
Description:
Slim Gray Trooper: +30/+30 if ≥10 own cells revealed
Implementation Reference:
- BattleResolver ATK_DEF_BONUS_IF_OWN_REVEALED_GTE
- AbilityType.ATK_DEF_BONUS_IF_OWN_REVEALED_GTE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Reveal ≥10 cells on own grid (including dead_ends face-up).
Steps:
Step 1: Battle with card.
Expected Result:
- Stats include +30 ATK / +30 DEF when threshold met.

---

Card Name: Aerial the Battlemage
Type: Character
Stats: ATK=50 DEF=45 Cost=750 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_IF_UNION_ON_FIELD
ability_params: {'atk': 20, 'def': 20}
Description: +20 ATK&DEF if there is Union card on your side
Test Cases:

Test Case ID: TC-FUNC-Aerial-the-Battlemage-001
Description:
Aerial the Battlemage: +20/+20 when Union on own field
Implementation Reference:
- BattleResolver._get_effective_atk() checks is_union face-up ally
- AbilityType.ATK_DEF_BONUS_IF_UNION_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Summon or place face-up Union on attacker's field.
Steps:
Step 1: Attack with Aerial the Battlemage.
Expected Result:
- attacker_atk_used == 70; effective DEF bonus 20 when defending.

---

Card Name: Dragoon
Type: Character
Stats: ATK=20 DEF=20 Cost=380 Affinity=ANIMA
AbilityType: ATK_DEF_BONUS_IF_UNION_ON_FIELD
ability_params: {'name_contains': 'Dragon', 'atk': 40, 'def': 40}
Description: +40 ATK&DEF if there is another “Dragon” card on your field
Test Cases:

Test Case ID: TC-FUNC-Dragoon-001
Description:
Dragoon: +40/+40 when Union on own field
Implementation Reference:
- BattleResolver._get_effective_atk() checks is_union face-up ally
- AbilityType.ATK_DEF_BONUS_IF_UNION_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Summon or place face-up Union on attacker's field.
Steps:
Step 1: Attack with Dragoon.
Expected Result:
- attacker_atk_used == 60; effective DEF bonus 40 when defending.

---

Card Name: Mighty Genie
Type: Character
Stats: ATK=20 DEF=15 Cost=200 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_IF_UNION_ON_FIELD
ability_params: {'affinity': 'ARCANE', 'atk': 5, 'def': 5}
Description: +5 ATK&DEF is there is Arcane ally on its side
Test Cases:

Test Case ID: TC-FUNC-Mighty-Genie-001
Description:
Mighty Genie: +5/+5 when Union on own field
Implementation Reference:
- BattleResolver._get_effective_atk() checks is_union face-up ally
- AbilityType.ATK_DEF_BONUS_IF_UNION_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Summon or place face-up Union on attacker's field.
Steps:
Step 1: Attack with Mighty Genie.
Expected Result:
- attacker_atk_used == 25; effective DEF bonus 5 when defending.

---

Card Name: Apprentice Mage
Type: Character
Stats: ATK=20 DEF=20 Cost=220 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ARCANE', 'atk': 5, 'def': 5}
Description: +5 ATK&DEF vs Non-Arcane
Test Cases:

Test Case ID: TC-FUNC-Apprentice-Mage-001
Description:
Apprentice Mage: +5 ATK / +5 DEF vs ARCANE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Apprentice Mage (ATK 20) vs ARCANE defender; or Apprentice Mage defends vs ARCANE attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 25.
- Defending: defender_def_used == 25 when Apprentice Mage is defender.

---

Card Name: Book with Fangs
Type: Character
Stats: ATK=45 DEF=55 Cost=800 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ARCANE', 'atk': 30, 'def': 30}
Description: +30 ATK&DEF vs Arcane
Test Cases:

Test Case ID: TC-FUNC-Book-with-Fangs-001
Description:
Book with Fangs: +30 ATK / +30 DEF vs ARCANE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Book with Fangs (ATK 45) vs ARCANE defender; or Book with Fangs defends vs ARCANE attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 75.
- Defending: defender_def_used == 85 when Book with Fangs is defender.

---

Card Name: Flame Lizard
Type: Character
Stats: ATK=25 DEF=40 Cost=400 Affinity=NATURE
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'atk': 20, 'def': 20}
Description: +20 ATK&DEF vs Nature
Test Cases:

Test Case ID: TC-FUNC-Flame-Lizard-001
Description:
Flame Lizard: +20 ATK / +20 DEF vs NATURE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Flame Lizard (ATK 25) vs NATURE defender; or Flame Lizard defends vs NATURE attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 45.
- Defending: defender_def_used == 60 when Flame Lizard is defender.

---

Card Name: Gamma Emitter
Type: Character
Stats: ATK=20 DEF=15 Cost=220 Affinity=BIO
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'atk': 10, 'def': 10, 'mutagen_atk': 5}
Description: +10 ATK&DEF vs Nature. With Mutagen Flag : +5 ATK
Test Cases:

Test Case ID: TC-FUNC-Gamma-Emitter-001
Description:
Gamma Emitter: +10 ATK / +10 DEF vs NATURE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Gamma Emitter (ATK 20) vs NATURE defender; or Gamma Emitter defends vs NATURE attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 30.
- Defending: defender_def_used == 25 when Gamma Emitter is defender.

---

Card Name: Lady of the Sacred Pond
Type: Character
Stats: ATK=25 DEF=35 Cost=450 Affinity=DIVINE
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ANIMA', 'atk': 20, 'def': 20, 'choice_affinity': 'CHAOS'}
Description: Once exposed, choose either : +20 ATK&DEF vs Anima, or +20 ATK&DEF vs Chaos
Test Cases:

Test Case ID: TC-FUNC-Lady-of-the-Sacred-Pond-001
Description:
Lady of the Sacred Pond: +20 ATK / +20 DEF vs ANIMA
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Lady of the Sacred Pond (ATK 25) vs ANIMA defender; or Lady of the Sacred Pond defends vs ANIMA attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 45.
- Defending: defender_def_used == 55 when Lady of the Sacred Pond is defender.

---

Card Name: Mind Flayer
Type: Character
Stats: ATK=100 DEF=70 Cost=1500 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ANIMA', 'atk': 50, 'def': 50}
Description: +50 ATK&DEF against Anima
Test Cases:

Test Case ID: TC-FUNC-Mind-Flayer-001
Description:
Mind Flayer: +50 ATK / +50 DEF vs ANIMA
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Mind Flayer (ATK 100) vs ANIMA defender; or Mind Flayer defends vs ANIMA attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 150.
- Defending: defender_def_used == 120 when Mind Flayer is defender.

---

Card Name: Nunchuck Nun
Type: Character
Stats: ATK=25 DEF=15 Cost=320 Affinity=DIVINE
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'atk': 5, 'def': 5}
Description: + 5 ATK&DEF vs Chaos card
Test Cases:

Test Case ID: TC-FUNC-Nunchuck-Nun-001
Description:
Nunchuck Nun: +5 ATK / +5 DEF vs CHAOS
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Nunchuck Nun (ATK 25) vs CHAOS defender; or Nunchuck Nun defends vs CHAOS attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 30.
- Defending: defender_def_used == 20 when Nunchuck Nun is defender.

---

Card Name: Randez the Rogue King
Type: Character
Stats: ATK=60 DEF=60 Cost=100 Affinity=ANIMA
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'target': 'union', 'atk': 100, 'def': 100, 'penalty_vs_affinity': "{'affinity': 'ANIMA'"}
Description: +100 ATK&DEF vs Union cards. -30 ATK&DEF vs Anima cards.
Test Cases:

Test Case ID: TC-FUNC-Randez-the-Rogue-King-001
Description:
Randez the Rogue King: +100 ATK / +100 DEF vs ?
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Randez the Rogue King (ATK 60) vs ? defender; or Randez the Rogue King defends vs ? attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 160.
- Defending: defender_def_used == 160 when Randez the Rogue King is defender.

---

Card Name: Vicmark the Sky Overlord
Type: Character
Stats: ATK=60 DEF=60 Cost=1100 Affinity=ANIMA
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'target': 'union_zone', 'atk': 90, 'def': 90, 'requires_union_summon': True}
Description: After foe have ever performed Union summon, this card gain +90 ATK&DEF vs unit within foe’s Union Zone
Test Cases:

Test Case ID: TC-FUNC-Vicmark-the-Sky-Overlord-001
Description:
Vicmark the Sky Overlord: +90 ATK / +90 DEF vs ?
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Vicmark the Sky Overlord (ATK 60) vs ? defender; or Vicmark the Sky Overlord defends vs ? attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 150.
- Defending: defender_def_used == 150 when Vicmark the Sky Overlord is defender.

---

Card Name: Witchhunter
Type: Character
Stats: ATK=20 DEF=20 Cost=250 Affinity=ANIMA
AbilityType: ATK_DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'ARCANE', 'atk': 5, 'def': 5}
Description: +5 ATK&DEF vs Arcane
Test Cases:

Test Case ID: TC-FUNC-Witchhunter-001
Description:
Witchhunter: +5 ATK / +5 DEF vs ARCANE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Witchhunter (ATK 20) vs ARCANE defender; or Witchhunter defends vs ARCANE attacker.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking: attacker_atk_used == 25.
- Defending: defender_def_used == 25 when Witchhunter is defender.

---

Card Name: Cullan the Magic Swordsman
Type: Character
Stats: ATK=25 DEF=10 Cost=240 Affinity=ARCANE
AbilityType: ATK_DEF_BONUS_VS_NON_AFFINITY
ability_params: {'affinity': 'ARCANE', 'atk': 10, 'def': 10, 'once_exposed': True, 'coin_flip': True}
Description: Once exposed, flip a coin. Heads: +10 ATK&DEF vs Non-Arcane
Test Cases:

Test Case ID: TC-FUNC-Cullan-the-Magic-Swordsman-001
Description:
Cullan the Magic Swordsman: +10 ATK/DEF vs non-ARCANE
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent character affinity != ARCANE.
Steps:
Step 1: Attack or defend with Cullan the Magic Swordsman.
Expected Result:
- When opponent affinity != ARCANE: +10 to ATK (attack) or DEF (defend).

---

Card Name: Ox Patrol
Type: Character
Stats: ATK=30 DEF=35 Cost=420 Affinity=ANIMA
AbilityType: ATK_DEF_BONUS_VS_NON_AFFINITY
ability_params: {'affinity': 'ANIMA', 'atk': 10, 'def': 10}
Description: +10 ATK&DEF vs Non-Anima
Test Cases:

Test Case ID: TC-FUNC-Ox-Patrol-001
Description:
Ox Patrol: +10 ATK/DEF vs non-ANIMA
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_NON_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent character affinity != ANIMA.
Steps:
Step 1: Attack or defend with Ox Patrol.
Expected Result:
- When opponent affinity != ANIMA: +10 to ATK (attack) or DEF (defend).

---

Card Name: Vicious Lizard
Type: Character
Stats: ATK=40 DEF=25 Cost=1100 Affinity=NATURE
AbilityType: ATK_DEF_BONUS_VS_VENOM
ability_params: {'atk': 60, 'def': 60, 'self_venom_atk': 40}
Description: +60 ATK&DEF vs foe with Venom Flag. +40 ATK if itself has Venom Flag
Test Cases:

Test Case ID: TC-FUNC-Vicious-Lizard-001
Description:
Vicious Lizard: +60 ATK&DEF vs venom foe; +40 ATK if self has venom
Implementation Reference:
- BattleResolver._get_effective_atk/_get_effective_def
- AbilityType.ATK_DEF_BONUS_VS_VENOM
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent has venom flag and/or self has venom flag.
Steps:
Step 1: Resolve battle; read effective stats.
Expected Result:
- Attacking venom foe: +60 ATK.
- Defending vs venom attacker: +60 DEF.
- Self venom flag: +40 ATK when attacking.

---

Card Name: Moon Tribe Marksman
Type: Character
Stats: ATK=35 DEF=25 Cost=300 Affinity=COSMIC
AbilityType: ATK_PENALTY_IF_NO_NAME_ALLY
ability_params: {'name_contains': 'Moon', 'penalty': 10}
Description: If no other exposed ally Moon card, -10 ATK
Test Cases:

Test Case ID: TC-FUNC-Moon-Tribe-Marksman-001
Description:
Moon Tribe Marksman: -10 ATK if no ally name contains 'Moon'
Implementation Reference:
- BattleResolver._get_effective_atk ATK_PENALTY_IF_NO_NAME_ALLY
- AbilityType.ATK_PENALTY_IF_NO_NAME_ALLY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- No other card with matching name on field.
Steps:
Step 1: Attack with Moon Tribe Marksman.
Expected Result:
- attacker_atk_used == 25.

---

Card Name: Sniping Fairy
Type: Character
Stats: ATK=40 DEF=20 Cost=350 Affinity=DIVINE
AbilityType: ATK_PENALTY_WHEN_EXPOSED
ability_params: {'penalty': 20}
Description: After it becomes exposed, -20 ATK at that turn’s end.
Test Cases:

Test Case ID: TC-FUNC-Sniping-Fairy-001
Description:
Sniping Fairy: -20 ATK while face-up
Implementation Reference:
- BattleResolver._get_effective_atk() when attacker.face_up
- AbilityType.ATK_PENALTY_WHEN_EXPOSED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Sniping Fairy face-up on field.
Steps:
Step 1: Attack any target.
Expected Result:
- attacker_atk_used == max(0, 40 - 20) == 20.

---

Card Name: Mephisto the Fallen
Type: Character
Stats: ATK=75 DEF=0 Cost=860 Affinity=DIVINE
AbilityType: ATK_ZERO_AFTER_WIN
ability_params: {}
Description: After this card attacked unit successfully, its ATK becomes 0 permanently
Test Cases:

Test Case ID: TC-FUNC-Mephisto-the-Fallen-001
Description:
Mephisto the Fallen: ATK→0 permanently after winning battle
Implementation Reference:
- TurnManager._apply_post_battle_effects when defender_destroyed
- AbilityType.ATK_ZERO_AFTER_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mephisto the Fallen wins attack.
Steps:
Step 1: Destroy defender.
Expected Result:
- current_atk == 0 after battle.

---

Card Name: Toxin Folk
Type: Character
Stats: ATK=25 DEF=25 Cost=350 Affinity=BIO
AbilityType: ATTACKER_ATK_DEBUFF
ability_params: {'amount': 5, 'when_exposed': True, 'foe_attackers': True, 'temp_until_foe_turn': True}
Description: While this card is exposed, foe that perform attack get -5 ATK until the end of foe’s turn.
Test Cases:

Test Case ID: TC-FUNC-Toxin-Folk-001
Description:
Toxin Folk: debuff attacker ATK by 5 during battle
Implementation Reference:
- BattleResolver._get_effective_atk() defender branch
- AbilityType.ATTACKER_ATK_DEBUFF
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Toxin Folk defends; attacker ATK > 25.
Steps:
Step 1: Resolve battle.
Expected Result:
- Attacker effective ATK reduced by 5 (unless effect_nullified_until active).
- GameState.post_message contains 'Attacker loses N ATK'.

---

Card Name: White Tiger
Type: Character
Stats: ATK=40 DEF=25 Cost=450 Affinity=NATURE
AbilityType: ATTACKER_ATK_DEBUFF
ability_params: {'amount': 15}
Description: In Reckoning, -15 ATK to the attacker
Test Cases:

Test Case ID: TC-FUNC-White-Tiger-001
Description:
White Tiger: debuff attacker ATK by 15 during battle
Implementation Reference:
- BattleResolver._get_effective_atk() defender branch
- AbilityType.ATTACKER_ATK_DEBUFF
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- White Tiger defends; attacker ATK > 25.
Steps:
Step 1: Resolve battle.
Expected Result:
- Attacker effective ATK reduced by 15 (unless effect_nullified_until active).
- GameState.post_message contains 'Attacker loses N ATK'.

---

Card Name: Battle Maid Midori
Type: Character
Stats: ATK=30 DEF=100 Cost=900 Affinity=ANIMA
AbilityType: ATTACK_STANCE_BOOST
ability_params: {'affinity': 'ANIMA', 'atk': 100, 'per_turn': True, 'intercept_anima': True}
Description: Once per turn, Anima ally get +100 ATK in Reckoning. You can flip this card face-up if other Anima unit is targeted for attack.
Test Cases:

Test Case ID: TC-FUNC-Battle-Maid-Midori-001
Description:
Battle Maid Midori: +100 ATK in attack stance
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATTACK_STANCE_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Maid Midori attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == 130.

---

Card Name: Da Loong
Type: Character
Stats: ATK=40 DEF=20 Cost=1100 Affinity=DIVINE
AbilityType: ATTACK_STANCE_BOOST
ability_params: {'atk': 60, 'def': 60, 'when_exposed': True}
Description: +60 ATK&DEF if exposed
Test Cases:

Test Case ID: TC-FUNC-Da-Loong-001
Description:
Da Loong: +60 ATK in attack stance
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATTACK_STANCE_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Da Loong attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == 100.

---

Card Name: Epsilon The Wither
Type: Character
Stats: ATK=80 DEF=50 Cost=850 Affinity=BIO
AbilityType: ATTACK_STANCE_BOOST
ability_params: {'atk': 40, 'def': 40, 'debuff_allies': 10}
Description: At Reckoning, +40 ATK&DEF until this turn ends, but all ally units lose 10 ATK&DEF until this turn ends
Test Cases:

Test Case ID: TC-FUNC-Epsilon-The-Wither-001
Description:
Epsilon The Wither: +40 ATK in attack stance
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATTACK_STANCE_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Epsilon The Wither attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == 120.

---

Card Name: Mole Scout
Type: Character
Stats: ATK=25 DEF=10 Cost=340 Affinity=NATURE
AbilityType: ATTACK_STANCE_BOOST
ability_params: {'atk': 15, 'when_facedown_attack': True, 'temp': True}
Description: If this card was commanded to attack while being face-down, it gains 15 ATK until the end of this turn.
Test Cases:

Test Case ID: TC-FUNC-Mole-Scout-001
Description:
Mole Scout: +15 ATK in attack stance
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATTACK_STANCE_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mole Scout attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == 40.

---

Card Name: Sunrise Lady
Type: Character
Stats: ATK=20 DEF=30 Cost=300 Affinity=DIVINE
AbilityType: ATTACK_STANCE_BOOST
ability_params: {'atk': 10}
Description: If it attacks: +10 ATK,-10 DEF permanently (if possible)
Test Cases:

Test Case ID: TC-FUNC-Sunrise-Lady-001
Description:
Sunrise Lady: +10 ATK in attack stance
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATTACK_STANCE_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Sunrise Lady attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == 30.

---

Card Name: White Knight
Type: Character
Stats: ATK=40 DEF=35 Cost=560 Affinity=ANIMA
AbilityType: ATTACK_STANCE_BOOST
ability_params: {'when_facedown_attack': True, 'attacks_at_zero_count': True}
Description: While you have 0 attacks count, you can command this face-down card to attack.
Test Cases:

Test Case ID: TC-FUNC-White-Knight-001
Description:
White Knight: +0 ATK in attack stance
Implementation Reference:
- BattleResolver._get_effective_atk()
- AbilityType.ATTACK_STANCE_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- White Knight attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == 40.

---

Card Name: Leorudus the Warlord
Type: Character
Stats: ATK=80 DEF=80 Cost=1150 Affinity=ANIMA
AbilityType: BOOST_PER_ANIMA_ON_FIELD
ability_params: {'atk_bonus': 20, 'def_bonus': 20}
Description: +20 ATK&DEF for each other exposed Anima card on your side
Test Cases:

Test Case ID: TC-FUNC-Leorudus-the-Warlord-001
Description:
Leorudus the Warlord: +20/+20 per other face-up Anima on field
Implementation Reference:
- BattleResolver._count_anima_cards()
- AbilityType.BOOST_PER_ANIMA_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- 2 other face-up Anima characters on field.
Steps:
Step 1: calculate_field_bonuses then battle.
Expected Result:
- With 2 anima allies: perm_atk_bonus==40, perm_def_bonus==40.

---

Card Name: Azaxuna the Fallen
Type: Character
Stats: ATK=90 DEF=90 Cost=1500 Affinity=DIVINE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'affinity': 'CHAOS', 'atk_bonus': 20, 'def_bonus': 20, 'field_scope': 'owner'}
Description: +20 ATK&DEF for each Chaos card on your side.
Test Cases:

Test Case ID: TC-FUNC-Azaxuna-the-Fallen-001
Description:
Azaxuna the Fallen: field passive +20 ATK / +20 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: CHAOS) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Azaxuna the Fallen.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 20 × matching_count.
- perm_def_bonus == 20 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Death Knight
Type: Character
Stats: ATK=65 DEF=65 Cost=850 Affinity=CHAOS
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 5, 'def_bonus': 0, 'affinity': 'CHAOS'}
Description: +5 ATK per Chaos unit on your side. +5 DEF per Chaos unit in your void.
Test Cases:

Test Case ID: TC-FUNC-Death-Knight-001
Description:
Death Knight: field passive +5 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: CHAOS) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Death Knight.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 5 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Drifting Head
Type: Character
Stats: ATK=10 DEF=10 Cost=240 Affinity=CHAOS
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'affinity': 'CHAOS', 'atk_bonus': 5, 'def_bonus': 0, 'field_scope': 'owner'}
Description: +5 ATK for each Chaos ally. This bonus does not exceed 20
Test Cases:

Test Case ID: TC-FUNC-Drifting-Head-001
Description:
Drifting Head: field passive +5 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: CHAOS) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Drifting Head.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 5 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Evil Chef
Type: Character
Stats: ATK=30 DEF=20 Cost=300 Affinity=CHAOS
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'affinities': ['ANIMA'], 'atk_bonus': 5, 'def_bonus': 5, 'field_scope': 'foe', 'exposed_only': True}
Description: +5 ATK&DEF for each exposed Anima or Nature cards on foe’s side
Test Cases:

Test Case ID: TC-FUNC-Evil-Chef-001
Description:
Evil Chef: field passive +5 ATK / +5 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: ) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Evil Chef.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 5 × matching_count.
- perm_def_bonus == 5 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Halo Guardian
Type: Character
Stats: ATK=35 DEF=35 Cost=450 Affinity=DIVINE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'affinity': 'CHAOS', 'atk_bonus': 5, 'def_bonus': 5, 'field_scope': 'foe', 'exposed_only': True}
Description: +5 ATK&DEF for each exposed Chaos unit on foe’s side
Test Cases:

Test Case ID: TC-FUNC-Halo-Guardian-001
Description:
Halo Guardian: field passive +5 ATK / +5 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: CHAOS) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Halo Guardian.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 5 × matching_count.
- perm_def_bonus == 5 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Hammer Shark
Type: Character
Stats: ATK=20 DEF=20 Cost=250 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark', 'field_scope': 'all'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Hammer-Shark-001
Description:
Hammer Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Hammer Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Ice Lich
Type: Character
Stats: ATK=80 DEF=80 Cost=1250 Affinity=CHAOS
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'affinity': 'ARCANE', 'atk_bonus': 15, 'def_bonus': 15, 'field_scope': 'owner'}
Description: +15 ATK&DEF for each Arcane card on your side.
Test Cases:

Test Case ID: TC-FUNC-Ice-Lich-001
Description:
Ice Lich: field passive +15 ATK / +15 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: ARCANE) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Ice Lich.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 15 × matching_count.
- perm_def_bonus == 15 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Jill the Merciful Priestess
Type: Character
Stats: ATK=0 DEF=0 Cost=800 Affinity=DIVINE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'affinity': 'DIVINE', 'atk_bonus': 20, 'def_bonus': 20, 'field_scope': 'owner', 'exposed_only': True}
Description: +20 ATK&DEF for each exposed Divine cards on your side
Test Cases:

Test Case ID: TC-FUNC-Jill-the-Merciful-Priestess-001
Description:
Jill the Merciful Priestess: field passive +20 ATK / +20 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: DIVINE) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Jill the Merciful Priestess.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 20 × matching_count.
- perm_def_bonus == 20 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Kulu the Alpha Leader
Type: Character
Stats: ATK=25 DEF=25 Cost=500 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'affinity': 'NATURE', 'atk_bonus': 10, 'def_bonus': 0, 'field_scope': 'owner'}
Description: +10 ATK for each Nature card on your side.
Test Cases:

Test Case ID: TC-FUNC-Kulu-the-Alpha-Leader-001
Description:
Kulu the Alpha Leader: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: NATURE) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Kulu the Alpha Leader.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Night Dweller
Type: Character
Stats: ATK=15 DEF=15 Cost=260 Affinity=CHAOS
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'field_scope': 'void', 'min_void': 3, 'atk_bonus': 10, 'def_bonus': 10}
Description: +10 ATK&DEF if there is 3 or more units in your void.
Test Cases:

Test Case ID: TC-FUNC-Night-Dweller-001
Description:
Night Dweller: field passive +10 ATK / +10 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: ) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Night Dweller.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 10 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Night Whisperer
Type: Character
Stats: ATK=30 DEF=30 Cost=900 Affinity=CHAOS
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 30, 'def_bonus': 30, 'card_name_contains': 'wisp'}
Description: +30 ATK&DEF for each exposed ‘wisp’ card on your side
Test Cases:

Test Case ID: TC-FUNC-Night-Whisperer-001
Description:
Night Whisperer: field passive +30 ATK / +30 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: wisp) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Night Whisperer.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 30 × matching_count.
- perm_def_bonus == 30 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Parasite Titan
Type: Character
Stats: ATK=0 DEF=0 Cost=1050 Affinity=COSMIC
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'affinity': 'COSMIC', 'atk_bonus': 50, 'def_bonus': 50, 'mutagen': True, 'exposed_only': True}
Description: With Mutagen Flag : This card gain 50 ATK&DEF for each face-up Cosmic card on the field
Test Cases:

Test Case ID: TC-FUNC-Parasite-Titan-001
Description:
Parasite Titan: field passive +50 ATK / +50 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: COSMIC) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Parasite Titan.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 50 × matching_count.
- perm_def_bonus == 50 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Saw Shark
Type: Character
Stats: ATK=25 DEF=10 Cost=280 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark', 'field_scope': 'all'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Saw-Shark-001
Description:
Saw Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Saw Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Scythe Shark
Type: Character
Stats: ATK=35 DEF=35 Cost=550 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark', 'field_scope': 'all'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Scythe-Shark-001
Description:
Scythe Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Scythe Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Shotgun Shark
Type: Character
Stats: ATK=75 DEF=25 Cost=900 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark', 'field_scope': 'all'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Shotgun-Shark-001
Description:
Shotgun Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Shotgun Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Soul Overlord
Type: Character
Stats: ATK=40 DEF=40 Cost=1600 Affinity=CHAOS
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'field_scope': 'both_void', 'atk_bonus': 15, 'def_bonus': 0}
Description: +15 ATK for each card in both player’s void
Test Cases:

Test Case ID: TC-FUNC-Soul-Overlord-001
Description:
Soul Overlord: field passive +15 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: ) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Soul Overlord.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 15 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Spear Shark
Type: Character
Stats: ATK=50 DEF=20 Cost=480 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 10, 'def_bonus': 0, 'card_name_contains': 'shark', 'field_scope': 'all'}
Description: +10 ATK per shark card on the field
Test Cases:

Test Case ID: TC-FUNC-Spear-Shark-001
Description:
Spear Shark: field passive +10 ATK / +0 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: shark) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Spear Shark.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 10 × matching_count.
- perm_def_bonus == 0 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Swarmcaller
Type: Character
Stats: ATK=45 DEF=45 Cost=950 Affinity=NATURE
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 15, 'def_bonus': 15, 'affinity': 'NATURE'}
Description: +15 ATK&DEF for each other exposed Nature card on your side
Test Cases:

Test Case ID: TC-FUNC-Swarmcaller-001
Description:
Swarmcaller: field passive +15 ATK / +15 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: NATURE) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Swarmcaller.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 15 × matching_count.
- perm_def_bonus == 15 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Uproaring Warband
Type: Character
Stats: ATK=30 DEF=15 Cost=280 Affinity=ANIMA
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'atk_bonus': 5, 'def_bonus': 5, 'affinity': 'ANIMA'}
Description: +5 ATK&DEF for each exposed ally Anima on your side
Test Cases:

Test Case ID: TC-FUNC-Uproaring-Warband-001
Description:
Uproaring Warband: field passive +5 ATK / +5 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: ANIMA) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Uproaring Warband.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 5 × matching_count.
- perm_def_bonus == 5 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Urban Zombie
Type: Character
Stats: ATK=25 DEF=0 Cost=300 Affinity=BIO
AbilityType: BOOST_PER_TYPED_CARD_ON_FIELD
ability_params: {'name_contains': 'Zombie', 'atk_bonus': 20, 'def_bonus': 20, 'requires_mutagen': True, 'field_scope': 'all'}
Description: With Mutagen Flag: +20 ATK&DEF for each Zombie card on the field
Test Cases:

Test Case ID: TC-FUNC-Urban-Zombie-001
Description:
Urban Zombie: field passive +20 ATK / +20 DEF per matching card
Implementation Reference:
- BattleResolver.calculate_field_bonuses() → _apply_field_ability_bonus
- Sets perm_atk_bonus / perm_def_bonus on source card
- AbilityType.BOOST_PER_TYPED_CARD_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place 2+ matching face-up allies (filter: ) on attacker's field.
- Call calculate_field_bonuses(player) before battle.
Steps:
Step 1: Inspect Urban Zombie.perm_atk_bonus and perm_def_bonus.
Expected Result:
- perm_atk_bonus == 20 × matching_count.
- perm_def_bonus == 20 × matching_count.
- get_effective_atk/def includes perm bonuses.

---

Card Name: Arcane Enforcer
Type: Character
Stats: ATK=200 DEF=95 Cost=1600 Affinity=ARCANE
AbilityType: CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD
ability_params: {'allowed': ['ARCANE'], 'invert': True}
Description: This card can only attack Arcane card
Test Cases:

Test Case ID: TC-FUNC-Arcane-Enforcer-001
Description:
Arcane Enforcer: blocked from attacking if disallowed affinity on field
Implementation Reference:
- TurnManager attack validation CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD
- AbilityType.CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place disallowed affinity face-up on own field.
Steps:
Step 1: Try select Arcane Enforcer as attacker.
Expected Result:
- Attack blocked or unit not selectable.

---

Card Name: Moon Owl
Type: Character
Stats: ATK=50 DEF=10 Cost=900 Affinity=NATURE
AbilityType: CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD
ability_params: {'protect_facedown': True}
Description: Foe cannot select face-down card as an attack target
Test Cases:

Test Case ID: TC-FUNC-Moon-Owl-001
Description:
Moon Owl: blocked from attacking if disallowed affinity on field
Implementation Reference:
- TurnManager attack validation CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD
- AbilityType.CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place disallowed affinity face-up on own field.
Steps:
Step 1: Try select Moon Owl as attacker.
Expected Result:
- Attack blocked or unit not selectable.

---

Card Name: Volcanic Dragon
Type: Character
Stats: ATK=125 DEF=125 Cost=1400 Affinity=NATURE
AbilityType: CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD
ability_params: {'only_exposed_self': True}
Description: Can only attack if this is the only exposed card on your side
Test Cases:

Test Case ID: TC-FUNC-Volcanic-Dragon-001
Description:
Volcanic Dragon: blocked from attacking if disallowed affinity on field
Implementation Reference:
- TurnManager attack validation CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD
- AbilityType.CANNOT_ATTACK_IF_NON_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Place disallowed affinity face-up on own field.
Steps:
Step 1: Try select Volcanic Dragon as attacker.
Expected Result:
- Attack blocked or unit not selectable.

---

Card Name: Blue Mage
Type: Character
Stats: ATK=35 DEF=35 Cost=800 Affinity=ARCANE
AbilityType: COIN_FLIP_2_DESTROY_NON_AFFINITY
ability_params: {'affinity': 'ARCANE'}
Description: If this card battles non-Arcane card, flip two coins. If both are head, destroy it.
Test Cases:

Test Case ID: TC-FUNC-Blue-Mage-001
Description:
Blue Mage: 2 coin flips; both heads destroys non-ARCANE defender
Implementation Reference:
- BattleResolver uses randf()>=0.5 twice; skips normal battle on success
- AbilityType.COIN_FLIP_2_DESTROY_NON_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Non-ARCANE defender.
Steps:
Step 1: Run battle; log coin outcomes.
Expected Result:
- Both heads: defender_destroyed=true, no ATK/DEF comparison.
- Otherwise: normal battle proceeds.
Verification (automated):
- Non-deterministic — run ≥20 iterations; verify both branches occur.

---

Card Name: Lightning Hawk
Type: Character
Stats: ATK=20 DEF=10 Cost=500 Affinity=ARCANE
AbilityType: COIN_FLIP_2_EXTRA_ATTACK
ability_params: {}
Description: After it performed attack, flip 2 coins, Both are heads: this card can attack 1 more time.
Test Cases:

Test Case ID: TC-FUNC-Lightning-Hawk-001
Description:
Lightning Hawk: ability COIN_FLIP_2_EXTRA_ATTACK functional smoke test
Implementation Reference:
- CharacterData.AbilityType.COIN_FLIP_2_EXTRA_ATTACK
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After it performed attack, flip 2 coins, Both are heads: this card can attack 1 more time.

---

Card Name: Century Fortuneteller
Type: Character
Stats: ATK=25 DEF=25 Cost=400 Affinity=ARCANE
AbilityType: COIN_FLIP_ATK_BOOST
ability_params: {'amount': 5}
Description: Your turn starts: flip a coin. Head: +5 ATK until your turn ends. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Century-Fortuneteller-001
Description:
Century Fortuneteller: coin flip +0 ATK this battle
Implementation Reference:
- BattleResolver._get_effective_atk() randf()>=0.5
- AbilityType.COIN_FLIP_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Century Fortuneteller attacks.
Steps:
Step 1: Resolve battle multiple times.
Expected Result:
- Heads: attacker_atk_used == 25; Tails: attacker_atk_used == 25.

---

Card Name: Death Jester
Type: Character
Stats: ATK=15 DEF=15 Cost=500 Affinity=ANIMA
AbilityType: COIN_FLIP_ATK_BOOST
ability_params: {'amount': 10}
Description: Exposed : Flip a coin. Heads: +10 ATK. Tails: +10 DEF
Test Cases:

Test Case ID: TC-FUNC-Death-Jester-001
Description:
Death Jester: coin flip +0 ATK this battle
Implementation Reference:
- BattleResolver._get_effective_atk() randf()>=0.5
- AbilityType.COIN_FLIP_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Death Jester attacks.
Steps:
Step 1: Resolve battle multiple times.
Expected Result:
- Heads: attacker_atk_used == 15; Tails: attacker_atk_used == 15.

---

Card Name: Joseph the Battle Priest
Type: Character
Stats: ATK=60 DEF=25 Cost=600 Affinity=DIVINE
AbilityType: COIN_FLIP_ATK_BOOST
ability_params: {'bonus': 10}
Description: In Reckoning, flip a coin. If head, +10 ATK
Test Cases:

Test Case ID: TC-FUNC-Joseph-the-Battle-Priest-001
Description:
Joseph the Battle Priest: coin flip +10 ATK this battle
Implementation Reference:
- BattleResolver._get_effective_atk() randf()>=0.5
- AbilityType.COIN_FLIP_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Joseph the Battle Priest attacks.
Steps:
Step 1: Resolve battle multiple times.
Expected Result:
- Heads: attacker_atk_used == 70; Tails: attacker_atk_used == 60.

---

Card Name: Long Tongue
Type: Character
Stats: ATK=75 DEF=60 Cost=700 Affinity=BIO
AbilityType: COIN_FLIP_ATK_BOOST
ability_params: {'bonus': 0, 'crystal_gain_heads': 50, 'after_attack': True}
Description: After successfully attacking, flip a coin, if head, gain 50 Crystal
Test Cases:

Test Case ID: TC-FUNC-Long-Tongue-001
Description:
Long Tongue: coin flip +0 ATK this battle
Implementation Reference:
- BattleResolver._get_effective_atk() randf()>=0.5
- AbilityType.COIN_FLIP_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Long Tongue attacks.
Steps:
Step 1: Resolve battle multiple times.
Expected Result:
- Heads: attacker_atk_used == 75; Tails: attacker_atk_used == 75.

---

Card Name: Messenger of Fate
Type: Character
Stats: ATK=45 DEF=35 Cost=500 Affinity=DIVINE
AbilityType: COIN_FLIP_ATK_BOOST
ability_params: {'amount': 20}
Description: In Reckoning, flip a coin. Head: +20 ATK&DEF. Tail -20 ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Messenger-of-Fate-001
Description:
Messenger of Fate: coin flip +0 ATK this battle
Implementation Reference:
- BattleResolver._get_effective_atk() randf()>=0.5
- AbilityType.COIN_FLIP_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Messenger of Fate attacks.
Steps:
Step 1: Resolve battle multiple times.
Expected Result:
- Heads: attacker_atk_used == 45; Tails: attacker_atk_used == 45.

---

Card Name: Grand Wizard
Type: Character
Stats: ATK=90 DEF=70 Cost=1100 Affinity=ARCANE
AbilityType: COIN_FLIP_ATK_DEF_BOOST
ability_params: {'bonus': 30}
Description: In Reckoning, flip a coin. Head: +30 ATK&DEF until this turn’s end
Test Cases:

Test Case ID: TC-FUNC-Grand-Wizard-001
Description:
Grand Wizard: ability COIN_FLIP_ATK_DEF_BOOST functional smoke test
Implementation Reference:
- CharacterData.AbilityType.COIN_FLIP_ATK_DEF_BOOST
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'bonus': 30}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: In Reckoning, flip a coin. Head: +30 ATK&DEF until this turn’s end

---

Card Name: Mini Probe
Type: Character
Stats: ATK=10 DEF=10 Cost=50 Affinity=COSMIC
AbilityType: COIN_FLIP_ATK_DEF_BOOST
ability_params: {'bonus': 10}
Description: In Reckoning, flip a coin. Heads: +10 ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Mini-Probe-001
Description:
Mini Probe: ability COIN_FLIP_ATK_DEF_BOOST functional smoke test
Implementation Reference:
- CharacterData.AbilityType.COIN_FLIP_ATK_DEF_BOOST
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'bonus': 10}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: In Reckoning, flip a coin. Heads: +10 ATK&DEF

---

Card Name: Wild West Raccoon
Type: Character
Stats: ATK=35 DEF=35 Cost=350 Affinity=ANIMA
AbilityType: COIN_FLIP_ATK_DEF_BOOST
ability_params: {'coin_flips': 3, 'atk_per_head': 5, 'def_per_tail': 5, 'three_tails_penalty': '{"atk": 15', 'def': 15}
Description: In Reckoning, flip 3 coins. +5 ATK for each heads. If 3 tails, -15ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Wild-West-Raccoon-001
Description:
Wild West Raccoon: ability COIN_FLIP_ATK_DEF_BOOST functional smoke test
Implementation Reference:
- CharacterData.AbilityType.COIN_FLIP_ATK_DEF_BOOST
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'coin_flips': 3, 'atk_per_head': 5, 'def_per_tail': 5, 'three_tails_penalty': '{"atk": 15', 'def': 15}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: In Reckoning, flip 3 coins. +5 ATK for each heads. If 3 tails, -15ATK&DEF

---

Card Name: Lazy Troll
Type: Character
Stats: ATK=120 DEF=60 Cost=1000 Affinity=NATURE
AbilityType: COIN_FLIP_CANCEL_ATTACK
ability_params: {}
Description: If this card performs an attack, flip a coin. Tail: it stops attacking.
Test Cases:

Test Case ID: TC-FUNC-Lazy-Troll-001
Description:
Lazy Troll: coin flip may cancel own attack
Implementation Reference:
- TurnManager pre-attack check AbilityType.COIN_FLIP_CANCEL_ATTACK
- AbilityType.COIN_FLIP_CANCEL_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lazy Troll selected as attacker.
Steps:
Step 1: Initiate attack; observe pre-battle coin.
Expected Result:
- Tails: attack cancelled before battle; Heads: proceeds.

---

Card Name: Horn Face
Type: Character
Stats: ATK=85 DEF=60 Cost=1350 Affinity=COSMIC
AbilityType: COIN_FLIP_EXTRA_ATTACK
ability_params: {'max_attacks': 3, 'coin_flips': 2}
Description: After a successful attack, flip 2 coins. It can attack again equal to number of head.
Test Cases:

Test Case ID: TC-FUNC-Horn-Face-001
Description:
Horn Face: coin flip extra attack after battle
Implementation Reference:
- TurnManager._apply_post_battle_effects randi()%2
- AbilityType.COIN_FLIP_EXTRA_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Horn Face completes an attack.
Steps:
Step 1: Check attacks_remaining after battle.
Expected Result:
- Heads: attacks_remaining incremented by 1; Tails: no extra.

---

Card Name: Moon Tribe Twin Blader
Type: Character
Stats: ATK=30 DEF=20 Cost=300 Affinity=COSMIC
AbilityType: COIN_FLIP_EXTRA_ATTACK
ability_params: {}
Description: If this card attacks, flip a coin. If head, this card can attack twice.
Test Cases:

Test Case ID: TC-FUNC-Moon-Tribe-Twin-Blader-001
Description:
Moon Tribe Twin Blader: coin flip extra attack after battle
Implementation Reference:
- TurnManager._apply_post_battle_effects randi()%2
- AbilityType.COIN_FLIP_EXTRA_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Moon Tribe Twin Blader completes an attack.
Steps:
Step 1: Check attacks_remaining after battle.
Expected Result:
- Heads: attacks_remaining incremented by 1; Tails: no extra.

---

Card Name: Bingo the Chrono Rabbit
Type: Character
Stats: ATK=60 DEF=55 Cost=850 Affinity=ARCANE
AbilityType: COIN_FLIP_NULLIFY_ON_DEFEND
ability_params: {'once': True, 'no_coin': True}
Description: Once, when this card defends, the attacker's attack is negated.
Test Cases:

Test Case ID: TC-FUNC-Bingo-the-Chrono-Rabbit-001
Description:
Bingo the Chrono Rabbit: coin flip nullifies attack on heads
Implementation Reference:
- BattleResolver pre-compare COIN_FLIP_NULLIFY_ON_DEFEND
- AbilityType.COIN_FLIP_NULLIFY_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks Bingo the Chrono Rabbit.
Steps:
Step 1: Resolve coin.
Expected Result:
- Heads: no destruction; Tails: normal battle.

---

Card Name: Gemmed Sphinx
Type: Character
Stats: ATK=40 DEF=40 Cost=700 Affinity=DIVINE
AbilityType: COIN_FLIP_NULLIFY_ON_DEFEND
ability_params: {}
Description: In Reckoning if it defends, flip a coin. Head: the attack does nothing.
Test Cases:

Test Case ID: TC-FUNC-Gemmed-Sphinx-001
Description:
Gemmed Sphinx: coin flip nullifies attack on heads
Implementation Reference:
- BattleResolver pre-compare COIN_FLIP_NULLIFY_ON_DEFEND
- AbilityType.COIN_FLIP_NULLIFY_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks Gemmed Sphinx.
Steps:
Step 1: Resolve coin.
Expected Result:
- Heads: no destruction; Tails: normal battle.

---

Card Name: Sandy Sphinx
Type: Character
Stats: ATK=20 DEF=20 Cost=450 Affinity=DIVINE
AbilityType: COIN_FLIP_NULLIFY_ON_DEFEND
ability_params: {}
Description: In Reckoning if it defends, flip a coin. Head: the attack does nothing.
Test Cases:

Test Case ID: TC-FUNC-Sandy-Sphinx-001
Description:
Sandy Sphinx: coin flip nullifies attack on heads
Implementation Reference:
- BattleResolver pre-compare COIN_FLIP_NULLIFY_ON_DEFEND
- AbilityType.COIN_FLIP_NULLIFY_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks Sandy Sphinx.
Steps:
Step 1: Resolve coin.
Expected Result:
- Heads: no destruction; Tails: normal battle.

---

Card Name: Shock Jellyfish
Type: Character
Stats: ATK=20 DEF=20 Cost=550 Affinity=NATURE
AbilityType: COIN_FLIP_NULLIFY_ON_DEFEND
ability_params: {'end_foe_turn': True, 'no_coin': True}
Description: If this card defended, foe’s turn ends immediately
Test Cases:

Test Case ID: TC-FUNC-Shock-Jellyfish-001
Description:
Shock Jellyfish: coin flip nullifies attack on heads
Implementation Reference:
- BattleResolver pre-compare COIN_FLIP_NULLIFY_ON_DEFEND
- AbilityType.COIN_FLIP_NULLIFY_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks Shock Jellyfish.
Steps:
Step 1: Resolve coin.
Expected Result:
- Heads: no destruction; Tails: normal battle.

---

Card Name: Sticky Grappler
Type: Character
Stats: ATK=25 DEF=20 Cost=300 Affinity=BIO
AbilityType: COIN_FLIP_NULLIFY_ON_DEFEND
ability_params: {'end_foe_turn_on_heads': True}
Description: If this card defended, flip a coin. If head, turn ends immediately
Test Cases:

Test Case ID: TC-FUNC-Sticky-Grappler-001
Description:
Sticky Grappler: coin flip nullifies attack on heads
Implementation Reference:
- BattleResolver pre-compare COIN_FLIP_NULLIFY_ON_DEFEND
- AbilityType.COIN_FLIP_NULLIFY_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks Sticky Grappler.
Steps:
Step 1: Resolve coin.
Expected Result:
- Heads: no destruction; Tails: normal battle.

---

Card Name: Nuki the Tanuki
Type: Character
Stats: ATK=10 DEF=10 Cost=100 Affinity=NATURE
AbilityType: COIN_FLIP_SWAP_POSITION
ability_params: {}
Description: Before Reckoning, flip a coin. If head, swap position with any of own unit. Repeat Reckoning.
Test Cases:

Test Case ID: TC-FUNC-Nuki-the-Tanuki-001
Description:
Nuki the Tanuki: coin flip swap position after battle
Implementation Reference:
- BattleResolver sets pending_coin_flip_swap_position; TurnManager prompts swap
- AbilityType.COIN_FLIP_SWAP_POSITION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Nuki the Tanuki on field with another own character.
Steps:
Step 1: Complete battle; on heads choose swap target.
Expected Result:
- Grid positions exchange; cards retain stats.

---

Card Name: Tholin Kraken
Type: Character
Stats: ATK=65 DEF=50 Cost=820 Affinity=COSMIC
AbilityType: COIN_FLIP_SWAP_POSITION
ability_params: {'vs_trap': True, 'name_contains': 'Tholin', 'crystal_gain': 200}
Description: If attacked a trap, you can swap position with 1 of your Tholin card, then restore your crystal by 200.
Test Cases:

Test Case ID: TC-FUNC-Tholin-Kraken-001
Description:
Tholin Kraken: coin flip swap position after battle
Implementation Reference:
- BattleResolver sets pending_coin_flip_swap_position; TurnManager prompts swap
- AbilityType.COIN_FLIP_SWAP_POSITION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tholin Kraken on field with another own character.
Steps:
Step 1: Complete battle; on heads choose swap target.
Expected Result:
- Grid positions exchange; cards retain stats.

---

Card Name: Toyol
Type: Character
Stats: ATK=0 DEF=0 Cost=400 Affinity=CHAOS
AbilityType: COIN_FLIP_SWAP_POSITION
ability_params: {'on_targeted': True, 'once': True, 'face_down': True}
Description: Once, if its being targeted for attack, swap this card’s position with another ally, then repeat Reckoning. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Toyol-001
Description:
Toyol: coin flip swap position after battle
Implementation Reference:
- BattleResolver sets pending_coin_flip_swap_position; TurnManager prompts swap
- AbilityType.COIN_FLIP_SWAP_POSITION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Toyol on field with another own character.
Steps:
Step 1: Complete battle; on heads choose swap target.
Expected Result:
- Grid positions exchange; cards retain stats.

---

Card Name: Doctopus
Type: Character
Stats: ATK=15 DEF=20 Cost=900 Affinity=NATURE
AbilityType: COPY_ALLY_STATS_ON_DESTROY
ability_params: {'affinity': 'NATURE', 'zero_atk_revive': True, 'face_down': True}
Description: Once, whenever ally Nature card is destroyed, you can make this card’s ATK becomes 0, revive the destroyed unit at this turn’s end. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Doctopus-001
Description:
Doctopus: ability COPY_ALLY_STATS_ON_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.COPY_ALLY_STATS_ON_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'NATURE', 'zero_atk_revive': True, 'face_down': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, whenever ally Nature card is destroyed, you can make this card’s ATK becomes 0, revive the destroyed unit at this turn’s end. Usable face-down.

---

Card Name: Ectoplasm
Type: Character
Stats: ATK=20 DEF=0 Cost=800 Affinity=BIO
AbilityType: COPY_ALLY_STATS_ON_DESTROY
ability_params: {}
Description: After this card is destroyed in Reckoning, revive 1 unit you own with no ability. Repeat the Reckoning.
Test Cases:

Test Case ID: TC-FUNC-Ectoplasm-001
Description:
Ectoplasm: ability COPY_ALLY_STATS_ON_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.COPY_ALLY_STATS_ON_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After this card is destroyed in Reckoning, revive 1 unit you own with no ability. Repeat the Reckoning.

---

Card Name: Nostra the Necromancer
Type: Character
Stats: ATK=65 DEF=65 Cost=1700 Affinity=CHAOS
AbilityType: COPY_ALLY_STATS_ON_DESTROY
ability_params: {'revive_ally': True, 'max_cost': 600, 'face_down': True}
Description: Once, whenever an ally unit with 600 or less cost is destroyed, revive that unit. Usable face-down
Test Cases:

Test Case ID: TC-FUNC-Nostra-the-Necromancer-001
Description:
Nostra the Necromancer: ability COPY_ALLY_STATS_ON_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.COPY_ALLY_STATS_ON_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'revive_ally': True, 'max_cost': 600, 'face_down': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, whenever an ally unit with 600 or less cost is destroyed, revive that unit. Usable face-down

---

Card Name: Miner Probe
Type: Character
Stats: ATK=10 DEF=10 Cost=200 Affinity=COSMIC
AbilityType: CRYSTAL_GAIN_ON_DEAD_END_ATTACK
ability_params: {'amount': 200}
Description: Gain 200 Crystals upon hitting Dead End
Test Cases:

Test Case ID: TC-FUNC-Miner-Probe-001
Description:
Miner Probe: +200 crystals on dead_end attack
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

Card Name: Anatomy Doll
Type: Character
Stats: ATK=20 DEF=20 Cost=200 Affinity=CHAOS
AbilityType: CRYSTAL_GAIN_ON_DEFEND
ability_params: {'amount': 300, 'vs_affinity': 'ANIMA'}
Description: After Reckoning with Anima unit, +300 Crystals.
Test Cases:

Test Case ID: TC-FUNC-Anatomy-Doll-001
Description:
Anatomy Doll: ability CRYSTAL_GAIN_ON_DEFEND functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 300, 'vs_affinity': 'ANIMA'}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After Reckoning with Anima unit, +300 Crystals.

---

Card Name: Deep Tribe Healer
Type: Character
Stats: ATK=30 DEF=70 Cost=800 Affinity=NATURE
AbilityType: CRYSTAL_GAIN_ON_DEFEND
ability_params: {'amount': 300, 'name_contains': 'Tribe', 'half_cost': True, 'face_down': True}
Description: Cost for Tribe units are halved. Once, if Tribe units get Reckoning, heal 300 crystals. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Deep-Tribe-Healer-001
Description:
Deep Tribe Healer: ability CRYSTAL_GAIN_ON_DEFEND functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 300, 'name_contains': 'Tribe', 'half_cost': True, 'face_down': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Cost for Tribe units are halved. Once, if Tribe units get Reckoning, heal 300 crystals. Usable face-down.

---

Card Name: Energy Elf
Type: Character
Stats: ATK=20 DEF=40 Cost=500 Affinity=ARCANE
AbilityType: CRYSTAL_GAIN_ON_DEFEND
ability_params: {'amount': 100, 'on_expose': True}
Description: Exposed : +100 crystals
Test Cases:

Test Case ID: TC-FUNC-Energy-Elf-001
Description:
Energy Elf: ability CRYSTAL_GAIN_ON_DEFEND functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 100, 'on_expose': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Exposed : +100 crystals

---

Card Name: Fierce Gladiator
Type: Character
Stats: ATK=70 DEF=90 Cost=1000 Affinity=ANIMA
AbilityType: CRYSTAL_GAIN_ON_DEFEND
ability_params: {'amount': 500}
Description: +200 Crystal if successfully defended
Test Cases:

Test Case ID: TC-FUNC-Fierce-Gladiator-001
Description:
Fierce Gladiator: ability CRYSTAL_GAIN_ON_DEFEND functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 500}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +200 Crystal if successfully defended

---

Card Name: Mina the Chemist
Type: Character
Stats: ATK=5 DEF=15 Cost=100 Affinity=ANIMA
AbilityType: CRYSTAL_GAIN_ON_DEFEND
ability_params: {'amount': 150, 'on_expose': True}
Description: Exposed : +150 crystals
Test Cases:

Test Case ID: TC-FUNC-Mina-the-Chemist-001
Description:
Mina the Chemist: ability CRYSTAL_GAIN_ON_DEFEND functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 150, 'on_expose': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Exposed : +150 crystals

---

Card Name: Quezil the Space Rescuer
Type: Character
Stats: ATK=55 DEF=35 Cost=580 Affinity=COSMIC
AbilityType: CRYSTAL_GAIN_ON_DEFEND
ability_params: {'amount': 100, 'per_void_affinity': 'COSMIC'}
Description: Exposed : +100 crystals per 1 Cosmic card in your void
Test Cases:

Test Case ID: TC-FUNC-Quezil-the-Space-Rescuer-001
Description:
Quezil the Space Rescuer: ability CRYSTAL_GAIN_ON_DEFEND functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 100, 'per_void_affinity': 'COSMIC'}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Exposed : +100 crystals per 1 Cosmic card in your void

---

Card Name: Wicked Nurse
Type: Character
Stats: ATK=15 DEF=25 Cost=240 Affinity=CHAOS
AbilityType: CRYSTAL_GAIN_ON_DEFEND
ability_params: {'amount': 20}
Description: +20 Crystal when it successfully defended
Test Cases:

Test Case ID: TC-FUNC-Wicked-Nurse-001
Description:
Wicked Nurse: ability CRYSTAL_GAIN_ON_DEFEND functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DEFEND
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 20}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +20 Crystal when it successfully defended

---

Card Name: Alchemist
Type: Character
Stats: ATK=20 DEF=100 Cost=1000 Affinity=ANIMA
AbilityType: CRYSTAL_GAIN_ON_DESTROY
ability_params: {'amount': 500, 'or_foe_loss': True}
Description: After Reckoning, choose either gain 500 crystals or make foe lose 500 crystals
Test Cases:

Test Case ID: TC-FUNC-Alchemist-001
Description:
Alchemist: ability CRYSTAL_GAIN_ON_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 500, 'or_foe_loss': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After Reckoning, choose either gain 500 crystals or make foe lose 500 crystals

---

Card Name: Gold Dragon
Type: Character
Stats: ATK=120 DEF=110 Cost=1250 Affinity=ARCANE
AbilityType: CRYSTAL_GAIN_ON_DESTROY
ability_params: {'foe_loss': 500, 'min_target_cost': 800}
Description: After a successful Reckoning with unit cost ≥ 800, your foe lose 500 crystals
Test Cases:

Test Case ID: TC-FUNC-Gold-Dragon-001
Description:
Gold Dragon: ability CRYSTAL_GAIN_ON_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.CRYSTAL_GAIN_ON_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'foe_loss': 500, 'min_target_cost': 800}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After a successful Reckoning with unit cost ≥ 800, your foe lose 500 crystals

---

Card Name: Dryad
Type: Character
Stats: ATK=20 DEF=110 Cost=950 Affinity=NATURE
AbilityType: CRYSTAL_GAIN_ON_OPP_REVEAL
ability_params: {'amount': 300, 'on_foe_destroy': True, 'when_exposed': True}
Description: While exposed, whenever foe’s card is destroyed, gain 300 Crystals
Test Cases:

Test Case ID: TC-FUNC-Dryad-001
Description:
Dryad: +300 crystals when opponent cell revealed
Implementation Reference:
- GameState reveal hooks / CardRuleEngine
- AbilityType.CRYSTAL_GAIN_ON_OPP_REVEAL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Dryad face-up on field.
Steps:
Step 1: Reveal any opponent cell (Spy/Radar/attack reveal).
Expected Result:
- Owner gains 300 crystals per reveal event.

---

Card Name: Ore Transporter
Type: Character
Stats: ATK=20 DEF=35 Cost=280 Affinity=ARCANE
AbilityType: CRYSTAL_GAIN_ON_OPP_REVEAL
ability_params: {'amount': 20, 'on_own_tech': True}
Description: Whenever you uses tech, they receive 20 Crystals
Test Cases:

Test Case ID: TC-FUNC-Ore-Transporter-001
Description:
Ore Transporter: +20 crystals when opponent cell revealed
Implementation Reference:
- GameState reveal hooks / CardRuleEngine
- AbilityType.CRYSTAL_GAIN_ON_OPP_REVEAL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Ore Transporter face-up on field.
Steps:
Step 1: Reveal any opponent cell (Spy/Radar/attack reveal).
Expected Result:
- Owner gains 20 crystals per reveal event.

---

Card Name: Parom the Smuggler
Type: Character
Stats: ATK=30 DEF=20 Cost=300 Affinity=COSMIC
AbilityType: CRYSTAL_GAIN_ON_OPP_REVEAL
ability_params: {'amount': 40}
Description: Each time foe’s cell got revealed by a card’s ability: gain 40 Crystals.
Test Cases:

Test Case ID: TC-FUNC-Parom-the-Smuggler-001
Description:
Parom the Smuggler: +40 crystals when opponent cell revealed
Implementation Reference:
- GameState reveal hooks / CardRuleEngine
- AbilityType.CRYSTAL_GAIN_ON_OPP_REVEAL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Parom the Smuggler face-up on field.
Steps:
Step 1: Reveal any opponent cell (Spy/Radar/attack reveal).
Expected Result:
- Owner gains 40 crystals per reveal event.

---

Card Name: Melissa the Healer
Type: Character
Stats: ATK=0 DEF=25 Cost=700 Affinity=DIVINE
AbilityType: CRYSTAL_RECOVER_ON_BIG_LOSS
ability_params: {'threshold': 500, 'amount': 300}
Description: If you lose 500 or more Crystals, you recover 300 Crystals.
Test Cases:

Test Case ID: TC-FUNC-Melissa-the-Healer-001
Description:
Melissa the Healer: recover 300 if single loss ≥500
Implementation Reference:
- GameState crystal loss hook
- AbilityType.CRYSTAL_RECOVER_ON_BIG_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Melissa the Healer on field.
Steps:
Step 1: Lose ≥500 crystals in one event (destroy high-cost card).
Expected Result:
- Net loss reduced by 300 (gain 300 back).

---

Card Name: Aether Warden
Type: Character
Stats: ATK=30 DEF=110 Cost=800 Affinity=DIVINE
AbilityType: DEFEND_DRAIN_ATTACKER
ability_params: {'drain_amount': 300}
Description: In Reckoning if it defends, attacker loses 300 Crystals
Test Cases:

Test Case ID: TC-FUNC-Aether-Warden-001
Description:
Aether Warden: drain 300 crystals from attacker on defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.DEFEND_DRAIN_ATTACKER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks; Aether Warden wins defense.
Steps:
Step 1: Resolve battle.
Expected Result:
- result.attacker_crystal_loss includes +300 (or separate drain message).

---

Card Name: Lessor Leech
Type: Character
Stats: ATK=0 DEF=0 Cost=100 Affinity=BIO
AbilityType: DEFEND_DRAIN_ATTACKER
ability_params: {'drain_amount': 400, 'self_gain': 400, 'mutagen_bonus': 400}
Description: After Reckoning, foe loses 400 Crystals. You gains 400 Crystals. With Mutagen Flag : You gain 400 more.
Test Cases:

Test Case ID: TC-FUNC-Lessor-Leech-001
Description:
Lessor Leech: drain 400 crystals from attacker on defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.DEFEND_DRAIN_ATTACKER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks; Lessor Leech wins defense.
Steps:
Step 1: Resolve battle.
Expected Result:
- result.attacker_crystal_loss includes +400 (or separate drain message).

---

Card Name: Green Mage
Type: Character
Stats: ATK=15 DEF=15 Cost=400 Affinity=ARCANE
AbilityType: DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF
ability_params: {'atk': 10, 'def': 10}
Description: When this card defends, the attacker permanently loses 10 ATK&DEF.
Test Cases:

Test Case ID: TC-FUNC-Green-Mage-001
Description:
Green Mage: attacker permanently -10 ATK / -10 DEF on defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.DEFEND_PERM_DEBUFF_ATTACKER_ATK_DEF
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Green Mage defends successfully.
Steps:
Step 1: Resolve defense.
Expected Result:
- attacker.current_atk -= 10; attacker.current_def -= 10.

---

Card Name: Moonrise Gentleman
Type: Character
Stats: ATK=40 DEF=30 Cost=400 Affinity=DIVINE
AbilityType: DEFENSE_STANCE_BOOST
ability_params: {'def': 10}
Description: If it defends: +10 DEF,-10 ATK permanently (if possible)
Test Cases:

Test Case ID: TC-FUNC-Moonrise-Gentleman-001
Description:
Moonrise Gentleman: +10 DEF in defense stance
Implementation Reference:
- BattleResolver._get_effective_def()
- AbilityType.DEFENSE_STANCE_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks Moonrise Gentleman.
Steps:
Step 1: Resolve battle.
Expected Result:
- defender_def_used == 40.

---

Card Name: Dragonling
Type: Character
Stats: ATK=40 DEF=40 Cost=400 Affinity=ARCANE
AbilityType: DEF_BONUS_IF_AFFINITY_ON_FIELD
ability_params: {'affinity': 'ARCANE', 'bonus': -40, 'invert': True, 'face_up_required': True}
Description: Without face-up Arcane card on your side, -40 DEF
Test Cases:

Test Case ID: TC-FUNC-Dragonling-001
Description:
Dragonling: +-40 DEF when face-up ARCANE on field (both players unless scoped)
Implementation Reference:
- BattleResolver._get_effective_def()
- AbilityType.DEF_BONUS_IF_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-up ARCANE unit on either field when field_scope=all; opponent attacks Dragonling.
Steps:
Step 1: Resolve defense.
Expected Result:
- defender_def_used == 0.

---

Card Name: Joan the Faithful Warrior
Type: Character
Stats: ATK=25 DEF=5 Cost=280 Affinity=DIVINE
AbilityType: DEF_BONUS_IF_AFFINITY_ON_FIELD
ability_params: {'affinity': 'DIVINE', 'def': 35, 'field_scope': 'all'}
Description: If at least 1 exposed Divine unit is on the field, this card gains 35 DEF
Test Cases:

Test Case ID: TC-FUNC-Joan-the-Faithful-Warrior-001
Description:
Joan the Faithful Warrior: +35 DEF when face-up DIVINE on field (both players unless scoped)
Implementation Reference:
- BattleResolver._get_effective_def()
- AbilityType.DEF_BONUS_IF_AFFINITY_ON_FIELD
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-up DIVINE unit on either field when field_scope=all; opponent attacks Joan the Faithful Warrior.
Steps:
Step 1: Resolve defense.
Expected Result:
- defender_def_used == 40.

---

Card Name: Cloudbender
Type: Character
Stats: ATK=20 DEF=35 Cost=350 Affinity=ARCANE
AbilityType: DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'COSMIC', 'bonus': 15}
Description: +15 DEF vs Cosmic
Test Cases:

Test Case ID: TC-FUNC-Cloudbender-001
Description:
Cloudbender: ability DEF_BONUS_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'COSMIC', 'bonus': 15}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +15 DEF vs Cosmic

---

Card Name: Lightbringer
Type: Character
Stats: ATK=80 DEF=40 Cost=1200 Affinity=DIVINE
AbilityType: DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'bonus': 100}
Description: +100 DEF vs Chaos Affinity
Test Cases:

Test Case ID: TC-FUNC-Lightbringer-001
Description:
Lightbringer: ability DEF_BONUS_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'CHAOS', 'bonus': 100}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +100 DEF vs Chaos Affinity

---

Card Name: Lucky Statue
Type: Character
Stats: ATK=40 DEF=30 Cost=400 Affinity=DIVINE
AbilityType: DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'bonus': 20}
Description: +20 DEF vs Chaos
Test Cases:

Test Case ID: TC-FUNC-Lucky-Statue-001
Description:
Lucky Statue: ability DEF_BONUS_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'CHAOS', 'bonus': 20}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +20 DEF vs Chaos

---

Card Name: Totem Granpa
Type: Character
Stats: ATK=20 DEF=20 Cost=420 Affinity=DIVINE
AbilityType: DEF_BONUS_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'bonus': 30}
Description: +30 DEF vs Nature
Test Cases:

Test Case ID: TC-FUNC-Totem-Granpa-001
Description:
Totem Granpa: ability DEF_BONUS_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DEF_BONUS_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'NATURE', 'bonus': 30}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +30 DEF vs Nature

---

Card Name: Mafia Associates
Type: Character
Stats: ATK=45 DEF=40 Cost=500 Affinity=ANIMA
AbilityType: DEF_ZERO_WHEN_EXPOSED
ability_params: {}
Description: At the end of the turn that it’s been exposed, its defense becomes 0
Test Cases:

Test Case ID: TC-FUNC-Mafia-Associates-001
Description:
Mafia Associates: DEF=0 while face-up
Implementation Reference:
- BattleResolver._get_effective_def() returns 0 when defender.face_up
- AbilityType.DEF_ZERO_WHEN_EXPOSED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mafia Associates face-up; opponent attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- defender_def_used == 0 regardless of base DEF 40.
Verification (automated):
- assert_eq(result.defender_def_used, 0)

---

Card Name: Pit Lord
Type: Character
Stats: ATK=120 DEF=100 Cost=1250 Affinity=CHAOS
AbilityType: DESTROYED_IF_BATTLES_DIVINE
ability_params: {'also_halve_after_attack': True}
Description: Destroy this card after Reckoning with Divine Unit. After this card attacked, halve its ATK&DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Pit-Lord-001
Description:
Pit Lord: destroyed when battling Divine; halve stats after attack
Implementation Reference:
- BattleResolver pre-compare: attacker destroyed if defender.affinity==DIVINE
- _apply_post_attack_effects: halve_stats() via ability_type match
- AbilityType.DESTROYED_IF_BATTLES_DIVINE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine defender (e.g. Angel Gatekeeper) face-up.
Steps:
Step 1: Pit Lord attacks Divine character.
Expected Result:
- result.attacker_destroyed == true.
- result.attacker_crystal_loss == 1250.
- After any successful attack: current_atk and current_def halved permanently.

---

Card Name: Bomb Squad
Type: Character
Stats: ATK=25 DEF=40 Cost=420 Affinity=ANIMA
AbilityType: DESTROY_END_TURN_BLAST_ADJACENT
ability_params: {'once': True, 'on_defend': True}
Description: Once, after attacked, destroy 1 card on target’s adjacent cell.
Test Cases:

Test Case ID: TC-FUNC-Bomb-Squad-001
Description:
Bomb Squad: ability DESTROY_END_TURN_BLAST_ADJACENT functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DESTROY_END_TURN_BLAST_ADJACENT
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'once': True, 'on_defend': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, after attacked, destroy 1 card on target’s adjacent cell.

---

Card Name: Orc Cannoneer
Type: Character
Stats: ATK=40 DEF=60 Cost=850 Affinity=CHAOS
AbilityType: DESTROY_END_TURN_BLAST_ADJACENT
ability_params: {'once': True, 'on_attack': True}
Description: Once, after performed attacked, destroy 1 card in adjacent cell
Test Cases:

Test Case ID: TC-FUNC-Orc-Cannoneer-001
Description:
Orc Cannoneer: ability DESTROY_END_TURN_BLAST_ADJACENT functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DESTROY_END_TURN_BLAST_ADJACENT
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'once': True, 'on_attack': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, after performed attacked, destroy 1 card in adjacent cell

---

Card Name: Atheist Outlaw
Type: Character
Stats: ATK=45 DEF=35 Cost=550 Affinity=ANIMA
AbilityType: DESTROY_IF_OPPONENT_AFFINITY
ability_params: {'affinity': 'DIVINE', 'destroy_foe': True}
Description: In Reckoning with Divine unit, destroy foe’s unit
Test Cases:

Test Case ID: TC-FUNC-Atheist-Outlaw-001
Description:
Atheist Outlaw: auto-destroy DIVINE defender before ATK/DEF compare
Implementation Reference:
- BattleResolver._resolve_character_vs_character pre-compare branch
- AbilityType.DESTROY_IF_OPPONENT_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender is DIVINE character.
Steps:
Step 1: Atheist Outlaw attacks DIVINE defender.
Expected Result:
- result.defender_destroyed == true regardless of stats.
- result.defender_crystal_loss == defender.crystal_cost.
- Normal ATK/DEF comparison skipped.
Verification (automated):
- assert_true(result.defender_destroyed)

---

Card Name: Deep Tribe Witchdoctor
Type: Character
Stats: ATK=75 DEF=100 Cost=1200 Affinity=NATURE
AbilityType: DESTROY_IF_OPPONENT_AFFINITY
ability_params: {'affinity': 'NATURE', 'invert': True, 'once': True}
Description: Once, destroy Non-Nature in Reckoning. When Tribe unit get Reckoning, you can switch position with this card. Usable face-down
Test Cases:

Test Case ID: TC-FUNC-Deep-Tribe-Witchdoctor-001
Description:
Deep Tribe Witchdoctor: auto-destroy NATURE defender before ATK/DEF compare
Implementation Reference:
- BattleResolver._resolve_character_vs_character pre-compare branch
- AbilityType.DESTROY_IF_OPPONENT_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender is NATURE character.
Steps:
Step 1: Deep Tribe Witchdoctor attacks NATURE defender.
Expected Result:
- result.defender_destroyed == true regardless of stats.
- result.defender_crystal_loss == defender.crystal_cost.
- Normal ATK/DEF comparison skipped.
Verification (automated):
- assert_true(result.defender_destroyed)

---

Card Name: Goddess of Virtue
Type: Character
Stats: ATK=80 DEF=100 Cost=1400 Affinity=DIVINE
AbilityType: DESTROY_IF_OPPONENT_AFFINITY
ability_params: {'affinity': 'CHAOS'}
Description: In Reckoning, destroy Chaos before any calculation
Test Cases:

Test Case ID: TC-FUNC-Goddess-of-Virtue-001
Description:
Goddess of Virtue: auto-destroy CHAOS defender before ATK/DEF compare
Implementation Reference:
- BattleResolver._resolve_character_vs_character pre-compare branch
- AbilityType.DESTROY_IF_OPPONENT_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender is CHAOS character.
Steps:
Step 1: Goddess of Virtue attacks CHAOS defender.
Expected Result:
- result.defender_destroyed == true regardless of stats.
- result.defender_crystal_loss == defender.crystal_cost.
- Normal ATK/DEF comparison skipped.
Verification (automated):
- assert_true(result.defender_destroyed)

---

Card Name: Justin the Vampire Hunter
Type: Character
Stats: ATK=55 DEF=40 Cost=660 Affinity=ANIMA
AbilityType: DESTROY_IF_OPPONENT_AFFINITY
ability_params: {'affinity': 'CHAOS'}
Description: Destroy Chaos card in Reckoning
Test Cases:

Test Case ID: TC-FUNC-Justin-the-Vampire-Hunter-001
Description:
Justin the Vampire Hunter: auto-destroy CHAOS defender before ATK/DEF compare
Implementation Reference:
- BattleResolver._resolve_character_vs_character pre-compare branch
- AbilityType.DESTROY_IF_OPPONENT_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender is CHAOS character.
Steps:
Step 1: Justin the Vampire Hunter attacks CHAOS defender.
Expected Result:
- result.defender_destroyed == true regardless of stats.
- result.defender_crystal_loss == defender.crystal_cost.
- Normal ATK/DEF comparison skipped.
Verification (automated):
- assert_true(result.defender_destroyed)

---

Card Name: Nelfa the Windstorm Princess
Type: Character
Stats: ATK=50 DEF=40 Cost=550 Affinity=ARCANE
AbilityType: DESTROY_IF_OPPONENT_AFFINITY
ability_params: {'atk_exceeds_def_by': 30}
Description: During battle, destroy defender if its ATK exceeds foe’s DEF by 30 or more
Test Cases:

Test Case ID: TC-FUNC-Nelfa-the-Windstorm-Princess-001
Description:
Nelfa the Windstorm Princess: auto-destroy ? defender before ATK/DEF compare
Implementation Reference:
- BattleResolver._resolve_character_vs_character pre-compare branch
- AbilityType.DESTROY_IF_OPPONENT_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender is ? character.
Steps:
Step 1: Nelfa the Windstorm Princess attacks ? defender.
Expected Result:
- result.defender_destroyed == true regardless of stats.
- result.defender_crystal_loss == defender.crystal_cost.
- Normal ATK/DEF comparison skipped.
Verification (automated):
- assert_true(result.defender_destroyed)

---

Card Name: Zombie Hunter
Type: Character
Stats: ATK=40 DEF=30 Cost=500 Affinity=ANIMA
AbilityType: DESTROY_IF_OPPONENT_AFFINITY
ability_params: {'name_contains': 'Zombie'}
Description: In Reckoning, destroy Zombie card
Test Cases:

Test Case ID: TC-FUNC-Zombie-Hunter-001
Description:
Zombie Hunter: auto-destroy ? defender before ATK/DEF compare
Implementation Reference:
- BattleResolver._resolve_character_vs_character pre-compare branch
- AbilityType.DESTROY_IF_OPPONENT_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender is ? character.
Steps:
Step 1: Zombie Hunter attacks ? defender.
Expected Result:
- result.defender_destroyed == true regardless of stats.
- result.defender_crystal_loss == defender.crystal_cost.
- Normal ATK/DEF comparison skipped.
Verification (automated):
- assert_true(result.defender_destroyed)

---

Card Name: Agent Lucia
Type: Character
Stats: ATK=60 DEF=50 Cost=800 Affinity=ANIMA
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: Unit with 150 or less cost get destroyed in Reckoning with this card
Test Cases:

Test Case ID: TC-FUNC-Agent-Lucia-001
Description:
Agent Lucia: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Agent Lucia completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

---

Card Name: Elite Bleacher Unit
Type: Character
Stats: ATK=60 DEF=40 Cost=650 Affinity=BIO
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: In Reckoning, destroy Bio card.
Test Cases:

Test Case ID: TC-FUNC-Elite-Bleacher-Unit-001
Description:
Elite Bleacher Unit: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Elite Bleacher Unit completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

---

Card Name: Klabautermann
Type: Character
Stats: ATK=0 DEF=0 Cost=150 Affinity=CHAOS
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: Before Reckoning of any ally, you can destroy this card to make that card gain +5 ATK&DEF.
Test Cases:

Test Case ID: TC-FUNC-Klabautermann-001
Description:
Klabautermann: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Klabautermann completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

---

Card Name: Mad Exorcist
Type: Character
Stats: ATK=55 DEF=30 Cost=700 Affinity=DIVINE
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: Destroy Chaos card after Reckoning
Test Cases:

Test Case ID: TC-FUNC-Mad-Exorcist-001
Description:
Mad Exorcist: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mad Exorcist completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

---

Card Name: Mean Angel
Type: Character
Stats: ATK=20 DEF=10 Cost=250 Affinity=DIVINE
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: Once, destroy Anima card in Reckoning
Test Cases:

Test Case ID: TC-FUNC-Mean-Angel-001
Description:
Mean Angel: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mean Angel completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

---

Card Name: Moon Tribe Demolisher
Type: Character
Stats: ATK=25 DEF=60 Cost=600 Affinity=COSMIC
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: Once, in Reckoning, destroy the defender. If no another ally Moon card, also destroy this card.
Test Cases:

Test Case ID: TC-FUNC-Moon-Tribe-Demolisher-001
Description:
Moon Tribe Demolisher: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Moon Tribe Demolisher completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

---

Card Name: Phantom Assassain
Type: Character
Stats: ATK=50 DEF=25 Cost=660 Affinity=ANIMA
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: Once, pay 1000 card to choose either destroy unit in Reckoning with this card or gain 40 ATK permanently
Test Cases:

Test Case ID: TC-FUNC-Phantom-Assassain-001
Description:
Phantom Assassain: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Phantom Assassain completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

---

Card Name: Pyrosilicate Drake
Type: Character
Stats: ATK=105 DEF=0 Cost=800 Affinity=COSMIC
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: Destroy this card after Reckoning with a unit. Whenever you use Tech card, revive this card.
Test Cases:

Test Case ID: TC-FUNC-Pyrosilicate-Drake-001
Description:
Pyrosilicate Drake: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Pyrosilicate Drake completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

---

Card Name: Space Janitor
Type: Character
Stats: ATK=50 DEF=50 Cost=860 Affinity=COSMIC
AbilityType: DESTROY_SELF_AFTER_BATTLE
ability_params: {}
Description: Before Reckoning, you can choose to destroy 1 trap card on your side to gain +60 ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Space-Janitor-001
Description:
Space Janitor: self-destroy after battle (no crystal loss)
Implementation Reference:
- TurnManager DESTROY_SELF_AFTER_BATTLE pay_cost=false
- AbilityType.DESTROY_SELF_AFTER_BATTLE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Space Janitor completes any battle surviving.
Steps:
Step 1: Finish battle resolution.
Expected Result:
- Attacker destroyed via GameState.destroy_card pay_cost=false.

---

Card Name: Alloy Comet
Type: Character
Stats: ATK=150 DEF=100 Cost=1200 Affinity=COSMIC
AbilityType: DESTROY_SELF_AT_END_OF_EXPOSE_TURN
ability_params: {}
Description: Once exposed, destroy it and the end of this turn
Test Cases:

Test Case ID: TC-FUNC-Alloy-Comet-001
Description:
Alloy Comet: destroyed end of turn when first revealed
Implementation Reference:
- TurnManager._end_turn expose_destroy_pending
- AbilityType.DESTROY_SELF_AT_END_OF_EXPOSE_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Reveal Alloy Comet this turn.
Steps:
Step 1: End turn without destroying in battle.
Expected Result:
- Card destroyed pay_cost=false at turn end.

---

Card Name: Striker Comet
Type: Character
Stats: ATK=25 DEF=25 Cost=200 Affinity=COSMIC
AbilityType: DESTROY_SELF_AT_END_OF_EXPOSE_TURN
ability_params: {}
Description: Once exposed, destroy it and the end of this turn
Test Cases:

Test Case ID: TC-FUNC-Striker-Comet-001
Description:
Striker Comet: destroyed end of turn when first revealed
Implementation Reference:
- TurnManager._end_turn expose_destroy_pending
- AbilityType.DESTROY_SELF_AT_END_OF_EXPOSE_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Reveal Striker Comet this turn.
Steps:
Step 1: End turn without destroying in battle.
Expected Result:
- Card destroyed pay_cost=false at turn end.

---

Card Name: Black Devil
Type: Character
Stats: ATK=80 DEF=65 Cost=750 Affinity=CHAOS
AbilityType: DESTROY_SELF_VS_DIVINE_BOTH
ability_params: {}
Description: This card is not affected by traps. Destroy this card in Reckoning with Divine units.
Test Cases:

Test Case ID: TC-FUNC-Black-Devil-001
Description:
Black Devil: self-destruct when battling Divine (attacker or defender role)
Implementation Reference:
- BattleResolver early-return branches for Divine match
- AbilityType.DESTROY_SELF_VS_DIVINE_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine character involved in battle.
Steps:
Step 1: Battle Black Devil vs Divine.
Expected Result:
- Black Devil result.either_destroyed == true.

---

Card Name: Feral Vampire
Type: Character
Stats: ATK=40 DEF=25 Cost=400 Affinity=CHAOS
AbilityType: DESTROY_SELF_VS_DIVINE_BOTH
ability_params: {}
Description: In Reckoning with Divine, destroy this card
Test Cases:

Test Case ID: TC-FUNC-Feral-Vampire-001
Description:
Feral Vampire: self-destruct when battling Divine (attacker or defender role)
Implementation Reference:
- BattleResolver early-return branches for Divine match
- AbilityType.DESTROY_SELF_VS_DIVINE_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine character involved in battle.
Steps:
Step 1: Battle Feral Vampire vs Divine.
Expected Result:
- Feral Vampire result.attacker_destroyed == true.

---

Card Name: Immortal Vampire
Type: Character
Stats: ATK=30 DEF=80 Cost=1200 Affinity=CHAOS
AbilityType: DESTROY_SELF_VS_DIVINE_BOTH
ability_params: {'atk_bonus': 50, 'def_bonus': 0, 'affinity': 'CHAOS'}
Description: +30 ATK for each other exposed Chaos card on your side. In Reckoning with Divine, destroy this card.
Test Cases:

Test Case ID: TC-FUNC-Immortal-Vampire-001
Description:
Immortal Vampire: self-destruct when battling Divine (attacker or defender role)
Implementation Reference:
- BattleResolver early-return branches for Divine match
- AbilityType.DESTROY_SELF_VS_DIVINE_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine character involved in battle.
Steps:
Step 1: Battle Immortal Vampire vs Divine.
Expected Result:
- Immortal Vampire result.attacker_destroyed == true.

---

Card Name: Shadow Beast
Type: Character
Stats: ATK=35 DEF=35 Cost=400 Affinity=CHAOS
AbilityType: DESTROY_SELF_VS_DIVINE_BOTH
ability_params: {}
Description: -40 DEF to the defending foe until the end of foe’s turn. Destroy this card in Reckoning with Divine units.
Test Cases:

Test Case ID: TC-FUNC-Shadow-Beast-001
Description:
Shadow Beast: self-destruct when battling Divine (attacker or defender role)
Implementation Reference:
- BattleResolver early-return branches for Divine match
- AbilityType.DESTROY_SELF_VS_DIVINE_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine character involved in battle.
Steps:
Step 1: Battle Shadow Beast vs Divine.
Expected Result:
- Shadow Beast result.either_destroyed == true.

---

Card Name: Unearthed Warrior
Type: Character
Stats: ATK=50 DEF=50 Cost=500 Affinity=CHAOS
AbilityType: DESTROY_SELF_VS_DIVINE_BOTH
ability_params: {}
Description: +20 ATK if there is 5 or more units in your void. Destroy this card in Reckoning with Divine units.
Test Cases:

Test Case ID: TC-FUNC-Unearthed-Warrior-001
Description:
Unearthed Warrior: self-destruct when battling Divine (attacker or defender role)
Implementation Reference:
- BattleResolver early-return branches for Divine match
- AbilityType.DESTROY_SELF_VS_DIVINE_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine character involved in battle.
Steps:
Step 1: Battle Unearthed Warrior vs Divine.
Expected Result:
- Unearthed Warrior result.either_destroyed == true.

---

Card Name: Vampire Duchess
Type: Character
Stats: ATK=50 DEF=50 Cost=800 Affinity=CHAOS
AbilityType: DESTROY_SELF_VS_DIVINE_BOTH
ability_params: {'drain_atk': 5, 'drain_def': 5}
Description: In Reckoning with Divine, destroy this card. In Reckoning with non-Divine, Drain 5 ATK&DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Vampire-Duchess-001
Description:
Vampire Duchess: self-destruct when battling Divine (attacker or defender role)
Implementation Reference:
- BattleResolver early-return branches for Divine match
- AbilityType.DESTROY_SELF_VS_DIVINE_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Divine character involved in battle.
Steps:
Step 1: Battle Vampire Duchess vs Divine.
Expected Result:
- Vampire Duchess result.attacker_destroyed == true.

---

Card Name: Ivy Golem
Type: Character
Stats: ATK=85 DEF=105 Cost=1000 Affinity=NATURE
AbilityType: DOUBLE_TECH_EFFECT
ability_params: {'double_cost_reckoning': True}
Description: Unit in Reckoning with this card have its cost doubles until the end of your next turn.
Test Cases:

Test Case ID: TC-FUNC-Ivy-Golem-001
Description:
Ivy Golem: ability DOUBLE_TECH_EFFECT functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DOUBLE_TECH_EFFECT
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'double_cost_reckoning': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Unit in Reckoning with this card have its cost doubles until the end of your next turn.

---

Card Name: Mountain Sage
Type: Character
Stats: ATK=50 DEF=30 Cost=600 Affinity=ARCANE
AbilityType: DOUBLE_TECH_EFFECT
ability_params: {}
Description: Double effect of Tech card applied to this unit
Test Cases:

Test Case ID: TC-FUNC-Mountain-Sage-001
Description:
Mountain Sage: ability DOUBLE_TECH_EFFECT functional smoke test
Implementation Reference:
- CharacterData.AbilityType.DOUBLE_TECH_EFFECT
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Double effect of Tech card applied to this unit

---

Card Name: Black Anubis
Type: Character
Stats: ATK=75 DEF=90 Cost=1100 Affinity=DIVINE
AbilityType: END_OF_TURN_COIN_FLIP_STAT_BOOST
ability_params: {'atk': 5, 'def': 0, 'max_atk': 25}
Description: +5 ATK at your turn end. This bonus does not exceed 25
Test Cases:

Test Case ID: TC-FUNC-Black-Anubis-001
Description:
Black Anubis: end of turn coin +5 ATK or +0 DEF permanent
Implementation Reference:
- TurnManager._end_turn END_OF_TURN_COIN_FLIP_STAT_BOOST
- AbilityType.END_OF_TURN_COIN_FLIP_STAT_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Black Anubis face-up at end of own turn.
Steps:
Step 1: End turn.
Expected Result:
- Heads: current_atk += 5; Tails: current_def += 0.

---

Card Name: Hare Soldier
Type: Character
Stats: ATK=20 DEF=10 Cost=200 Affinity=NATURE
AbilityType: END_OF_TURN_COIN_FLIP_STAT_BOOST
ability_params: {'coin_flips': 2, 'atk': 5, 'def': 5, 'in_reckoning': True, 'per_head_atk': True, 'per_tail_def': True}
Description: In Reckoning, flip 2 coins. +5 ATK for each heads. +5 DEF for each tails
Test Cases:

Test Case ID: TC-FUNC-Hare-Soldier-001
Description:
Hare Soldier: end of turn coin +5 ATK or +5 DEF permanent
Implementation Reference:
- TurnManager._end_turn END_OF_TURN_COIN_FLIP_STAT_BOOST
- AbilityType.END_OF_TURN_COIN_FLIP_STAT_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hare Soldier face-up at end of own turn.
Steps:
Step 1: End turn.
Expected Result:
- Heads: current_atk += 5; Tails: current_def += 5.

---

Card Name: Tornado Genie
Type: Character
Stats: ATK=70 DEF=55 Cost=700 Affinity=ARCANE
AbilityType: END_OF_TURN_COIN_FLIP_STAT_BOOST
ability_params: {'coin_flips': 4, 'atk': 10, 'def': 10, 'in_reckoning': True, 'per_head_atk': True, 'per_tail_def': True}
Description: In Reckoning, flip 4 coins. +10 ATK for each heads. +10 DEF for each tails
Test Cases:

Test Case ID: TC-FUNC-Tornado-Genie-001
Description:
Tornado Genie: end of turn coin +10 ATK or +10 DEF permanent
Implementation Reference:
- TurnManager._end_turn END_OF_TURN_COIN_FLIP_STAT_BOOST
- AbilityType.END_OF_TURN_COIN_FLIP_STAT_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tornado Genie face-up at end of own turn.
Steps:
Step 1: End turn.
Expected Result:
- Heads: current_atk += 10; Tails: current_def += 10.

---

Card Name: Infiltrator Squad
Type: Character
Stats: ATK=15 DEF=10 Cost=180 Affinity=ANIMA
AbilityType: EXTRA_ATTACK_ON_DEAD_END
ability_params: {'max_per_turn': 2, 'grant_attack_count': 1}
Description: Up to twice per turn, If this card attacks a dead end card, gain 1 attack count.
Test Cases:

Test Case ID: TC-FUNC-Infiltrator-Squad-001
Description:
Infiltrator Squad: extra attack after hitting dead_end (once/turn)
Implementation Reference:
- TurnManager._apply_post_battle_effects
- AbilityType.EXTRA_ATTACK_ON_DEAD_END
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Target cell is dead_end.
Steps:
Step 1: Attack dead_end.
Expected Result:
- attacks_remaining += 1; flag extra_deadend_turn.

---

Card Name: Sonic Seraph
Type: Character
Stats: ATK=45 DEF=50 Cost=550 Affinity=DIVINE
AbilityType: EXTRA_ATTACK_ON_DEAD_END
ability_params: {}
Description: Once per turn, if it attacked Dead End, it can attack again
Test Cases:

Test Case ID: TC-FUNC-Sonic-Seraph-001
Description:
Sonic Seraph: extra attack after hitting dead_end (once/turn)
Implementation Reference:
- TurnManager._apply_post_battle_effects
- AbilityType.EXTRA_ATTACK_ON_DEAD_END
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Target cell is dead_end.
Steps:
Step 1: Attack dead_end.
Expected Result:
- attacks_remaining += 1; flag extra_deadend_turn.

---

Card Name: Tholin Lobster
Type: Character
Stats: ATK=15 DEF=15 Cost=200 Affinity=COSMIC
AbilityType: EXTRA_ATTACK_ON_DEAD_END
ability_params: {'vs_trap': True, 'per_turn': True, 'name_contains': 'Tholin'}
Description: Once per turn, If attacked a trap, all Tholin cards can attack again.
Test Cases:

Test Case ID: TC-FUNC-Tholin-Lobster-001
Description:
Tholin Lobster: extra attack after hitting dead_end (once/turn)
Implementation Reference:
- TurnManager._apply_post_battle_effects
- AbilityType.EXTRA_ATTACK_ON_DEAD_END
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Target cell is dead_end.
Steps:
Step 1: Attack dead_end.
Expected Result:
- attacks_remaining += 1; flag extra_deadend_turn.

---

Card Name: Echo Bringer
Type: Character
Stats: ATK=70 DEF=40 Cost=900 Affinity=COSMIC
AbilityType: EXTRA_ATTACK_VS_REVEALED
ability_params: {}
Description: When this card attacks a revealed card, it can attack a second time this turn (once per turn).
Test Cases:

Test Case ID: TC-FUNC-Echo-Bringer-001
Description:
Echo Bringer: extra attack when target was exposed before attack
Implementation Reference:
- TurnManager requires defender_was_exposed==true
- AbilityType.EXTRA_ATTACK_VS_REVEALED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender face-up before attack selected.
Steps:
Step 1: Attack with Echo Bringer.
Expected Result:
- attacks_remaining += 1 once per turn; flag extra_vs_revealed_used.

---

Card Name: Abominable Scientist
Type: Character
Stats: ATK=80 DEF=80 Cost=1000 Affinity=BIO
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'mutagen_flag': True, 'affinity': 'BIO', 'atk_bonus': 40, 'def_bonus': 40}
Description: Units with Mutagen Flag on your side gain +40ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Abominable-Scientist-001
Description:
Abominable Scientist: aura +0 ATK to own BIO characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Abominable Scientist face-up.
- Other face-up BIO ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from Abominable Scientist aura.

---

Card Name: Benjamin the Holy Craftsman
Type: Character
Stats: ATK=25 DEF=30 Cost=300 Affinity=DIVINE
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'affinity': 'DIVINE', 'atk_bonus': 10, 'def_bonus': 10, 'exclude_self': True}
Description: +10 ATK&DEF to other Divine card on your side
Test Cases:

Test Case ID: TC-FUNC-Benjamin-the-Holy-Craftsman-001
Description:
Benjamin the Holy Craftsman: aura +0 ATK to own DIVINE characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Benjamin the Holy Craftsman face-up.
- Other face-up DIVINE ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from Benjamin the Holy Craftsman aura.

---

Card Name: Devoted Scientist
Type: Character
Stats: ATK=0 DEF=90 Cost=400 Affinity=BIO
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'mutagen_flag': True, 'atk_bonus': 40, 'def_bonus': 40}
Description: Ally with Mutagen Flag gain +40ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Devoted-Scientist-001
Description:
Devoted Scientist: aura +0 ATK to own ? characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Devoted Scientist face-up.
- Other face-up ? ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from Devoted Scientist aura.

---

Card Name: Dragon Hunter Lumina
Type: Character
Stats: ATK=60 DEF=30 Cost=500 Affinity=ANIMA
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'affinity': 'ANIMA', 'atk_bonus': 40, 'vs_name_contains': 'Dragon'}
Description: All Anima ally units gain +40 ATK vs “Dragon” unit
Test Cases:

Test Case ID: TC-FUNC-Dragon-Hunter-Lumina-001
Description:
Dragon Hunter Lumina: aura +0 ATK to own ANIMA characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Dragon Hunter Lumina face-up.
- Other face-up ANIMA ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from Dragon Hunter Lumina aura.

---

Card Name: Elemental Master
Type: Character
Stats: ATK=20 DEF=60 Cost=800 Affinity=ARCANE
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'name_contains': 'elemental', 'atk': 60}
Description: While exposed, +60 ATK to ally Elemental units
Test Cases:

Test Case ID: TC-FUNC-Elemental-Master-001
Description:
Elemental Master: aura +60 ATK to own ? characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Elemental Master face-up.
- Other face-up ? ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +60 from Elemental Master aura.

---

Card Name: Fern the Mermaid Princess
Type: Character
Stats: ATK=30 DEF=30 Cost=350 Affinity=NATURE
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'affinity': 'NATURE', 'def_bonus': 10, 'attacked_this_turn': True, 'temp_until_foe_turn': True}
Description: Nature card that attacked this turn has +10 DEF until the end of foe’s turn.
Test Cases:

Test Case ID: TC-FUNC-Fern-the-Mermaid-Princess-001
Description:
Fern the Mermaid Princess: aura +0 ATK to own NATURE characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Fern the Mermaid Princess face-up.
- Other face-up NATURE ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from Fern the Mermaid Princess aura.

---

Card Name: Franky the Steel Claw
Type: Character
Stats: ATK=20 DEF=15 Cost=500 Affinity=CHAOS
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'temp': True, 'atk_bonus': 5, 'ally_only': True}
Description: +5 ATK to ally, until the end of this turn
Test Cases:

Test Case ID: TC-FUNC-Franky-the-Steel-Claw-001
Description:
Franky the Steel Claw: aura +0 ATK to own ? characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Franky the Steel Claw face-up.
- Other face-up ? ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from Franky the Steel Claw aura.

---

Card Name: Hive Overlord
Type: Character
Stats: ATK=40 DEF=75 Cost=950 Affinity=BIO
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'affinity': 'BIO', 'def_bonus': 50, 'double_cost': True}
Description: All ally Bio cards on your side gain +50 DEF. Double their cost.
Test Cases:

Test Case ID: TC-FUNC-Hive-Overlord-001
Description:
Hive Overlord: aura +0 ATK to own BIO characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hive Overlord face-up.
- Other face-up BIO ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from Hive Overlord aura.

---

Card Name: Orc Bannerlord
Type: Character
Stats: ATK=55 DEF=35 Cost=650 Affinity=CHAOS
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'name_contains': 'Orc', 'atk_bonus': 15, 'def_bonus': 15}
Description: All ally Orc units on your side get +15ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Orc-Bannerlord-001
Description:
Orc Bannerlord: aura +0 ATK to own ? characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Orc Bannerlord face-up.
- Other face-up ? ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from Orc Bannerlord aura.

---

Card Name: Sharoniel the Dragon Princess
Type: Character
Stats: ATK=40 DEF=60 Cost=520 Affinity=NATURE
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'name_contains': 'princess', 'atk_bonus': 30, 'exposed_only': True}
Description: Your exposed card with princess flag has +30 ATK
Test Cases:

Test Case ID: TC-FUNC-Sharoniel-the-Dragon-Princess-001
Description:
Sharoniel the Dragon Princess: aura +0 ATK to own ? characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Sharoniel the Dragon Princess face-up.
- Other face-up ? ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from Sharoniel the Dragon Princess aura.

---

Card Name: War Dragon
Type: Character
Stats: ATK=95 DEF=70 Cost=950 Affinity=ARCANE
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'name_contains': 'Dragon', 'atk_bonus': 10, 'def_bonus': 10}
Description: +10 ATK&DEF to ally Dragon units
Test Cases:

Test Case ID: TC-FUNC-War-Dragon-001
Description:
War Dragon: aura +0 ATK to own ? characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- War Dragon face-up.
- Other face-up ? ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from War Dragon aura.

---

Card Name: War Queen
Type: Character
Stats: ATK=70 DEF=80 Cost=1000 Affinity=ANIMA
AbilityType: FIELD_ATK_BOOST_OWN_AFFINITY
ability_params: {'name_contains': 'Knight', 'def_bonus': 50}
Description: +50 DEF to ally “Knight” cards.
Test Cases:

Test Case ID: TC-FUNC-War-Queen-001
Description:
War Queen: aura +0 ATK to own ? characters
Implementation Reference:
- BattleResolver field scan FIELD_ATK_BOOST_OWN_AFFINITY
- AbilityType.FIELD_ATK_BOOST_OWN_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- War Queen face-up.
- Other face-up ? ally attacks.
Steps:
Step 1: Ally attacks while aura source exposed.
Expected Result:
- Ally attacker_atk_used includes +0 from War Queen aura.

---

Card Name: Restless Soldier
Type: Character
Stats: ATK=30 DEF=20 Cost=420 Affinity=CHAOS
AbilityType: FIELD_DEBUFF_ALL_VENOM_CARDS
ability_params: {'atk': 5, 'def': 5, 'per_void_unit': True, 'target': 'foe_reckoning'}
Description: -5 ATK&DEF to foe’s unit in Reckoning per units in your void
Test Cases:

Test Case ID: TC-FUNC-Restless-Soldier-001
Description:
Restless Soldier: -5 ATK&DEF aura on all venom-flagged cards while exposed
Implementation Reference:
- BattleResolver._apply_venom_queen_global_debuff
- AbilityType.FIELD_DEBUFF_ALL_VENOM_CARDS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Restless Soldier face-up.
- Another card has venom flag.
Steps:
Step 1: Recalculate field bonuses.
Expected Result:
- Venom-flagged cards get field_aura ATK/DEF -= 5/5.

---

Card Name: Venom Queen
Type: Character
Stats: ATK=45 DEF=75 Cost=550 Affinity=NATURE
AbilityType: FIELD_DEBUFF_ALL_VENOM_CARDS
ability_params: {'atk': 15, 'def': 15}
Description: While this card remains exposed, -15 ATK&DEF to all cards with Venom Flag
Test Cases:

Test Case ID: TC-FUNC-Venom-Queen-001
Description:
Venom Queen: -15 ATK&DEF aura on all venom-flagged cards while exposed
Implementation Reference:
- BattleResolver._apply_venom_queen_global_debuff
- AbilityType.FIELD_DEBUFF_ALL_VENOM_CARDS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Venom Queen face-up.
- Another card has venom flag.
Steps:
Step 1: Recalculate field bonuses.
Expected Result:
- Venom-flagged cards get field_aura ATK/DEF -= 15/15.

---

Card Name: Armored Unicorn
Type: Character
Stats: ATK=45 DEF=45 Cost=500 Affinity=DIVINE
AbilityType: GAIN_HALF_STATS_ON_SURVIVE
ability_params: {'atk': 15, 'def': 15, 'permanent': True}
Description: If this card survived Reckoning, +15 ATK&DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Armored-Unicorn-001
Description:
Armored Unicorn: gain half of opponent ATK/DEF after surviving battle
Implementation Reference:
- TurnManager._apply_post_battle_effects GAIN_HALF_STATS_ON_SURVIVE
- AbilityType.GAIN_HALF_STATS_ON_SURVIVE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Armored Unicorn attacks character and survives.
Steps:
Step 1: Complete battle.
Expected Result:
- current_atk += defender.current_atk/2; current_def += defender.current_def/2.

---

Card Name: Evolving Cell
Type: Character
Stats: ATK=75 DEF=55 Cost=1200 Affinity=BIO
AbilityType: HALVE_ATK_ADD_TO_DEF_ON_DEFEND
ability_params: {'once': True, 'drain': 35, 'zero_def_untargetable': True}
Description: Cannot select unit with 0 DEF as attack target. Once, if defended, drain 35 ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Evolving-Cell-001
Description:
Evolving Cell: on defend, halve ATK and add to DEF permanently
Implementation Reference:
- BattleResolver._apply_defend_effects HALVE_ATK_ADD_TO_DEF_ON_DEFEND
- AbilityType.HALVE_ATK_ADD_TO_DEF_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Evolving Cell defends and survives.
Steps:
Step 1: Resolve defense.
Expected Result:
- current_atk halved; current_def += halved amount.

---

Card Name: Magenta the Nightbloom
Type: Character
Stats: ATK=25 DEF=40 Cost=300 Affinity=CHAOS
AbilityType: HALVE_DEF_ON_FIRST_EXPOSE
ability_params: {}
Description: Half its DEF permanently at the end of that turn
Test Cases:

Test Case ID: TC-FUNC-Magenta-the-Nightbloom-001
Description:
Magenta the Nightbloom: halve DEF permanently on first reveal
Implementation Reference:
- GameState.reveal_card hook
- AbilityType.HALVE_DEF_ON_FIRST_EXPOSE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Magenta the Nightbloom face-down.
Steps:
Step 1: Reveal Magenta the Nightbloom.
Expected Result:
- current_def = 20 (half of 40, permanent).

---

Card Name: Stealth Archer
Type: Character
Stats: ATK=60 DEF=40 Cost=500 Affinity=ANIMA
AbilityType: HALVE_DEF_ON_FIRST_EXPOSE
ability_params: {'also_atk': True, 'expose_turn_end': True}
Description: Halve this card ATK&DEF at the end of the exposed turn.
Test Cases:

Test Case ID: TC-FUNC-Stealth-Archer-001
Description:
Stealth Archer: halve DEF permanently on first reveal
Implementation Reference:
- GameState.reveal_card hook
- AbilityType.HALVE_DEF_ON_FIRST_EXPOSE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Stealth Archer face-down.
Steps:
Step 1: Reveal Stealth Archer.
Expected Result:
- current_def = 20 (half of 40, permanent).

---

Card Name: Gorewood the Hooded Killer
Type: Character
Stats: ATK=80 DEF=40 Cost=600 Affinity=CHAOS
AbilityType: HALVE_STATS_AFTER_ATTACK
ability_params: {}
Description: Once, at the end of exposed turn, if you have less than 8 units in your void, halve its attack.
Test Cases:

Test Case ID: TC-FUNC-Gorewood-the-Hooded-Killer-001
Description:
Gorewood the Hooded Killer: ability HALVE_STATS_AFTER_ATTACK functional smoke test
Implementation Reference:
- CharacterData.AbilityType.HALVE_STATS_AFTER_ATTACK
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, at the end of exposed turn, if you have less than 8 units in your void, halve its attack.

---

Card Name: Silent Stabber
Type: Character
Stats: ATK=40 DEF=10 Cost=280 Affinity=CHAOS
AbilityType: HALVE_STATS_AFTER_ATTACK
ability_params: {'expose_turn_end': True, 'once': True}
Description: Once, at the end of exposed turn, halve its ATK.
Test Cases:

Test Case ID: TC-FUNC-Silent-Stabber-001
Description:
Silent Stabber: ability HALVE_STATS_AFTER_ATTACK functional smoke test
Implementation Reference:
- CharacterData.AbilityType.HALVE_STATS_AFTER_ATTACK
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'expose_turn_end': True, 'once': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, at the end of exposed turn, halve its ATK.

---

Card Name: Ninjamaster Sasuya
Type: Character
Stats: ATK=65 DEF=50 Cost=900 Affinity=ANIMA
AbilityType: IMMUNE_DESTROY_BY_NON_UNION
ability_params: {'name_contains': 'Ninja', 'ally_aura': True}
Description: Ally Ninja units is not destroyed in Reckoning.
Test Cases:

Test Case ID: TC-FUNC-Ninjamaster-Sasuya-001
Description:
Ninjamaster Sasuya: ability IMMUNE_DESTROY_BY_NON_UNION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.IMMUNE_DESTROY_BY_NON_UNION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'name_contains': 'Ninja', 'ally_aura': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Ally Ninja units is not destroyed in Reckoning.

---

Card Name: Agent Rick
Type: Character
Stats: ATK=30 DEF=10 Cost=350 Affinity=ANIMA
AbilityType: IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP
ability_params: {'name_contains': 'Agent'}
Description: This card is not destroyed while Agent card is face-up on your side
Test Cases:

Test Case ID: TC-FUNC-Agent-Rick-001
Description:
Agent Rick: cannot be destroyed while another ANIMA ally face-up
Implementation Reference:
- BattleResolver post-compare IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP
- AbilityType.IMMUNE_IF_OWN_SAME_AFFINITY_FACE_UP
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Another face-up ANIMA ally on field.
- Agent Rick would be destroyed.
Steps:
Step 1: Resolve battle that would destroy defender.
Expected Result:
- defender_destroyed reverted to false; defender_crystal_loss=0.

---

Card Name: Ancient Lich
Type: Character
Stats: ATK=60 DEF=60 Cost=750 Affinity=CHAOS
AbilityType: IMMUNE_TO_TECH_CARDS
ability_params: {}
Description: This card is unaffected by Tech cards.
Test Cases:

Test Case ID: TC-FUNC-Ancient-Lich-001
Description:
Ancient Lich: unaffected by Tech
Implementation Reference:
- GameBoard tech target filters skip IMMUNE cards
- AbilityType.IMMUNE_TO_TECH_CARDS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent plays Accident targeting Ancient Lich.
Steps:
Step 1: Select Ancient Lich if UI allows.
Expected Result:
- Ancient Lich not destroyed; no stat change from Tech.

---

Card Name: Araya the Eerie Dancer
Type: Character
Stats: ATK=15 DEF=20 Cost=400 Affinity=CHAOS
AbilityType: IMMUNE_TO_TECH_CARDS
ability_params: {}
Description: This card is unaffected by Tech cards
Test Cases:

Test Case ID: TC-FUNC-Araya-the-Eerie-Dancer-001
Description:
Araya the Eerie Dancer: unaffected by Tech
Implementation Reference:
- GameBoard tech target filters skip IMMUNE cards
- AbilityType.IMMUNE_TO_TECH_CARDS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent plays Accident targeting Araya the Eerie Dancer.
Steps:
Step 1: Select Araya the Eerie Dancer if UI allows.
Expected Result:
- Araya the Eerie Dancer not destroyed; no stat change from Tech.

---

Card Name: Flying Dutchman
Type: Character
Stats: ATK=90 DEF=65 Cost=900 Affinity=CHAOS
AbilityType: IMMUNE_TO_TECH_CARDS
ability_params: {'once_trap_immune': True}
Description: This card is not affected by tech. Once, this card is not affected by trap.
Test Cases:

Test Case ID: TC-FUNC-Flying-Dutchman-001
Description:
Flying Dutchman: unaffected by Tech
Implementation Reference:
- GameBoard tech target filters skip IMMUNE cards
- AbilityType.IMMUNE_TO_TECH_CARDS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent plays Accident targeting Flying Dutchman.
Steps:
Step 1: Select Flying Dutchman if UI allows.
Expected Result:
- Flying Dutchman not destroyed; no stat change from Tech.

---

Card Name: The Ancient One
Type: Character
Stats: ATK=85 DEF=90 Cost=1500 Affinity=ARCANE
AbilityType: IMMUNE_TO_TECH_CARDS
ability_params: {}
Description: Foe cannot use Tech cards while this card is exposed. This card is unaffected by tech or traps.
Test Cases:

Test Case ID: TC-FUNC-The-Ancient-One-001
Description:
The Ancient One: unaffected by Tech
Implementation Reference:
- GameBoard tech target filters skip IMMUNE cards
- AbilityType.IMMUNE_TO_TECH_CARDS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent plays Accident targeting The Ancient One.
Steps:
Step 1: Select The Ancient One if UI allows.
Expected Result:
- The Ancient One not destroyed; no stat change from Tech.

---

Card Name: Ironclad Sentinel
Type: Character
Stats: ATK=55 DEF=95 Cost=1100 Affinity=ANIMA
AbilityType: IMMUNE_TO_TECH_DESTRUCTION
ability_params: {}
Description: Immune to 0-cost Traps. This Unit cannot be destroyed by Tech Cards.
Test Cases:

Test Case ID: TC-FUNC-Ironclad-Sentinel-001
Description:
Ironclad Sentinel: ability IMMUNE_TO_TECH_DESTRUCTION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.IMMUNE_TO_TECH_DESTRUCTION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Immune to 0-cost Traps. This Unit cannot be destroyed by Tech Cards.

---

Card Name: Ant Lion
Type: Character
Stats: ATK=90 DEF=90 Cost=900 Affinity=NATURE
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: This card is unaffected by Trap cards
Test Cases:

Test Case ID: TC-FUNC-Ant-Lion-001
Description:
Ant Lion: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Ant Lion attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Dragonfire Tank
Type: Character
Stats: ATK=125 DEF=100 Cost=1300 Affinity=ANIMA
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: Unaffected by trap cards. In Reckoning with unit with 40 ATK or less, destroy that unit.
Test Cases:

Test Case ID: TC-FUNC-Dragonfire-Tank-001
Description:
Dragonfire Tank: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Dragonfire Tank attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Goat Head
Type: Character
Stats: ATK=25 DEF=10 Cost=400 Affinity=CHAOS
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: This card is unaffected by Trap cards
Test Cases:

Test Case ID: TC-FUNC-Goat-Head-001
Description:
Goat Head: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Goat Head attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Jet Trooper
Type: Character
Stats: ATK=70 DEF=60 Cost=750 Affinity=ANIMA
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: Once, this card is unaffected by trap
Test Cases:

Test Case ID: TC-FUNC-Jet-Trooper-001
Description:
Jet Trooper: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Jet Trooper attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Krahang
Type: Character
Stats: ATK=15 DEF=15 Cost=380 Affinity=CHAOS
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: Once, this card is unaffected by trap
Test Cases:

Test Case ID: TC-FUNC-Krahang-001
Description:
Krahang: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Krahang attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Mad Familiar
Type: Character
Stats: ATK=25 DEF=0 Cost=180 Affinity=CHAOS
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: This card is unaffected by traps if there is 5 or more units in your void.
Test Cases:

Test Case ID: TC-FUNC-Mad-Familiar-001
Description:
Mad Familiar: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Mad Familiar attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Prowler Tank
Type: Character
Stats: ATK=50 DEF=70 Cost=650 Affinity=ANIMA
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: Unaffected by trap cards
Test Cases:

Test Case ID: TC-FUNC-Prowler-Tank-001
Description:
Prowler Tank: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Prowler Tank attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Thunderclap Tank
Type: Character
Stats: ATK=110 DEF=80 Cost=980 Affinity=ANIMA
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: Unaffected by trap cards. Once, this card is not destroyed.
Test Cases:

Test Case ID: TC-FUNC-Thunderclap-Tank-001
Description:
Thunderclap Tank: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Thunderclap Tank attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Tomb Bandit
Type: Character
Stats: ATK=75 DEF=60 Cost=1000 Affinity=ANIMA
AbilityType: IMMUNE_TO_TRAPS
ability_params: {}
Description: This Unit cannot be destroyed by Traps. It gets -20 DEF permanently if it attacked a trap card.
Test Cases:

Test Case ID: TC-FUNC-Tomb-Bandit-001
Description:
Tomb Bandit: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Tomb Bandit attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Xenospawn
Type: Character
Stats: ATK=100 DEF=95 Cost=1200 Affinity=COSMIC
AbilityType: IMMUNE_TO_TRAPS
ability_params: {'atk_def_loss_vs_trap': 15}
Description: This card is not affected by traps. This card get -15 ATK&DEF each time it attacked a trap.
Test Cases:

Test Case ID: TC-FUNC-Xenospawn-001
Description:
Xenospawn: immune to all traps
Implementation Reference:
- BattleResolver._resolve_trap IMMUNE_TO_TRAPS
- AbilityType.IMMUNE_TO_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Any trap including Spike Trap (1500 cost).
- Xenospawn attacks trap.
Steps:
Step 1: Resolve trap trigger.
Expected Result:
- special_trigger=='trap_nullified'; attacker survives.

---

Card Name: Bison Tank
Type: Character
Stats: ATK=65 DEF=50 Cost=700 Affinity=ANIMA
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: Unaffected by 0-cost trap cards. In Reckoning with unit with 10 ATK or less, destroy that unit.
Test Cases:

Test Case ID: TC-FUNC-Bison-Tank-001
Description:
Bison Tank: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Bison Tank as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Flak Tank
Type: Character
Stats: ATK=20 DEF=25 Cost=250 Affinity=ANIMA
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: Unaffected by 0-cost trap cards
Test Cases:

Test Case ID: TC-FUNC-Flak-Tank-001
Description:
Flak Tank: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Flak Tank as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Gremlin Worker
Type: Character
Stats: ATK=15 DEF=15 Cost=200 Affinity=ARCANE
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: This card is unaffected by 0 cost traps
Test Cases:

Test Case ID: TC-FUNC-Gremlin-Worker-001
Description:
Gremlin Worker: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Gremlin Worker as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Huntress of Green Glade
Type: Character
Stats: ATK=50 DEF=50 Cost=800 Affinity=ANIMA
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: Immune to 0-cost Traps
Test Cases:

Test Case ID: TC-FUNC-Huntress-of-Green-Glade-001
Description:
Huntress of Green Glade: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Huntress of Green Glade as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Laser Walker
Type: Character
Stats: ATK=20 DEF=10 Cost=250 Affinity=COSMIC
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: This card is not affected by 0 cost traps
Test Cases:

Test Case ID: TC-FUNC-Laser-Walker-001
Description:
Laser Walker: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Laser Walker as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Mars Drill
Type: Character
Stats: ATK=40 DEF=30 Cost=400 Affinity=COSMIC
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: This card is not affected by 0 cost traps
Test Cases:

Test Case ID: TC-FUNC-Mars-Drill-001
Description:
Mars Drill: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Mars Drill as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Mini Tank
Type: Character
Stats: ATK=20 DEF=20 Cost=320 Affinity=ANIMA
AbilityType: IMMUNE_ZERO_COST_TRAPS
ability_params: {}
Description: Once, this card is unaffected by 0-cost traps
Test Cases:

Test Case ID: TC-FUNC-Mini-Tank-001
Description:
Mini Tank: nullifies 0-cost trap activation
Implementation Reference:
- BattleResolver._resolve_trap: IMMUNE_ZERO_COST_TRAPS → special_trigger=trap_nullified
- AbilityType.IMMUNE_ZERO_COST_TRAPS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent Trap Hole (cost 0) face-down.
- Mini Tank as attacker.
Steps:
Step 1: Attack trap cell.
Expected Result:
- result.special_trigger == 'trap_nullified'.
- Attacker NOT destroyed by trap.
- Trap still consumed from grid.

---

Card Name: Bat Swarm
Type: Character
Stats: ATK=15 DEF=15 Cost=200 Affinity=CHAOS
AbilityType: INTERCEPT_ALLY_ATTACK
ability_params: {'affinity': 'CHAOS'}
Description: If a Chaos card on your side is being attacked, you may swap this card's position with that card. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Bat-Swarm-001
Description:
Bat Swarm: swap position with attacked CHAOS ally
Implementation Reference:
- TurnManager pre-attack INTERCEPT_ALLY_ATTACK prompt
- AbilityType.INTERCEPT_ALLY_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Another CHAOS ally targeted.
- Bat Swarm on field.
Steps:
Step 1: When ally attacked, accept intercept.
Expected Result:
- Positions swap; original target unchanged.

---

Card Name: Blood Hound
Type: Character
Stats: ATK=60 DEF=80 Cost=850 Affinity=NATURE
AbilityType: INTERCEPT_ALLY_ATTACK
ability_params: {'target': 'dead_end', 'swap_self': True, 'face_down': True}
Description: When foe attacks a Dead End, swap this card with it. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Blood-Hound-001
Description:
Blood Hound: swap position with attacked ? ally
Implementation Reference:
- TurnManager pre-attack INTERCEPT_ALLY_ATTACK prompt
- AbilityType.INTERCEPT_ALLY_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Another ? ally targeted.
- Blood Hound on field.
Steps:
Step 1: When ally attacked, accept intercept.
Expected Result:
- Positions swap; original target unchanged.

---

Card Name: Freya the Rift Walker
Type: Character
Stats: ATK=25 DEF=35 Cost=400 Affinity=ARCANE
AbilityType: INTERCEPT_ALLY_ATTACK
ability_params: {'affinity': 'ARCANE', 'swap_self': True, 'face_down': True}
Description: When ally Arcane unit is targeted, you can swap it with this card. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Freya-the-Rift-Walker-001
Description:
Freya the Rift Walker: swap position with attacked ARCANE ally
Implementation Reference:
- TurnManager pre-attack INTERCEPT_ALLY_ATTACK prompt
- AbilityType.INTERCEPT_ALLY_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Another ARCANE ally targeted.
- Freya the Rift Walker on field.
Steps:
Step 1: When ally attacked, accept intercept.
Expected Result:
- Positions swap; original target unchanged.

---

Card Name: Sweet Lure Pod
Type: Character
Stats: ATK=0 DEF=30 Cost=200 Affinity=BIO
AbilityType: INTERCEPT_ALLY_ATTACK
ability_params: {'force_target_self': True, 'this_turn': True}
Description: This turn, foe can only target this card for an attack.
Test Cases:

Test Case ID: TC-FUNC-Sweet-Lure-Pod-001
Description:
Sweet Lure Pod: swap position with attacked ? ally
Implementation Reference:
- TurnManager pre-attack INTERCEPT_ALLY_ATTACK prompt
- AbilityType.INTERCEPT_ALLY_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Another ? ally targeted.
- Sweet Lure Pod on field.
Steps:
Step 1: When ally attacked, accept intercept.
Expected Result:
- Positions swap; original target unchanged.

---

Card Name: Alluring Spellcaster
Type: Character
Stats: ATK=20 DEF=15 Cost=500 Affinity=ARCANE
AbilityType: LIMIT_FOE_ATTACKS_COIN_FLIP_ONCE
ability_params: {}
Description: Once, at foe’s turn start, flip a coin. Head: foe can only attack once.
Test Cases:

Test Case ID: TC-FUNC-Alluring-Spellcaster-001
Description:
Alluring Spellcaster: ability LIMIT_FOE_ATTACKS_COIN_FLIP_ONCE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.LIMIT_FOE_ATTACKS_COIN_FLIP_ONCE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, at foe’s turn start, flip a coin. Head: foe can only attack once.

---

Card Name: Skeleton Grappler
Type: Character
Stats: ATK=20 DEF=5 Cost=150 Affinity=CHAOS
AbilityType: LOCK_ATTACKER_ON_DEFEND
ability_params: {}
Description: After Reckoning: that foe’s unit cannot attack until foe’s turn ends
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Grappler-001
Description:
Skeleton Grappler: attacker locked after defending
Implementation Reference:
- TurnManager post-defend lock
- AbilityType.LOCK_ATTACKER_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks; Skeleton Grappler defends successfully.
Steps:
Step 1: Next opponent turn: same attacker cannot attack.
Expected Result:
- Attacker cannot_attack_until set.

---

Card Name: Spider Lady
Type: Character
Stats: ATK=30 DEF=30 Cost=450 Affinity=CHAOS
AbilityType: LOCK_ATTACKER_ON_DEFEND
ability_params: {'once': True}
Description: Once, unit in Reckoning with this card cannot attack until foe’s next turn end.
Test Cases:

Test Case ID: TC-FUNC-Spider-Lady-001
Description:
Spider Lady: attacker locked after defending
Implementation Reference:
- TurnManager post-defend lock
- AbilityType.LOCK_ATTACKER_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks; Spider Lady defends successfully.
Steps:
Step 1: Next opponent turn: same attacker cannot attack.
Expected Result:
- Attacker cannot_attack_until set.

---

Card Name: Stinky Insect
Type: Character
Stats: ATK=10 DEF=10 Cost=400 Affinity=NATURE
AbilityType: LOCK_ATTACKER_ON_DEFEND
ability_params: {}
Description: If this card defends, the attacking unit cannot attack until foe’s next turn ends
Test Cases:

Test Case ID: TC-FUNC-Stinky-Insect-001
Description:
Stinky Insect: attacker locked after defending
Implementation Reference:
- TurnManager post-defend lock
- AbilityType.LOCK_ATTACKER_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent attacks; Stinky Insect defends successfully.
Steps:
Step 1: Next opponent turn: same attacker cannot attack.
Expected Result:
- Attacker cannot_attack_until set.

---

Card Name: Parasite Queen
Type: Character
Stats: ATK=25 DEF=150 Cost=920 Affinity=BIO
AbilityType: LOCK_ATTACKER_ON_DESTROYED
ability_params: {'attacker_not_destroyed': True}
Description: After this card defended successfully, the attacker is not destroyed but also cannot attack ever again.
Test Cases:

Test Case ID: TC-FUNC-Parasite-Queen-001
Description:
Parasite Queen: destroyer cannot attack rest of turn
Implementation Reference:
- TurnManager sets attacks_remaining=0
- AbilityType.LOCK_ATTACKER_ON_DESTROYED
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent destroys Parasite Queen.
Steps:
Step 1: Same turn: attacker has attacks_remaining=0.
Expected Result:

---

Card Name: Full-armored Seraphim
Type: Character
Stats: ATK=150 DEF=150 Cost=2500 Affinity=DIVINE
AbilityType: LOCK_SELF_AFTER_ATTACK
ability_params: {'cannot_attack_facedown': True}
Description: This card cannot attack face-down cards. After this card performed attack, it cannot attack on your next turn.
Test Cases:

Test Case ID: TC-FUNC-Full-armored-Seraphim-001
Description:
Full-armored Seraphim: cannot attack next turn after attacking
Implementation Reference:
- cannot_attack_until = turn_number+2
- AbilityType.LOCK_SELF_AFTER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Full-armored Seraphim attacks.
Steps:
Step 1: End turn; next own turn try to attack with Full-armored Seraphim.
Expected Result:
- Full-armored Seraphim not selectable as attacker next turn.

---

Card Name: Ostrich Cannon
Type: Character
Stats: ATK=60 DEF=30 Cost=800 Affinity=NATURE
AbilityType: LOCK_SELF_AFTER_ATTACK
ability_params: {}
Description: After performing an attack, this card cannot attack during your next turn.
Test Cases:

Test Case ID: TC-FUNC-Ostrich-Cannon-001
Description:
Ostrich Cannon: cannot attack next turn after attacking
Implementation Reference:
- cannot_attack_until = turn_number+2
- AbilityType.LOCK_SELF_AFTER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Ostrich Cannon attacks.
Steps:
Step 1: End turn; next own turn try to attack with Ostrich Cannon.
Expected Result:
- Ostrich Cannon not selectable as attacker next turn.

---

Card Name: Railgun Tank
Type: Character
Stats: ATK=150 DEF=95 Cost=1500 Affinity=ANIMA
AbilityType: LOCK_SELF_AFTER_ATTACK
ability_params: {}
Description: After a successful attack, this card cannot attack on the next of your turn.
Test Cases:

Test Case ID: TC-FUNC-Railgun-Tank-001
Description:
Railgun Tank: cannot attack next turn after attacking
Implementation Reference:
- cannot_attack_until = turn_number+2
- AbilityType.LOCK_SELF_AFTER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Railgun Tank attacks.
Steps:
Step 1: End turn; next own turn try to attack with Railgun Tank.
Expected Result:
- Railgun Tank not selectable as attacker next turn.

---

Card Name: Thunder Daddy
Type: Character
Stats: ATK=120 DEF=120 Cost=2000 Affinity=ARCANE
AbilityType: LOCK_SELF_AFTER_ATTACK
ability_params: {'exclusive_attacker': True, 'after_expose': True}
Description: After exposed, you can only command this card (and not any card else) for an attack.
Test Cases:

Test Case ID: TC-FUNC-Thunder-Daddy-001
Description:
Thunder Daddy: cannot attack next turn after attacking
Implementation Reference:
- cannot_attack_until = turn_number+2
- AbilityType.LOCK_SELF_AFTER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Thunder Daddy attacks.
Steps:
Step 1: End turn; next own turn try to attack with Thunder Daddy.
Expected Result:
- Thunder Daddy not selectable as attacker next turn.

---

Card Name: Leopard Jailer
Type: Character
Stats: ATK=30 DEF=45 Cost=450 Affinity=ANIMA
AbilityType: LOCK_TARGET_ON_ATTACK
ability_params: {}
Description: If this card attacks a unit card, the target is unable to attack until the end of foe’s turn.
Test Cases:

Test Case ID: TC-FUNC-Leopard-Jailer-001
Description:
Leopard Jailer: lock attacked character from attacking next turn
Implementation Reference:
- TurnManager sets defender.cannot_attack_until = turn_number+1
- AbilityType.LOCK_TARGET_ON_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender survives attack.
Steps:
Step 1: Attack character with Leopard Jailer.
Expected Result:
- Target cannot_attack_until prevents selection next turn.

---

Card Name: Snow Dragon
Type: Character
Stats: ATK=60 DEF=60 Cost=1000 Affinity=ARCANE
AbilityType: LOCK_TARGET_ON_ATTACK
ability_params: {'when_exposed': True, 'select_foe': True, 'until_foe_turn_end': True}
Description: Exposed : Select 1 of foe’s face-up unit, it cannot attack until the foe’s next turn end.
Test Cases:

Test Case ID: TC-FUNC-Snow-Dragon-001
Description:
Snow Dragon: lock attacked character from attacking next turn
Implementation Reference:
- TurnManager sets defender.cannot_attack_until = turn_number+1
- AbilityType.LOCK_TARGET_ON_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender survives attack.
Steps:
Step 1: Attack character with Snow Dragon.
Expected Result:
- Target cannot_attack_until prevents selection next turn.

---

Card Name: Battle Maid Naru
Type: Character
Stats: ATK=5 DEF=20 Cost=240 Affinity=ANIMA
AbilityType: MOON_ALLY_FIELD_AURA
ability_params: {'affinity': 'ANIMA', 'atk_bonus': 5, 'def_bonus': 5, 'intercept_anima': True}
Description: All Anima ally units gain +5 ATK&DEF. You can flip this card face-up if other Anima unit is targeted for attack.
Test Cases:

Test Case ID: TC-FUNC-Battle-Maid-Naru-001
Description:
Battle Maid Naru: ability MOON_ALLY_FIELD_AURA functional smoke test
Implementation Reference:
- CharacterData.AbilityType.MOON_ALLY_FIELD_AURA
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'ANIMA', 'atk_bonus': 5, 'def_bonus': 5, 'intercept_anima': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: All Anima ally units gain +5 ATK&DEF. You can flip this card face-up if other Anima unit is targeted for attack.

---

Card Name: Lunar Wraith
Type: Character
Stats: ATK=30 DEF=20 Cost=500 Affinity=COSMIC
AbilityType: MOON_ALLY_FIELD_AURA
ability_params: {'name_contains': 'moon', 'atk': 15, 'def': 15, 'self_atk': 30}
Description: +15 ATK&DEF to all exposed Moon card on your side. +30 ATK to itself if there is exposed Moon card on your side
Test Cases:

Test Case ID: TC-FUNC-Lunar-Wraith-001
Description:
Lunar Wraith: ability MOON_ALLY_FIELD_AURA functional smoke test
Implementation Reference:
- CharacterData.AbilityType.MOON_ALLY_FIELD_AURA
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'name_contains': 'moon', 'atk': 15, 'def': 15, 'self_atk': 30}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +15 ATK&DEF to all exposed Moon card on your side. +30 ATK to itself if there is exposed Moon card on your side

---

Card Name: Agent Matts
Type: Character
Stats: ATK=20 DEF=20 Cost=200 Affinity=ANIMA
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'requires_name': 'Agent', 'once': True}
Description: Once, attack twice if there is face-up Agent card on your side
Test Cases:

Test Case ID: TC-FUNC-Agent-Matts-001
Description:
Agent Matts: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Blind Jaw
Type: Character
Stats: ATK=150 DEF=75 Cost=1200 Affinity=BIO
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 1, 'only_exposed_targets': True, 'without_mutagen': True}
Description: This card can only attack exposed cards. Without Mutagen Flag : It can only attack once.
Test Cases:

Test Case ID: TC-FUNC-Blind-Jaw-001
Description:
Blind Jaw: up to 1 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 1 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Coffin Spider
Type: Character
Stats: ATK=25 DEF=25 Cost=250 Affinity=CHAOS
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'crystal_cost': 500}
Description: At the start of your turn, you can pay 500 crystals allow this card to attack twice.
Test Cases:

Test Case ID: TC-FUNC-Coffin-Spider-001
Description:
Coffin Spider: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Elven Huntsman
Type: Character
Stats: ATK=40 DEF=35 Cost=400 Affinity=NATURE
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'adjacent_affinity': 'NATURE', 'once': True, 'face_down': True}
Description: Once, Nature card in surrounding cell can attack twice. Usable face-down
Test Cases:

Test Case ID: TC-FUNC-Elven-Huntsman-001
Description:
Elven Huntsman: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Fierce Cavalry
Type: Character
Stats: ATK=50 DEF=25 Cost=700 Affinity=ANIMA
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'attack_cost': 2, 'vs_facedown_bonus': 50}
Description: Consumes 2 attack count. + 50 ATK vs face-down card
Test Cases:

Test Case ID: TC-FUNC-Fierce-Cavalry-001
Description:
Fierce Cavalry: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Golden Knight
Type: Character
Stats: ATK=100 DEF=90 Cost=1200 Affinity=ANIMA
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'attack_cost': 2}
Description: Consumes 2 attack count
Test Cases:

Test Case ID: TC-FUNC-Golden-Knight-001
Description:
Golden Knight: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Headless Rider
Type: Character
Stats: ATK=30 DEF=10 Cost=400 Affinity=CHAOS
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'attack_cost': 2, 'once': True}
Description: Once, this card can consume 2 attack count and attack twice
Test Cases:

Test Case ID: TC-FUNC-Headless-Rider-001
Description:
Headless Rider: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Howard the Trigger Happy
Type: Character
Stats: ATK=40 DEF=30 Cost=500 Affinity=ANIMA
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 3, 'once': True, 'double_cost': True}
Description: Once, this card can attack thrice, but double its cost.
Test Cases:

Test Case ID: TC-FUNC-Howard-the-Trigger-Happy-001
Description:
Howard the Trigger Happy: up to 3 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 3 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Hydra
Type: Character
Stats: ATK=105 DEF=90 Cost=1400 Affinity=BIO
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 3, 'attack_cost': 2, 'mutagen': True}
Description: Consumes 2 attack count. With Mutagen Flag : This card can attack 3 times
Test Cases:

Test Case ID: TC-FUNC-Hydra-001
Description:
Hydra: up to 3 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 3 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Nachzehrer
Type: Character
Stats: ATK=80 DEF=75 Cost=900 Affinity=CHAOS
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'requires_affinity_on_field': 'ANIMA', 'name_contains': 'Vampire', 'atk_per_match': 15}
Description: +15 ATK for each Vampire card the field. Can attack twice if there is Anima card on the field.
Test Cases:

Test Case ID: TC-FUNC-Nachzehrer-001
Description:
Nachzehrer: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Orc Berserker
Type: Character
Stats: ATK=75 DEF=25 Cost=800 Affinity=CHAOS
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'once': True}
Description: Once, this card can attack twice
Test Cases:

Test Case ID: TC-FUNC-Orc-Berserker-001
Description:
Orc Berserker: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Paladin of Avalon
Type: Character
Stats: ATK=140 DEF=120 Cost=1500 Affinity=ANIMA
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'attack_cost': 2, 'lock_next_turn': True}
Description: Consumes 2 attack count. After performed attack, it cannot attack during your next turn.
Test Cases:

Test Case ID: TC-FUNC-Paladin-of-Avalon-001
Description:
Paladin of Avalon: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Parasite Dione
Type: Character
Stats: ATK=45 DEF=60 Cost=800 Affinity=COSMIC
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 2, 'mutagen': True}
Description: With Mutagen Flag : This card can attack twice
Test Cases:

Test Case ID: TC-FUNC-Parasite-Dione-001
Description:
Parasite Dione: up to 2 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 2 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Red Closet
Type: Character
Stats: ATK=65 DEF=60 Cost=900 Affinity=CHAOS
AbilityType: MULTI_ATTACK_ANY
ability_params: {'max_attacks': 3, 'crystal_threshold_lte': 1000}
Description: If you has 1000 or less Crystals, this card can attack thrice
Test Cases:

Test Case ID: TC-FUNC-Red-Closet-001
Description:
Red Closet: up to 3 attacks per turn
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY
- AbilityType.MULTI_ATTACK_ANY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining initial value noted.
Steps:
Step 1: Perform up to 3 attacks.
Expected Result:
- extra attacks granted while multi_attack_count < max_attacks.

---

Card Name: Spine Creeper
Type: Character
Stats: ATK=80 DEF=45 Cost=900 Affinity=BIO
AbilityType: MULTI_ATTACK_ANY_WITH_ATK_LOSS
ability_params: {'max_attacks': 2, 'atk_loss': 30, 'once': True}
Description: Once, this card can attack twice, but lose 30 ATK permanently at the end of turn.
Test Cases:

Test Case ID: TC-FUNC-Spine-Creeper-001
Description:
Spine Creeper: up to 2 attacks, -30 ATK per attack
Implementation Reference:
- TurnManager MULTI_ATTACK_ANY_WITH_ATK_LOSS
- AbilityType.MULTI_ATTACK_ANY_WITH_ATK_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- attacks_remaining sufficient.
Steps:
Step 1: Chain 2 attacks same turn.
Expected Result:
- Each attack: current_atk -= 30; extra attack while multi_attack_count < 2.

---

Card Name: Golden Senju
Type: Character
Stats: ATK=15 DEF=0 Cost=200 Affinity=DIVINE
AbilityType: MULTI_ATTACK_VS_NON_CHARACTER
ability_params: {'max_attacks': 3, 'bonus_attacks': 1}
Description: After attacked a non-unit cell, this card can attack 1 more time.
Test Cases:

Test Case ID: TC-FUNC-Golden-Senju-001
Description:
Golden Senju: up to 3 attacks when targeting non-characters
Implementation Reference:
- TurnManager._apply_post_battle_effects MULTI_ATTACK_VS_NON_CHARACTER
- AbilityType.MULTI_ATTACK_VS_NON_CHARACTER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Targets: dead_end, trap in sequence.
Steps:
Step 1: Chain attacks on non-character cells.
Expected Result:
- Up to 3 attacks same turn when targeting non-characters.

---

Card Name: Claw Mutant
Type: Character
Stats: ATK=15 DEF=10 Cost=180 Affinity=BIO
AbilityType: MUTAGEN_ATK_BOOST_VS_AFFINITIES
ability_params: {'bonus': 10, 'affinities': []}
Description: +10 ATK if it has mutagen flag
Test Cases:

Test Case ID: TC-FUNC-Claw-Mutant-001
Description:
Claw Mutant: +10 ATK vs [] when has_mutagen_flag
Implementation Reference:
- BattleResolver._get_effective_atk() checks has_mutagen_flag
- AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Apply Release Mutagen to Claw Mutant.
- Target defender affinity in ['configured affinities'].
Steps:
Step 1: Attack with mutagen flag.
Expected Result:
- attacker_atk_used == 25 when affinity matches and has_mutagen_flag.

---

Card Name: Daddy Long Legs
Type: Character
Stats: ATK=40 DEF=40 Cost=500 Affinity=BIO
AbilityType: MUTAGEN_ATK_BOOST_VS_AFFINITIES
ability_params: {'bonus': 20}
Description: With Mutagen Flag : +20 ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Daddy-Long-Legs-001
Description:
Daddy Long Legs: +20 ATK vs [] when has_mutagen_flag
Implementation Reference:
- BattleResolver._get_effective_atk() checks has_mutagen_flag
- AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Apply Release Mutagen to Daddy Long Legs.
- Target defender affinity in ['configured affinities'].
Steps:
Step 1: Attack with mutagen flag.
Expected Result:
- attacker_atk_used == 60 when affinity matches and has_mutagen_flag.

---

Card Name: Lab Zombie
Type: Character
Stats: ATK=55 DEF=20 Cost=700 Affinity=BIO
AbilityType: MUTAGEN_ATK_BOOST_VS_AFFINITIES
ability_params: {'bonus': 45, 'affinities': ['NATURE']}
Description: With Mutagen Flag: +45 ATK vs Nature or Anima.
Test Cases:

Test Case ID: TC-FUNC-Lab-Zombie-001
Description:
Lab Zombie: +45 ATK vs ['NATURE'] when has_mutagen_flag
Implementation Reference:
- BattleResolver._get_effective_atk() checks has_mutagen_flag
- AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Apply Release Mutagen to Lab Zombie.
- Target defender affinity in ['NATURE'].
Steps:
Step 1: Attack with mutagen flag.
Expected Result:
- attacker_atk_used == 100 when affinity matches and has_mutagen_flag.

---

Card Name: Plaguespreader
Type: Character
Stats: ATK=65 DEF=50 Cost=680 Affinity=BIO
AbilityType: MUTAGEN_ATK_BOOST_VS_AFFINITIES
ability_params: {'spread_mutagen': True, 'turn_end': True}
Description: With Mutagen Flag : At the end of your turn, put 1 Mutagen Flag on one of your exposed card.
Test Cases:

Test Case ID: TC-FUNC-Plaguespreader-001
Description:
Plaguespreader: +0 ATK vs [] when has_mutagen_flag
Implementation Reference:
- BattleResolver._get_effective_atk() checks has_mutagen_flag
- AbilityType.MUTAGEN_ATK_BOOST_VS_AFFINITIES
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Apply Release Mutagen to Plaguespreader.
- Target defender affinity in ['configured affinities'].
Steps:
Step 1: Attack with mutagen flag.
Expected Result:
- attacker_atk_used == 65 when affinity matches and has_mutagen_flag.

---

Card Name: Lab Bloater
Type: Character
Stats: ATK=20 DEF=85 Cost=800 Affinity=BIO
AbilityType: MUTAGEN_DESTROY_ATTACKER
ability_params: {'both_pay_no_cost': True}
Description: With Mutagen Flag: Destroy both units in Reckoning. Both players pay no cost.
Test Cases:

Test Case ID: TC-FUNC-Lab-Bloater-001
Description:
Lab Bloater: with has_mutagen_flag, destroy attacker after surviving
Implementation Reference:
- BattleResolver post-compare: if not defender_destroyed and has_mutagen_flag
- Sets attacker_destroyed=true; defender_crystal_loss=0
- AbilityType.MUTAGEN_DESTROY_ATTACKER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lab Bloater Bio character; play Release Mutagen → has_mutagen_flag=true.
- Opponent attacks with ATK < effective DEF.
Steps:
Step 1: Resolve defense.
Expected Result:
- Attacker destroyed; attacker pays crystal cost.
- Defender Lab Bloater survives.
- When Lab Bloater later destroyed: pay_cost=false (no crystal loss to owner).

---

Card Name: Mutant Prisoner
Type: Character
Stats: ATK=70 DEF=25 Cost=800 Affinity=BIO
AbilityType: MUTAGEN_DESTROY_ATTACKER
ability_params: {}
Description: With Mutagen Flag : Once, destroy foe’s unit in Reckoning
Test Cases:

Test Case ID: TC-FUNC-Mutant-Prisoner-001
Description:
Mutant Prisoner: with has_mutagen_flag, destroy attacker after surviving
Implementation Reference:
- BattleResolver post-compare: if not defender_destroyed and has_mutagen_flag
- Sets attacker_destroyed=true; defender_crystal_loss=0
- AbilityType.MUTAGEN_DESTROY_ATTACKER
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mutant Prisoner Bio character; play Release Mutagen → has_mutagen_flag=true.
- Opponent attacks with ATK < effective DEF.
Steps:
Step 1: Resolve defense.
Expected Result:
- Attacker destroyed; attacker pays crystal cost.
- Defender Mutant Prisoner survives.
- When Lab Bloater later destroyed: pay_cost=false (no crystal loss to owner).

---

Card Name: Lab Crawler
Type: Character
Stats: ATK=95 DEF=60 Cost=1200 Affinity=BIO
AbilityType: MUTAGEN_IMMEDIATE_ATTACK
ability_params: {}
Description: With Mutagen Flag: this card can target 3 cards
Test Cases:

Test Case ID: TC-FUNC-Lab-Crawler-001
Description:
Lab Crawler: extra attack capability with mutagen (Lab Crawler)
Implementation Reference:
- TurnManager / GameState mutagen attack grant
- AbilityType.MUTAGEN_IMMEDIATE_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Release Mutagen on Lab Crawler; attacks_remaining=2.
Steps:
Step 1: Attack twice in same turn after mutagen.
Expected Result:
- Second attack allowed same turn with mutagen flag.

---

Card Name: Battle Maid Kyoko
Type: Character
Stats: ATK=20 DEF=70 Cost=600 Affinity=ANIMA
AbilityType: NEGATE_ZERO_COST_TRAPS_BOTH
ability_params: {'nullify_foe_anima_ability': True, 'intercept_anima': True}
Description: Ability of foe’s unit in Reckoning with Anima card becomes None. You can flip this card face-up if other Anima unit is targeted for attack.
Test Cases:

Test Case ID: TC-FUNC-Battle-Maid-Kyoko-001
Description:
Battle Maid Kyoko: passive — all 0-cost traps nullified on both fields
Implementation Reference:
- BattleResolver scans both grids for NEGATE_ZERO_COST_TRAPS_BOTH
- AbilityType.NEGATE_ZERO_COST_TRAPS_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Maid Kyoko face-up.
- Both players have 0-cost traps.
Steps:
Step 1: Attack any 0-cost trap.
Expected Result:
- trap_nullified for both sides while Electrogazer face-up.

---

Card Name: Electrogazer
Type: Character
Stats: ATK=80 DEF=45 Cost=1000 Affinity=COSMIC
AbilityType: NEGATE_ZERO_COST_TRAPS_BOTH
ability_params: {}
Description: Negate all zero cost trap on both players’s field
Test Cases:

Test Case ID: TC-FUNC-Electrogazer-001
Description:
Electrogazer: passive — all 0-cost traps nullified on both fields
Implementation Reference:
- BattleResolver scans both grids for NEGATE_ZERO_COST_TRAPS_BOTH
- AbilityType.NEGATE_ZERO_COST_TRAPS_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Electrogazer face-up.
- Both players have 0-cost traps.
Steps:
Step 1: Attack any 0-cost trap.
Expected Result:
- trap_nullified for both sides while Electrogazer face-up.

---

Card Name: Gamma Amoeba
Type: Character
Stats: ATK=0 DEF=20 Cost=350 Affinity=BIO
AbilityType: NEGATE_ZERO_COST_TRAPS_BOTH
ability_params: {'nullify_foe_ability': True, 'until_foe_turn': True}
Description: In Reckoning, foe’s unit ability becomes None until the end of foe’s turn.
Test Cases:

Test Case ID: TC-FUNC-Gamma-Amoeba-001
Description:
Gamma Amoeba: passive — all 0-cost traps nullified on both fields
Implementation Reference:
- BattleResolver scans both grids for NEGATE_ZERO_COST_TRAPS_BOTH
- AbilityType.NEGATE_ZERO_COST_TRAPS_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Gamma Amoeba face-up.
- Both players have 0-cost traps.
Steps:
Step 1: Attack any 0-cost trap.
Expected Result:
- trap_nullified for both sides while Electrogazer face-up.

---

Card Name: Legendary Ninja
Type: Character
Stats: ATK=80 DEF=55 Cost=1000 Affinity=ANIMA
AbilityType: NEGATE_ZERO_COST_TRAPS_BOTH
ability_params: {'nullify_union_effect_in_reckoning': True, 'until_turn_end': True}
Description: Effect of Union card in Reckoning with this card becomes None until the end of your turn.
Test Cases:

Test Case ID: TC-FUNC-Legendary-Ninja-001
Description:
Legendary Ninja: passive — all 0-cost traps nullified on both fields
Implementation Reference:
- BattleResolver scans both grids for NEGATE_ZERO_COST_TRAPS_BOTH
- AbilityType.NEGATE_ZERO_COST_TRAPS_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Legendary Ninja face-up.
- Both players have 0-cost traps.
Steps:
Step 1: Attack any 0-cost trap.
Expected Result:
- trap_nullified for both sides while Electrogazer face-up.

---

Card Name: Lukkey the Jammer
Type: Character
Stats: ATK=15 DEF=10 Cost=300 Affinity=COSMIC
AbilityType: NEGATE_ZERO_COST_TRAPS_BOTH
ability_params: {'nullify_target_ability': True, 'when_attacked': True}
Description: After attacked, select 1 face-up unit, that unit’s ability becomes None until the start of your turn.
Test Cases:

Test Case ID: TC-FUNC-Lukkey-the-Jammer-001
Description:
Lukkey the Jammer: passive — all 0-cost traps nullified on both fields
Implementation Reference:
- BattleResolver scans both grids for NEGATE_ZERO_COST_TRAPS_BOTH
- AbilityType.NEGATE_ZERO_COST_TRAPS_BOTH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lukkey the Jammer face-up.
- Both players have 0-cost traps.
Steps:
Step 1: Attack any 0-cost trap.
Expected Result:
- trap_nullified for both sides while Electrogazer face-up.

---

Card Name: Angel Harper
Type: Character
Stats: ATK=85 DEF=50 Cost=800 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Angel-Harper-001
Description:
Angel Harper: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Armored Rhino
Type: Character
Stats: ATK=60 DEF=85 Cost=720 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Armored-Rhino-001
Description:
Armored Rhino: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Arsonist
Type: Character
Stats: ATK=15 DEF=5 Cost=100 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Arsonist-001
Description:
Arsonist: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Asteroid Trooper
Type: Character
Stats: ATK=30 DEF=10 Cost=250 Affinity=COSMIC
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Asteroid-Trooper-001
Description:
Asteroid Trooper: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Astro-cargo Guard
Type: Character
Stats: ATK=15 DEF=25 Cost=200 Affinity=COSMIC
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Astro-cargo-Guard-001
Description:
Astro-cargo Guard: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Beast-447
Type: Character
Stats: ATK=20 DEF=25 Cost=200 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Beast-447-001
Description:
Beast-447: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Big Thug
Type: Character
Stats: ATK=40 DEF=35 Cost=400 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Big-Thug-001
Description:
Big Thug: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Blade Biker
Type: Character
Stats: ATK=30 DEF=30 Cost=280 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Blade-Biker-001
Description:
Blade Biker: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Blade Singer
Type: Character
Stats: ATK=10 DEF=20 Cost=100 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Blade-Singer-001
Description:
Blade Singer: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Border Guard
Type: Character
Stats: ATK=10 DEF=25 Cost=160 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Border-Guard-001
Description:
Border Guard: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Canyon Warg
Type: Character
Stats: ATK=70 DEF=30 Cost=750 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Canyon-Warg-001
Description:
Canyon Warg: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Centaur
Type: Character
Stats: ATK=55 DEF=70 Cost=800 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Centaur-001
Description:
Centaur: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Chaotic Wisp
Type: Character
Stats: ATK=20 DEF=0 Cost=100 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Chaotic-Wisp-001
Description:
Chaotic Wisp: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Choir Lady Abigail
Type: Character
Stats: ATK=25 DEF=15 Cost=250 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Choir-Lady-Abigail-001
Description:
Choir Lady Abigail: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Choir Lady Alice
Type: Character
Stats: ATK=20 DEF=25 Cost=250 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Choir-Lady-Alice-001
Description:
Choir Lady Alice: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Choir Lady Anna
Type: Character
Stats: ATK=20 DEF=20 Cost=250 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Choir-Lady-Anna-001
Description:
Choir Lady Anna: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Church Guard
Type: Character
Stats: ATK=0 DEF=35 Cost=150 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Church-Guard-001
Description:
Church Guard: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Cleaver Saint
Type: Character
Stats: ATK=95 DEF=80 Cost=1200 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Cleaver-Saint-001
Description:
Cleaver Saint: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Cloud Soldier
Type: Character
Stats: ATK=20 DEF=15 Cost=200 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Cloud-Soldier-001
Description:
Cloud Soldier: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Crooktown Pirate
Type: Character
Stats: ATK=20 DEF=20 Cost=300 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Crooktown-Pirate-001
Description:
Crooktown Pirate: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Crystal Rabbit
Type: Character
Stats: ATK=10 DEF=25 Cost=300 Affinity=NATURE
AbilityType: NONE
ability_params: {'union_material_crystal_gain': 500}
Description: If this card is used for Union summon, get 500 crystals
Test Cases:

Test Case ID: TC-FUNC-Crystal-Rabbit-001
Description:
Crystal Rabbit: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'union_material_crystal_gain': 500}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: If this card is used for Union summon, get 500 crystals

---

Card Name: Cursed Suitcase
Type: Character
Stats: ATK=0 DEF=30 Cost=150 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Cursed-Suitcase-001
Description:
Cursed Suitcase: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Cyborg dog
Type: Character
Stats: ATK=10 DEF=15 Cost=100 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Cyborg-dog-001
Description:
Cyborg dog: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Dark Monk
Type: Character
Stats: ATK=15 DEF=25 Cost=300 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Dark-Monk-001
Description:
Dark Monk: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Demon Spawn
Type: Character
Stats: ATK=40 DEF=35 Cost=400 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: Destroy this card in Reckoning with Divine units.
Test Cases:

Test Case ID: TC-FUNC-Demon-Spawn-001
Description:
Demon Spawn: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: Destroy this card in Reckoning with Divine units.

---

Card Name: Desert Rascal
Type: Character
Stats: ATK=15 DEF=15 Cost=100 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Desert-Rascal-001
Description:
Desert Rascal: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Dew the Frog Knight
Type: Character
Stats: ATK=45 DEF=35 Cost=420 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Dew-the-Frog-Knight-001
Description:
Dew the Frog Knight: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Doom Wisp
Type: Character
Stats: ATK=15 DEF=15 Cost=100 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Doom-Wisp-001
Description:
Doom Wisp: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Drill Woodpecker
Type: Character
Stats: ATK=20 DEF=20 Cost=500 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Drill-Woodpecker-001
Description:
Drill Woodpecker: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Dystopian Cultist
Type: Character
Stats: ATK=65 DEF=40 Cost=550 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Dystopian-Cultist-001
Description:
Dystopian Cultist: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Earth Elemental
Type: Character
Stats: ATK=20 DEF=40 Cost=380 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Earth-Elemental-001
Description:
Earth Elemental: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Elven Merchant
Type: Character
Stats: ATK=40 DEF=35 Cost=500 Affinity=NATURE
AbilityType: NONE
ability_params: {'halve_adjacent_nature_cost': True}
Description: Nature card in surrounding cell cost are halved.
Test Cases:

Test Case ID: TC-FUNC-Elven-Merchant-001
Description:
Elven Merchant: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'halve_adjacent_nature_cost': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Nature card in surrounding cell cost are halved.

---

Card Name: Energy Wisp
Type: Character
Stats: ATK=20 DEF=10 Cost=100 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Energy-Wisp-001
Description:
Energy Wisp: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Feuermann
Type: Character
Stats: ATK=95 DEF=70 Cost=800 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Feuermann-001
Description:
Feuermann: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Fire Elemental
Type: Character
Stats: ATK=35 DEF=20 Cost=380 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Fire-Elemental-001
Description:
Fire Elemental: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Firework Mania
Type: Character
Stats: ATK=20 DEF=20 Cost=200 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Firework-Mania-001
Description:
Firework Mania: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Flame Seraph
Type: Character
Stats: ATK=50 DEF=10 Cost=500 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Flame-Seraph-001
Description:
Flame Seraph: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Foul Wisp
Type: Character
Stats: ATK=0 DEF=25 Cost=100 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Foul-Wisp-001
Description:
Foul Wisp: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Fujin
Type: Character
Stats: ATK=35 DEF=40 Cost=450 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Fujin-001
Description:
Fujin: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Gerald of the Heavenly Light
Type: Character
Stats: ATK=80 DEF=50 Cost=750 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Gerald-of-the-Heavenly-Light-001
Description:
Gerald of the Heavenly Light: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Goblin Poacher
Type: Character
Stats: ATK=30 DEF=10 Cost=250 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Goblin-Poacher-001
Description:
Goblin Poacher: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Grand Fort Footsoldier
Type: Character
Stats: ATK=25 DEF=25 Cost=300 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Grand-Fort-Footsoldier-001
Description:
Grand Fort Footsoldier: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Grand Fort Mauler
Type: Character
Stats: ATK=40 DEF=10 Cost=350 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Grand-Fort-Mauler-001
Description:
Grand Fort Mauler: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Gryphon
Type: Character
Stats: ATK=100 DEF=85 Cost=1150 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Gryphon-001
Description:
Gryphon: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Headless Axeman
Type: Character
Stats: ATK=20 DEF=20 Cost=300 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Headless-Axeman-001
Description:
Headless Axeman: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Heavy Tome Preacher
Type: Character
Stats: ATK=25 DEF=20 Cost=300 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Heavy-Tome-Preacher-001
Description:
Heavy Tome Preacher: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Highrise Runner
Type: Character
Stats: ATK=15 DEF=15 Cost=150 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Highrise-Runner-001
Description:
Highrise Runner: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Ice Mage
Type: Character
Stats: ATK=50 DEF=0 Cost=400 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Ice-Mage-001
Description:
Ice Mage: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Karakasa
Type: Character
Stats: ATK=25 DEF=15 Cost=200 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Karakasa-001
Description:
Karakasa: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Kyber Trooper
Type: Character
Stats: ATK=25 DEF=20 Cost=300 Affinity=COSMIC
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Kyber-Trooper-001
Description:
Kyber Trooper: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Lesser Dragon
Type: Character
Stats: ATK=65 DEF=35 Cost=600 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Lesser-Dragon-001
Description:
Lesser Dragon: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Library Critters
Type: Character
Stats: ATK=15 DEF=15 Cost=120 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Library-Critters-001
Description:
Library Critters: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Lich Servant
Type: Character
Stats: ATK=20 DEF=30 Cost=400 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: Destroy this card in Reckoning with Divine units.
Test Cases:

Test Case ID: TC-FUNC-Lich-Servant-001
Description:
Lich Servant: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: Destroy this card in Reckoning with Divine units.

---

Card Name: Lurklings
Type: Character
Stats: ATK=25 DEF=5 Cost=170 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Lurklings-001
Description:
Lurklings: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Mad Raccoon
Type: Character
Stats: ATK=30 DEF=15 Cost=260 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Mad-Raccoon-001
Description:
Mad Raccoon: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Mad Spellcaster
Type: Character
Stats: ATK=40 DEF=0 Cost=300 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Mad-Spellcaster-001
Description:
Mad Spellcaster: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Mad Wyvern
Type: Character
Stats: ATK=65 DEF=40 Cost=550 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Mad-Wyvern-001
Description:
Mad Wyvern: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Maria the Battle Priest
Type: Character
Stats: ATK=55 DEF=70 Cost=820 Affinity=DIVINE
AbilityType: NONE
ability_params: {'force_coin_heads_surrounding': True, 'face_down': True}
Description: Coin flip ability of units in surrounding cell will always lands on head. Usable face-down
Test Cases:

Test Case ID: TC-FUNC-Maria-the-Battle-Priest-001
Description:
Maria the Battle Priest: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'force_coin_heads_surrounding': True, 'face_down': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Coin flip ability of units in surrounding cell will always lands on head. Usable face-down

---

Card Name: Mind Elemental
Type: Character
Stats: ATK=75 DEF=75 Cost=900 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Mind-Elemental-001
Description:
Mind Elemental: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Minotaur
Type: Character
Stats: ATK=65 DEF=65 Cost=800 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Minotaur-001
Description:
Minotaur: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Moon Clown
Type: Character
Stats: ATK=45 DEF=10 Cost=400 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Moon-Clown-001
Description:
Moon Clown: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Musketeer
Type: Character
Stats: ATK=25 DEF=5 Cost=250 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Musketeer-001
Description:
Musketeer: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Mutant Cowboy
Type: Character
Stats: ATK=30 DEF=25 Cost=280 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Mutant-Cowboy-001
Description:
Mutant Cowboy: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Mystic Dagger Dancer
Type: Character
Stats: ATK=25 DEF=15 Cost=260 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Mystic-Dagger-Dancer-001
Description:
Mystic Dagger Dancer: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Oni
Type: Character
Stats: ATK=95 DEF=80 Cost=1200 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Oni-001
Description:
Oni: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Orc Maceman
Type: Character
Stats: ATK=50 DEF=50 Cost=500 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Orc-Maceman-001
Description:
Orc Maceman: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Outpost Magician
Type: Character
Stats: ATK=15 DEF=30 Cost=200 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Outpost-Magician-001
Description:
Outpost Magician: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Pegasus
Type: Character
Stats: ATK=60 DEF=60 Cost=800 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Pegasus-001
Description:
Pegasus: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Ponycorn
Type: Character
Stats: ATK=25 DEF=20 Cost=300 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Ponycorn-001
Description:
Ponycorn: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Psy Warrior
Type: Character
Stats: ATK=20 DEF=15 Cost=200 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Psy-Warrior-001
Description:
Psy Warrior: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Raijin
Type: Character
Stats: ATK=60 DEF=0 Cost=550 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Raijin-001
Description:
Raijin: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Rotten Dog
Type: Character
Stats: ATK=25 DEF=15 Cost=200 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Rotten-Dog-001
Description:
Rotten Dog: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Samurai Angel
Type: Character
Stats: ATK=90 DEF=45 Cost=900 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Samurai-Angel-001
Description:
Samurai Angel: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Sapphire Beetle
Type: Character
Stats: ATK=20 DEF=30 Cost=300 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Sapphire-Beetle-001
Description:
Sapphire Beetle: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Scar Brawler
Type: Character
Stats: ATK=20 DEF=15 Cost=150 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Scar-Brawler-001
Description:
Scar Brawler: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Scarlet Mutant
Type: Character
Stats: ATK=35 DEF=30 Cost=350 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Scarlet-Mutant-001
Description:
Scarlet Mutant: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Scythe Warrior
Type: Character
Stats: ATK=80 DEF=20 Cost=800 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Scythe-Warrior-001
Description:
Scythe Warrior: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Shredder Doll
Type: Character
Stats: ATK=25 DEF=5 Cost=250 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Shredder-Doll-001
Description:
Shredder Doll: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Skeleton Lancer
Type: Character
Stats: ATK=45 DEF=5 Cost=300 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Lancer-001
Description:
Skeleton Lancer: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Skeleton Sickleman
Type: Character
Stats: ATK=25 DEF=5 Cost=150 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Sickleman-001
Description:
Skeleton Sickleman: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Space Boy
Type: Character
Stats: ATK=75 DEF=65 Cost=800 Affinity=COSMIC
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Space-Boy-001
Description:
Space Boy: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Spell Exile
Type: Character
Stats: ATK=35 DEF=30 Cost=350 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Spell-Exile-001
Description:
Spell Exile: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Spikelings
Type: Character
Stats: ATK=25 DEF=0 Cost=120 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Spikelings-001
Description:
Spikelings: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Staircase Lady
Type: Character
Stats: ATK=30 DEF=0 Cost=180 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Staircase-Lady-001
Description:
Staircase Lady: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Star Crusader
Type: Character
Stats: ATK=25 DEF=25 Cost=250 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Star-Crusader-001
Description:
Star Crusader: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Suigin
Type: Character
Stats: ATK=80 DEF=140 Cost=900 Affinity=COSMIC
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Suigin-001
Description:
Suigin: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Suijin
Type: Character
Stats: ATK=20 DEF=75 Cost=800 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Suijin-001
Description:
Suijin: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Swords Dancer
Type: Character
Stats: ATK=20 DEF=25 Cost=350 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Swords-Dancer-001
Description:
Swords Dancer: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Tall Black Coat
Type: Character
Stats: ATK=55 DEF=40 Cost=550 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Tall-Black-Coat-001
Description:
Tall Black Coat: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Tall Shadow
Type: Character
Stats: ATK=30 DEF=80 Cost=500 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: Destroy this card in Reckoning with Divine units.
Test Cases:

Test Case ID: TC-FUNC-Tall-Shadow-001
Description:
Tall Shadow: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: Destroy this card in Reckoning with Divine units.

---

Card Name: Tower Guard
Type: Character
Stats: ATK=10 DEF=25 Cost=160 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Tower-Guard-001
Description:
Tower Guard: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Ultralings
Type: Character
Stats: ATK=60 DEF=60 Cost=600 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Ultralings-001
Description:
Ultralings: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Unwavering Cleric
Type: Character
Stats: ATK=45 DEF=65 Cost=550 Affinity=DIVINE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Unwavering-Cleric-001
Description:
Unwavering Cleric: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Vent Killer
Type: Character
Stats: ATK=35 DEF=35 Cost=500 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Vent-Killer-001
Description:
Vent Killer: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Wandering Swordsman
Type: Character
Stats: ATK=60 DEF=60 Cost=600 Affinity=ANIMA
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Wandering-Swordsman-001
Description:
Wandering Swordsman: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Water Elemental
Type: Character
Stats: ATK=25 DEF=35 Cost=380 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Water-Elemental-001
Description:
Water Elemental: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Wide Smile Lady
Type: Character
Stats: ATK=25 DEF=0 Cost=200 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Wide-Smile-Lady-001
Description:
Wide Smile Lady: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Wind Elemental
Type: Character
Stats: ATK=30 DEF=30 Cost=380 Affinity=ARCANE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Wind-Elemental-001
Description:
Wind Elemental: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Wood Wisp
Type: Character
Stats: ATK=10 DEF=20 Cost=100 Affinity=NATURE
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Wood-Wisp-001
Description:
Wood Wisp: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Yaksa
Type: Character
Stats: ATK=30 DEF=30 Cost=500 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Yaksa-001
Description:
Yaksa: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Z-99 the Perfect Organism
Type: Character
Stats: ATK=125 DEF=100 Cost=1500 Affinity=BIO
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Z-99-the-Perfect-Organism-001
Description:
Z-99 the Perfect Organism: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Zealot
Type: Character
Stats: ATK=75 DEF=50 Cost=900 Affinity=ANIMA
AbilityType: NONE
ability_params: {'union_material_boost': 40}
Description: If this card is used for Union summon, increase the Union card’s ATK&DEF by 40
Test Cases:

Test Case ID: TC-FUNC-Zealot-001
Description:
Zealot: ability NONE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.NONE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'union_material_boost': 40}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: If this card is used for Union summon, increase the Union card’s ATK&DEF by 40

---

Card Name: Zombie Knight
Type: Character
Stats: ATK=80 DEF=60 Cost=800 Affinity=CHAOS
AbilityType: NONE
ability_params: {}
Description: None
Test Cases:

Test Case ID: TC-FUNC-Zombie-Knight-001
Description:
Zombie Knight: ability NONE functional smoke test
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
- Behavior matches CardDatabase description: None

---

Card Name: Battle Penguin
Type: Character
Stats: ATK=20 DEF=15 Cost=300 Affinity=NATURE
AbilityType: ONE_USE_ATK_BOOST
ability_params: {'bonus': 15}
Description: +15 ATK until the end of that turn, once.
Test Cases:

Test Case ID: TC-FUNC-Battle-Penguin-001
Description:
Battle Penguin: one-time +15 ATK on first attack
Implementation Reference:
- BattleResolver._get_effective_atk() if not one_use_atk_boost_used
- TurnManager._apply_post_battle_effects sets one_use_atk_boost_used=true
- AbilityType.ONE_USE_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Battle Penguin has one_use_atk_boost_used=false.
Steps:
Step 1: First attack: verify bonus; second attack: no bonus.
Expected Result:
- First attack: attacker_atk_used == 35; one_use_atk_boost_used becomes true.
- Second attack: attacker_atk_used == 20.

---

Card Name: Dragon Hunter Vanrose
Type: Character
Stats: ATK=35 DEF=20 Cost=300 Affinity=ANIMA
AbilityType: ONE_USE_ATK_BOOST
ability_params: {'bonus': 100, 'vs_name_contains': 'Dragon'}
Description: Once, +100 ATK vs “Dragon” unit
Test Cases:

Test Case ID: TC-FUNC-Dragon-Hunter-Vanrose-001
Description:
Dragon Hunter Vanrose: one-time +100 ATK on first attack
Implementation Reference:
- BattleResolver._get_effective_atk() if not one_use_atk_boost_used
- TurnManager._apply_post_battle_effects sets one_use_atk_boost_used=true
- AbilityType.ONE_USE_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Dragon Hunter Vanrose has one_use_atk_boost_used=false.
Steps:
Step 1: First attack: verify bonus; second attack: no bonus.
Expected Result:
- First attack: attacker_atk_used == 135; one_use_atk_boost_used becomes true.
- Second attack: attacker_atk_used == 35.

---

Card Name: Grand Fort Archer
Type: Character
Stats: ATK=20 DEF=20 Cost=280 Affinity=ANIMA
AbilityType: ONE_USE_ATK_BOOST
ability_params: {'bonus': 10}
Description: Once, +10 ATK when attack
Test Cases:

Test Case ID: TC-FUNC-Grand-Fort-Archer-001
Description:
Grand Fort Archer: one-time +10 ATK on first attack
Implementation Reference:
- BattleResolver._get_effective_atk() if not one_use_atk_boost_used
- TurnManager._apply_post_battle_effects sets one_use_atk_boost_used=true
- AbilityType.ONE_USE_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Grand Fort Archer has one_use_atk_boost_used=false.
Steps:
Step 1: First attack: verify bonus; second attack: no bonus.
Expected Result:
- First attack: attacker_atk_used == 30; one_use_atk_boost_used becomes true.
- Second attack: attacker_atk_used == 20.

---

Card Name: Hands in the Attic
Type: Character
Stats: ATK=20 DEF=20 Cost=300 Affinity=CHAOS
AbilityType: ONE_USE_ATK_BOOST
ability_params: {'bonus': 10}
Description: Once, +10 ATK when attack
Test Cases:

Test Case ID: TC-FUNC-Hands-in-the-Attic-001
Description:
Hands in the Attic: one-time +10 ATK on first attack
Implementation Reference:
- BattleResolver._get_effective_atk() if not one_use_atk_boost_used
- TurnManager._apply_post_battle_effects sets one_use_atk_boost_used=true
- AbilityType.ONE_USE_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hands in the Attic has one_use_atk_boost_used=false.
Steps:
Step 1: First attack: verify bonus; second attack: no bonus.
Expected Result:
- First attack: attacker_atk_used == 30; one_use_atk_boost_used becomes true.
- Second attack: attacker_atk_used == 20.

---

Card Name: Moon Siren
Type: Character
Stats: ATK=60 DEF=60 Cost=1000 Affinity=COSMIC
AbilityType: ONE_USE_COPY_STATS_ON_SURVIVE
ability_params: {'temp': True}
Description: Once, in Reckoning, you can copy foe’s ATK and DEF until the end of this turn
Test Cases:

Test Case ID: TC-FUNC-Moon-Siren-001
Description:
Moon Siren: once, copy battled card stats on mutual survival
Implementation Reference:
- TurnManager when both survive; copy_stats_used flag
- AbilityType.ONE_USE_COPY_STATS_ON_SURVIVE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tie or mutual survive scenario.
Steps:
Step 1: Battle where neither destroyed.
Expected Result:
- perm_atk_bonus += defender.current_atk; perm_def_bonus += defender.current_def.

---

Card Name: Succubus
Type: Character
Stats: ATK=10 DEF=30 Cost=600 Affinity=CHAOS
AbilityType: ONE_USE_COPY_STATS_ON_SURVIVE
ability_params: {}
Description: Once, if survived Reckoning: +ATK&DEF equal to half of that foe’s card
Test Cases:

Test Case ID: TC-FUNC-Succubus-001
Description:
Succubus: once, copy battled card stats on mutual survival
Implementation Reference:
- TurnManager when both survive; copy_stats_used flag
- AbilityType.ONE_USE_COPY_STATS_ON_SURVIVE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tie or mutual survive scenario.
Steps:
Step 1: Battle where neither destroyed.
Expected Result:
- perm_atk_bonus += defender.current_atk; perm_def_bonus += defender.current_def.

---

Card Name: Bladeshifter
Type: Character
Stats: ATK=0 DEF=50 Cost=420 Affinity=BIO
AbilityType: ONE_USE_DEFEND_MORPH
ability_params: {'atk': 40, 'def': 40}
Description: Once, after defended: -40 DEF,+40 ATK permanently.
Test Cases:

Test Case ID: TC-FUNC-Bladeshifter-001
Description:
Bladeshifter: once after defend: -40 DEF, +40 ATK permanently
Implementation Reference:
- BattleResolver._apply_defend_effects ONE_USE_DEFEND_MORPH
- AbilityType.ONE_USE_DEFEND_MORPH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Bladeshifter defends successfully first time.
Steps:
Step 1: Win defense.
Expected Result:
- current_def -= 40; current_atk += 40; one_use_def_boost_used=true.

---

Card Name: Armored Bee
Type: Character
Stats: ATK=30 DEF=0 Cost=480 Affinity=NATURE
AbilityType: ONE_USE_DEF_BOOST
ability_params: {'bonus': 60}
Description: +60 DEF until the end of that turn once
Test Cases:

Test Case ID: TC-FUNC-Armored-Bee-001
Description:
Armored Bee: one-time +60 DEF when defending
Implementation Reference:
- BattleResolver._get_effective_def()
- TurnManager marks one_use_def_boost_used after battle
- AbilityType.ONE_USE_DEF_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First defense with Armored Bee.
Steps:
Step 1: Opponent attacks twice across two turns.
Expected Result:
- First defense: defender_def_used == 60.
- Second defense: defender_def_used == 0.

---

Card Name: Deozhor the Europan Warlord
Type: Character
Stats: ATK=85 DEF=70 Cost=950 Affinity=COSMIC
AbilityType: ONE_USE_DESTROY_BY_AFFINITY
ability_params: {'flag_cost': 'Europa', 'destroy_any': True}
Description: You can remove 1 Europa flag on your side to destroy 1 card on the field
Test Cases:

Test Case ID: TC-FUNC-Deozhor-the-Europan-Warlord-001
Description:
Deozhor the Europan Warlord: once destroy defender matching ? or ? (no crystal loss)
Implementation Reference:
- BattleResolver ONE_USE_DESTROY_BY_AFFINITY
- AbilityType.ONE_USE_DESTROY_BY_AFFINITY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Defender affinity in (?,?); one_use_atk_boost_used=false.
Steps:
Step 1: Attack matching defender.
Expected Result:
- defender_destroyed=true; defender_crystal_loss=0.
- one_use_atk_boost_used=true; second use does not auto-destroy.

---

Card Name: Havoc the Gatling General
Type: Character
Stats: ATK=90 DEF=65 Cost=1000 Affinity=ANIMA
AbilityType: ONE_USE_EXTRA_ATTACK_ON_DEAD_END
ability_params: {'grant_attack_count': 1, 'turn_start': True}
Description: Once, at the start of your turn, gain 1 attack count.
Test Cases:

Test Case ID: TC-FUNC-Havoc-the-Gatling-General-001
Description:
Havoc the Gatling General: one lifetime extra attack on dead_end
Implementation Reference:
- TurnManager flag extra_deadend_used
- AbilityType.ONE_USE_EXTRA_ATTACK_ON_DEAD_END
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First dead_end attack.
Steps:
Step 1: Attack dead_end once.
Expected Result:
- One bonus attack total per card lifetime.

---

Card Name: Skeleton Scout
Type: Character
Stats: ATK=20 DEF=5 Cost=150 Affinity=CHAOS
AbilityType: ONE_USE_EXTRA_ATTACK_ON_DEAD_END
ability_params: {}
Description: Once, if hitting Dead End: attack again
Test Cases:

Test Case ID: TC-FUNC-Skeleton-Scout-001
Description:
Skeleton Scout: one lifetime extra attack on dead_end
Implementation Reference:
- TurnManager flag extra_deadend_used
- AbilityType.ONE_USE_EXTRA_ATTACK_ON_DEAD_END
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First dead_end attack.
Steps:
Step 1: Attack dead_end once.
Expected Result:
- One bonus attack total per card lifetime.

---

Card Name: Bomber Fairy
Type: Character
Stats: ATK=30 DEF=15 Cost=500 Affinity=DIVINE
AbilityType: ONE_USE_EXTRA_ATTACK_ON_KILL
ability_params: {}
Description: Once, after destroyed a unit, this card can attack 1 more time.
Test Cases:

Test Case ID: TC-FUNC-Bomber-Fairy-001
Description:
Bomber Fairy: one extra attack after destroying a card
Implementation Reference:
- TurnManager._apply_post_battle_effects; flag 'extra_kill_used'
- AbilityType.ONE_USE_EXTRA_ATTACK_ON_KILL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Bomber Fairy destroys defender.
Steps:
Step 1: Check attacks_remaining.
Expected Result:
- attacks_remaining += 1 once; flag extra_kill_used set.

---

Card Name: Brave Knight
Type: Character
Stats: ATK=15 DEF=15 Cost=300 Affinity=ANIMA
AbilityType: ONE_USE_EXTRA_ATTACK_ON_KILL
ability_params: {'grant_attack_count': 1}
Description: Once, after this card attacked, gain 1 attack count
Test Cases:

Test Case ID: TC-FUNC-Brave-Knight-001
Description:
Brave Knight: one extra attack after destroying a card
Implementation Reference:
- TurnManager._apply_post_battle_effects; flag 'extra_kill_used'
- AbilityType.ONE_USE_EXTRA_ATTACK_ON_KILL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Brave Knight destroys defender.
Steps:
Step 1: Check attacks_remaining.
Expected Result:
- attacks_remaining += 1 once; flag extra_kill_used set.

---

Card Name: Deep Tribe Axe Thrower
Type: Character
Stats: ATK=70 DEF=30 Cost=500 Affinity=NATURE
AbilityType: ONE_USE_EXTRA_ATTACK_ON_KILL
ability_params: {'vs_non_affinity': 'NATURE', 'per_turn': True}
Description: Once per turn, attack again if destroyed Non-Nature unit.
Test Cases:

Test Case ID: TC-FUNC-Deep-Tribe-Axe-Thrower-001
Description:
Deep Tribe Axe Thrower: one extra attack after destroying a card
Implementation Reference:
- TurnManager._apply_post_battle_effects; flag 'extra_kill_used'
- AbilityType.ONE_USE_EXTRA_ATTACK_ON_KILL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Deep Tribe Axe Thrower destroys defender.
Steps:
Step 1: Check attacks_remaining.
Expected Result:
- attacks_remaining += 1 once; flag extra_kill_used set.

---

Card Name: Lina the Swordmistress
Type: Character
Stats: ATK=55 DEF=50 Cost=780 Affinity=ANIMA
AbilityType: ONE_USE_EXTRA_ATTACK_ON_KILL
ability_params: {'grant_attack_count': 1, 'per_turn': True, 'on_successful_attack': True}
Description: Once per turn, after a successful attack, gain 1 attack count
Test Cases:

Test Case ID: TC-FUNC-Lina-the-Swordmistress-001
Description:
Lina the Swordmistress: one extra attack after destroying a card
Implementation Reference:
- TurnManager._apply_post_battle_effects; flag 'extra_kill_used'
- AbilityType.ONE_USE_EXTRA_ATTACK_ON_KILL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lina the Swordmistress destroys defender.
Steps:
Step 1: Check attacks_remaining.
Expected Result:
- attacks_remaining += 1 once; flag extra_kill_used set.

---

Card Name: Winter Tropper
Type: Character
Stats: ATK=40 DEF=25 Cost=380 Affinity=ANIMA
AbilityType: ONE_USE_EXTRA_ATTACK_ON_KILL
ability_params: {'grant_attack_count': 1, 'on_successful_attack': True}
Description: After a successful attack, gain 1 attack count
Test Cases:

Test Case ID: TC-FUNC-Winter-Tropper-001
Description:
Winter Tropper: one extra attack after destroying a card
Implementation Reference:
- TurnManager._apply_post_battle_effects; flag 'extra_kill_used'
- AbilityType.ONE_USE_EXTRA_ATTACK_ON_KILL
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Winter Tropper destroys defender.
Steps:
Step 1: Check attacks_remaining.
Expected Result:
- attacks_remaining += 1 once; flag extra_kill_used set.

---

Card Name: Diamond Porcupine
Type: Character
Stats: ATK=75 DEF=90 Cost=950 Affinity=NATURE
AbilityType: ONE_USE_PERM_DEBUFF_ATTACKER_ATK
ability_params: {'atk': 60, 'permanent': True}
Description: Once, in Reckoning, foe’s unit permanently loses 60 ATK.
Test Cases:

Test Case ID: TC-FUNC-Diamond-Porcupine-001
Description:
Diamond Porcupine: once, defender permanently -60 ATK to attacker
Implementation Reference:
- BattleResolver._apply_defend_effects; one_use_def_boost_used flag
- AbilityType.ONE_USE_PERM_DEBUFF_ATTACKER_ATK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First defend only.
Steps:
Step 1: Defend twice across battles.
Expected Result:
- First: attacker -60 ATK permanent; second: no debuff.

---

Card Name: Gem Turtle
Type: Character
Stats: ATK=0 DEF=30 Cost=200 Affinity=ARCANE
AbilityType: ONE_USE_PERM_DEBUFF_ATTACKER_ATK
ability_params: {'atk': 5}
Description: Once, when this card defends, the attacker permanently loses 5 ATK.
Test Cases:

Test Case ID: TC-FUNC-Gem-Turtle-001
Description:
Gem Turtle: once, defender permanently -5 ATK to attacker
Implementation Reference:
- BattleResolver._apply_defend_effects; one_use_def_boost_used flag
- AbilityType.ONE_USE_PERM_DEBUFF_ATTACKER_ATK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First defend only.
Steps:
Step 1: Defend twice across battles.
Expected Result:
- First: attacker -5 ATK permanent; second: no debuff.

---

Card Name: Needle Porcupine
Type: Character
Stats: ATK=10 DEF=10 Cost=200 Affinity=NATURE
AbilityType: ONE_USE_PERM_DEBUFF_ATTACKER_ATK
ability_params: {'atk': 5}
Description: Once, when this card defends, the attacker permanently loses 5 ATK.
Test Cases:

Test Case ID: TC-FUNC-Needle-Porcupine-001
Description:
Needle Porcupine: once, defender permanently -5 ATK to attacker
Implementation Reference:
- BattleResolver._apply_defend_effects; one_use_def_boost_used flag
- AbilityType.ONE_USE_PERM_DEBUFF_ATTACKER_ATK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First defend only.
Steps:
Step 1: Defend twice across battles.
Expected Result:
- First: attacker -5 ATK permanent; second: no debuff.

---

Card Name: Angel Mauler
Type: Character
Stats: ATK=45 DEF=40 Cost=700 Affinity=DIVINE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'destroyer_affinity': 'CHAOS', 'permanent': True}
Description: This card is not destroyed by Chaos cards
Test Cases:

Test Case ID: TC-FUNC-Angel-Mauler-001
Description:
Angel Mauler: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Angel Mauler would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Atheist Rogue
Type: Character
Stats: ATK=30 DEF=20 Cost=350 Affinity=ANIMA
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'destroyer_affinity': 'DIVINE', 'permanent': True}
Description: This card is not destroyed by Divine units
Test Cases:

Test Case ID: TC-FUNC-Atheist-Rogue-001
Description:
Atheist Rogue: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Atheist Rogue would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Benedict the Battle Priest
Type: Character
Stats: ATK=60 DEF=60 Cost=750 Affinity=DIVINE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'coin_flip': True, 'name_contains': 'Battle Priest'}
Description: Once, if Battle Priest is going to be destroyed, flip a coin. Heads: It’s not destroyed.
Test Cases:

Test Case ID: TC-FUNC-Benedict-the-Battle-Priest-001
Description:
Benedict the Battle Priest: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Benedict the Battle Priest would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Cloud Beast
Type: Character
Stats: ATK=65 DEF=30 Cost=850 Affinity=DIVINE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'destroyer_affinity': 'ANIMA', 'permanent': True}
Description: This card is not destroyed by Anima card
Test Cases:

Test Case ID: TC-FUNC-Cloud-Beast-001
Description:
Cloud Beast: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Cloud Beast would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Diego the Thief
Type: Character
Stats: ATK=15 DEF=15 Cost=300 Affinity=ANIMA
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, you can discard 1 Tech card, this card is not destroyed.
Test Cases:

Test Case ID: TC-FUNC-Diego-the-Thief-001
Description:
Diego the Thief: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Diego the Thief would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Dragon Hunter Eugene
Type: Character
Stats: ATK=20 DEF=20 Cost=200 Affinity=ANIMA
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'destroyer_name_contains': 'Dragon', 'permanent': True, 'reckoning_debuff': '{"name_contains": "Dragon"', 'def': 50}
Description: This card is not destroyed by “Dragon” units. In Reckoning, Dragon foe get -50 DEF permanently.
Test Cases:

Test Case ID: TC-FUNC-Dragon-Hunter-Eugene-001
Description:
Dragon Hunter Eugene: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Dragon Hunter Eugene would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Dwarven Guard
Type: Character
Stats: ATK=40 DEF=65 Cost=750 Affinity=ARCANE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, if a dwarven card will be destroyed, it is not destroyed.
Test Cases:

Test Case ID: TC-FUNC-Dwarven-Guard-001
Description:
Dwarven Guard: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Dwarven Guard would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Elegant Butterfly
Type: Character
Stats: ATK=10 DEF=10 Cost=150 Affinity=NATURE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, this card is not destroyed
Test Cases:

Test Case ID: TC-FUNC-Elegant-Butterfly-001
Description:
Elegant Butterfly: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Elegant Butterfly would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Ethereal Shielder
Type: Character
Stats: ATK=25 DEF=80 Cost=1200 Affinity=ARCANE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'vs_non_affinity': 'ARCANE', 'per_turn': True}
Description: Once per turn, this card cannot be destroyed vs Non-Arcane
Test Cases:

Test Case ID: TC-FUNC-Ethereal-Shielder-001
Description:
Ethereal Shielder: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Ethereal Shielder would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Irondust Ghoul
Type: Character
Stats: ATK=0 DEF=25 Cost=200 Affinity=COSMIC
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, it is not destroyed while there is face-up Cosmic card on the field.
Test Cases:

Test Case ID: TC-FUNC-Irondust-Ghoul-001
Description:
Irondust Ghoul: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Irondust Ghoul would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Manananggal
Type: Character
Stats: ATK=100 DEF=80 Cost=500 Affinity=CHAOS
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once vs Non-Divine, this card is not destroyed
Test Cases:

Test Case ID: TC-FUNC-Manananggal-001
Description:
Manananggal: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Manananggal would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Mastimus the Outlaw
Type: Character
Stats: ATK=15 DEF=15 Cost=800 Affinity=COSMIC
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'destroy_cost': 200}
Description: You pay only 200 cost if this card get destroyed
Test Cases:

Test Case ID: TC-FUNC-Mastimus-the-Outlaw-001
Description:
Mastimus the Outlaw: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mastimus the Outlaw would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Maybell the Doverider
Type: Character
Stats: ATK=40 DEF=40 Cost=500 Affinity=DIVINE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, this card is not destroyed with unsuccessful attack
Test Cases:

Test Case ID: TC-FUNC-Maybell-the-Doverider-001
Description:
Maybell the Doverider: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Maybell the Doverider would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Moonstone Golem
Type: Character
Stats: ATK=70 DEF=130 Cost=1200 Affinity=NATURE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, this card is not destroyed
Test Cases:

Test Case ID: TC-FUNC-Moonstone-Golem-001
Description:
Moonstone Golem: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Moonstone Golem would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Orang Minyak
Type: Character
Stats: ATK=25 DEF=30 Cost=320 Affinity=CHAOS
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, it is not destroyed, but its DEF becomes 0.
Test Cases:

Test Case ID: TC-FUNC-Orang-Minyak-001
Description:
Orang Minyak: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Orang Minyak would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Parasite Mimas
Type: Character
Stats: ATK=10 DEF=15 Cost=200 Affinity=COSMIC
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'requires_mutagen': True}
Description: With Mutagen Flag : Once, this card is not destroyed.
Test Cases:

Test Case ID: TC-FUNC-Parasite-Mimas-001
Description:
Parasite Mimas: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Parasite Mimas would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Pochong
Type: Character
Stats: ATK=90 DEF=90 Cost=1000 Affinity=CHAOS
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'foe_gain': 500, 'avoid_cost': True}
Description: When this card is destroyed, you can choose to avoid paying cost and grant 500 crystals to foe instead.
Test Cases:

Test Case ID: TC-FUNC-Pochong-001
Description:
Pochong: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Pochong would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Stealth Bomber
Type: Character
Stats: ATK=100 DEF=40 Cost=1200 Affinity=ANIMA
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'expose_turn_immune': True, 'foe_cannot_target': True}
Description: Cannot be destroyed the turn it is exposed. Until foe’s turn end, your foe cannot target this exposed card.
Test Cases:

Test Case ID: TC-FUNC-Stealth-Bomber-001
Description:
Stealth Bomber: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Stealth Bomber would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Tiny Pixie
Type: Character
Stats: ATK=0 DEF=0 Cost=100 Affinity=DIVINE
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {}
Description: Once, this card is not destroyed
Test Cases:

Test Case ID: TC-FUNC-Tiny-Pixie-001
Description:
Tiny Pixie: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tiny Pixie would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Waste Slime
Type: Character
Stats: ATK=10 DEF=15 Cost=150 Affinity=BIO
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'destroyer_affinities': ['ANIMA']}
Description: Once, if it’s going to be destroyed by Anima or Bio card, it’s not destroyed.
Test Cases:

Test Case ID: TC-FUNC-Waste-Slime-001
Description:
Waste Slime: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Waste Slime would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Zomborg
Type: Character
Stats: ATK=65 DEF=70 Cost=900 Affinity=BIO
AbilityType: ONE_USE_SURVIVE_DESTRUCTION
ability_params: {'invert_debuff': True}
Description: Once, when this card ATK and/or DEF will be decreased, gain ATK and/or DEF by that amount instead.
Test Cases:

Test Case ID: TC-FUNC-Zomborg-001
Description:
Zomborg: once per card, survive destruction
Implementation Reference:
- TurnManager/GameState destruction intercept
- AbilityType.ONE_USE_SURVIVE_DESTRUCTION
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Zomborg would be destroyed first time.
Steps:
Step 1: Trigger destruction.
Expected Result:
- Card remains; one-use flag consumed.

---

Card Name: Deep Tribe Warrior
Type: Character
Stats: ATK=35 DEF=45 Cost=400 Affinity=NATURE
AbilityType: ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
ability_params: {'atk': 50, 'def': 50, 'vs_non_affinity': 'NATURE', 'temp': True}
Description: Once, +50 ATK&DEF in Reckoning vs Non-Nature until the end of this turn.
Test Cases:

Test Case ID: TC-FUNC-Deep-Tribe-Warrior-001
Description:
Deep Tribe Warrior: once +50 ATK attack / once +50 DEF defend
Implementation Reference:
- BattleResolver separate one_use flags for atk/def uses
- AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Deep Tribe Warrior unused one-use flags.
Steps:
Step 1: Attack once, then defend once on later turn.
Expected Result:
- First attack includes +50 ATK.
- First defend includes +50 DEF.
- Subsequent uses: no corresponding bonus.

---

Card Name: Laughing Granny
Type: Character
Stats: ATK=15 DEF=20 Cost=350 Affinity=CHAOS
AbilityType: ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
ability_params: {'atk': 10, 'def': 10}
Description: Once when defending, +10 DEF until end of turn. Once when attacking, +10 ATK until end of turn
Test Cases:

Test Case ID: TC-FUNC-Laughing-Granny-001
Description:
Laughing Granny: once +10 ATK attack / once +10 DEF defend
Implementation Reference:
- BattleResolver separate one_use flags for atk/def uses
- AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Laughing Granny unused one-use flags.
Steps:
Step 1: Attack once, then defend once on later turn.
Expected Result:
- First attack includes +10 ATK.
- First defend includes +10 DEF.
- Subsequent uses: no corresponding bonus.

---

Card Name: Logan the Lumberjack
Type: Character
Stats: ATK=15 DEF=20 Cost=350 Affinity=ANIMA
AbilityType: ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
ability_params: {'atk': 50, 'def': 50, 'vs_affinity': 'NATURE', 'temp': True}
Description: Once, +50 ATK&DEF vs Nature until the end of that turn.
Test Cases:

Test Case ID: TC-FUNC-Logan-the-Lumberjack-001
Description:
Logan the Lumberjack: once +50 ATK attack / once +50 DEF defend
Implementation Reference:
- BattleResolver separate one_use flags for atk/def uses
- AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Logan the Lumberjack unused one-use flags.
Steps:
Step 1: Attack once, then defend once on later turn.
Expected Result:
- First attack includes +50 ATK.
- First defend includes +50 DEF.
- Subsequent uses: no corresponding bonus.

---

Card Name: Magical Smith
Type: Character
Stats: ATK=15 DEF=15 Cost=170 Affinity=ARCANE
AbilityType: ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
ability_params: {'atk': 5, 'def': 5, 'temp': True}
Description: Once, if this card battles, +5 ATK&DEF until the end of this turn.
Test Cases:

Test Case ID: TC-FUNC-Magical-Smith-001
Description:
Magical Smith: once +5 ATK attack / once +5 DEF defend
Implementation Reference:
- BattleResolver separate one_use flags for atk/def uses
- AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Magical Smith unused one-use flags.
Steps:
Step 1: Attack once, then defend once on later turn.
Expected Result:
- First attack includes +5 ATK.
- First defend includes +5 DEF.
- Subsequent uses: no corresponding bonus.

---

Card Name: Tholin Shark
Type: Character
Stats: ATK=20 DEF=15 Cost=240 Affinity=COSMIC
AbilityType: ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
ability_params: {'atk': 10, 'def': 10, 'vs_trap': True, 'until_next_turn': True}
Description: If attacked a trap, +10 ATK&DEF until the end of your next turn.
Test Cases:

Test Case ID: TC-FUNC-Tholin-Shark-001
Description:
Tholin Shark: once +10 ATK attack / once +10 DEF defend
Implementation Reference:
- BattleResolver separate one_use flags for atk/def uses
- AbilityType.ONE_USE_TEMP_BOOST_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tholin Shark unused one-use flags.
Steps:
Step 1: Attack once, then defend once on later turn.
Expected Result:
- First attack includes +10 ATK.
- First defend includes +10 DEF.
- Subsequent uses: no corresponding bonus.

---

Card Name: Lockpicker
Type: Character
Stats: ATK=30 DEF=35 Cost=450 Affinity=ANIMA
AbilityType: ON_EXPOSE_REVEAL_FOE_ONCE
ability_params: {}
Description: Once exposed, reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Lockpicker-001
Description:
Lockpicker: ability ON_EXPOSE_REVEAL_FOE_ONCE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.ON_EXPOSE_REVEAL_FOE_ONCE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once exposed, reveal 1 foe’s cell

---

Card Name: Nebulomancer
Type: Character
Stats: ATK=20 DEF=25 Cost=260 Affinity=COSMIC
AbilityType: ON_EXPOSE_REVEAL_FOE_ONCE
ability_params: {'own_cell': True, 'count': 1}
Description: Exposed: Reveal 1 of your own cells
Test Cases:

Test Case ID: TC-FUNC-Nebulomancer-001
Description:
Nebulomancer: ability ON_EXPOSE_REVEAL_FOE_ONCE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.ON_EXPOSE_REVEAL_FOE_ONCE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'own_cell': True, 'count': 1}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Exposed: Reveal 1 of your own cells

---

Card Name: Stratomancer
Type: Character
Stats: ATK=55 DEF=0 Cost=300 Affinity=COSMIC
AbilityType: ON_EXPOSE_REVEAL_FOE_ONCE
ability_params: {'own_cell': True, 'count': 3}
Description: Exposed: Reveal 3 of your own cells
Test Cases:

Test Case ID: TC-FUNC-Stratomancer-001
Description:
Stratomancer: ability ON_EXPOSE_REVEAL_FOE_ONCE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.ON_EXPOSE_REVEAL_FOE_ONCE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'own_cell': True, 'count': 3}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Exposed: Reveal 3 of your own cells

---

Card Name: Grave Worm
Type: Character
Stats: ATK=15 DEF=30 Cost=250 Affinity=CHAOS
AbilityType: OPPONENT_EXTRA_CRYSTAL_LOSS
ability_params: {'amount': 20}
Description: Each time foe loses Crystal: foe loses 200 more Crystals
Test Cases:

Test Case ID: TC-FUNC-Grave-Worm-001
Description:
Grave Worm: opponent loses +20 on every crystal loss
Implementation Reference:
- GameState.lose_crystals opponent passives
- AbilityType.OPPONENT_EXTRA_CRYSTAL_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Grave Worm face-up on opponent's field... (owner is player with Grave Worm).
Steps:
Step 1: Opponent loses crystals from any source.
Expected Result:
- Each loss event: additional -20 crystals.

---

Card Name: Sinister Cultist
Type: Character
Stats: ATK=40 DEF=30 Cost=450 Affinity=CHAOS
AbilityType: OPPONENT_EXTRA_CRYSTAL_LOSS
ability_params: {'amount': 100}
Description: Whenever foe loses Crystal, they lose 100 more Crystals
Test Cases:

Test Case ID: TC-FUNC-Sinister-Cultist-001
Description:
Sinister Cultist: opponent loses +100 on every crystal loss
Implementation Reference:
- GameState.lose_crystals opponent passives
- AbilityType.OPPONENT_EXTRA_CRYSTAL_LOSS
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Sinister Cultist face-up on opponent's field... (owner is player with Grave Worm).
Steps:
Step 1: Opponent loses crystals from any source.
Expected Result:
- Each loss event: additional -100 crystals.

---

Card Name: Hairpin Assassin
Type: Character
Stats: ATK=25 DEF=15 Cost=300 Affinity=ANIMA
AbilityType: OPTIONAL_CRYSTAL_PAY_ATK_BOOST
ability_params: {'cost': 800, 'atk': 10}
Description: In Reckoning, you can pay 800 Crystal for +10 ATK bonus
Test Cases:

Test Case ID: TC-FUNC-Hairpin-Assassin-001
Description:
Hairpin Assassin: optional pay 800 crystals for +10 ATK
Implementation Reference:
- TurnManager pre-battle crystal prompt OPTIONAL_CRYSTAL_PAY_ATK_BOOST
- AbilityType.OPTIONAL_CRYSTAL_PAY_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Player crystals ≥ 800 and < 800 for decline test.
Steps:
Step 1: Accept prompt / Decline prompt in separate runs.
Expected Result:
- Accept: attacker_atk_used includes +10; crystals -= 800.
- Decline: no bonus; no payment.

---

Card Name: Mirror Lady
Type: Character
Stats: ATK=30 DEF=90 Cost=960 Affinity=CHAOS
AbilityType: OPTIONAL_CRYSTAL_PAY_ATK_BOOST
ability_params: {'cost': 300, 'swap_foe_stats': True, 'once': True}
Description: In Reckoning, you pay 300 crystals to swap foe’s ATK and DEF
Test Cases:

Test Case ID: TC-FUNC-Mirror-Lady-001
Description:
Mirror Lady: optional pay 300 crystals for +0 ATK
Implementation Reference:
- TurnManager pre-battle crystal prompt OPTIONAL_CRYSTAL_PAY_ATK_BOOST
- AbilityType.OPTIONAL_CRYSTAL_PAY_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Player crystals ≥ 300 and < 300 for decline test.
Steps:
Step 1: Accept prompt / Decline prompt in separate runs.
Expected Result:
- Accept: attacker_atk_used includes +0; crystals -= 300.
- Decline: no bonus; no payment.

---

Card Name: Silver Dragon
Type: Character
Stats: ATK=155 DEF=95 Cost=1500 Affinity=ARCANE
AbilityType: OPTIONAL_CRYSTAL_PAY_ATK_BOOST
ability_params: {'cost': 1000, 'atk': 0, 'mandatory': True, 'per_attack': True}
Description: Pay 1000 Crystal tax to command this card for attack
Test Cases:

Test Case ID: TC-FUNC-Silver-Dragon-001
Description:
Silver Dragon: optional pay 1000 crystals for +0 ATK
Implementation Reference:
- TurnManager pre-battle crystal prompt OPTIONAL_CRYSTAL_PAY_ATK_BOOST
- AbilityType.OPTIONAL_CRYSTAL_PAY_ATK_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Player crystals ≥ 1000 and < 1000 for decline test.
Steps:
Step 1: Accept prompt / Decline prompt in separate runs.
Expected Result:
- Accept: attacker_atk_used includes +0; crystals -= 1000.
- Decline: no bonus; no payment.

---

Card Name: Crab Ronin
Type: Character
Stats: ATK=75 DEF=50 Cost=950 Affinity=NATURE
AbilityType: OPTIONAL_CRYSTAL_PAY_DEF_BOOST
ability_params: {'cost': 1000, 'def': 20, 'permanent': True}
Description: At Reckoning, pay 1000 Crystals then +20 DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Crab-Ronin-001
Description:
Crab Ronin: optional pay 1000 for +20 DEF during battle
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
- Accept: effective DEF +20; crystals -= 1000.

---

Card Name: Moon Nobleman
Type: Character
Stats: ATK=125 DEF=110 Cost=1200 Affinity=ARCANE
AbilityType: OPTIONAL_CRYSTAL_PAY_DEF_BOOST
ability_params: {'cost': 500, 'on_survive_battle': True}
Description: If this card battles and survived, pay 500 Crystal cost
Test Cases:

Test Case ID: TC-FUNC-Moon-Nobleman-001
Description:
Moon Nobleman: optional pay 500 for +60 DEF during battle
Implementation Reference:
- TurnManager OPTIONAL_CRYSTAL_PAY_DEF_BOOST on defender side
- AbilityType.OPTIONAL_CRYSTAL_PAY_DEF_BOOST
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Union/card defends; crystals>=500.
Steps:
Step 1: Accept/decline DEF boost prompt on battle overlay.
Expected Result:
- Accept: effective DEF +60; crystals -= 500.

---

Card Name: Blood Mage
Type: Character
Stats: ATK=70 DEF=90 Cost=1300 Affinity=CHAOS
AbilityType: OPTIONAL_CRYSTAL_PAY_DESTROY_OPPONENT
ability_params: {'cost': 1000}
Description: In Reckoning, you can pay 1000 Crystals to destroy foe unit.
Test Cases:

Test Case ID: TC-FUNC-Blood-Mage-001
Description:
Blood Mage: pay 1000 crystals to destroy defender (no opp crystal loss)
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

Card Name: Bloom Fairy
Type: Character
Stats: ATK=35 DEF=40 Cost=500 Affinity=DIVINE
AbilityType: PERM_ATK_BOOST_ON_KILL_CAPPED
ability_params: {'atk': 5, 'max_bonus': 25, 'turn_end': True}
Description: At the end of this turn, +5 ATK permanently. This bonus does not exceed maximum of 25
Test Cases:

Test Case ID: TC-FUNC-Bloom-Fairy-001
Description:
Bloom Fairy: ability PERM_ATK_BOOST_ON_KILL_CAPPED functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_ATK_BOOST_ON_KILL_CAPPED
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'atk': 5, 'max_bonus': 25, 'turn_end': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: At the end of this turn, +5 ATK permanently. This bonus does not exceed maximum of 25

---

Card Name: Champion of the Valley
Type: Character
Stats: ATK=35 DEF=45 Cost=400 Affinity=ANIMA
AbilityType: PERM_ATK_BOOST_ON_KILL_CAPPED
ability_params: {'atk': 10, 'max_bonus': 30}
Description: +10 ATK permanently if it destroyed a unit. This bonus does not exceed 30
Test Cases:

Test Case ID: TC-FUNC-Champion-of-the-Valley-001
Description:
Champion of the Valley: ability PERM_ATK_BOOST_ON_KILL_CAPPED functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_ATK_BOOST_ON_KILL_CAPPED
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'atk': 10, 'max_bonus': 30}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +10 ATK permanently if it destroyed a unit. This bonus does not exceed 30

---

Card Name: Dark Blob
Type: Character
Stats: ATK=20 DEF=50 Cost=500 Affinity=CHAOS
AbilityType: PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN
ability_params: {'atk': 5}
Description: After Reckoning: +5 ATK at the end of foe’s turn
Test Cases:

Test Case ID: TC-FUNC-Dark-Blob-001
Description:
Dark Blob: +5 ATK when alive at end of opponent turn
Implementation Reference:
- TurnManager._apply_end_of_turn_boosts
- AbilityType.PERM_ATK_BOOST_PER_SURVIVE_OPP_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Dark Blob survives opponent's turn face-up.
Steps:
Step 1: End opponent turn / start own turn.
Expected Result:
- current_atk += 5.

---

Card Name: Cursed Well
Type: Character
Stats: ATK=0 DEF=25 Cost=300 Affinity=CHAOS
AbilityType: PERM_ATK_BOOST_WHEN_EXPOSED
ability_params: {'amount': 15}
Description: At the end of the turn that it’s been exposed, +15 ATK permanently
Test Cases:

Test Case ID: TC-FUNC-Cursed-Well-001
Description:
Cursed Well: ability PERM_ATK_BOOST_WHEN_EXPOSED functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_ATK_BOOST_WHEN_EXPOSED
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 15}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: At the end of the turn that it’s been exposed, +15 ATK permanently

---

Card Name: Johnny the Most Wanted
Type: Character
Stats: ATK=25 DEF=20 Cost=450 Affinity=ANIMA
AbilityType: PERM_ATK_BOOST_WHEN_EXPOSED
ability_params: {'amount': 5}
Description: After it performed attack, flip a coin. Heads: +5 ATK permanently. This bonus does not exceed 10
Test Cases:

Test Case ID: TC-FUNC-Johnny-the-Most-Wanted-001
Description:
Johnny the Most Wanted: ability PERM_ATK_BOOST_WHEN_EXPOSED functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_ATK_BOOST_WHEN_EXPOSED
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 5}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After it performed attack, flip a coin. Heads: +5 ATK permanently. This bonus does not exceed 10

---

Card Name: Sleeping Kirin
Type: Character
Stats: ATK=0 DEF=25 Cost=400 Affinity=DIVINE
AbilityType: PERM_ATK_BOOST_WHEN_EXPOSED
ability_params: {'amount': 25}
Description: +25 ATK permanently
Test Cases:

Test Case ID: TC-FUNC-Sleeping-Kirin-001
Description:
Sleeping Kirin: ability PERM_ATK_BOOST_WHEN_EXPOSED functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PERM_ATK_BOOST_WHEN_EXPOSED
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 25}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: +25 ATK permanently

---

Card Name: War Genie
Type: Character
Stats: ATK=100 DEF=80 Cost=1150 Affinity=ARCANE
AbilityType: PERM_ATK_LOSS_PER_ATTACK
ability_params: {'amount': 10}
Description: -10 ATK permanently after it attacked
Test Cases:

Test Case ID: TC-FUNC-War-Genie-001
Description:
War Genie: -10 ATK permanently after each attack
Implementation Reference:
- TurnManager._apply_post_battle_effects
- AbilityType.PERM_ATK_LOSS_PER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- War Genie attacks.
Steps:
Step 1: Resolve any battle result.
Expected Result:
- current_atk -= 10 (floored at 0).

---

Card Name: Dark Cavalier
Type: Character
Stats: ATK=100 DEF=60 Cost=1500 Affinity=CHAOS
AbilityType: PERM_ATK_LOSS_PER_OWN_TURN
ability_params: {'amount': 20, 'if_no_attack': True}
Description: If this card has not performed attack, -20 ATK permanently at the end of your turn
Test Cases:

Test Case ID: TC-FUNC-Dark-Cavalier-001
Description:
Dark Cavalier: -20 ATK at end of own turn (face-up)
Implementation Reference:
- TurnManager._end_turn match PERM_ATK_LOSS_PER_OWN_TURN
- AbilityType.PERM_ATK_LOSS_PER_OWN_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Dark Cavalier face-up at end of owner's turn.
Steps:
Step 1: End turn.
Expected Result:
- current_atk -= 20.

---

Card Name: Jiro the Battlemaster
Type: Character
Stats: ATK=65 DEF=30 Cost=500 Affinity=DIVINE
AbilityType: PERM_ATK_LOSS_PER_OWN_TURN
ability_params: {'amount': 10, 'if_no_attack': True}
Description: -10 ATK permanently at the end of that turn if this card has not performed attack.
Test Cases:

Test Case ID: TC-FUNC-Jiro-the-Battlemaster-001
Description:
Jiro the Battlemaster: -10 ATK at end of own turn (face-up)
Implementation Reference:
- TurnManager._end_turn match PERM_ATK_LOSS_PER_OWN_TURN
- AbilityType.PERM_ATK_LOSS_PER_OWN_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Jiro the Battlemaster face-up at end of owner's turn.
Steps:
Step 1: End turn.
Expected Result:
- current_atk -= 10.

---

Card Name: Rotten Shrieker
Type: Character
Stats: ATK=40 DEF=30 Cost=450 Affinity=BIO
AbilityType: PERM_ATK_LOSS_PER_OWN_TURN
ability_params: {'amount': 10}
Description: Without Mutagen Flag : -10 ATK permanently at the end of your turn.
Test Cases:

Test Case ID: TC-FUNC-Rotten-Shrieker-001
Description:
Rotten Shrieker: -10 ATK at end of own turn (face-up)
Implementation Reference:
- TurnManager._end_turn match PERM_ATK_LOSS_PER_OWN_TURN
- AbilityType.PERM_ATK_LOSS_PER_OWN_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Rotten Shrieker face-up at end of owner's turn.
Steps:
Step 1: End turn.
Expected Result:
- current_atk -= 10.

---

Card Name: Superionic Leviathan
Type: Character
Stats: ATK=180 DEF=180 Cost=1500 Affinity=COSMIC
AbilityType: PERM_ATK_LOSS_PER_OWN_TURN
ability_params: {'crystal_or_halve': 1000}
Description: At the end of each player’s turn, pay 1000 crystals or halve its ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Superionic-Leviathan-001
Description:
Superionic Leviathan: -0 ATK at end of own turn (face-up)
Implementation Reference:
- TurnManager._end_turn match PERM_ATK_LOSS_PER_OWN_TURN
- AbilityType.PERM_ATK_LOSS_PER_OWN_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Superionic Leviathan face-up at end of owner's turn.
Steps:
Step 1: End turn.
Expected Result:
- current_atk -= 0.

---

Card Name: Corrupted Gremlin
Type: Character
Stats: ATK=50 DEF=60 Cost=960 Affinity=ARCANE
AbilityType: PERM_BOOST_END_OF_TURN
ability_params: {'atk': 10, 'def': 0, 'on_crystal_gain': True, 'max_atk': 50}
Description: Whenever you gains Crystals from any source, this card gains +10 ATK permanently (max +50).
Test Cases:

Test Case ID: TC-FUNC-Corrupted-Gremlin-001
Description:
Corrupted Gremlin: +10/+0 permanent at end of turn
Implementation Reference:
- TurnManager._apply_end_of_turn_boosts PERM_BOOST_END_OF_TURN
- AbilityType.PERM_BOOST_END_OF_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Corrupted Gremlin face-up.
Steps:
Step 1: End own turn.
Expected Result:
- current_atk += 10; current_def += 0.

Test Case ID: TC-FUNC-Corrupted-Gremlin-002
Description:
Corrupted Gremlin: standard ATK vs DEF (no ability)
Implementation Reference:
- BattleResolver standard comparison only
- AbilityType.NONE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Corrupted Gremlin ATK=50 DEF=60.
Steps:
Step 1: Attack Wandering Swordsman (60/60) or suitable target.
Expected Result:
- Pure stat comparison; no ability_triggered flags.
- Crystal loss equals destroyed card's cost.

---

Card Name: Greedy Gremlin
Type: Character
Stats: ATK=20 DEF=20 Cost=300 Affinity=ARCANE
AbilityType: PERM_BOOST_END_OF_TURN
ability_params: {'atk': 10, 'def': 10, 'on_crystal_gain': True, 'once': True}
Description: Whenever you gains Crystals from any source, this card gains +10 ATK&DEF permanently, once.
Test Cases:

Test Case ID: TC-FUNC-Greedy-Gremlin-001
Description:
Greedy Gremlin: +10/+10 permanent at end of turn
Implementation Reference:
- TurnManager._apply_end_of_turn_boosts PERM_BOOST_END_OF_TURN
- AbilityType.PERM_BOOST_END_OF_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Greedy Gremlin face-up.
Steps:
Step 1: End own turn.
Expected Result:
- current_atk += 10; current_def += 10.

Test Case ID: TC-FUNC-Greedy-Gremlin-002
Description:
Greedy Gremlin: standard ATK vs DEF (no ability)
Implementation Reference:
- BattleResolver standard comparison only
- AbilityType.NONE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Greedy Gremlin ATK=20 DEF=20.
Steps:
Step 1: Attack Wandering Swordsman (60/60) or suitable target.
Expected Result:
- Pure stat comparison; no ability_triggered flags.
- Crystal loss equals destroyed card's cost.

---

Card Name: Hyperspeed Saucer
Type: Character
Stats: ATK=80 DEF=40 Cost=850 Affinity=COSMIC
AbilityType: PERM_BOOST_END_OF_TURN
ability_params: {'atk': 10, 'def': 10}
Description: Permanently increase this card's ATK&DEF by 10 at the end of each of your turn
Test Cases:

Test Case ID: TC-FUNC-Hyperspeed-Saucer-001
Description:
Hyperspeed Saucer: +10/+10 permanent at end of turn
Implementation Reference:
- TurnManager._apply_end_of_turn_boosts PERM_BOOST_END_OF_TURN
- AbilityType.PERM_BOOST_END_OF_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hyperspeed Saucer face-up.
Steps:
Step 1: End own turn.
Expected Result:
- current_atk += 10; current_def += 10.

Test Case ID: TC-FUNC-Hyperspeed-Saucer-002
Description:
Hyperspeed Saucer: standard ATK vs DEF (no ability)
Implementation Reference:
- BattleResolver standard comparison only
- AbilityType.NONE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Hyperspeed Saucer ATK=80 DEF=40.
Steps:
Step 1: Attack Wandering Swordsman (60/60) or suitable target.
Expected Result:
- Pure stat comparison; no ability_triggered flags.
- Crystal loss equals destroyed card's cost.

---

Card Name: Tholin Battleship
Type: Character
Stats: ATK=85 DEF=70 Cost=950 Affinity=COSMIC
AbilityType: PERM_BOOST_END_OF_TURN
ability_params: {'atk': 50, 'def': 50, 'vs_trap': True}
Description: +50 ATK&DEF permanently if attack a trap.
Test Cases:

Test Case ID: TC-FUNC-Tholin-Battleship-001
Description:
Tholin Battleship: +50/+50 permanent at end of turn
Implementation Reference:
- TurnManager._apply_end_of_turn_boosts PERM_BOOST_END_OF_TURN
- AbilityType.PERM_BOOST_END_OF_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tholin Battleship face-up.
Steps:
Step 1: End own turn.
Expected Result:
- current_atk += 50; current_def += 50.

Test Case ID: TC-FUNC-Tholin-Battleship-002
Description:
Tholin Battleship: standard ATK vs DEF (no ability)
Implementation Reference:
- BattleResolver standard comparison only
- AbilityType.NONE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tholin Battleship ATK=85 DEF=70.
Steps:
Step 1: Attack Wandering Swordsman (60/60) or suitable target.
Expected Result:
- Pure stat comparison; no ability_triggered flags.
- Crystal loss equals destroyed card's cost.

---

Card Name: Armored Elephant
Type: Character
Stats: ATK=20 DEF=150 Cost=800 Affinity=NATURE
AbilityType: PERM_DEF_BOOST_ON_DEFEND
ability_params: {'def': -50, 'per_successful_defense': True}
Description: -50 DEF for each successful defense
Test Cases:

Test Case ID: TC-FUNC-Armored-Elephant-001
Description:
Armored Elephant: +-50 DEF permanently after successful defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.PERM_DEF_BOOST_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent ATK < Armored Elephant DEF.
Steps:
Step 1: Defend successfully.
Expected Result:
- defender.current_def increased by -50 permanently.

---

Card Name: Aurumancer
Type: Character
Stats: ATK=25 DEF=125 Cost=700 Affinity=ARCANE
AbilityType: PERM_DEF_BOOST_ON_DEFEND
ability_params: {'cost_set': 1500}
Description: After this card successfully defended, its cost becomes 1500
Test Cases:

Test Case ID: TC-FUNC-Aurumancer-001
Description:
Aurumancer: +0 DEF permanently after successful defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.PERM_DEF_BOOST_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent ATK < Aurumancer DEF.
Steps:
Step 1: Defend successfully.
Expected Result:
- defender.current_def increased by 0 permanently.

---

Card Name: Elven Swordsman
Type: Character
Stats: ATK=25 DEF=35 Cost=290 Affinity=NATURE
AbilityType: PERM_DEF_BOOST_ON_DEFEND
ability_params: {'def': -20}
Description: After successfully defended : -20 DEF
Test Cases:

Test Case ID: TC-FUNC-Elven-Swordsman-001
Description:
Elven Swordsman: +-20 DEF permanently after successful defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.PERM_DEF_BOOST_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent ATK < Elven Swordsman DEF.
Steps:
Step 1: Defend successfully.
Expected Result:
- defender.current_def increased by -20 permanently.

---

Card Name: Jirayu the Rebellious Prince
Type: Character
Stats: ATK=40 DEF=40 Cost=600 Affinity=ANIMA
AbilityType: PERM_DEF_BOOST_ON_DEFEND
ability_params: {'def': 10}
Description: If this card successfully defended, +10 DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Jirayu-the-Rebellious-Prince-001
Description:
Jirayu the Rebellious Prince: +10 DEF permanently after successful defend
Implementation Reference:
- BattleResolver._apply_defend_effects
- AbilityType.PERM_DEF_BOOST_ON_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent ATK < Jirayu the Rebellious Prince DEF.
Steps:
Step 1: Defend successfully.
Expected Result:
- defender.current_def increased by 10 permanently.

---

Card Name: Leech Man
Type: Character
Stats: ATK=60 DEF=40 Cost=880 Affinity=BIO
AbilityType: PERM_DEF_BOOST_PER_ATTACK_SURVIVE
ability_params: {'def': 10}
Description: +10 DEF permanently after it performed attack on unit. Also +10 ATK with mutagen flag
Test Cases:

Test Case ID: TC-FUNC-Leech-Man-001
Description:
Leech Man: +10 DEF permanently each attack survived
Implementation Reference:
- TurnManager._apply_post_battle_effects
- AbilityType.PERM_DEF_BOOST_PER_ATTACK_SURVIVE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Leech Man attacks and survives (wins or ties without self-destruct).
Steps:
Step 1: Complete attack.
Expected Result:
- perm_def_bonus += 10 (or current_def += 10).

---

Card Name: Travis the Battle Priest
Type: Character
Stats: ATK=80 DEF=25 Cost=700 Affinity=DIVINE
AbilityType: POST_BATTLE_COIN_FLIP_DESTROY
ability_params: {'reveal_adjacent': True, 'destroy_affinity': 'CHAOS'}
Description: After Reckoning, flip a coin. Heads: Reveal one adjacent cell. Destroy it if it’s Chaos.
Test Cases:

Test Case ID: TC-FUNC-Travis-the-Battle-Priest-001
Description:
Travis the Battle Priest: ability POST_BATTLE_COIN_FLIP_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.POST_BATTLE_COIN_FLIP_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'reveal_adjacent': True, 'destroy_affinity': 'CHAOS'}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: After Reckoning, flip a coin. Heads: Reveal one adjacent cell. Destroy it if it’s Chaos.

---

Card Name: WK-17 the Siren
Type: Character
Stats: ATK=10 DEF=25 Cost=200 Affinity=BIO
AbilityType: PRE_BATTLE_COIN_FLIP_2_REDIRECT_OR_DESTROY
ability_params: {}
Description: Before Reckoning, flip 2 coin. Both are Heads : foe choose their ally to fight in place of this card. Both are Tails : Destroy this card.
Test Cases:

Test Case ID: TC-FUNC-WK-17-the-Siren-001
Description:
WK-17 the Siren: ability PRE_BATTLE_COIN_FLIP_2_REDIRECT_OR_DESTROY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PRE_BATTLE_COIN_FLIP_2_REDIRECT_OR_DESTROY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Before Reckoning, flip 2 coin. Both are Heads : foe choose their ally to fight in place of this card. Both are Tails : Destroy this card.

---

Card Name: Gravedigger
Type: Character
Stats: ATK=20 DEF=15 Cost=250 Affinity=ANIMA
AbilityType: PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
ability_params: {'affinity': 'CHAOS', 'def': 20, 'as_attacker': True}
Description: -20 DEF to Chaos defender
Test Cases:

Test Case ID: TC-FUNC-Gravedigger-001
Description:
Gravedigger: ability PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'CHAOS', 'def': 20, 'as_attacker': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: -20 DEF to Chaos defender

---

Card Name: Radiaghoul
Type: Character
Stats: ATK=20 DEF=5 Cost=160 Affinity=BIO
AbilityType: PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
ability_params: {'affinity': 'NATURE', 'def': 5}
Description: Before Reckoning, -5 DEF permanently to Nature foe
Test Cases:

Test Case ID: TC-FUNC-Radiaghoul-001
Description:
Radiaghoul: ability PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinity': 'NATURE', 'def': 5}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Before Reckoning, -5 DEF permanently to Nature foe

---

Card Name: Rama the Justice Arrow
Type: Character
Stats: ATK=85 DEF=70 Cost=990 Affinity=DIVINE
AbilityType: PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
ability_params: {'def': 20, 'target': 'defender'}
Description: At Reckoning, -20 DEF to the defender
Test Cases:

Test Case ID: TC-FUNC-Rama-the-Justice-Arrow-001
Description:
Rama the Justice Arrow: ability PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'def': 20, 'target': 'defender'}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: At Reckoning, -20 DEF to the defender

---

Card Name: Sickle Mantis
Type: Character
Stats: ATK=30 DEF=10 Cost=300 Affinity=NATURE
AbilityType: PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
ability_params: {'def': 10, 'target': 'defender'}
Description: At Reckoning, -10 DEF to the defender
Test Cases:

Test Case ID: TC-FUNC-Sickle-Mantis-001
Description:
Sickle Mantis: ability PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'def': 10, 'target': 'defender'}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: At Reckoning, -10 DEF to the defender

---

Card Name: Spell Ninja
Type: Character
Stats: ATK=40 DEF=40 Cost=600 Affinity=ANIMA
AbilityType: PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
ability_params: {'def': 5, 'target': 'foe_reckoning_anima'}
Description: In Reckoning, foe’s unit get -5 DEF permanently
Test Cases:

Test Case ID: TC-FUNC-Spell-Ninja-001
Description:
Spell Ninja: ability PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY functional smoke test
Implementation Reference:
- CharacterData.AbilityType.PRE_BATTLE_PERM_DEF_DEBUFF_VS_AFFINITY
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'def': 5, 'target': 'foe_reckoning_anima'}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: In Reckoning, foe’s unit get -5 DEF permanently

---

Card Name: Archbishop
Type: Character
Stats: ATK=70 DEF=90 Cost=1200 Affinity=DIVINE
AbilityType: REDIRECT_DESTRUCTION_TO_ALLY
ability_params: {'affinity': 'DIVINE'}
Description: If this card would be destroyed, you can destroy 1 other Divine card on your side instead
Test Cases:

Test Case ID: TC-FUNC-Archbishop-001
Description:
Archbishop: redirect own destruction to other DIVINE ally
Implementation Reference:
- TurnManager._apply_battle_result prompts own_divine_character_redirect
- GameBoard destroys chosen ally instead
- AbilityType.REDIRECT_DESTRUCTION_TO_ALLY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Archbishop would be destroyed.
- Another face-up DIVINE ally on field (not REDIRECT card).
Steps:
Step 1: Trigger destruction; choose redirect target.
Expected Result:
- Archbishop survives; chosen DIVINE ally destroyed and owner pays cost.

---

Card Name: Europan Tankmaster
Type: Character
Stats: ATK=30 DEF=25 Cost=400 Affinity=COSMIC
AbilityType: REDIRECT_DESTRUCTION_TO_ALLY
ability_params: {'flag': 'Europa', 'remove_flag': True}
Description: If this card is going to be destroy, you can remove 1 Europa flag from this card instead
Test Cases:

Test Case ID: TC-FUNC-Europan-Tankmaster-001
Description:
Europan Tankmaster: redirect own destruction to other ? ally
Implementation Reference:
- TurnManager._apply_battle_result prompts own_divine_character_redirect
- GameBoard destroys chosen ally instead
- AbilityType.REDIRECT_DESTRUCTION_TO_ALLY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Europan Tankmaster would be destroyed.
- Another face-up ? ally on field (not REDIRECT card).
Steps:
Step 1: Trigger destruction; choose redirect target.
Expected Result:
- Europan Tankmaster survives; chosen ? ally destroyed and owner pays cost.

---

Card Name: Leviathan
Type: Character
Stats: ATK=55 DEF=85 Cost=1200 Affinity=ARCANE
AbilityType: REDIRECT_DESTRUCTION_TO_ALLY
ability_params: {'affinity': 'ARCANE', 'crystal_cost': 500, 'vs_non_arcane': True, 'face_down': True}
Description: If ally Arcane card would be destroyed by Non-Arcane unit, pay 500 Crystals, it is not destroyed. Can be use face-down.
Test Cases:

Test Case ID: TC-FUNC-Leviathan-001
Description:
Leviathan: redirect own destruction to other ARCANE ally
Implementation Reference:
- TurnManager._apply_battle_result prompts own_divine_character_redirect
- GameBoard destroys chosen ally instead
- AbilityType.REDIRECT_DESTRUCTION_TO_ALLY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Leviathan would be destroyed.
- Another face-up ARCANE ally on field (not REDIRECT card).
Steps:
Step 1: Trigger destruction; choose redirect target.
Expected Result:
- Leviathan survives; chosen ARCANE ally destroyed and owner pays cost.

---

Card Name: Necro Zombie
Type: Character
Stats: ATK=70 DEF=15 Cost=500 Affinity=CHAOS
AbilityType: REDIRECT_DESTRUCTION_TO_ALLY
ability_params: {'name_contains': 'Zombie'}
Description: If this card is going to be destroyed, you can destroy ally Zombie card instead.
Test Cases:

Test Case ID: TC-FUNC-Necro-Zombie-001
Description:
Necro Zombie: redirect own destruction to other ? ally
Implementation Reference:
- TurnManager._apply_battle_result prompts own_divine_character_redirect
- GameBoard destroys chosen ally instead
- AbilityType.REDIRECT_DESTRUCTION_TO_ALLY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Necro Zombie would be destroyed.
- Another face-up ? ally on field (not REDIRECT card).
Steps:
Step 1: Trigger destruction; choose redirect target.
Expected Result:
- Necro Zombie survives; chosen ? ally destroyed and owner pays cost.

---

Card Name: Rena the Space Princess
Type: Character
Stats: ATK=40 DEF=40 Cost=420 Affinity=COSMIC
AbilityType: REDIRECT_DESTRUCTION_TO_ALLY
ability_params: {'affinity': 'COSMIC'}
Description: If this card would be destroyed, remove 1 princess flag from ally unit instead.
Test Cases:

Test Case ID: TC-FUNC-Rena-the-Space-Princess-001
Description:
Rena the Space Princess: redirect own destruction to other COSMIC ally
Implementation Reference:
- TurnManager._apply_battle_result prompts own_divine_character_redirect
- GameBoard destroys chosen ally instead
- AbilityType.REDIRECT_DESTRUCTION_TO_ALLY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Rena the Space Princess would be destroyed.
- Another face-up COSMIC ally on field (not REDIRECT card).
Steps:
Step 1: Trigger destruction; choose redirect target.
Expected Result:
- Rena the Space Princess survives; chosen COSMIC ally destroyed and owner pays cost.

---

Card Name: Royal Guard
Type: Character
Stats: ATK=60 DEF=60 Cost=1200 Affinity=ANIMA
AbilityType: REDIRECT_DESTRUCTION_TO_ALLY
ability_params: {'affinity': 'ANIMA', 'half_cost_until_next_turn': True}
Description: If this card is going to be destroyed, until start of your next turn, you pay only halve of Anima unit’s cost
Test Cases:

Test Case ID: TC-FUNC-Royal-Guard-001
Description:
Royal Guard: redirect own destruction to other ANIMA ally
Implementation Reference:
- TurnManager._apply_battle_result prompts own_divine_character_redirect
- GameBoard destroys chosen ally instead
- AbilityType.REDIRECT_DESTRUCTION_TO_ALLY
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Royal Guard would be destroyed.
- Another face-up ANIMA ally on field (not REDIRECT card).
Steps:
Step 1: Trigger destruction; choose redirect target.
Expected Result:
- Royal Guard survives; chosen ANIMA ally destroyed and owner pays cost.

---

Card Name: Scout Probe
Type: Character
Stats: ATK=40 DEF=50 Cost=700 Affinity=COSMIC
AbilityType: REVEAL_ADJACENT_AFTER_ATTACK
ability_params: {}
Description: After this card attacks, choose and reveal 1 adjacent cell.
Test Cases:

Test Case ID: TC-FUNC-Scout-Probe-001
Description:
Scout Probe: reveal adjacent cell after attack (Scout Probe)
Implementation Reference:
- TurnManager after battle (win or lose)
- AbilityType.REVEAL_ADJACENT_AFTER_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Scout Probe completes an attack (survives or is destroyed in Reckoning).
Steps:
Step 1: Select adjacent hidden cell.
Expected Result:
- Adjacent cell revealed.

---

Card Name: Europan Trooper
Type: Character
Stats: ATK=25 DEF=10 Cost=260 Affinity=COSMIC
AbilityType: REVEAL_ON_ANY_ATTACK
ability_params: {'flag': 'Europa', 'when_attacked': True}
Description: After attacked, Put Europa flag on 1 of your unit.
Test Cases:

Test Case ID: TC-FUNC-Europan-Trooper-001
Description:
Europan Trooper: reveal 1 opponent hidden cell after any attack
Implementation Reference:
- TurnManager emit awaiting_target_selection opponent_any_hidden
- AbilityType.REVEAL_ON_ANY_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Europan Trooper attacks any target.
Steps:
Step 1: Complete target selection UI.
Expected Result:
- One opponent face-down cell becomes face_up.

---

Card Name: Shepherd Detective
Type: Character
Stats: ATK=40 DEF=25 Cost=400 Affinity=ANIMA
AbilityType: REVEAL_ON_ANY_ATTACK
ability_params: {}
Description: After performed attack : reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Shepherd-Detective-001
Description:
Shepherd Detective: reveal 1 opponent hidden cell after any attack
Implementation Reference:
- TurnManager emit awaiting_target_selection opponent_any_hidden
- AbilityType.REVEAL_ON_ANY_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Shepherd Detective attacks any target.
Steps:
Step 1: Complete target selection UI.
Expected Result:
- One opponent face-down cell becomes face_up.

---

Card Name: Solarling
Type: Character
Stats: ATK=20 DEF=0 Cost=120 Affinity=COSMIC
AbilityType: REVEAL_ON_ANY_ATTACK
ability_params: {'count': 1, 'own_cell': True, 'when_attacked': True}
Description: After attacked: Reveal 1 of your own cells
Test Cases:

Test Case ID: TC-FUNC-Solarling-001
Description:
Solarling: reveal 1 opponent hidden cell after any attack
Implementation Reference:
- TurnManager emit awaiting_target_selection opponent_any_hidden
- AbilityType.REVEAL_ON_ANY_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Solarling attacks any target.
Steps:
Step 1: Complete target selection UI.
Expected Result:
- One opponent face-down cell becomes face_up.

---

Card Name: Moon Rover
Type: Character
Stats: ATK=15 DEF=20 Cost=200 Affinity=COSMIC
AbilityType: REVEAL_ON_DEAD_END_ATTACK
ability_params: {}
Description: After hitting a Dead End : reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Moon-Rover-001
Description:
Moon Rover: reveal after dead_end attack
Implementation Reference:
- TurnManager when defender.card_type=='dead_end'
- AbilityType.REVEAL_ON_DEAD_END_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- dead_end target.
Steps:
Step 1: Attack empty cell.
Expected Result:
- Reveal selection triggered.

---

Card Name: Neptune Diver
Type: Character
Stats: ATK=20 DEF=10 Cost=200 Affinity=COSMIC
AbilityType: REVEAL_ON_TRAP_ATTACK
ability_params: {}
Description: After hitting a trap : reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Neptune-Diver-001
Description:
Neptune Diver: reveal after trap attack
Implementation Reference:
- TurnManager when special_trigger trap_*
- AbilityType.REVEAL_ON_TRAP_ATTACK
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Opponent trap face-down.
Steps:
Step 1: Attack trap.
Expected Result:
- Reveal prompt after trap resolution.

---

Card Name: Dwarven Bomber
Type: Character
Stats: ATK=35 DEF=15 Cost=600 Affinity=ARCANE
AbilityType: REVEAL_ON_WIN
ability_params: {'count': 1}
Description: After this card battled, flip a coin. If 3 coin, reveal foe’s cell up to number of head. If got 3 tail, destroy this card
Test Cases:

Test Case ID: TC-FUNC-Dwarven-Bomber-001
Description:
Dwarven Bomber: reveal on win only
Implementation Reference:
- TurnManager when defender_destroyed
- AbilityType.REVEAL_ON_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Win and lose scenarios.
Steps:
Step 1: Attack character / dead_end.
Expected Result:
- Reveal prompt only when defender_destroyed.

---

Card Name: Dwarven Explorer
Type: Character
Stats: ATK=10 DEF=15 Cost=250 Affinity=ARCANE
AbilityType: REVEAL_ON_WIN
ability_params: {'count': 1}
Description: After this card battled, reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Dwarven-Explorer-001
Description:
Dwarven Explorer: reveal on win only
Implementation Reference:
- TurnManager when defender_destroyed
- AbilityType.REVEAL_ON_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Win and lose scenarios.
Steps:
Step 1: Attack character / dead_end.
Expected Result:
- Reveal prompt only when defender_destroyed.

---

Card Name: Dwarven Miner
Type: Character
Stats: ATK=30 DEF=20 Cost=380 Affinity=ARCANE
AbilityType: REVEAL_ON_WIN
ability_params: {'count': 1}
Description: After this card battled, flip a coin. If head, reveal 1 of foe’s cell, if tail, it loses 5 ATK
Test Cases:

Test Case ID: TC-FUNC-Dwarven-Miner-001
Description:
Dwarven Miner: reveal on win only
Implementation Reference:
- TurnManager when defender_destroyed
- AbilityType.REVEAL_ON_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Win and lose scenarios.
Steps:
Step 1: Attack character / dead_end.
Expected Result:
- Reveal prompt only when defender_destroyed.

---

Card Name: Mysterious Miner
Type: Character
Stats: ATK=25 DEF=15 Cost=250 Affinity=CHAOS
AbilityType: REVEAL_ON_WIN
ability_params: {}
Description: After attacked: reveal 1 foe’s cell
Test Cases:

Test Case ID: TC-FUNC-Mysterious-Miner-001
Description:
Mysterious Miner: reveal on win only
Implementation Reference:
- TurnManager when defender_destroyed
- AbilityType.REVEAL_ON_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Win and lose scenarios.
Steps:
Step 1: Attack character / dead_end.
Expected Result:
- Reveal prompt only when defender_destroyed.

---

Card Name: Parasite Enceladus
Type: Character
Stats: ATK=20 DEF=30 Cost=500 Affinity=COSMIC
AbilityType: REVEAL_ON_WIN
ability_params: {'count': 2}
Description: With Mutagen Flag : After Reckoning, reveal 2 cards on foe’s side.
Test Cases:

Test Case ID: TC-FUNC-Parasite-Enceladus-001
Description:
Parasite Enceladus: reveal on win only
Implementation Reference:
- TurnManager when defender_destroyed
- AbilityType.REVEAL_ON_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Win and lose scenarios.
Steps:
Step 1: Attack character / dead_end.
Expected Result:
- Reveal prompt only when defender_destroyed.

---

Card Name: Steel Eagle
Type: Character
Stats: ATK=70 DEF=70 Cost=850 Affinity=NATURE
AbilityType: REVEAL_ON_WIN
ability_params: {'count': 1}
Description: After this card attacked (survived or not), reveal 1 of foe’s face-down cell
Test Cases:

Test Case ID: TC-FUNC-Steel-Eagle-001
Description:
Steel Eagle: reveal on win only
Implementation Reference:
- TurnManager when defender_destroyed
- AbilityType.REVEAL_ON_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Win and lose scenarios.
Steps:
Step 1: Attack character / dead_end.
Expected Result:
- Reveal prompt only when defender_destroyed.

---

Card Name: Zombie Dog
Type: Character
Stats: ATK=55 DEF=20 Cost=450 Affinity=BIO
AbilityType: REVEAL_ON_WIN
ability_params: {'count': 1, 'adjacent_to_target': True, 'requires_mutagen': True}
Description: With Mutagen Flag: After Reckoning, reveal 1 adjacent cell around foe’s unit.
Test Cases:

Test Case ID: TC-FUNC-Zombie-Dog-001
Description:
Zombie Dog: reveal on win only
Implementation Reference:
- TurnManager when defender_destroyed
- AbilityType.REVEAL_ON_WIN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Win and lose scenarios.
Steps:
Step 1: Attack character / dead_end.
Expected Result:
- Reveal prompt only when defender_destroyed.

---

Card Name: Bone Dragon
Type: Character
Stats: ATK=135 DEF=0 Cost=1550 Affinity=CHAOS
AbilityType: REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
ability_params: {'foe_turn_end': True, 'coin_flip': True}
Description: When it’s destroyed, at the end of foe’s turn, flip a coin. If head, revive it.
Test Cases:

Test Case ID: TC-FUNC-Bone-Dragon-001
Description:
Bone Dragon: ability REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'foe_turn_end': True, 'coin_flip': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: When it’s destroyed, at the end of foe’s turn, flip a coin. If head, revive it.

---

Card Name: Hanuman the Second Wind
Type: Character
Stats: ATK=95 DEF=60 Cost=1250 Affinity=NATURE
AbilityType: REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
ability_params: {'requires_divine_ally': True, 'self_revive': True}
Description: Once, at the start of your turn, if there is Divine unit on your side, revive itself
Test Cases:

Test Case ID: TC-FUNC-Hanuman-the-Second-Wind-001
Description:
Hanuman the Second Wind: ability REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'requires_divine_ally': True, 'self_revive': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, at the start of your turn, if there is Divine unit on your side, revive itself

---

Card Name: Loyal Tomb Guard
Type: Character
Stats: ATK=35 DEF=0 Cost=300 Affinity=CHAOS
AbilityType: REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
ability_params: {'turn_end_self': True, 'crystal_threshold': 1200}
Description: Once, at the end of your turn. If you have 1200 or less Crystals, you can revive this card.
Test Cases:

Test Case ID: TC-FUNC-Loyal-Tomb-Guard-001
Description:
Loyal Tomb Guard: ability REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'turn_end_self': True, 'crystal_threshold': 1200}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, at the end of your turn. If you have 1200 or less Crystals, you can revive this card.

---

Card Name: NG-01 the Forgotten Failure
Type: Character
Stats: ATK=80 DEF=15 Cost=860 Affinity=BIO
AbilityType: REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
ability_params: {'on_any_destroy': True, 'crystal_threshold': 1000, 'stat_bonus': 40}
Description: Whenever a card is destroyed while you have 1000 or less crystal, revive this card with +40 ATK&DEF bonus
Test Cases:

Test Case ID: TC-FUNC-NG-01-the-Forgotten-Failure-001
Description:
NG-01 the Forgotten Failure: ability REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'on_any_destroy': True, 'crystal_threshold': 1000, 'stat_bonus': 40}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Whenever a card is destroyed while you have 1000 or less crystal, revive this card with +40 ATK&DEF bonus

---

Card Name: Red Zombie
Type: Character
Stats: ATK=60 DEF=30 Cost=580 Affinity=BIO
AbilityType: REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
ability_params: {'union_material': True, 'requires_mutagen': True, 'turn_end': True}
Description: With Mutagen Flag: If used as a Union material, revive it at the end of this turn.
Test Cases:

Test Case ID: TC-FUNC-Red-Zombie-001
Description:
Red Zombie: ability REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'union_material': True, 'requires_mutagen': True, 'turn_end': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: With Mutagen Flag: If used as a Union material, revive it at the end of this turn.

---

Card Name: The First Angel
Type: Character
Stats: ATK=140 DEF=100 Cost=2000 Affinity=DIVINE
AbilityType: REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
ability_params: {'from_void': True, 'halve_stats': True}
Description: Start of your turn: while in void, revive with halved ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-The-First-Angel-001
Description:
The First Angel: ability REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION functional smoke test
Implementation Reference:
- CharacterData.AbilityType.REVIVE_ONCE_IF_DESTROYED_BY_NON_UNION
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'from_void': True, 'halve_stats': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Start of your turn: while in void, revive with halved ATK&DEF

---

Card Name: Mine Guard
Type: Character
Stats: ATK=20 DEF=15 Cost=300 Affinity=COSMIC
AbilityType: SACRIFICE_FOR_CARD_TYPE
ability_params: {'name_contains': 'Miner'}
Description: Prevent ‘Miner’ or ‘Mining’ card from being destroyed, but destroy this card instead. Usable face-down
Test Cases:

Test Case ID: TC-FUNC-Mine-Guard-001
Description:
Mine Guard: sacrifice self to save 'Miner' card
Implementation Reference:
- TurnManager._apply_battle_result SACRIFICE_FOR_CARD_TYPE prompt
- AbilityType.SACRIFICE_FOR_CARD_TYPE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-up Mine Guard on field.
- Ally defender name contains 'Miner' would be destroyed.
Steps:
Step 1: Accept sacrifice prompt.
Expected Result:
- Mine Guard destroyed instead; 'Miner' ally survives.

---

Card Name: Oak Guardian
Type: Character
Stats: ATK=30 DEF=50 Cost=450 Affinity=DIVINE
AbilityType: SACRIFICE_FOR_CARD_TYPE
ability_params: {'name_contains': 'Nature', 'save_ally': True, 'face_down': True}
Description: Once, if an exposed Nature card will be destroyed, it cannot be destroyed. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Oak-Guardian-001
Description:
Oak Guardian: sacrifice self to save 'Nature' card
Implementation Reference:
- TurnManager._apply_battle_result SACRIFICE_FOR_CARD_TYPE prompt
- AbilityType.SACRIFICE_FOR_CARD_TYPE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-up Oak Guardian on field.
- Ally defender name contains 'Nature' would be destroyed.
Steps:
Step 1: Accept sacrifice prompt.
Expected Result:
- Oak Guardian destroyed instead; 'Nature' ally survives.

---

Card Name: Vampire Servant
Type: Character
Stats: ATK=20 DEF=20 Cost=800 Affinity=CHAOS
AbilityType: SACRIFICE_FOR_CARD_TYPE
ability_params: {'name_contains': 'Vampire'}
Description: If a 'Vampire' card will be destroyed, destroy this card instead. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Vampire-Servant-001
Description:
Vampire Servant: sacrifice self to save 'Vampire' card
Implementation Reference:
- TurnManager._apply_battle_result SACRIFICE_FOR_CARD_TYPE prompt
- AbilityType.SACRIFICE_FOR_CARD_TYPE
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Face-up Vampire Servant on field.
- Ally defender name contains 'Vampire' would be destroyed.
Steps:
Step 1: Accept sacrifice prompt.
Expected Result:
- Vampire Servant destroyed instead; 'Vampire' ally survives.

---

Card Name: Armored Wolf
Type: Character
Stats: ATK=40 DEF=80 Cost=800 Affinity=NATURE
AbilityType: SELF_DEBUFF_ON_ATTACK_AND_DEFEND
ability_params: {'atk': 50, 'def': -50, 'once_in_reckoning': True}
Description: Once in Reckoning, you can choose to grant +50 ATK and -50 DEF to it permanently
Test Cases:

Test Case ID: TC-FUNC-Armored-Wolf-001
Description:
Armored Wolf: once -50 ATK on attack, once --50 DEF on defend
Implementation Reference:
- TurnManager._apply_post_battle_effects SELF_DEBUFF
- AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First attack and first defend.
Steps:
Step 1: Execute both in separate battles.
Expected Result:
- After first attack: current_atk -= 50. After first defend: current_def -= -50.

---

Card Name: Berserker of Ice Sea
Type: Character
Stats: ATK=105 DEF=50 Cost=1000 Affinity=ANIMA
AbilityType: SELF_DEBUFF_ON_ATTACK_AND_DEFEND
ability_params: {'atk': 35, 'def': 0, 'once_turn_end': True}
Description: Once, at your turn end, -35 ATK
Test Cases:

Test Case ID: TC-FUNC-Berserker-of-Ice-Sea-001
Description:
Berserker of Ice Sea: once -35 ATK on attack, once -0 DEF on defend
Implementation Reference:
- TurnManager._apply_post_battle_effects SELF_DEBUFF
- AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First attack and first defend.
Steps:
Step 1: Execute both in separate battles.
Expected Result:
- After first attack: current_atk -= 35. After first defend: current_def -= 0.

---

Card Name: Dark Tengu
Type: Character
Stats: ATK=30 DEF=30 Cost=250 Affinity=CHAOS
AbilityType: SELF_DEBUFF_ON_ATTACK_AND_DEFEND
ability_params: {'atk': 5, 'def': 5}
Description: -10 ATK once it successfully attacked. -10 DEF once it successfully defended.
Test Cases:

Test Case ID: TC-FUNC-Dark-Tengu-001
Description:
Dark Tengu: once -5 ATK on attack, once -5 DEF on defend
Implementation Reference:
- TurnManager._apply_post_battle_effects SELF_DEBUFF
- AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First attack and first defend.
Steps:
Step 1: Execute both in separate battles.
Expected Result:
- After first attack: current_atk -= 5. After first defend: current_def -= 5.

---

Card Name: Elven Archer
Type: Character
Stats: ATK=40 DEF=20 Cost=320 Affinity=NATURE
AbilityType: SELF_DEBUFF_ON_ATTACK_AND_DEFEND
ability_params: {'atk': 0, 'def': -30, 'on_attack': True}
Description: After performed attack : -30 DEF
Test Cases:

Test Case ID: TC-FUNC-Elven-Archer-001
Description:
Elven Archer: once -0 ATK on attack, once --30 DEF on defend
Implementation Reference:
- TurnManager._apply_post_battle_effects SELF_DEBUFF
- AbilityType.SELF_DEBUFF_ON_ATTACK_AND_DEFEND
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- First attack and first defend.
Steps:
Step 1: Execute both in separate battles.
Expected Result:
- After first attack: current_atk -= 0. After first defend: current_def -= -30.

---

Card Name: Vile Creeper
Type: Character
Stats: ATK=10 DEF=30 Cost=200 Affinity=BIO
AbilityType: SWAP_ATK_DEF_PER_OPP_TURN
ability_params: {}
Description: While this card is exposed, at foe’s turn end, swap its ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Vile-Creeper-001
Description:
Vile Creeper: swap ATK/DEF at end of each opponent turn
Implementation Reference:
- TurnManager._apply_end_of_turn_boosts
- AbilityType.SWAP_ATK_DEF_PER_OPP_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Vile Creeper face-up.
Steps:
Step 1: End opponent turn.
Expected Result:
- current_atk and current_def values swapped.

---

Card Name: Poltergeist
Type: Character
Stats: ATK=0 DEF=70 Cost=700 Affinity=CHAOS
AbilityType: SWAP_ATK_DEF_WHEN_ATTACKING
ability_params: {}
Description: If this card performs an attack, switch this card’s ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Poltergeist-001
Description:
Poltergeist: uses DEF as ATK when attacking
Implementation Reference:
- BattleResolver._get_effective_atk() sets atk = get_effective_def()
- AbilityType.SWAP_ATK_DEF_WHEN_ATTACKING
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Poltergeist ATK=0 DEF=70 attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == effective DEF (70 + temp/perm bonuses), not base ATK 0.

---

Card Name: Sea Fortress
Type: Character
Stats: ATK=90 DEF=150 Cost=1200 Affinity=ANIMA
AbilityType: SWAP_ATK_DEF_WHEN_ATTACKING
ability_params: {'coin_flip_choice': True, 'in_reckoning': True}
Description: In Reckoning, flip a coin. Heads: You can choose to swap its ATK&DEF
Test Cases:

Test Case ID: TC-FUNC-Sea-Fortress-001
Description:
Sea Fortress: uses DEF as ATK when attacking
Implementation Reference:
- BattleResolver._get_effective_atk() sets atk = get_effective_def()
- AbilityType.SWAP_ATK_DEF_WHEN_ATTACKING
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Sea Fortress ATK=90 DEF=150 attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == effective DEF (150 + temp/perm bonuses), not base ATK 90.

---

Card Name: Steel Angel
Type: Character
Stats: ATK=45 DEF=75 Cost=500 Affinity=DIVINE
AbilityType: SWAP_ATK_DEF_WHEN_ATTACKING
ability_params: {'vs_affinity': 'CHAOS'}
Description: Swap this card’s ATK&DEF if performs attack on Chaos
Test Cases:

Test Case ID: TC-FUNC-Steel-Angel-001
Description:
Steel Angel: uses DEF as ATK when attacking
Implementation Reference:
- BattleResolver._get_effective_atk() sets atk = get_effective_def()
- AbilityType.SWAP_ATK_DEF_WHEN_ATTACKING
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Steel Angel ATK=45 DEF=75 attacks.
Steps:
Step 1: Resolve battle.
Expected Result:
- attacker_atk_used == effective DEF (75 + temp/perm bonuses), not base ATK 45.

---

Card Name: The White Lady
Type: Character
Stats: ATK=50 DEF=30 Cost=600 Affinity=CHAOS
AbilityType: TEMP_ATK_BOOST_OWN_TURN_START
ability_params: {'atk': 40, 'crystal_cost': 500, 'optional': True}
Description: At the start of your turn, you can pay 500 crystal to increase this card’s ATK by 40
Test Cases:

Test Case ID: TC-FUNC-The-White-Lady-001
Description:
The White Lady: +40 temp ATK at start of own turn
Implementation Reference:
- TurnManager turn start clears/applies temp bonuses
- AbilityType.TEMP_ATK_BOOST_OWN_TURN_START
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- The White Lady on field.
Steps:
Step 1: Start own turn.
Expected Result:
- temp_atk_bonus == 40 until end of turn.

---

Card Name: Tiyanak
Type: Character
Stats: ATK=30 DEF=30 Cost=350 Affinity=CHAOS
AbilityType: TEMP_ATK_BOOST_OWN_TURN_START
ability_params: {'atk': 20, 'crystal_cost': 200, 'optional': True}
Description: At the start of your turn, you can pay 200 crystals to increase this card’s ATK by 20
Test Cases:

Test Case ID: TC-FUNC-Tiyanak-001
Description:
Tiyanak: +20 temp ATK at start of own turn
Implementation Reference:
- TurnManager turn start clears/applies temp bonuses
- AbilityType.TEMP_ATK_BOOST_OWN_TURN_START
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Tiyanak on field.
Steps:
Step 1: Start own turn.
Expected Result:
- temp_atk_bonus == 20 until end of turn.

---

Card Name: Giant Mosquito
Type: Character
Stats: ATK=30 DEF=20 Cost=800 Affinity=NATURE
AbilityType: TEMP_ATK_HALF_TARGET
ability_params: {}
Description: If this card performs an attack, +ATK equal to half of target’s ATK until the end of this turn
Test Cases:

Test Case ID: TC-FUNC-Giant-Mosquito-001
Description:
Giant Mosquito: ability TEMP_ATK_HALF_TARGET functional smoke test
Implementation Reference:
- CharacterData.AbilityType.TEMP_ATK_HALF_TARGET
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: If this card performs an attack, +ATK equal to half of target’s ATK until the end of this turn

---

Card Name: Aembar the Intel Dealer
Type: Character
Stats: ATK=10 DEF=10 Cost=150 Affinity=COSMIC
AbilityType: TEMP_BOOST_ON_OPP_TECH
ability_params: {'reveal_on_tech': True, 'any_player': True, 'face_down': True}
Description: Any player use Tech card, they reveal 1 cell on their field. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Aembar-the-Intel-Dealer-001
Description:
Aembar the Intel Dealer: +5/+5 permanently when opponent plays Tech
Implementation Reference:
- TurnManager.play_tech_card TEMP_BOOST_ON_OPP_TECH loop
- AbilityType.TEMP_BOOST_ON_OPP_TECH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Aembar the Intel Dealer face-up on opponent of tech player.
Steps:
Step 1: Opponent plays any Tech.
Expected Result:
- perm_atk_bonus += 5; perm_def_bonus += 5 (stacks per foe Tech).

---

Card Name: Ethereal Enchanter
Type: Character
Stats: ATK=50 DEF=20 Cost=900 Affinity=ARCANE
AbilityType: TEMP_BOOST_ON_OPP_TECH
ability_params: {'atk': 50, 'def': 50, 'on_own_tech': True, 'until_foe_turn': True}
Description: Whenever you uses tech, this card gains 50 ATK&DEF until the end of foe’s turn
Test Cases:

Test Case ID: TC-FUNC-Ethereal-Enchanter-001
Description:
Ethereal Enchanter: +50/+50 permanently when opponent plays Tech
Implementation Reference:
- TurnManager.play_tech_card TEMP_BOOST_ON_OPP_TECH loop
- AbilityType.TEMP_BOOST_ON_OPP_TECH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Ethereal Enchanter face-up on opponent of tech player.
Steps:
Step 1: Opponent plays any Tech.
Expected Result:
- perm_atk_bonus += 50; perm_def_bonus += 50 (stacks per foe Tech).

---

Card Name: Mad Doctor
Type: Character
Stats: ATK=70 DEF=50 Cost=700 Affinity=CHAOS
AbilityType: TEMP_BOOST_ON_OPP_TECH
ability_params: {'crystal_gain': 150, 'any_player': True}
Description: +150 Crystal whenever any player use Tech card
Test Cases:

Test Case ID: TC-FUNC-Mad-Doctor-001
Description:
Mad Doctor: +5/+5 permanently when opponent plays Tech
Implementation Reference:
- TurnManager.play_tech_card TEMP_BOOST_ON_OPP_TECH loop
- AbilityType.TEMP_BOOST_ON_OPP_TECH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Mad Doctor face-up on opponent of tech player.
Steps:
Step 1: Opponent plays any Tech.
Expected Result:
- perm_atk_bonus += 5; perm_def_bonus += 5 (stacks per foe Tech).

---

Card Name: Magical Butterfly
Type: Character
Stats: ATK=15 DEF=15 Cost=180 Affinity=NATURE
AbilityType: TEMP_BOOST_ON_OPP_TECH
ability_params: {'atk': 10, 'def': 10}
Description: Whenever foe’s tech card is activated, +10 ATK&DEF permanently. Usable face-down
Test Cases:

Test Case ID: TC-FUNC-Magical-Butterfly-001
Description:
Magical Butterfly: +10/+10 permanently when opponent plays Tech
Implementation Reference:
- TurnManager.play_tech_card TEMP_BOOST_ON_OPP_TECH loop
- AbilityType.TEMP_BOOST_ON_OPP_TECH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Magical Butterfly face-up on opponent of tech player.
Steps:
Step 1: Opponent plays any Tech.
Expected Result:
- perm_atk_bonus += 10; perm_def_bonus += 10 (stacks per foe Tech).

---

Card Name: Spell Tank
Type: Character
Stats: ATK=35 DEF=40 Cost=400 Affinity=ARCANE
AbilityType: TEMP_BOOST_ON_OPP_TECH
ability_params: {'atk': 40, 'on_own_tech': True, 'temp': True}
Description: After you use a Tech card, this card gain 40 ATK until the end of this turn.
Test Cases:

Test Case ID: TC-FUNC-Spell-Tank-001
Description:
Spell Tank: +40/+5 permanently when opponent plays Tech
Implementation Reference:
- TurnManager.play_tech_card TEMP_BOOST_ON_OPP_TECH loop
- AbilityType.TEMP_BOOST_ON_OPP_TECH
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Spell Tank face-up on opponent of tech player.
Steps:
Step 1: Opponent plays any Tech.
Expected Result:
- perm_atk_bonus += 40; perm_def_bonus += 5 (stacks per foe Tech).

---

Card Name: Black Worms
Type: Character
Stats: ATK=45 DEF=65 Cost=800 Affinity=BIO
AbilityType: TURN_END_FOE_CRYSTAL_PER_MUTAGEN
ability_params: {'amount': 300}
Description: At your turn’s end, foe loses 300 Crystals for each Mutagen flag on the field
Test Cases:

Test Case ID: TC-FUNC-Black-Worms-001
Description:
Black Worms: ability TURN_END_FOE_CRYSTAL_PER_MUTAGEN functional smoke test
Implementation Reference:
- CharacterData.AbilityType.TURN_END_FOE_CRYSTAL_PER_MUTAGEN
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'amount': 300}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: At your turn’s end, foe loses 300 Crystals for each Mutagen flag on the field

---

Card Name: Moon Rabbit
Type: Character
Stats: ATK=10 DEF=20 Cost=180 Affinity=COSMIC
AbilityType: TURN_END_REVEAL_OPPONENT_CELLS_ONCE
ability_params: {'count': 1}
Description: Once after reckoning, reveal foe’s cell for each Moon card on the field
Test Cases:

Test Case ID: TC-FUNC-Moon-Rabbit-001
Description:
Moon Rabbit: ability TURN_END_REVEAL_OPPONENT_CELLS_ONCE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.TURN_END_REVEAL_OPPONENT_CELLS_ONCE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'count': 1}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once after reckoning, reveal foe’s cell for each Moon card on the field

---

Card Name: Nanami the Long Neck
Type: Character
Stats: ATK=45 DEF=45 Cost=600 Affinity=CHAOS
AbilityType: TURN_END_REVEAL_OPPONENT_CELLS_ONCE
ability_params: {'count': 2}
Description: Once exposed, foe choose and reveal 2 or their cells
Test Cases:

Test Case ID: TC-FUNC-Nanami-the-Long-Neck-001
Description:
Nanami the Long Neck: ability TURN_END_REVEAL_OPPONENT_CELLS_ONCE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.TURN_END_REVEAL_OPPONENT_CELLS_ONCE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'count': 2}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once exposed, foe choose and reveal 2 or their cells

---

Card Name: Nimrod the Wonder Seeker
Type: Character
Stats: ATK=65 DEF=50 Cost=720 Affinity=COSMIC
AbilityType: TURN_END_REVEAL_OPPONENT_CELLS_ONCE
ability_params: {'count': 2}
Description: Once, at this turn’s end, reveal 2 foe’s cell and 1 of your cell.
Test Cases:

Test Case ID: TC-FUNC-Nimrod-the-Wonder-Seeker-001
Description:
Nimrod the Wonder Seeker: ability TURN_END_REVEAL_OPPONENT_CELLS_ONCE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.TURN_END_REVEAL_OPPONENT_CELLS_ONCE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'count': 2}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, at this turn’s end, reveal 2 foe’s cell and 1 of your cell.

---

Card Name: Wendella the Wise Princess
Type: Character
Stats: ATK=25 DEF=30 Cost=300 Affinity=ANIMA
AbilityType: TURN_END_REVEAL_OPPONENT_CELLS_ONCE
ability_params: {'count': 1}
Description: Once exposed, choose either: reveal 1 foe’s cell or put 1 princes flag on ally unit.
Test Cases:

Test Case ID: TC-FUNC-Wendella-the-Wise-Princess-001
Description:
Wendella the Wise Princess: ability TURN_END_REVEAL_OPPONENT_CELLS_ONCE functional smoke test
Implementation Reference:
- CharacterData.AbilityType.TURN_END_REVEAL_OPPONENT_CELLS_ONCE
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'count': 1}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once exposed, choose either: reveal 1 foe’s cell or put 1 princes flag on ally unit.

---

Card Name: Europan Architect
Type: Character
Stats: ATK=20 DEF=20 Cost=400 Affinity=COSMIC
AbilityType: TURN_START_COIN_FLIP_FLAG
ability_params: {'flag': 'Europa', 'count': 2}
Description: Exposed : Put Europa flag on up to 2 of your units
Test Cases:

Test Case ID: TC-FUNC-Europan-Architect-001
Description:
Europan Architect: turn start coin → venom on 1 exposed ally/foe or mutagen on own unit
Implementation Reference:
- TurnManager turn start ability
- AbilityType.TURN_START_COIN_FLIP_FLAG
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Europan Architect on field at turn start.
- Board has valid flag targets.
Steps:
Step 1: Start turn; flip coin; select target per result.
Expected Result:
- Heads: venom flag on 1 exposed ally or foe card.
- Tails: mutagen on any of your unit (characters get has_mutagen_flag).

---

Card Name: Europan Engineer
Type: Character
Stats: ATK=45 DEF=55 Cost=600 Affinity=COSMIC
AbilityType: TURN_START_COIN_FLIP_FLAG
ability_params: {'flag': 'Europa', 'target_affinity': 'COSMIC'}
Description: At the start of your turn, put Europa flag on any of your Cosmic card.
Test Cases:

Test Case ID: TC-FUNC-Europan-Engineer-001
Description:
Europan Engineer: turn start coin → venom on 1 exposed ally/foe or mutagen on own unit
Implementation Reference:
- TurnManager turn start ability
- AbilityType.TURN_START_COIN_FLIP_FLAG
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Europan Engineer on field at turn start.
- Board has valid flag targets.
Steps:
Step 1: Start turn; flip coin; select target per result.
Expected Result:
- Heads: venom flag on 1 exposed ally or foe card.
- Tails: mutagen on any of your unit (characters get has_mutagen_flag).

---

Card Name: Plant-29
Type: Character
Stats: ATK=45 DEF=85 Cost=900 Affinity=BIO
AbilityType: TURN_START_COIN_FLIP_FLAG
ability_params: {}
Description: Start of your turn: Flip a coin. Head: put Venom Flag on 1 exposed ally or foe card. Tail: put Mutagen Flag on any of your unit.
Test Cases:

Test Case ID: TC-FUNC-Plant-29-001
Description:
Plant-29: turn start coin → venom on 1 exposed ally/foe or mutagen on own unit
Implementation Reference:
- TurnManager turn start ability
- AbilityType.TURN_START_COIN_FLIP_FLAG
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Plant-29 on field at turn start.
- Board has valid flag targets.
Steps:
Step 1: Start turn; flip coin; select target per result.
Expected Result:
- Heads: venom flag on 1 exposed ally or foe card.
- Tails: mutagen on any of your unit (characters get has_mutagen_flag).

---

Card Name: S-02 the Hatcher
Type: Character
Stats: ATK=5 DEF=35 Cost=200 Affinity=BIO
AbilityType: UNION_SUMMON_REVIVE_MATCH
ability_params: {'token': True, 'foe_turn_end': True}
Description: Once at foe’s turn end, create a token on an empty cell with 0 ATK&DEF and no ability.
Test Cases:

Test Case ID: TC-FUNC-S-02-the-Hatcher-001
Description:
S-02 the Hatcher: ability UNION_SUMMON_REVIVE_MATCH functional smoke test
Implementation Reference:
- CharacterData.AbilityType.UNION_SUMMON_REVIVE_MATCH
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'token': True, 'foe_turn_end': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once at foe’s turn end, create a token on an empty cell with 0 ATK&DEF and no ability.

---

Card Name: Seraph Lawkeeper
Type: Character
Stats: ATK=35 DEF=50 Cost=900 Affinity=DIVINE
AbilityType: UNION_SUMMON_REVIVE_MATCH
ability_params: {'affinities': ['DIVINE'], 'turn_end': True, 'face_down': True}
Description: Once, if a Divine or Anima card is destroyed, revived that destroyed card at this turn’s end. Usable face-down.
Test Cases:

Test Case ID: TC-FUNC-Seraph-Lawkeeper-001
Description:
Seraph Lawkeeper: ability UNION_SUMMON_REVIVE_MATCH functional smoke test
Implementation Reference:
- CharacterData.AbilityType.UNION_SUMMON_REVIVE_MATCH
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'affinities': ['DIVINE'], 'turn_end': True, 'face_down': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: Once, if a Divine or Anima card is destroyed, revived that destroyed card at this turn’s end. Usable face-down.

---

Card Name: Zetamas the Great Summoner
Type: Character
Stats: ATK=0 DEF=0 Cost=1000 Affinity=ARCANE
AbilityType: UNION_SUMMON_REVIVE_MATCH
ability_params: {'token_name': 'Leviathan', 'turn_end': True}
Description: At the end of your turn: create a token copy of Leviathan on an empty cell on your side
Test Cases:

Test Case ID: TC-FUNC-Zetamas-the-Great-Summoner-001
Description:
Zetamas the Great Summoner: ability UNION_SUMMON_REVIVE_MATCH functional smoke test
Implementation Reference:
- CharacterData.AbilityType.UNION_SUMMON_REVIVE_MATCH
- See BattleResolver.gd / TurnManager.gd
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Card placed; ability_params={'token_name': 'Leviathan', 'turn_end': True}.
Steps:
Step 1: Trigger battle/turn/tech condition per description.
Expected Result:
- Behavior matches CardDatabase description: At the end of your turn: create a token copy of Leviathan on an empty cell on your side

---

Card Name: Death Cobra
Type: Character
Stats: ATK=85 DEF=50 Cost=900 Affinity=NATURE
AbilityType: VENOM_FLAG_END_OF_TURN
ability_params: {}
Description: Your turn end: select 1 exposed card on either’s side. Put 1 venom flag on it. In Reckoning, foe with Venom Flag get -50 DEF
Test Cases:

Test Case ID: TC-FUNC-Death-Cobra-001
Description:
Death Cobra: end of own turn apply venom to opponent face-up card
Implementation Reference:
- TurnManager._end_turn random venom target
- AbilityType.VENOM_FLAG_END_OF_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Death Cobra face-up; opponent has face-up character.
Steps:
Step 1: End own turn.
Expected Result:
- Random opponent face-up character gets "venom" in flags array.

---

Card Name: Lindsy the Brave Princess
Type: Character
Stats: ATK=55 DEF=35 Cost=600 Affinity=ANIMA
AbilityType: VENOM_FLAG_END_OF_TURN
ability_params: {'flag': 'princess', 'turn_start': True, 'ally_target': True}
Description: At the start of each turn, put 1 princess flag on ally unit
Test Cases:

Test Case ID: TC-FUNC-Lindsy-the-Brave-Princess-001
Description:
Lindsy the Brave Princess: end of own turn apply venom to opponent face-up card
Implementation Reference:
- TurnManager._end_turn random venom target
- AbilityType.VENOM_FLAG_END_OF_TURN
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Lindsy the Brave Princess face-up; opponent has face-up character.
Steps:
Step 1: End own turn.
Expected Result:
- Random opponent face-up character gets "venom" in flags array.

---

Card Name: Venom Toad
Type: Character
Stats: ATK=15 DEF=20 Cost=400 Affinity=NATURE
AbilityType: VENOM_TOAD_RECKONING
ability_params: {}
Description: After Reckoning, add venom flag to the foe’s unit. In Reckoning, destroy foe’s unit with venom flag
Test Cases:

Test Case ID: TC-FUNC-Venom-Toad-001
Description:
Venom Toad: destroy venom foe in reckoning; venom on foe after battle
Implementation Reference:
- BattleResolver._apply_venom_toad_reckoning_destroy
- TurnManager._apply_post_battle_effects VENOM_TOAD_RECKONING
- AbilityType.VENOM_TOAD_RECKONING
Preconditions:
- Godot battle_test or Daily Dungeon; `CardDatabase` loaded.
- Both players STARTING_CRYSTALS=5000 unless test specifies otherwise.
- Disable `bare_hands_brawling` dungeon modifier (cancels character abilities in BattleResolver).
- Venom Toad in battle vs character.
Steps:
Step 1: Attack or defend; check destroy and post-battle venom.
Expected Result:
- Foe with venom flag destroyed during reckoning.
- After reckoning, surviving foe receives venom flag.

---
